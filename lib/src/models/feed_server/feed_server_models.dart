import 'package:publicos_core/src/config/paid_feed_chains.dart';
import 'package:publicos_core/src/models/feed_server/gate_tier.dart';
import 'package:publicos_core/src/models/post.dart' show PostMedia;

class FeedServer {
  final int id;
  final String feedServerAddress;
  final String? name;
  final bool isDefault;
  final String sessionAddress;
  final DateTime createdAt;
  final DateTime updatedAt;

  FeedServer({
    required this.id,
    required this.feedServerAddress,
    this.name,
    required this.isDefault,
    required this.sessionAddress,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeedServer.fromJson(Map<String, dynamic> json) {
    return FeedServer(
      id: json['id'],
      feedServerAddress: json['feed_server_address'] ?? json['rss_server_address'],
      name: json['name'],
      isDefault: (json['is_default'] ?? 0) == 1,
      sessionAddress: json['session_address'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'feed_server_address': feedServerAddress,
      'name': name,
      'is_default': isDefault ? 1 : 0,
      'session_address': sessionAddress,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  FeedServer copyWith({
    int? id,
    String? feedServerAddress,
    String? name,
    bool? isDefault,
    String? sessionAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FeedServer(
      id: id ?? this.id,
      feedServerAddress: feedServerAddress ?? this.feedServerAddress,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      sessionAddress: sessionAddress ?? this.sessionAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// One place a paid channel can be paid for: a numeric feed id on a `PaidFeeds`
/// master contract on one chain.
///
/// **A channel may list several entries on the SAME chain, and that is not a
/// bug.** It is the lost-registrant-key recovery path: `registrant` is
/// immutable in the contract and there is no transfer function, so an owner who
/// loses that key registers a FRESH feed id and the channel keeps the old entry
/// beside it. Every entry is honoured for entitlement — so readers who already
/// paid into the retired id keep reading, with nothing to re-grant — but only
/// the newest per chain may be sold into. That is what [payable] carries, and a
/// pay sheet MUST respect it: money sent to a feed whose registrant is gone is
/// unreachable, and its owner cannot even close it.
class ChannelAccessEntry {
  final int chainId;

  /// Feed id inside the master contract. Always > 0 (the contract's `nextId`
  /// starts at 1, so a zero would gate every reader forever).
  final int feedId;

  /// The paywall contract on [chainId].
  ///
  /// On a READ this is what the server actually calls — resolved from its own
  /// allowlist, never a guess, which is why `PaidFeedChains` deliberately holds
  /// no addresses of its own. On a WRITE it is what the owner is proposing, and
  /// the server checks it against that allowlist before storing it.
  ///
  /// Empty means "this server's default for the chain": legal on a write, and
  /// on a read only for a chain the server no longer serves — always alongside
  /// `payable: false`.
  final String contract;

  /// The server's display name for the chain, e.g. "Base". Only used when this
  /// build does not know [chainId]; prefer `PaidFeedChains.nameFor`.
  final String? chainName;

  /// Whether a reader may subscribe into this entry. False for a retired feed
  /// id and for a chain the server dropped.
  final bool payable;

  const ChannelAccessEntry({
    required this.chainId,
    required this.feedId,
    this.contract = '',
    this.chainName,
    this.payable = false,
  });

  /// [defaultPayable] exists because the two surfaces that carry entries say
  /// different things: a 403 body contains ONLY payable entries and omits the
  /// flag, while the channel listing carries every entry and states it.
  factory ChannelAccessEntry.fromJson(Map<String, dynamic> json,
      {bool defaultPayable = false}) {
    return ChannelAccessEntry(
      chainId: (json['chain_id'] as num?)?.toInt() ?? 0,
      feedId: (json['feed_id'] as num?)?.toInt() ?? 0,
      contract: json['contract'] as String? ?? '',
      chainName: json['chain_name'] as String?,
      payable: json['payable'] as bool? ?? defaultPayable,
    );
  }

  /// The write shape the server accepts on create/update.
  ///
  /// [contract] is sent when known and **omitted when empty**, which the server
  /// reads as "use this chain's default". Sending it is not the same as being
  /// trusted with it: the server checks the address against its own allowlist
  /// at save time and answers `CONTRACT_NOT_ALLOWED` otherwise. Carrying it in
  /// the shape from v1 is what keeps the owner flow — pick a chain, a contract,
  /// an id — unchanged the day that allowlist widens to payout splitters and
  /// foreign gates.
  ///
  /// An RPC URL is never sent, and that rule does not soften: naming the
  /// endpoint would hand an owner a server-side request forgery primitive.
  Map<String, dynamic> toJson() => {
        'chain_id': chainId,
        'feed_id': feedId,
        if (contract.isNotEmpty) 'contract': contract,
      };

  /// True when this entry can actually be transacted on by this build: it is
  /// sellable, the server gave us an address, and we have an endpoint for the
  /// chain.
  bool get isUsable =>
      payable &&
      contract.isNotEmpty &&
      (PaidFeedChains.forId(chainId)?.isReachable ?? false);

  @override
  String toString() =>
      'ChannelAccessEntry(chain: $chainId, feed: $feedId, payable: $payable)';

  /// Identity is `(chain, contract, feed)` — the same triple the server uniquely
  /// indexes. **The contract belongs in the key**: feed ids are per contract, so
  /// id 7 on the master and id 7 on a payout splitter are unrelated plans, and
  /// treating them as equal would silently drop one from a list.
  @override
  bool operator ==(Object other) =>
      other is ChannelAccessEntry &&
      other.chainId == chainId &&
      other.feedId == feedId &&
      other.contract.toLowerCase() == contract.toLowerCase();

  @override
  int get hashCode => Object.hash(chainId, feedId, contract.toLowerCase());
}

/// Unified channel model — replaces both Feed and Forum.
/// [postingPolicy] distinguishes behavior:
///   "owner"    — only the channel owner can post (classic feed)
///   "open"     — anyone can post
///   "approved" — only whitelisted posters can post
/// The signed reader's own standing on a PAID channel — the `subscription`
/// block of a channel object (listing row, `GET …/channels/<slug>`, the
/// feed's interactions answer, `error.channel`). Absent for anonymous
/// callers and free channels.
class ChannelSubscription {
  final bool active;

  /// Non-null means the reader HAD a subscription and it ran out — "renew"
  /// copy rather than "subscribe".
  final DateTime? lapsedAt;

  const ChannelSubscription({required this.active, this.lapsedAt});

  factory ChannelSubscription.fromJson(Map<String, dynamic> json) {
    final lapsed = json['lapsed_at'];
    return ChannelSubscription(
      active: json['active'] == true,
      lapsedAt: lapsed is num && lapsed > 0
          ? DateTime.fromMillisecondsSinceEpoch(lapsed.toInt() * 1000,
              isUtc: true)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'active': active,
        if (lapsedAt != null)
          'lapsed_at': lapsedAt!.millisecondsSinceEpoch ~/ 1000,
      };
}

class Channel {
  final int id;
  final int accountId;
  final String name;
  final String description;
  final String slug;
  final String? iconUrl;

  /// Channel language (BCP-47 style tag, e.g. 'en', 'es', 'es-MX').
  /// Feed-level: the server emits it on the JSON Feed / RSS / Atom output.
  final String language;
  final bool isPrivate;

  /// The ONE listing filter: when on,
  /// the server drops this channel from `GetChannelsByAddress` for everyone
  /// but the owner — even when the channel is public — and excludes it from
  /// public stats aggregates and rankings. Deliberately ORTHOGONAL to the
  /// read gate: privacy (a read list) gates CONTENT at the feed door; secret
  /// gates EXISTENCE in the listing. A public secret channel is reachable by
  /// anyone holding its URL, exactly like an unlisted video.
  final bool secret;

  /// PublicOS Feed v1 interaction settings: `open` (default) or `closed`. A closed one
  /// makes the SSP's quote check answer no for that kind. A post may be
  /// stricter than its channel, never looser.
  final String quotePolicy;
  final String repostPolicy;
  final String replyPolicy;
  final String postingPolicy;
  final int postRateLimit;
  /// The four RETIRED booleans. They remain on the wire so an older server or
  /// an older client still round-trips, and they are what the tier getters
  /// below derive from when a channel predates the ladder. Read the tiers, not
  /// these — a bool can only say "citizens or everyone", which is exactly the
  /// gap the ladder was added to close.
  final bool requireRent;
  final bool requireVerifiedRead;
  final bool requireVerifiedPosting;
  final bool requireVerifiedComments;

  /// The identity ladder, one rung per gate. See [GateTier].
  ///
  /// Empty means the server has not sent one — an older deployment, or a row
  /// written before the backfill. Never read these directly; use
  /// [readTier], [commentTier], [reactionTier] and [postingTier], which
  /// fall back to the retired booleans. Reading the raw field and finding ''
  /// would present a citizens-only channel as open.
  final String readIdentity;
  final String commentIdentity;
  final String reactionIdentity;
  final String postingIdentity;

  /// Which lists each gate consults. INDEPENDENT switches whose results union:
  /// any enabled source that admits you is enough, and none enabled means the
  /// list step is skipped entirely. That last part is why [isPrivate] is a
  /// consequence of these rather than a separate flag that can contradict them.
  final bool readUseFriends;
  final bool readUseChannelList;
  final bool interactUseFriends;
  final bool interactUseChannelList;
  final bool interactUseInteractionList;
  final int? maxPosts;
  final int? maxDays;
  final int? postCount;
  final String? ownerAddress;
  final String? serverAddress;
  final int? serverId;
  final String? followStatus;

  /// Denormalised on the server from the entry rows, and the ONE bit the read
  /// ladder's public fast path tests — a paid channel whose `is_paid` is false
  /// is served free. Treat it as the authority for "is this gated", and
  /// [accessEntries] as the authority for "where can it be paid".
  final bool isPaid;

  /// Where this channel can be paid for. Empty for a free channel, and also
  /// empty on responses that predate the server addendum — so a client must
  /// treat "paid with no entries" as "locked, nowhere to pay right now" rather
  /// than as "free".
  final List<ChannelAccessEntry> accessEntries;

  /// The reader's own standing on a paid channel, when the request was
  /// signed. Null = anonymous, free channel, or an older server.
  final ChannelSubscription? subscription;

  // -- The tier getters. ALWAYS read these, never the raw fields. ----------
  //
  // Each falls back to the retired boolean when the server sent no tier, so a
  // channel from an older deployment keeps the gate it was configured with.
  // Getting the fallback wrong is the worst outcome available here: a
  // citizens-only channel would present as OPEN, and the UI would offer to
  // loosen something already loose.

  /// Who may READ. Falls back to require_verified_read.
  String get readTier => readIdentity.isNotEmpty
      ? readIdentity
      : (requireVerifiedRead ? GateTier.citizen : GateTier.anyone);

  /// Who may COMMENT. Falls back to require_verified_comments - but note the
  /// floor differs from reads: an un-tiered channel defaults to `standing`,
  /// not `anyone`, because interactions are where the server tightened.
  String get commentTier => commentIdentity.isNotEmpty
      ? commentIdentity
      : (requireVerifiedComments ? GateTier.citizen : GateTier.standing);

  /// Who may REACT. There was never a channel-level reactions mirror to derive
  /// from - only comments had one - so an unset value takes the new default
  /// outright.
  String get reactionTier =>
      reactionIdentity.isNotEmpty ? reactionIdentity : GateTier.standing;

  /// Who may POST. Folds the two retired booleans, and the ORDER matters:
  /// require_verified_posting (citizen) is stricter than require_rent
  /// (standing), so a channel that set both must land on the tighter one.
  String get postingTier {
    if (postingIdentity.isNotEmpty) return postingIdentity;
    if (requireVerifiedPosting) return GateTier.citizen;
    if (requireRent) return GateTier.standing;
    return GateTier.account;
  }

  /// True when some list decides who may SEE this channel. Prefer this over
  /// [isPrivate] when reasoning about the current switches - isPrivate is
  /// maintained by the server from exactly these two, so they agree, but this
  /// one cannot go stale against a locally-edited draft.
  bool get isRestrictedForReading => readUseFriends || readUseChannelList;

  /// True when some list decides who may comment or react.
  bool get isRestrictedForInteracting =>
      interactUseFriends || interactUseChannelList || interactUseInteractionList;

  final String createdAt;
  final String updatedAt;

  Channel({
    required this.id,
    required this.accountId,
    required this.name,
    required this.description,
    required this.slug,
    this.iconUrl,
    this.language = 'en',
    this.isPrivate = false,
    this.secret = false,
    this.quotePolicy = 'open',
    this.repostPolicy = 'open',
    this.replyPolicy = 'open',
    this.postingPolicy = 'owner',
    this.postRateLimit = 0,
    this.requireRent = false,
    this.requireVerifiedRead = false,
    this.requireVerifiedPosting = false,
    this.requireVerifiedComments = false,
    this.readIdentity = '',
    this.commentIdentity = '',
    this.reactionIdentity = '',
    this.postingIdentity = '',
    this.readUseFriends = false,
    this.readUseChannelList = false,
    this.interactUseFriends = false,
    this.interactUseChannelList = false,
    this.interactUseInteractionList = false,
    this.maxPosts,
    this.maxDays,
    this.postCount,
    this.ownerAddress,
    this.serverAddress,
    this.serverId,
    this.followStatus,
    this.isPaid = false,
    this.accessEntries = const [],
    this.subscription,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Sellable entries only, ordered the way the server walks them (PublicOS
  /// first, then ascending) so a pay sheet preselects the same chain the server
  /// would have answered from.
  List<ChannelAccessEntry> get payableEntries {
    final out = accessEntries.where((e) => e.payable).toList()
      ..sort((a, b) => PaidFeedChains.compareChainIds(a.chainId, b.chainId));
    return out;
  }

  bool get isOwnerOnly => postingPolicy == 'owner';
  bool get isOpen => postingPolicy == 'open';
  bool get isApproved => postingPolicy == 'approved';
  bool get isCommunity => !isOwnerOnly;

  factory Channel.fromJson(Map<String, dynamic> json, {String? serverAddress, int? serverId}) {
    return Channel(
      id: json['id'] ?? json['ID'] ?? 0,
      accountId: json['account_id'] ?? json['AccountID'] ?? 0,
      name: json['name'] ?? json['Name'] ?? '',
      description: json['description'] ?? json['Description'] ?? '',
      slug: json['slug'] ?? json['Slug'] ?? '',
      iconUrl: json['icon_url'] ?? json['IconURL'],
      language: json['language'] as String? ?? json['Language'] as String? ?? 'en',
      isPrivate: json['is_private'] ?? json['IsPrivate'] ?? false,
      secret: json['secret'] as bool? ?? json['Secret'] as bool? ?? false,
      quotePolicy: json['quote_policy'] as String? ?? 'open',
      repostPolicy: json['repost_policy'] as String? ?? 'open',
      replyPolicy: json['reply_policy'] as String? ?? 'open',
      postingPolicy: json['posting_policy'] as String? ?? 'owner',
      postRateLimit: json['post_rate_limit'] as int? ?? 0,
      requireRent: json['require_rent'] as bool? ?? false,
      requireVerifiedRead: json['require_verified_read'] as bool? ?? false,
      readIdentity: json['read_identity'] as String? ?? '',
      commentIdentity: json['comment_identity'] as String? ?? '',
      reactionIdentity: json['reaction_identity'] as String? ?? '',
      postingIdentity: json['posting_identity'] as String? ?? '',
      readUseFriends: json['read_use_friends'] as bool? ?? false,
      readUseChannelList: json['read_use_channel_list'] as bool? ?? false,
      interactUseFriends: json['interact_use_friends'] as bool? ?? false,
      interactUseChannelList: json['interact_use_channel_list'] as bool? ?? false,
      interactUseInteractionList:
          json['interact_use_interaction_list'] as bool? ?? false,
      requireVerifiedPosting: json['require_verified_posting'] as bool? ?? false,
      requireVerifiedComments: json['require_verified_comments'] as bool? ?? false,
      maxPosts: json['max_posts'] ?? json['MaxPosts'],
      maxDays: json['max_days'] ?? json['MaxDays'],
      postCount: json['post_count'] as int?,
      ownerAddress: json['owner_address'] as String?,
      serverAddress: serverAddress,
      serverId: serverId,
      followStatus: json['follow_status'],
      isPaid: json['is_paid'] as bool? ?? json['IsPaid'] as bool? ?? false,
      accessEntries: (json['access_entries'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(ChannelAccessEntry.fromJson)
              .toList() ??
          const [],
      subscription: json['subscription'] is Map
          ? ChannelSubscription.fromJson(
              (json['subscription'] as Map).cast<String, dynamic>())
          : null,
      createdAt: (json['created_at'] ?? json['CreatedAt'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? json['UpdatedAt'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_id': accountId,
      'name': name,
      'description': description,
      'slug': slug,
      'icon_url': iconUrl,
      'language': language,
      'is_private': isPrivate,
      'secret': secret,
      'quote_policy': quotePolicy,
      'repost_policy': repostPolicy,
      'reply_policy': replyPolicy,
      'posting_policy': postingPolicy,
      'post_rate_limit': postRateLimit,
      'require_rent': requireRent,
      'require_verified_read': requireVerifiedRead,
      'read_identity': readIdentity,
      'comment_identity': commentIdentity,
      'reaction_identity': reactionIdentity,
      'posting_identity': postingIdentity,
      'read_use_friends': readUseFriends,
      'read_use_channel_list': readUseChannelList,
      'interact_use_friends': interactUseFriends,
      'interact_use_channel_list': interactUseChannelList,
      'interact_use_interaction_list': interactUseInteractionList,
      'require_verified_posting': requireVerifiedPosting,
      'require_verified_comments': requireVerifiedComments,
      'max_posts': maxPosts,
      'max_days': maxDays,
      if (postCount != null) 'post_count': postCount,
      if (ownerAddress != null) 'owner_address': ownerAddress,
      'server_address': serverAddress,
      'server_id': serverId,
      'follow_status': followStatus,
      // READ shape, for round-tripping a cached channel. The update body is
      // built field-by-field in PublicOSChannels.updateChannel and never from
      // here — which matters, because on the wire an ABSENT `access_entries`
      // means "leave the paywall alone" while a present one REPLACES it.
      'is_paid': isPaid,
      if (subscription != null) 'subscription': subscription!.toJson(),
      if (accessEntries.isNotEmpty)
        'access_entries': [
          for (final e in accessEntries)
            {
              'chain_id': e.chainId,
              'feed_id': e.feedId,
              'contract': e.contract,
              'chain_name': e.chainName,
              'payable': e.payable,
            }
        ],
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Channel copyWith({
    int? id,
    int? accountId,
    String? name,
    String? description,
    String? slug,
    String? iconUrl,
    String? language,
    bool? isPrivate,
    bool? secret,
    String? quotePolicy,
    String? repostPolicy,
    String? replyPolicy,
    String? postingPolicy,
    int? postRateLimit,
    bool? requireRent,
    bool? requireVerifiedRead,
    String? readIdentity,
    String? commentIdentity,
    String? reactionIdentity,
    String? postingIdentity,
    bool? readUseFriends,
    bool? readUseChannelList,
    bool? interactUseFriends,
    bool? interactUseChannelList,
    bool? interactUseInteractionList,
    bool? requireVerifiedPosting,
    bool? requireVerifiedComments,
    int? maxPosts,
    int? maxDays,
    int? postCount,
    String? ownerAddress,
    String? serverAddress,
    int? serverId,
    String? followStatus,
    bool? isPaid,
    List<ChannelAccessEntry>? accessEntries,
    ChannelSubscription? subscription,
    String? createdAt,
    String? updatedAt,
  }) {
    return Channel(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      name: name ?? this.name,
      description: description ?? this.description,
      slug: slug ?? this.slug,
      iconUrl: iconUrl ?? this.iconUrl,
      language: language ?? this.language,
      isPrivate: isPrivate ?? this.isPrivate,
      secret: secret ?? this.secret,
      quotePolicy: quotePolicy ?? this.quotePolicy,
      repostPolicy: repostPolicy ?? this.repostPolicy,
      replyPolicy: replyPolicy ?? this.replyPolicy,
      postingPolicy: postingPolicy ?? this.postingPolicy,
      postRateLimit: postRateLimit ?? this.postRateLimit,
      requireRent: requireRent ?? this.requireRent,
      requireVerifiedRead: requireVerifiedRead ?? this.requireVerifiedRead,
      readIdentity: readIdentity ?? this.readIdentity,
      commentIdentity: commentIdentity ?? this.commentIdentity,
      reactionIdentity: reactionIdentity ?? this.reactionIdentity,
      postingIdentity: postingIdentity ?? this.postingIdentity,
      readUseFriends: readUseFriends ?? this.readUseFriends,
      readUseChannelList: readUseChannelList ?? this.readUseChannelList,
      interactUseFriends: interactUseFriends ?? this.interactUseFriends,
      interactUseChannelList:
          interactUseChannelList ?? this.interactUseChannelList,
      interactUseInteractionList:
          interactUseInteractionList ?? this.interactUseInteractionList,
      requireVerifiedPosting:
          requireVerifiedPosting ?? this.requireVerifiedPosting,
      requireVerifiedComments:
          requireVerifiedComments ?? this.requireVerifiedComments,
      maxPosts: maxPosts ?? this.maxPosts,
      maxDays: maxDays ?? this.maxDays,
      postCount: postCount ?? this.postCount,
      ownerAddress: ownerAddress ?? this.ownerAddress,
      serverAddress: serverAddress ?? this.serverAddress,
      serverId: serverId ?? this.serverId,
      followStatus: followStatus ?? this.followStatus,
      isPaid: isPaid ?? this.isPaid,
      accessEntries: accessEntries ?? this.accessEntries,
      subscription: subscription ?? this.subscription,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class FeedServerApiRequest {
  final int timestamp;
  final String action;
  final Map<String, dynamic> data;
  final String session;
  final String nonce;
  final String target;
  final String signature;

  FeedServerApiRequest({
    required this.timestamp,
    required this.action,
    required this.data,
    required this.session,
    required this.nonce,
    required this.target,
    required this.signature,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'action': action,
      'data': data,
      'session': session,
      'nonce': nonce,
      'target': target,
      'signature': signature,
    };
  }
}

/// The reader-type split of [ChannelStats.totalViews]. The four types
/// partition every read, so they sum to `totalViews`.
class ChannelStatsByType {
  final int citizen;
  final int private;
  final int signedNoAccount;
  final int anonymous;

  const ChannelStatsByType({
    this.citizen = 0,
    this.private = 0,
    this.signedNoAccount = 0,
    this.anonymous = 0,
  });

  factory ChannelStatsByType.fromJson(Map<String, dynamic> json) {
    return ChannelStatsByType(
      citizen: json['citizen'] ?? 0,
      private: json['private'] ?? 0,
      signedNoAccount: json['signed_no_account'] ?? 0,
      anonymous: json['anonymous'] ?? 0,
    );
  }
}

/// Channel-level read stats, carried in the interactions call's
/// `channel.stats` (social-reads KPI). These are per-channel and this-week.
///
/// This object is only ever built when the server actually sent a `stats`
/// block. It is ABSENT — the field on the response is null — for plain RSS /
/// external feeds, opted-out channels, and channels nobody has read. Absent
/// means *not measured*; it must never be coalesced into a zero object, or the
/// UI would render "0 readers" for a feed that simply doesn't report stats.
/// See [ChannelStats.tryFromJson].
class ChannelStats {
  /// Distinct citizens this week — the non-spoofable "Readers" headline.
  final int verifiedCitizenViews;

  /// Every read ever, all reader types (a superset of citizens). All-time —
  /// the server's gross counter carries no time dimension, unlike the weekly
  /// citizen numbers.
  final int totalViews;

  /// The 4-way split of [totalViews].
  final ChannelStatsByType byType;

  /// Distinct citizens per day, oldest → newest. Fixed length (7 today), but
  /// treat the length as whatever the server sent.
  final List<int> daily;

  /// Distinct citizens so far today — partial, not folded into the headline.
  final int today;

  /// ISO week the numbers cover, e.g. "2026-W30".
  final String week;

  /// Last SEALED week, e.g. "2026-W28". Null until a seal exists (a brand-new
  /// channel has none yet) — the server omits the field entirely in that case.
  final String? verifiedThrough;

  const ChannelStats({
    required this.verifiedCitizenViews,
    required this.totalViews,
    required this.byType,
    required this.daily,
    required this.today,
    required this.week,
    this.verifiedThrough,
  });

  /// Null-safe parse. Returns null when [raw] is not a stats map, so callers
  /// can pass `json['stats']` directly and get null for the absent case.
  static ChannelStats? tryFromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    return ChannelStats(
      verifiedCitizenViews: raw['verified_citizen_views'] ?? 0,
      totalViews: raw['total_views'] ?? 0,
      byType: raw['by_type'] is Map<String, dynamic>
          ? ChannelStatsByType.fromJson(raw['by_type'] as Map<String, dynamic>)
          : const ChannelStatsByType(),
      daily: (raw['daily'] as List?)
              ?.map((e) => (e as num?)?.toInt() ?? 0)
              .toList() ??
          const [],
      today: raw['today'] ?? 0,
      week: raw['week'] as String? ?? '',
      verifiedThrough: raw['verified_through'] as String?,
    );
  }
}

class FeedServerApiResponse<T> {
  final bool success;
  final T? data;
  final Map<String, dynamic>? error;
  final bool hasMore;

  /// Channel-level read stats from the interactions call's `channel.stats`,
  /// or null when the server sent none (the open web, opted-out, no reads).
  /// Rides on the response the same way [hasMore] does.
  final ChannelStats? channelStats;

  /// The feed's own top-level `description` — carried off the SAME response
  /// as the posts, so a single-feed surface can
  /// render its header without a separate channel-metadata call. Null when
  /// the server sent none.
  final String? description;

  /// The channel's `posting` — `'open'` marks a forum channel.
  /// Carried so callers learn forum-ness from the response instead of peeking
  /// at the first post's `isForumChannel`. Null when the server sent none.
  final String? postingPolicy;

  /// The response's `ETag` validator, when the endpoint emits one (feed +
  /// single-post reads). Callers that keep a local copy store it and send it
  /// back as `If-None-Match` to revalidate cheaply.
  final String? etag;

  /// True when the server answered `304 Not Modified` to a conditional
  /// request — the caller's stored copy is byte-current. [data] is null in
  /// that case, and [success] is true (a confirmed-current copy is not an
  /// error).
  final bool notModified;

  FeedServerApiResponse({
    required this.success,
    this.data,
    this.error,
    this.hasMore = false,
    this.channelStats,
    this.description,
    this.postingPolicy,
    this.etag,
    this.notModified = false,
  });

  factory FeedServerApiResponse.success(
    T data, {
    bool hasMore = false,
    ChannelStats? channelStats,
    String? description,
    String? postingPolicy,
    String? etag,
  }) {
    return FeedServerApiResponse<T>(
      success: true,
      data: data,
      hasMore: hasMore,
      channelStats: channelStats,
      description: description,
      postingPolicy: postingPolicy,
      etag: etag,
    );
  }

  /// The 304 verdict for conditional reads — "what you have is current".
  factory FeedServerApiResponse.notModified() {
    return FeedServerApiResponse<T>(
      success: true,
      notModified: true,
    );
  }

  factory FeedServerApiResponse.error(Map<String, dynamic> error) {
    return FeedServerApiResponse<T>(
      success: false,
      error: error,
    );
  }
}

class ChannelListResponse {
  final List<Channel> channels;
  final int count;

  ChannelListResponse({
    required this.channels,
    required this.count,
  });

  factory ChannelListResponse.fromJson(Map<String, dynamic> json) {
    final channelsList = (json['channels'] as List)
        .map((ch) => Channel.fromJson(ch as Map<String, dynamic>))
        .toList();
    return ChannelListResponse(
      channels: channelsList,
      count: json['count'] as int? ?? channelsList.length,
    );
  }
}

class FeedList {
  final int id;
  final String name;
  final String? icon;
  final String sessionAddress;
  final DateTime createdAt;
  final DateTime updatedAt;
  /// True when this list wraps exactly one feed and presents itself as that
  /// feed (icon + name + via line). UI invariant: count(feeds) ≤ 1.
  final bool isSingle;

  FeedList({
    required this.id,
    required this.name,
    this.icon,
    required this.sessionAddress,
    required this.createdAt,
    required this.updatedAt,
    this.isSingle = false,
  });

  factory FeedList.fromJson(Map<String, dynamic> json) {
    return FeedList(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      sessionAddress: json['session_address'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at']),
      isSingle: json['is_single'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'session_address': sessionAddress,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_single': isSingle,
    };
  }

  FeedList copyWith({
    int? id,
    String? name,
    String? icon,
    String? sessionAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSingle,
  }) {
    return FeedList(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      sessionAddress: sessionAddress ?? this.sessionAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSingle: isSingle ?? this.isSingle,
    );
  }
}

class ListFeed {
  final int id;
  final int listId;
  final String feedUrl;
  final String? feedTitle;
  final String? feedDescription;
  final String? feedFoundAtAccountAddress;

  /// The owner's `record.key` when this row is a CHANNEL FOLLOW. Null = raw
  /// URL snapshot. Non-null rows have [feedUrl] re-resolved from the owner at
  /// read time (see `PublicOSFollows.resolveListFeeds`), so the follow
  /// survives the author re-pointing the channel.
  final String? feedRecordKey;
  final DateTime addedAt;

  ListFeed({
    required this.id,
    required this.listId,
    required this.feedUrl,
    this.feedTitle,
    this.feedDescription,
    this.feedFoundAtAccountAddress,
    this.feedRecordKey,
    required this.addedAt,
  });

  factory ListFeed.fromJson(Map<String, dynamic> json) {
    return ListFeed(
      id: json['id'],
      listId: json['list_id'],
      feedUrl: json['feed_url'],
      feedTitle: json['feed_title'],
      feedDescription: json['feed_description'],
      feedFoundAtAccountAddress: json['feed_found_at_account_address'],
      feedRecordKey: json['feed_record_key'],
      addedAt: DateTime.fromMillisecondsSinceEpoch(json['added_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'list_id': listId,
      'feed_url': feedUrl,
      'feed_title': feedTitle,
      'feed_description': feedDescription,
      'feed_found_at_account_address': feedFoundAtAccountAddress,
      'feed_record_key': feedRecordKey,
      'added_at': addedAt.millisecondsSinceEpoch,
    };
  }

  ListFeed copyWith({
    int? id,
    int? listId,
    String? feedUrl,
    String? feedTitle,
    String? feedDescription,
    String? feedFoundAtAccountAddress,
    String? feedRecordKey,
    DateTime? addedAt,
  }) {
    return ListFeed(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      feedUrl: feedUrl ?? this.feedUrl,
      feedTitle: feedTitle ?? this.feedTitle,
      feedDescription: feedDescription ?? this.feedDescription,
      feedFoundAtAccountAddress: feedFoundAtAccountAddress ?? this.feedFoundAtAccountAddress,
      feedRecordKey: feedRecordKey ?? this.feedRecordKey,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}

class ListWithFeeds {
  final FeedList list;
  final List<ListFeed> feeds;

  ListWithFeeds({
    required this.list,
    required this.feeds,
  });

  int get feedCount => feeds.length;

  String get displayName => list.name;

  bool get isEmpty => feeds.isEmpty;
}

class FollowRequest {
  /// UUID PK on the server (`follow_requests.uid`). Used in approve/ignore
  /// path params (`/followers/:requestUid` and `/followers/:requestUid/ignore`).
  final String uid;
  // Server omits `channel_id` from the JSON response (struct tag `json:"-"`),
  // so this is optional. Don't depend on it for routing — it's metadata only.
  final int? channelId;
  final String requesterAddress;

  /// One of: `pending`, `ignored`, `approved`.
  ///
  /// `pending` and `ignored` are operationally identical (the requester has
  /// no read access in either state) — `ignored` is purely an owner-side UI
  /// signal that the row was already triaged. `approved` is terminal and
  /// guarantees a backing whitelist row was created; revoke happens through
  /// whitelist removal, not by mutating the request.
  final String status;

  /// Accept-and-badge: the server does not refuse a
  /// follow request on the channel's read filter — the request LANDS, and each
  /// row carries whether the requester passes that filter TODAY.
  ///
  /// One of: `passes`, `blocked`, `unknown` — or null from a server that
  /// predates the field. `unknown` means the chain read failed (a badge is
  /// owner information, not access, so it fails soft). Evaluated live against
  /// the CURRENT filter on every list, so tightening or loosening the gate
  /// flips badges on the next read. An owner may approve a `blocked`
  /// requester — the whitelist row then waits behind the filter.
  final String? filterStatus;
  final String? expiresAt;
  final String createdAt;
  final String updatedAt;

  FollowRequest({
    required this.uid,
    this.channelId,
    required this.requesterAddress,
    required this.status,
    this.filterStatus,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FollowRequest.fromJson(Map<String, dynamic> json) {
    return FollowRequest(
      uid: (json['uid'] ?? json['UID'] ?? '').toString(),
      channelId: (json['channel_id'] ?? json['feed_id'] ?? json['ChannelID'] ?? json['FeedID']) as int?,
      requesterAddress: json['requester_address'] ?? json['RequesterAddress'] ?? '',
      status: json['status'] ?? json['Status'] ?? 'pending',
      filterStatus: json['filter_status'] as String?,
      expiresAt: json['expires_at'] as String?,
      createdAt: (json['created_at'] ?? json['CreatedAt'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? json['UpdatedAt'] ?? '').toString(),
    );
  }

  bool get isPending => status == 'pending';
  bool get isIgnored => status == 'ignored';
  bool get isApproved => status == 'approved';

  /// True for any state where the owner can still act (`pending` or `ignored`).
  /// Useful for UI affordances: only actionable rows show Approve / Ignore.
  bool get isActionable => isPending || isIgnored;

  /// The requester clears the channel's CURRENT read filter.
  bool get passesFilter => filterStatus == 'passes';

  /// The requester is bounced by the channel's CURRENT read filter. Approve
  /// still works — the whitelist row waits behind the filter — but the UI
  /// should badge the row so the owner approves with eyes open.
  bool get isFilterBlocked => filterStatus == 'blocked';
}

class FollowRequestListResponse {
  final List<FollowRequest> followRequests;
  final int count;

  FollowRequestListResponse({
    required this.followRequests,
    required this.count,
  });

  factory FollowRequestListResponse.fromJson(Map<String, dynamic> json) {
    return FollowRequestListResponse(
      followRequests: (json['follow_requests'] as List)
          .map((r) => FollowRequest.fromJson(r))
          .toList(),
      count: json['count'] ?? 0,
    );
  }
}

/// Result of a post vote action
class VoteResult {
  /// "voted", "unvoted", or "changed"
  final String action;
  final int score;
  final int upvotes;
  final int downvotes;
  /// +1, -1, or null (when unvoted)
  final int? userVote;

  VoteResult({
    required this.action,
    required this.score,
    required this.upvotes,
    required this.downvotes,
    this.userVote,
  });

  factory VoteResult.fromJson(Map<String, dynamic> json) {
    return VoteResult(
      action: json['action'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      upvotes: json['upvotes'] as int? ?? 0,
      downvotes: json['downvotes'] as int? ?? 0,
      userVote: json['user_vote'] as int?,
    );
  }
}

/// Post permission entry — who can post in a channel
///
/// [isOrg]: see [WhitelistEntry.isOrg]. An org on this list may publish.
class PostPermissionEntry {
  final int id;
  final int? accountId;
  final int? channelId;
  final String address;
  final bool isOrg;
  final String? expiresAt;
  final String grantedBy;
  final DateTime createdAt;

  PostPermissionEntry({
    required this.id,
    this.accountId,
    this.channelId,
    required this.address,
    this.isOrg = false,
    this.expiresAt,
    required this.grantedBy,
    required this.createdAt,
  });

  factory PostPermissionEntry.fromJson(Map<String, dynamic> json) {
    return PostPermissionEntry(
      id: json['id'] as int? ?? 0,
      accountId: json['account_id'] as int?,
      channelId: json['channel_id'] as int?,
      address: json['address'] as String? ?? '',
      isOrg: json['is_org'] as bool? ?? false,
      expiresAt: json['expires_at'] as String?,
      grantedBy: json['granted_by'] as String? ?? json['added_by'] as String? ?? '',
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

/// Whitelist entry — read access control with optional expiration
///
/// Also used for the channel INTERACTION list, which the server keeps in a
/// separate table but serves in the same row shape.
///
/// [isOrg] means the row names an ORG rather than a person: every CURRENT
/// member of that org is admitted, resolved live from chain on each read. The
/// server decides this when the row is created — the client only pastes an
/// address and renders whatever came back. Never set it from the UI.
class WhitelistEntry {
  final int id;
  final int? accountId;
  final int? channelId;
  final String address;
  final bool isOrg;
  final String? expiresAt;
  final String grantedBy;
  final DateTime createdAt;

  WhitelistEntry({
    required this.id,
    this.accountId,
    this.channelId,
    required this.address,
    this.isOrg = false,
    this.expiresAt,
    required this.grantedBy,
    required this.createdAt,
  });

  factory WhitelistEntry.fromJson(Map<String, dynamic> json) {
    return WhitelistEntry(
      id: json['id'] as int? ?? 0,
      accountId: json['account_id'] as int?,
      channelId: json['channel_id'] as int?,
      address: json['address'] as String? ?? '',
      isOrg: json['is_org'] as bool? ?? false,
      expiresAt: json['expires_at'] as String?,
      grantedBy: json['granted_by'] as String? ?? json['added_by'] as String? ?? '',
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

/// Ban/blacklist entry — channel-specific (channelId set) or account-wide (channelId null)
class BanEntry {
  final int id;
  final int? accountId;
  final int? channelId;
  final String address;
  final String? reason;
  final String addedBy;
  final DateTime createdAt;

  BanEntry({
    required this.id,
    this.accountId,
    this.channelId,
    required this.address,
    this.reason,
    required this.addedBy,
    required this.createdAt,
  });

  factory BanEntry.fromJson(Map<String, dynamic> json) {
    return BanEntry(
      id: json['id'] as int? ?? 0,
      accountId: json['account_id'] as int?,
      channelId: json['channel_id'] as int?,
      address: json['address'] as String? ?? '',
      reason: json['reason'] as String?,
      addedBy: json['added_by'] as String? ?? '',
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

/// Type of a [PostInteractionRule] override.
enum PostInteractionRuleType {
  allow,
  deny;

  String get wireValue {
    switch (this) {
      case PostInteractionRuleType.allow:
        return 'allow';
      case PostInteractionRuleType.deny:
        return 'deny';
    }
  }

  static PostInteractionRuleType fromWire(String? value) {
    switch (value) {
      case 'deny':
        return PostInteractionRuleType.deny;
      case 'allow':
      default:
        return PostInteractionRuleType.allow;
    }
  }
}

/// Per-post interaction rule — allow or deny a specific address from
/// interacting with a single post (one row gates BOTH a comment AND a
/// reaction attempt). Independent toggleability between comments and
/// reactions is achieved via the post's CommentPolicy / ReactionPolicy
/// enums; the rule rows are shared.
///
/// Maps to the server's `PostInteractionRule` model.
class PostInteractionRule {
  final String uid;
  final String address;
  final PostInteractionRuleType type;
  final String? expiresAt; // ISO-8601 string, nullable = never expires
  final String grantedBy;
  final DateTime createdAt;

  PostInteractionRule({
    required this.uid,
    required this.address,
    required this.type,
    this.expiresAt,
    required this.grantedBy,
    required this.createdAt,
  });

  factory PostInteractionRule.fromJson(Map<String, dynamic> json) {
    return PostInteractionRule(
      uid: json['uid'] as String? ?? '',
      address: json['address'] as String? ?? '',
      type: PostInteractionRuleType.fromWire(json['rule'] as String?),
      expiresAt: json['expires_at'] as String?,
      grantedBy: json['granted_by'] as String? ?? '',
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (uid.isNotEmpty) 'uid': uid,
        'address': address,
        'rule': type.wireValue,
        if (expiresAt != null) 'expires_at': expiresAt,
        if (grantedBy.isNotEmpty) 'granted_by': grantedBy,
        'created_at': createdAt.toIso8601String(),
      };
}

class MediaFile {
  final int id;
  final String filename;
  final String originalFilename;
  final String contentType;
  final int fileSize;
  final String url;
  final String createdAt;

  /// SHA-256 (lowercase hex) of the bytes `uploadMedia` sent, computed on the
  /// device so a composer signs the file it has without downloading it back.
  /// Empty on a listing (the server does not serve hashes).
  final String sha256;

  MediaFile({
    required this.id,
    required this.filename,
    required this.originalFilename,
    required this.contentType,
    required this.fileSize,
    required this.url,
    required this.createdAt,
    this.sha256 = '',
  });

  factory MediaFile.fromJson(Map<String, dynamic> json) {
    return MediaFile(
      id: json['id'],
      filename: json['filename'],
      originalFilename: json['original_filename'] ?? '',
      contentType: json['content_type'] ?? 'application/octet-stream',
      fileSize: json['file_size'] ?? 0,
      url: json['url'],
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }

  MediaFile copyWith({String? sha256, int? fileSize}) => MediaFile(
        id: id,
        filename: filename,
        originalFilename: originalFilename,
        contentType: contentType,
        fileSize: fileSize ?? this.fileSize,
        url: url,
        createdAt: createdAt,
        sha256: sha256 ?? this.sha256,
      );

  /// This upload as a post's media object: url, type, hash and size from
  /// here; the facts only the composer knows (pixels, a poster, the length)
  /// passed in. Hero items need [width] and [height].
  PostMedia toPostMedia({
    int? width,
    int? height,
    String? thumbnailUrl,
    num? durationInSeconds,
    String? title,
    String? alt,
    bool loop = false,
  }) =>
      PostMedia(
        url: url,
        mimeType: contentType,
        sha256: sha256.isEmpty ? null : sha256,
        sizeInBytes: fileSize > 0 ? fileSize : null,
        width: width,
        height: height,
        thumbnailUrl: thumbnailUrl,
        durationInSeconds: durationInSeconds,
        title: title,
        alt: alt,
        loop: loop,
      );
}

class MediaQuota {
  final int usedMb;
  final int totalMb;
  final int fileCount;
  final int maxFiles;

  MediaQuota({
    required this.usedMb,
    required this.totalMb,
    required this.fileCount,
    required this.maxFiles,
  });

  factory MediaQuota.fromJson(Map<String, dynamic> json) {
    return MediaQuota(
      usedMb: json['used_mb'] ?? 0,
      totalMb: json['total_mb'] ?? 0,
      fileCount: json['file_count'] ?? 0,
      maxFiles: json['max_files'] ?? -1,
    );
  }
}

class MediaListResponse {
  final List<MediaFile> files;
  final int count;
  final MediaQuota quota;

  MediaListResponse({
    required this.files,
    required this.count,
    required this.quota,
  });

  factory MediaListResponse.fromJson(Map<String, dynamic> json) {
    return MediaListResponse(
      files: ((json['files'] ?? []) as List)
          .map((f) => MediaFile.fromJson(f))
          .toList(),
      count: json['count'] ?? 0,
      quota: MediaQuota.fromJson(json['quota'] ?? {}),
    );
  }
}

/// A file in the user's PRIVATE media library (`/pedia/`, the second
/// door). Not a [MediaFile]: the id is the 32-hex
/// random string that doubles as the stable `/pedia/<id>` URL segment (there
/// is no server-side filename — the id IS the address), and the URL it
/// carries only ever serves per-reader ECIES ciphertext.
class PediaFile {
  final String id;
  final String originalFilename;
  final String contentType;
  final int fileSize;
  final String url;
  final String createdAt;

  /// SHA-256 (lowercase hex) of the PLAIN bytes `uploadPedia` sent: a private
  /// file is hashed before sealing (spec § Media hashes). Empty on a listing.
  final String sha256;

  PediaFile({
    required this.id,
    required this.originalFilename,
    required this.contentType,
    required this.fileSize,
    required this.url,
    required this.createdAt,
    this.sha256 = '',
  });

  factory PediaFile.fromJson(Map<String, dynamic> json) {
    return PediaFile(
      id: json['id'],
      originalFilename: json['original_filename'] ?? '',
      contentType: json['content_type'] ?? 'application/octet-stream',
      fileSize: json['file_size'] ?? 0,
      url: json['url'],
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }

  PediaFile copyWith({String? sha256, int? fileSize}) => PediaFile(
        id: id,
        originalFilename: originalFilename,
        contentType: contentType,
        fileSize: fileSize ?? this.fileSize,
        url: url,
        createdAt: createdAt,
        sha256: sha256 ?? this.sha256,
      );

  /// This upload as a post's media object. See [MediaFile.toPostMedia].
  PostMedia toPostMedia({
    int? width,
    int? height,
    String? thumbnailUrl,
    num? durationInSeconds,
    String? title,
    String? alt,
    bool loop = false,
  }) =>
      PostMedia(
        url: url,
        mimeType: contentType,
        sha256: sha256.isEmpty ? null : sha256,
        sizeInBytes: fileSize > 0 ? fileSize : null,
        width: width,
        height: height,
        thumbnailUrl: thumbnailUrl,
        durationInSeconds: durationInSeconds,
        title: title,
        alt: alt,
        loop: loop,
      );
}

/// Progress callback for the two upload calls: bytes handed to the socket so
/// far, and the file's total.
typedef UploadProgress = void Function(int sent, int total);

/// Answer of `POST /api/:address/media/move`:
/// the file's new URL in the other door. [id] is a string in
/// both directions (the pedia hex id, or the public row id as text).
/// [deletedOld] is false when another live post still used the old copy.
class MovedMedia {
  final String url;
  final String id;
  final String contentType;
  final bool deletedOld;

  MovedMedia({
    required this.url,
    required this.id,
    required this.contentType,
    required this.deletedOld,
  });

  factory MovedMedia.fromJson(Map<String, dynamic> json) {
    return MovedMedia(
      url: json['url'] as String,
      id: (json['id'] ?? '').toString(),
      contentType: json['content_type'] ?? 'application/octet-stream',
      deletedOld: json['deleted_old'] == true,
    );
  }
}

/// Answer of `GET /api/limits`: the
/// text caps an SSP enforces on posts and comments, rune-counted. A composer
/// reads them once per server and stops the author at the cap instead of
/// letting them learn it from a 413. A zero or missing value means that cap
/// is off on this host, so each getter answers null for "unlimited".
class SspLimits {
  final int maxTitleChars;
  final int maxBodyChars;
  final int maxSummaryChars;
  final int maxCommentChars;
  final int maxRequestBytes;

  const SspLimits({
    required this.maxTitleChars,
    required this.maxBodyChars,
    required this.maxSummaryChars,
    required this.maxCommentChars,
    required this.maxRequestBytes,
  });

  factory SspLimits.fromJson(Map<String, dynamic> json) {
    int n(String k) => (json[k] is num) ? (json[k] as num).toInt() : 0;
    return SspLimits(
      maxTitleChars: n('max_title_chars'),
      maxBodyChars: n('max_body_chars'),
      maxSummaryChars: n('max_summary_chars'),
      maxCommentChars: n('max_comment_chars'),
      maxRequestBytes: n('max_request_bytes'),
    );
  }

  /// null = no cap on this host.
  int? get title => maxTitleChars > 0 ? maxTitleChars : null;
  int? get body => maxBodyChars > 0 ? maxBodyChars : null;
  int? get summary => maxSummaryChars > 0 ? maxSummaryChars : null;
  int? get comment => maxCommentChars > 0 ? maxCommentChars : null;
}

/// Answer of `GET /privacy_and_agreements`:
/// an SSP's house rules and privacy notice, one dated version,
/// each text keyed by language ("en" always present). The app shows it before
/// the subscribe transaction; subscribing IS the acceptance.
class SspRules {
  final int version;
  final String effectiveFrom; // YYYY-MM-DD
  final Map<String, String> rules;
  final Map<String, String> privacy;

  const SspRules({
    required this.version,
    required this.effectiveFrom,
    required this.rules,
    required this.privacy,
  });

  static Map<String, String> _texts(Object? v) => v is Map
      ? {for (final e in v.entries) if (e.value is String) '${e.key}': e.value as String}
      : const {};

  /// null when the body lacks a version or the English texts.
  static SspRules? fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    final rules = _texts(json['rules']);
    final privacy = _texts(json['privacy']);
    if (version is! num || version <= 0) return null;
    if ((rules['en'] ?? '').trim().isEmpty || (privacy['en'] ?? '').trim().isEmpty) return null;
    return SspRules(
      version: version.toInt(),
      effectiveFrom: json['effective_from'] is String ? json['effective_from'] as String : '',
      rules: rules,
      privacy: privacy,
    );
  }

  /// The text in [languageCode], falling back to English.
  String rulesFor(String languageCode) => rules[languageCode] ?? rules['en']!;
  String privacyFor(String languageCode) => privacy[languageCode] ?? privacy['en']!;
}

/// What [PublicOSSsp.fetchRules] found on a server.
enum SspRulesStatus { published, notPublished, unreachable }

class PediaListResponse {
  final List<PediaFile> files;
  final int count;
  final MediaQuota quota;

  PediaListResponse({
    required this.files,
    required this.count,
    required this.quota,
  });

  factory PediaListResponse.fromJson(Map<String, dynamic> json) {
    return PediaListResponse(
      files: ((json['files'] ?? []) as List)
          .map((f) => PediaFile.fromJson(f))
          .toList(),
      count: json['count'] ?? 0,
      quota: MediaQuota.fromJson(json['quota'] ?? {}),
    );
  }
}

/// Server-side account record for a feed server.
///
/// Mirrors the Go `Account` struct in `my_rss_server/internal/models/models.go`.
/// This is the **server's own copy** of account metadata (display name, bio,
/// avatar URL, media quota usage) — independent of the on-chain [Contact]
/// record that lives in `AccountMemory` / `accountManager`. Users manage
/// this via `PUT /api/account` (wrapped by `PublicOSChannels.updateFeedAccount`).
///
/// The `username` field is set at account creation on the server and is
/// **immutable from the client** — the Go `UpdateAccount` handler does not
/// accept it as a field. All other display fields are editable.
class FeedAccount {
  final int id;
  final String accountAddress;
  final String username;
  final String displayName;
  final String bio;
  final String avatarUrl;
  final int mediaQuotaMb;
  final int mediaUsedMb;
  final int mediaFileCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FeedAccount({
    required this.id,
    required this.accountAddress,
    required this.username,
    required this.displayName,
    required this.bio,
    required this.avatarUrl,
    required this.mediaQuotaMb,
    required this.mediaUsedMb,
    required this.mediaFileCount,
    this.createdAt,
    this.updatedAt,
  });

  factory FeedAccount.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String) return DateTime.tryParse(v);
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      return null;
    }

    return FeedAccount(
      id: (json['id'] as num?)?.toInt() ?? 0,
      accountAddress: json['account_address'] as String? ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      mediaQuotaMb: (json['media_quota_mb'] as num?)?.toInt() ?? 0,
      mediaUsedMb: (json['media_used_mb'] as num?)?.toInt() ?? 0,
      mediaFileCount: (json['media_file_count'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'account_address': accountAddress,
        'username': username,
        'display_name': displayName,
        'bio': bio,
        'avatar_url': avatarUrl,
        'media_quota_mb': mediaQuotaMb,
        'media_used_mb': mediaUsedMb,
        'media_file_count': mediaFileCount,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  FeedAccount copyWith({
    int? id,
    String? accountAddress,
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
    int? mediaQuotaMb,
    int? mediaUsedMb,
    int? mediaFileCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FeedAccount(
      id: id ?? this.id,
      accountAddress: accountAddress ?? this.accountAddress,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      mediaQuotaMb: mediaQuotaMb ?? this.mediaQuotaMb,
      mediaUsedMb: mediaUsedMb ?? this.mediaUsedMb,
      mediaFileCount: mediaFileCount ?? this.mediaFileCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
