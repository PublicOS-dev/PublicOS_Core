// Record expiration on chain: Unix SECONDS, 0 = never.
//
// The contract argument is the single source of truth for a record's
// expiration; the value blob carries none. The contract compares it with
// block.timestamp, so the unit is seconds. Records don't expire: the apps write
// 0. Earlier app builds sent MILLISECONDS, which the chain reads as tens of
// thousands of years away; those are read as never, so the next save writes 0
// and they heal.
import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/src/models/record_model.dart';

void main() {
  // The contract gate: require(expiration == 0 || expiration > block.timestamp), seconds.
  bool contractAccepts(BigInt arg, int blockTimestampSec) =>
      arg == BigInt.zero || arg > BigInt.from(blockTimestampSec);
  const blockTsSec = 1794873600; // 2026-11-16

  Record readFromChain(Map<String, dynamic> blob, BigInt arg, bool expired) =>
      Record.fromJson(blob).copyWith(
        expiration: Record.expirationFromChain(arg),
        isExpired: expired,
      );

  group('toChainValue', () {
    test('omits expiration and isExpired (the contract owns them)', () {
      final r = Record.fromJson({
        'key': 'card.abc',
        'value': 'https://feeds.publicos.dev/media/x.png',
        'type': 0,
        'metadata': {'rank': 'a'},
        'subtype': 'card',
      });
      final blob = r.toChainValue();
      expect(blob.containsKey('expiration'), isFalse);
      expect(blob.containsKey('isExpired'), isFalse);
      expect(blob['subtype'], 'card');
    });
  });

  group('factories default to never', () {
    test('a record built without an expiration goes to the chain as 0', () {
      final r = Record.asProfile(key: 'automated_account', value: 'true');
      expect(r.expiration, Record.never);
      expect(r.chainExpiration, BigInt.zero);
      expect(Record.asSettings(key: 'color', value: '1', isSystem: true).chainExpiration, BigInt.zero);
      expect(Record.asRouter(key: 'channel.x', value: 'u', routerSubtype: RouterSubtype.channel).chainExpiration, BigInt.zero);
    });

    test('fromJson ignores any expiration in a legacy blob', () {
      final r = Record.fromJson({
        'key': 'card.legacy', 'value': 'v', 'type': 0,
        'metadata': const <String, dynamic>{}, 'expiration': 1780000000, 'subtype': 'card',
      });
      expect(r.expiration.millisecondsSinceEpoch, 0);
    });
  });

  group('seconds on the chain', () {
    test('a real date round-trips in seconds and passes the contract', () {
      final when = DateTime.utc(2027, 1, 1);
      final r = Record.asProfile(key: 'profile.status', value: 'away', expiration: when);
      expect(r.chainExpiration, BigInt.from(when.millisecondsSinceEpoch ~/ 1000));
      expect(contractAccepts(r.chainExpiration, blockTsSec), isTrue);
      final back = readFromChain({'key': 'profile.status', 'value': 'away', 'type': 0, 'metadata': {}}, r.chainExpiration, false);
      expect(back.expiration, when);
    });

    test('0 reads as never and is re-sent as 0', () {
      final r = readFromChain({'key': 'profile.bio', 'value': 'hi', 'type': 0, 'metadata': {}}, BigInt.zero, false);
      expect(r.expiration, Record.never);
      expect(r.chainExpiration, BigInt.zero);
    });

    test('a legacy MILLISECOND value reads as never, so a re-save writes 0 (heals)', () {
      final legacy = BigInt.from(1950159338000); // a millisecond value as found on chain
      final r = readFromChain({'key': 'automated_account', 'value': 'true', 'type': 0, 'metadata': {}}, legacy, false);
      expect(r.expiration, Record.never);
      expect(r.chainExpiration, BigInt.zero);
      expect(contractAccepts(r.chainExpiration, blockTsSec), isTrue);
    });

    test('the 06-24 regression stays fixed: a re-sent value is never a past seconds date', () {
      // A ms value that, re-sent as seconds, would be in the past cannot occur: it reads as never.
      final r = readFromChain({'key': 'card.33445b8b', 'value': '@assistant', 'type': 0, 'metadata': {'rank': 'a'}, 'subtype': 'card'},
          BigInt.from(1780000000000), false);
      expect(contractAccepts(r.chainExpiration, blockTsSec), isTrue);
    });
  });

  group('channelTabKey', () {
    test('channel.<slug> when it fits the 31-byte key', () {
      expect(Record.channelTabKey('margins'), 'channel.margins');
      expect(Record.channelTabKey('a' * 23).length, 31);
      expect(Record.channelTabKey('a' * 23), 'channel.${'a' * 23}');
    });

    test('a long slug is cut and hashed to exactly 31, stable, and valid for the chain', () {
      final k = Record.channelTabKey('a-very-long-channel-slug-indeed');
      expect(k.length, 31);
      expect(k, Record.channelTabKey('a-very-long-channel-slug-indeed'));
      expect(RegExp(r'^[a-z0-9_][a-z0-9._-]{0,30}$').hasMatch(k), isTrue);
      expect(k == Record.channelTabKey('a-very-long-channel-slug-indeee'), isFalse);
    });
  });
}
