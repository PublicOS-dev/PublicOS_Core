// Does a REAL EIP-712 consent signature survive the QR transport codec and
// still ecrecover to the signer? The contract's _verifyConsent recovers the
// signer from (digest, sig) and checks it == firstSession. If the
// compact<->expanded round-trip in consent_uri.dart corrupts the sig, the
// recovered signer is wrong -> on-chain "execution reverted" with no reason,
// while the displayName/address fields still decode fine (they don't go
// through the lossy packing). That is the exact symptom we're chasing.
//
// The existing consent_uri_test.dart only uses synthetic, always-low-s sig
// bytes, so it cannot catch a high-s signing output. This test signs many
// real consents and asserts recoverability after transport.
//
// Types note: EthereumAddress / EthPrivateKey come from the `wallet` package
// (re-exported by publicos_core); only the ecrecover crypto comes from
// web3dart (prefixed `w3`).

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart' hide EthPrivateKey;
import 'package:publicos_core/src/utils/eip712_consent.dart';
import 'package:web3dart/web3dart.dart' as w3;

// secp256k1 order and half-order (EIP-2 canonical-s threshold).
final BigInt _n = BigInt.parse(
    'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141',
    radix: 16);
final BigInt _halfN = _n >> 1;

// The deployed AccountManager (verifyingContract). Value is irrelevant to the
// round-trip itself (we recover against the same digest we signed), but use
// the real one so the test mirrors production exactly.
final EthereumAddress _accountManager =
    EthereumAddress.fromHex('0xeeAc25d90447452EcA6eA6041488a000e0d9A69F');

BigInt _be(List<int> b) {
  var r = BigInt.zero;
  for (final x in b) {
    r = (r << 8) | BigInt.from(x);
  }
  return r;
}

String _hex(Uint8List b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

bool _listEq(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// New random key (web3dart EthPrivateKey — the type the sign path expects)
/// plus its address as a wallet EthereumAddress (the type the consent
/// functions expect). Convert through the checksummed hex.
(w3.EthPrivateKey, EthereumAddress) _newKey(Random rng) {
  final key = w3.EthPrivateKey.createRandom(rng);
  return (key, key.address);
}

Uint8List _createAccountDigest(
    String displayName, EthereumAddress newSession, BigInt deadline) {
  final structHash = createAccountStructHash(
    displayName: displayName,
    newSession: newSession,
    deadline: deadline,
    protocolVersion: BigInt.one, // agreements: any fixed version works for a transport test
  );
  final domainSep = domainSeparator(
    chainId: 4489,
    verifyingContract: _accountManager,
  );
  return finalDigest(domainSep: domainSep, structHash: structHash);
}

/// Lowercase 0x-hex of the address recovered from (digest, 65-byte sig).
String _recoverHex(Uint8List digest, Uint8List sig65) {
  final r = _be(sig65.sublist(0, 32));
  final s = _be(sig65.sublist(32, 64));
  final v = sig65[64];
  final pub = w3.ecRecover(digest, w3.MsgSignature(r, s, v));
  // web3dart can return a 63-byte pubkey when the X coord has a leading zero;
  // left-pad to 64 so publicKeyToAddress's length assert holds.
  final padded = pub.length == 64
      ? pub
      : (Uint8List(64)..setRange(64 - pub.length, 64, pub));
  return '0x${_hex(w3.publicKeyToAddress(padded))}';
}

void main() {
  test('Core sign recovers to signer (baseline — digest + sign are ok)', () {
    final (key, newSession) = _newKey(Random.secure());
    final deadline =
        BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600);
    final digest = _createAccountDigest('mike_0000', newSession, deadline);
    final sig = signDigest(digest, key);
    expect(_recoverHex(digest, sig), newSession.eip55With0x.toLowerCase(),
        reason: 'signDigest output must recover to the signer');
  });

  test('real consent sig survives the full QR codec round-trip (×400)', () {
    final rng = Random.secure();
    var highSCount = 0;
    var byteMismatches = 0;
    var transportFailures = 0;
    final failExamples = <String>[];

    for (var i = 0; i < 400; i++) {
      final (key, newSession) = _newKey(rng);
      final deadline =
          BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600);
      const displayName = 'mike_0000';

      final digest = _createAccountDigest(displayName, newSession, deadline);
      final originalSig = signDigest(digest, key);

      // Did Core's sign produce a high-s value (the case the compact codec
      // assumes never happens)?
      final s = _be(originalSig.sublist(32, 64));
      final isHighS = s > _halfN;
      if (isHighS) highSCount++;

      // ---- the exact transport the new device + sponsor perform ----
      final compact = toCompactSig(originalSig);
      final uri = encodeNewAccountUri(
        newSession: newSession,
        deadline: deadline,
        compactSig: compact,
        displayName: displayName,
      );
      final decoded = decodeConsentUri(uri);
      final transportedSig = decoded.expandedSig();
      // --------------------------------------------------------------

      // Fields must survive (sanity — matches the working log).
      expect(decoded.displayName, displayName);
      expect(decoded.newSession.eip55With0x, newSession.eip55With0x);
      expect(decoded.deadline, deadline);

      // Did the bytes themselves survive?
      final byteMismatch = !_listEq(transportedSig, originalSig);
      if (byteMismatch) byteMismatches++;

      // The actual question: does the transported sig still recover to the
      // signer? (This is what the contract checks.)
      String recovered;
      try {
        recovered = _recoverHex(digest, transportedSig);
      } catch (e) {
        recovered = 'RECOVER_ERROR';
      }
      if (recovered != newSession.eip55With0x.toLowerCase()) {
        transportFailures++;
        if (failExamples.length < 5) {
          failExamples.add('highS=$isHighS byteMismatch=$byteMismatch '
              'origV=${originalSig[64]} recovered=$recovered '
              'expected=${newSession.eip55With0x.toLowerCase()}');
        }
      }
    }

    // ignore: avoid_print
    print('high-s signatures: $highSCount / 400');
    // ignore: avoid_print
    print('byte mismatches after round-trip: $byteMismatches / 400');
    // ignore: avoid_print
    print('transport recover failures: $transportFailures / 400');
    for (final e in failExamples) {
      // ignore: avoid_print
      print('  fail: $e');
    }

    expect(transportFailures, 0,
        reason: 'A real consent sig failed to recover after the QR codec '
            'round-trip — the sponsor would see "execution reverted". '
            'high-s count=$highSCount (compact codec assumes low-s).');
  });

  test('byte-exact round-trip for a real signature', () {
    final (key, newSession) = _newKey(Random.secure());
    final deadline =
        BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600);
    final digest = _createAccountDigest('mike_0000', newSession, deadline);
    final originalSig = signDigest(digest, key);

    final decoded = decodeConsentUri(encodeNewAccountUri(
      newSession: newSession,
      deadline: deadline,
      compactSig: toCompactSig(originalSig),
      displayName: 'mike_0000',
    ));
    expect(decoded.expandedSig(), originalSig,
        reason: 'expanded sig must be byte-identical to the original');
  });
}
