// S16 — Sessions (keys): the account's key surface
// (a key is a SESSION; permanent vs expiring keys).
//
// Local hardhat deploy of the current source. Serial: `flutter test test/scenarios --concurrency=1`.
//
//   1. jmsl adds a PERMANENT second session (own-consent, ttl 0)
//   2. jmsl adds an EXPIRING session (ttl 1 day) — both show in getMySessions
//   3. the second device (the permanent key) ACTS for jmsl: writes a record
//   4. the expiring key is removed; the permanent one stays
//   5. the last permanent session cannot be removed (floor = one permanent key)

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;

import '../fixtures/test_fixtures.dart';

void main() {
  group('S16 — sessions', () {
    setUpAll(() async {
      await TestFixtures.bootstrap();
    });

    tearDownAll(() async {
      await TestFixtures.teardown();
    });

    test('permanent + expiring second sessions; a second device acts; remove; floor', () async {
      final jmsl = await TestFixtures.setupWithJmsl();
      if (jmsl == null) return;
      final before = await PublicOSAccounts.getMySessions();
      expect(before, isNotEmpty);
      // Fresh keys every run: AccountMemory.consentConsumed is permanent, so a
      // key that was added once (even if removed) can never be added again.
      final run = await PublicOS.web3Client.getBlockNumber();

      // 1. permanent second session
      final device2 = TestFixtures.actorKey('s16-device2-$run');
      final okPerm = await PublicOSAccounts.addSessionWithLocalKey(newSessionKey: device2);
      expect(okPerm, isTrue, reason: 'addSession (permanent) failed: ${PublicOS.lastError}');

      // 2. expiring second session (ttl 1 day)
      final tempKey = TestFixtures.actorKey('s16-temp-$run');
      final okTtl = await PublicOSAccounts.addSessionWithLocalKey(
        newSessionKey: tempKey,
        ttl: BigInt.from(const Duration(days: 1).inSeconds),
      );
      expect(okTtl, isTrue, reason: 'addSession (ttl) failed: ${PublicOS.lastError}');

      final now = await PublicOSAccounts.getMySessions();
      final nowHex = now.map((a) => a.eip55With0x).toSet();
      expect(nowHex, contains(device2.address.eip55With0x));
      expect(nowHex, contains(tempKey.address.eip55With0x));
      expect(now.length, before.length + 2);

      // Both keys resolve to jmsl's account.
      expect(await PublicOSAccounts.getAccountAddressForSession(device2.address), equals(jmsl));
      expect(await PublicOSAccounts.getAccountAddressForSession(tempKey.address), equals(jmsl));

      // 3. the second device acts for jmsl: a profile record written by device2
      await TestFixtures.actAs(jmsl, device2, displayName: 'jmsl');
      expect(PublicOS.sessionBlockchainAddress, equals(device2.address.eip55With0x));
      final wrote = await PublicOSContacts.setRecord(Record.asProfile(
        key: 'profile.bio',
        value: 'written by device 2 (session ${device2.address.eip55With0x.substring(0, 8)})',
        expiration: DateTime.now().add(const Duration(days: 365)),
      ));
      expect(wrote, isTrue, reason: 'device2 setRecord failed: ${PublicOS.lastError}');
      final records = await PublicOSContacts.getAllUserRecordsOrThrow(jmsl);
      expect(records.any((r) => r.key == 'profile.bio' && r.value.contains('device 2')), isTrue);

      // 4. back on the first key: remove the expiring session
      await TestFixtures.actAsJmsl();
      final removed = await PublicOSAccounts.removeSession(tempKey.address);
      expect(removed, isTrue, reason: 'removeSession(ttl key) failed: ${PublicOS.lastError}');
      final after = await PublicOSAccounts.getMySessions();
      expect(after.map((a) => a.eip55With0x), isNot(contains(tempKey.address.eip55With0x)));
      expect(after.map((a) => a.eip55With0x), contains(device2.address.eip55With0x));

      // 5. the floor: remove device2 (ok), then the last permanent key (refused)
      expect(await PublicOSAccounts.removeSession(device2.address), isTrue);
      final onlyOne = await PublicOSAccounts.getMySessions();
      final permanentLeft = onlyOne.where((a) => a != tempKey.address).toList();
      if (permanentLeft.length == 1) {
        final refused = await PublicOSAccounts.removeSession(permanentLeft.single);
        expect(refused, isFalse, reason: 'the last permanent session must not be removable');
        expect(PublicOS.lastError, isNotNull);
      }
      expect(await PublicOSAccounts.getAccountAddressForSession(TestFixtures.jmslSessionAddress!), equals(jmsl));
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}
