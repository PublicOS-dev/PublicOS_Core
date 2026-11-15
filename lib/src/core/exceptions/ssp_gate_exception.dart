/// Thrown when the SSP-pairing gate on a my_rss_server denies a signed write.
///
/// The server gates every signed mutating request on (1) the account being
/// subscribed to *this* SSP, and (2) the subscription being paid through.
/// Failures land here with a stable [code] so the client can route the user
/// to the right Treasury action without string-matching the message.
class SSPGateException implements Exception {
  /// One of: `SSP_NOT_SUBSCRIBED`, `SSP_WRONG`, `SSP_EXPIRED`,
  /// `SSP_GATE_FAILED`. Stable across server versions; route the UI on
  /// this, not on [message].
  final String code;

  /// Human-readable message from the server.
  final String message;

  /// The slug of the SSP this server identifies as. Useful for the
  /// "Subscribe to <slug>" affordance on `SSP_NOT_SUBSCRIBED`.
  final String? sspSlug;

  /// `SSP_WRONG` only — the slug the user IS currently subscribed to,
  /// so the client can offer "switch to <us>" or "write at <other>".
  /// Server returns this in `error.details`.
  final String? otherSlug;

  /// 403 for the three user-fixable codes
  /// (`SSP_NOT_SUBSCRIBED` / `SSP_WRONG` / `SSP_EXPIRED`); 500 for
  /// `SSP_GATE_FAILED` (transient — contract RPC failed on the server
  /// side). Use [isClientFault] / [isServerFault] for routing.
  final int statusCode;

  SSPGateException({
    required this.code,
    required this.message,
    required this.statusCode,
    this.sspSlug,
    this.otherSlug,
  });

  /// True when the user can fix the underlying state (subscribe / switch /
  /// renew). Show a Treasury affordance in the snackbar.
  bool get isClientFault => statusCode == 403;

  /// True when the failure is transient (server couldn't reach the chain).
  /// Show a retry affordance.
  bool get isServerFault => statusCode == 500;

  @override
  String toString() => 'SSPGateException($code @ ${sspSlug ?? "?"}): $message';

  /// Try to parse a server response into an [SSPGateException]. Returns
  /// null when the response shape doesn't match the gate's contract — let
  /// existing error handling continue. Public so the multipart upload path
  /// (which doesn't go through `signedRequest`) can reuse the same parse.
  static SSPGateException? tryFromErrorMap(
      int statusCode, Map<String, dynamic>? error) {
    if (statusCode != 403 && statusCode != 500) return null;
    if (error == null) return null;
    final code = error['code'];
    if (code is! String) return null;
    if (code != 'SSP_NOT_SUBSCRIBED' &&
        code != 'SSP_WRONG' &&
        code != 'SSP_EXPIRED' &&
        code != 'SSP_GATE_FAILED') {
      return null;
    }
    return SSPGateException(
      code: code,
      message: (error['message'] as String?) ?? '',
      sspSlug: error['ssp_slug'] as String?,
      otherSlug:
          code == 'SSP_WRONG' ? error['details'] as String? : null,
      statusCode: statusCode,
    );
  }
}
