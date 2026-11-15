/// `RssParser.fetchFeed` under the per-channel sign-in:
/// no session cache, no silent signed
/// retry, the 401 challenge is a SIGNAL that seeds the row and surfaces typed,
/// and every 403 carries the channel object. And under the PublicOS Feed:
/// a channel URL is read as its document at `/feed`,
/// then the page's interactions call fills the counts.
///
/// Only the plain path is exercised here (the injectable client covers it);
/// the signed path goes through `PublicOSSsp` and is covered by the Go tests
/// and the device script.
library;

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_core/src/core/extensions/publicos_channel_signin.dart';
import 'package:web3dart/web3dart.dart';

const _session = '0xEA6ac90E1010FEfB9EDb11E60B750D4A9350d95a';
const _owner = '0xabcabcabcabcabcabcabcabcabcabcabcabcabca';
const _base = 'https://feeds.test/api/$_owner/channels/nuevas';
const _feed = '$_base/json';
const _post = '3d5e51cb-d673-4f24-9856-844d427f016e';

const _emptyFeed =
    '{"version":"https://jsonfeed.org/version/1.1","title":"nuevas","items":[]}';

String _v1Document({bool private = false}) => jsonEncode({
      'version': 'https://publicos.dev/feed/1',
      'channel': {
        'owner': _owner,
        'slug': 'nuevas',
        'title': 'nuevas',
        'description': 'd',
        'language': 'es',
        'icon': 'https://feeds.test/i.png',
        'feed_url': '$_base/feed',
        'posting': 'open',
        'tags': ['pueblo'],
        'access': {
          'private': private,
          'read_identity': 'anyone',
          'posting_identity': 'account',
          'comment_identity': 'standing',
          'reaction_identity': 'standing',
          'quotes': 'open',
          'reposts': 'open',
          'replies': 'open',
        },
      },
      'items': [
        {
          'id': _post,
          'url': '$_base/posts/$_post',
          'author': 'Ana',
          'date_published': '2026-10-26T16:02:11Z',
          'date_received': '2026-10-26T16:02:13Z',
          'text': 'Primer post',
          'hero_media': [
            {'url': 'https://feeds.test/m/a.jpg', 'mime_type': 'image/jpeg', 'width': 10, 'height': 20},
          ],
          'interactions_url': '$_base/posts/$_post/interactions',
          'comments_url': '$_base/posts/$_post/comments',
        },
      ],
      'interactions_url': '$_base/feed/interactions?offset=0',
      'next_url': '$_base/feed?offset=1',
      'total': 2,
    });

String _interactions() => jsonEncode({
      'items': {
        _post: {
          'counts': {'comments': 4, 'score': 7, 'upvotes': 8, 'downvotes': 1, 'reactions': {'🔥': 3}},
          'viewer': {'vote': 1, 'reactions': ['🔥']},
          'can_comment': true,
          'can_react': false,
        },
      },
      'channel': {
        'stats': {
          'verified_citizen_views': 42,
          'total_views': 100,
          'by_type': {'citizen': 42, 'anonymous': 58},
          'daily': [1, 2, 3, 4, 5, 6, 7],
          'today': 2,
          'week': '2026-W43',
        },
        'access': {'follow_status': 'approved'},
        'can_post': true,
      },
    });

void main() {
  late AppDatabase db;
  late List<http.Request> seen;

  void mock(http.Response Function(http.Request) handler) {
    RssParser.httpClient = MockClient((req) async {
      seen.add(req);
      return handler(req);
    });
  }

  void withKey(bool on) {
    PublicOS.currentBlockchainPrivateKey =
        on ? EthPrivateKey.fromHex('0x${'11' * 32}') : null;
    PublicOS.myPublicosAddress = on ? _session : null;
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    PublicOS.database = db;
    PublicOS.isAuthenticated = true;
    PublicOS.sessionBlockchainAddress = _session;
    withKey(true);
    seen = [];
  });
  tearDown(() async {
    RssParser.httpClient = null;
    PublicOS.isAuthenticated = false;
    PublicOS.sessionBlockchainAddress = null;
    withKey(false);
    await db.close();
  });

  http.Response challenge() => http.Response(
        '{"error":{"code":"ENVELOPE_MISSING","message":"sign"}}',
        401,
        headers: {
          'www-authenticate': 'PublicOS-Envelope action="read_feed"',
          'content-type': 'application/json',
        },
      );

  http.Response document(http.Request req, {Map<String, String> headers = const {}}) {
    if (req.url.path.endsWith('/feed/interactions')) {
      return http.Response(_interactions(), 200,
          headers: {'content-type': 'application/json'});
    }
    return http.Response(_v1Document(), 200, headers: {
      'content-type': 'application/publicos-feed+json; charset=utf-8',
      ...headers,
    });
  }

  test('401 with a key: exactly ONE request, the row is seeded required, typed FeedSigninRequired', () async {
    mock((_) => challenge());
    await expectLater(RssParser.fetchFeed(_feed), throwsA(isA<FeedSigninRequired>()));
    expect(seen.length, 1, reason: 'the silent signed retry is gone');
    final row = await PublicOSChannelSignin.getPref(_feed);
    expect(row, isNotNull);
    expect(row!.mode, 'required');
    expect(row.decision, isNull);
  });

  test('401 without a key: one request, NO row, the plain string error keeps today\'s gate', () async {
    withKey(false);
    mock((_) => challenge());
    await expectLater(
      RssParser.fetchFeed(_feed),
      throwsA(predicate((e) => e is! FeedSigninRequired && e.toString().contains('FEED_ERROR:ENVELOPE_MISSING'))),
    );
    expect(seen.length, 1);
    expect(await PublicOSChannelSignin.getPref(_feed), isNull);
  });

  test('a denied channel is fetched plain and the 401 still surfaces typed (the client locks)', () async {
    await PublicOSChannelSignin.recordSignal(_feed, 'required');
    await PublicOSChannelSignin.setDecision(_feed, 'denied');
    mock((_) => challenge());
    await expectLater(RssParser.fetchFeed(_feed), throwsA(isA<FeedSigninRequired>()));
    expect(seen.length, 1);
    expect(seen.single.body, isEmpty, reason: 'plain GET — no envelope for a denied channel');
    expect((await PublicOSChannelSignin.getPref(_feed))!.decision, 'denied', reason: 'a fetch never touches the answer');
  });

  test('200 + PublicOS-Envelope: optional seeds the row {optional, null} and parses', () async {
    mock((_) => http.Response(_emptyFeed, 200, headers: {
          'content-type': 'application/feed+json',
          'publicos-envelope': 'optional; action="read_feed"',
        }));
    final parsed = await RssParser.fetchFeed(_feed);
    expect(parsed.title, 'nuevas');
    final row = await PublicOSChannelSignin.getPref(_feed);
    expect(row!.mode, 'optional');
    expect(row.decision, isNull);
  });

  test('200 with NO header on a channel URL deletes the row', () async {
    await PublicOSChannelSignin.recordSignal(_feed, 'optional');
    await PublicOSChannelSignin.setDecision(_feed, 'accepted');
    // accepted → the signed path would run first; with no server it fails
    // and falls back to plain, which we mock. Flip to null so the fetch is
    // plain from the start and the assertion is about the signal only.
    await PublicOSChannelSignin.setDecision(_feed, null);
    mock((_) => http.Response(_emptyFeed, 200, headers: {'content-type': 'application/feed+json'}));
    await RssParser.fetchFeed(_feed);
    expect(await PublicOSChannelSignin.getPref(_feed), isNull);
  });

  test('304 with NO header keeps the row (a stripping proxy must not delete it)', () async {
    await PublicOSChannelSignin.recordSignal(_feed, 'optional');
    mock((req) => req.url.path.endsWith('/feed/interactions')
        ? http.Response(_interactions(), 200, headers: {'content-type': 'application/json'})
        : http.Response('', 304, headers: {'etag': '"v1"'}));
    final parsed = await RssParser.fetchFeed(_feed, etag: '"v1"');
    expect(parsed.notModified, isTrue);
    expect(await PublicOSChannelSignin.getPref(_feed), isNotNull);
  });

  test('200 on an external RSS URL writes nothing', () async {
    mock((_) => http.Response(_emptyFeed, 200, headers: {'content-type': 'application/feed+json'}));
    await RssParser.fetchFeed('https://example.com/feed.json');
    expect(await PublicOSChannelSignin.getPref('https://example.com/feed.json'), isNull);
  });

  test('403 PRIVATE_FEED_NOT_APPROVED carries error.channel → FeedGateException with follow_status', () async {
    mock((_) => http.Response(
          jsonEncode({
            'error': {
              'code': 'PRIVATE_FEED_NOT_APPROVED',
              'message': 'nope',
              'channel': {
                'id': 1, 'account_id': 1, 'name': 'nuevas', 'description': '', 'slug': 'nuevas',
                'is_private': true, 'is_paid': true, 'follow_status': 'pending',
                'created_at': '', 'updated_at': '',
              },
            }
          }),
          403,
          headers: {'content-type': 'application/json'},
        ));
    await expectLater(
      RssParser.fetchFeed(_feed),
      throwsA(isA<FeedGateException>()
          .having((e) => e.code, 'code', 'PRIVATE_FEED_NOT_APPROVED')
          .having((e) => e.toString(), 'string protocol', 'FEED_ERROR:PRIVATE_FEED_NOT_APPROVED')
          .having((e) => e.channel?.followStatus, 'follow_status', 'pending')
          .having((e) => e.channel?.isPaid, 'is_paid', isTrue)
          .having((e) => e.channel?.serverAddress, 'server', 'https://feeds.test')),
    );
  });

  test('403 PAYWALL_DENIED is still a PaywallException, now with the object', () async {
    mock((_) => http.Response(
          jsonEncode({
            'error': {
              'code': 'PAYWALL_DENIED',
              'message': 'pay',
              'entries': [{'chain_id': 4489, 'feed_id': 7, 'contract': '0xFeed', 'chain_name': 'PublicOS'}],
              'lapsed_at': 1700000000,
              'channel': {
                'id': 1, 'account_id': 1, 'name': 'nuevas', 'description': '', 'slug': 'nuevas',
                'is_private': false, 'is_paid': true, 'created_at': '', 'updated_at': '',
              },
            }
          }),
          403,
          headers: {'content-type': 'application/json'},
        ));
    await expectLater(
      RssParser.fetchFeed(_feed),
      throwsA(isA<PaywallException>()
          .having((e) => e.entries.length, 'entries', 1)
          .having((e) => e.hasLapsed, 'lapsed', isTrue)
          .having((e) => e.channel?.isPaid, 'channel.is_paid', isTrue)
          .having((e) => e, 'is a gate exception', isA<FeedGateException>())),
    );
  });

  test('403 without a channel object (old server) → FeedGateException with channel null', () async {
    mock((_) => http.Response('{"error":{"code":"VERIFIED_ONLY","message":"citizens"}}', 403,
        headers: {'content-type': 'application/json'}));
    await expectLater(
      RssParser.fetchFeed(_feed),
      throwsA(isA<FeedGateException>().having((e) => e.channel, 'channel', isNull)),
    );
  });

  // A 404 is GONE, typed — never a blip.
  test('404 with the bare-string body (today\'s feed handlers) → FeedGoneException CHANNEL_NOT_FOUND', () async {
    mock((_) => http.Response('{"error":"channel not found"}', 404,
        headers: {'content-type': 'application/json'}));
    await expectLater(
      RssParser.fetchFeed(_feed),
      throwsA(isA<FeedGoneException>().having((e) => e.code, 'code', 'CHANNEL_NOT_FOUND')),
    );
  });

  test('404 with a typed body → FeedGoneException carrying the server code', () async {
    mock((_) => http.Response('{"error":{"code":"ACCOUNT_NOT_FOUND","message":"x"}}', 404,
        headers: {'content-type': 'application/json'}));
    await expectLater(
      RssParser.fetchFeed(_feed),
      throwsA(isA<FeedGoneException>().having((e) => e.code, 'code', 'ACCOUNT_NOT_FOUND')),
    );
  });

  test('404 with no JSON body (external RSS) → FeedGoneException HTTP_404', () async {
    mock((_) => http.Response('<html>Not Found</html>', 404));
    await expectLater(
      RssParser.fetchFeed('https://raw.example.com/feed.xml'),
      throwsA(isA<FeedGoneException>().having((e) => e.code, 'code', 'HTTP_404')),
    );
  });

  test('500 stays a plain (transient) error, not gone', () async {
    mock((_) => http.Response('{"error":"boom"}', 500));
    await expectLater(
      RssParser.fetchFeed(_feed),
      throwsA(predicate((e) => e is! FeedGoneException && e.toString().contains('FEED_ERROR:HTTP_500'))),
    );
  });

  group('the PublicOS Feed document', () {
    test('a channel URL is asked for /feed; the stored URL stays as given', () async {
      mock(document);
      final parsed = await RssParser.fetchFeed(_feed);
      expect(seen.first.url.toString(), '$_base/feed');
      expect(parsed.isFeedV1, isTrue);
      expect(parsed.link, _feed);
      expect(parsed.posts.single.feedUrl, _feed);
    });

    test('the query the stored URL carried rides on the document request', () async {
      mock(document);
      await RssParser.fetchFeed('$_base/rss?sort=top&limit=5');
      expect(seen.first.url.toString(), '$_base/feed?sort=top&limit=5');
    });

    test('channel → ParsedFeed: title, posting, access, tags, next page, total', () async {
      mock(document);
      final parsed = await RssParser.fetchFeed(_feed);
      expect(parsed.title, 'nuevas');
      expect(parsed.description, 'd');
      expect(parsed.language, 'es');
      expect(parsed.imageUrl, 'https://feeds.test/i.png');
      expect(parsed.postingPolicy, 'open');
      expect(parsed.isPrivate, isFalse);
      expect(parsed.sensitive, isFalse);
      expect(parsed.tags, ['pueblo']);
      expect(parsed.hasMore, isTrue);
      expect(parsed.nextUrl, '$_base/feed?offset=1');
      expect(parsed.total, 2);
      expect(parsed.channel, isNotNull);
      expect(parsed.channel!.slug, 'nuevas');
      expect(parsed.channel!.ownerAddress, _owner);
      expect(parsed.channel!.isPrivate, isFalse);
      expect(parsed.channel!.readTier, 'anyone');
      expect(parsed.channel!.commentTier, 'standing');
      expect(parsed.channel!.serverAddress, 'https://feeds.test');
    });

    test('items → Post: the v1 keys, the hero, forum flag, channel coordinates', () async {
      mock(document);
      final p = (await RssParser.fetchFeed(_feed)).posts.single;
      expect(p.uid, _post);
      expect(p.contentText, 'Primer post');
      expect(p.authorName, 'Ana');
      expect(p.postAuthorAddress, isNull);
      expect(p.createdAt, DateTime.parse('2026-10-26T16:02:11Z'));
      expect(p.dateReceived, DateTime.parse('2026-10-26T16:02:13Z'));
      expect(p.bannerImage, 'https://feeds.test/m/a.jpg');
      expect(p.heroMedia.single.width, 10);
      expect(p.isForumChannel, isTrue);
      expect(p.channelOwnerAddress, _owner);
      expect(p.channelSlug, 'nuevas');
      expect(p.serverAddress, 'https://feeds.test');
      expect(p.commentsUrl, '$_base/posts/$_post/comments');
      expect(p.interactionsUrl, '$_base/posts/$_post/interactions');
      expect(p.url, '$_base/posts/$_post');
    });

    test('the interactions call follows the document and is merged by id', () async {
      mock(document);
      final parsed = await RssParser.fetchFeed(_feed);
      expect(seen.map((r) => r.url.toString()),
          ['$_base/feed', '$_base/feed/interactions?offset=0']);
      final p = parsed.posts.single;
      expect(p.score, 7);
      expect(p.upvotes, 8);
      expect(p.downvotes, 1);
      expect(p.commentsCount, 4);
      expect(p.reactions, '🔥:3');
      expect(p.userVote, 1);
      expect(p.viewerReactions, ['🔥']);
      expect(p.canCommentAnswer, isTrue);
      expect(p.canReactAnswer, isFalse);
      expect(parsed.stats?.verifiedCitizenViews, 42);
      expect(parsed.canPost, isTrue);
      expect(parsed.channel!.followStatus, 'approved');
      expect(parsed.interactions, isNotNull);
    });

    test('a failed interactions call leaves the counts absent, not zero', () async {
      mock((req) => req.url.path.endsWith('/feed/interactions')
          ? http.Response('{"error":"boom"}', 500)
          : document(req));
      final parsed = await RssParser.fetchFeed(_feed);
      final p = parsed.posts.single;
      expect(p.commentsCount, isNull);
      expect(p.userVote, isNull);
      expect(p.canCommentAnswer, isNull);
      expect(parsed.stats, isNull);
      expect(parsed.interactions, isNull);
    });

    test('a 304 still fetches the interactions and hands them to the caller', () async {
      mock((req) => req.url.path.endsWith('/feed/interactions')
          ? http.Response(_interactions(), 200, headers: {'content-type': 'application/json'})
          : http.Response('', 304, headers: {'etag': '"v1"'}));
      final parsed = await RssParser.fetchFeed(_feed, etag: '"v1"');
      expect(parsed.notModified, isTrue);
      expect(parsed.interactions, isNotNull);
      expect(parsed.interactions!.items[_post]!.score, 7);
      // The caller's cached re-parse applies them.
      final cached = RssParser.parseBody(_v1Document(), _feed,
              contentType: 'application/publicos-feed+json')
          .withInteractions(parsed.interactions!);
      expect(cached.posts.single.score, 7);
      expect(cached.channel!.followStatus, 'approved');
    });

    test('a server with no /feed (404) is read at the URL as given, plainly', () async {
      mock((req) => req.url.path.endsWith('/feed')
          ? http.Response('{"error":{"code":"NOT_FOUND"}}', 404)
          : http.Response(_emptyFeed, 200, headers: {'content-type': 'application/feed+json'}));
      final parsed = await RssParser.fetchFeed(_feed);
      expect(seen.map((r) => r.url.toString()), ['$_base/feed', _feed]);
      expect(parsed.isFeedV1, isFalse);
      expect(parsed.title, 'nuevas');
      expect(parsed.channel, isNull);
    });

    test('an outside URL is never redirected and gets no interactions call', () async {
      mock((_) => http.Response(_emptyFeed, 200, headers: {'content-type': 'application/feed+json'}));
      await RssParser.fetchFeed('https://example.com/feed.json');
      expect(seen.map((r) => r.url.toString()), ['https://example.com/feed.json']);
    });

    test('the request accepts the PublicOS Feed document first', () async {
      mock(document);
      await RssParser.fetchFeed(_feed);
      expect(seen.first.headers['Accept'], startsWith('application/publicos-feed+json'));
    });
  });

  test('parseBody: a vanilla JSON Feed body has no channel object', () {
    final parsed = RssParser.parseBody(_emptyFeed, _feed, contentType: 'application/feed+json');
    expect(parsed.channel, isNull);
    expect(parsed.isFeedV1, isFalse);
  });

  test('parseBody: a cached document under an export URL is still the document', () {
    final parsed = RssParser.parseBody(_v1Document(), '$_base/rss',
        contentType: 'application/publicos-feed+json; charset=utf-8');
    expect(parsed.isFeedV1, isTrue);
    expect(parsed.posts.single.feedUrl, '$_base/rss');
  });
}
