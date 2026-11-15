import 'package:crypto/crypto.dart' show sha256;
import 'package:drift/drift.dart';
import 'package:publicos_core/src/core/core.dart';
import 'package:publicos_core/src/database/database.dart' as db;
import 'package:publicos_core/src/utils/log.dart';
import 'package:xmtp_plugin/codecs.dart';

/// The user's saved sticker library.
///
/// A sticker is an ordinary `xmtp.org/attachment` carrying the `isSticker`
/// flag, and intake is inline-only under a 1 MB cap — so a received sticker's
/// bytes are **already local**, sitting in the message payload. Saving one is
/// a byte copy: no network, no SSP, no download.
///
/// Distinct from [PublicOSAttachmentCache], which is an LRU cache (30-day
/// expiry, 500 MB eviction). Library rows are owned by the user; only the user
/// deletes them.
///
/// Scoped by [PublicOS.sessionBlockchainAddress] — a personal collection, shared
/// across the keychain keys of one account. See `db.SavedStickers`.
extension PublicOSStickers on PublicOS {
  static const _tag = 'Stickers';

  /// Content-address a sticker. The `{digest, sessionAddress}` unique index
  /// turns this into free, silent dedup.
  static String digestOf(Uint8List data) =>
      sha256.convert(data).bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// Save [attachment] to the library. Returns true when a NEW row landed,
  /// false when this exact sticker was already saved (a no-op re-save).
  ///
  /// The caller's `description` is deliberately dropped: a caption belonged to
  /// the message it was sent with, not to the sticker.
  ///
  /// Throws [StateError] when no account is signed in — a library row without
  /// a `sessionAddress` would be unreachable by every read path.
  static Future<bool> saveSticker(AttachmentContent attachment) async {
    final sessionAddress = PublicOS.sessionBlockchainAddress;
    if (sessionAddress == null) {
      throw StateError('Cannot save a sticker with no signed-in account');
    }
    if (attachment.data.isEmpty) {
      throw ArgumentError('Cannot save a sticker with no bytes');
    }

    final database = PublicOS.database;
    final digest = digestOf(attachment.data);

    final inserted = await database.insertSavedSticker(
      db.SavedStickersCompanion(
        digest: Value(digest),
        filename: Value(attachment.filename),
        mimeType: Value(attachment.mimeType),
        data: Value(attachment.data),
        size: Value(attachment.data.length),
        sessionAddress: Value(sessionAddress),
        savedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );

    // Null means the unique index rejected the row — already in the library.
    final isNew = inserted != null;
    Log.d(_tag,
        isNew ? 'Saved ${attachment.filename} (${attachment.data.length} bytes)'
              : 'Already saved: ${digest.substring(0, 16)}…');
    return isNew;
  }

  /// Whether this exact sticker is already in the signed-in account's library.
  /// Lets a UI show "saved" state without pulling bytes.
  static Future<bool> isStickerSaved(Uint8List data) async {
    final sessionAddress = PublicOS.sessionBlockchainAddress;
    if (sessionAddress == null) return false;
    final row = await PublicOS.database
        .getSavedStickerByDigest(digestOf(data), sessionAddress);
    return row != null;
  }

  /// The library, newest first, **without bytes** — see [db.SavedStickerMeta].
  /// Empty when no account is signed in.
  static Future<List<db.SavedStickerMeta>> listStickers() async {
    final sessionAddress = PublicOS.sessionBlockchainAddress;
    if (sessionAddress == null) return const [];
    return PublicOS.database.getSavedStickerMeta(sessionAddress);
  }

  /// Bytes for one sticker. Null when the row was deleted between the grid's
  /// meta query and this fetch.
  static Future<Uint8List?> getStickerData(int id) =>
      PublicOS.database.getSavedStickerData(id);

  /// Rehydrate a saved sticker into a sendable [AttachmentContent].
  /// `isSticker: true` is what makes the receiver render it bubble-less.
  /// Null when the row is gone.
  static Future<AttachmentContent?> toAttachment(db.SavedStickerMeta meta) async {
    final data = await getStickerData(meta.id);
    if (data == null) return null;
    return AttachmentContent(
      data: data,
      mimeType: meta.mimeType,
      filename: meta.filename,
      isSticker: true,
    );
  }

  /// Remove one sticker from the library.
  static Future<void> deleteSticker(int id) async {
    final deleted = await PublicOS.database.deleteSavedSticker(id);
    Log.d(_tag, deleted > 0 ? 'Deleted sticker $id' : 'Sticker $id not found');
  }
}
