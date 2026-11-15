import 'dart:convert';

/// Canonical event-type slugs for [ActivityEvent.eventType].
///
/// Kept as plain string constants (not a Dart enum) on purpose: a future
/// Phase-B BSP-side indexer can serve the exact same shape over the wire
/// without a Dart enum sitting on the boundary. The view layer switches on
/// these to build human-readable copy.
class ActivityEventType {
  ActivityEventType._();

  // --- Contract events (PublicOSActivity — contact/profile scoped) ---
  static const vouched = 'vouched';
  static const citizenized = 'citizenized';
  static const bonusNameChangeGranted = 'bonusNameChangeGranted';
  static const domainPaid = 'domainPaid';
  static const evicted = 'evicted';
  static const nameChanged = 'nameChanged';
  static const recordSet = 'recordSet';
  static const displayNameSet = 'displayNameSet';

  // --- Token transfers (PublicOSWalletActivity — own-wallet scoped) ---
  //
  // `actor` is ALWAYS the `from` address and `target` ALWAYS the `to` address;
  // the direction lives in the slug, not in which field holds whose address.
  // A move between two of the user's own wallets is ONE event (transferSelf),
  // not a send + a receive — see PublicOSWalletActivity's decode note.

  /// Money arrived: `to` is one of the user's wallets, `from` is not.
  static const transferIn = 'transferIn';

  /// Money left: `from` is one of the user's wallets, `to` is not.
  static const transferOut = 'transferOut';

  /// Both parties are the user's own wallets (Safe → keychain EOA, etc.).
  static const transferSelf = 'transferSelf';

  // --- Social events (the home SSP's inbox) ---
  //
  // Stored in the same table as the chain feed, slug `social_<kind>` with the
  // six wire kinds (comment · reply · mention · reaction · follow_request ·
  // follow_approved). `actor` is the acting account; `data` carries
  // {id, from, post_url, item_url, seq?}. The dedup key is the notification id
  // (`txHash` = id, `logIndex` = 0), so a push and the 15-min pull never show
  // one event twice.
  static const socialPrefix = 'social_';
  static bool isSocial(String eventType) => eventType.startsWith(socialPrefix);
  static String socialKind(String eventType) =>
      isSocial(eventType) ? eventType.substring(socialPrefix.length) : '';
}

/// A single on-chain activity item — source-agnostic.
///
/// Produced today by `PublicOSActivity.fetchActivity` (client-side `getLogs`
/// poll), but the same shape a Phase-B BSP indexer would serve. Pure data:
/// the view layer renders the sentence (display-name resolution + "you"
/// framing), so no UI copy lives here. Drift row <-> model mapping lives in
/// the `publicos_activity` extension, keeping this model free of Drift.
class ActivityEvent {
  /// One of [ActivityEventType].
  final String eventType;

  /// Primary subject, eip55 hex — voucher / account / payer-target / evictee.
  final String actor;

  /// Secondary subject, eip55 hex — the vouch target. Null for single-party
  /// events.
  final String? target;

  final int blockNumber;

  /// Log index within the block. Together with [txHash] this is the dedupe
  /// key: one transaction can emit several same-type events (e.g. a
  /// multi-record update fires several `RecordSet`), so [eventType] alone
  /// would collapse them.
  final int logIndex;

  final String txHash;

  /// Block timestamp, milliseconds since epoch.
  final int timestamp;

  /// Event-specific non-address fields (months, cost, names, ...).
  final Map<String, dynamic> data;

  final bool isRead;

  const ActivityEvent({
    required this.eventType,
    required this.actor,
    this.target,
    required this.blockNumber,
    required this.logIndex,
    required this.txHash,
    required this.timestamp,
    this.data = const {},
    this.isRead = false,
  });

  /// The [data] map serialized for the Drift `data` text column.
  String get dataJson => data.isEmpty ? '{}' : jsonEncode(data);

  Map<String, dynamic> toJson() => {
        'eventType': eventType,
        'actor': actor,
        'target': target,
        'blockNumber': blockNumber,
        'logIndex': logIndex,
        'txHash': txHash,
        'timestamp': timestamp,
        'data': data,
        'isRead': isRead,
      };

  /// A social item (a decrypted push blob, or an inbox row's `toPushData()`)
  /// as a row of the shared activity table. `occurred_at` is RFC3339.
  factory ActivityEvent.social(Map<String, dynamic> d) {
    final occurred = DateTime.tryParse(d['occurred_at'] as String? ?? '') ??
        DateTime.now().toUtc();
    final data = <String, dynamic>{
      'id': d['id'],
      'from': d['from'] ?? '',
      'post_url': d['post_url'] ?? '',
      'item_url': d['item_url'] ?? '',
    };
    if (d['seq'] != null) data['seq'] = (d['seq'] as num).toInt();
    return ActivityEvent(
      eventType: ActivityEventType.socialPrefix + (d['kind'] as String),
      actor: d['actor'] as String,
      blockNumber: 0,
      logIndex: 0,
      txHash: d['id'] as String,
      timestamp: occurred.millisecondsSinceEpoch,
      data: data,
    );
  }

  factory ActivityEvent.fromJson(Map<String, dynamic> json) => ActivityEvent(
        eventType: json['eventType'] as String,
        actor: json['actor'] as String,
        target: json['target'] as String?,
        blockNumber: (json['blockNumber'] as num).toInt(),
        logIndex: (json['logIndex'] as num).toInt(),
        txHash: json['txHash'] as String,
        timestamp: (json['timestamp'] as num).toInt(),
        data: (json['data'] as Map?)?.cast<String, dynamic>() ?? const {},
        isRead: json['isRead'] as bool? ?? false,
      );
}
