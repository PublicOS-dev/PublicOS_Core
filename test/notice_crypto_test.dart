// The reverse of pedia_crypto_test.dart:
// Core ENCRYPTS an SSP notice letter to the host's notice_key and the
// host's Go side (go-ethereum ecies.Decrypt) opens it. Two checks:
//
//  1. Round trip in Dart: PediaCrypto.encrypt then PediaCrypto.decrypt.
//  2. The cross-language fixture test/fixtures/notice_vector.json, emitted
//     ONCE and never overwritten. The server's
//     internal/crypto/notice_vector_test.go decrypts the committed copy; if it
//     fails, STOP: no shortcut codecs.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:publicos_core/src/utils/pedia_crypto.dart';
import 'package:flutter_test/flutter_test.dart';

// Throwaway test key, the same one the pedia vector uses. NEVER a real one.
const _privHex = '4c0883a69102937d6231471b5dbb6204fe512961708279f2e3e8a5d4b8e3e8a5';
const _plaintext = 'notice vector v1 — Core encrypts, go-ethereum ecies.Decrypt opens';
const _fixture = 'test/fixtures/notice_vector.json';

String _hexOf(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
Uint8List _bytesOf(String h) => Uint8List.fromList(List<int>.generate(h.length ~/ 2, (i) => int.parse(h.substring(2 * i, 2 * i + 2), radix: 16)));

Uint8List _pubOf(String privHex) {
  final d = BigInt.parse(privHex, radix: 16);
  final q = ECCurve_secp256k1().G * d;
  return q!.getEncoded(false);
}

void main() {
  final priv = Uint8List.fromList(_bytesOf(_privHex));
  final pub = _pubOf(_privHex);

  test('encrypt then decrypt round-trips', () {
    final plain = Uint8List.fromList(utf8.encode(_plaintext));
    final sealed = PediaCrypto.encrypt(plain, pub);
    expect(sealed.length, 65 + 16 + plain.length + 32);
    expect(sealed[0], 0x04);
    expect(utf8.decode(PediaCrypto.decrypt(sealed, priv)), _plaintext);
  });

  test('every seal is fresh (new ephemeral key + IV)', () {
    final plain = Uint8List.fromList(utf8.encode('x'));
    expect(_hexOf(PediaCrypto.encrypt(plain, pub)),
        isNot(_hexOf(PediaCrypto.encrypt(plain, pub))));
  });

  test('a wrong reader cannot open it', () {
    final sealed = PediaCrypto.encrypt(Uint8List.fromList([1, 2, 3]), pub);
    final other = Uint8List.fromList(List<int>.filled(31, 0) + [7]);
    expect(() => PediaCrypto.decrypt(sealed, other), throwsStateError);
  });

  test('rejects a key that is not an uncompressed point', () {
    expect(() => PediaCrypto.encrypt(Uint8List(3), Uint8List(33)),
        throwsFormatException);
  });

  test('emit the cross-language fixture once', () {
    final f = File(_fixture);
    if (f.existsSync()) {
      markTestSkipped('$_fixture already exists: the committed fixture is the contract');
      return;
    }
    final plain = Uint8List.fromList(utf8.encode(_plaintext));
    final sealed = PediaCrypto.encrypt(plain, pub);
    f.writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
      'privkey_hex': _privHex,
      'pubkey_hex': _hexOf(pub),
      'plaintext_hex': _hexOf(plain),
      'ciphertext_hex': _hexOf(sealed),
    }));
  });
}
