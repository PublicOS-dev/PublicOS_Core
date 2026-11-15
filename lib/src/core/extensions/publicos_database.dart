import 'package:publicos_core/src/core/core.dart';
import 'package:publicos_core/src/database/database.dart';
import 'package:publicos_core/src/utils/log.dart';

/// Database management extension for PublicOS.
/// Handles database initialization using Drift.
extension PublicOSDatabase on PublicOS {
  /// Initialize the Drift database
  static Future<bool> initializeDatabase() async {
    try {
      Log.i('Database', 'Initializing Drift database');

      // Create the database instance
      PublicOS.database = AppDatabase();

      // Verify the database is working by running a simple query
      await PublicOS.database.customSelect('SELECT 1').get();

      Log.i('Database', 'Drift database initialized successfully');
      return true;
    } catch (e) {
      Log.e('Database', 'Database initialization failed: $e');
      return false;
    }
  }
}
