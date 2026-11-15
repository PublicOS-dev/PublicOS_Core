import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';

/// The live fixture these mirror: app `petdemo`, registered on chain 4489,
/// `card_origin = https://cards.publicos.dev/petdemo/`.
const _origin = 'https://cards.publicos.dev/petdemo/';
const _image = 'https://cards.publicos.dev/petdemo/pet1/still.gif';
const _live = 'https://cards.publicos.dev/petdemo/pet1/';

String _card({
  int v = 1,
  String app = 'petdemo',
  String? image = _image,
  String? live = _live,
  String extra = '',
}) {
  final parts = <String>[
    '"v":$v',
    '"app":"$app"',
    if (image != null) '"image":"$image"',
    if (live != null) '"live":"$live"',
    if (extra.isNotEmpty) extra,
  ];
  return '{${parts.join(',')}}';
}

void main() {
  group('AppCardRef.isUnder - the entire security surface', () {
    final origin = Uri.parse(_origin);

    test('a URL genuinely under the declared prefix passes', () {
      expect(AppCardRef.isUnder(Uri.parse(_image), origin), isTrue);
      expect(AppCardRef.isUnder(Uri.parse(_live), origin), isTrue);
      // the prefix root itself is under the prefix
      expect(AppCardRef.isUnder(Uri.parse(_origin), origin), isTrue);
    });

    test('the lookalike-suffix host is REJECTED (what startsWith would allow)',
        () {
      final evil =
          Uri.parse('https://cards.publicos.dev.evil.com/petdemo/pet1/x.gif');
      // Prove the naive check really would have been fooled, so this test
      // documents the attack rather than just asserting a bool.
      expect(evil.toString().startsWith('https://cards.publicos.dev'), isTrue);
      expect(AppCardRef.isUnder(evil, origin), isFalse);
    });

    test('a sibling path that merely shares a string prefix is rejected', () {
      expect(
        AppCardRef.isUnder(
            Uri.parse('https://cards.publicos.dev/petdemoEVIL/x.gif'), origin),
        isFalse,
      );
    });

    test('path traversal cannot climb out of the prefix', () {
      expect(
        AppCardRef.isUnder(
            Uri.parse('https://cards.publicos.dev/petdemo/../other/x.gif'),
            origin),
        isFalse,
      );
    });

    test('http, a different port, and embedded credentials are all rejected',
        () {
      expect(
        AppCardRef.isUnder(
            Uri.parse('http://cards.publicos.dev/petdemo/pet1/x.gif'), origin),
        isFalse,
      );
      expect(
        AppCardRef.isUnder(
            Uri.parse('https://cards.publicos.dev:8443/petdemo/pet1/x.gif'),
            origin),
        isFalse,
      );
      expect(
        AppCardRef.isUnder(
            Uri.parse('https://u:p@cards.publicos.dev/petdemo/pet1/x.gif'),
            origin),
        isFalse,
      );
    });

    test('host comparison is case-insensitive', () {
      expect(
        AppCardRef.isUnder(
            Uri.parse('https://CARDS.PublicOS.dev/petdemo/pet1/x.gif'), origin),
        isTrue,
      );
    });

    test('an origin that is not path-shaped is rejected, never coerced', () {
      // Coercing this to `/` would silently widen the grant to the whole site.
      final bare = Uri.parse('https://cards.publicos.dev/petdemo');
      expect(AppCardRef.isUnder(Uri.parse(_image), bare), isFalse);
    });

    test('an origin carrying a query or fragment is rejected', () {
      expect(
        AppCardRef.isUnder(Uri.parse(_image),
            Uri.parse('https://cards.publicos.dev/petdemo/?a=1')),
        isFalse,
      );
      expect(
        AppCardRef.isUnder(Uri.parse(_image),
            Uri.parse('https://cards.publicos.dev/petdemo/#f')),
        isFalse,
      );
    });
  });

  group('AppCardRef.tryParse', () {
    test('a full card parses and is promotable', () {
      final r = AppCardRef.tryParse(_card())!;
      expect(r.app, 'petdemo');
      expect(r.image.toString(), _image);
      expect(r.live.toString(), _live);
      expect(r.isSupportedVersion, isTrue);
      expect(r.isPromotable, isTrue);
    });

    test('no live half is a COMPLETE card, not a failure', () {
      final r = AppCardRef.tryParse(_card(live: null))!;
      expect(r.live, isNull);
      expect(r.isPromotable, isFalse);
      expect(r.image.toString(), _image);
    });

    test('an unknown future version still renders, but never promotes', () {
      final r = AppCardRef.tryParse(_card(v: 99))!;
      expect(r.version, 99);
      expect(r.isSupportedVersion, isFalse);
      expect(r.isPromotable, isFalse, reason: 'cannot know what v99 live wants');
      expect(r.image.toString(), _image, reason: 'the picture still shows');
    });

    test('unread keys survive a round trip', () {
      final r = AppCardRef.tryParse(_card(extra: '"futureKey":{"a":1}'))!;
      expect(r.extra['futureKey'], {'a': 1});
      final again = AppCardRef.tryParse(r.encode())!;
      expect(again.extra['futureKey'], {'a': 1});
      expect(again.image, r.image);
    });

    test('malformed input is null, never half-accepted', () {
      expect(AppCardRef.tryParse(null), isNull);
      expect(AppCardRef.tryParse(''), isNull);
      expect(AppCardRef.tryParse('not json'), isNull);
      expect(AppCardRef.tryParse('[]'), isNull);
      expect(AppCardRef.tryParse('{}'), isNull, reason: 'version required');
      expect(AppCardRef.tryParse(_card(image: null)), isNull);
    });

    test('a capitalised slug is rejected, as the chain would reject it', () {
      // `_isValidSlug` on AppRegistryMemory is lowercase-only; registering
      // `petDemo` reverts, so a record naming it can never resolve.
      expect(AppCardRef.tryParse(_card(app: 'petDemo')), isNull);
      expect(AppCardRef.tryParse(_card(app: 'ab')), isNull);
      expect(AppCardRef.tryParse(_card(app: '-lead')), isNull);
      expect(AppCardRef.isValidSlug('petdemo'), isTrue);
      expect(AppCardRef.isValidSlug('a_b-9'), isTrue);
    });

    test('a non-https image is rejected; a non-https live degrades to none', () {
      expect(
        AppCardRef.tryParse(_card(image: 'http://cards.publicos.dev/p/x.gif')),
        isNull,
      );
      final r =
          AppCardRef.tryParse(_card(live: 'http://cards.publicos.dev/p/'))!;
      expect(r.live, isNull, reason: 'unusable live half is simply absent');
      expect(r.isPromotable, isFalse);
    });
  });

  group('the resolver verdict, composed from the parts above', () {
    // Mirrors what PublicOSContacts does per card, minus the chain reads.
    AppCardVerdict verdictFor(AppCardRef? ref, {String? cardOrigin}) {
      if (ref == null) return AppCardVerdict.broken;
      if (cardOrigin == null || cardOrigin.isEmpty) {
        return AppCardVerdict.imageOnly;
      }
      final origin = Uri.tryParse(cardOrigin);
      if (origin == null) return AppCardVerdict.imageOnly;
      if (!AppCardRef.isUnder(ref.image, origin)) return AppCardVerdict.broken;
      if (ref.live == null || !AppCardRef.isUnder(ref.live!, origin)) {
        return AppCardVerdict.imageOnly;
      }
      return ref.isSupportedVersion
          ? AppCardVerdict.ok
          : AppCardVerdict.imageOnly;
    }

    test('the live petdemo fixture resolves ok', () {
      expect(verdictFor(AppCardRef.tryParse(_card()), cardOrigin: _origin),
          AppCardVerdict.ok);
    });

    test('app dropped its pointer -> imageOnly, the revocation state', () {
      expect(verdictFor(AppCardRef.tryParse(_card()), cardOrigin: null),
          AppCardVerdict.imageOnly);
    });

    test('live outside the declared origin -> imageOnly, not broken', () {
      final r = AppCardRef.tryParse(
          _card(live: 'https://somewhere.else/petdemo/pet1/'));
      expect(verdictFor(r, cardOrigin: _origin), AppCardVerdict.imageOnly);
    });

    test('image outside the declared origin -> broken, not imageOnly', () {
      final r = AppCardRef.tryParse(
          _card(image: 'https://somewhere.else/petdemo/pet1/x.gif'));
      expect(verdictFor(r, cardOrigin: _origin), AppCardVerdict.broken,
          reason: 'the app must be accountable for everything the card shows');
    });
  });
}
