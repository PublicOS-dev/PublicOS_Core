import 'dart:collection';

/// Lightweight logger for PublicOS_Core.
///
/// Usage:
///   static const _tag = 'Messages';
///   Log.d(_tag, 'Loaded $n messages');        // debug — stripped from release builds
///   Log.i(_tag, 'Session restored');           // info — always prints
///   Log.w(_tag, 'No auth session');            // warning — recoverable
///   Log.e(_tag, 'DB query failed: $e');        // error — something broke
class Log {
  static const _prefix = 'PublicOS';
  static const _maxEntries = 2000;

  /// In-memory ring buffer for log entries (info, warn, error — NOT debug).
  static final _buffer = Queue<String>();

  /// Debug — compiled out of release builds via assert().
  static void d(String tag, String msg) {
    assert(() {
      print('[$_prefix.$tag] $msg');
      return true;
    }());
  }

  /// Info — key state changes, always prints.
  static void i(String tag, String msg) {
    final line = '[$_prefix.$tag] $msg';
    _write(line);
    print(line);
  }

  /// Warning — recoverable issues, always prints.
  static void w(String tag, String msg) {
    final line = '[$_prefix.$tag] WARN: $msg';
    _write(line);
    print(line);
  }

  /// Error — something broke, always prints.
  static void e(String tag, String msg) {
    final line = '[$_prefix.$tag] ERROR: $msg';
    _write(line);
    print(line);
  }

  static void _write(String line) {
    final ts = DateTime.now().toIso8601String();
    _buffer.addLast('$ts  $line');
    while (_buffer.length > _maxEntries) {
      _buffer.removeFirst();
    }
  }

  /// Returns the buffered log as a single string.
  static String dump() => _buffer.join('\n');

  /// Clears the in-memory log buffer.
  static void clearBuffer() => _buffer.clear();
}
