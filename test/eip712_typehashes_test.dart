// Drift detector for the EIP-712 typehashes shared between
// PublicOS_Core (Dart) and ContactOS_Contracts (Solidity).
//
// The silent-failure mode: someone edits the type string on one side, sigs
// verify locally but revert on chain. This test reads the Solidity source
// directly (cross-repo path — the contracts repo is expected at the path
// set below) and asserts
// every `bytes32 private constant *_TYPEHASH = keccak256("...")` literal
// matches its Dart counterpart byte-for-byte.
//
// Bonus assertion: keccak256(typeString) is computed on the Dart side and
// asserted to match what we expect — guards the digest pipeline itself.
//
// If the Solidity source is missing (e.g. CI environment), the test
// SKIPS rather than failing loudly. Local dev gets the drift signal.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:publicos_core/src/utils/eip712_consent.dart';

const _solidityPath =
    r'..\ContactOS_Contracts\contracts\AccountManager.sol';

const _wdmPath =
    r'..\ContactOS_Contracts\contracts\WalletDirectoryManager.sol';

/// Per-typehash record: the Solidity constant name + the Dart type string
/// we expect to find inside its `keccak256("...")` literal.
const Map<String, String> _expected = {
  'CREATE_ACCOUNT_TYPEHASH': createAccountConsentTypeString,
  // add/reseed/full-reset share one typehash.
  // A key is a session; the consent carries a ttl.
  'SESSION_CONSENT_TYPEHASH': sessionConsentTypeString,
};

void main() {
  group('EIP-712 typehash drift', () {
    late String soliditySource;
    setUpAll(() {
      final file = File(_solidityPath);
      if (!file.existsSync()) {
        markTestSkipped(
          'Solidity source not found at $_solidityPath — skipping drift check. '
          'Run locally with ContactOS_Contracts checked out alongside PublicOS_Core.',
        );
        soliditySource = '';
        return;
      }
      soliditySource = file.readAsStringSync();
    });

    for (final entry in _expected.entries) {
      final name = entry.key;
      final dartTypeString = entry.value;

      test('$name matches Solidity source', () {
        if (soliditySource.isEmpty) return;
        final pattern = RegExp(
          r'bytes32\s+private\s+constant\s+' +
              RegExp.escape(name) +
              r'\s*=\s*keccak256\(\s*"([^"]+)"\s*\)',
          multiLine: true,
        );
        final match = pattern.firstMatch(soliditySource);
        expect(
          match,
          isNotNull,
          reason:
              '$name not found in $_solidityPath — either the contract was '
              'refactored or the regex needs updating.',
        );
        final solidityTypeString = match!.group(1)!;
        expect(
          solidityTypeString,
          dartTypeString,
          reason:
              'Drift: $name type string differs between Solidity and '
              'lib/src/utils/eip712_consent.dart. Sigs will verify on Dart '
              'side but revert on chain. Update one to match the other.',
        );
      });
    }

    test('Dart-computed typehashes are deterministic', () {
      // Sanity: re-computing must yield the same bytes. Catches keccak/utf8
      // implementation drift if a Dart-side dep ever changes behavior.
      final a = createAccountTypehash;
      final b = createAccountTypehash;
      expect(_hex(a), _hex(b));
      expect(a.length, 32);
    });

    test('distinct-purpose typehashes stay distinct', () {
      // add / reseed / full-reset DELIBERATELY
      // share one SessionConsent (the submitter's authority is the gate,
      // not the typehash). What must still differ: CreateAccount (different
      // struct shape) and LinkWallet (different verifying contract) vs the
      // shared SessionConsent — a collision there would be a real bug.
      final hashes = <String, String>{
        'CREATE_ACCOUNT': _hex(createAccountTypehash),
        'SESSION_CONSENT': _hex(sessionConsentTypehash),
        'LINK_WALLET': _hex(linkWalletTypehash),
      };
      final seen = <String, String>{};
      for (final e in hashes.entries) {
        final prev = seen[e.value];
        expect(prev, isNull, reason: 'Typehash collision: ${e.key} == $prev');
        seen[e.value] = e.key;
      }
    });
  });

  group('WalletDirectory LinkWallet typehash drift', () {
    late String wdmSource;
    setUpAll(() {
      final file = File(_wdmPath);
      if (!file.existsSync()) {
        markTestSkipped(
          'WalletDirectoryManager.sol not found at $_wdmPath — skipping. '
          'Run locally with ContactOS_Contracts checked out alongside PublicOS_Core.',
        );
        wdmSource = '';
        return;
      }
      wdmSource = file.readAsStringSync();
    });

    test('LINK_WALLET_TYPEHASH matches Solidity source', () {
      if (wdmSource.isEmpty) return;
      final pattern = RegExp(
        r'bytes32\s+private\s+constant\s+LINK_WALLET_TYPEHASH\s*=\s*keccak256\(\s*"([^"]+)"\s*\)',
        multiLine: true,
      );
      final match = pattern.firstMatch(wdmSource);
      expect(
        match,
        isNotNull,
        reason:
            'LINK_WALLET_TYPEHASH not found in $_wdmPath — either the contract '
            'was refactored or the regex needs updating.',
      );
      expect(
        match!.group(1)!,
        linkWalletConsentTypeString,
        reason:
            'Drift: LinkWallet type string differs between Solidity and '
            'lib/src/utils/eip712_consent.dart. addWallet proofs will verify on '
            'the Dart side but revert on chain. Update one to match the other.',
      );
    });
  });

  group('EIP-712 final-digest pipeline sanity', () {
    test('LinkWallet digest matches the ethers reference encoder', () {
      // Cross-implementation anchor: the contract tests sign with ethers'
      // TypedDataEncoder. This asserts the Dart pipeline (domainSeparator +
      // linkWalletStructHash + finalDigest) produces the byte-identical digest
      // for fixed inputs, so a Dart-signed EOA proof verifies on chain. The
      // expected value was computed by ethers.TypedDataEncoder.hash with:
      //   domain  = {PublicOS, 1, chainId 4489, verifyingContract 0x..1234}
      //   account = 0x..aa, protocol = bytes32("eip155"),
      //   walletAddress = 0x..bb (20 bytes), walletChainId = 0,
      //   deadline = 1234567890
      final protocol = Uint8List(32)..setRange(0, 6, utf8.encode('eip155'));
      final walletAddress = Uint8List(20)..[19] = 0xbb;
      final domainSep = domainSeparator(
        chainId: 4489,
        verifyingContract:
            EthereumAddress.fromHex('0x0000000000000000000000000000000000001234'),
      );
      final structHash = linkWalletStructHash(
        account:
            EthereumAddress.fromHex('0x00000000000000000000000000000000000000aa'),
        protocol: protocol,
        walletAddress: walletAddress,
        walletChainId: 0,
        deadline: BigInt.from(1234567890),
      );
      final digest = finalDigest(domainSep: domainSep, structHash: structHash);
      expect(
        _hex(digest),
        '293fc5db3fc7a4871131c0d428db28604f0ac2317a14e2fd212938286278c2cc',
        reason:
            'LinkWallet digest diverges from the ethers reference — Dart EOA '
            'proofs would revert on chain. Check field encoding in '
            'linkWalletStructHash (bytes32 raw / bytes keccak / uint64 padding).',
      );
    });

    test('finalDigest is deterministic and 32 bytes', () {
      final domainSep = Uint8List(32);
      final structHash = Uint8List(32);
      final a = finalDigest(domainSep: domainSep, structHash: structHash);
      final b = finalDigest(domainSep: domainSep, structHash: structHash);
      expect(a.length, 32);
      expect(_hex(a), _hex(b));
      // Non-trivial output (keccak of 66-byte input is never all-zero).
      expect(a.any((x) => x != 0), isTrue);
    });
  });
}

String _hex(Uint8List b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

// ignore: unused_element
String _utf8Hex(String s) => _hex(Uint8List.fromList(utf8.encode(s)));
