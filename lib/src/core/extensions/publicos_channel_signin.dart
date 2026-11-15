import 'package:publicos_core/src/core/core.dart';
import 'package:publicos_core/src/core/extensions/publicos_settings.dart';
import 'package:publicos_core/src/database/database.dart' as db;
import 'package:publicos_core/src/utils/channel_url.dart';
import 'package:publicos_core/src/utils/log.dart';

/// The per-channel "Sign in" mechanic.
///
/// ONE rule decides whether a read carries the user's identity, and the key
/// icon shows that rule's answer and nothing else:
///
/// ```
/// send_signature(channel) = decision == accepted
///                        OR (global auto-sign-in ON AND decision != denied)
/// ```
/// …and only when a signing key is loaded. Writes (a comment, a reaction, a
/// follow request) are not reads — an interaction IS an identity and always
/// signs; nothing here is consulted for them.
///
/// State: a [db.ChannelSigninPrefs] row exists ⇔ the channel accepts
/// sign-in. It is seeded by ANY server signal — the `PublicOS-Envelope`
/// header on a served 200/304, or the 401 challenge — with `mode` refreshed
/// on every fetch, and deleted when a served 200 carries no signal. Its
/// existence is what the client's key icon renders. The user's answer is the
/// nullable `decision` column (null / accepted / denied), written ONLY by the
/// user's three actions (Allow / Deny / Forget) — a fetch never touches it.
///
/// Keyed on the CHANNEL BASE URL: every method accepts any URL under the
/// channel (feed, post, comments, replies, reactions, the object route) and
/// normalises with [channelBaseOf], so the feed GET and every per-post read
/// consult one row. Rows are per signed-in session
/// ([PublicOS.sessionBlockchainAddress]).
extension PublicOSChannelSignin on PublicOS {
  static const _tag = 'ChannelSignin';

  static const accepted = 'accepted';
  static const denied = 'denied';

  static String _key(String url) => channelBaseOf(url) ?? url;
  static String? get _session => PublicOS.sessionBlockchainAddress;
  static bool get hasKey =>
      PublicOS.myPublicosAddress != null &&
      PublicOS.currentBlockchainPrivateKey != null;

  /// THE RULE, as a pure function so the truth table is a unit test.
  static bool decideSign({
    required bool hasKey,
    required bool global,
    required String? decision,
  }) {
    if (!hasKey) return false;
    if (decision == accepted) return true;
    if (decision == denied) return false;
    return global;
  }

  /// Should THIS read carry the user's identity? False with no key, false
  /// when nobody is signed in, false for a non-channel URL (no row can exist).
  static Future<bool> shouldSign(String url) async {
    final session = _session;
    if (!hasKey || session == null) return false;
    final pref = await PublicOS.database.getChannelSigninPref(_key(url), session);
    final global = await PublicOSSettings.getFeedsAutoSignin();
    return decideSign(hasKey: true, global: global, decision: pref?.decision);
  }

  /// The row for the channel under [url], or null when its server has never
  /// signalled sign-in (UI contract: null = no key icon).
  static Future<db.ChannelSigninPref?> getPref(String url) async {
    final session = _session;
    if (session == null) return null;
    return PublicOS.database.getChannelSigninPref(_key(url), session);
  }

  /// Allow ([accepted]) / Deny ([denied]) / Forget (null). Logs, rather than
  /// throws, when the row is missing — a menu should only exist over a row.
  static Future<void> setDecision(String url, String? decision) async {
    assert(decision == null || decision == accepted || decision == denied,
        'decision must be accepted, denied or null');
    final session = _session;
    if (session == null) return;
    final touched = await PublicOS.database
        .setChannelSigninDecision(_key(url), session, decision);
    if (touched == 0) {
      Log.e(_tag, 'setDecision($decision) on an unsignalled channel: $url');
    }
  }

  /// A server signal for the channel under [url]: the raw
  /// `PublicOS-Envelope` header value (`optional; action="read_feed"`) or
  /// the literal `required` for a 401 challenge. Only the leading mode token
  /// is kept. Best-effort: never lets a served feed become an error. No-op
  /// for an anonymous session (nothing to consent with) and for a non-channel
  /// URL (never a row).
  static Future<void> recordSignal(String url, String headerValue) async {
    final session = _session;
    if (session == null) return;
    final base = channelBaseOf(url);
    if (base == null) return;
    final mode = headerValue.split(';').first.trim().toLowerCase();
    if (mode != 'optional' && mode != 'required') return;
    try {
      await PublicOS.database.recordChannelSigninSignal(
        channelUrl: base,
        sessionAddress: session,
        mode: mode,
      );
    } catch (e) {
      Log.e(_tag, 'recordSignal failed for $url: $e');
    }
  }

  /// A served 200 with NO signal: the channel stopped accepting sign-in (or
  /// moved to a non-conforming server). The row — and the answer with it —
  /// goes; it is re-asked if the channel signals again.
  static Future<void> clearSignal(String url) async {
    final session = _session;
    if (session == null) return;
    final base = channelBaseOf(url);
    if (base == null) return;
    try {
      await PublicOS.database.deleteChannelSigninPref(base, session);
    } catch (e) {
      Log.e(_tag, 'clearSignal failed for $url: $e');
    }
  }
}
