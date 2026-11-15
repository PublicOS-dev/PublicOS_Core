/// The per-channel sign-in rule.
///
/// One rule decides whether a read carries the user's identity:
///   send = decision == accepted OR (global ON AND decision != denied)
/// …and only with a key loaded. The row is the "accepts sign-in" flag; the
/// decision is a nullable column on it. Keyed on the channel BASE url.
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_core/src/core/extensions/publicos_channel_signin.dart';
import 'package:web3dart/web3dart.dart';

const _session = '0xEA6ac90E1010FEfB9EDb11E60B750D4A9350d95a';
const _base = 'https://feeds.test/api/0xAbC/channels/nuevas';

void main() {
  group('decideSign — the rule as a truth table', () {
    test('no key → never, whatever the row or the global says', () {
      for (final global in [false, true]) {
        for (final decision in [null, 'accepted', 'denied']) {
          expect(
            PublicOSChannelSignin.decideSign(
                hasKey: false, global: global, decision: decision),
            isFalse,
            reason: 'global=$global decision=$decision',
          );
        }
      }
    });

    test('accepted → sign, global OFF or ON', () {
      expect(PublicOSChannelSignin.decideSign(hasKey: true, global: false, decision: 'accepted'), isTrue);
      expect(PublicOSChannelSignin.decideSign(hasKey: true, global: true, decision: 'accepted'), isTrue);
    });

    test('denied → never, and a deny beats the global', () {
      expect(PublicOSChannelSignin.decideSign(hasKey: true, global: false, decision: 'denied'), isFalse);
      expect(PublicOSChannelSignin.decideSign(hasKey: true, global: true, decision: 'denied'), isFalse);
    });

    test('not answered → the global decides', () {
      expect(PublicOSChannelSignin.decideSign(hasKey: true, global: false, decision: null), isFalse);
      expect(PublicOSChannelSignin.decideSign(hasKey: true, global: true, decision: null), isTrue);
    });
  });

  group('channelBaseOf — every URL under a channel lands on one key', () {
    const cases = <String>[
      '$_base/json',
      '$_base/rss',
      '$_base/atom',
      '$_base/json?sort=top&limit=20&offset=0',
      '$_base/posts/abc123',
      '$_base/posts/abc123/comments',
      '$_base/posts/abc123/comments?sort=new',
      '$_base/posts/abc123/comments/42/replies',
      '$_base/posts/abc123/reactions',
      _base, // the object route itself
    ];
    for (final url in cases) {
      test(url, () => expect(channelBaseOf(url), _base));
    }

    test('a non-channel URL is null (external RSS, a profile, media)', () {
      expect(channelBaseOf('https://example.com/feed.xml'), isNull);
      expect(channelBaseOf('https://feeds.test/api/0xAbC'), isNull);
      expect(channelBaseOf('https://feeds.test/media/x.png'), isNull);
      expect(channelBaseOf('not a url'), isNull);
      expect(channelBaseOf(''), isNull);
    });

    test('the owner segment is kept as-is — casing is the server\'s concern', () {
      expect(channelBaseOf('https://feeds.test/api/0xabc/channels/x/json'),
          'https://feeds.test/api/0xabc/channels/x');
    });

    test('serverOf', () {
      expect(serverOf('$_base/json'), 'https://feeds.test');
      expect(serverOf('http://localhost:5665/api/0xA/channels/s/json'),
          'http://localhost:5665');
      expect(serverOf('nope'), isNull);
    });
  });

  group('isFeedRefusal — a refusal is never a transient failure', () {
    test('typed refusals', () {
      expect(PublicOSFeedLists.isFeedRefusal(const FeedSigninRequired(channelUrl: _base)), isTrue);
      expect(PublicOSFeedLists.isFeedRefusal(const FeedGateException(code: 'PRIVATE_FEED_NOT_APPROVED', message: '', statusCode: 403)), isTrue);
      expect(PublicOSFeedLists.isFeedRefusal(const PaywallException(code: 'PAYWALL_DENIED', message: '', statusCode: 403)), isTrue);
    });
    test('every string-protocol code, incl. the two client-side ones', () {
      for (final code in kFeedRefusalCodes) {
        expect(PublicOSFeedLists.isFeedRefusal(Exception('FEED_ERROR:$code')), isTrue, reason: code);
      }
      expect(PublicOSFeedLists.isFeedRefusal(Exception('FEED_ERROR:HTTP_403')), isTrue);
    });
    test('transient failures are not refusals — the cached copy may stay', () {
      expect(PublicOSFeedLists.isFeedRefusal(Exception('Feed timeout: x')), isFalse);
      expect(PublicOSFeedLists.isFeedRefusal(Exception('Error fetching feed: SocketException')), isFalse);
      expect(PublicOSFeedLists.isFeedRefusal(Exception('FEED_ERROR:HTTP_500')), isFalse);
      expect(PublicOSFeedLists.isFeedRefusal(Exception('FEED_ERROR:FEED_ERROR')), isFalse);
    });
  });

  group('the row — drift round trip', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() async => db.close());

    test('a signal seeds the row with decision null; a second signal refreshes mode only', () async {
      await db.recordChannelSigninSignal(channelUrl: _base, sessionAddress: _session, mode: 'optional');
      var row = await db.getChannelSigninPref(_base, _session);
      expect(row, isNotNull);
      expect(row!.decision, isNull);
      expect(row.mode, 'optional');

      await db.setChannelSigninDecision(_base, _session, 'accepted');
      await db.recordChannelSigninSignal(channelUrl: _base, sessionAddress: _session, mode: 'required');
      row = await db.getChannelSigninPref(_base, _session);
      expect(row!.decision, 'accepted', reason: 'a fetch never touches the answer');
      expect(row.mode, 'required');
    });

    test('accepted / denied / Forget (null) round-trip; touching a missing row returns 0', () async {
      expect(await db.setChannelSigninDecision(_base, _session, 'accepted'), 0);
      await db.recordChannelSigninSignal(channelUrl: _base, sessionAddress: _session, mode: 'optional');
      expect(await db.setChannelSigninDecision(_base, _session, 'denied'), 1);
      expect((await db.getChannelSigninPref(_base, _session))!.decision, 'denied');
      expect(await db.setChannelSigninDecision(_base, _session, null), 1);
      expect((await db.getChannelSigninPref(_base, _session))!.decision, isNull);
    });

    test('a served 200 with no signal deletes the row', () async {
      await db.recordChannelSigninSignal(channelUrl: _base, sessionAddress: _session, mode: 'optional');
      expect(await db.deleteChannelSigninPref(_base, _session), 1);
      expect(await db.getChannelSigninPref(_base, _session), isNull);
      expect(await db.deleteChannelSigninPref(_base, _session), 0);
    });

    test('rows are per session', () async {
      await db.recordChannelSigninSignal(channelUrl: _base, sessionAddress: _session, mode: 'optional');
      expect(await db.getChannelSigninPref(_base, '0x0000000000000000000000000000000000000001'), isNull);
    });
  });

  group('shouldSign — through the PublicOS statics', () {
    late AppDatabase db;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      PublicOS.database = db;
      PublicOS.isAuthenticated = true;
      PublicOS.sessionBlockchainAddress = _session;
      PublicOS.myPublicosAddress = _session;
      PublicOS.currentBlockchainPrivateKey =
          EthPrivateKey.fromHex('0x${'11' * 32}');
    });
    tearDown(() async {
      PublicOS.isAuthenticated = false;
      PublicOS.sessionBlockchainAddress = null;
      PublicOS.myPublicosAddress = null;
      PublicOS.currentBlockchainPrivateKey = null;
      await db.close();
    });

    test('no row + global OFF → plain', () async {
      expect(await PublicOSChannelSignin.shouldSign('$_base/json'), isFalse);
    });

    test('global ON → signed, and writes NO decision', () async {
      expect(await PublicOSSettings.setFeedsAutoSignin(true), isTrue);
      expect(await PublicOSChannelSignin.shouldSign('$_base/json'), isTrue);
      expect(await PublicOSChannelSignin.getPref('$_base/json'), isNull,
          reason: 'the global is a default, never a stored answer');
    });

    test('denied beats global ON', () async {
      await PublicOSSettings.setFeedsAutoSignin(true);
      await PublicOSChannelSignin.recordSignal('$_base/json', 'optional; action="read_feed"');
      await PublicOSChannelSignin.setDecision('$_base/posts/x/comments', 'denied'); // any URL under the channel
      expect(await PublicOSChannelSignin.shouldSign('$_base/json'), isFalse);
      expect(await PublicOSChannelSignin.shouldSign('$_base/posts/x/reactions'), isFalse);
    });

    test('accepted signs every URL under the channel, global OFF', () async {
      await PublicOSChannelSignin.recordSignal('$_base/json', 'required');
      await PublicOSChannelSignin.setDecision('$_base/json', 'accepted');
      expect(await PublicOSChannelSignin.shouldSign('$_base/posts/x/comments/1/replies'), isTrue);
      expect(await PublicOSChannelSignin.shouldSign(_base), isTrue, reason: 'the object route too');
    });

    test('no key → plain even when accepted', () async {
      await PublicOSChannelSignin.recordSignal('$_base/json', 'required');
      await PublicOSChannelSignin.setDecision('$_base/json', 'accepted');
      PublicOS.currentBlockchainPrivateKey = null;
      expect(await PublicOSChannelSignin.shouldSign('$_base/json'), isFalse);
    });

    test('a non-channel URL never signs and never gets a row', () async {
      await PublicOSSettings.setFeedsAutoSignin(true);
      await PublicOSChannelSignin.recordSignal('https://example.com/feed.xml', 'optional');
      expect(await PublicOSChannelSignin.getPref('https://example.com/feed.xml'), isNull);
      // global ON still says "sign" for an unknown URL — the row model cannot
      // refuse what it has never seen; the WIRE decides (an external host
      // ignores the envelope). Pinned so a change here is deliberate.
      expect(await PublicOSChannelSignin.shouldSign('https://example.com/feed.xml'), isTrue);
    });

    test('recordSignal keeps only the mode token; junk is ignored', () async {
      await PublicOSChannelSignin.recordSignal('$_base/json', 'Optional; action="read_feed"');
      expect((await PublicOSChannelSignin.getPref(_base))!.mode, 'optional');
      await PublicOSChannelSignin.recordSignal('$_base/json', 'banana');
      expect((await PublicOSChannelSignin.getPref(_base))!.mode, 'optional');
    });

    test('clearSignal deletes the row and the answer with it', () async {
      await PublicOSChannelSignin.recordSignal('$_base/json', 'optional');
      await PublicOSChannelSignin.setDecision('$_base/json', 'accepted');
      await PublicOSChannelSignin.clearSignal('$_base/rss');
      expect(await PublicOSChannelSignin.getPref('$_base/json'), isNull);
    });

    test('the global is OFF for an unauthenticated session and never throws', () async {
      PublicOS.isAuthenticated = false;
      expect(await PublicOSSettings.getFeedsAutoSignin(), isFalse);
    });
  });
}
