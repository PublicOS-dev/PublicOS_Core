import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';

void main() {
  test('PublicOS core class exists and is not initialized by default', () {
    expect(PublicOS.isInitialized, false);
    expect(PublicOS.isAuthenticated, false);
  });
}
