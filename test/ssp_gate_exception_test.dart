import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';

void main() {
  group('SSPGateException.tryFromErrorMap', () {
    test('parses SSP_NOT_SUBSCRIBED with ssp_slug', () {
      final ex = SSPGateException.tryFromErrorMap(403, {
        'code': 'SSP_NOT_SUBSCRIBED',
        'message': 'Subscribe to publicos to write here.',
        'ssp_slug': 'publicos',
      });
      expect(ex, isNotNull);
      expect(ex!.code, 'SSP_NOT_SUBSCRIBED');
      expect(ex.message, 'Subscribe to publicos to write here.');
      expect(ex.sspSlug, 'publicos');
      expect(ex.otherSlug, isNull);
      expect(ex.statusCode, 403);
      expect(ex.isClientFault, isTrue);
      expect(ex.isServerFault, isFalse);
    });

    test('parses SSP_WRONG and pulls otherSlug from details', () {
      final ex = SSPGateException.tryFromErrorMap(403, {
        'code': 'SSP_WRONG',
        'message': "You're on another SSP.",
        'ssp_slug': 'publicos',
        'details': 'someothershop',
      });
      expect(ex, isNotNull);
      expect(ex!.code, 'SSP_WRONG');
      expect(ex.sspSlug, 'publicos');
      expect(ex.otherSlug, 'someothershop');
    });

    test('parses SSP_EXPIRED', () {
      final ex = SSPGateException.tryFromErrorMap(403, {
        'code': 'SSP_EXPIRED',
        'message': 'Your subscription expired.',
        'ssp_slug': 'publicos',
      });
      expect(ex, isNotNull);
      expect(ex!.code, 'SSP_EXPIRED');
      expect(ex.statusCode, 403);
      expect(ex.isClientFault, isTrue);
    });

    test('parses SSP_GATE_FAILED as 500 / server fault', () {
      final ex = SSPGateException.tryFromErrorMap(500, {
        'code': 'SSP_GATE_FAILED',
        'message': "Couldn't verify subscription.",
        'ssp_slug': 'publicos',
      });
      expect(ex, isNotNull);
      expect(ex!.code, 'SSP_GATE_FAILED');
      expect(ex.statusCode, 500);
      expect(ex.isClientFault, isFalse);
      expect(ex.isServerFault, isTrue);
    });

    test('SSP_WRONG ignores details when called with non-WRONG code', () {
      final ex = SSPGateException.tryFromErrorMap(403, {
        'code': 'SSP_NOT_SUBSCRIBED',
        'message': 'irrelevant',
        'details': 'someothershop',
      });
      expect(ex, isNotNull);
      expect(ex!.otherSlug, isNull);
    });

    test('returns null for non-gate codes (e.g. AUTH_FAILED on 401)', () {
      final ex = SSPGateException.tryFromErrorMap(401, {
        'code': 'AUTH_FAILED',
        'message': 'bad sig',
      });
      expect(ex, isNull);
    });

    test('returns null for non-gate codes on 403 (e.g. BANNED)', () {
      final ex = SSPGateException.tryFromErrorMap(403, {
        'code': 'BANNED',
        'message': 'you are banned',
      });
      expect(ex, isNull);
    });

    test('returns null when status is not 403/500', () {
      final ex = SSPGateException.tryFromErrorMap(404, {
        'code': 'SSP_NOT_SUBSCRIBED',
        'message': 'irrelevant',
      });
      expect(ex, isNull);
    });

    test('returns null on null error map', () {
      final ex = SSPGateException.tryFromErrorMap(403, null);
      expect(ex, isNull);
    });

    test('returns null when error has no code field', () {
      final ex = SSPGateException.tryFromErrorMap(403, {
        'message': 'hello',
      });
      expect(ex, isNull);
    });

    test('toString includes code and slug', () {
      final ex = SSPGateException.tryFromErrorMap(403, {
        'code': 'SSP_EXPIRED',
        'message': 'expired',
        'ssp_slug': 'publicos',
      })!;
      expect(ex.toString(), contains('SSP_EXPIRED'));
      expect(ex.toString(), contains('publicos'));
    });
  });
}
