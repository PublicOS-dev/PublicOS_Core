// S1 — Contact CRUD (local DB only).
//
// Validates the basic contact storage layer:
//   - saveContact (insert)
//   - getContact (read by address)
//   - searchContacts (local search by name)
//   - findContactByInboxId (read by registered inbox ID)
//   - dedup on second save (no duplicate row)
//   - removeContact (delete)
//
// This test does NOT need the chain — only the in-memory DB. We still need
// jmsl loaded so `sessionBlockchainAddress` is set (the contacts table is
// scoped per-session). We use the full setup so the test mirrors a real
// session.

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';

import '../fixtures/test_fixtures.dart';

void main() {
  group('S1 — Contact CRUD', () {
    setUpAll(() async {
      await TestFixtures.bootstrap();
    });

    tearDownAll(() async {
      await TestFixtures.teardown();
    });

    test('save → read → update → dedup → delete', () async {
      final jmsl = await TestFixtures.setupWithJmsl();
      if (jmsl == null) return; // skipped — no local node

      // ── Create a fake contact (not on chain) ──────────────────────
      final aliceAddr = EthereumAddress.fromHex(
        '0xCa35b7d915458EF540aDe6068dFe2F44E8fa733c',
      );
      final alice = Contact(
        displayName: 'Alice From Work',
        publicosDisplayName: 'alice',
        publicosAddress: aliceAddr,
        records: [],
        registeredInboxIDs: [
          InboxEntry(
            inboxId:
                'a1b2c3d4e5f6789012345678901234567890123456789012345678901234abcd',
            label: 'main',
          ),
        ],
      );

      await PublicOSContacts.saveContact(alice);

      // ── Read back via getContact ──────────────────────────────────
      final fetched = await PublicOSContacts.getContact(aliceAddr);
      expect(fetched, isNotNull);
      expect(fetched!.displayName, equals('Alice From Work'));
      expect(fetched.publicosDisplayName, equals('alice'));
      expect(fetched.registeredInboxIDs?.length, equals(1));

      // ── Search by display name ────────────────────────────────────
      final searchByName = await PublicOSContacts.searchContacts('Alice From Work');
      expect(searchByName, isNotNull);
      expect(searchByName!.publicosAddress, equals(aliceAddr));

      // ── Search by publicos display name ───────────────────────────
      final searchByPublicosName = await PublicOSContacts.searchContacts('alice');
      expect(searchByPublicosName, isNotNull);
      expect(searchByPublicosName!.publicosAddress, equals(aliceAddr));

      // ── Find by registered inbox ID ───────────────────────────────
      final byInbox = await PublicOSContacts.findContactByInboxId(
        'a1b2c3d4e5f6789012345678901234567890123456789012345678901234abcd',
      );
      expect(byInbox, isNotNull);
      expect(byInbox!.publicosAddress, equals(aliceAddr));
      expect(byInbox.displayName, equals('Alice From Work'));

      // ── Update: same publicosAddress, new displayName → dedups ────
      final aliceRenamed = alice.copyWith(displayName: 'Alice');
      await PublicOSContacts.saveContact(aliceRenamed);

      final stored = await PublicOSContacts.getStoredContacts();
      final aliceMatches = stored
          .where((c) => c.publicosAddress == aliceAddr)
          .toList();
      expect(aliceMatches.length, equals(1),
          reason: 'saveContact should dedup by publicosAddress');
      expect(aliceMatches.first.displayName, equals('Alice'));

      // ── Delete ────────────────────────────────────────────────────
      await PublicOSContacts.removeContact(alice);
      final after = await PublicOSContacts.getContact(aliceAddr);
      expect(after, isNull);

      // jmsl should still be in the DB (we shouldn't have nuked everything)
      final jmslContact = await PublicOSContacts.getContact(jmsl);
      expect(jmslContact, isNotNull);
      expect(jmslContact!.publicosDisplayName, equals('jmsl'));
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
