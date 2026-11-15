import 'package:publicos_core/src/models/feed_server/feed_server_models.dart';

/// A my_rss_server read refused by the ladder (403), typed, carrying the
/// channel object the server attached (`error.channel`). The private lock reads
/// `channel.followStatus` from here — no second signed call to the owner
/// listing; the tier and paywall bodies read `isPrivate` / `readIdentity` /
/// `accessEntries`.
///
/// Codes: `PRIVATE_FEED` (masked ban — the object arrives WITHOUT
/// `followStatus`, by design) · `PRIVATE_FEED_NOT_APPROVED` · `VERIFIED_ONLY`
/// · `ACCOUNT_ONLY` · `STANDING_REQUIRED` · `PAYWALL_DENIED` (the
/// [PaywallException] subclass, which adds the payable entries).
///
/// `channel` is null on a server that predates the object (or a 403 with no
/// body) — callers treat null as UNKNOWN and fall back to resolving.
class FeedGateException implements Exception {
  final String code;
  final String message;
  final int statusCode;
  final Channel? channel;

  const FeedGateException({
    required this.code,
    required this.message,
    required this.statusCode,
    this.channel,
  });

  /// Kept compatible with the `FEED_ERROR:<code>` string protocol that
  /// `RssParser.fetchFeed` has always thrown, so callers that still match on
  /// the message keep working while new ones catch the type.
  @override
  String toString() => 'FEED_ERROR:$code';

  /// Parse a 403 error body into a typed refusal, or null when [status] is
  /// not 403 or the body carries no code. [serverAddress] is stamped on the
  /// parsed channel so its object round-trips like a listing row.
  static FeedGateException? tryFromErrorMap(
    int status,
    Map<String, dynamic>? error, {
    String? serverAddress,
  }) {
    if (status != 403 || error == null) return null;
    final code = error['code'];
    if (code is! String) return null;
    return FeedGateException(
      code: code,
      message: (error['message'] as String?) ?? '',
      statusCode: status,
      channel: channelFromErrorMap(error, serverAddress: serverAddress),
    );
  }

  /// The `error.channel` object, when present.
  static Channel? channelFromErrorMap(
    Map<String, dynamic> error, {
    String? serverAddress,
  }) {
    final raw = error['channel'];
    if (raw is! Map) return null;
    try {
      return Channel.fromJson(raw.cast<String, dynamic>(),
          serverAddress: serverAddress);
    } catch (_) {
      return null;
    }
  }
}

/// The 401 envelope challenge on a channel, seen with a signing key loaded:
/// the channel requires sign-in and the user has either not answered
/// (`decision == null` → the client ASKS) or said no (`denied` → the client
/// LOCKS). Core records the row (`mode: required`) before throwing and never
/// opens a dialog. Never thrown without a key — a keyless reader keeps
/// the plain `FEED_ERROR:ENVELOPE_MISSING` gate.
class FeedSigninRequired implements Exception {
  static const code = 'SIGNIN_REQUIRED';

  /// The URL that was fetched; the row is keyed on its channel base.
  final String channelUrl;

  const FeedSigninRequired({required this.channelUrl});

  @override
  String toString() => 'FEED_ERROR:$code';
}

/// The feed is GONE: a 404 on the feed URL. Not a
/// refusal and not a blip — the channel (or its account) no longer exists on
/// that server, so no retry will bring it back and a cached copy must not
/// pose as the feed.
///
/// [code] is the server's `error.code` when it sent one (`CHANNEL_NOT_FOUND` /
/// `ACCOUNT_NOT_FOUND`), the matching code for an older server's bare-string
/// body (`{"error":"channel not found"}`), and `HTTP_404` for anything else
/// (an external RSS URL that disappeared).
class FeedGoneException implements Exception {
  final String code;

  const FeedGoneException(this.code);

  @override
  String toString() => 'FEED_ERROR:$code';
}
