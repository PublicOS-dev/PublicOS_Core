// S19 — Transactions: value moves between MainSafes and between session keys
// on the local hardhat deploy (native coin, zero-gas chain).
//
//   1. fund jmsl's MainSafe (hardhat_setBalance) and read it back
//   2. jmsl pays a private's MainSafe from the Safe (SafeAuth path)
//   3. a session key pays another key directly (keychain path)
//   4. the receiver's balance moved by exactly the amount

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;

import '../fixtures/test_fixtures.dart';

void main() {
  group('S19 — transactions', () {
    setUpAll(() async {
      await TestFixtures.bootstrap();
    });

    tearDownAll(() async {
      await TestFixtures.teardown();
    });

    test('Safe → Safe and key → key transfers', () async {
      final jmsl = await TestFixtures.setupWithJmsl();
      if (jmsl == null) return;

      final payee = await TestFixtures.ensureAccount('s19-payee');
      final jmslSafeHex = await PublicOSSafe.getMainSafeAddress(jmsl);
      final payeeSafeHex = await PublicOSSafe.getMainSafeAddress(payee);
      expect(jmslSafeHex, isNotNull);
      expect(payeeSafeHex, isNotNull);
      final jmslSafe = EthereumAddress.fromHex(jmslSafeHex!);
      final payeeSafe = EthereumAddress.fromHex(payeeSafeHex!);

      // 1. fund + read
      await TestFixtures.fund(jmslSafe, ether: 100);
      final funded = await PublicOSSafe.getSafeBalance(jmslSafe);
      expect(funded, isNotNull);
      expect(funded!, greaterThanOrEqualTo(100.0));
      final payeeBefore = (await PublicOSSafe.getSafeBalance(payeeSafe)) ?? 0;

      // 2. Safe → Safe (SafeAuth: the session signs, the Safe pays)
      final oneEther = BigInt.from(10).pow(18);
      final tx = await PublicOSSafe.sendTransactionFromSafe(
        accountAddress: jmsl,
        safeAddress: jmslSafe,
        to: payeeSafe.eip55With0x,
        valueWei: oneEther,
      );
      expect(tx, isNotNull, reason: 'sendTransactionFromSafe failed: ${PublicOS.lastError}');
      final mined = await TxUtils.waitForReceipt(tx!, label: 'S19 safe→safe');
      expect(mined, isTrue);
      final payeeAfter = (await PublicOSSafe.getSafeBalance(payeeSafe)) ?? 0;
      expect(payeeAfter - payeeBefore, closeTo(1.0, 1e-6));

      // 3. key → key (keychain path)
      final alice = TestFixtures.actorKey('s19-alice');
      final bob = TestFixtures.actorKey('s19-bob');
      await TestFixtures.fund(alice.address, ether: 5);
      final bobBefore = (await PublicOSBsp.getEthBalance(bob.address.eip55With0x)).getInWei;
      final tx2 = await PublicOSBsp.sendTransactionFromKeychain(
        privateKeyHex: '0x${alice.privateKeyInt.toRadixString(16).padLeft(64, '0')}',
        to: bob.address.eip55With0x,
        valueWei: oneEther * BigInt.two,
      );
      expect(tx2, isNotNull, reason: 'sendTransactionFromKeychain failed: ${PublicOS.lastError}');
      expect(await TxUtils.waitForReceipt(tx2!, label: 'S19 key→key'), isTrue);
      final bobAfter = (await PublicOSBsp.getEthBalance(bob.address.eip55With0x)).getInWei;
      // 4. exact amount (zero-gas chain: no fee leaks)
      expect(bobAfter - bobBefore, equals(oneEther * BigInt.two));
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}
