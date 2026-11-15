// Regression tests for the record-expiration single-source-of-truth fix.
//
// Bug: a record's expiration was duplicated into the on-chain value blob AND
// carried in the contract's `expiration` argument. Writers disagreed on the
// blob's unit (Core: ISO/ms, another writer: seconds), and the read path
// trusted the blob over the arg. A legacy seconds-blob (e.g. 1780000000) was
// read back as DateTime(1970) whose millisecondsSinceEpoch == 1780000000, then
// re-sent verbatim on a profile reorder. The contract's
// `require(expiration > block.timestamp)` (block.timestamp in SECONDS) then
// reverted once that seconds-date had passed, bricking the whole atomic batch.
//
// Fix: the contract `expiration` arg (ms) is the single source of truth. The
// value blob no longer carries expiration ([Record.toChainValue]); reads apply
// the arg ([getRecord]/[getAllUserRecords]); [Record.fromJson] no longer parses
// a blob expiration.
import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/src/models/record_model.dart';

void main() {
  // The contract gate: require(expiration == 0 || expiration > block.timestamp),
  // with block.timestamp in SECONDS.
  bool contractAccepts(int expirationArgMs, int blockTimestampSec) =>
      expirationArgMs == 0 || expirationArgMs > blockTimestampSec;

  // A realistic chain clock (2026-06-23, unix seconds).
  const blockTsSec = 1782238602;

  // Mirrors the read path (getRecord / getAllUserRecords): build the Record from
  // the value blob, then apply the authoritative on-chain expiration arg (ms).
  Record readFromChain(
          Map<String, dynamic> blob, int expirationArgMs, bool expired) =>
      Record.fromJson(blob).copyWith(
        expiration: DateTime.fromMillisecondsSinceEpoch(expirationArgMs),
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
      }).copyWith(expiration: DateTime.fromMillisecondsSinceEpoch(1813761640424));

      final blob = r.toChainValue();
      expect(blob.containsKey('expiration'), isFalse);
      expect(blob.containsKey('isExpired'), isFalse);
      expect(blob['key'], 'card.abc');
      expect(blob['value'], 'https://feeds.publicos.dev/media/x.png');
      expect(blob['subtype'], 'card');
    });
  });

  group('fromJson', () {
    test('ignores any expiration present in a (legacy) blob', () {
      final r = Record.fromJson({
        'key': 'card.legacy',
        'value': 'v',
        'type': 0,
        'metadata': const <String, dynamic>{},
        'expiration': 1780000000, // legacy SECONDS — the old poison
        'subtype': 'card',
      });
      // The blob value does not leak through; expiration is the epoch sentinel
      // until the read path applies the authoritative contract arg.
      expect(r.expiration.millisecondsSinceEpoch, 0);
    });
  });

  group('reorder bake survives legacy seconds records', () {
    test('read applies the ms arg; the re-baked arg passes the contract', () {
      // On-chain state of a manager-written card: SECONDS in the blob, MS in the
      // authoritative arg.
      final blob = {
        'key': 'card.33445b8b',
        'value': '@assistant',
        'type': 0,
        'metadata': {'rank': 'a'},
        'expiration': 1780000000, // seconds (drift-prone duplicate)
        'subtype': 'card',
      };
      const onChainArgMs = 1780000000000; // authoritative ms arg

      final r = readFromChain(blob, onChainArgMs, false);
      // The read used the arg, not the blob.
      expect(r.expiration.millisecondsSinceEpoch, onChainArgMs);

      // The reorder bake re-sends millisecondsSinceEpoch; the contract accepts it.
      final reBakedArg = r.expiration.millisecondsSinceEpoch;
      expect(contractAccepts(reBakedArg, blockTsSec), isTrue);

      // Guard the exact regression: the OLD path re-sent the seconds number,
      // which the contract rejects once that date has passed.
      expect(contractAccepts(1780000000, blockTsSec), isFalse);
    });

    test('expiration arg 0 (never expires) round-trips and is accepted', () {
      final r = readFromChain(
        {
          'key': 'profile.bio',
          'value': 'hi',
          'type': 0,
          'metadata': const <String, dynamic>{},
        },
        0,
        false,
      );
      expect(r.expiration.millisecondsSinceEpoch, 0);
      expect(
          contractAccepts(r.expiration.millisecondsSinceEpoch, blockTsSec), isTrue);
    });
  });
}
