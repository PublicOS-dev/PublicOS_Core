import 'package:publicos_core/publicos_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('postRefOf — a post permalink carries its own server', () {
    test('a live-shaped permalink splits into all four parts, verbatim', () {
      final ref = postRefOf('https://feeds.publicos.dev/api/'
          '0x494a032bd61f0dC9D662479f9E4dFebBAf9fCE2C/channels/nuevas/posts/'
          'bdbb5433-1314-4fe8-9204-63b076a6e47c');
      expect(ref, isNotNull);
      expect(ref!.server, 'https://feeds.publicos.dev');
      // Casing is kept: the SSP resolves the owner case-sensitively.
      expect(ref.owner, '0x494a032bd61f0dC9D662479f9E4dFebBAf9fCE2C');
      expect(ref.slug, 'nuevas');
      expect(ref.uid, 'bdbb5433-1314-4fe8-9204-63b076a6e47c');
    });

    test('another SSP stays that SSP, never the reader\'s', () {
      final ref = postRefOf(
          'https://feeds-de.publicos.dev/api/0xAbC/channels/x/posts/u1');
      expect(ref!.server, 'https://feeds-de.publicos.dev');
    });

    test('anything that is not a post permalink is null', () {
      for (final url in [
        'https://feeds.test/api/0xAbC/channels/x/json',
        'https://feeds.test/api/0xAbC/channels/x',
        'https://feeds.test/api/0xAbC/channels/x/posts/u1/comments',
        'https://feeds.test/api/0xAbC/channels/x/posts/',
        'https://www.theverge.com/2026/9/26/some-article',
        'not a url',
        '',
      ]) {
        expect(postRefOf(url), isNull, reason: url);
      }
    });
  });
}
