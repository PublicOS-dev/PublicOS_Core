import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Child→parent binding preimage: sha256 hex (lowercase) over the exact
/// UTF-8 bytes of a stored `signed_object` string.
///
/// Children (comments / reactions / votes) include this as `target_hash`
/// in their own signed_object, binding them to the parent's *content*
/// rather than only its URL path — re-pointing the child at a different
/// parent breaks the hash even when the path string still matches. The
/// hash covers the blob bytes, NOT the parent's signature: signatures are
/// malleable (same blob, multiple valid encodings) while the stored blob
/// has exactly one byte representation.
String targetHashOf(String signedObjectJson) =>
    sha256.convert(utf8.encode(signedObjectJson)).toString();

/// The acknowledged-edit chain an EDIT blob must carry: the current blob's
/// own `prev_hashes` (all previously acknowledged versions) plus the hash
/// of the current blob itself. Signing this full list is what keeps
/// children bound to ANY prior version verifiable against the latest blob
/// alone. Empty when the object is currently unsigned (nothing to
/// acknowledge).
List<String> chainedPrevHashes(String currentSignedObject) {
  if (currentSignedObject.isEmpty) return const [];
  var prev = const <String>[];
  try {
    final decoded = jsonDecode(currentSignedObject);
    if (decoded is Map<String, dynamic> && decoded['prev_hashes'] is List) {
      prev = (decoded['prev_hashes'] as List).whereType<String>().toList();
    }
  } catch (_) {
    // Unparseable blob — chain just starts at its hash.
  }
  return [...prev, targetHashOf(currentSignedObject)];
}

/// Membership test shared by the reader-side verifiers: does [hash] bind
/// to [parentSignedObject] — equal to the current bytes' hash, or one of
/// the acknowledged prior versions in its prev_hashes?
bool hashAcceptedBy(String parentSignedObject, String? hash) {
  if (hash == null || hash.isEmpty || parentSignedObject.isEmpty) {
    return false;
  }
  if (hash == targetHashOf(parentSignedObject)) return true;
  try {
    final decoded = jsonDecode(parentSignedObject);
    if (decoded is Map<String, dynamic> && decoded['prev_hashes'] is List) {
      return (decoded['prev_hashes'] as List).contains(hash);
    }
  } catch (_) {}
  return false;
}
