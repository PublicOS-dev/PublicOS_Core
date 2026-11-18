import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:publicos_core/src/core/extensions/publicos_channels.dart';
import 'package:publicos_core/src/core/publicos_core.dart';
import 'package:publicos_core/src/database/database.dart' as db;
import 'package:publicos_core/src/models/feed_server/feed_server_models.dart';
import 'package:publicos_core/src/models/post.dart';
import 'package:publicos_core/src/models/rss_models.dart' show FeedInteractions;
import 'package:publicos_core/src/utils/log.dart';
import 'package:publicos_core/src/core/exceptions/feed_gate_exception.dart';
import 'package:publicos_core/src/utils/rss_parser.dart';
import 'package:publicos_core/src/utils/channel_url.dart';

/// Every code the server refuses a channel read with, plus the two the client
/// side produces for a challenge it could (`SIGNIN_REQUIRED`, a key loaded)
/// or could not (`ENVELOPE_MISSING`, no key) answer. Server source:
/// `internal/handlers/authorize.go`; add a rung there, add its code here.
const List<String> kFeedRefusalCodes = <String>[
  'PRIVATE_FEED',
  'PRIVATE_FEED_NOT_APPROVED',
  'VERIFIED_ONLY',
  'ACCOUNT_ONLY',
  'STANDING_REQUIRED',
  'PAYWALL_DENIED',
  'SIGNIN_REQUIRED',
  'ENVELOPE_MISSING',
];

/// Result of [PublicOSFeedLists.refreshPostsForFeeds] — the fresh list, plus the
/// two things only Core can know: how much of it is NEW relative to the cache,
/// and how much of the network round trip was actually free.
class RefreshedFeedList {
  /// The full, merged, newest-first list. This REPLACES what the caller is
  /// showing; it is not a delta.
  final List<Post> posts;

  /// How many of [posts] were not in the cached set the user is currently
  /// looking at. Drives the "New posts" chip.
  ///
  /// Computed in Core deliberately: this is the only place holding the old set
  /// and the new set at the same instant. Handing both to the widget and asking
  /// it to diff them is how you get a count that is subtly, permanently wrong.
  final int newCount;

  /// Feeds that answered with a private/locked error. Drives the "some feeds in
  /// this list are private" banner.
  final Set<String> lockedFeedUrls;

  /// How many feeds answered `304 Not Modified` — i.e. cost a round trip and no
  /// download. Telemetry: if this is near zero in the wild, either the servers
  /// we read don't send validators or we're storing them wrong.
  final int notModifiedCount;

  // ── Feed-level metadata ──────────────────────
  //
  // Populated ONLY on the single-feed path ([PublicOSFeedLists.refreshPostsForFeed])
  // — a merged multi-feed refresh has no single feed to describe, so the
  // multi-feed path leaves all three null. Carried off the same response (or
  // cached body) as the posts, so a single-feed surface renders its header
  // with zero extra network — including offline.

  /// The feed's own top-level description. Null when absent or multi-feed.
  final String? description;

  /// The website the feed declares (`ParsedFeed.siteUrl`) and its declared,
  /// unverified language (`ParsedFeed.language`). Null when undeclared or
  /// multi-feed. The single-feed header's details line.
  final String? siteUrl;
  final String? language;

  /// The channel's read stats (the interactions call's `channel.stats`) —
  /// null for external feeds, opted-out channels, and multi-feed refreshes.
  /// Absent means *not measured*, never zero.
  final ChannelStats? stats;

  /// The channel's `posting` — `'open'` marks a forum. Null for
  /// non-PublicOS feeds and multi-feed refreshes.
  final String? postingPolicy;

  /// `channel.access.private` — true when this is a private channel the
  /// (approved) reader is seeing. Single-feed path only; null for
  /// non-PublicOS feeds and multi-feed refreshes. Drives the composer's
  /// media upload door.
  final bool? isPrivate;

  /// Whether THIS reader may post in the channel: the server's per-reader
  /// answer (`channel.can_post` in the signed interactions call). Single-feed
  /// path only; null = not asked (unsigned read, external feed, older
  /// server, multi-feed). Lights the compose button on any channel the
  /// reader may post in, not only `open` ones.
  final bool? canPost;

  /// The document has a `next_url` — the server has more posts beyond this
  /// page. Single-feed path only; false for external feeds and multi-feed
  /// refreshes. A capability learned from the response, never from the URL.
  final bool hasMore;

  /// The channel object the server embedded on a single-feed fetch
  /// (`ParsedFeed.channel`). Null on rosters, older servers and cache paints
  /// — null means UNKNOWN.
  final Channel? channel;

  /// Feed url → the feed's own image (`ParsedFeed.imageUrl`: a channel's
  /// icon or its owner's avatar, RSS `<image>`, Atom `<logo>`, JSON Feed
  /// `icon`), for every feed this refresh read, 304s included. `''` = the
  /// feed declares no image. A feed that failed is absent. Both paths fill
  /// it, so an app's icon registry updates off the fetch it already made
  /// instead of downloading the document again.
  final Map<String, String> feedIcons;

  const RefreshedFeedList({
    required this.posts,
    required this.newCount,
    required this.lockedFeedUrls,
    required this.notModifiedCount,
    this.feedIcons = const {},
    this.description,
    this.siteUrl,
    this.language,
    this.stats,
    this.postingPolicy,
    this.isPrivate,
    this.canPost,
    this.hasMore = false,
    this.channel,
  });

  factory RefreshedFeedList.empty() => const RefreshedFeedList(
        posts: [],
        newCount: 0,
        lockedFeedUrls: {},
        notModifiedCount: 0,
      );
}

/// User-side feed curation: custom feed lists (mixed RSS + PublicOS
/// channels) and saved-post bookmarks.
///
/// Feed lists are "my playlist of feeds I follow" — completely decoupled
/// from SSP/BSP. You can add any RSS feed from any source. Lists load two-
/// phase via [getCachedPostsForFeeds] + [refreshPostsForFeeds]; single feeds
/// via [getCachedFeed] + [refreshPostsForFeed].
///
/// Bookmarked posts are user-side "save for later" snapshots — tied to a
/// specific post UID, not a feed or channel.
extension PublicOSFeedLists on PublicOS {
  static const _tag = 'FeedLists';

  /// Per-feed network ceiling.
  ///
  /// Was 30s inline. A feed that has not answered in 8 seconds is not going to
  /// save the render, and on a COLD cache this is still the barrier — the whole
  /// list waits for the slowest member — so the ceiling is what the user feels.
  /// Dropping it 30s → 8s cuts the worst case by nearly 4x for one constant.
  static const Duration _feedTimeout = Duration(seconds: 8);

  // ==========================================================================
  // LIST CRUD
  // ==========================================================================

  /// Re-key legacy account-scoped feed lists onto the current session.
  ///
  /// **Why this exists.** `FeedLists` used to be scoped by
  /// `myPublicosAddress` (the ACCOUNT) while every other per-user table scoped
  /// by `sessionBlockchainAddress` (the SESSION). That was wrong: a user can hold
  /// **multiple sessions for the same account on the same device**, and an
  /// account-scoped row cannot tell them apart. Fixed — but the rows
  /// already on disk still carry the account address, so a straight flip of the
  /// reader would make every existing user's lists (Following, their demo News
  /// list, everything) **silently disappear**.
  ///
  /// So: at login, re-point any row still keyed by this account onto this
  /// session. Idempotent, best-effort, never throws — a failure here must not
  /// block a login.
  ///
  /// ⚠ Known limit, and it is inherent to the old data: if two sessions for the
  /// same account exist on one device, **the first to log in claims the legacy
  /// lists.** The old rows carry no session attribution, so there is nothing to
  /// split them by. Nothing is lost; it just lands on one of the two.
  static Future<void> migrateListScopeToSession() async {
    final account = PublicOS.myPublicosAddress;
    final client = PublicOS.sessionBlockchainAddress;
    if (account == null || client == null) return;
    try {
      final moved = await PublicOS.database.rekeyFeedListScope(
        fromAccount: account,
        toSession: client,
      );
      if (moved > 0) {
        Log.i(_tag,
            'Re-keyed $moved feed list(s) from account scope to session scope');
      }

      // ⚠ Load-bearing, and NOT just cleanup after the re-key.
      //
      // `_ensureFollowing` (client + desktop) creates a "Following" list
      // whenever the fetched set contains none. Any read that lands BEFORE the
      // re-key above sees zero session-scoped lists, creates a fresh empty
      // "Following", and then the re-key brings the real one across as well —
      // two Following lists, one empty.
      //
      // Chasing that ordering is the wrong fix: the same race can be lost by any
      // future caller. Collapsing duplicates is idempotent and closes it for
      // good. Runs every login; a no-op once there is nothing to merge.
      final merged = await PublicOS.database.mergeDuplicateLists(client);
      if (merged > 0) {
        Log.i(_tag, 'Merged $merged duplicate feed list(s)');
      }
    } catch (e) {
      Log.e(_tag, 'migrateListScopeToSession error (non-fatal): $e');
    }
  }

  /// Get all feed lists for the current user.
  static Future<List<FeedList>> getUserLists() async {
    try {
      if (PublicOS.sessionBlockchainAddress == null) return [];
      final sessionAddress = PublicOS.sessionBlockchainAddress!;
      final results = await PublicOS.database.getListsForSession(sessionAddress);

      return results
          .map((row) => FeedList(
                id: row.id,
                name: row.name,
                icon: row.icon,
                sessionAddress: row.sessionAddress,
                createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
                updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
                isSingle: row.isSingle,
              ))
          .toList();
    } catch (e) {
      Log.e(_tag, 'getUserLists error: $e');
      return [];
    }
  }

  /// Create a new feed list (optional icon).
  ///
  /// `isSingle: true` flags the list as wrapping a single feed; the UI then
  /// renders it as that feed (icon + name + via line) instead of as a list.
  /// The single-feed cap is a UI-layer invariant, not a DB constraint.
  static Future<FeedList?> createList(
    String name, {
    String? icon,
    bool isSingle = false,
  }) async {
    try {
      if (PublicOS.sessionBlockchainAddress == null) {
        Log.w(_tag, 'Cannot create list: no authenticated session');
        return null;
      }

      final sessionAddress = PublicOS.sessionBlockchainAddress!;
      final now = DateTime.now().millisecondsSinceEpoch;

      final companion = db.FeedListsCompanion(
        name: Value(name),
        icon: Value(icon),
        sessionAddress: Value(sessionAddress),
        createdAt: Value(now),
        updatedAt: Value(now),
        isSingle: Value(isSingle),
      );

      final listId = await PublicOS.database.insertList(companion);
      Log.i(_tag,
          'Created list "$name" (id: $listId${isSingle ? ', single' : ''})');

      return FeedList(
        id: listId,
        name: name,
        icon: icon,
        sessionAddress: sessionAddress,
        createdAt: DateTime.fromMillisecondsSinceEpoch(now),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
        isSingle: isSingle,
      );
    } catch (e) {
      Log.e(_tag, 'createList error: $e');
      return null;
    }
  }

  /// Update list name and/or icon.
  static Future<FeedList?> updateList(int listId,
      {String? name, String? icon}) async {
    try {
      if (PublicOS.sessionBlockchainAddress == null) return null;

      final sessionAddress = PublicOS.sessionBlockchainAddress!;
      final now = DateTime.now().millisecondsSinceEpoch;

      final currentLists = await PublicOS.database.getListsForSession(sessionAddress);
      final currentList = currentLists.where((l) => l.id == listId).firstOrNull;
      if (currentList == null) {
        Log.w(_tag, 'List not found: $listId');
        return null;
      }

      final updatedList = db.FeedListData(
        id: listId,
        name: name ?? currentList.name,
        icon: icon ?? currentList.icon,
        sessionAddress: sessionAddress,
        createdAt: currentList.createdAt,
        updatedAt: now,
        isSingle: currentList.isSingle,
      );

      final updated = await PublicOS.database.updateList(updatedList);
      if (!updated) return null;

      Log.i(_tag, 'Updated list $listId');
      return FeedList(
        id: listId,
        name: updatedList.name,
        icon: updatedList.icon,
        sessionAddress: updatedList.sessionAddress,
        createdAt: DateTime.fromMillisecondsSinceEpoch(updatedList.createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedList.updatedAt),
        isSingle: updatedList.isSingle,
      );
    } catch (e) {
      Log.e(_tag, 'updateList error: $e');
      return null;
    }
  }

  /// Delete a list and its feeds (CASCADE).
  static Future<bool> deleteList(int listId) async {
    try {
      if (PublicOS.sessionBlockchainAddress == null) return false;
      final deleted = await PublicOS.database.deleteList(listId);
      if (deleted > 0) {
        Log.i(_tag, 'Deleted list $listId');
        return true;
      }
      return false;
    } catch (e) {
      Log.e(_tag, 'deleteList error: $e');
      return false;
    }
  }

  /// Convenience: create a list with a single feed in one step.
  static Future<FeedList?> createListWithFeed(
    String listName,
    String feedUrl,
    String? feedTitle,
    String? feedDescription, {
    String? feedFoundAtAccountAddress,
    String? feedRecordKey,
    String? icon,
    bool isSingle = false,
  }) async {
    try {
      final list = await createList(listName, icon: icon, isSingle: isSingle);
      if (list == null) return null;

      final ok = await addFeedToList(
        list.id,
        feedUrl,
        feedTitle,
        feedDescription,
        feedFoundAtAccountAddress: feedFoundAtAccountAddress,
        feedRecordKey: feedRecordKey,
      );
      if (!ok) {
        await deleteList(list.id);
        return null;
      }

      return list;
    } catch (e) {
      Log.e(_tag, 'createListWithFeed error: $e');
      return null;
    }
  }

  /// Follow a feed as its own dedicated single-flagged list.
  ///
  /// Creates an `is_single: true` list named after the feed (falling back to
  /// the URL host) and adds the feed in one step. The UI renders this list as
  /// the feed itself — icon + name + `via [foundAt]` — instead of as a list of
  /// feeds. The single-feed invariant is enforced at the sheet layer.
  ///
  /// Returns the created list, or null on failure.
  static Future<FeedList?> followFeedAsSingle(
    String feedUrl, {
    String? feedTitle,
    String? feedDescription,
    String? feedFoundAtAccountAddress,
    String? feedRecordKey,
  }) async {
    final fallbackName = (feedTitle != null && feedTitle.isNotEmpty)
        ? feedTitle
        : (Uri.tryParse(feedUrl)?.host ?? feedUrl);
    return createListWithFeed(
      fallbackName,
      feedUrl,
      feedTitle,
      feedDescription,
      feedFoundAtAccountAddress: feedFoundAtAccountAddress,
      feedRecordKey: feedRecordKey,
      isSingle: true,
    );
  }

  /// Find an existing single-flagged list that contains [feedUrl] for the
  /// current user, or null if none. Used by the add-to-lists sheet to
  /// branch the single-follow row affordance between `+` (create) and
  /// `x` (unfollow).
  static Future<FeedList?> findSingleListForFeed(String feedUrl) async {
    try {
      final lists = await getUserLists();
      for (final list in lists.where((l) => l.isSingle)) {
        final feeds = await getFeedsInList(list.id);
        if (feeds.any((f) => f.feedUrl == feedUrl)) return list;
      }
      return null;
    } catch (e) {
      Log.e(_tag, 'findSingleListForFeed error: $e');
      return null;
    }
  }

  // ==========================================================================
  // FEED SUBSCRIPTIONS (feeds inside a list)
  // ==========================================================================

  /// Add a feed URL to a list. Idempotent (duplicate-safe).
  static Future<bool> addFeedToList(
    int listId,
    String feedUrl,
    String? feedTitle,
    String? feedDescription, {
    String? feedFoundAtAccountAddress,
    String? feedRecordKey,
  }) async {
    try {
      if (PublicOS.sessionBlockchainAddress == null) return false;

      final existingFeeds = await PublicOS.database.getFeedsForList(listId);
      if (existingFeeds.any((f) => f.feedUrl == feedUrl)) {
        return true; // already present
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final companion = db.ListFeedsCompanion(
        listId: Value(listId),
        feedUrl: Value(feedUrl),
        feedTitle: Value(feedTitle),
        feedDescription: Value(feedDescription),
        feedFoundAtAccountAddress: Value(feedFoundAtAccountAddress),
        feedRecordKey: Value(feedRecordKey),
        addedAt: Value(now),
      );

      await PublicOS.database.insertListFeed(companion);
      Log.d(_tag, 'Added feed to list $listId: $feedUrl');
      return true;
    } catch (e) {
      Log.e(_tag, 'addFeedToList error: $e');
      return false;
    }
  }

  /// Remove a feed from a list.
  static Future<bool> removeFeedFromList(int listId, int feedId) async {
    try {
      final deleted = await PublicOS.database.deleteListFeed(feedId);
      if (deleted > 0) {
        Log.d(_tag, 'Removed feed $feedId from list $listId');
        return true;
      }
      return false;
    } catch (e) {
      Log.e(_tag, 'removeFeedFromList error: $e');
      return false;
    }
  }

  /// Get all feeds in a list.
  static Future<List<ListFeed>> getFeedsInList(int listId) async {
    try {
      final results = await PublicOS.database.getFeedsForList(listId);
      return results
          .map((row) => ListFeed(
                id: row.id,
                listId: row.listId,
                feedUrl: row.feedUrl,
                feedTitle: row.feedTitle,
                feedDescription: row.feedDescription,
                feedFoundAtAccountAddress: row.feedFoundAtAccountAddress,
                feedRecordKey: row.feedRecordKey,
                addedAt: DateTime.fromMillisecondsSinceEpoch(row.addedAt),
              ))
          .toList();
    } catch (e) {
      Log.e(_tag, 'getFeedsInList error: $e');
      return [];
    }
  }

  /// Get a list and all its feeds in one call.
  static Future<ListWithFeeds?> getListWithFeeds(int listId) async {
    try {
      if (PublicOS.sessionBlockchainAddress == null) return null;

      final sessionAddress = PublicOS.sessionBlockchainAddress!;
      final listResults =
          await PublicOS.database.getListsForSession(sessionAddress);
      final listRow = listResults.where((l) => l.id == listId).firstOrNull;
      if (listRow == null) return null;

      final list = FeedList(
        id: listRow.id,
        name: listRow.name,
        icon: listRow.icon,
        sessionAddress: listRow.sessionAddress,
        createdAt: DateTime.fromMillisecondsSinceEpoch(listRow.createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(listRow.updatedAt),
        isSingle: listRow.isSingle,
      );
      final feeds = await getFeedsInList(listId);

      return ListWithFeeds(list: list, feeds: feeds);
    } catch (e) {
      Log.e(_tag, 'getListWithFeeds error: $e');
      return null;
    }
  }

  // ==========================================================================
  // FEED CACHE + TWO-PHASE LOAD
  // ==========================================================================
  //
  // Phase 1 [getCachedPostsForFeeds] paints from disk, instantly, no network.
  // Phase 2 [refreshPostsForFeeds] revalidates with conditional GET, rewrites
  // the cache, and reports how many posts are NEW relative to what phase 1
  // showed. The client orchestrates: paint → refresh behind → offer the delta.

  /// Scope for every FeedCache read/write.
  ///
  /// **The SESSION, not the account.** `publicos.sqlite` is one file shared by
  /// everything on the device, and a user can hold **several sessions for the
  /// same account on the same device** — so the account is not a fine enough
  /// scope. Every other per-user table already keys on the session
  /// (`Settings`, `Messages`, `Conversations`, `BookmarkedPosts`), and
  /// `FeedLists` does too (see
  /// [migrateListScopeToSession]).
  static String? get _cacheScope => PublicOS.sessionBlockchainAddress;

  /// The PublicOS-channel enrichment, lifted out of the live fetch path so a
  /// CACHED body goes through **exactly the same** transformation.
  ///
  /// This is the load-bearing bit: `commentsUrl` reconstruction + stamping the
  /// true channel owner/slug from the URL is what makes comments and reactions
  /// work on list-aggregated posts. If the cached path skipped it, cached posts
  /// would render but their comments would silently be dead.
  static List<Post> _enrichFeedPosts(String feedUrl, List<Post> posts) {
    // Pattern: /api/{address}/channels/{slug}/json
    final seg = Uri.parse(feedUrl).pathSegments;
    if (seg.length < 5 ||
        seg[0] != 'api' ||
        seg[2] != 'channels' ||
        seg[4] != 'json') {
      return posts; // external RSS — nothing to reconstruct
    }
    final baseUrl = _extractServerUrl(feedUrl);
    final ownerAddr = seg[1];
    final slug = seg[3];
    return posts
        .map((post) => post
            .copyWith(
              channelOwnerAddress: ownerAddr,
              channelSlug: slug,
            )
            .withInteractionUrls(
              baseUrl: baseUrl,
              ownerAddress: ownerAddr,
              slug: slug,
            ))
        .toList();
  }

  /// Stable identity for "have I seen this post before?".
  ///
  /// NOT `uid` alone: Core's own docstring says `uid` is the *server-assigned*
  /// UUID and is an **empty string for external/unpublished posts** — so every
  /// post in an RSS feed would collide on `''` and `newCount` would always be
  /// zero. Fall through to the post's URL, then to a title+timestamp composite.
  static String _postKey(Post p) {
    if (p.uid.isNotEmpty) return 'uid:${p.uid}';
    final url = p.url ?? p.externalUrl;
    if (url != null && url.isNotEmpty) return 'url:$url';
    return 'ttl:${p.title}@${p.createdAt.millisecondsSinceEpoch}';
  }

  /// The interactions answer stored with a cache row (v33), or null when the
  /// row predates it or holds something unreadable. Never throws: a bad
  /// stored answer costs the counts, not the paint.
  static FeedInteractions? _storedInteractions(db.FeedCacheData row) {
    final raw = row.interactions;
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return FeedInteractions.fromJson(decoded);
    } catch (e) {
      Log.w(_tag, 'Stored interactions unreadable ${row.feedUrl}: $e');
      return null;
    }
  }

  /// A parsed feed's own image as [RefreshedFeedList.feedIcons] carries it:
  /// trimmed, `''` when the feed declares none.
  static String _iconOf(String? imageUrl) => imageUrl?.trim() ?? '';

  /// Decode one cached row into enriched posts. Returns empty on a parse
  /// failure — a corrupt cached body must never take the whole list down; the
  /// refresh behind it will overwrite the row anyway.
  static List<Post> _postsFromCacheRow(db.FeedCacheData row, ListFeed feed,
          {FeedInteractions? interactions}) =>
      _postsFromCachedBody(
        row,
        feedFoundAtAccountAddress: feed.feedFoundAtAccountAddress,
        feedTitle: feed.feedTitle,
        interactions: interactions,
      );

  /// Same decode, but keyed on the raw feed metadata instead of a [ListFeed]
  /// row — the single-feed surfaces ([getCachedPostsForFeed] /
  /// [refreshPostsForFeed]) hold a bare URL, not a list membership.
  static List<Post> _postsFromCachedBody(
    db.FeedCacheData row, {
    String? feedFoundAtAccountAddress,
    String? feedTitle,
    FeedInteractions? interactions,
  }) =>
      _feedFromCachedBody(
        row,
        feedFoundAtAccountAddress: feedFoundAtAccountAddress,
        feedTitle: feedTitle,
        interactions: interactions,
      )?.posts ??
      const [];

  /// Full decode of one cached row — enriched posts PLUS the feed-level
  /// metadata the body always carried (the cache
  /// stores the raw response body, so description/stats/posting_policy are
  /// re-derivable offline).
  /// Null on a parse failure — a corrupt cached body must never take the
  /// surface down; the refresh behind it overwrites the row anyway.
  static ({
    List<Post> posts,
    String imageUrl,
    String? description,
    String? siteUrl,
    String? language,
    ChannelStats? stats,
    String? postingPolicy,
    bool? isPrivate,
    bool hasMore,
  })? _feedFromCachedBody(
    db.FeedCacheData row, {
    String? feedFoundAtAccountAddress,
    String? feedTitle,
    FeedInteractions? interactions,
  }) {
    try {
      Log.i(_tag,
          '[FeedDiag] cached row url=${row.feedUrl} ct=${row.contentType} len=${row.body.length} fetchedAt=${row.fetchedAt} etag=${row.etag}');
      var parsed = RssParser.parseBody(
        row.body,
        row.feedUrl,
        contentType: row.contentType,
        feedFoundAtAccountAddress: feedFoundAtAccountAddress,
        feedTitle: feedTitle,
      );
      Log.i(_tag,
          '[FeedDiag] cached row parsed url=${row.feedUrl} posts=${parsed.posts.length} v1=${parsed.isFeedV1} parseError=${parsed.parseError}');
      // A body this reader cannot read (written by an older one: kept, the
      // parse error would sit where the feed's description goes, over
      // "No posts yet", and every 304 would keep it there)
      // is no cache at all. The refresh behind it fetches the body anew.
      if (parsed.isParseError) {
        Log.w(_tag,
            'Cached body unreadable ${row.feedUrl}: ${parsed.parseError}');
        return null;
      }
      // A PublicOS document carries no counts. A 304 revalidation fetched
      // them anew and hands them here; the cached paint (no answer in hand)
      // reads the last one stored with the row (v33), so the
      // first frame already carries counts, comment totals and the reader's
      // own heart as of the last visit.
      final ix = interactions ?? _storedInteractions(row);
      if (ix != null) parsed = parsed.withInteractions(ix);
      final description = parsed.description.trim();
      return (
        posts: _enrichFeedPosts(row.feedUrl, parsed.posts),
        imageUrl: _iconOf(parsed.imageUrl),
        description: description.isEmpty ? null : description,
        siteUrl: parsed.siteUrl,
        language: parsed.language,
        stats: parsed.stats,
        postingPolicy: parsed.postingPolicy,
        isPrivate: parsed.isPrivate,
        hasMore: parsed.hasMore,
      );
    } catch (e, st) {
      Log.e(_tag, '[FeedDiag] cached feed re-parse THREW ${row.feedUrl}: $e');
      Log.e(_tag, '[FeedDiag] $st');
      return null;
    }
  }

  /// **Phase 1 — instant.** Everything we last saw for [feeds], straight from
  /// disk. No network, ever. Empty on a cold cache (which is a normal, expected
  /// state — the caller simply shows its loader and waits for phase 2).
  ///
  /// The two-phase load is keyed by a `List<ListFeed>`, not a `listId` — the
  /// resolve-the-feeds step is the caller's, so a source with no single list id
  /// can drive it too.
  ///
  /// This is what makes the merged list view possible: [PublicOSFollows]
  /// resolves a list's stored feeds UNION every account followed in it (see
  /// [PublicOSFollows.resolveListItems]) into one feed set with no backing
  /// `listId`, then hands it straight in. Neither loader reads
  /// `feed.id`/`feed.listId` — only `feedUrl` / `feedTitle` /
  /// `feedFoundAtAccountAddress` — so a synthesized [ListFeed] for an account
  /// channel is fetched identically to a stored one.
  ///
  /// `feedIcons` is each readable cached feed's own image, as
  /// [RefreshedFeedList.feedIcons] — read off the same decode as the posts.
  static Future<
          ({
            List<Post> posts,
            Set<String> lockedFeedUrls,
            Map<String, String> feedIcons,
          })>
      getCachedPostsForFeeds(List<ListFeed> feeds) async {
    final scope = _cacheScope;
    if (scope == null) {
      return (
        posts: <Post>[],
        lockedFeedUrls: <String>{},
        feedIcons: <String, String>{},
      );
    }
    try {
      if (feeds.isEmpty) {
        return (
          posts: <Post>[],
          lockedFeedUrls: <String>{},
          feedIcons: <String, String>{},
        );
      }

      // One batched query, not N — this sits directly in front of the first
      // frame, which is the entire latency we are here to remove.
      final rows = await PublicOS.database.getCachedFeeds(
        feeds.map((f) => f.feedUrl).toList(),
        scope,
      );
      final byUrl = {for (final r in rows) r.feedUrl: r};

      final allPosts = <Post>[];
      final lockedFeedUrls = <String>{};
      final feedIcons = <String, String>{};
      for (final feed in feeds) {
        final row = byUrl[feed.feedUrl];
        if (row == null) continue; // never fetched — phase 2 will get it
        if (row.locked) {
          lockedFeedUrls.add(feed.feedUrl);
          continue;
        }
        final decoded = _feedFromCachedBody(
          row,
          feedFoundAtAccountAddress: feed.feedFoundAtAccountAddress,
          feedTitle: feed.feedTitle,
        );
        if (decoded == null) continue;
        allPosts.addAll(decoded.posts);
        feedIcons[feed.feedUrl] = decoded.imageUrl;
      }
      allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return (
        posts: allPosts,
        lockedFeedUrls: lockedFeedUrls,
        feedIcons: feedIcons,
      );
    } catch (e) {
      Log.e(_tag, 'getCachedPostsForFeeds error: $e');
      return (
        posts: <Post>[],
        lockedFeedUrls: <String>{},
        feedIcons: <String, String>{},
      );
    }
  }

  /// **Phase 2 — network.** Revalidate every feed in [feeds] with a conditional
  /// GET, rewrite the cache, and report what is new relative to what phase 1
  /// would have shown.
  ///
  /// `newCount` is computed HERE, not in the widget, because this is the only
  /// place that holds the old set and the new set at the same instant.
  ///
  /// See [getCachedPostsForFeeds] for why the two-phase load is keyed by a
  /// resolved feed set, not a `listId`. This is the phase-2 half the merged
  /// list view rides.
  static Future<RefreshedFeedList> refreshPostsForFeeds(
      List<ListFeed> feeds) async {
    final scope = _cacheScope;
    if (scope == null) return RefreshedFeedList.empty();
    try {
      if (feeds.isEmpty) return RefreshedFeedList.empty();

      final rows = await PublicOS.database.getCachedFeeds(
        feeds.map((f) => f.feedUrl).toList(),
        scope,
      );
      final cachedByUrl = {for (final r in rows) r.feedUrl: r};

      // What phase 1 showed — the baseline `newCount` is measured against.
      final seenKeys = <String>{};
      for (final feed in feeds) {
        final row = cachedByUrl[feed.feedUrl];
        if (row == null || row.locked) continue;
        for (final p in _postsFromCacheRow(row, feed)) {
          seenKeys.add(_postKey(p));
        }
      }

      var notModified = 0;

      final futures = feeds.map((feed) async {
        final cached = cachedByUrl[feed.feedUrl];
        try {
          var parsedFeed = await RssParser.fetchFeed(
            feed.feedUrl,
            feedFoundAtAccountAddress: feed.feedFoundAtAccountAddress,
            feedTitle: feed.feedTitle,
            etag: cached?.etag,
            lastModified: cached?.lastModified,
          ).timeout(
            _feedTimeout,
            onTimeout: () {
              throw Exception('Feed timeout: ${feed.feedUrl}');
            },
          );
          // "Not modified" is only worth something if the body we hold
          // reads; when it does not, fetch it plain (see the single path).
          if (parsedFeed.notModified &&
              cached != null &&
              _feedFromCachedBody(
                    cached,
                    feedFoundAtAccountAddress: feed.feedFoundAtAccountAddress,
                    feedTitle: feed.feedTitle,
                  ) ==
                  null) {
            parsedFeed = await RssParser.fetchFeed(
              feed.feedUrl,
              feedFoundAtAccountAddress: feed.feedFoundAtAccountAddress,
              feedTitle: feed.feedTitle,
            ).timeout(
              _feedTimeout,
              onTimeout: () {
                throw Exception('Feed timeout: ${feed.feedUrl}');
              },
            );
          }
          if (parsedFeed.isParseError) {
            throw FormatException(parsedFeed.parseError!);
          }

          // 304 — the body we hold is still current. Nothing downloaded,
          // nothing parsed. Advance fetchedAt (the row is proven fresh, and
          // eviction keys off it) and reuse the cached posts.
          if (parsedFeed.notModified) {
            notModified++;
            await PublicOS.database.touchCachedFeed(
              feed.feedUrl,
              scope,
              etag: parsedFeed.etag,
              lastModified: parsedFeed.lastModified,
              interactions: parsedFeed.interactions?.rawJson,
            );
            final decoded = cached == null
                ? null
                : _feedFromCachedBody(
                    cached,
                    feedFoundAtAccountAddress: feed.feedFoundAtAccountAddress,
                    feedTitle: feed.feedTitle,
                    interactions: parsedFeed.interactions,
                  );
            return (
              url: feed.feedUrl,
              posts: decoded?.posts ?? const <Post>[],
              locked: false,
              icon: decoded?.imageUrl,
            );
          }

          final posts = _enrichFeedPosts(feed.feedUrl, parsedFeed.posts);

          // 200 — store the new body + its validators. This is what makes the
          // NEXT open a 304.
          //
          // The write is fenced in its own try. A CACHE failure is not a FETCH
          // failure: we already hold fresh, parsed posts, and letting a write
          // error fall through to the catch below would hand the user the STALE
          // cached body instead — silently reverting reactions, scores, and new
          // posts to whatever the last good write held. Degrade the cache, never
          // the data. (This is exactly what the FeedCache 2067 bug did.)
          if (parsedFeed.rawBody != null) {
            try {
              await PublicOS.database
                  .upsertCachedFeed(db.FeedCacheCompanion.insert(
                feedUrl: feed.feedUrl,
                sessionAddress: scope,
                body: parsedFeed.rawBody!,
                contentType: Value(parsedFeed.contentType),
                etag: Value(parsedFeed.etag),
                lastModified: Value(parsedFeed.lastModified),
                fetchedAt: DateTime.now().millisecondsSinceEpoch,
                locked: const Value(false),
                // The counts ride with the body; a failed interactions call
                // keeps the last stored answer rather than erasing it.
                interactions: Value(
                    parsedFeed.interactions?.rawJson ?? cached?.interactions),
              ));
            } catch (e) {
              Log.e(_tag, 'Feed cache write failed ${feed.feedUrl}: $e');
            }
          }
          return (
            url: feed.feedUrl,
            posts: posts,
            locked: false,
            icon: _iconOf(parsedFeed.imageUrl),
          );
        } catch (e) {
          Log.e(_tag, 'Feed refresh failed ${feed.feedUrl}: $e');
          final msg = e.toString();
          // A REFUSAL is never transient: with the 401 filed as a blip,
          // the stale signed body would stay on screen after "Deny".
          final locked = isFeedRefusal(e);

          if (locked) {
            // Persist the verdict so the "some feeds are private" banner
            // survives a cold start instead of needing a live 403 to know.
            await PublicOS.database.upsertCachedFeed(db.FeedCacheCompanion.insert(
              feedUrl: feed.feedUrl,
              sessionAddress: scope,
              body: cached?.body ?? '',
              contentType: Value(cached?.contentType),
              etag: const Value(null),
              lastModified: const Value(null),
              fetchedAt: DateTime.now().millisecondsSinceEpoch,
              locked: const Value(true),
              lastError: Value(msg),
            ));
            return (
              url: feed.feedUrl,
              posts: <Post>[],
              locked: true,
              icon: null,
            );
          }

          // GONE is not transient either: the channel no longer exists, so in
          // a merged list it simply drops out
          // — its cached posts must not linger as if it were live.
          if (e is FeedGoneException) {
            return (
              url: feed.feedUrl,
              posts: <Post>[],
              locked: false,
              icon: null,
            );
          }

          // A transient failure must NOT blank a feed the user can already see.
          // Serve the cached copy and keep going — degrading to stale beats
          // degrading to empty.
          return (
            url: feed.feedUrl,
            posts: cached == null
                ? const <Post>[]
                : _postsFromCacheRow(cached, feed),
            locked: false,
            icon: null,
          );
        }
      });

      final results = await Future.wait(futures);
      final allPosts = <Post>[];
      final lockedFeedUrls = <String>{};
      final feedIcons = <String, String>{};
      for (final r in results) {
        allPosts.addAll(r.posts);
        if (r.locked) lockedFeedUrls.add(r.url);
        final icon = r.icon;
        if (icon != null) feedIcons[r.url] = icon;
      }
      allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final newCount =
          allPosts.where((p) => !seenKeys.contains(_postKey(p))).length;

      // Housekeeping. Cheap, and nothing else prunes this table.
      unawaited(PublicOS.database.evictStaleFeedCache());

      Log.d(_tag,
          'refreshPostsForFeeds: ${allPosts.length} posts, $newCount new, $notModified/${feeds.length} unchanged (304)');

      return RefreshedFeedList(
        posts: allPosts,
        newCount: newCount,
        lockedFeedUrls: lockedFeedUrls,
        notModifiedCount: notModified,
        feedIcons: feedIcons,
      );
    } catch (e) {
      Log.e(_tag, 'refreshPostsForFeeds error: $e');
      return RefreshedFeedList.empty();
    }
  }

  // ==========================================================================
  // SINGLE-FEED TWO-PHASE (single-flagged lists + the browser surface)
  // ==========================================================================
  //
  // A single-flagged list and a bare browser feed both render one feed via a
  // URL, not a list id — so they can't ride [getCachedPostsForFeeds] /
  // [refreshPostsForFeeds]. These are the one-feed analogues: the same cache
  // row, the same conditional GET, the same [RefreshedFeedList] contract, so
  // the caller reuses the identical cold / unchanged / new-while-reading
  // branch.

  /// **Phase 1 for a single feed, with feed-level metadata.** Whatever we last
  /// stored for [feedUrl], straight from disk — posts PLUS the description /
  /// stats / posting_policy the cached body always carried, so a single-feed
  /// surface can render its header offline.
  ///
  /// Null on a cold cache (never fetched) or an unreadable row. A locked
  /// (private) feed returns `locked: true` with no posts, so the caller can
  /// show its gate without waiting for a live 403.
  static Future<
      ({
        List<Post> posts,
        String? description,
        String? siteUrl,
        String? language,
        ChannelStats? stats,
        String? postingPolicy,
        bool? isPrivate,
        bool hasMore,
        bool locked,
        String? imageUrl,
      })?> getCachedFeed(
    String feedUrl, {
    String? feedFoundAtAccountAddress,
    String? feedTitle,
  }) async {
    final scope = _cacheScope;
    if (scope == null) return null;
    try {
      final rows = await PublicOS.database.getCachedFeeds([feedUrl], scope);
      if (rows.isEmpty) return null;
      final row = rows.first;
      if (row.locked) {
        return (
          posts: const <Post>[],
          description: null,
          siteUrl: null,
          language: null,
          stats: null,
          postingPolicy: null,
          isPrivate: true, // a locked verdict IS the privacy signal
          hasMore: false,
          locked: true,
          imageUrl: null,
        );
      }
      final decoded = _feedFromCachedBody(
        row,
        feedFoundAtAccountAddress: feedFoundAtAccountAddress,
        feedTitle: feedTitle,
      );
      if (decoded == null) return null;
      return (
        posts: decoded.posts,
        description: decoded.description,
        siteUrl: decoded.siteUrl,
        language: decoded.language,
        stats: decoded.stats,
        postingPolicy: decoded.postingPolicy,
        isPrivate: decoded.isPrivate,
        hasMore: decoded.hasMore,
        locked: false,
        imageUrl: decoded.imageUrl,
      );
    } catch (e) {
      Log.e(_tag, 'getCachedFeed error: $e');
      return null;
    }
  }

  /// **Phase 1 for a single feed.** Whatever we last stored for [feedUrl],
  /// straight from disk. Empty on a cold cache or a locked (private) feed.
  ///
  /// Posts-only view of [getCachedFeed] — kept with this exact signature for
  /// the publicos_desktop fork of posts_list.dart; new code that wants the
  /// feed header should call [getCachedFeed].
  static Future<List<Post>> getCachedPostsForFeed(
    String feedUrl, {
    String? feedFoundAtAccountAddress,
    String? feedTitle,
  }) async {
    final cached = await getCachedFeed(
      feedUrl,
      feedFoundAtAccountAddress: feedFoundAtAccountAddress,
      feedTitle: feedTitle,
    );
    if (cached == null || cached.locked) return const [];
    return cached.posts;
  }

  /// **Phase 2 for a single feed.** Conditional GET, rewrite the cache, report
  /// how many posts are new relative to the cached copy.
  ///
  /// Unlike [refreshPostsForFeeds] this **rethrows a transient failure** instead
  /// of swallowing it: with only one feed there is no partial result to salvage,
  /// and the single-feed caller needs the exception to tell "private feed" (a
  /// gate) from "fetch failed" (keep the stale copy). A private/locked verdict
  /// is returned in [RefreshedFeedList.lockedFeedUrls] rather than thrown, so a
  /// warm reader isn't kicked to the gate by a write.
  static Future<RefreshedFeedList> refreshPostsForFeed(
    String feedUrl, {
    String? feedFoundAtAccountAddress,
    String? feedTitle,
  }) async {
    final scope = _cacheScope;
    if (scope == null) return RefreshedFeedList.empty();

    final rows = await PublicOS.database.getCachedFeeds([feedUrl], scope);
    final cached = rows.isEmpty ? null : rows.first;

    // Baseline — what phase 1 would have shown, so newCount is measured off it.
    final seenKeys = <String>{};
    if (cached != null && !cached.locked) {
      for (final p in _postsFromCachedBody(
        cached,
        feedFoundAtAccountAddress: feedFoundAtAccountAddress,
        feedTitle: feedTitle,
      )) {
        seenKeys.add(_postKey(p));
      }
    }

    try {
      var parsedFeed = await RssParser.fetchFeed(
        feedUrl,
        feedFoundAtAccountAddress: feedFoundAtAccountAddress,
        feedTitle: feedTitle,
        etag: cached?.etag,
        lastModified: cached?.lastModified,
      ).timeout(
        _feedTimeout,
        onTimeout: () => throw Exception('Feed timeout: $feedUrl'),
      );
      // "Not modified" is only worth something if the body we hold reads.
      // When it does not (a reader newer than the writer), fetch it plain.
      if (parsedFeed.notModified &&
          cached != null &&
          _feedFromCachedBody(
                cached,
                feedFoundAtAccountAddress: feedFoundAtAccountAddress,
                feedTitle: feedTitle,
              ) ==
              null) {
        parsedFeed = await RssParser.fetchFeed(
          feedUrl,
          feedFoundAtAccountAddress: feedFoundAtAccountAddress,
          feedTitle: feedTitle,
        ).timeout(
          _feedTimeout,
          onTimeout: () => throw Exception('Feed timeout: $feedUrl'),
        );
      }
      // A body that does not read is a failed fetch, not a feed with an
      // error for a description; the catch below degrades or surfaces it.
      if (parsedFeed.isParseError) {
        throw FormatException(parsedFeed.parseError!);
      }

      List<Post> posts;
      String? description;
      String? siteUrl;
      String? language;
      ChannelStats? stats;
      String? postingPolicy;
      bool? isPrivate;
      String? imageUrl;
      var hasMore = false;
      var notModified = 0;
      if (parsedFeed.notModified) {
        // 304 — reuse the body we hold; just advance fetchedAt + validators.
        // The cached body carries the feed-level metadata too, so the header
        // survives a free round trip.
        notModified = 1;
        await PublicOS.database.touchCachedFeed(
          feedUrl,
          scope,
          etag: parsedFeed.etag,
          lastModified: parsedFeed.lastModified,
          interactions: parsedFeed.interactions?.rawJson,
        );
        final decoded = cached == null
            ? null
            : _feedFromCachedBody(
                cached,
                feedFoundAtAccountAddress: feedFoundAtAccountAddress,
                feedTitle: feedTitle,
                interactions: parsedFeed.interactions,
              );
        posts = decoded?.posts ?? const [];
        description = decoded?.description;
        siteUrl = decoded?.siteUrl;
        language = decoded?.language;
        stats = decoded?.stats;
        postingPolicy = decoded?.postingPolicy;
        isPrivate = decoded?.isPrivate;
        hasMore = decoded?.hasMore ?? false;
        imageUrl = decoded?.imageUrl;
      } else {
        posts = _enrichFeedPosts(feedUrl, parsedFeed.posts);
        final trimmedDescription = parsedFeed.description.trim();
        description =
            trimmedDescription.isEmpty ? null : trimmedDescription;
        siteUrl = parsedFeed.siteUrl;
        language = parsedFeed.language;
        stats = parsedFeed.stats;
        postingPolicy = parsedFeed.postingPolicy;
        isPrivate = parsedFeed.isPrivate;
        hasMore = parsedFeed.hasMore;
        imageUrl = _iconOf(parsedFeed.imageUrl);
        // 200 — store the new body + validators. Fenced: a cache-write failure
        // must not blank posts we already parsed (see refreshPostsForFeeds).
        if (parsedFeed.rawBody != null) {
          try {
            await PublicOS.database
                .upsertCachedFeed(db.FeedCacheCompanion.insert(
              feedUrl: feedUrl,
              sessionAddress: scope,
              body: parsedFeed.rawBody!,
              contentType: Value(parsedFeed.contentType),
              etag: Value(parsedFeed.etag),
              lastModified: Value(parsedFeed.lastModified),
              fetchedAt: DateTime.now().millisecondsSinceEpoch,
              locked: const Value(false),
              // The counts ride with the body; a failed interactions call
              // keeps the last stored answer rather than erasing it.
              interactions: Value(
                  parsedFeed.interactions?.rawJson ?? cached?.interactions),
            ));
          } catch (e) {
            Log.e(_tag, 'Feed cache write failed $feedUrl: $e');
          }
        }
      }

      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final newCount =
          posts.where((p) => !seenKeys.contains(_postKey(p))).length;
      unawaited(PublicOS.database.evictStaleFeedCache());

      Log.d(_tag,
          'refreshPostsForFeed($feedUrl): ${posts.length} posts, $newCount new, $notModified unchanged (304)');

      return RefreshedFeedList(
        posts: posts,
        newCount: newCount,
        lockedFeedUrls: const {},
        notModifiedCount: notModified,
        feedIcons: imageUrl == null ? const {} : {feedUrl: imageUrl},
        description: description,
        siteUrl: siteUrl,
        language: language,
        stats: stats,
        postingPolicy: postingPolicy,
        isPrivate: isPrivate,
        // Per reader and never cached: read off this round trip's
        // interactions answer, which a 304 carries too.
        canPost: parsedFeed.canPost ?? parsedFeed.interactions?.canPost,
        hasMore: hasMore,
      );
    } catch (e) {
      final msg = e.toString();
      if (isFeedRefusal(e)) {
        // A REFUSAL is never transient: persist the verdict so the gate
        // survives a cold start, then hand the TYPED exception up — the
        // single-feed surface renders the right lock from it (the object
        // on a FeedGateException, the ask/lock on a FeedSigninRequired).
        // Returning `lockedFeedUrls` here would erase the code, and a 401
        // after "Deny" filed as a blip would leave the stale SIGNED body
        // on screen.
        await PublicOS.database.upsertCachedFeed(db.FeedCacheCompanion.insert(
          feedUrl: feedUrl,
          sessionAddress: scope,
          body: cached?.body ?? '',
          contentType: Value(cached?.contentType),
          etag: const Value(null),
          lastModified: const Value(null),
          fetchedAt: DateTime.now().millisecondsSinceEpoch,
          locked: const Value(true),
          lastError: Value(msg),
        ));
        rethrow;
      }
      // Transient — hand it to the caller so it can keep the cached copy (warm)
      // or surface the error (cold).
      rethrow;
    }
  }

  /// A read-gate REFUSAL, as opposed to a transient failure. Refusals must
  /// never keep a stale cached body on screen: the typed ones
  /// ([FeedGateException] incl. [PaywallException], [FeedSigninRequired]) and
  /// the string-protocol codes an older path may still throw.
  static bool isFeedRefusal(Object e) {
    if (e is FeedGateException || e is FeedSigninRequired) return true;
    final msg = e.toString();
    return kFeedRefusalCodes.any((c) => msg.contains('FEED_ERROR:$c')) ||
        msg.contains('FEED_ERROR:HTTP_403');
  }

  /// **Direct, uncached fetch** of one feed with optional server-side sort /
  /// pagination query params (only the bare
  /// first-page default-sort fetch rides the cache; deeper pages and
  /// non-default sorts go straight to the server, every time).
  ///
  /// The params are plain query parameters merged into the URL — a server
  /// that doesn't understand them ignores them, so this needs no URL-shape
  /// detection. **Server order is preserved** (no date re-sort): for
  /// `sort=top/hot/controversial` the order IS the payload.
  ///
  /// Throws on failure (including `FEED_ERROR:PRIVATE_FEED` etc.) — a direct
  /// fetch has no cached copy to degrade to; the caller decides.
  static Future<RefreshedFeedList> fetchPostsForFeed(
    String feedUrl, {
    String? sort,
    int? limit,
    int? offset,
    String? feedFoundAtAccountAddress,
    String? feedTitle,
  }) async {
    final uri = Uri.parse(feedUrl);
    final params = Map<String, String>.from(uri.queryParameters);
    if (sort != null) params['sort'] = sort;
    if (limit != null) params['limit'] = '$limit';
    if (offset != null) params['offset'] = '$offset';
    final url =
        uri.replace(queryParameters: params.isEmpty ? null : params).toString();

    final parsed = await RssParser.fetchFeed(
      url,
      feedFoundAtAccountAddress: feedFoundAtAccountAddress,
      feedTitle: feedTitle,
    ).timeout(
      _feedTimeout,
      onTimeout: () => throw Exception('Feed timeout: $feedUrl'),
    );

    // Enrichment is keyed on the ORIGINAL url so the stamped owner/slug and
    // commentsUrl match what the cached path produces for the same feed.
    final posts = _enrichFeedPosts(feedUrl, parsed.posts);
    final description = parsed.description.trim();
    return RefreshedFeedList(
      posts: posts,
      newCount: 0,
      lockedFeedUrls: const {},
      notModifiedCount: 0,
      description: description.isEmpty ? null : description,
      siteUrl: parsed.siteUrl,
      language: parsed.language,
      stats: parsed.stats,
      postingPolicy: parsed.postingPolicy,
      isPrivate: parsed.isPrivate,
      hasMore: parsed.hasMore,
      channel: parsed.channel,
    );
  }

  // ==========================================================================
  // BOOKMARKED POSTS (user-side "save for later")
  // ==========================================================================

  /// Get all bookmarked posts for the current user, newest first.
  static Future<List<db.BookmarkedPost>> getBookmarkedPosts() async {
    if (PublicOS.sessionBlockchainAddress == null) return [];
    try {
      return await PublicOS.database.getBookmarkedPosts(
        PublicOS.sessionBlockchainAddress!,
      );
    } catch (e) {
      Log.e(_tag, 'getBookmarkedPosts error: $e');
      return [];
    }
  }

  /// Insert or update a bookmarked post snapshot.
  static Future<void> upsertBookmarkedPost(
      db.BookmarkedPostsCompanion companion) async {
    try {
      await PublicOS.database.upsertBookmarkedPost(companion);
    } catch (e) {
      Log.e(_tag, 'upsertBookmarkedPost error: $e');
      rethrow;
    }
  }

  /// Delete a bookmarked post by UID + feed URL.
  static Future<bool> deleteBookmarkedPost(String postUid,
      {String? feedUrl}) async {
    if (PublicOS.sessionBlockchainAddress == null) return false;
    try {
      final deleted = await PublicOS.database.deleteBookmarkedPost(
        postUid,
        feedUrl,
        PublicOS.sessionBlockchainAddress!,
      );
      return deleted > 0;
    } catch (e) {
      Log.e(_tag, 'deleteBookmarkedPost error: $e');
      return false;
    }
  }

  /// Refresh one bookmarked post from its server — the phase-2 primitive.
  /// Fetches the current item
  /// via [PublicOSChannels.getPost], merges it over the stored blob (server
  /// truth for content/counts/policies; STORED truth for the provenance the
  /// server cannot know — `feedFoundAtAccountAddress`, `feedTitle`,
  /// `feedUrl`, `isForumChannel`), writes the row back with a fresh
  /// `updatedAt`, and returns the merged post.
  ///
  /// Sends the stored `etag` as `If-None-Match`, so the steady state of the
  /// sweep is a 304 per unchanged post — no body, no re-parse, no blob write.
  ///
  /// Verdicts:
  ///  - 304 Not Modified → the stored copy is byte-current: `updatedAt`
  ///    bumped, `unavailable` cleared, stored post returned as-is.
  ///  - success (200) → blob + new etag written, `unavailable` cleared,
  ///    merged Post returned.
  ///  - server says GONE (`POST_NOT_FOUND` / `CHANNEL_NOT_FOUND` /
  ///    `ACCOUNT_NOT_FOUND`) → `unavailable` set, blob UNTOUCHED (the local
  ///    copy may be the only copy left), `updatedAt` bumped so the retry
  ///    backs off to the slow cadence; returns null.
  ///  - transport failure → row untouched entirely (a flaky network must
  ///    never mark a post lost); returns null.
  ///  - external/RSS bookmark (no uid / no channel coordinates) → nothing to
  ///    refresh against; returns null without touching the row.
  static Future<Post?> refreshBookmarkedPost(db.BookmarkedPost row) async {
    // ⚠ The write-back scope comes from the ROW, never from ambient identity.
    // The client app keys bookmark rows by the ACCOUNT address
    // (AppStateNotifier.currentMyContact.publicosAddress) while
    // `PublicOS.sessionBlockchainAddress` is the session EOA — two different
    // addresses. Resolving the scope here instead of reading the row's own
    // value would make every write-back a silent 0-row UPDATE.
    final sessionAddr = row.sessionAddress;

    Post stored;
    try {
      stored = Post.fromJson(jsonDecode(row.postJson) as Map<String, dynamic>);
    } catch (e) {
      Log.e(_tag, 'refreshBookmark ${row.postUid}: unreadable blob: $e');
      return null;
    }
    // The post's own permalink names its server. Posts read through feeds
    // and lists never carry `serverAddress`, and `getPost` with a null
    // server asks the READER's SSP, so a bookmark from another SSP would
    // come back ACCOUNT_NOT_FOUND and get flagged gone. Coordinates stay as
    // the fallback for a blob with no permalink.
    final permalink = stored.url;
    final FeedServerApiResponse<Post> resp;
    if (permalink != null && postRefOf(permalink) != null) {
      resp = await PublicOSChannels.getPostByUrl(permalink,
          ifNoneMatch: row.etag);
    } else {
      final owner = stored.channelOwnerAddress;
      final slug = stored.channelSlug;
      if (owner == null || slug == null || stored.uid.isEmpty) {
        Log.w(_tag,
            'refreshBookmark ${row.postUid}: no permalink and no channel '
            'coordinates in blob (owner=$owner slug=$slug uid=${stored.uid}) '
            '— cannot refresh');
        return null;
      }
      resp = await PublicOSChannels.getPost(
        ownerAddress: owner,
        slug: slug,
        postUid: stored.uid,
        serverAddress: stored.serverAddress,
        ifNoneMatch: row.etag,
      );
    }
    final now = DateTime.now().millisecondsSinceEpoch;

    if (resp.notModified) {
      Log.i(_tag, 'refreshBookmark ${row.postUid}: 304 byte-current');
      // Byte-current — bump the sweep anchor, nothing else to write.
      final n = await PublicOS.database.updateBookmarkedPostRefresh(
        postUid: row.postUid,
        feedUrl: row.feedUrl,
        sessionAddr: sessionAddr,
        updatedAt: now,
        unavailable: false,
      );
      if (n == 0) {
        Log.e(_tag, 'refreshBookmark ${row.postUid}: 304 write matched 0 rows');
      }
      return stored;
    }

    if (resp.success && resp.data != null) {
      Log.i(_tag,
          'refreshBookmark ${row.postUid}: 200 — comments=${resp.data!.commentsCount} '
          'reactions=${resp.data!.reactions} etag=${resp.etag}');
      final merged = resp.data!.copyWith(
        feedFoundAtAccountAddress: stored.feedFoundAtAccountAddress,
        feedRecordKey: stored.feedRecordKey,
        feedTitle: stored.feedTitle,
        feedUrl: stored.feedUrl,
        isForumChannel: stored.isForumChannel,
      );
      final n = await PublicOS.database.updateBookmarkedPostRefresh(
        postUid: row.postUid,
        feedUrl: row.feedUrl,
        sessionAddr: sessionAddr,
        postJson: jsonEncode(merged.toJson()),
        etag: resp.etag,
        updatedAt: now,
        unavailable: false,
      );
      if (n == 0) {
        Log.e(_tag, 'refreshBookmark ${row.postUid}: blob write matched 0 rows');
      }
      return merged;
    }

    final code = resp.error?['code'];
    if (code == 'POST_NOT_FOUND' ||
        code == 'CHANNEL_NOT_FOUND' ||
        code == 'ACCOUNT_NOT_FOUND') {
      Log.w(_tag, 'refreshBookmark ${row.postUid}: GONE ($code) — flagged');
      await PublicOS.database.updateBookmarkedPostRefresh(
        postUid: row.postUid,
        feedUrl: row.feedUrl,
        sessionAddr: sessionAddr,
        postJson: null,
        updatedAt: now,
        unavailable: true,
      );
    } else {
      Log.w(_tag,
          'refreshBookmark ${row.postUid}: failed transiently — '
          'code=$code msg=${resp.error?['message']}');
    }
    return null;
  }

  /// Check if a post is bookmarked.
  static Future<bool> isPostBookmarked(String postUid,
      {String? feedUrl}) async {
    if (PublicOS.sessionBlockchainAddress == null) return false;
    try {
      return await PublicOS.database.isPostBookmarked(
        postUid,
        feedUrl,
        PublicOS.sessionBlockchainAddress!,
      );
    } catch (e) {
      Log.e(_tag, 'isPostBookmarked error: $e');
      return false;
    }
  }

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  /// Extract base server URL from a full URL (scheme + host + optional port).
  static String _extractServerUrl(String url) {
    final uri = Uri.parse(url);
    final port = (uri.port == 80 || uri.port == 443) ? '' : ':${uri.port}';
    return '${uri.scheme}://${uri.host}$port';
  }
}
