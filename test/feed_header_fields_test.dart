/// Feed-level header fields across RSS 2.0, Atom and JSON Feed: the website
/// (`siteUrl`), the declared `language`, and a description that never borrows
/// an item's. Feeds the mobile feed reader header.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';

void main() {
  test('RSS 2.0: <link> site, <language>, channel description', () {
    const xml = '''<?xml version="1.0"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom"><channel>
  <title>Example News</title>
  <link>https://example.com/</link>
  <atom:link href="https://example.com/feed.xml" rel="self" type="application/rss+xml"/>
  <description>All the news</description>
  <language>es-mx</language>
  <item><title>One</title><link>https://example.com/1</link><description>item desc</description></item>
</channel></rss>''';
    final f = RssParser.parseBody(xml, 'https://example.com/feed.xml');
    expect(f.siteUrl, 'https://example.com/');
    expect(f.language, 'es-mx');
    expect(f.description, 'All the news');
  });

  test('RSS without a channel description does NOT borrow the first item\'s', () {
    const xml = '''<rss version="2.0"><channel>
  <title>Bare</title><link>https://bare.example/</link>
  <item><title>One</title><description>item desc</description></item>
</channel></rss>''';
    final f = RssParser.parseBody(xml, 'https://bare.example/rss');
    expect(f.description, isEmpty);
    expect(f.language, isNull);
  });

  test('Atom: rel=alternate site (self skipped), xml:lang, subtitle', () {
    const xml = '''<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xml:lang="en">
  <title>Atom Blog</title>
  <subtitle>Thoughts</subtitle>
  <link href="https://blog.example/atom.xml" rel="self"/>
  <link href="https://blog.example/" rel="alternate"/>
  <updated>2026-10-01T00:00:00Z</updated>
  <entry><title>Post</title><link href="https://blog.example/p1"/><updated>2026-10-01T00:00:00Z</updated><summary>s</summary></entry>
</feed>''';
    final f = RssParser.parseBody(xml, 'https://blog.example/atom.xml');
    expect(f.siteUrl, 'https://blog.example/');
    expect(f.language, 'en');
    expect(f.description, 'Thoughts');
  });

  test('Atom: a rel-less <link> is the site (Atom default = alternate)', () {
    const xml = '''<feed xmlns="http://www.w3.org/2005/Atom">
  <title>A</title><link href="https://a.example/"/>
</feed>''';
    expect(RssParser.parseBody(xml, 'https://a.example/feed').siteUrl,
        'https://a.example/');
  });

  test('JSON Feed: home_page_url + language; none declared → null', () {
    const withBoth = '{"version":"https://jsonfeed.org/version/1.1","title":"J",'
        '"home_page_url":"https://j.example/","language":"pt-BR","items":[]}';
    final f = RssParser.parseBody(withBoth, 'https://j.example/feed.json',
        contentType: 'application/feed+json');
    expect(f.siteUrl, 'https://j.example/');
    expect(f.language, 'pt-BR');

    const bare = '{"version":"https://jsonfeed.org/version/1.1","title":"J","items":[]}';
    final g = RssParser.parseBody(bare, 'https://j.example/feed.json',
        contentType: 'application/feed+json');
    expect(g.siteUrl, isNull, reason: 'never the feed URL');
    expect(g.language, isNull);
  });
}
