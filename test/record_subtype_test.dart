import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';

Record _written(String key) => Record.asProfile(
      key: key,
      value: 'v',
      expiration: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );

/// A blob as it sits on chain, with an optional stored subtype.
Record _read(String key, {String? subtype}) => Record.fromJson(
      jsonDecode(jsonEncode({
        'key': key,
        'value': 'v',
        'type': 0,
        'metadata': <String, dynamic>{},
        'noTitle': false,
        if (subtype != null) 'subtype': subtype,
      })) as Map<String, dynamic>,
    );

void main() {
  group('profile subtype — a fixed list decides what shows', () {
    test('the page background is identity, written or read back as social', () {
      expect(_written('_osux_profile_background_url_').profileSubtype,
          ProfileSubtype.identity);
      expect(_read('_osux_profile_background_url_', subtype: 'social')
          .profileSubtype, ProfileSubtype.identity);
    });

    test('every key on SocialLinks is social', () {
      for (final l in SocialLinks.all) {
        expect(_written(l.key).profileSubtype, ProfileSubtype.social,
            reason: l.key);
      }
      expect(_read('url', subtype: 'social').profileSubtype,
          ProfileSubtype.social);
      expect(_read('email').profileSubtype, ProfileSubtype.social);
    });

    test('a key off the list is unknown (never rendered)', () {
      for (final k in ['txt', '_dmarc', 'com.discord', 'com.medium', 'foo']) {
        expect(_written(k).profileSubtype, ProfileSubtype.unknown, reason: k);
        expect(_read(k, subtype: 'social').profileSubtype,
            ProfileSubtype.unknown, reason: k);
      }
    });

    test('a card must be declared one', () {
      expect(_written('card.abc').profileSubtype, ProfileSubtype.card);
      expect(_read('card.abc', subtype: 'card').profileSubtype,
          ProfileSubtype.card);
      // A card.* key that declares something else is not a card.
      expect(_read('card.abc', subtype: 'social').profileSubtype,
          ProfileSubtype.unknown);
      // No subtype stored at all: still a card from its key.
      expect(_read('card.abc').profileSubtype, ProfileSubtype.card);
    });

    test('unknown is never written back to chain', () {
      expect(_written('txt').toChainValue().containsKey('subtype'), isFalse);
    });

    test('links build per network', () {
      expect(SocialLinks.of('com.twitter')!.buildLink('@jmsl'),
          'https://x.com/jmsl');
      expect(SocialLinks.of('url')!.buildLink('publicos.dev'),
          'https://publicos.dev');
      expect(SocialLinks.of('url')!.buildLink('http://a.b'), 'http://a.b');
      expect(SocialLinks.of('email')!.buildLink('a@b.co'), 'mailto:a@b.co');
      expect(SocialLinks.of('email')!.buildLink('nope'), isNull);
      expect(SocialLinks.of('com.youtube')!.buildLink('@chan'),
          'https://youtube.com/@chan');
      expect(SocialLinks.of('com.discord'), isNull); // commented out
    });
  });
}
