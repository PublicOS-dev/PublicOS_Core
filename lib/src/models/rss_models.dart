import 'dart:convert' show jsonEncode;

import 'package:publicos_core/src/models/feed_server/feed_server_models.dart';
import 'package:publicos_core/src/models/post.dart';

/// Parsed feed result - unified for all feed formats (PublicOS Feed, JSON
/// Feed, RSS, Atom)
class ParsedFeed {
  final String title;
  final String description;

  /// ⚠ Legacy: the website for RSS 2.0, but the FEED URL itself for JSON Feed
  /// and Atom. Use [siteUrl] for "the website".
  final String link;
  final String? imageUrl;

  /// ⚠ Always the parse time — no format's feed date is read. The newest
  /// post's date is the honest "last updated".
  final DateTime lastUpdated;
  final List<Post> posts;

  /// The website this feed belongs to, as the feed declares it: RSS `<link>`,
  /// Atom `<link rel="alternate">` (or a rel-less `<link>`), JSON Feed
  /// `home_page_url`. Null when the feed declares none (never the feed URL).
  final String? siteUrl;

  /// The language the feed DECLARES (unverified): RSS `<language>` /
  /// `<dc:language>`, Atom `xml:lang` on `<feed>`, JSON Feed `language`,
  /// PublicOS Feed `channel.language`. Null when undeclared.
  final String? language;

  /// The document's `version` string. [feedV1] for a PublicOS Feed; the JSON
  /// Feed version for a JSON Feed; null for RSS/Atom.
  final String? version;

  /// Channel-level read stats, from the interactions call's `channel.stats`.
  /// Null for the open web, opted-out channels, and channels nobody has read:
  /// absent means *not measured*, never zero.
  final ChannelStats? stats;

  /// `channel.posting` — `'open'` marks a forum channel. Null for the open web.
  final String? postingPolicy;

  /// `channel.access.private` — true when this is a private channel the
  /// (approved) reader is seeing. Drives the composer's media door. Null for
  /// the open web.
  final bool? isPrivate;

  /// The channel says it carries mature or sensitive content
  /// (`channel.sensitive`). Null for the open web.
  final bool? sensitive;

  /// `channel.tags`. Null when the channel has none or for the open web.
  final List<String>? tags;

  /// The server has more posts beyond this page (`next_url` present). False
  /// for the open web and unpaginated bodies.
  final bool hasMore;

  /// The next page (`next_url`), when there is one.
  final String? nextUrl;

  /// Total posts the reader may see, when the server said (`total`).
  final int? total;

  /// The page's interactions call (`interactions_url`). Null for the open web
  /// and for a document of copies (then each item carries its own).
  final String? interactionsUrl;

  /// Whether THIS reader may post in the channel (signed interactions only).
  /// Null = not asked.
  final bool? canPost;

  /// The interactions answer merged into [posts] (counts, the reader's own
  /// facts). Also carried on a `304` result, where there are no posts to merge
  /// into: the caller re-parses the cached body and applies them with
  /// [withInteractions]. Never cached locally.
  final FeedInteractions? interactions;

  /// The channel as the document describes it, built from `channel` and, on a
  /// signed interactions call, the reader's own `follow_status` and
  /// `subscription`. Null on a non-PublicOS feed; null means UNKNOWN, never
  /// "public / free".
  final Channel? channel;

  // ── HTTP cache metadata ─────────────────────────
  //
  // Additive and optional: a caller that passes no validators can never receive
  // [notModified], so every existing call site behaves exactly as before.

  /// True when the server answered `304 Not Modified` — the body we already
  /// hold is still current, so nothing was downloaded and [posts] is empty.
  ///
  /// **Callers must branch on this before reading [posts].** An empty post list
  /// on a 304 means "unchanged", NOT "the feed is empty" — treating them the
  /// same would silently blank a healthy feed on every successful revalidation.
  final bool notModified;

  /// The raw response body, for the caller to cache. Null on a 304 (there was
  /// no body) and null when the caller never asked to cache.
  final String? rawBody;
  final String? contentType;

  /// Set when the body could not be read as a feed at all (the parser's
  /// catch): the message. Such a feed has no posts and must never be shown
  /// or cached as if it were one; the cache treats it as "no cache" and a
  /// fetch treats it as a failure. Null on every real document.
  final String? parseError;

  bool get isParseError => parseError != null;

  /// Validators to store and echo back on the next fetch. A server that sends
  /// neither leaves both null, and we simply re-download next time — exactly
  /// today's behaviour.
  final String? etag;
  final String? lastModified;

  /// The PublicOS Feed version this reader speaks.
  static const feedV1 = 'https://publicos.dev/feed/1';

  bool get isFeedV1 => version == feedV1;

  ParsedFeed({
    required this.title,
    required this.description,
    required this.link,
    this.imageUrl,
    required this.lastUpdated,
    required this.posts,
    this.siteUrl,
    this.language,
    this.version,
    this.stats,
    this.postingPolicy,
    this.isPrivate,
    this.sensitive,
    this.tags,
    this.hasMore = false,
    this.nextUrl,
    this.total,
    this.interactionsUrl,
    this.canPost,
    this.interactions,
    this.channel,
    this.notModified = false,
    this.rawBody,
    this.contentType,
    this.parseError,
    this.etag,
    this.lastModified,
  });

  /// A `304 Not Modified` result: no body, no posts, only the (possibly
  /// refreshed) validators, plus the page's interactions when the feed is a
  /// PublicOS channel (counts are never cached, so they are fetched anew).
  factory ParsedFeed.notModifiedResult({
    String? etag,
    String? lastModified,
    FeedInteractions? interactions,
  }) =>
      ParsedFeed(
        title: '',
        description: '',
        link: '',
        lastUpdated: DateTime.now(),
        posts: const [],
        notModified: true,
        etag: etag,
        lastModified: lastModified,
        interactions: interactions,
      );

  ParsedFeed copyWith({
    String? title,
    String? description,
    String? link,
    String? imageUrl,
    DateTime? lastUpdated,
    List<Post>? posts,
    String? siteUrl,
    String? language,
    String? version,
    ChannelStats? stats,
    String? postingPolicy,
    bool? isPrivate,
    bool? sensitive,
    List<String>? tags,
    bool? hasMore,
    String? nextUrl,
    int? total,
    String? interactionsUrl,
    bool? canPost,
    FeedInteractions? interactions,
    Channel? channel,
    bool? notModified,
    String? rawBody,
    String? contentType,
    String? etag,
    String? lastModified,
  }) =>
      ParsedFeed(
        title: title ?? this.title,
        description: description ?? this.description,
        link: link ?? this.link,
        imageUrl: imageUrl ?? this.imageUrl,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        posts: posts ?? this.posts,
        siteUrl: siteUrl ?? this.siteUrl,
        language: language ?? this.language,
        version: version ?? this.version,
        stats: stats ?? this.stats,
        postingPolicy: postingPolicy ?? this.postingPolicy,
        isPrivate: isPrivate ?? this.isPrivate,
        sensitive: sensitive ?? this.sensitive,
        tags: tags ?? this.tags,
        hasMore: hasMore ?? this.hasMore,
        nextUrl: nextUrl ?? this.nextUrl,
        total: total ?? this.total,
        interactionsUrl: interactionsUrl ?? this.interactionsUrl,
        canPost: canPost ?? this.canPost,
        interactions: interactions ?? this.interactions,
        channel: channel ?? this.channel,
        notModified: notModified ?? this.notModified,
        rawBody: rawBody ?? this.rawBody,
        contentType: contentType ?? this.contentType,
        etag: etag ?? this.etag,
        lastModified: lastModified ?? this.lastModified,
        parseError: parseError,
      );

  ParsedFeed copyWithHttp({
    String? rawBody,
    String? contentType,
    String? etag,
    String? lastModified,
  }) =>
      copyWith(
        rawBody: rawBody,
        contentType: contentType,
        etag: etag,
        lastModified: lastModified,
      );

  /// The interactions answer merged in: each post's counts and the reader's
  /// own facts by `id` (a post with no entry stays as parsed: not measured,
  /// never zero), the channel's stats, and, on a signed answer, the reader's
  /// standing on the channel.
  ParsedFeed withInteractions(FeedInteractions ix) {
    final merged = [
      for (final p in posts)
        ix.items[p.uid] == null ? p : ix.items[p.uid]!.applyTo(p)
    ];
    Channel? ch = channel;
    if (ch != null && (ix.followStatus != null || ix.subscription != null)) {
      ch = ch.copyWith(
          followStatus: ix.followStatus, subscription: ix.subscription);
    }
    return copyWith(
      posts: merged,
      stats: ix.channelStats,
      canPost: ix.canPost,
      interactions: ix,
      channel: ch,
    );
  }
}

/// The interactions call's answer (spec § Interactions): everything that
/// changes with each vote, reaction, comment or read, and everything that is
/// about the reader. Fetched after the document, never cached locally.
class FeedInteractions {
  /// Keyed by item `id`. A missing id is "not measured".
  final Map<String, ItemInteractions> items;

  /// `channel.stats`: the channel's read counts, when measured.
  final ChannelStats? channelStats;

  /// `channel.access.follow_status` / `.subscription`: signed answers only.
  final String? followStatus;
  final ChannelSubscription? subscription;

  /// `channel.can_post`: signed answers only.
  final bool? canPost;

  /// The answer as decoded, kept so the feed cache can store it next to the
  /// document it belongs to: a PublicOS document carries no
  /// counts, so the cached paint reads its last interactions from here.
  final Map<String, dynamic>? raw;

  const FeedInteractions({
    required this.items,
    this.channelStats,
    this.followStatus,
    this.subscription,
    this.canPost,
    this.raw,
  });

  /// [raw] re-encoded for the cache row, or null when this answer was built
  /// without one.
  String? get rawJson => raw == null ? null : jsonEncode(raw);

  factory FeedInteractions.fromJson(Map<String, dynamic> json) {
    final items = <String, ItemInteractions>{};
    final rawItems = json['items'];
    if (rawItems is Map) {
      for (final e in rawItems.entries) {
        if (e.value is Map) {
          items[e.key.toString()] = ItemInteractions.fromJson(
              (e.value as Map).cast<String, dynamic>());
        }
      }
    }
    final channel = json['channel'];
    final access = channel is Map ? channel['access'] : null;
    return FeedInteractions(
      items: items,
      channelStats:
          channel is Map ? ChannelStats.tryFromJson(channel['stats']) : null,
      followStatus: access is Map ? access['follow_status'] as String? : null,
      subscription: access is Map && access['subscription'] is Map
          ? ChannelSubscription.fromJson(
              (access['subscription'] as Map).cast<String, dynamic>())
          : null,
      canPost: channel is Map ? channel['can_post'] as bool? : null,
      raw: json,
    );
  }
}

/// One item's entry in an interactions answer.
class ItemInteractions {
  final int? comments;
  final int score;
  final int upvotes;
  final int downvotes;

  /// emoji → count.
  final Map<String, int> reactionCounts;

  /// The post's read counts, as served. Null when not measured.
  final Map<String, dynamic>? stats;

  /// Signed answers only: the reader's own vote (-1, 0, 1) and emojis.
  final int? viewerVote;
  final List<String>? viewerReactions;

  /// Signed answers only: whether this reader may comment / react here.
  final bool? canComment;
  final bool? canReact;

  const ItemInteractions({
    this.comments,
    this.score = 0,
    this.upvotes = 0,
    this.downvotes = 0,
    this.reactionCounts = const {},
    this.stats,
    this.viewerVote,
    this.viewerReactions,
    this.canComment,
    this.canReact,
  });

  factory ItemInteractions.fromJson(Map<String, dynamic> json) {
    final counts = json['counts'];
    final viewer = json['viewer'];
    int n(Object? v) => v is num ? v.toInt() : 0;
    final reactions = <String, int>{};
    if (counts is Map && counts['reactions'] is Map) {
      for (final e in (counts['reactions'] as Map).entries) {
        if (e.value is num) reactions[e.key.toString()] = (e.value as num).toInt();
      }
    }
    return ItemInteractions(
      comments: counts is Map && counts['comments'] is num
          ? (counts['comments'] as num).toInt()
          : null,
      score: counts is Map ? n(counts['score']) : 0,
      upvotes: counts is Map ? n(counts['upvotes']) : 0,
      downvotes: counts is Map ? n(counts['downvotes']) : 0,
      reactionCounts: reactions,
      stats: json['stats'] is Map
          ? (json['stats'] as Map).cast<String, dynamic>()
          : null,
      viewerVote: viewer is Map && viewer['vote'] is num
          ? (viewer['vote'] as num).toInt()
          : null,
      viewerReactions: viewer is Map && viewer['reactions'] is List
          ? (viewer['reactions'] as List).whereType<String>().toList()
          : null,
      canComment: json['can_comment'] as bool?,
      canReact: json['can_react'] as bool?,
    );
  }

  /// The card's `emoji:count,...` string, or null when nobody reacted.
  String? get reactionsString => Post.parseReactions(reactionCounts);

  /// This entry written onto [post]: counts, the reader's vote (0 = none),
  /// their reactions, and the server's `can_*` answers.
  Post applyTo(Post post) => post.copyWith(
        score: score,
        upvotes: upvotes,
        downvotes: downvotes,
        commentsCount: comments,
        reactions: reactionsString,
        userVote: viewerVote == null || viewerVote == 0 ? null : viewerVote,
        viewerReactions: viewerReactions,
        canCommentAnswer: canComment,
        canReactAnswer: canReact,
      );
}

/// @deprecated Use ParsedFeed instead - will be removed
class RssItem {
  final String title;
  final String description;
  final String link;
  final DateTime publishedDate;
  final String? imageUrl;
  final String? author;
  final List<String>? mediaContentUrls; // URLs from <media:content> tags

  RssItem({
    required this.title,
    required this.description,
    required this.link,
    required this.publishedDate,
    this.imageUrl,
    this.author,
    this.mediaContentUrls,
  });

  String get formattedDescription {
    // Strip basic HTML tags from description
    final stripped = description
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&[^;]+;'), ' ')
        .trim();
    return stripped.length > 200 ? '${stripped.substring(0, 200)}...' : stripped;
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(publishedDate);

    if (difference.inDays == 0) {
      if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } else if (difference.inDays == 1) {
      return '1 day ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${publishedDate.year}-${publishedDate.month.toString().padLeft(2, '0')}-${publishedDate.day.toString().padLeft(2, '0')}';
    }
  }
}

class RssFeed {
  final String title;
  final String description;
  final String link;
  final List<RssItem> items;
  final DateTime lastUpdated;
  final String? imageUrl;

  RssFeed({
    required this.title,
    required this.description,
    required this.link,
    required this.items,
    required this.lastUpdated,
    this.imageUrl,
  });
}

class RssItemWithOrigin {
  final RssItem item;
  final String? feedFoundAtAccountAddress;
  final String? feedTitle;
  final String feedUrl;

  RssItemWithOrigin({
    required this.item,
    this.feedFoundAtAccountAddress,
    this.feedTitle,
    required this.feedUrl,
  });

  // Delegate all RssItem properties
  String get title => item.title;
  String get description => item.description;
  String get link => item.link;
  DateTime get publishedDate => item.publishedDate;
  String? get imageUrl => item.imageUrl;
  String? get author => item.author;
  List<String>? get mediaContentUrls => item.mediaContentUrls;
  String get formattedDescription => item.formattedDescription;
  String get formattedDate => item.formattedDate;
}
