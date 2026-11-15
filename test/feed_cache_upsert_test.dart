/// Regression: the FeedCache upsert must survive the SECOND write.
///
/// `FeedCache` carries an autoIncrement `id` AND a `{feedUrl, sessionAddress}`
/// unique key. Drift's `insertOnConflictUpdate` targets the PRIMARY KEY, which
/// an auto-assigned `id` can never collide on — so the `DO UPDATE` branch was
/// unreachable and every write after the first raised
/// `SqliteException(2067): UNIQUE constraint failed`.
///
/// The blast radius was not "the cache is cold". `refreshPostsForFeeds` treated
/// the throw as a FETCH failure and served the STALE cached body instead of the
/// fresh one it was already holding — so a post's reactions, score, and comment
/// count froze at whatever the first successful write captured. A reaction would
/// POST fine, render optimistically, and vanish on reload.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/src/database/database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  const url = 'https://feeds.publicos.dev/api/0xAbC/channels/nuevas/json';
  const session = '0xEA6ac90E1010FEfB9EDb11E60B750D4A9350d95a';

  FeedCacheCompanion row(String body, {String? etag}) =>
      FeedCacheCompanion.insert(
        feedUrl: url,
        sessionAddress: session,
        body: body,
        etag: Value(etag),
        fetchedAt: DateTime.now().millisecondsSinceEpoch,
      );

  test('a second write to the same (feedUrl, sessionAddress) UPDATES, not throws',
      () async {
    await db.upsertCachedFeed(row('{"items":[]}', etag: '"v1"'));

    // This is the call that used to raise 2067.
    await db.upsertCachedFeed(row('{"items":[{"reactions":1}]}', etag: '"v2"'));

    final rows = await db.getCachedFeeds([url], session);
    expect(rows, hasLength(1), reason: 'must upsert in place, not duplicate');
    expect(rows.single.body, '{"items":[{"reactions":1}]}',
        reason: 'the FRESH body must win — this is the reaction bug');
    expect(rows.single.etag, '"v2"');
  });

  test('rows stay scoped per session', () async {
    await db.upsertCachedFeed(row('a'));
    await db.upsertCachedFeed(FeedCacheCompanion.insert(
      feedUrl: url,
      sessionAddress: '0xOtherClient',
      body: 'b',
      fetchedAt: DateTime.now().millisecondsSinceEpoch,
    ));

    expect(await db.getCachedFeeds([url], session), hasLength(1));
    expect((await db.getCachedFeeds([url], '0xOtherClient')).single.body, 'b');
  });
}
