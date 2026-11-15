/// The upgrade ladder must be replay-safe and atomic.
///
/// The case this guards (a v9 install upgrading): `m.createTable` builds
/// a table from its CURRENT definition, so a DB that ran v22 in the same
/// ladder already carried `connected_sites.active_key`, and v30's bare
/// `addColumn` threw "duplicate column name". Drift runs `onUpgrade` with no
/// transaction and stamps `user_version` only on success, so the throw left
/// the file half-migrated at v9 and every later launch failed earlier than
/// the one before. Two fixtures, both real files written with raw SQL and
/// opened through AppDatabase so the ladder runs exactly as on a device:
///
/// 1. v29 with `connected_sites` already in its current shape → opens, lands
///    on the current version.
/// 2. v28 whose ladder MUST throw (no `connected_sites` for v29's DELETE) → the
///    open fails, and the file is untouched: still v28, old tables intact.
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/src/database/database.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

const _session = '0xEA6ac90E1010FEfB9EDb11E60B750D4A9350d95a';

/// `connected_sites` the way v22's `createTable` writes it TODAY: with
/// `active_key` (v30) already there, scope column still pre-v32.
const _connectedSitesCurrentShape = '''
  CREATE TABLE connected_sites (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    origin TEXT NOT NULL,
    client_address TEXT NOT NULL,
    granted_eoa TEXT NOT NULL,
    key_label TEXT NOT NULL,
    granted_at INTEGER NOT NULL,
    last_used_at INTEGER NOT NULL,
    active_key INTEGER NOT NULL DEFAULT 0
  )''';

/// `channel_signin_prefs` in its v30 shape (what v31 expects to read).
const _signinPrefsV30 = '''
  CREATE TABLE channel_signin_prefs (
    feed_url TEXT NOT NULL,
    client_address TEXT NOT NULL,
    enabled INTEGER NOT NULL DEFAULT 0,
    mode TEXT NOT NULL DEFAULT 'optional',
    discovered_at INTEGER NOT NULL,
    PRIMARY KEY (feed_url, client_address)
  )''';

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('ladder_');
    file = File('${dir.path}${Platform.pathSeparator}app.db');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('v30 is replay-safe: active_key already present is skipped', () async {
    final raw = sql.sqlite3.open(file.path);
    raw.execute(_connectedSitesCurrentShape);
    raw.execute(_signinPrefsV30);
    raw.execute(
        "INSERT INTO connected_sites (origin, client_address, granted_eoa, key_label, granted_at, last_used_at, active_key) VALUES ('https://a.test', '$_session', '0x01', 'client', 1, 1, 1)");
    raw.execute('PRAGMA user_version = 29');
    raw.dispose();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);

    final rows = await db.select(db.connectedSites).get();
    expect(rows.length, 1);
    expect(rows.single.activeKey, isTrue, reason: 'the row survived the ladder');
    expect(rows.single.sessionAddress, _session, reason: 'v32 renamed the scope column');
    expect(rows.single.keyLabel, 'session', reason: 'v32 relabelled the key');

    final version = await db
        .customSelect('PRAGMA user_version')
        .getSingle()
        .then((r) => r.read<int>('user_version'));
    expect(version, db.schemaVersion);
  });

  test('a throwing step rolls the whole ladder back: file stays at the old version', () async {
    final raw = sql.sqlite3.open(file.path);
    // v28-shaped bookmarked_posts with a marker column; v29 drops + recreates
    // it, which is the DDL that must NOT survive the later throw.
    raw.execute('''
      CREATE TABLE bookmarked_posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        old_marker TEXT
      )''');
    // No connected_sites: v29's bare `DELETE FROM connected_sites` throws
    // "no such table" right after the recreate above committed its DDL.
    // (A real device always has it from v22; this only forces the throw.)
    raw.execute('PRAGMA user_version = 28');
    raw.dispose();

    final db = AppDatabase(NativeDatabase(file));
    await expectLater(db.customSelect('SELECT 1').get(), throwsA(anything));
    await db.close();

    final check = sql.sqlite3.open(file.path);
    final version = check.select('PRAGMA user_version').first['user_version'];
    expect(version, 28, reason: 'user_version is stamped only after success');
    final cols = check
        .select('PRAGMA table_info(bookmarked_posts)')
        .map((r) => r['name'])
        .toList();
    expect(cols, contains('old_marker'),
        reason: 'v29\'s drop-and-recreate was rolled back with the rest');
    check.dispose();
  });

  test('v33 adds feed_cache.interactions and keeps the cached rows', () async {
    final raw = sql.sqlite3.open(file.path);
    raw.execute(_connectedSitesCurrentShape);
    // feed_cache in its v32 shape: the document, its validators, the verdict.
    raw.execute('''
      CREATE TABLE feed_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        feed_url TEXT NOT NULL,
        session_address TEXT NOT NULL,
        body TEXT NOT NULL,
        content_type TEXT,
        etag TEXT,
        last_modified TEXT,
        fetched_at INTEGER NOT NULL,
        locked INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        UNIQUE (feed_url, session_address)
      )''');
    raw.execute(
        "INSERT INTO feed_cache (feed_url, session_address, body, content_type, etag, fetched_at) VALUES ('https://a.test/feed', '$_session', '{}', 'application/json', '\"e1\"', 1)");
    raw.execute('PRAGMA user_version = 32');
    raw.dispose();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);

    final rows = await db.select(db.feedCache).get();
    expect(rows.length, 1, reason: 'the cached row survived the ladder');
    expect(rows.single.interactions, isNull,
        reason: 'a pre-v33 row has no stored answer yet');
    await db.touchCachedFeed('https://a.test/feed', _session,
        interactions: '{"items":{}}');
    final touched = await db.select(db.feedCache).get();
    expect(touched.single.interactions, '{"items":{}}');
    expect(touched.single.etag, '"e1"', reason: 'a null etag keeps the old one');

    final version = await db
        .customSelect('PRAGMA user_version')
        .getSingle()
        .then((r) => r.read<int>('user_version'));
    expect(version, db.schemaVersion);
  });
}
