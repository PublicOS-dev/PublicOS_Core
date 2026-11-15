import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/src/utils/pedia_crypto.dart';

Uint8List _hex(String s) {
  final out = Uint8List(s.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(s.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}

/// The golden-vector gate: the fixture was emitted by the
/// server's Go test (my_rss_server internal/crypto/pedia_vector_test.go) via
/// go-ethereum ecies.Encrypt and committed. This decrypt MUST round-trip it
/// byte-exact BEFORE any UI work. If it ever fails: STOP — no shortcut codecs;
/// the scheme gets re-decided together, never patched around.
void main() {
  final fixture = jsonDecode(
          File('test/fixtures/pedia_vector.json').readAsStringSync())
      as Map<String, dynamic>;
  final privKey = _hex(fixture['privkey_hex'] as String);
  final plaintext = _hex(fixture['plaintext_hex'] as String);
  final ciphertext = _hex(fixture['ciphertext_hex'] as String);

  test('golden vector decrypts byte-exact', () {
    expect(PediaCrypto.decrypt(ciphertext, privKey), equals(plaintext));
  });

  test('wire layout is the pinned one', () {
    expect(ciphertext[0], 0x04);
    expect(ciphertext.length, 65 + 16 + plaintext.length + 32);
  });

  test('tampered tag is rejected before decryption', () {
    final tampered = Uint8List.fromList(ciphertext);
    tampered[tampered.length - 1] ^= 0x01;
    expect(() => PediaCrypto.decrypt(tampered, privKey),
        throwsA(isA<StateError>()));
  });

  test('tampered ciphertext byte is rejected by the MAC', () {
    final tampered = Uint8List.fromList(ciphertext);
    tampered[90] ^= 0x01; // inside IV‖ct
    expect(() => PediaCrypto.decrypt(tampered, privKey),
        throwsA(isA<StateError>()));
  });

  test('wrong reader key is rejected (blob sealed to someone else)', () {
    final wrongKey = Uint8List.fromList(privKey);
    wrongKey[31] ^= 0x01;
    expect(() => PediaCrypto.decrypt(ciphertext, wrongKey),
        throwsA(isA<StateError>()));
  });

  test('truncated blob is a format error', () {
    expect(() => PediaCrypto.decrypt(ciphertext.sublist(0, 100), privKey),
        throwsA(isA<FormatException>()));
  });
}
