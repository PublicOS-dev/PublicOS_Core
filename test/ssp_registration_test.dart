import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';

/// Registered-SSP lookup: the client's key for the registry's
/// host lookup must equal a canonical apiUrl byte for byte.
void main() {
  group('canonicalSspUrlOf', () {
    test('scheme + lower-cased authority, nothing else', () {
      expect(
        PublicOSSsp.canonicalSspUrlOf(
            'https://Feeds.PublicOS.dev/api/0xabc/channels/thefeed/json'),
        'https://feeds.publicos.dev',
      );
      expect(PublicOSSsp.canonicalSspUrlOf('https://feeds.publicos.dev/'),
          'https://feeds.publicos.dev');
      expect(PublicOSSsp.canonicalSspUrlOf('https://feeds.publicos.dev'),
          'https://feeds.publicos.dev');
    });
    test('a port survives, a path does not', () {
      expect(PublicOSSsp.canonicalSspUrlOf('http://10.0.0.5:8080/api/x'),
          'http://10.0.0.5:8080');
    });
    test('no scheme or host → null', () {
      expect(PublicOSSsp.canonicalSspUrlOf('feeds.publicos.dev/api'), isNull);
      expect(PublicOSSsp.canonicalSspUrlOf(''), isNull);
      expect(PublicOSSsp.canonicalSspUrlOf('https://'), isNull);
    });
  });
  test('sspRegistrationOf on a URL with no host is unknown, no chain', () async {
    expect(await PublicOSSsp.sspRegistrationOf('not a url'),
        SspRegistration.unknown);
  });
}
