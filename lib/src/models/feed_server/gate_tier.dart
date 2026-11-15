/// Identity tiers for channel gates — ONE ladder, five values, and they NEST.
///
///     anyone -> signed -> account -> standing -> citizen
///
/// Each tier contains the next. That is the property everything leans on: it is
/// why a post can only ever tighten its channel's setting, and why a refusal can
/// always name the rung that produced it.
///
/// The same ladder serves reading, interacting and posting. It replaces four
/// booleans spread across three separate gates — `require_verified_read`,
/// `require_verified_posting`, `require_verified_comments` and `require_rent` —
/// each of which meant "citizens only" except the last, which meant "paid-up
/// domain". Two different rungs of one ladder wearing unrelated names.
///
/// Server source: `internal/models/tiers.go`.
class GateTier {
  /// No envelope required. Plain RSS works, and a ban cannot bite someone who
  /// never signs.
  static const String anyone = 'anyone';

  /// A valid signature from any key. Proves control of an address without
  /// demanding membership — the cheapest real deterrent, and the rung that did
  /// not exist before this ladder.
  static const String signed = 'signed';

  /// The signing key resolves to a live PublicOS account.
  static const String account = 'account';

  /// A citizen, OR an account with a paid-up domain.
  ///
  /// The OR is load-bearing rather than redundant: a citizen who rented a 3-4
  /// character premium name and stopped paying reads `citizen = true,
  /// compliant = false`, so without it the system would turn away a citizen.
  /// The only people this tier actually stops are accounts with a lapsed
  /// domain.
  static const String standing = 'standing';

  /// Vouched.
  static const String citizen = 'citizen';

  /// Loosest first. Iterate this rather than restating the order anywhere else.
  static const List<String> ladder = [anyone, signed, account, standing, citizen];

  /// Strictness rank. An unknown value ranks as [anyone] so a malformed server
  /// response can never read as *more* restrictive than it is — but callers
  /// should reject unknown values at the boundary rather than lean on that.
  static int ordinal(String tier) {
    final i = ladder.indexOf(tier);
    return i < 0 ? 0 : i;
  }

  static bool isValid(String tier) => ladder.contains(tier);

  /// Whichever of the two is tighter. This is how a channel-level tier acts as
  /// a FLOOR on a post-level one: a post may tighten what the channel decided,
  /// never loosen it. Only correct because the tiers nest.
  static String stricter(String a, String b) =>
      ordinal(b) > ordinal(a) ? b : a;
}
