// S15 — follows and mutes are PER LIST.
//
// The unified-list model makes an account a MEMBER OF
// A LIST rather than a global subscription. Everything downstream depends on
// that scoping actually holding:
//
//   - the same account followed in two lists is two independent memberships
//   - a mute placed in one list does not silence the channel in the other
//   - unfollowing in one list leaves the other untouched
//   - resolveListItems(list) only ever sees THAT list's accounts + mutes
//
// If this test fails, dropping AggregatorSource.isFollowing (rewire step 4)
// would make every plain list absorb the whole follow graph.
//
// Pre-conditions: local PublicOS chain reachable (same as the other scenarios).

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';

import '../fixtures/test_fixtures.dart';

void main() {
  group('S15 — per-list follows', () {
    setUpAll(() async {
      await TestFixtures.bootstrap();
    });

    tearDownAll(() async {
      await TestFixtures.teardown();
    });

    test('same account in two lists; mute and unfollow stay scoped', () async {
      final jmsl = await TestFixtures.setupWithJmsl();
      if (jmsl == null) return; // skipped — no local node

      final session = PublicOS.sessionBlockchainAddress!;
      final account = jmsl.eip55With0x;

      // The followed account needs at least one channel for the mute half of
      // this test to mean anything (seeded on a fresh local deploy).
      await TestFixtures.ensureChannelRecord(jmsl);
      final channels = await PublicOSFollows.resolveProfileChannels(jmsl);
      expect(channels, isNotEmpty,
          reason: 'jmsl must publish >=1 channel for this scenario');
      final channel = channels.first;

      final listA = await PublicOSFeedLists.createList('News');
      final listB = await PublicOSFeedLists.createList('Friends');
      expect(listA, isNotNull);
      expect(listB, isNotNull);

      // ── Follow the SAME account in both lists → two independent rows.
      await PublicOS.database
          .followAccount(session: session, account: account, listId: listA!.id);
      await PublicOS.database
          .followAccount(session: session, account: account, listId: listB!.id);

      expect(
        (await PublicOS.database
                .listFollowedAccounts(session: session, listId: listA.id))
            .length,
        equals(1),
      );
      expect(
        (await PublicOS.database
                .listFollowedAccounts(session: session, listId: listB.id))
            .length,
        equals(1),
      );
      expect(
        await PublicOS.database.listsContainingAccount(
            session: session, account: account),
        equals({listA.id, listB.id}),
        reason: 'the OQ3 indicator reads membership across all lists',
      );

      // Both lists resolve the account's channels.
      final beforeA = await PublicOSFollows.resolveListItems(listA.id);
      final beforeB = await PublicOSFollows.resolveListItems(listB.id);
      expect(beforeA.map((f) => f.feedUrl), contains(channel.feedUrl));
      expect(beforeB.map((f) => f.feedUrl), contains(channel.feedUrl));

      // ── Mute the channel in A only.
      await PublicOS.database.muteChannel(
        session: session,
        account: account,
        listId: listA.id,
        recordKey: channel.key,
      );

      final afterMuteA = await PublicOSFollows.resolveListItems(listA.id);
      final afterMuteB = await PublicOSFollows.resolveListItems(listB.id);
      expect(afterMuteA.map((f) => f.feedUrl), isNot(contains(channel.feedUrl)),
          reason: 'muted in A → gone from A');
      expect(afterMuteB.map((f) => f.feedUrl), contains(channel.feedUrl),
          reason: 'A mute must NOT leak into B');
      print('mute scoped: A=${afterMuteA.length} B=${afterMuteB.length}');

      // ── Unfollow in A only. B keeps its membership AND its channels.
      await PublicOS.database
          .unfollowAccount(session: session, account: account, listId: listA.id);

      expect(
        (await PublicOS.database
                .listFollowedAccounts(session: session, listId: listA.id)),
        isEmpty,
      );
      expect(
        (await PublicOS.database
                .listFollowedAccounts(session: session, listId: listB.id))
            .length,
        equals(1),
        reason: 'unfollowing in A must not touch B',
      );

      final afterUnfollowB = await PublicOSFollows.resolveListItems(listB.id);
      expect(afterUnfollowB.map((f) => f.feedUrl), contains(channel.feedUrl));

      // The mute cascade is scoped too: A's mute is gone with A's follow, and
      // B never had one.
      expect(
        await PublicOS.database
            .allMutedKeys(session: session, listId: listA.id),
        isEmpty,
        reason: 'unfollow drops that list\'s mutes',
      );
      print('unfollow scoped: B still resolves ${afterUnfollowB.length} feed(s)');

      // ── A list with zero followed accounts reduces to its stored feeds —
      // this is what makes "Following" stop being special.
      final plain = await PublicOSFeedLists.createList('Plain');
      await PublicOSFeedLists.addFeedToList(
          plain!.id, 'https://example.com/feed.xml', 'Example', null);
      final plainItems = await PublicOSFollows.resolveListItems(plain.id);
      expect(plainItems.length, equals(1));
      expect(plainItems.single.origin, equals(FeedOrigin.single));
      print('plain list reduces to stored feeds: ${plainItems.length}');
    });

    test('a channel follow re-resolves by record.key; a raw URL does not',
        () async {
      final jmsl = await TestFixtures.setupWithJmsl();
      if (jmsl == null) return; // skipped — no local node

      await TestFixtures.ensureChannelRecord(jmsl);
      final channels = await PublicOSFollows.resolveProfileChannels(jmsl);
      expect(channels, isNotEmpty);
      final channel = channels.first;
      final owner = jmsl.eip55With0x;

      final list = await PublicOSFeedLists.createList('Tracked');

      // (1) A CHANNEL FOLLOW stored with a DELIBERATELY STALE url. The row
      // says the channel lives somewhere it no longer does — exactly the
      // re-point case. Only the record.key is trustworthy.
      await PublicOSFeedLists.addFeedToList(
        list!.id,
        'https://stale.example.com/old-location.xml',
        'Stale title',
        null,
        feedFoundAtAccountAddress: owner,
        feedRecordKey: channel.key,
      );

      // (2) A RAW URL with no key — a snapshot, must be left alone.
      await PublicOSFeedLists.addFeedToList(
        list.id,
        'https://raw.example.com/feed.xml',
        'Raw',
        null,
      );

      final resolved =
          await PublicOSFollows.resolveListFeeds(
              await PublicOSFeedLists.getFeedsInList(list.id));

      final tracked =
          resolved.where((r) => r.feedRecordKey == channel.key).toList();
      expect(tracked, hasLength(1));
      expect(tracked.single.feedUrl, equals(channel.feedUrl),
          reason: 'the stale stored URL must be replaced by the current one');
      print('re-resolved: stale → ${tracked.single.feedUrl}');

      final raw = resolved
          .where((r) => r.feedUrl == 'https://raw.example.com/feed.xml')
          .toList();
      expect(raw, hasLength(1),
          reason: 'a keyless row is a snapshot and must survive verbatim');
      print('raw URL untouched: ${raw.single.feedUrl}');

      // (3) A channel follow whose key the owner no longer publishes is
      // DROPPED — the author deleted it. Honest only because the read
      // underneath throws on failure instead of returning [].
      await PublicOSFeedLists.addFeedToList(
        list.id,
        'https://gone.example.com/feed.xml',
        'Gone',
        null,
        feedFoundAtAccountAddress: owner,
        feedRecordKey: 'a-key-this-owner-does-not-publish',
      );
      final afterGone = await PublicOSFollows.resolveListFeeds(
          await PublicOSFeedLists.getFeedsInList(list.id));
      expect(
        afterGone.where((r) => r.feedUrl == 'https://gone.example.com/feed.xml'),
        isEmpty,
        reason: 'a deleted channel resolves to nothing and is dropped',
      );
      print('deleted channel dropped; ${afterGone.length} row(s) remain');

      // (4) ...but the DETAILED resolve hands it back as gone, as stored, so a
      // single follow can render "Channel not found".
      final detailed = await PublicOSFollows.resolveListFeedsDetailed(
          await PublicOSFeedLists.getFeedsInList(list.id));
      expect(detailed.live.length, equals(afterGone.length));
      expect(
        detailed.gone.map((r) => r.feedUrl),
        equals(['https://gone.example.com/feed.xml']),
        reason: 'the deleted channel is reported, not silently lost',
      );
      print('gone reported: ${detailed.gone.single.feedUrl}');
    });

    test('deleting a list cascades its follows and mutes away', () async {
      final jmsl = await TestFixtures.setupWithJmsl();
      if (jmsl == null) return; // skipped — no local node

      final session = PublicOS.sessionBlockchainAddress!;
      final account = jmsl.eip55With0x;
      await TestFixtures.ensureChannelRecord(jmsl);
      final channels = await PublicOSFollows.resolveProfileChannels(jmsl);
      expect(channels, isNotEmpty);

      final doomed = await PublicOSFeedLists.createList('Doomed');
      final keeper = await PublicOSFeedLists.createList('Keeper');
      for (final l in [doomed!, keeper!]) {
        await PublicOS.database
            .followAccount(session: session, account: account, listId: l.id);
        await PublicOS.database.muteChannel(
          session: session,
          account: account,
          listId: l.id,
          recordKey: channels.first.key,
        );
      }

      await PublicOSFeedLists.deleteList(doomed.id);

      // The FK cascade must take the follow AND the mute with the list — an
      // account is a MEMBER of a list, so it cannot outlive it. A stranded
      // row would resurrect as a phantom follow if the id were ever reused.
      expect(
        await PublicOS.database
            .listFollowedAccounts(session: session, listId: doomed.id),
        isEmpty,
        reason: 'follows must cascade with the deleted list',
      );
      expect(
        await PublicOS.database
            .allMutedKeys(session: session, listId: doomed.id),
        isEmpty,
        reason: 'mutes must cascade with the deleted list',
      );

      // ...and the OTHER list is untouched.
      expect(
        (await PublicOS.database
                .listFollowedAccounts(session: session, listId: keeper.id))
            .length,
        equals(1),
        reason: 'deleting one list must not touch another',
      );
      expect(
        await PublicOS.database.listsContainingAccount(
            session: session, account: account),
        equals({keeper.id}),
        reason: 'the profile indicator must drop the deleted list',
      );
      print('cascade ok: doomed cleared, keeper intact');
    });

    test('the FK is real: a follow cannot point at a nonexistent list',
        () async {
      // Guards the customConstraint workaround. `.references(FeedLists, #id)`
      // — the canonical form — is silently DROPPED by drift_dev <=2.32.0 under
      // analyzer >=10.2.0 (it warns "should be a simple class name" and emits
      // no REFERENCES clause). We use customConstraint instead. If someone
      // "tidies" that back to .references(), the constraint vanishes with only
      // a build warning and this test is what catches it.
      final jmsl = await TestFixtures.setupWithJmsl();
      if (jmsl == null) return; // skipped — no local node

      final session = PublicOS.sessionBlockchainAddress!;
      await expectLater(
        PublicOS.database.followAccount(
          session: session,
          account: jmsl.eip55With0x,
          listId: 999999, // no such list
        ),
        throwsA(anything),
        reason: 'FK must reject a follow pointing at a nonexistent list',
      );
      print('FK enforced: orphan follow rejected');
    });
  });
}
