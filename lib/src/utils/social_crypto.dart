import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:web3dart/web3dart.dart' show EthPrivateKey, keccak256, sign;

/// The device side of social-push privacy (the BLIND gateway):
///
///  - K_s: a 32-byte AES-256-GCM key the device mints and hands to its home
///    inside the signed target PUT; the home seals one blob per device with it;
///    the gateway relays the blob and cannot read it.
///  - R: a throwaway secp256k1 key the device mints and never puts on chain;
///    it signs the gateway calls, so the gateway learns no session and no
///    account.
///
/// Wire form of a blob (my_rss_server internal/notif/blob.go):
/// `base64(nonce ‖ ciphertext ‖ tag)`, 12-byte nonce, 16-byte tag, no AAD.
class SocialCrypto {
  SocialCrypto._();

  static const keySize = 32;
  static const nonceSize = 12;
  static const tagBits = 128;

  static final Random _rng = Random.secure();

  /// Mint a K_s.
  static Uint8List newKey() =>
      Uint8List.fromList(List<int>.generate(keySize, (_) => _rng.nextInt(256)));

  /// Mint an R.
  static EthPrivateKey newThrowawayKey() => EthPrivateKey.createRandom(_rng);

  /// Open a blob with K_s. Throws on a wrong key or a corrupt blob.
  static Uint8List openBlob(Uint8List key, String blobB64) {
    if (key.length != keySize) {
      throw ArgumentError('blob key must be $keySize bytes, got ${key.length}');
    }
    final raw = base64.decode(blobB64);
    if (raw.length < nonceSize + tagBits ~/ 8) {
      throw ArgumentError('blob too short');
    }
    final nonce = raw.sublist(0, nonceSize);
    final body = raw.sublist(nonceSize); // ciphertext ‖ tag
    final gcm = GCMBlockCipher(AESEngine())
      ..init(false,
          AEADParameters(KeyParameter(key), tagBits, nonce, Uint8List(0)));
    return gcm.process(body);
  }

  /// Open a blob and decode its JSON object.
  static Map<String, dynamic> openBlobJson(Uint8List key, String blobB64) =>
      (jsonDecode(utf8.decode(openBlob(key, blobB64))) as Map)
          .cast<String, dynamic>();

  /// Seal a plaintext under a key (tests and the reference client only; the
  /// home does the sealing in production).
  static String sealBlob(Uint8List key, Uint8List plaintext,
      {Uint8List? nonce}) {
    if (key.length != keySize) {
      throw ArgumentError('blob key must be $keySize bytes, got ${key.length}');
    }
    final n = nonce ??
        Uint8List.fromList(
            List<int>.generate(nonceSize, (_) => _rng.nextInt(256)));
    final gcm = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), tagBits, n, Uint8List(0)));
    final out = gcm.process(plaintext);
    return base64.encode([...n, ...out]);
  }

  /// EIP-191 personal-sign with an arbitrary key, v = 27/28, as
  /// `PublicOSSsp.signMessage` does with the session key.
  static String signEip191(EthPrivateKey key, String message) {
    final messageBytes = utf8.encode(message);
    final prefix =
        utf8.encode('\x19Ethereum Signed Message:\n${messageBytes.length}');
    final hash = keccak256(Uint8List.fromList([...prefix, ...messageBytes]));
    final sig = sign(hash, key.privateKey);
    final v = sig.v < 27 ? sig.v + 27 : sig.v;
    return '0x${sig.r.toRadixString(16).padLeft(64, '0')}'
        '${sig.s.toRadixString(16).padLeft(64, '0')}'
        '${v.toRadixString(16).padLeft(2, '0')}';
  }

  /// Sort every map level, so `jsonEncode` of the result is the canonical form
  /// a Go `json.Marshal` of the same map produces (Go sorts keys at every
  /// level; Dart keeps insertion order).
  static dynamic sortedDeep(dynamic v) {
    if (v is Map) {
      final out = <String, dynamic>{};
      for (final k in v.keys.map((e) => e.toString()).toList()..sort()) {
        out[k] = sortedDeep(v[k]);
      }
      return out;
    }
    if (v is List) return v.map(sortedDeep).toList();
    return v;
  }

  /// Build and sign a v2 envelope with a throwaway key (the gateway calls).
  /// Same bytes as `PublicOSSsp.createApiRequest`, minus `account_address`:
  /// a gateway must never see one.
  static Map<String, dynamic> envelopeSignedBy(
    EthPrivateKey key, {
    required String action,
    required String target,
    required Map<String, dynamic> data,
    required String nonce,
    int? timestamp,
  }) {
    final ts = timestamp ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final session = key.address.eip55With0x;
    final body = {
      'action': action,
      'data': sortedDeep(data),
      'nonce': nonce,
      'session': session,
      'target': target,
      'timestamp': ts,
    };
    final signature = signEip191(key, jsonEncode(body));
    return {...body, 'signature': signature};
  }
}
