/// v30 → v31: `channel_signin_prefs.enabled` (bool) becomes a nullable
/// `decision`, and the key becomes the channel BASE url. Rows are KEPT —
/// they are the key icon — and re-keyed in Dart: two old rows for one
/// channel (…/json and …/rss) collapse onto one, accepted winning.
///
/// The fixture is a real v30-shaped file written with raw SQL, then opened
/// through AppDatabase so the migration runs exactly as it will on a device.
library;

import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/src/database/database.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

const _session = '0xEA6ac90E1010FEfB9EDb11E60B750D4A9350d95a';
const _other = '0x0000000000000000000000000000000000000002';
const _base = 'https://feeds.test/api/0xAbC/channels/nuevas';

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('signin_v30_');
    file = File('${dir.path}${Platform.pathSeparator}app.db');
    final raw = sql.sqlite3.open(file.path);
    raw.execute('''
      CREATE TABLE channel_signin_prefs (
        feed_url TEXT NOT NULL,
        client_address TEXT NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 0,
        mode TEXT NOT NULL DEFAULT 'optional',
        discovered_at INTEGER NOT NULL,
        PRIMARY KEY (feed_url, client_address)
      )''');
    final stmt = raw.prepare(
        'INSERT INTO channel_signin_prefs (feed_url, client_address, enabled, mode, discovered_at) VALUES (?, ?, ?, ?, ?)');
    // one channel, two old rows: the /json one opted IN, the /rss one not
    stmt.execute(['$_base/json', _session, 1, 'required', 1000]);
    stmt.execute(['$_base/rss', _session, 0, 'optional', 2000]);
    // a second channel, never opted in
    stmt.execute(['https://feeds.test/api/0xAbC/channels/other/json', _session, 0, 'optional', 3000]);
    // another session on the first channel, never opted in
    stmt.execute(['$_base/json', _other, 0, 'optional', 4000]);
    // a non-channel feed URL that somehow got a row (external server that
    // advertised?) — keyed on itself, kept
    stmt.execute(['https://example.com/feed.xml', _session, 1, 'optional', 5000]);
    stmt.dispose();
    raw.execute('PRAGMA user_version = 30');
    raw.dispose();
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('rows survive, re-keyed and merged; enabled → decision', () async {
    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);

    final rows = await (db.select(db.channelSigninPrefs)
          ..orderBy([(p) => OrderingTerm.asc(p.discoveredAt)]))
        .get();
    // 5 old rows → 4: the two nuevas rows for _session merged into one
    expect(rows.length, 4, reason: rows.map((r) => '${r.feedUrl}|${r.sessionAddress}|${r.decision}').join('\n'));

    final nuevas = rows.singleWhere((r) => r.feedUrl == _base && r.sessionAddress == _session);
    expect(nuevas.decision, 'accepted', reason: 'enabled=1 on either old row wins');
    expect(nuevas.mode, 'required', reason: 'the first-seen (accepted) row\'s mode is kept');

    final other = rows.singleWhere((r) => r.feedUrl.endsWith('/channels/other'));
    expect(other.decision, isNull, reason: 'enabled=0 cannot tell "never asked" from "declined" → ask again');

    final otherSession = rows.singleWhere((r) => r.sessionAddress == _other);
    expect(otherSession.feedUrl, _base);
    expect(otherSession.decision, isNull);

    final external = rows.singleWhere((r) => r.feedUrl == 'https://example.com/feed.xml');
    expect(external.decision, 'accepted', reason: 'non-channel URLs key on themselves and keep their answer');

    // and the schema is really v31: the column exists, the old one is gone
    final cols = await db.customSelect('PRAGMA table_info(channel_signin_prefs)').get();
    final names = cols.map((c) => c.read<String>('name')).toSet();
    expect(names, containsAll(['feed_url', 'session_address', 'decision', 'mode', 'discovered_at']));
    expect(names, isNot(contains('enabled')));
  });
}
