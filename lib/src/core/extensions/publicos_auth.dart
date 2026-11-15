import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';
import 'package:publicos_core/src/core/core.dart';
import 'package:publicos_core/src/utils/log.dart';

/// Authentication extension for PublicOS.
/// Handles biometric authentication.
extension PublicOSAuth on PublicOS {
  /// Authenticate user with biometrics
  /// On web, biometric auth is not supported, so we skip and return true.
  static Future<bool> authenticate() async {
    if (!PublicOS.isInitialized) {
      throw Exception('Core not initialized');
    }

    // Skip biometric auth on web - not supported
    if (kIsWeb) {
      Log.d('Auth', 'Web platform detected, skipping biometric auth');
      PublicOS.isAuthenticated = true;
      return true;
    }

    try {
      PublicOS.isAuthenticated = await PublicOS.localAuth.authenticate(
        localizedReason: 'Authenticate to access PublicOS',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      return PublicOS.isAuthenticated || PublicOS.debugNoAuthNeeded;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e('Auth', 'Authentication error: $e');
      PublicOS.isAuthenticated = false;
      return false;
    }
  }
}
