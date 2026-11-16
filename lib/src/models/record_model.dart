import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_card.dart';
import 'social_links.dart';

enum RecordType { profile, settings, router, custom, system }

/// What a profile record is. `unknown` (appended last) is any key
/// that is not a known identity key, not a TYPED card and not on the fixed
/// [SocialLinks] list: no surface renders it.
enum ProfileSubtype { identity, text, social, card, status, unknown }

enum RouterSubtype { tab, channel }

class Record {
  final String key;
  final String value;
  final DateTime expiration;
  final RecordType type;
  final bool isExpired;
  final Map<String, dynamic> metadata;
  final ProfileSubtype? profileSubtype;
  final RouterSubtype? routerSubtype;
  final bool noTitle;

  Record({
    required this.key,
    required this.value,
    required this.expiration,
    required this.type,
    required this.isExpired,
    required Map<String, dynamic> metadata,
    this.profileSubtype,
    this.routerSubtype,
    this.noTitle = false,
  }) : this.metadata = Map<String, dynamic>.from(metadata) {
    if (!this.metadata.containsKey('opacity')) {
      this.metadata['opacity'] = 1.0;
    } else if (this.metadata['opacity'] is! num) {
      final dynamic currentOpacity = this.metadata['opacity'];
      if (currentOpacity is String) {
        this.metadata['opacity'] = double.tryParse(currentOpacity) ?? 1.0;
      } else {
        this.metadata['opacity'] = 1.0;
      }
    } else {
      this.metadata['opacity'] = (this.metadata['opacity'] as num).toDouble();
    }
  }

  // ---------------------------------------------------------------------------
  // Expiration on chain — Unix SECONDS, 0 = never
  // ---------------------------------------------------------------------------

  /// "Never expires": the epoch, which goes to the chain as 0. The default for
  /// every factory: the apps never ask for an expiry, and a profile record
  /// lives until its owner deletes it. A record that must
  /// really end passes a date.
  static final DateTime never = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  /// The last second a date can be read as (9999-12-31T23:59:59Z). A chain
  /// value beyond it is read as [never]: records written by earlier app builds
  /// carry MILLISECONDS (the apps converted with `millisecondsSinceEpoch`),
  /// which the contract, counting seconds, already treats as never expiring.
  /// Reading them as never lets the next save write 0, so they heal on edit.
  static const int maxChainSeconds = 253402300799;

  /// The `expiration` argument for `setRecord` / `setMultipleRecords`.
  BigInt get chainExpiration {
    final ms = expiration.millisecondsSinceEpoch;
    return ms <= 0 ? BigInt.zero : BigInt.from(ms ~/ 1000);
  }

  /// A chain `expiration` (seconds) as a date; 0 and out-of-range values = [never].
  static DateTime expirationFromChain(BigInt seconds) {
    if (seconds <= BigInt.zero || seconds > BigInt.from(maxChainSeconds)) return never;
    return DateTime.fromMillisecondsSinceEpoch(seconds.toInt() * 1000, isUtc: true);
  }

  /// The key of a channel tab (a router record, subtype `channel`): `channel.<slug>`.
  /// A record key is at most 31 bytes and a channel slug has no length limit, so
  /// a slug over 23 is cut to 14 and given 8 hex of its SHA-256 (31 exactly).
  /// Readers find channel tabs by subtype and URL, never by key.
  static String channelTabKey(String slug) {
    final k = 'channel.$slug';
    if (k.length <= 31) return k;
    final h = sha256.convert(utf8.encode(slug)).toString().substring(0, 8);
    return 'channel.${slug.substring(0, 14)}-$h';
  }

  // ---------------------------------------------------------------------------
  // Subtype → contract string
  // ---------------------------------------------------------------------------

  String? get subtype {
    if (profileSubtype != null) {
      switch (profileSubtype!) {
        case ProfileSubtype.identity:
          return 'identity';
        case ProfileSubtype.text:
          return 'text';
        case ProfileSubtype.social:
          return 'social';
        case ProfileSubtype.card:
          return 'card';
        case ProfileSubtype.status:
          return 'status';
        // Never written: an unrecognised record keeps whatever it stored.
        case ProfileSubtype.unknown:
          return null;
      }
    }
    if (routerSubtype != null) {
      switch (routerSubtype!) {
        case RouterSubtype.tab:
          return 'tab';
        case RouterSubtype.channel:
          return 'channel';
      }
    }
    return null;
  }

  static ProfileSubtype? _profileSubtypeFromString(String? s) {
    if (s == null) return null;
    switch (s) {
      case 'identity':
        return ProfileSubtype.identity;
      case 'text':
        return ProfileSubtype.text;
      case 'social':
        return ProfileSubtype.social;
      case 'card':
        return ProfileSubtype.card;
      case 'status':
        return ProfileSubtype.status;
      default:
        return null;
    }
  }

  // No legacy 'rss' accept: the rename ships on a fresh re-deploy, so the
  // string never exists on-chain post-deploy.
  static RouterSubtype? _routerSubtypeFromString(String? s) {
    if (s == null) return null;
    switch (s) {
      case 'tab':
        return RouterSubtype.tab;
      case 'channel':
        return RouterSubtype.channel;
      default:
        return null;
    }
  }

  /// Detects ProfileSubtype from record key.
  static ProfileSubtype _detectProfileSubtype(String key) {
    final lowerKey = key.toLowerCase();
    if (lowerKey == 'profile.avatar' || lowerKey == 'profile.banner' || lowerKey == 'profile.color') {
      return ProfileSubtype.identity;
    }
    // The page background is part of how the profile LOOKS, like the banner,
    // not a social link: classed `social`, every
    // surface would list it as a link tile named after the key.
    // Re-derived on read (`fromJson`), so records stored with an older
    // classification are reclassified too.
    if (lowerKey == '_osux_profile_background_url_') {
      return ProfileSubtype.identity;
    }
    if (lowerKey == 'profile.bio') return ProfileSubtype.text;
    if (lowerKey == 'profile.status') return ProfileSubtype.status;
    if (lowerKey.startsWith('card.')) return ProfileSubtype.card;
    // A social link only when the key is on the FIXED list; anything else
    // is not displayed. Otherwise any stray profile record (the page
    // background, a DNS-style TXT record) would render as a link tile.
    if (SocialLinks.isKnown(lowerKey)) return ProfileSubtype.social;
    return ProfileSubtype.unknown;
  }

  // ---------------------------------------------------------------------------
  // Factories
  // ---------------------------------------------------------------------------

  factory Record.asProfile({
    required String key,
    required String value,
    int? icon,
    Color? color,
    String? link,
    DateTime? expiration,
    bool isExpired = false,
    bool noTitle = false,
    int width = 1,
    double borderRadius = 16,
    int order = 0,
    String? rank,
    int height = 1,
    String? fontFamily,
    double? fontSize,
    String? alignment,
    Map<String, dynamic>? customMetadataAttributes,
    double opacity = 1.0,
  }) {
    final ProfileSubtype detectedSubtype = _detectProfileSubtype(key);

    final Map<String, dynamic> metadataMap = {
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color.value,
      if (link != null) 'link': link,
      'noTitle': noTitle,
      'width': width,
      'borderRadius': borderRadius,
      'order': order,
      if (rank != null) 'rank': rank,
      'height': height,
      'opacity': opacity,
    };

    if (fontFamily != null) metadataMap['fontFamily'] = fontFamily;
    if (fontSize != null) metadataMap['fontSize'] = fontSize;
    if (alignment != null) metadataMap['alignment'] = alignment;

    if (customMetadataAttributes != null) {
      metadataMap.addAll(customMetadataAttributes);
    }
    metadataMap['opacity'] = opacity;

    return Record(
      key: key,
      value: value,
      expiration: expiration ?? never,
      type: RecordType.profile,
      isExpired: isExpired,
      profileSubtype: detectedSubtype,
      metadata: metadataMap,
      noTitle: noTitle,
    );
  }

  factory Record.asSettings({
    required String key,
    required String value,
    required bool isSystem,
    dynamic defaultValue,
    DateTime? expiration,
    bool isExpired = false,
    double opacity = 1.0,
  }) {
    final Map<String, dynamic> metadataMap = {
      'isSystem': isSystem,
      if (defaultValue != null) 'defaultValue': defaultValue,
      'opacity': opacity,
    };

    return Record(
      key: key,
      value: value,
      expiration: expiration ?? never,
      type: RecordType.settings,
      isExpired: isExpired,
      metadata: metadataMap,
    );
  }

  factory Record.asRouter({
    required String key,
    required String value,
    required RouterSubtype routerSubtype,
    DateTime? expiration,
    bool isExpired = false,
    String? name,
    int order = 0,
    Map<String, dynamic>? extraMetadata,
  }) {
    final Map<String, dynamic> metadataMap = {
      if (name != null) 'name': name,
      'order': order,
    };

    if (extraMetadata != null) {
      metadataMap.addAll(extraMetadata);
    }

    return Record(
      key: key,
      value: value,
      expiration: expiration ?? never,
      type: RecordType.router,
      isExpired: isExpired,
      routerSubtype: routerSubtype,
      metadata: metadataMap,
    );
  }

  factory Record.asCustom({
    required String key,
    required String value,
    required Map<String, dynamic> customMetadata,
    DateTime? expiration,
    bool isExpired = false,
    double opacity = 1.0,
  }) {
    final Map<String, dynamic> metadataWithOpacity = Map<String, dynamic>.from(customMetadata);
    metadataWithOpacity['opacity'] = opacity;

    return Record(
      key: key,
      value: value,
      expiration: expiration ?? never,
      type: RecordType.custom,
      isExpired: isExpired,
      metadata: metadataWithOpacity,
    );
  }

  // ---------------------------------------------------------------------------
  // Getters — profile records
  // ---------------------------------------------------------------------------

  String get name => key;

  int? get icon => type == RecordType.profile ? metadata['icon'] as int? : null;
  Color? get color => type == RecordType.profile && metadata['color'] != null ? Color(metadata['color'] as int) : null;
  String? get link => type == RecordType.profile ? metadata['link'] as String? : null;

  int get width => type == RecordType.profile ? (metadata['width'] as int?) ?? 1 : 1;
  int get height => type == RecordType.profile ? (metadata['height'] as int?) ?? 1 : 1;
  double get borderRadius => type == RecordType.profile
      ? (() {
          try {
            return (metadata['borderRadius'] as double?) ?? 16.0;
          } catch (_) {
            return (metadata['borderRadius'] as int?)?.toDouble() ?? 16.0;
          }
        })()
      : 16.0;
  int get order => (metadata['order'] as int?) ?? 0;

  /// Fractional-index order key (LexoRank string) used for grid + social-strip
  /// placement. Null for legacy records written before ordering existed; the
  /// read path ([PublicOSContacts.getAllUserRecords]) sorts ranked records
  /// first (by this key), then unranked in chain-enumeration order. Supersedes
  /// the vestigial [order] int (which was never populated). See
  /// `utils/lexorank.dart` for how ranks are generated.
  String? get rank {
    final r = metadata['rank'];
    return r is String && r.isNotEmpty ? r : null;
  }

  // Text styling (cards + text subtypes)
  String? get textElementFontFamily => profileSubtype == ProfileSubtype.card || profileSubtype == ProfileSubtype.text ? metadata['fontFamily'] as String? : null;
  double? get textElementFontSize => profileSubtype == ProfileSubtype.card || profileSubtype == ProfileSubtype.text ? metadata['fontSize'] as double? : null;
  String? get textElementAlignment => profileSubtype == ProfileSubtype.card || profileSubtype == ProfileSubtype.text ? metadata['alignment'] as String? : null;

  // Bio styling
  Color get bioTextColor {
    if (profileSubtype == ProfileSubtype.text) {
      final colorValue = metadata['bioTextColor'];
      if (colorValue is int) return Color(colorValue);
      return Colors.transparent;
    }
    return Colors.transparent;
  }

  bool get bioBorderIsVisible {
    if (profileSubtype == ProfileSubtype.text && metadata.containsKey('bioBorderVisible')) {
      final visibleValue = metadata['bioBorderVisible'];
      if (visibleValue is bool) return visibleValue;
    }
    return false;
  }

  Color get bioBorderColor {
    if (profileSubtype == ProfileSubtype.text) {
      final colorValue = metadata['bioBorderColor'];
      if (colorValue is int) return Color(colorValue);
      return Colors.transparent;
    }
    return Colors.transparent;
  }

  double get bioBorderWidth {
    if (profileSubtype == ProfileSubtype.text && metadata.containsKey('bioBorderWidth')) {
      final widthValue = metadata['bioBorderWidth'];
      if (widthValue is double) return widthValue;
      if (widthValue is int) return widthValue.toDouble();
    }
    return 1.0;
  }

  // ---------------------------------------------------------------------------
  // Getters — settings records
  // ---------------------------------------------------------------------------

  bool? get isSystem => type == RecordType.settings ? metadata['isSystem'] as bool? : null;
  dynamic get defaultValue => type == RecordType.settings ? metadata['defaultValue'] : null;

  // ---------------------------------------------------------------------------
  // Getters — router records (tabs)
  // ---------------------------------------------------------------------------

  String? get tabName => type == RecordType.router ? metadata['name'] as String? : null;
  String? get tabUrl => type == RecordType.router ? value : null;

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'type': type.index,
      'metadata': metadata,
      'expiration': expiration.toIso8601String(),
      'isExpired': isExpired,
      'noTitle': noTitle,
      if (subtype != null && subtype!.isNotEmpty) 'subtype': subtype,
    };
  }

  /// The on-chain `value` blob for this record.
  ///
  /// Expiration is owned by the contract: it travels in the
  /// `setRecord`/`setMultipleRecords` `expiration` argument and is returned by
  /// `getRecord`/`getAllRecords`. It is deliberately NOT written into this blob.
  /// The contract's `expiration` is the single source of truth for a record's
  /// lifetime; a second copy in the blob is redundant and can drift in
  /// units (ms vs seconds) between writers, which breaks profile reorders.
  /// `isExpired` is likewise derived from the contract (`expired`) on read, so
  /// it is omitted here too.
  /// Keys `fetchContact` stamps onto a record's metadata at VIEW time and that
  /// must not ride back to the chain on a re-save. The NFT four are the client's
  /// cached verdict (art URL, ownership, when it was checked, and `nftVerified`,
  /// the full verdict with the token's whole metadata inside); the app-card set
  /// is the trust walk's answer, including an origin that is a trust token.
  /// Every write goes through [toChainValue], so this is the one place to drop
  /// them -- `copyWith(rank:)` on a reorder and `updateVisual` on a resize both
  /// start from a stamped record and would otherwise persist it verbatim.
  /// `nftVerified` alone can pass [maxChainValueBytes] (an on-chain-art token
  /// carries its image as a `data:` URI), which refused the write outright.
  static const Set<String> _viewTimeMetadataKeys = {
    'nftImage', 'nftOwned', 'nftCheckedAt', 'nftVerified',
    ...AppCardMeta.viewTimeKeys,
  };

  // The chain's limits on one record (RecordManager):
  // the stored value (this whole JSON envelope, not the text a user
  // typed) at most 2048 BYTES, the custom type at most 64. Bytes, not characters:
  // an emoji or an @mention token costs more than it looks. Checked before a write
  // so the user gets a reason instead of a refused transaction.
  static const int maxChainValueBytes = 2048;
  static const int maxSubtypeBytes = 64;

  /// The exact string a write stores as the value.
  String toChainJson() => jsonEncode(toChainValue());

  /// Size of [toChainJson] in bytes.
  int get chainValueBytes => utf8.encode(toChainJson()).length;

  /// Null when the chain will take this record; otherwise a sentence for the user.
  String? get chainSizeProblem {
    final bytes = chainValueBytes;
    if (bytes > maxChainValueBytes) {
      return 'This is too long to save: ${bytes - maxChainValueBytes} bytes over the limit. '
          'Shorten the text or the link.';
    }
    if (utf8.encode(subtype ?? '').length > maxSubtypeBytes) {
      return 'This record type name is too long to save.';
    }
    return null;
  }

  Map<String, dynamic> toChainValue() {
    final Map<String, dynamic> chainMetadata = {
      for (final e in metadata.entries)
        if (!_viewTimeMetadataKeys.contains(e.key)) e.key: e.value,
    };
    return {
      'key': key,
      'value': value,
      'type': type.index,
      'metadata': chainMetadata,
      'noTitle': noTitle,
      if (subtype != null && subtype!.isNotEmpty) 'subtype': subtype,
    };
  }

  factory Record.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> recordData;

    if (json['value'] is String) {
      try {
        final decodedValue = jsonDecode(json['value'] as String);
        if (decodedValue is Map<String, dynamic> && decodedValue.containsKey('key') && decodedValue.containsKey('value') && decodedValue.containsKey('metadata')) {
          recordData = decodedValue;
        } else {
          recordData = json;
        }
      } catch (e) {
        recordData = json;
      }
    } else {
      recordData = json;
    }

    Map<String, dynamic> metadata;
    if (recordData['metadata'] is String) {
      try {
        metadata = Map<String, dynamic>.from(jsonDecode(recordData['metadata'] as String));
      } catch (e) {
        metadata = {};
      }
    } else if (recordData['metadata'] is Map) {
      metadata = Map<String, dynamic>.from(recordData['metadata'] as Map);
    } else {
      metadata = {};
    }

    if (recordData.containsKey('opacity') && !metadata.containsKey('opacity')) {
      metadata['opacity'] = recordData['opacity'];
    }

    int typeValue;
    if (recordData['type'] is String) {
      typeValue = BigInt.parse(recordData['type'] as String).toInt();
    } else if (recordData['type'] is BigInt) {
      typeValue = (recordData['type'] as BigInt).toInt();
    } else if (recordData['type'] is int) {
      typeValue = recordData['type'] as int;
    } else {
      typeValue = RecordType.custom.index;
    }
    // Clamp to valid range
    if (typeValue < 0 || typeValue >= RecordType.values.length) {
      typeValue = RecordType.custom.index;
    }

    final recordType = RecordType.values[typeValue];
    final String? subtypeStr = recordData['subtype'] as String?;

    ProfileSubtype? profileSubtype;
    RouterSubtype? routerSubtype;

    if (recordType == RecordType.profile) {
      final stored = _profileSubtypeFromString(subtypeStr);
      // The KEY decides what a profile record is; the stored subtype only
      // confirms a card:
      //  · identity / bio / status keys and the fixed social list classify by
      //    key, whatever the blob carries (a stored value can be stale: older
      //    writers stamped the page background `social`);
      //  · a card must be DECLARED one: key `card.*` AND a stored `card`
      //    subtype (every writer stamps it); a `card.*` key that declares
      //    something else is not shown. A blob with no subtype at all (built
      //    in memory, pre-subtype data) still reads as a card from its key;
      //  · anything else is `unknown`, and no surface renders it.
      final key = recordData['key'];
      if (key is String) {
        final derived = _detectProfileSubtype(key);
        profileSubtype = derived == ProfileSubtype.card &&
                stored != null &&
                stored != ProfileSubtype.card
            ? ProfileSubtype.unknown
            : derived;
      } else {
        profileSubtype = stored;
      }
    } else if (recordType == RecordType.router) {
      routerSubtype = _routerSubtypeFromString(subtypeStr);
    }

    // Expiration is owned by the contract. Chain reads apply the authoritative
    // `expiration` arg via copyWith after this factory runs, so the value blob
    // no longer carries it (see [toChainValue]). Local/DB serialization keeps an
    // ISO-8601 string (see [toJson]); anything else falls back to the epoch
    // sentinel, which round-trips to the contract's "never expires" (0).
    final dynamic rawExpiration = recordData['expiration'];
    final DateTime expiration = rawExpiration is String
        ? (DateTime.tryParse(rawExpiration) ??
            DateTime.fromMillisecondsSinceEpoch(0))
        : DateTime.fromMillisecondsSinceEpoch(0);

    return Record(
      key: recordData['key'] as String? ?? '',
      value: recordData['value'] as String? ?? '',
      type: recordType,
      metadata: metadata,
      expiration: expiration,
      isExpired: recordData['isExpired'] as bool? ?? false,
      profileSubtype: profileSubtype,
      routerSubtype: routerSubtype,
      noTitle: recordData['noTitle'] as bool? ?? false,
    );
  }

  // ---------------------------------------------------------------------------
  // Copy / update
  // ---------------------------------------------------------------------------

  Record copyWith({
    String? key,
    String? value,
    DateTime? expiration,
    RecordType? type,
    bool? isExpired,
    Map<String, dynamic>? metadata,
    ProfileSubtype? profileSubtype,
    RouterSubtype? routerSubtype,
    bool? noTitle,
    String? rank,
  }) {
    final Map<String, dynamic> newMetadata = metadata ?? Map<String, dynamic>.from(this.metadata);

    // Fractional-index order key (LexoRank). Set on reorder / rank-at-creation /
    // bake; merged into metadata so it survives the JSON round-trip to chain.
    if (rank != null) newMetadata['rank'] = rank;

    if (newMetadata.containsKey('opacity') && newMetadata['opacity'] is! double) {
      if (newMetadata['opacity'] is num) {
        newMetadata['opacity'] = (newMetadata['opacity'] as num).toDouble();
      } else if (newMetadata['opacity'] is String) {
        newMetadata['opacity'] = double.tryParse(newMetadata['opacity'] as String) ?? 1.0;
      }
    }

    return Record(
      key: key ?? this.key,
      value: value ?? this.value,
      expiration: expiration ?? this.expiration,
      type: type ?? this.type,
      isExpired: isExpired ?? this.isExpired,
      metadata: newMetadata,
      profileSubtype: profileSubtype ?? this.profileSubtype,
      routerSubtype: routerSubtype ?? this.routerSubtype,
      noTitle: noTitle ?? this.noTitle,
    );
  }

  Record updateVisual({
    int? width,
    double? borderRadius,
    int? order,
    Color? color,
    int? height,
  }) {
    final newMetadata = Map<String, dynamic>.from(metadata);
    if (width != null) newMetadata['width'] = width;
    if (borderRadius != null) newMetadata['borderRadius'] = borderRadius;
    if (order != null) newMetadata['order'] = order;
    if (height != null) newMetadata['height'] = height;
    if (color != null) newMetadata['color'] = color.value;

    return copyWith(metadata: newMetadata);
  }

  // ---------------------------------------------------------------------------
  // Equality
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Record &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          value == other.value &&
          type == other.type &&
          expiration == other.expiration &&
          isExpired == other.isExpired &&
          profileSubtype == other.profileSubtype &&
          routerSubtype == other.routerSubtype &&
          noTitle == other.noTitle &&
          mapEquals(metadata, other.metadata);

  @override
  int get hashCode =>
      key.hashCode ^ value.hashCode ^ type.hashCode ^ expiration.hashCode ^ isExpired.hashCode ^ profileSubtype.hashCode ^ routerSubtype.hashCode ^ noTitle.hashCode ^ metadata.hashCode;
}

class RecordFactory {
  static String listToJson(List<Record> records) {
    return jsonEncode(records.map((record) => record.toJson()).toList());
  }

  static List<Record> listFromJson(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Record.fromJson(json as Map<String, dynamic>)).toList();
  }
}
