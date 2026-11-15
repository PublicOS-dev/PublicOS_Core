/// Pure-Dart port of `contracts/libraries/DisplayNameValidator.sol`.
///
/// Mirrors the on-chain charset/length rules so UIs can validate live and
/// fail fast before paying gas. Behaviour MUST stay byte-for-byte equivalent
/// to the Solidity library — any divergence produces "name passed in client
/// but reverted on-chain" UX bugs.
///
/// Storage in `AccountMemory` is case-preserving; collision is case-insensitive
/// (AccountManager `_getDisplayNameHash` lowercases A-Z before keccak). This
/// library accepts both cases without introducing new collision surface.
///
/// Caller resolves the (minLength, maxLength) tier — all from DomainMemory, the
/// single name-policy ledger under the domain-rights economy:
///   - createAccount     → (minCharsNewAccount, maxChars)  // new accounts born private
///   - changeName        → (minDomainChars, maxChars)  // UNIVERSAL floor; the price
///                          tier gates premium 3-6 char names, not the charset
///   - createOrg         → isPublic ? (minCharsPublicOrg, maxChars) : (minCharsNewAccount, maxChars)
///   - rootForceRename   → (minCharsRoot, maxChars)
///   - rootGrantName     → BYPASSES (root assigns anything)
///
/// Read live tier minima from DomainMemory via `PublicOSAccounts.getNameTierLimits`
/// (do not bake constants — governance can tune them).
library;

import 'dart:convert';
import 'dart:typed_data';
import 'package:web3dart/web3dart.dart' show keccak256;

/// What policy tier a length-valid name qualifies for.
///
/// Tiers are nested: a length that satisfies `minDomainChars` also satisfies
/// `minCharsPublicOrg` and `minCharsNewAccount` if those are higher. The validator
/// only enforces the (min, max) range the caller passes; tier classification
/// is a UX hint surfaced alongside the validation result.
enum NameTier { root, citizen, publicOrg, private, none }

/// Specific reason a name failed `validate`. Surfaced in UI for live feedback
/// (char counter, "needs to start with a letter", etc.) so the user gets
/// actionable text rather than a generic "invalid".
enum NameValidationError {
  empty,
  tooShort,
  tooLong,
  leadingNonAlpha,
  trailingNonAlphanumeric,
  illegalChar,
  consecutiveDash,
  consecutiveUnderscore,
}

class NameValidationResult {
  final bool ok;
  final NameValidationError? reason;
  final int byteLength;

  const NameValidationResult.valid({required this.byteLength})
      : ok = true,
        reason = null;
  const NameValidationResult.invalid({
    required this.reason,
    required this.byteLength,
  }) : ok = false;
}

class DisplayNameValidator {
  /// Returns valid iff `name` satisfies the policy at [minLength, maxLength].
  /// Iterates UTF-8 bytes to mirror Solidity's `bytes(name).length` semantics —
  /// non-ASCII input is rejected on the first byte that fails `_isAllowedChar`.
  static NameValidationResult validate(
    String name, {
    required int minLength,
    required int maxLength,
  }) {
    final bytes = utf8.encode(name);
    final len = bytes.length;
    if (len == 0) {
      return const NameValidationResult.invalid(
        reason: NameValidationError.empty,
        byteLength: 0,
      );
    }
    if (len < minLength) {
      return NameValidationResult.invalid(
        reason: NameValidationError.tooShort,
        byteLength: len,
      );
    }
    if (len > maxLength) {
      return NameValidationResult.invalid(
        reason: NameValidationError.tooLong,
        byteLength: len,
      );
    }
    if (!_isAlpha(bytes[0])) {
      return NameValidationResult.invalid(
        reason: NameValidationError.leadingNonAlpha,
        byteLength: len,
      );
    }
    if (!_isAlphaNumeric(bytes[len - 1])) {
      return NameValidationResult.invalid(
        reason: NameValidationError.trailingNonAlphanumeric,
        byteLength: len,
      );
    }
    for (var i = 0; i < len; i++) {
      final c = bytes[i];
      if (!_isAllowedChar(c)) {
        return NameValidationResult.invalid(
          reason: NameValidationError.illegalChar,
          byteLength: len,
        );
      }
      if (i > 0) {
        final prev = bytes[i - 1];
        if (c == 0x2D && prev == 0x2D) {
          return NameValidationResult.invalid(
            reason: NameValidationError.consecutiveDash,
            byteLength: len,
          );
        }
        if (c == 0x5F && prev == 0x5F) {
          return NameValidationResult.invalid(
            reason: NameValidationError.consecutiveUnderscore,
            byteLength: len,
          );
        }
      }
    }
    return NameValidationResult.valid(byteLength: len);
  }

  /// Returns the lowest tier whose minimum [length] satisfies. Tiers nest:
  /// a private-tier length implicitly clears citizen + public-org + root.
  /// Returns `NameTier.none` if length is below `minRoot`.
  static NameTier classifyTier(
    int length, {
    required int minRoot,
    required int minCitizen,
    required int minPublicOrg,
    required int minPrivate,
  }) {
    if (length >= minPrivate) return NameTier.private;
    if (length >= minPublicOrg) return NameTier.publicOrg;
    if (length >= minCitizen) return NameTier.citizen;
    if (length >= minRoot) return NameTier.root;
    return NameTier.none;
  }

  /// Compute the bytes32 hash matching `AccountManager._getDisplayNameHash` —
  /// keccak256(utf8(asciiLowerFold(name))). Use to query mappings keyed by
  /// display-name hash (e.g. `AccountMemory.nameCooldownUntil`).
  ///
  /// The fold is ASCII-only (0x41-0x5A → 0x61-0x7A) to mirror Solidity exactly.
  /// `String.toLowerCase()` would do Unicode case folding which is broader.
  static Uint8List computeHash(String name) {
    return keccak256(_asciiLowerFold(utf8.encode(name)));
  }

  static Uint8List _asciiLowerFold(List<int> bytes) {
    final out = Uint8List.fromList(bytes);
    for (var i = 0; i < out.length; i++) {
      if (out[i] >= 0x41 && out[i] <= 0x5A) out[i] += 0x20;
    }
    return out;
  }

  static bool _isAlpha(int c) =>
      (c >= 0x61 && c <= 0x7A) || (c >= 0x41 && c <= 0x5A);
  static bool _isAlphaNumeric(int c) =>
      _isAlpha(c) || (c >= 0x30 && c <= 0x39);
  static bool _isAllowedChar(int c) =>
      _isAlphaNumeric(c) || c == 0x2D || c == 0x5F;
}

/// Snapshot of the four tier minimums + `maxChars` from `AccountMemory`.
/// Read once per surface (e.g. on `_loadData`); these change rarely
/// (governance tuning) but we don't bake constants.
class NameTierLimits {
  final int minRoot;
  final int minCitizen;
  final int minPublicOrg;
  final int minPrivate;
  final int maxChars;

  const NameTierLimits({
    required this.minRoot,
    required this.minCitizen,
    required this.minPublicOrg,
    required this.minPrivate,
    required this.maxChars,
  });
}
