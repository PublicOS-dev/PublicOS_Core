// Roundtrip + cross-variant tests for the publicos-claim URI codec.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/src/utils/consent_uri.dart';
import 'package:wallet/wallet.dart';

void main() {
  final newSession = EthereumAddress.fromHex(
      '0x90F79bf6EB2c4f870365E785982E1f101E93b906');
  final account = EthereumAddress.fromHex(
      '0x06cd7788D77332cF1156f1E327eBC090B5FF16a3');
  final deadline = BigInt.from(1735000000); // somewhere in 2024
  final compactSig = Uint8List(64)
    ..setRange(0, 32, List<int>.filled(32, 0x11)) // r
    ..setRange(32, 64, List<int>.filled(32, 0x22)) // s (high bit clear → v=27)
    ..[32] = 0x22; // already clear

  test('newAccount roundtrip', () {
    final uri = encodeNewAccountUri(
      newSession: newSession,
      deadline: deadline,
      compactSig: compactSig,
      displayName: 'jmsltest',
    );
    expect(uri.startsWith('publicos-claim:'), isTrue);

    final decoded = decodeConsentUri(uri);
    expect(decoded.kind, ConsentKind.newAccount);
    expect(decoded.newSession.eip55With0x, newSession.eip55With0x);
    expect(decoded.deadline, deadline);
    expect(decoded.compactSig, compactSig);
    expect(decoded.displayName, 'jmsltest');
    expect(decoded.account, isNull);
  });

  test('addSession roundtrip', () {
    final uri = encodeAddSessionUri(
      newSession: newSession,
      deadline: deadline,
      compactSig: compactSig,
      account: account,
    );

    final decoded = decodeConsentUri(uri);
    expect(decoded.kind, ConsentKind.addSession);
    expect(decoded.newSession.eip55With0x, newSession.eip55With0x);
    expect(decoded.deadline, deadline);
    expect(decoded.compactSig, compactSig);
    expect(decoded.account?.eip55With0x, account.eip55With0x);
    expect(decoded.displayName, isNull);
  });

  test('toCompactSig pack/unpack', () {
    // Build a 65-byte sig with v=28 → top bit of s[0] should flip on pack.
    final rsv = Uint8List(65)
      ..setRange(0, 32, List<int>.filled(32, 0xaa))
      ..setRange(32, 64, List<int>.filled(32, 0x42))
      ..[64] = 28;
    final compact = toCompactSig(rsv);
    expect(compact.length, 64);
    expect(compact[32] & 0x80, 0x80, reason: 'v=28 → top bit set');
    expect(compact[32] & 0x7f, 0x42, reason: 's bits preserved');

    // Now expand back via ConsentPayload.expandedSig.
    final uri = encodeAddSessionUri(
      newSession: newSession,
      deadline: deadline,
      compactSig: compact,
      account: account,
    );
    final decoded = decodeConsentUri(uri);
    final expanded = decoded.expandedSig();
    expect(expanded[64], 28);
    expect(expanded.sublist(0, 32), rsv.sublist(0, 32));
    expect(expanded.sublist(32, 64), rsv.sublist(32, 64));
  });

  test('toCompactSig v=27', () {
    final rsv = Uint8List(65)..[64] = 27;
    final compact = toCompactSig(rsv);
    expect(compact[32] & 0x80, 0, reason: 'v=27 → top bit clear');
  });

  test('reject malformed scheme', () {
    expect(() => decodeConsentUri('https://example.com'),
        throwsA(isA<FormatException>()));
    expect(() => decodeConsentUri('publicos-claim:!!!notbase64'),
        throwsA(isA<FormatException>()));
  });

  test('payload size for new-account stays inside QR budget', () {
    final uri = encodeNewAccountUri(
      newSession: newSession,
      deadline: deadline,
      compactSig: compactSig,
      displayName: 'samplelongerthan13chars',
    );
    // Spec budget: ~110-122 bytes raw, ~160 chars base64. With our
    // overhead the URI fits easily within QR v10. Sanity check:
    expect(uri.length, lessThan(220),
        reason: 'URI exceeded the QR-v10 budget');
  });
}
