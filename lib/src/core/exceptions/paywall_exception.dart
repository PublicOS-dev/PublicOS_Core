import 'package:publicos_core/src/core/exceptions/feed_gate_exception.dart';
import 'package:publicos_core/src/models/feed_server/feed_server_models.dart';

/// Thrown when a my_rss_server read is refused by the paid-feed rung.
///
/// **There is exactly one refusal code: `PAYWALL_DENIED`.** That is a design
/// decision, not an omission. An entry whose chain cannot answer is simply the
/// next entry's turn, and the walk ending with nothing means "not subscribed" —
/// there is deliberately no "the chain was down" verdict, because the pay sheet
/// reads price and expiry from that same chain before Confirm, so a chain too
/// sick to answer the gate is equally unable to sell anything. Do not add a
/// second code here to be helpful; there is no second screen to render for it.
///
/// `PAYWALL_CHECK_FAILED` (500) is a different animal and is NOT a paywall
/// condition: it means the server could not read its OWN database. It parses
/// into this type only so a caller can route it with [isServerFault] instead of
/// string-matching, and it never carries [entries].
class PaywallException extends FeedGateException {
  // `code` (`PAYWALL_DENIED` 403 / `PAYWALL_CHECK_FAILED` 500), `message`,
  // `statusCode` and the server-attached `channel` object come from
  // [FeedGateException] — a paywall refusal is one read-gate refusal among
  // six, and the locks read the object the same way for all of them.

  /// Where this feed can be paid for — the newest feed id per chain, each with
  /// the master address to send `subscribe()` to.
  ///
  /// **Empty is meaningful and must be handled**: a channel whose only entries
  /// sit on chains this SSP no longer serves is locked with nowhere to pay. The
  /// screen for that is "this feed is not currently for sale", not a Confirm
  /// button.
  final List<ChannelAccessEntry> entries;

  /// The highest EXPIRED `paidUntil` found while the server walked the entries,
  /// or null when none was. Non-null means the reader HAD a subscription and it
  /// ran out — a *renew* screen rather than a *subscribe* screen, and it costs
  /// nothing extra because the walk had already read the value.
  final DateTime? lapsedAt;

  const PaywallException({
    required super.code,
    required super.message,
    required super.statusCode,
    super.channel,
    this.entries = const [],
    this.lapsedAt,
  });

  /// True for a real paywall denial the reader can fix by paying.
  bool get isDenied => statusCode == 403;

  /// True when the server failed rather than refused. Show a retry, not a
  /// price.
  bool get isServerFault => statusCode == 500;

  /// True when the reader previously subscribed and lapsed — the copy should
  /// say "renew", not "subscribe".
  bool get hasLapsed => lapsedAt != null;

  /// Somewhere to pay exists.
  bool get isPayable => entries.isNotEmpty;

  /// Kept compatible with the `FEED_ERROR:<code>` string protocol that
  /// `RssParser.fetchFeed` has always thrown, so callers that still match on
  /// the message keep working while new ones catch the type.
  @override
  String toString() => 'FEED_ERROR:$code';

  /// Parse a my_rss_server error body into a [PaywallException], or null when
  /// the response is not a paywall refusal — in which case the caller's
  /// existing error handling should continue untouched.
  ///
  /// [error] is the `error` object of the response body, i.e.
  /// `{"code": ..., "message": ..., "entries": [...], "lapsed_at": ...}`.
  static PaywallException? tryFromErrorMap(
      int statusCode, Map<String, dynamic>? error,
      {String? serverAddress}) {
    if (error == null) return null;
    final code = error['code'];
    if (code is! String) return null;
    if (code != 'PAYWALL_DENIED' && code != 'PAYWALL_CHECK_FAILED') return null;

    final rawEntries = error['entries'];
    final entries = <ChannelAccessEntry>[];
    if (rawEntries is List) {
      for (final item in rawEntries) {
        if (item is Map<String, dynamic>) {
          // The server only ever puts PAYABLE entries in a 403 body, so
          // anything that arrives here can be sold into.
          entries.add(ChannelAccessEntry.fromJson(item, defaultPayable: true));
        }
      }
    }

    final lapsed = error['lapsed_at'];
    return PaywallException(
      code: code,
      message: (error['message'] as String?) ?? '',
      statusCode: statusCode,
      channel: FeedGateException.channelFromErrorMap(error,
          serverAddress: serverAddress),
      entries: entries,
      lapsedAt: lapsed is num && lapsed > 0
          ? DateTime.fromMillisecondsSinceEpoch(lapsed.toInt() * 1000,
              isUtc: true)
          : null,
    );
  }
}
