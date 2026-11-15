import 'dart:typed_data';
import 'package:drift/drift.dart';
import 'package:publicos_core/src/core/core.dart';
import 'package:publicos_core/src/database/database.dart' as db;
import 'package:publicos_core/src/utils/log.dart';
import 'package:xmtp_plugin/codecs.dart';

/// Attachment cache management extension for PublicOS.
/// Provides SQLite-based caching for remote attachments.
extension PublicOSAttachmentCache on PublicOS {
  static const _tag = 'Cache';

  /// Cache configuration
  static const int MAX_CACHE_SIZE_BYTES = 500 * 1024 * 1024; // 500MB
  static const int MAX_AGE_DAYS = 30;

  /// Get a cached attachment by content digest
  ///
  /// Returns null if not found in cache
  static Future<AttachmentContent?> getCachedAttachment(String contentDigest) async {
    try {
      final database = PublicOS.database;
      final row = await database.getCachedAttachment(contentDigest);

      if (row == null) {
        Log.d(_tag, 'Cache miss for digest: ${contentDigest.substring(0, 16)}...');
        return null;
      }

      // Update last accessed time
      await database.updateAttachmentLastAccessed(
        contentDigest,
        DateTime.now().millisecondsSinceEpoch,
      );

      Log.d(_tag, 'Cache hit for ${row.filename} (${row.size} bytes)');

      return AttachmentContent(
        data: row.data,
        filename: row.filename,
        mimeType: row.mimeType,
      );
    } catch (e) {
      Log.e(_tag, 'Error retrieving from cache: $e');
      return null;
    }
  }

  /// Store an attachment in the cache
  ///
  /// Automatically handles cache size management and eviction
  static Future<void> putCachedAttachment({
    required String contentDigest,
    required AttachmentContent attachment,
  }) async {
    try {
      final database = PublicOS.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Check if already cached
      final existing = await database.getCachedAttachment(contentDigest);

      if (existing != null) {
        // Already cached, just update last accessed
        await database.updateAttachmentLastAccessed(contentDigest, now);
        Log.d(_tag, 'Updated last_accessed for ${attachment.filename}');
        return;
      }

      // Check cache size before inserting
      await _evictIfNeeded(attachment.data.length);

      // Insert new cache entry
      final companion = db.AttachmentCacheCompanion(
        contentDigest: Value(contentDigest),
        filename: Value(attachment.filename),
        mimeType: Value(attachment.mimeType),
        data: Value(attachment.data),
        size: Value(attachment.data.length),
        cachedAt: Value(now),
        lastAccessed: Value(now),
      );
      await database.upsertCachedAttachment(companion);

      Log.d(_tag, 'Cached ${attachment.filename} (${attachment.data.length} bytes)');
    } catch (e) {
      Log.e(_tag, 'Error storing in cache: $e');
    }
  }

  /// Evict old or excess cache entries if needed
  static Future<void> _evictIfNeeded(int newEntrySize) async {
    try {
      final database = PublicOS.database;

      // Get current cache size
      final currentSize = await database.getCacheTotalSize();

      // If adding new entry would exceed max size, evict LRU entries
      if (currentSize + newEntrySize > MAX_CACHE_SIZE_BYTES) {
        Log.d(_tag, 'Cache size ($currentSize bytes) + new entry ($newEntrySize bytes) exceeds limit. Evicting...');

        // Get entries sorted by last accessed (LRU)
        final entries = await database.getCacheEntriesLRU();

        int freedSpace = 0;
        int evictedCount = 0;

        for (final entry in entries) {
          if (currentSize - freedSpace + newEntrySize <= MAX_CACHE_SIZE_BYTES) {
            break;
          }

          await database.deleteCachedAttachment(entry.contentDigest);

          freedSpace += entry.size;
          evictedCount++;
          Log.d(_tag, 'Evicted ${entry.filename} (${entry.size} bytes)');
        }

        Log.d(_tag, 'Evicted $evictedCount entries, freed $freedSpace bytes');
      }

      // Clean up entries older than MAX_AGE_DAYS
      final cutoffTime = DateTime.now().subtract(Duration(days: MAX_AGE_DAYS)).millisecondsSinceEpoch;
      final deletedCount = await database.deleteOldCacheEntries(cutoffTime);

      if (deletedCount > 0) {
        Log.d(_tag, 'Cleaned up $deletedCount old entries (>$MAX_AGE_DAYS days)');
      }
    } catch (e) {
      Log.e(_tag, 'Error during eviction: $e');
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final database = PublicOS.database;

      final entries = await database.getCacheEntriesLRU();
      final count = entries.length;
      final totalSize = await database.getCacheTotalSize();

      return {
        'count': count,
        'totalSize': totalSize,
        'maxSize': MAX_CACHE_SIZE_BYTES,
        'utilizationPercent': (totalSize / MAX_CACHE_SIZE_BYTES * 100).toStringAsFixed(1),
      };
    } catch (e) {
      Log.e(_tag, 'Error getting cache stats: $e');
      return {};
    }
  }

  /// Clear all cached attachments
  static Future<void> clearCache() async {
    try {
      final database = PublicOS.database;
      final deletedCount = await database.clearAttachmentCache();
      Log.i(_tag, 'Cleared cache ($deletedCount entries removed)');
    } catch (e) {
      Log.e(_tag, 'Error clearing cache: $e');
    }
  }
}
