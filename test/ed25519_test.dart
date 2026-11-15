import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_core/src/utils/ed25519.dart';

Uint8List _hex(String h) {
  final out = Uint8List(h.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(h.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}

void main() {
  group('ed25519Verify — RFC 8032 §7.1 official vectors', () {
    test('TEST 1 (empty message) verifies', () {
      expect(
        ed25519Verify(
          _hex('d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a'),
          Uint8List(0),
          _hex('e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e065224901555fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b'),
        ),
        isTrue,
      );
    });

    test('TEST 2 (message 0x72) verifies', () {
      expect(
        ed25519Verify(
          _hex('3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c'),
          _hex('72'),
          _hex('92a009a9f0d4cab8720e820b5f642540a2b27b5416503f8fb3762223ebdb69da085ac1e43e15996e458f3613d0f11d8c387b2eaeb4302aeeb00d291612bb0c00'),
        ),
        isTrue,
      );
    });

    test('rejects a flipped signature byte', () {
      final sig = _hex(
          'e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e065224901555fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b');
      sig[5] ^= 0x01;
      expect(
        ed25519Verify(
          _hex('d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a'),
          Uint8List(0),
          sig,
        ),
        isFalse,
      );
    });
  });

  group('Solana wallet link — real Phantom signature', () {
    // Captured from a real Phantom signMessage via link_solana.html.
    const account = '0x78615b8f4Ca63681a905a7E37D50Dc4Ece199988';
    const pubB58 = '9njx6BCehwB9FEnP8hxW6cre6u4DEhmZTyMDXdX4bVex';
    final sig = _hex(
        'f1e6b71941aa11c161c6f148e5d445cd8fa99ada26d642b49832afef576f5667dd0cc623e30c95adfeb7db5f1abab20be432c085e5abadd9279d509e3782370e');

    test('verifySolSignature accepts the real Phantom proof', () {
      final msg = PublicOSWallets.solanaLinkMessage(
          accountEip55: account, pubkeyBase58: pubB58);
      final pub = PublicOSWallets.base58Decode(pubB58);
      expect(
        PublicOSWallets.verifySolSignature(
          publicKey: pub,
          message: Uint8List.fromList(utf8.encode(msg)),
          signature: sig,
        ),
        isTrue,
      );
    });

    test('verifySolanaWalletLink accepts genuine, rejects wrong account', () {
      final wallet = Wallet(
        protocol: PublicOSWallets.protoSolana,
        addressData: Uint8List.fromList(utf8.encode(pubB58)), // canonical: utf8 of base58
        chainId: 0,
        label: 'test',
        walletType: WalletType.none,
        proof: sig,
        verification: Verification.claimed,
      );
      expect(
        PublicOSWallets.verifySolanaWalletLink(
          account: EthereumAddress.fromHex(account),
          wallet: wallet,
        ),
        isTrue,
      );
      // Same proof, different account → must reject (account-binding).
      expect(
        PublicOSWallets.verifySolanaWalletLink(
          account: EthereumAddress.fromHex('0x1111111111111111111111111111111111111111'),
          wallet: wallet,
        ),
        isFalse,
      );
    });

    test('verifySolanaWalletLink rejects a non-Solana entry', () {
      final evm = Wallet(
        protocol: PublicOSWallets.protoEvm,
        addressData: Uint8List(20),
        chainId: 0,
        label: 'evm',
        walletType: WalletType.eoa,
        proof: sig,
        verification: Verification.onchainVerified,
      );
      expect(
        PublicOSWallets.verifySolanaWalletLink(
          account: EthereumAddress.fromHex(account),
          wallet: evm,
        ),
        isFalse,
      );
    });

    test('base58 round-trips the pubkey', () {
      expect(
        PublicOSWallets.base58Encode(PublicOSWallets.base58Decode(pubB58)),
        pubB58,
      );
    });
  });
}
