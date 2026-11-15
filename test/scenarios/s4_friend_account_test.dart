// S4 — Create a friend account on chain.
//
// Flow:
//   1. Load jmsl (gas payer)
//   2. Generate a fresh random friend EOA (no on-chain state yet)
//   3. Confirm getAccountAddressForSession(friendEoa) returns null — not linked
//   4. Call createAccount(timestampedName, friendEoa) signed by jmsl
//   5. Poll getAccountAddressForSession(friendEoa) until an account appears
//   6. Verify the new account: getAccountInfo shows our display name and
//      the friend EOA as the first session
//
// Uniqueness note: display names must be globally unique on chain. We
// timestamp them so re-runs don't collide. Each run leaves a new account
// on the test chain permanently — acceptable for the local dev chain.
//
// This test is the gas-intensive scenario that unlocks S5 (session swap),
// S6/S7/S8 (DM + messages — those need a second account with XMTP), and
// S12 (private account).

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:web3dart/web3dart.dart';

import '../fixtures/test_fixtures.dart';

void main() {
  group('S4 — Friend account creation', () {
    setUpAll(() async {
      await TestFixtures.bootstrap();
    });

    tearDownAll(() async {
      await TestFixtures.teardown();
    });

    test('create a fresh on-chain account for a random EOA', () async {
      final jmsl = await TestFixtures.setupWithJmsl();
      if (jmsl == null) return;

      // ── 1. Generate a fresh friend EOA ────────────────────────────
      final friendEoa = await TestFixtures.generateFriend(label: 's4-friend');
      // ignore: avoid_print
      print('Fresh friend EOA: ${friendEoa.eip55With0x}');

      // ── 2. Confirm the friend is not yet linked to any account ───
      final preAccount =
          await PublicOSAccounts.getAccountAddressForSession(friendEoa);
      expect(preAccount, isNull,
          reason: 'Fresh random EOA should not be linked to any account');

      // ── 3. Create the account on chain ───────────────────────────
      // Timestamp the name so re-runs don't collide with the
      // "display name already taken" check.
      final displayName =
          's4friend_${DateTime.now().millisecondsSinceEpoch}';
      // ignore: avoid_print
      print('Creating account with displayName: $displayName');

      final createOk = await PublicOSAccounts.createAccountWithLocalKey(
        displayName: displayName,
        newSessionKey: TestFixtures.lastFriendKey!,
      );
      expect(createOk, isTrue,
          reason: 'createAccount should return true after on-chain '
              'confirmation. Last error: ${PublicOS.lastError}');

      // ── 4. Confirm the new account is resolvable ────────────────
      // After a successful createAccount, the reverse lookup should
      // return the new address immediately — no polling needed.
      final newAccount =
          await PublicOSAccounts.getAccountAddressForSession(friendEoa);
      expect(newAccount, isNotNull,
          reason: 'createAccount reported success but the new account '
              'is not resolvable via getAccountAddressForSession');
      // ignore: avoid_print
      print('New account: ${newAccount!.eip55With0x}');

      // ── 5. Verify the account metadata on chain ──────────────────
      // Read the fresh account directly from chain. fetchContact hits the
      // chain (not the local DB, which never saw this account) and returns
      // displayName, records, inbox IDs, and org status — but NOT sessions.
      // We already verified session linkage via getAccountAddressForSession
      // in step 4, so that's covered.
      final friendContact =
          await PublicOSContacts.fetchContact(newAccount);
      expect(friendContact.publicosDisplayName, equals(displayName),
          reason: 'On-chain display name should match what we set');
      expect(friendContact.isOrgAccount, isFalse,
          reason: 'Individual account, not an org');
      expect(friendContact.publicosAddress, equals(newAccount),
          reason: 'publicosAddress should echo the lookup address');
      // ignore: avoid_print
      print('New friend account verified: ${newAccount.eip55With0x}');
      // ignore: avoid_print
      print('  displayName: ${friendContact.publicosDisplayName}');
      // ignore: avoid_print
      print('  isOrg: ${friendContact.isOrgAccount}');
      // ignore: avoid_print
      print('  records: ${friendContact.records.length}');
    }, timeout: const Timeout(Duration(seconds: 120)));

    test('createAccount rejects empty username without touching chain',
        () async {
      final jmsl = await TestFixtures.setupWithJmsl();
      if (jmsl == null) return;

      final friendEoa = await TestFixtures.generateFriend(label: 's4-empty');
      PublicOS.lastError = null;

      final ok = await PublicOSAccounts.createAccountWithLocalKey(
        displayName: '', // invalid
        newSessionKey: TestFixtures.lastFriendKey!,
      );
      expect(ok, isFalse,
          reason: 'createAccount should return false for empty username');
      expect(PublicOS.lastError, isNotNull,
          reason: 'lastError should be populated so the UI can surface it');
      // ignore: avoid_print
      print('Empty-username lastError: ${PublicOS.lastError}');
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
