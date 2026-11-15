// Roundtrip coverage for the publicos-claim consent URI codec — the layer
// between the (contract-tested) sig and the client display. Proves account vs
// newSession are NOT swapped through encode -> decode.
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:publicos_core/src/utils/consent_uri.dart';

void main() {
  // Deliberately distinct, recognizable values so a swap is obvious.
  final account = EthereumAddress.fromHex('0x1111111111111111111111111111111111111111');
  final newSession = EthereumAddress.fromHex('0x2222222222222222222222222222222222222222');
  final deadline = BigInt.from(1717000000);
  final sig = Uint8List(64);
  for (var i = 0; i < 64; i++) {
    sig[i] = i;
  }

  test('add-session URI roundtrip keeps account and newSession distinct (no swap)', () {
    final uri = encodeAddSessionUri(
      newSession: newSession,
      deadline: deadline,
      compactSig: sig,
      account: account,
    );
    final d = decodeConsentUri(uri);
    expect(d.kind, ConsentKind.addSession);
    expect(d.newSession.eip55With0x, newSession.eip55With0x, reason: 'newSession must come back as newSession');
    expect(d.account!.eip55With0x, account.eip55With0x, reason: 'account must come back as account');
    // The smoking-gun check: the two fields must NOT be cross-wired.
    expect(d.newSession.eip55With0x, isNot(account.eip55With0x));
    expect(d.account!.eip55With0x, isNot(newSession.eip55With0x));
    expect(d.deadline, deadline);
  });

  test('new-account URI roundtrip keeps newSession + displayName', () {
    final uri = encodeNewAccountUri(
      newSession: newSession,
      deadline: deadline,
      compactSig: sig,
      displayName: 'alice',
    );
    final d = decodeConsentUri(uri);
    expect(d.kind, ConsentKind.newAccount);
    expect(d.newSession.eip55With0x, newSession.eip55With0x);
    expect(d.displayName, 'alice');
    expect(d.account, isNull);
  });
}
