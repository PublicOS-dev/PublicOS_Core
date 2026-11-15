/// Fractional indexing ("LexoRank"-style) order keys for profile records.
///
/// A rank is a non-empty string over a base-62 digit alphabet. Records sort by
/// `rank.compareTo(other.rank)`. To place an item between two neighbours we
/// generate a string strictly between their ranks; strings can always be
/// subdivided, so there is **no exhaustion and no global rebalance** — every
/// reorder is a single record write. This is why the profile uses string ranks
/// rather than integer gaps: a gap scheme eventually collides and needs an
/// N-write (for orgs, N-vote) rebalance, which a string scheme never does.
///
/// Hand-rolled, no package dependency (the project prefers hand-rolled over
/// pulling third-party code for small, well-understood features). The algorithm
/// is the classic recursive `midpoint` over a digit alphabet — the same core as
/// Observable / Figma "fractional-indexing". Invariant: a rank never ends in the
/// lowest digit (`'0'`), which guarantees a successor always exists.
library;

/// Base-62 digit alphabet, ordered so lexical string order == digit order.
const String _digits =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

/// Returns a rank string strictly between [a] and [b].
///
/// `a == null` means "before everything"; `b == null` means "after everything".
/// Requires `a < b` when both are provided. Common cases:
/// - `keyBetween(null, null)` → the first rank for an empty list.
/// - `keyBetween(maxRank, null)` → append after the last item.
/// - `keyBetween(a, b)` → insert between two adjacent items.
String keyBetween(String? a, String? b) {
  if (a != null && b != null && a.compareTo(b) >= 0) {
    throw ArgumentError('keyBetween: lower "$a" must be < upper "$b"');
  }
  return _midpoint(a ?? '', b);
}

/// Generates [n] strictly-increasing ranks between [a] and [b] (exclusive).
///
/// Used by the one-shot "bake" that assigns ranks to a whole profile's worth of
/// records in a single batch write. `nKeysBetween(null, null, n)` yields `n`
/// fresh ranks for an unranked list, in order.
List<String> nKeysBetween(String? a, String? b, int n) {
  if (n <= 0) return const [];
  if (n == 1) return [keyBetween(a, b)];
  if (b == null) {
    var c = keyBetween(a, null);
    final out = <String>[c];
    for (var i = 0; i < n - 1; i++) {
      c = keyBetween(c, null);
      out.add(c);
    }
    return out;
  }
  if (a == null) {
    var c = keyBetween(null, b);
    final out = <String>[c];
    for (var i = 0; i < n - 1; i++) {
      c = keyBetween(null, c);
      out.add(c);
    }
    return out.reversed.toList();
  }
  final mid = n ~/ 2;
  final c = keyBetween(a, b);
  return [
    ...nKeysBetween(a, c, mid),
    c,
    ...nKeysBetween(c, b, n - mid - 1),
  ];
}

/// Recursive midpoint. [a] is a digit string (possibly empty = lower bound);
/// [b] is a digit string or null (= upper bound). Returns a string strictly
/// between them that does not end in the lowest digit.
String _midpoint(String a, String? b) {
  const zero = '0';
  if (b != null) {
    // Strip the longest common prefix (padding `a` with zeros once exhausted),
    // then recurse on the divergent suffix.
    var n = 0;
    while (n < b.length) {
      final ca = n < a.length ? a[n] : zero;
      if (ca != b[n]) break;
      n++;
    }
    if (n > 0) {
      final aTail = a.length > n ? a.substring(n) : '';
      return b.substring(0, n) + _midpoint(aTail, b.substring(n));
    }
  }
  final digitA = a.isNotEmpty ? _digits.indexOf(a[0]) : 0;
  final digitB =
      (b != null && b.isNotEmpty) ? _digits.indexOf(b[0]) : _digits.length;
  if (digitB - digitA > 1) {
    final midDigit = ((digitA + digitB) / 2).round();
    return _digits[midDigit];
  }
  // Digits are adjacent: keep b's leading digit if it has room, else descend
  // into a's tail with no upper bound.
  if (b != null && b.length > 1) {
    return b.substring(0, 1);
  }
  return _digits[digitA] + _midpoint(a.isNotEmpty ? a.substring(1) : '', null);
}
