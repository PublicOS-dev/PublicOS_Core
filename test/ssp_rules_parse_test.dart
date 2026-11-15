import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';

/// GET /privacy_and_agreements parse.
void main() {
  test('a full body parses, Spanish served, unknown language falls back to English', () {
    final r = SspRules.fromJson({
      'version': 1,
      'effective_from': '2026-11-03',
      'rules': {'en': 'behave', 'es': 'compórtate'},
      'privacy': {'en': 'little'},
      'history': [],
    })!;
    expect(r.version, 1);
    expect(r.effectiveFrom, '2026-11-03');
    expect(r.rulesFor('es'), 'compórtate');
    expect(r.rulesFor('fr'), 'behave');
    expect(r.privacyFor('es'), 'little');
  });

  test('missing version or English text is not a rules body', () {
    expect(SspRules.fromJson({'rules': {'en': 'r'}, 'privacy': {'en': 'p'}}), isNull);
    expect(SspRules.fromJson({'version': 1, 'rules': {'es': 'r'}, 'privacy': {'en': 'p'}}), isNull);
    expect(SspRules.fromJson({'version': 1, 'rules': {'en': 'r'}}), isNull);
    expect(SspRules.fromJson({'version': 0, 'rules': {'en': 'r'}, 'privacy': {'en': 'p'}}), isNull);
  });
}
