import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:publicos_core/src/utils/log.dart';
import 'package:publicos_core/src/models/record_model.dart';
import 'package:publicos_core/src/models/nft_avatar.dart';
import 'package:publicos_core/src/utils/string_utils.dart';
import 'package:wallet/wallet.dart';

/// Represents an XMTP messaging address with its context (one of possibly
/// many ETH addresses registered to a person's inbox).
class ContactSession {
  final EthereumAddress address;
  final String label; // "main", "support", "community", ...
  final Map<String, dynamic>? metadata;

  ContactSession({
    required this.address,
    required this.label,
    this.metadata,
  });

  factory ContactSession.fromJson(Map<String, dynamic> json) {
    return ContactSession(
      address: EthereumAddress.fromHex(json['address']),
      label: json['label'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address.eip55With0x,
      'label': label,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

/// An entry in a person's `registeredInboxIDs` list — maps an inbox ID to
/// a human-readable label ("main", "work", ...). Used by the view layer to
/// resolve conversation peer inbox IDs back to a [Contact].
class InboxEntry {
  final String inboxId; // 64-char hex
  final String label;

  InboxEntry({required this.inboxId, required this.label});

  factory InboxEntry.fromJson(Map<String, dynamic> json) {
    return InboxEntry(
      inboxId: json['inboxId'] as String,
      label: (json['label'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'inboxId': inboxId,
        'label': label,
      };
}

/// Represents a **person** (or an **organization**) in the system.
///
/// A Contact is pure identity — it has nothing to do with messaging channels.
/// XMTP conversations live in [XmtpConversation]. When a conversation needs
/// a display name/avatar, the view layer resolves its `peerInboxId` against
/// the contacts table (matching against [registeredInboxIDs]) and stores
/// the result on the conversation's `contact` property.
class Contact {
  
  // ── Identity ────────────────────────────────────────────────────────────
  final String displayName; // Local display name (required, may be a stub)
  final String? publicosDisplayName; // On-chain PublicOS username ("alice")
  final EthereumAddress? publicosAddress; // Account Blueprint Contract address
  final bool isOrgAccount; // true for orgs/DAOs

  // ── Blockchain identity ────────────────────────────────────────────────
  /// ETH addresses registered to this person's inbox(es), extracted from
  /// XMTP inbox state. Used by identity resolution (ENS/Farcaster).
  final List<ContactSession>? sessions;

  /// Profile records from chain: avatar, banner, bio, color, social links.
  final List<Record> records;

  /// All XMTP inbox IDs this person owns, with labels. View layer matches
  /// conversation peer inbox IDs against this list to resolve display info.
  final List<InboxEntry>? registeredInboxIDs;

  // ── Org membership (only when isOrgAccount == true) ────────────────────
  /// Member account addresses for this org. May be partial — large orgs
  /// are lazy-loaded via `fetchOrgMembers(address, offset, limit)`.
  final List<EthereumAddress>? orgMembers;

  /// Total member count from chain. Used by the view for pagination UI.
  final int? orgMemberCount;

  // ── Relationship ────────────────────────────────────────────────────────
  final bool isBlocked;
  final bool isSupport;

  // ── Metadata ────────────────────────────────────────────────────────────
  final String? createdBy; // For orgs: founder's displayName
  /// For orgs: founder's account address (the org creator from chain). The
  /// view layer silently resolves this into a Contact for display — never
  /// changes once set, so it's persisted and never refetched.
  final EthereumAddress? founderAddress;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// On-chain citizenship, lazily enriched when the contact's profile is
  /// viewed and cached locally. null = never checked; the create-org flow
  /// reads this instead of a per-contact chain call. Re-checked on every
  /// profile visit while not `true` (citizenship is hard to lose).
  final bool? isCitizen;

  /// Orgs only — whether this org is a *public* org (admits only citizens as
  /// members). The org analog of [isCitizen]: lazily enriched on profile/icon,
  /// cached locally; null = never checked. Drives the contact icon's badge
  /// axis for org accounts (public org → clean, non-public org → phantom).
  final bool? isPublicOrg;

  /// Icon-managed NFT-avatar verdict cache — a [VerifiedNftAvatar] encoded as
  /// JSON, or null. Holds the resolved metadata (image inside), the ownership
  /// verdict (drives sparkles/shimmer) and the TTL anchor. Written by the
  /// contact icon, never by a chain re-fetch. See [verifiedNftAvatarData].
  final String? verifiedNftAvatar;

  /// Banner analog of [verifiedNftAvatar] — a [VerifiedNftAvatar] (same JSON
  /// shape) encoded for the `profile.banner.nft` pointer, or null. Written by
  /// the `NftBanner` widget at render time, never by a chain re-fetch. See
  /// [verifiedNftBannerData].
  final String? verifiedNftBanner;

  /// User-set bookmark flag. null = unset (DB default false). Reserved for an
  /// upcoming real-vs-searched contact distinction; not wired to UI yet.
  final bool? bookmarked;

  // ── Group stub ──────────────────────────────────────────────────────────
  /// XMTP conversation topic for group-chat stubs. Null for person contacts.
  /// Presence marks this Contact as a group stub — see [isGroupChat].
  /// Group metadata (image, description, members) lives on [XmtpConversation];
  /// the stub only carries local display name + avatar/color records so the
  /// Browser and ContactIcon can render it like any other contact.
  final String? xmtpConversationTopic;

  // ── Cached computed ─────────────────────────────────────────────────────
  Color? _iconColor;
  String? _avatarUrl;

  Contact({
    required this.displayName,
    this.publicosDisplayName,
    this.publicosAddress,
    this.isOrgAccount = false,
    this.sessions,
    this.records = const [],
    this.registeredInboxIDs,
    this.orgMembers,
    this.orgMemberCount,
    this.isBlocked = false,
    this.isSupport = false,
    this.createdBy,
    this.founderAddress,
    this.createdAt,
    this.updatedAt,
    this.xmtpConversationTopic,
    this.isCitizen,
    this.isPublicOrg,
    this.verifiedNftAvatar,
    this.verifiedNftBanner,
    this.bookmarked,
  });

  /// True when this Contact is a group-chat stub — identified by the
  /// presence of a conversation topic. Person contacts never set one.
  bool get isGroupChat => xmtpConversationTopic != null;

  /// Minimal person stub used when we only know an inbox ID and nothing
  /// else. Typically produced during conversation resolution when the peer
  /// has no PublicOS account.
  factory Contact.stub({required String displayName}) {
    return Contact(displayName: displayName);
  }

  /// Stub Contact representing an XMTP group conversation. Keyed by topic;
  /// seeded with a random `profile.color` so ContactIcon renders consistently
  /// on every read. If [imageUrl] is provided, a `profile.avatar` record is
  /// seeded too so the group's image shows wherever an avatar would.
  factory Contact.groupStub({
    required String topic,
    required String displayName,
    String? imageUrl,
  }) {
    final color = Colors.primaries[Random().nextInt(Colors.primaries.length)];
    final records = <Record>[
      Record.asProfile(
        key: 'profile.color',
        value: color.toARGB32().toString(),
        expiration: DateTime.now().add(const Duration(days: 365 * 100)),
      ),
      if (imageUrl != null && imageUrl.isNotEmpty)
        Record.asProfile(
          key: 'profile.avatar',
          value: imageUrl,
          expiration: DateTime.now().add(const Duration(days: 365 * 100)),
        ),
    ];
    return Contact(
      displayName: displayName,
      xmtpConversationTopic: topic,
      records: records,
    );
  }

  // ── Computed display helpers ────────────────────────────────────────────
  Color get iconColor {
    if (_iconColor != null) return _iconColor!;
    final colorRecord = getRecord('profile.color');
    if (colorRecord != null) {
      try {
        _iconColor = Color(int.parse(colorRecord.value));
        return _iconColor!;
      } catch (_) {
        Log.w('Contact', 'Invalid profile.color: ${colorRecord.value}');
      }
    }
    _iconColor = Colors.primaries[Random().nextInt(Colors.primaries.length)];
    return _iconColor!;
  }

  String? get avatarUrl {
    if (_avatarUrl != null) return _avatarUrl;
    final avatarRecord = getRecord('profile.avatar');
    if (avatarRecord != null) {
      _avatarUrl = avatarRecord.value;
      return _avatarUrl;
    }
    return null;
  }

  /// Avatar URL preferring the resolved-PNG variant used for NFT-backed
  /// avatars. Matches `GlassContactIcon` / `ContactIcon` so notifications,
  /// in-app rows, and any other surface display the same image.
  String? get resolvedAvatarUrl =>
      getRecordValue('profile.avatar.resolved') ?? avatarUrl;

  /// Parsed `profile.avatar.nft` pointer, or null for a plain-URL avatar.
  NftAvatarRef? get nftAvatar =>
      NftAvatarRef.tryParse(getRecordValue('profile.avatar.nft'));

  /// Parsed NFT-avatar verdict cache (the [verifiedNftAvatar] column JSON).
  VerifiedNftAvatar? get verifiedNftAvatarData =>
      VerifiedNftAvatar.tryParse(verifiedNftAvatar);

  /// Parsed `profile.banner.nft` pointer, or null for a plain-URL banner.
  NftAvatarRef? get nftBanner =>
      NftAvatarRef.tryParse(getRecordValue('profile.banner.nft'));

  /// Parsed NFT-banner verdict cache (the [verifiedNftBanner] column JSON).
  /// Reuses the [VerifiedNftAvatar] model — same shape, banner surface.
  VerifiedNftAvatar? get verifiedNftBannerData =>
      VerifiedNftAvatar.tryParse(verifiedNftBanner);

  static const String defaultBannerUrl =
      'https://feeds.publicos.dev/media/a2239444.1794777687.png';

  String get bannerUrl {
    final bannerRecord = records
        .where((r) => r.key == 'profile.banner' && !r.isExpired)
        .firstOrNull;
    return bannerRecord?.value ?? defaultBannerUrl;
  }

  /// The banner the owner set: a non-empty, unexpired `profile.banner`, or
  /// null. Unlike [bannerUrl] there is no default: "removed" (an empty
  /// record) and "never set" (no record) both read null.
  String? get ownBannerUrl {
    final v = records
        .where((r) => r.key == 'profile.banner' && !r.isExpired)
        .firstOrNull
        ?.value
        .trim();
    return v == null || v.isEmpty ? null : v;
  }

  /// The page background (`_osux_profile_background_url_`), or null.
  String? get backgroundUrl {
    final v = records
        .where((r) => r.key == '_osux_profile_background_url_' && !r.isExpired)
        .firstOrNull
        ?.value
        .trim();
    return v == null || v.isEmpty ? null : v;
  }

  /// The owner says this profile holds mature content: a `mature_content`
  /// record whose value is `true`. Self-declared; the
  /// enforcement for one that doesn't declare is flag category 8, "sexual
  /// content without an adult label". The apps ask "are you 18+?" before
  /// showing such a profile. The key is off Core's fixed profile list, so it
  /// never renders as a tile.
  bool get isMatureContent => records.any((r) =>
      r.key == 'mature_content' &&
      !r.isExpired &&
      r.value.trim().toLowerCase() == 'true');

  /// The owner says software runs this account: an `automated_account` record
  /// whose value is `true`. Self-reported; an account that
  /// should and doesn't is a matter for flags and the court. A citizen is a
  /// person by its agreement, so the apps never show the robot on a citizen:
  /// the robot replaces the ghost on private accounts only.
  bool get isAutomatedAccount => records.any((r) =>
      r.key == 'automated_account' &&
      !r.isExpired &&
      r.value.trim().toLowerCase() == 'true');

  /// True when a banner slot should paint the background instead: no plain
  /// banner, no NFT banner, and a background exists (drop
  /// the banner and every banner surface falls back to the background,
  /// pinned to the TOP of the image -> paint it with `Alignment.topCenter`).
  bool get bannerIsBackground =>
      ownBannerUrl == null && nftBanner == null && backgroundUrl != null;

  /// What a banner slot paints: the owner's banner, else the background
  /// ([bannerIsBackground]), else [bannerUrl] (the default banner, or `''`
  /// for a removed one, as before). The edit sheets keep reading [bannerUrl].
  String get displayBannerUrl =>
      ownBannerUrl ?? (bannerIsBackground ? backgroundUrl! : bannerUrl);

  String get initials {
    final words = displayName.trim().split(' ');
    if (words.isEmpty) return '';
    if (words.length == 1) return words[0][0].toUpperCase();
    return (words[0][0] + words[words.length - 1][0]).toUpperCase();
  }

  Record? getRecord(String key) {
    try {
      return records.firstWhere((record) => record.key == key);
    } catch (_) {
      return null;
    }
  }

  dynamic getRecordValue(String key) {
    return getRecord(key)?.value;
  }

  ContactSession? get mainSession {
    if (sessions == null) return null;
    for (final c in sessions!) {
      if (c.label == 'main') return c;
    }
    return null;
  }

  List<ContactSession>? getAddressesByLabel(String label) =>
      sessions?.where((addr) => addr.label == label).toList();

  /// True if this contact's inbox list contains the given inbox ID.
  /// Used by view-layer conversation resolution.
  bool ownsInboxId(String inboxId) {
    final normalized = _normalizeInboxId(inboxId);
    if (normalized == null) return false;
    return registeredInboxIDs?.any((e) => e.inboxId == normalized) ?? false;
  }

  /// Find the label for a specific inbox ID on this contact (e.g. "main",
  /// "work"). Returns null if the inbox doesn't belong to this contact.
  String? labelForInboxId(String inboxId) {
    final normalized = _normalizeInboxId(inboxId);
    if (normalized == null) return null;
    return registeredInboxIDs
        ?.where((e) => e.inboxId == normalized)
        .firstOrNull
        ?.label;
  }

  /// Normalize an inbox ID to the canonical 64-char hex form used throughout
  /// the system. Accepts String, Uint8List, or a hex string with/without
  /// 0x prefix. Returns null on unrecognized input.
  static String? _normalizeInboxId(dynamic inboxId) {
    if (inboxId == null) return null;
    if (inboxId is Uint8List) return bytes32ToString(inboxId);
    if (inboxId is String) {
      var tempId = inboxId;
      if (tempId.startsWith('0x')) tempId = tempId.substring(2);
      if (tempId.length < 64) {
        tempId = tempId.padLeft(64, '0');
      } else if (tempId.length > 64) {
        tempId = tempId.substring(0, 64);
      }
      return tempId;
    }
    Log.w('Contact', 'Unexpected inbox ID type: ${inboxId.runtimeType}');
    return null;
  }

  /// Canonical inbox-ID normalizer exposed for use by resolution code.
  static String? normalizeInboxId(dynamic inboxId) => _normalizeInboxId(inboxId);

  Contact copyWith({
    String? displayName,
    String? publicosDisplayName,
    EthereumAddress? publicosAddress,
    bool? isOrgAccount,
    List<ContactSession>? sessions,
    List<Record>? records,
    List<InboxEntry>? registeredInboxIDs,
    List<EthereumAddress>? orgMembers,
    int? orgMemberCount,
    bool? isBlocked,
    bool? isSupport,
    String? createdBy,
    EthereumAddress? founderAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? xmtpConversationTopic,
    bool? isCitizen,
    bool? isPublicOrg,
    String? verifiedNftAvatar,
    String? verifiedNftBanner,
    bool? bookmarked,
  }) {
    return Contact(
      displayName: displayName ?? this.displayName,
      publicosDisplayName: publicosDisplayName ?? this.publicosDisplayName,
      publicosAddress: publicosAddress ?? this.publicosAddress,
      isOrgAccount: isOrgAccount ?? this.isOrgAccount,
      sessions: sessions ?? this.sessions,
      records: records ?? this.records,
      registeredInboxIDs: registeredInboxIDs ?? this.registeredInboxIDs,
      orgMembers: orgMembers ?? this.orgMembers,
      orgMemberCount: orgMemberCount ?? this.orgMemberCount,
      isBlocked: isBlocked ?? this.isBlocked,
      isSupport: isSupport ?? this.isSupport,
      createdBy: createdBy ?? this.createdBy,
      founderAddress: founderAddress ?? this.founderAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      xmtpConversationTopic:
          xmtpConversationTopic ?? this.xmtpConversationTopic,
      isCitizen: isCitizen ?? this.isCitizen,
      isPublicOrg: isPublicOrg ?? this.isPublicOrg,
      verifiedNftAvatar: verifiedNftAvatar ?? this.verifiedNftAvatar,
      verifiedNftBanner: verifiedNftBanner ?? this.verifiedNftBanner,
      bookmarked: bookmarked ?? this.bookmarked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      if (publicosDisplayName != null) 'publicosDisplayName': publicosDisplayName,
      if (publicosAddress != null) 'publicosAddress': publicosAddress!.eip55With0x,
      'isOrgAccount': isOrgAccount,
      if (sessions != null) 'sessions': sessions!.map((c) => c.toJson()).toList(),
      'records': records.map((r) => r.toJson()).toList(),
      if (registeredInboxIDs != null)
        'registeredInboxIDs': registeredInboxIDs!.map((e) => e.toJson()).toList(),
      if (orgMembers != null)
        'orgMembers': orgMembers!.map((a) => a.eip55With0x).toList(),
      if (orgMemberCount != null) 'orgMemberCount': orgMemberCount,
      'isBlocked': isBlocked,
      'isSupport': isSupport,
      if (createdBy != null) 'createdBy': createdBy,
      if (founderAddress != null) 'founderAddress': founderAddress!.eip55With0x,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (xmtpConversationTopic != null)
        'xmtpConversationTopic': xmtpConversationTopic,
      if (isCitizen != null) 'isCitizen': isCitizen,
      if (isPublicOrg != null) 'isPublicOrg': isPublicOrg,
      if (verifiedNftAvatar != null) 'verifiedNftAvatar': verifiedNftAvatar,
      if (verifiedNftBanner != null) 'verifiedNftBanner': verifiedNftBanner,
      if (bookmarked != null) 'bookmarked': bookmarked,
    };
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      displayName: json['displayName'] as String,
      publicosDisplayName: json['publicosDisplayName'] as String?,
      publicosAddress: json['publicosAddress'] != null
          ? EthereumAddress.fromHex(json['publicosAddress'] as String)
          : null,
      isOrgAccount: json['isOrgAccount'] as bool? ?? false,
      sessions: (json['sessions'] as List?)
          ?.map((c) => ContactSession.fromJson(c as Map<String, dynamic>))
          .toList(),
      records: (json['records'] as List? ?? [])
          .map((r) => Record.fromJson(r as Map<String, dynamic>))
          .toList(),
      registeredInboxIDs: (json['registeredInboxIDs'] as List?)
          ?.map((e) => InboxEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      orgMembers: (json['orgMembers'] as List?)
          ?.map((a) => EthereumAddress.fromHex(a as String))
          .toList(),
      orgMemberCount: json['orgMemberCount'] as int?,
      isBlocked: json['isBlocked'] as bool? ?? false,
      isSupport: json['isSupport'] as bool? ?? false,
      createdBy: json['createdBy'] as String?,
      founderAddress: json['founderAddress'] != null
          ? EthereumAddress.fromHex(json['founderAddress'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      xmtpConversationTopic: json['xmtpConversationTopic'] as String?,
      isCitizen: json['isCitizen'] as bool?,
      isPublicOrg: json['isPublicOrg'] as bool?,
      verifiedNftAvatar: json['verifiedNftAvatar'] as String?,
      verifiedNftBanner: json['verifiedNftBanner'] as String?,
      bookmarked: json['bookmarked'] as bool?,
    );
  }
}
