import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:pointycastle/stream/ctr.dart';

/// ECIES decrypt for `/pedia/` private-media blobs — the Dart half of the
/// scheme.
///
/// Matches go-ethereum `crypto/ecies` defaults on secp256k1 exactly
/// (ECIES_AES128_SHA256): NIST SP 800-56 concatenation KDF over the ECDH
/// x-coordinate, AES-128-CTR + HMAC-SHA-256 encrypt-then-MAC. Wire layout as
/// `ecies.Encrypt` emits:
///
///   0x04 ‖ ephemX ‖ ephemY (65 B) ‖ IV (16 B) ‖ ct (len(plaintext)) ‖ tag (32 B)
///
/// `/pedia/`: the server encrypts (sealing each blob to the requesting reader's
/// envelope-recovered pubkey) and clients open blobs sealed to their own
/// keychain EOA. [encrypt] is the reverse, for SSP **notices**:
/// the app seals a letter to the host's `notice_key` pointer and the host's
/// operator opens it with go-ethereum `ecies.Decrypt`
/// (my_rss_server `DecryptNoticeLetter`). Correctness is gated by the
/// committed golden vector (test/fixtures/pedia_vector.json — emitted by the
/// server's Go test); if the round-trip ever fails, STOP — no shortcut codecs.
class PediaCrypto {
  PediaCrypto._();

  static final ECDomainParameters _secp256k1 = ECCurve_secp256k1();

  /// Opens [sealed] with the 32-byte keychain EOA private key [privKey].
  /// Throws [FormatException] on a malformed wire layout and
  /// [StateError] on MAC mismatch (tampered or wrong-reader blob).
  static Uint8List decrypt(Uint8List sealed, Uint8List privKey) {
    // 65 pubkey + 16 IV + 32 tag is the floor (empty plaintext).
    if (sealed.length < 65 + 16 + 32) {
      throw FormatException(
          'pedia blob too short: ${sealed.length} bytes, need ≥ 113');
    }
    if (sealed[0] != 0x04) {
      throw const FormatException(
          'pedia blob does not start with an uncompressed pubkey (0x04)');
    }

    // 1. Ephemeral public key R.
    final r = _secp256k1.curve.decodePoint(sealed.sublist(0, 65));
    if (r == null) {
      throw const FormatException('invalid ephemeral public key point');
    }
    final em = sealed.sublist(65, sealed.length - 32); // IV ‖ ct
    final tag = sealed.sublist(sealed.length - 32);

    // 2. ECDH shared secret z = (R · d).x, left-padded to 32 bytes —
    //    go-ethereum GenerateShared parity (sk buffer is skLen+macLen = 32).
    final d = _bytesToBigInt(privKey);
    final shared = (r * d);
    final sharedX = shared?.x?.toBigInteger();
    if (sharedX == null) {
      throw const FormatException('ECDH shared point at infinity');
    }
    final z = _bigIntTo32(sharedX);

    // 3. NIST concatenation KDF (SHA-256): counter(4 BE) ‖ z per round.
    final k = _concatKDF(z, 32);

    // 4. Ke = K[0..16]; Km = SHA256(K[16..32]) — go-ethereum hashes Km.
    final ke = k.sublist(0, 16);
    final km = _sha256(k.sublist(16, 32));

    // 5. Encrypt-then-MAC check over em (= IV ‖ ct), BEFORE any decryption.
    final mac = HMac(SHA256Digest(), 64)..init(KeyParameter(km));
    mac.update(em, 0, em.length);
    final expected = Uint8List(32);
    mac.doFinal(expected, 0);
    var diff = 0;
    for (var i = 0; i < 32; i++) {
      diff |= expected[i] ^ tag[i];
    }
    if (diff != 0) {
      throw StateError('pedia blob MAC mismatch — tampered or wrong reader');
    }

    // 6. AES-128-CTR: IV = em[0..16], ciphertext = the rest.
    final ctr = CTRStreamCipher(AESEngine())
      ..init(false, ParametersWithIV(KeyParameter(ke), em.sublist(0, 16)));
    return ctr.process(em.sublist(16));
  }

  /// Seals [plaintext] to [pubKey], an uncompressed secp256k1 public key
  /// (65 bytes, `0x04 ‖ X ‖ Y`, as go-ethereum `crypto.FromECDSAPub` writes
  /// it). Output is the wire layout [decrypt] reads and go-ethereum
  /// `ecies.Decrypt` opens: a fresh ephemeral key and IV per call.
  static Uint8List encrypt(Uint8List plaintext, Uint8List pubKey) {
    const bad = FormatException(
        'recipient key must be an uncompressed secp256k1 point (0x04, 65 bytes)');
    if (pubKey.length != 65 || pubKey[0] != 0x04) throw bad;
    final ECPoint? q;
    try {
      q = _secp256k1.curve.decodePoint(pubKey);
    } catch (_) {
      throw bad;
    }
    if (q == null) throw bad;
    final rnd = _secureRandom();

    // 1. Ephemeral key pair (r, R).
    BigInt r;
    do {
      r = _bytesToBigInt(rnd.nextBytes(32));
    } while (r == BigInt.zero || r >= _secp256k1.n);
    final rPoint = (_secp256k1.G * r)!;
    final rEncoded = rPoint.getEncoded(false); // 0x04 ‖ X ‖ Y

    // 2. z = (Q · r).x, left-padded to 32 bytes.
    final sharedX = (q * r)?.x?.toBigInteger();
    if (sharedX == null) {
      throw const FormatException('ECDH shared point at infinity');
    }
    final z = _bigIntTo32(sharedX);

    // 3-4. Same KDF and key split as [decrypt].
    final k = _concatKDF(z, 32);
    final ke = k.sublist(0, 16);
    final km = _sha256(k.sublist(16, 32));

    // 5. AES-128-CTR under a random IV.
    final iv = rnd.nextBytes(16);
    final ctr = CTRStreamCipher(AESEngine())
      ..init(true, ParametersWithIV(KeyParameter(ke), iv));
    final ct = ctr.process(plaintext);
    final em = Uint8List(16 + ct.length)
      ..setRange(0, 16, iv)
      ..setRange(16, 16 + ct.length, ct);

    // 6. Tag = HMAC-SHA256(Km, IV ‖ ct).
    final mac = HMac(SHA256Digest(), 64)..init(KeyParameter(km));
    mac.update(em, 0, em.length);
    final tag = Uint8List(32);
    mac.doFinal(tag, 0);

    return Uint8List.fromList([...rEncoded, ...em, ...tag]);
  }

  static SecureRandom _secureRandom() {
    final seed = Random.secure();
    return FortunaRandom()
      ..seed(KeyParameter(
          Uint8List.fromList(List<int>.generate(32, (_) => seed.nextInt(256)))));
  }

  static Uint8List _concatKDF(Uint8List z, int kdLen) {
    final out = BytesBuilder(copy: false);
    var counter = 1;
    while (out.length < kdLen) {
      final digest = SHA256Digest();
      final ctr = ByteData(4)..setUint32(0, counter, Endian.big);
      digest.update(ctr.buffer.asUint8List(), 0, 4);
      digest.update(z, 0, z.length);
      final round = Uint8List(32);
      digest.doFinal(round, 0);
      out.add(round);
      counter++;
    }
    return Uint8List.fromList(out.toBytes().sublist(0, kdLen));
  }

  static Uint8List _sha256(Uint8List data) {
    final digest = SHA256Digest();
    final out = Uint8List(32);
    digest.update(data, 0, data.length);
    digest.doFinal(out, 0);
    return out;
  }

  static BigInt _bytesToBigInt(Uint8List bytes) {
    var result = BigInt.zero;
    for (final b in bytes) {
      result = (result << 8) | BigInt.from(b);
    }
    return result;
  }

  static Uint8List _bigIntTo32(BigInt value) {
    final out = Uint8List(32);
    var v = value;
    for (var i = 31; i >= 0; i--) {
      out[i] = (v & BigInt.from(0xff)).toInt();
      v = v >> 8;
    }
    return out;
  }
}
