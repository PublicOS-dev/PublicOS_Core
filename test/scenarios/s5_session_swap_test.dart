// S5 — Session swap via pending-session activation.
//
// End-to-end flow for "I created a friend account, now I'm the friend":
//   1. Load jmsl (gas payer + initial session)
//   2. Generate a friend EOA (stores keys under `temporaryAccount*`)
//   3. jmsl.createAccount(name, friendEoa) — chain write
//   4. Poll for activation
//   5. checkAndActivatePendingTemporarySession()
//       → reads temporaryAccountSessionAddress
//       → detects on-chain account
//       → _transferTemporarySessionTo renames storage keys
//       → returns address (NO session load — that's step 6's job)
//   6. restoreSession(newAccount) → initBSP() swaps globals
//   7. Verify PublicOS.myPublicosAddress is now the friend's account, not jmsl
//
// This is the canonical "activate a newly created account" path that the
// client apps use after createAccount succeeds. Note that activation and
// session swap are now two explicit steps — checkAndActivate is a pure
// "am I linked?" check with no session side effects.

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:web3dart/web3dart.dart';

import '../fixtures/test_fixtures.dart';

void main() {
  group('S5 — Session swap', () {
    setUpAll(() async {
      await TestFixtures.bootstrap();
    });

    tearDownAll(() async {
      await TestFixtures.teardown();
    });

    test('activate friend + swap session away from jmsl', () async {
      final jmsl = await TestFixtures.setupWithJmsl();
      if (jmsl == null) return;

      // Sanity: we start as jmsl
      expect(PublicOS.myPublicosAddress, equals(jmsl.eip55With0x),
          reason: 'Initial session should be jmsl');

      // ── Create friend + on-chain account ─────────────────────────
      final friendEoa = await TestFixtures.generateFriend(label: 's5-friend');
      // ignore: avoid_print
      print('Friend EOA: ${friendEoa.eip55With0x}');

      final displayName =
          's5friend_${DateTime.now().millisecondsSinceEpoch}';
      final createOk = await PublicOSAccounts.createAccountWithLocalKey(
        displayName: displayName,
        newSessionKey: TestFixtures.lastFriendKey!,
      );
      expect(createOk, isTrue,
          reason: 'createAccount should confirm on-chain. '
              'Last error: ${PublicOS.lastError}');

      // createAccount already waited for the receipt — the reverse lookup
      // should resolve immediately.
      final newFriendAccount =
          await PublicOSAccounts.getAccountAddressForSession(friendEoa);
      expect(newFriendAccount, isNotNull,
          reason: 'friend account should be resolvable after createAccount');
      // ignore: avoid_print
      print('Friend account: ${newFriendAccount!.eip55With0x}');

      // ── Run the activation check ─────────────────────────────────
      // checkAndActivatePendingTemporarySession is a pure "am I linked?"
      // check now — it promotes the temp keys into account-scoped
      // storage and returns the address, but does NOT load any session.
      final activated =
          await PublicOSAccounts.checkAndActivatePendingTemporarySession();
      expect(activated, isNotNull,
          reason: 'activation should detect the newly minted account');
      expect(
        activated!.toLowerCase(),
        equals(newFriendAccount.eip55With0x.toLowerCase()),
        reason: 'activation should return the friend account address',
      );

      // ── Explicit session swap ────────────────────────────────────
      // Before: activation internally called restoreSession. Now the
      // caller drives the two-step swap explicitly. This is the flow
      // consumer apps use after createAccount when they want to become
      // the newly minted account.
      final restored =
          await PublicOSAccounts.restoreSession(newFriendAccount);
      expect(restored, isTrue,
          reason: 'restoreSession should succeed for the friend account');
      final bspOk = await PublicOS.initBSP();
      expect(bspOk, isTrue, reason: 'initBSP should succeed after session swap');

      // ── The session must now be the friend, not jmsl ─────────────
      expect(PublicOS.myPublicosAddress,
          equals(newFriendAccount.eip55With0x),
          reason: 'myPublicosAddress should have flipped to the friend');
      expect(PublicOS.sessionBlockchainAddress, equals(friendEoa.eip55With0x),
          reason: 'session address should now be the friend EOA');
      // ignore: avoid_print
      print('Session swapped. myPublicosAddress=${PublicOS.myPublicosAddress}');
      // ignore: avoid_print
      print('sessionBlockchainAddress=${PublicOS.sessionBlockchainAddress}');

      // ── The friend contact should be saved in the DB post-restore ──
      final friendContact =
          await PublicOSContacts.getContact(newFriendAccount);
      expect(friendContact, isNotNull,
          reason: 'restoreSession should have saved the friend to the DB');
      expect(friendContact!.publicosDisplayName, equals(displayName));
      // ignore: avoid_print
      print('initBSP swung RPC to: ${PublicOS.activeRpcUrl} (${PublicOS.activeRpcSource})');
      // ignore: avoid_print
      print('Friend contact stored with displayName=${friendContact.publicosDisplayName}');
    }, timeout: const Timeout(Duration(seconds: 120)));
  });
}
