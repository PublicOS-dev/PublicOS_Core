// Tests for the hand-rolled fractional-indexing rank generator
// (utils/lexorank.dart) used by profile-record ordering.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/src/utils/lexorank.dart';

void main() {
  group('keyBetween', () {
    test('first key for an empty list is non-empty and not zero-terminated', () {
      final k = keyBetween(null, null);
      expect(k, isNotEmpty);
      expect(k.endsWith('0'), isFalse);
    });

    test('append after produces a strictly greater key', () {
      var prev = keyBetween(null, null);
      for (var i = 0; i < 200; i++) {
        final next = keyBetween(prev, null);
        expect(prev.compareTo(next) < 0, isTrue,
            reason: 'append $i: "$prev" !< "$next"');
        expect(next.endsWith('0'), isFalse);
        prev = next;
      }
    });

    test('prepend before produces a strictly smaller key', () {
      var next = keyBetween(null, null);
      for (var i = 0; i < 200; i++) {
        final prev = keyBetween(null, next);
        expect(prev.compareTo(next) < 0, isTrue,
            reason: 'prepend $i: "$prev" !< "$next"');
        next = prev;
      }
    });

    test('between two keys lands strictly between them', () {
      final a = keyBetween(null, null);
      final b = keyBetween(a, null);
      final c = keyBetween(a, b);
      expect(a.compareTo(c) < 0, isTrue);
      expect(c.compareTo(b) < 0, isTrue);
    });

    test('repeated insertion at the same seam stays ordered (no exhaustion)', () {
      var lo = keyBetween(null, null);
      var hi = keyBetween(lo, null);
      for (var i = 0; i < 100; i++) {
        final mid = keyBetween(lo, hi);
        expect(lo.compareTo(mid) < 0, isTrue, reason: 'seam $i lo');
        expect(mid.compareTo(hi) < 0, isTrue, reason: 'seam $i hi');
        hi = mid; // keep narrowing the same gap
      }
    });

    test('throws when lower >= upper', () {
      final a = keyBetween(null, null);
      final b = keyBetween(a, null);
      expect(() => keyBetween(b, a), throwsArgumentError);
      expect(() => keyBetween(a, a), throwsArgumentError);
    });
  });

  group('nKeysBetween', () {
    test('generates n strictly-increasing keys for a fresh list', () {
      for (final n in [0, 1, 2, 3, 7, 25, 50]) {
        final keys = nKeysBetween(null, null, n);
        expect(keys.length, n);
        for (var i = 1; i < keys.length; i++) {
          expect(keys[i - 1].compareTo(keys[i]) < 0, isTrue,
              reason: 'n=$n at $i: ${keys[i - 1]} !< ${keys[i]}');
        }
      }
    });

    test('keys between two bounds stay within the bounds and ordered', () {
      final a = keyBetween(null, null);
      final b = keyBetween(a, null);
      final keys = nKeysBetween(a, b, 8);
      expect(keys.length, 8);
      expect(a.compareTo(keys.first) < 0, isTrue);
      expect(keys.last.compareTo(b) < 0, isTrue);
      for (var i = 1; i < keys.length; i++) {
        expect(keys[i - 1].compareTo(keys[i]) < 0, isTrue);
      }
    });
  });

  group('fuzz: random insert sequence stays a strict total order', () {
    test('500 random inserts into a growing ordered list', () {
      final rng = Random(42);
      // Maintain a sorted list of ranks; insert at random positions.
      final ranks = <String>[keyBetween(null, null)];
      for (var op = 0; op < 500; op++) {
        final pos = rng.nextInt(ranks.length + 1);
        final lo = pos == 0 ? null : ranks[pos - 1];
        final hi = pos == ranks.length ? null : ranks[pos];
        final k = keyBetween(lo, hi);
        ranks.insert(pos, k);
      }
      // The list must still be strictly increasing and contain no duplicates.
      final seen = <String>{};
      for (var i = 0; i < ranks.length; i++) {
        expect(seen.add(ranks[i]), isTrue, reason: 'duplicate at $i: ${ranks[i]}');
        if (i > 0) {
          expect(ranks[i - 1].compareTo(ranks[i]) < 0, isTrue,
              reason: 'order broken at $i: ${ranks[i - 1]} !< ${ranks[i]}');
        }
      }
      expect(ranks.length, 501);
    });
  });
}
