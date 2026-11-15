import 'dart:convert';

/// Social notifications: the home SSP's inbox item,
/// the "deliver me here" target and the device ticket, as the server emits
/// them (my_rss_server internal/handlers/notif_inbox.go). Pure data: the app
/// writes the sentence from [SocialNotification.kind] + the actor's name.

/// The six kinds, as the wire spells them.
class SocialNotificationKind {
  SocialNotificationKind._();
  static const comment = 'comment';
  static const reply = 'reply';
  static const mention = 'mention';
  static const reaction = 'reaction';
  static const followRequest = 'follow_request';
  static const followApproved = 'follow_approved';
  static const all = [
    comment,
    reply,
    mention,
    reaction,
    followRequest,
    followApproved
  ];
  static bool isKind(String k) => all.contains(k);
}

/// One item of the home inbox (`GET /api/{A}/notifications`).
class SocialNotification {
  final int seq;
  final String id; // "<hosting slug>:<uuid>", the dedup key everywhere
  final String from; // the hosting server's slug
  final String kind;
  final String actor; // EIP-55 account
  final String postUrl;
  final String itemUrl;
  final DateTime occurredAt;
  final DateTime receivedAt;
  final bool read;

  const SocialNotification({
    required this.seq,
    required this.id,
    required this.from,
    required this.kind,
    required this.actor,
    required this.postUrl,
    required this.itemUrl,
    required this.occurredAt,
    required this.receivedAt,
    required this.read,
  });

  factory SocialNotification.fromJson(Map<String, dynamic> j) =>
      SocialNotification(
        seq: (j['seq'] as num).toInt(),
        id: j['id'] as String,
        from: j['from'] as String? ?? '',
        kind: j['kind'] as String,
        actor: j['actor'] as String,
        postUrl: j['post_url'] as String? ?? '',
        itemUrl: j['item_url'] as String? ?? '',
        occurredAt: DateTime.tryParse(j['occurred_at'] as String? ?? '') ??
            DateTime.now().toUtc(),
        receivedAt: DateTime.tryParse(j['received_at'] as String? ?? '') ??
            DateTime.now().toUtc(),
        read: j['read'] as bool? ?? false,
      );

  static List<SocialNotification> listFromJson(dynamic items) =>
      (items as List? ?? const [])
          .map((e) =>
              SocialNotification.fromJson((e as Map).cast<String, dynamic>()))
          .toList();

  /// The same field set a decrypted push blob carries, so one mapping
  /// (`ActivityEvent.social`) serves both the push and the pull.
  Map<String, dynamic> toPushData() => {
        'id': id,
        'from': from,
        'kind': kind,
        'actor': actor,
        'post_url': postUrl,
        'item_url': itemUrl,
        'occurred_at': occurredAt.toUtc().toIso8601String(),
        'seq': seq,
      };
}

/// The home's ticket for this device: its word to a gateway that the device
/// holding key R belongs to a paid subscriber, until [exp]. Names no account.
/// Signed bytes (the home's notif key, EIP-191):
/// `{"exp":…,"handle":"…","r_pub":"0x…","slug":"…"}`.
class NotifTicket {
  final String handle;
  final String rPub; // EIP-55 address of the device's throwaway key R
  final String slug; // the home's registry slug
  final int exp; // unix seconds
  final String sig;

  const NotifTicket({
    required this.handle,
    required this.rPub,
    required this.slug,
    required this.exp,
    required this.sig,
  });

  factory NotifTicket.fromJson(Map<String, dynamic> j) => NotifTicket(
        handle: j['handle'] as String,
        rPub: j['r_pub'] as String,
        slug: j['slug'] as String,
        exp: (j['exp'] as num).toInt(),
        sig: j['sig'] as String,
      );

  /// Keys sorted: the gateway's envelope canonicalisation sorts nested maps,
  /// and so must the bytes we sign over.
  Map<String, dynamic> toJson() => {
        'exp': exp,
        'handle': handle,
        'r_pub': rPub,
        'sig': sig,
        'slug': slug,
      };

  bool get isExpired =>
      DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 >= exp;

  DateTime get expiresAt =>
      DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);

  @override
  String toString() => jsonEncode(toJson());
}

/// One "deliver me here" entry on the home SSP: one per (account, gateway).
/// The handle is minted by the home, once, and shared by every device of the
/// account on that app. [ticket] is present when the calling device is
/// registered on it (PUT with keys, or the boot-refresh GET).
class NotifTarget {
  final String id;
  final String label;
  final String gateway; // base URL, no trailing slash
  final String handle;
  final bool enabled;
  final Map<String, bool> kinds;
  final bool removable; // false for the official gateway
  final NotifTicket? ticket;

  const NotifTarget({
    required this.id,
    required this.label,
    required this.gateway,
    required this.handle,
    required this.enabled,
    required this.kinds,
    required this.removable,
    this.ticket,
  });

  factory NotifTarget.fromJson(Map<String, dynamic> j) => NotifTarget(
        id: j['id'] as String,
        label: j['label'] as String? ?? '',
        gateway: j['gateway'] as String,
        handle: j['handle'] as String,
        enabled: j['enabled'] as bool? ?? true,
        kinds: ((j['kinds'] as Map?) ?? const {})
            .map((k, v) => MapEntry(k as String, v == true)),
        removable: j['removable'] as bool? ?? true,
        ticket: j['ticket'] is Map
            ? NotifTicket.fromJson((j['ticket'] as Map).cast<String, dynamic>())
            : null,
      );

  static List<NotifTarget> listFromJson(dynamic items) =>
      (items as List? ?? const [])
          .map((e) => NotifTarget.fromJson((e as Map).cast<String, dynamic>()))
          .toList();

  bool wants(String kind) =>
      kinds[kind] ?? (kind != SocialNotificationKind.reaction);
}
