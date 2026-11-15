// End-to-end integration: PublicOS_Core ↔ ContactOS_Contracts on a local
// Hardhat node. Walks the 5 client consent signature paths, asserts each
// verifies on-chain (sig produced by Core's helpers, verified by the
// deployed AccountManager).
//
// PREREQUISITE — start the chain + deploy in another shell:
//
//   cd <path to ContactOS_Contracts>
//   npx hardhat node                                # terminal A
//   npx hardhat run scripts/deploy-local.ts --network local    # terminal B
//
// The deploy script writes the fixture this test reads at
// test/fixtures/local_chain.json. Skips gracefully if it isn't present.
//
// Run:
//   cd <path to PublicOS_Core>
//   flutter test test/integration/consent_flow_test.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:publicos_core/src/core/extensions/publicos_accounts.dart';
import 'package:publicos_core/src/core/extensions/publicos_bsp.dart';
import 'package:publicos_core/src/core/extensions/publicos_recovery.dart';
import 'package:publicos_core/src/core/publicos_core.dart';
import 'package:publicos_core/src/utils/consent_uri.dart';
import 'package:publicos_core/src/utils/eip712_consent.dart' as eip712;
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

const _fixturePath = 'test/fixtures/local_chain.json';

void main() {
  late Map<String, dynamic> fixture;
  late EthPrivateKey sponsorKey;
  late EthereumAddress sponsorAccount;

  setUpAll(() async {
    final f = File(_fixturePath);
    if (!f.existsSync()) {
      markTestSkipped(
        'Fixture $_fixturePath not found. Start a local Hardhat node and '
        'run scripts/deploy-local.ts in ContactOS_Contracts before running '
        'this test.',
      );
      fixture = {};
      sponsorKey = EthPrivateKey.fromHex(
        '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
      );
      sponsorAccount = EthereumAddress.fromHex(
        '0x0000000000000000000000000000000000000000',
      );
      return;
    }

    fixture = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    final addresses = fixture['addresses'] as Map<String, dynamic>;
    final sponsor = fixture['sponsor'] as Map<String, dynamic>;

    // Point Core at the local node + override module addresses to match.
    PublicOS.web3Client =
        Web3Client(fixture['rpcUrl'] as String, http.Client());
    PublicOSBsp.accountManagerAddress =
        EthereumAddress.fromHex(addresses['accountManager'] as String);
    PublicOSBsp.accountMemoryAddress =
        EthereumAddress.fromHex(addresses['accountMemory'] as String);
    PublicOSBsp.recoveryModuleAddress =
        EthereumAddress.fromHex(addresses['recoveryModule'] as String);

    sponsorKey = EthPrivateKey.fromHex(sponsor['privateKey'] as String);
    sponsorAccount =
        EthereumAddress.fromHex(sponsor['accountAddress'] as String);

    // Simulate the post-login state Core expects.
    PublicOS.isAuthenticated = true;
    PublicOS.currentBlockchainPrivateKey = sponsorKey;
    PublicOS.myPublicosAddress = sponsorAccount.eip55With0x;
  });

  group('Consent flow · live Hardhat', () {
    test('eth_chainId matches CHAIN_ID', () async {
      if (fixture.isEmpty) return;
      final id = await PublicOS.web3Client.getChainId();
      expect(id.toInt(), PublicOS.CHAIN_ID,
          reason:
              'Hardhat must report PublicOS chainId (4489) for domain separators '
              'to match end-to-end. See ContactOS_Contracts/hardhat.config.ts.');
    });

    // -----------------------------------------------------------------
    //  createAccount — sponsor mints a brand-new account for a fresh key
    // -----------------------------------------------------------------
    test('createAccountWithLocalKey → new account on chain', () async {
      if (fixture.isEmpty) return;
      final spareKeys =
          (fixture['spareKeys'] as List<dynamic>).cast<String>();
      // Use a fresh key per run (consentConsumed is permanent — across runs
      // against the same node the same address can't be re-minted). The
      // test harness restarts the chain fresh each run; pick spareKey[0].
      final newKey = EthPrivateKey.fromHex(spareKeys[0]);
      final newName = _uniqueName('createacct');

      final ok = await PublicOSAccounts.createAccountWithLocalKey(
        displayName: newName,
        newSessionKey: newKey,
      );

      expect(ok, isTrue, reason: 'createAccount tx failed: ${PublicOS.lastError}');

      // The new EOA must be flagged consentConsumed.
      final consumed = await PublicOSBsp.accountMemoryContract
          .consentConsumed((newSession: newKey.address));
      expect(consumed, isTrue);

      // And the new session should resolve to a non-zero account.
      final newAccount = await PublicOSBsp.accountMemoryContract
          .getSessionAccount((sessionAddress: newKey.address));
      expect(newAccount, isNot(EthereumAddress(Uint8List(20))));
    });

    // -----------------------------------------------------------------
    //  addSession — sponsor extends own account with a fresh key
    // -----------------------------------------------------------------
    test('addSessionWithLocalKey → fresh key shows in sessions[]', () async {
      if (fixture.isEmpty) return;
      final spareKeys =
          (fixture['spareKeys'] as List<dynamic>).cast<String>();
      final newKey = EthPrivateKey.fromHex(spareKeys[1]);

      final ok = await PublicOSAccounts.addSessionWithLocalKey(
        newSessionKey: newKey,
      );

      expect(ok, isTrue, reason: 'addSession tx failed: ${PublicOS.lastError}');

      final sessions = await PublicOSAccounts.getMySessions();
      expect(sessions, contains(newKey.address),
          reason: 'New key should appear in sessions[]');
    });

    // NOTE: the linkAddress/unlinkAddress/getOwnedAddresses metadata lane was
    // removed in linked_wallets_module (superseded by the WalletDirectory);
    // its integration test was removed with it.

    // -----------------------------------------------------------------
    //  Cross-device round-trip — new-device encodes URI → sponsor
    //  decodes → submits createAccount with the decoded sig
    // -----------------------------------------------------------------
    test('cross-device new-account URI roundtrip → on chain', () async {
      if (fixture.isEmpty) return;
      final spareKeys =
          (fixture['spareKeys'] as List<dynamic>).cast<String>();

      // ─── New device side: generate key, sign consent, encode URI ────
      // Fresh key not yet consumed in this run (consentConsumed is
      // permanent; earlier session-introducing tests consume [0]+[1]).
      final newKey = EthPrivateKey.fromHex(spareKeys[3]);
      final displayName = 'roundtripacct${DateTime.now().millisecond}';
      final signed = await PublicOSAccounts.signCreateAccountConsent(
        displayName: displayName,
        newSession: newKey.address,
        newSessionKey: newKey,
      );
      final compact = toCompactSig(signed.sig);
      final uri = encodeNewAccountUri(
        newSession: newKey.address,
        deadline: signed.deadline,
        compactSig: compact,
        displayName: displayName,
      );

      // ─── Sponsor side: decode URI, submit ────────────────────────────
      final decoded = decodeConsentUri(uri);
      expect(decoded.kind, ConsentKind.newAccount);
      expect(decoded.displayName, displayName);
      expect(decoded.newSession.eip55With0x, newKey.address.eip55With0x);

      final ok = await PublicOSAccounts.createAccount(
        displayName: decoded.displayName!,
        firstSession: decoded.newSession,
        deadline: decoded.deadline,
        sig: decoded.expandedSig(),
      );
      expect(ok, isTrue,
          reason: 'cross-device createAccount failed: ${PublicOS.lastError}');

      // Chain confirms.
      final consumed = await PublicOSBsp.accountMemoryContract
          .consentConsumed((newSession: newKey.address));
      expect(consumed, isTrue);
    });

    test('cross-device add-session URI roundtrip → on chain', () async {
      if (fixture.isEmpty) return;
      final spareKeys =
          (fixture['spareKeys'] as List<dynamic>).cast<String>();
      final newKey = EthPrivateKey.fromHex(spareKeys[4]);

      // New device side
      final signed = PublicOSAccounts.signAddSessionConsent(
        account: sponsorAccount,
        newSession: newKey.address,
        newSessionKey: newKey,
      );
      final compact = toCompactSig(signed.sig);
      final uri = encodeAddSessionUri(
        newSession: newKey.address,
        deadline: signed.deadline,
        compactSig: compact,
        account: sponsorAccount,
      );

      // Sponsor side
      final decoded = decodeConsentUri(uri);
      expect(decoded.kind, ConsentKind.addSession);
      expect(decoded.account?.eip55With0x, sponsorAccount.eip55With0x);

      final ok = await PublicOSAccounts.addSession(
        newSession: decoded.newSession,
        deadline: decoded.deadline,
        sig: decoded.expandedSig(),
      );
      expect(ok, isTrue,
          reason: 'cross-device addSession failed: ${PublicOS.lastError}');

      final sessions = await PublicOSAccounts.getMySessions();
      expect(sessions, contains(newKey.address));
    });

    // -----------------------------------------------------------------
    //  signReseedConsent — sig is recoverable to the expected signer
    // -----------------------------------------------------------------
    test('signReseedConsent produces a recoverable sig', () async {
      if (fixture.isEmpty) return;
      final spareKeys =
          (fixture['spareKeys'] as List<dynamic>).cast<String>();
      final newSoleKey = EthPrivateKey.fromHex(spareKeys[0]);

      final signed = PublicOSRecovery.signReseedConsent(
        account: sponsorAccount,
        newSoleSession: newSoleKey.address,
        newSoleSessionKey: newSoleKey,
      );

      // Reconstruct the digest the contract would compute, recover the
      // signer, assert it matches newSoleKey.address. Mirrors what
      // SignatureChecker.isValidSignatureNow does on chain.
      final domainSep = eip712.domainSeparator(
        chainId: PublicOS.CHAIN_ID,
        verifyingContract: PublicOSBsp.accountManagerAddress,
      );
      final structHash = eip712.sessionConsentStructHash(
        account: sponsorAccount,
        newSession: newSoleKey.address,
        ttl: BigInt.zero,
        deadline: signed.deadline,
      );
      final digest = eip712.finalDigest(
        domainSep: domainSep,
        structHash: structHash,
      );

      final sig = signed.sig;
      final r = _bytesToBigInt(sig.sublist(0, 32));
      final s = _bytesToBigInt(sig.sublist(32, 64));
      var v = sig[64];
      if (v < 27) v += 27;
      final recoveredPubKey = ecRecover(digest, MsgSignature(r, s, v));
      final recoveredAddr = EthereumAddress(publicKeyToAddress(recoveredPubKey));

      expect(recoveredAddr.eip55With0x, newSoleKey.address.eip55With0x);
    });
  });
}

String _uniqueName(String prefix) {
  // 13+ char target. e.g. 'createacct1715' (14 chars, well above
  // minCharsPrivate floor in any reasonable config).
  final stamp = DateTime.now().millisecondsSinceEpoch.toString();
  return ('$prefix${stamp.substring(stamp.length - 4)}').toLowerCase();
}

BigInt _bytesToBigInt(List<int> b) {
  var out = BigInt.zero;
  for (final byte in b) {
    out = (out << 8) | BigInt.from(byte);
  }
  return out;
}

