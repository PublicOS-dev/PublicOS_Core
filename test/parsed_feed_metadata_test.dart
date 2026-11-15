// Unit tests for the feed-level metadata carry:
// ParsedFeed surfaces the channel's facts off the same body as the posts, so
// a single-feed surface can render its header from any load path — including
// the cached raw body, offline. A PublicOS Feed document carries them in
// `channel`; its counts come from the interactions call, never the body; an
// outside body leaves them null (absent means *not measured*, never zero).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';

const _owner = '0xabcdabcdabcdabcdabcdabcdabcdabcdabcdabcd';
const _channelUrl = 'https://feeds.example/api/$_owner/channels/noticias/json';

String _channelBody({String? postingPolicy = 'open'}) => jsonEncode({
      'version': 'https://publicos.dev/feed/1',
      'channel': {
        'owner': _owner,
        'slug': 'noticias',
        'title': 'Noticias',
        'description': 'El canal de noticias del pueblo.',
        if (postingPolicy != null) 'posting': postingPolicy,
        'access': {'read_identity': 'anyone'},
      },
      'items': [
        {
          'id': 'post-1',
          'url': 'https://feeds.example/api/$_owner/channels/noticias/posts/post-1',
          'author': 'Pueblo',
          'title': 'Hola',
          'text': 'Primer post',
          'date_published': '2026-07-20T12:00:00Z',
        },
      ],
      'interactions_url':
          'https://feeds.example/api/$_owner/channels/noticias/feed/interactions?offset=0',
      'total': 1,
    });

void main() {
  group('ParsedFeed metadata carry — PublicOS Feed document', () {
    test('channel body → description + postingPolicy; counts are not in the body', () {
      final parsed = RssParser.parseBody(
        _channelBody(),
        _channelUrl,
        contentType: 'application/publicos-feed+json',
      );

      expect(parsed.description, 'El canal de noticias del pueblo.');
      expect(parsed.postingPolicy, 'open');
      expect(parsed.isPrivate, isFalse);
      expect(parsed.stats, isNull, reason: 'stats come from the interactions call');
      expect(parsed.posts, hasLength(1));
      expect(parsed.posts.single.isForumChannel, isTrue);
      expect(parsed.interactionsUrl, isNotNull);
    });

    test('the interactions answer brings the stats; absent stays null, never zero', () {
      final parsed = RssParser.parseBody(
        _channelBody(),
        _channelUrl,
        contentType: 'application/publicos-feed+json',
      );
      final withStats = parsed.withInteractions(FeedInteractions.fromJson({
        'items': {},
        'channel': {
          'stats': {
            'verified_citizen_views': 42,
            'total_views': 100,
            'by_type': {'citizen': 42, 'private': 8, 'signed_no_account': 0, 'anonymous': 50},
            'daily': [1, 2, 3, 4, 5, 6, 7],
            'today': 2,
            'week': '2026-W30',
          },
        },
      }));
      expect(withStats.stats!.verifiedCitizenViews, 42);
      expect(withStats.stats!.totalViews, 100);
      expect(withStats.posts.single.commentsCount, isNull,
          reason: 'an item with no entry is not measured');

      final without = parsed.withInteractions(
          FeedInteractions.fromJson({'items': {}, 'channel': {}}));
      expect(without.stats, isNull);
    });

    test('a channel with no posting value → postingPolicy null', () {
      final parsed = RssParser.parseBody(
        _channelBody(postingPolicy: null),
        _channelUrl,
        contentType: 'application/publicos-feed+json',
      );
      expect(parsed.postingPolicy, isNull);
      expect(parsed.posts.single.isForumChannel, isNull);
    });

    test('an outside JSON Feed → stats and postingPolicy null', () {
      final body = jsonEncode({
        'version': 'https://jsonfeed.org/version/1.1',
        'title': 'Some External Feed',
        'description': 'An external JSON feed.',
        'items': <Object>[],
      });
      final parsed = RssParser.parseBody(
        body,
        'https://example.com/feed/json',
        contentType: 'application/json',
      );

      expect(parsed.stats, isNull);
      expect(parsed.postingPolicy, isNull);
      expect(parsed.isPrivate, isNull);
      expect(parsed.description, 'An external JSON feed.');
      expect(parsed.isFeedV1, isFalse);
    });

    test('an outside JSON Feed item: image leads as the hero, attachments support', () {
      final body = jsonEncode({
        'version': 'https://jsonfeed.org/version/1.1',
        'title': 'Blog',
        'items': [
          {
            'id': 'https://blog.example/1',
            'url': 'https://blog.example/1',
            'title': 'One',
            'content_text': 'Body',
            'image': 'https://blog.example/1.jpg',
            'attachments': [
              {'url': 'https://blog.example/1.mp3', 'mime_type': 'audio/mpeg', 'size_in_bytes': 10, 'duration_in_seconds': 61},
            ],
          },
        ],
      });
      final p = RssParser.parseBody(body, 'https://blog.example/feed.json',
              contentType: 'application/feed+json')
          .posts
          .single;
      expect(p.externalUrl, 'https://blog.example/1');
      expect(p.url, isNull);
      expect(p.bannerImage, 'https://blog.example/1.jpg');
      expect(p.supportMedia.single.mimeType, 'audio/mpeg');
      expect(p.carouselItems.single.isFile, isTrue);
    });
  });

  group('ParsedFeed metadata carry — XML (external RSS) branch', () {
    test('external RSS body → description carried, stats/postingPolicy null',
        () {
      const rss = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>External Blog</title>
    <description>A plain RSS feed with a description.</description>
    <link>https://blog.example</link>
    <item>
      <title>Post one</title>
      <description><![CDATA[Body <img src="https://blog.example/1.png">]]></description>
      <link>https://blog.example/1</link>
      <pubDate>Mon, 20 Jul 2026 12:00:00 GMT</pubDate>
      <enclosure url="https://blog.example/lead.jpg" type="image/jpeg" length="1"/>
    </item>
  </channel>
</rss>''';
      final parsed = RssParser.parseBody(
        rss,
        'https://blog.example/rss',
        contentType: 'application/rss+xml',
      );

      expect(parsed.description, 'A plain RSS feed with a description.');
      expect(parsed.stats, isNull);
      expect(parsed.postingPolicy, isNull);
      expect(parsed.posts, hasLength(1));
      final p = parsed.posts.single;
      expect(p.bannerImage, 'https://blog.example/lead.jpg',
          reason: 'the enclosure leads as the hero');
      expect(p.carouselImages, ['https://blog.example/1.png'],
          reason: 'the body picture supports');
    });
  });

  group('FeedServerApiResponse metadata carry', () {
    test('success factory carries description + postingPolicy additively', () {
      final r = FeedServerApiResponse.success(
        <Post>[],
        hasMore: true,
        description: 'El canal de noticias del pueblo.',
        postingPolicy: 'open',
      );
      expect(r.description, 'El canal de noticias del pueblo.');
      expect(r.postingPolicy, 'open');
      expect(r.hasMore, isTrue);
    });

    test('omitting the new fields leaves them null (desktop-fork contract)',
        () {
      final r = FeedServerApiResponse.success(<Post>[]);
      expect(r.description, isNull);
      expect(r.postingPolicy, isNull);
    });
  });
}
