import 'dart:async';

import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:publicos_core/src/core/publicos_core.dart';
import 'package:publicos_core/src/core/extensions/publicos_contacts.dart';
import 'package:publicos_core/src/core/extensions/publicos_feed_lists.dart';
import 'package:publicos_core/src/models/contact.dart';
import 'package:publicos_core/src/models/feed_server/feed_server_models.dart';
import 'package:publicos_core/src/models/record_model.dart';
import 'package:publicos_core/src/utils/log.dart';

/// One channel a followed account publishes on its profile. Any feed type —
/// PublicOS-hosted OR external RSS/Atom.
///
/// **Two keys, deliberately — they answer different questions.**
///
/// [key] (the owner's `record.key`) is the channel's stable IDENTITY: it
/// survives the author re-pointing the channel at a new URL or renaming it.
/// Everything that must outlive a change of address is anchored here — mutes,
/// and the `list_feeds.feedRecordKey` follow anchor. It is scoped to the owner,
/// so identity is really the pair (accountAddress, key).
///
/// [feedUrl] is where the channel LIVES RIGHT NOW, and it is what the render
/// path dedupes on: two different follows that resolve to the same URL are one
/// feed on screen. A URL is globally comparable; a `record.key` is not (two
/// accounts can both call a channel `newsletter`), so the URL is the only
/// sound dedupe key across account-origin and raw-URL items.
///
/// Do not collapse these into one. Anchoring mutes on the URL strands them on
/// a re-point; deduping on the key merges unrelated channels.
class ResolvedChannel {
  /// eip55With0x — the followed account.
  final String accountAddress;

  /// The owner's `record.key` — stable identity. With [accountAddress], the
  /// mute key.
  final String key;

  /// `record.value`, verbatim — where it lives now. The dedupe key. Never
  /// parsed.
  final String feedUrl;

  /// `record.metadata['name']` — display only.
  final String? title;

  const ResolvedChannel({
    required this.accountAddress,
    required this.key,
    required this.feedUrl,
    this.title,
  });
}

/// Where a feed in a merged list came from — drives the post overflow verb:
/// `account` shows "Mute channel", `single` shows "Remove from list".
enum FeedOrigin { account, single }

/// A feed in a merged list view. Carries its origin so the UI can pick the
/// right verb, and the two identifiers a mute needs.
class FollowedFeed {
  /// The identity + the mute/dedupe key.
  final String feedUrl;
  final FeedOrigin origin;

  /// eip55 — set iff [origin] == account. With [recordKey], the mute key.
  final String? accountAddress;

  /// The router `record.key` of the channel tab this feed was found on.
  /// Account origin: always set — muting needs THIS, not [feedUrl], so a mute
  /// survives the author re-pointing the channel. Single origin: the stored
  /// `ListFeeds.feedRecordKey`, set when the feed was followed from a profile
  /// tab (null for pasted feeds). Paired with [feedFoundAtAccountAddress] it
  /// names the tab to land on (post "Go to feed").
  final String? recordKey;
  final String? title;

  /// set iff [origin] == single — `removeFeedFromList` needs it.
  final int? listFeedId;

  /// Provenance for "via X" post attribution when this feed is fetched. For an
  /// account-origin feed it IS [accountAddress]; for a single-origin feed it is
  /// whatever was stamped on the `list_feeds` row at follow time (nullable).
  /// Fetching + signing never read this — it drives display attribution only.
  final String? feedFoundAtAccountAddress;

  const FollowedFeed({
    required this.feedUrl,
    required this.origin,
    this.accountAddress,
    this.recordKey,
    this.title,
    this.listFeedId,
    this.feedFoundAtAccountAddress,
  });
}

/// [PublicOSFollows.resolveListFeedsDetailed]'s answer: the rows to render
/// ([live], re-pointed where the owner moved them) and the channel follows the
/// owner has deleted ([gone], as stored).
class ResolvedListFeeds {
  final List<ListFeed> live;
  final List<ListFeed> gone;

  const ResolvedListFeeds({required this.live, required this.gone});
}

/// Account-based follow: a follow is a stored *account*, not a stored set of
/// feeds. The feed set is DERIVED at read time from the account's profile
/// (its `RecordType.router` records of subtype `channel`) and merged with the
/// feeds stored directly on the same list.
///
/// Follows are scoped PER LIST — an account is a member of a list, not a
/// global subscription — so this machinery serves every list, not one special
/// one.
extension PublicOSFollows on PublicOS {
  static const _tag = 'Follows';

  /// How long a stored profile snapshot is trusted before we re-read the chain.
  /// The channel SET moves at human speed (an author enlists a new channel
  /// maybe monthly); the feed BODIES move fast and are revalidated separately
  /// by FeedCache's conditional GET. Do not conflate the two.
  static const Duration channelSetMaxAge = Duration(hours: 12);

  /// The channels [account] publishes ON THEIR PROFILE, from the local contact,
  /// refreshing from chain when the snapshot is stale.
  ///
  /// The explicit [PublicOSContacts.saveContact] is NOT redundant: `fetchContact`
  /// write-through is SELF-ONLY (publicos_contacts.dart:388-391). Without this
  /// line the stored `updatedAt` never bumps for a followed account, every read
  /// judges it stale, and the 12h gate degrades into a chain read per account
  /// per view. This is the pattern `getContact`'s own doc prescribes.
  static Future<List<ResolvedChannel>> resolveProfileChannels(
      EthereumAddress account) async {
    var contact = await PublicOSContacts.getContact(account);

    if (_isStale(contact)) {
      try {
        // requireRecords: the whole point of this refresh is the channel SET.
        // Without it a failed read returns records:[] silently, we'd persist
        // that as fact, stamp updatedAt fresh, and blank this account's
        // channels for channelSetMaxAge — while the catch below (written for
        // exactly this case) never fired. See gotchas: empty ≠ unreachable.
        final fresh = await PublicOSContacts.fetchContact(account,
            requireRecords: true);
        await PublicOSContacts.saveContact(fresh); // ← the write-through
        contact = fresh;
      } catch (e) {
        // Offline / RPC down. Fall back to the stale copy — a day-old channel
        // list beats an empty feed. Only give up if we have nothing.
        Log.w(_tag, '[RESOLVE] refresh failed for $account, using cache: $e');
        if (contact == null) return const [];
      }
    }
    if (contact == null) return const [];

    final owner = account.eip55With0x;
    return contact.records
        .where((r) =>
            r.type == RecordType.router &&
            r.routerSubtype == RouterSubtype.channel) // NOT `tab ||`
        .map((r) => _toResolved(owner, r))
        .whereType<ResolvedChannel>()
        .toList();
  }

  static bool _isStale(Contact? c) =>
      c == null ||
      c.updatedAt == null || // model is DateTime?, DB column is not — null-check
      DateTime.now().difference(c.updatedAt!) > channelSetMaxAge;

  /// `record.value` IS the feed URL (browser.dart:4002). We do NOT parse it.
  /// Every enlisted channel — PublicOS-hosted `/json` `/rss` `/atom`, OR a plain
  /// external RSS/Atom link — is kept, identified by its whole url. No segment
  /// contract, no slug, no dropped-because-external branch. The url is the key,
  /// so a mute placed from a Post (post.feedUrl) matches a channel resolved from
  /// a profile trivially: same string.
  static ResolvedChannel? _toResolved(String owner, Record r) {
    if (r.value.isEmpty) return null; // only guard: a record with no url isn't a feed
    return ResolvedChannel(
      accountAddress: owner, // eip55 (the followed account), not derived from the url
      key: r.key, // stable identity — survives a re-point/rename
      feedUrl: r.value,
      title: r.metadata['name'] as String?,
    );
  }

  /// Re-resolve a list's stored rows against their owners' current records.
  ///
  /// A row with a `feedRecordKey` is a CHANNEL FOLLOW: the URL on the row is
  /// just where the channel lived when it was followed. The owner may have
  /// re-pointed it since, so the row's URL is refreshed from
  /// `(feedFoundAtAccountAddress, feedRecordKey)`. A row without a key is a raw
  /// URL snapshot and is returned verbatim — that is the whole difference
  /// between the two kinds.
  ///
  /// A channel the owner has DELETED resolves to nothing and is dropped here.
  /// A caller that must SHOW the absence (a single follow → "Channel not
  /// found") uses [resolveListFeedsDetailed], which returns the dropped rows
  /// too. This is only honest because the read underneath throws on failure
  /// rather than returning an empty record set (see
  /// `fetchContact(requireRecords:)`) — otherwise an RPC blip would look
  /// exactly like "the author deleted it".
  ///
  /// Owners are resolved ONCE each, not once per row, so a list holding five
  /// channels from the same account costs one profile read.
  static Future<List<ListFeed>> resolveListFeeds(List<ListFeed> rows) async =>
      (await resolveListFeedsDetailed(rows)).live;

  /// [resolveListFeeds], plus the rows it drops: [ResolvedListFeeds.gone]
  /// holds every channel follow whose owner is readable and no longer lists
  /// its `record.key` — deleted by the owner. Gone
  /// rows are returned as STORED (last known URL + title), never re-pointed.
  static Future<ResolvedListFeeds> resolveListFeedsDetailed(
      List<ListFeed> rows) async {
    final tracked = rows
        .where((r) => (r.feedRecordKey?.isNotEmpty ?? false))
        .where((r) => (r.feedFoundAtAccountAddress?.isNotEmpty ?? false))
        .toList();
    if (tracked.isEmpty) return ResolvedListFeeds(live: rows, gone: const []);

    final owners = tracked.map((r) => r.feedFoundAtAccountAddress!).toSet();
    final byOwner = <String, Map<String, ResolvedChannel>>{};
    await Future.wait(owners.map((owner) async {
      try {
        final channels =
            await resolveProfileChannels(EthereumAddress.fromHex(owner));
        byOwner[owner] = {for (final c in channels) c.key: c};
      } catch (e) {
        // Unresolvable owner (bad address). Leave it absent — rows fall
        // through to their stored URL below rather than vanishing.
        Log.w(_tag, '[RESOLVE] owner $owner failed: $e');
      }
    }));

    final out = <ListFeed>[];
    final gone = <ListFeed>[];
    for (final r in rows) {
      final key = r.feedRecordKey;
      final owner = r.feedFoundAtAccountAddress;
      if (key == null || key.isEmpty || owner == null || owner.isEmpty) {
        out.add(r); // raw URL snapshot — untouched
        continue;
      }
      final resolvedOwner = byOwner[owner];
      if (resolvedOwner == null) {
        out.add(r); // owner unreadable — keep the last known URL
        continue;
      }
      final channel = resolvedOwner[key];
      if (channel == null) {
        gone.add(r); // the owner deleted this channel — out of the live set
        continue;
      }
      out.add(channel.feedUrl == r.feedUrl
          ? r
          : r.copyWith(
              feedUrl: channel.feedUrl,
              feedTitle: channel.title ?? r.feedTitle,
            ));
    }
    return ResolvedListFeeds(live: out, gone: gone);
  }

  /// The feed set ANY list renders: its stored feeds UNION the channels of
  /// every account followed IN THAT LIST, minus that list's mutes.
  ///
  /// There is no "Following list" special case — a list with zero followed
  /// accounts reduces naturally to its stored feeds, which is exactly what a
  /// plain list is.
  ///
  /// Deliberately returns FEEDS, not posts. Fetching + caching is not this
  /// method's concern; the caller hands these URLs
  /// to the existing refresh path exactly like any list.
  static Future<List<FollowedFeed>> resolveListItems(int listId) async {
    final session = PublicOS.sessionBlockchainAddress;
    if (session == null) return const [];

    // ── direct half: the list's own stored feeds, each re-resolved if it is a
    // channel follow (has a feedRecordKey) rather than a raw URL snapshot.
    final direct =
        await resolveListFeeds(await PublicOSFeedLists.getFeedsInList(listId));

    // ── account half, SCOPED TO THIS LIST. One query for every mute, not one
    // per account. This scoping is what ungates the whole thing: the merge was
    // always list-agnostic, these two reads were the only global ones.
    final follows = await PublicOS.database
        .listFollowedAccounts(session: session, listId: listId);
    final mutes = await PublicOS.database
        .allMutedKeys(session: session, listId: listId); // acct -> {record.key}

    // Resolved concurrently: each is an independent local read that MAY fall
    // through to a chain refresh. Serial would make N stale accounts an N×RPC
    // stall on the feed view.
    final resolved = await Future.wait(follows.map(
        (f) => resolveProfileChannels(EthereumAddress.fromHex(f.accountAddress))));

    // ── merge. Account-origin wins on collision, so seed the map with the
    // account half and let the direct half only fill gaps. That single ordering
    // IS the dedupe rule — it decides the verb the post menu shows.
    //
    // Note the two keys doing different jobs (see [ResolvedChannel]): the map
    // dedupes on the CURRENT URL, the mute subtract matches on the STABLE
    // record.key. Muting survives the author re-pointing the channel; deduping
    // still collapses two follows that land on the same feed.
    final out = <String, FollowedFeed>{};

    for (final channels in resolved) {
      for (final c in channels) {
        if (mutes[c.accountAddress]?.contains(c.key) == true) {
          continue; // subtract by (account, record.key)
        }
        out[c.feedUrl] = FollowedFeed(
          feedUrl: c.feedUrl,
          origin: FeedOrigin.account,
          accountAddress: c.accountAddress,
          recordKey: c.key,
          title: c.title,
          feedFoundAtAccountAddress: c.accountAddress, // provenance = the account
        );
      }
    }

    for (final f in direct) {
      if (out.containsKey(f.feedUrl)) continue; // account-origin wins
      out[f.feedUrl] = FollowedFeed(
        feedUrl: f.feedUrl,
        origin: FeedOrigin.single,
        title: f.feedTitle,
        listFeedId: f.id,
        recordKey: f.feedRecordKey,
        feedFoundAtAccountAddress: f.feedFoundAtAccountAddress,
      );
    }

    return out.values.toList();
  }

  /// Reshape one merged [FollowedFeed] into the [ListFeed] the two-phase loaders
  /// ([PublicOSFeedLists.getCachedPostsForFeeds] /
  /// [PublicOSFeedLists.refreshPostsForFeeds]) consume. **Pure — no I/O**; the
  /// merge/dedupe/mute-subtract already happened in [resolveListItems]. The
  /// caller resolves ONCE and maps, keeping the origin-tagged [FollowedFeed]s
  /// around for the post "Mute channel" verb (which needs `accountAddress`).
  ///
  /// Account-origin channels have no `list_feeds` row, so `id` is -1. The
  /// loaders never read `id`/`listId` (only `feedUrl` / `feedTitle` /
  /// `feedFoundAtAccountAddress`), and the client's per-row "remove from list"
  /// already treats `id == -1` as "not a list feed". `addedAt` is a throwaway
  /// (unused downstream) and epoch-0 to keep this clock-free / pure.
  static ListFeed followedFeedToListFeed(FollowedFeed f, int listId) =>
      ListFeed(
        id: f.listFeedId ?? -1,
        listId: listId,
        feedUrl: f.feedUrl,
        feedTitle: f.title,
        feedFoundAtAccountAddress: f.feedFoundAtAccountAddress,
        feedRecordKey: f.recordKey,
        addedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
}
