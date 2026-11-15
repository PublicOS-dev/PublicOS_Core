import 'dart:convert';

import 'package:publicos_core/src/core/extensions/publicos_ssp.dart';
import 'package:publicos_core/src/models/comment.dart';
import 'package:publicos_core/src/models/post.dart';
import 'package:publicos_core/src/utils/content_hash.dart';

/// Outcome of the signature half of a comment check. Mirrors
/// `PostSignatureState` — children are optional-sign, so unsigned is a
/// legitimate state, not a failure.
enum CommentSignatureState { unsigned, checked, bad }

/// Outcome of the child→parent binding half (single-bind: the ONE target
/// is the direct parent — the parent comment for replies, the post for
/// top-level comments).
enum CommentBindingState {
  /// target_hash equals sha256 of the parent's current signed_object.
  bound,

  /// target_hash matches one of the parent's acknowledged prior versions
  /// (prev_hashes) — written under an earlier version, later legitimately
  /// edited by the parent's author. Neutral: "on an earlier version".
  boundEarlier,

  /// Nothing to bind: the comment is unsigned, the parent is unsigned
  /// (URL is the only targeting an unsigned parent offers), or — for a
  /// reply — the parent comment wasn't provided to the verifier.
  unbound,

  /// The binding fails: hash absent where the fresh-start contract makes
  /// absence impossible for legitimately-stored rows (signed child of a
  /// signed parent), or a hash that matches neither the current blob nor
  /// any acknowledged version.
  broken,
}

class CommentVerificationResult {
  final CommentSignatureState signature;
  final CommentBindingState binding;
  final String? recoveredSigner;
  final String reason;

  const CommentVerificationResult({
    required this.signature,
    required this.binding,
    this.recoveredSigner,
    required this.reason,
  });

  /// True when the reader should surface a warning affordance.
  bool get isBad =>
      signature == CommentSignatureState.bad ||
      binding == CommentBindingState.broken;
}

/// Verifies a [Comment] against its DIRECT parent on-device:
///   1. ecRecover the EOA that signed [Comment.signedObject], compare to
///      [Comment.signerAddress] (mirrors `PostSignatureVerifier`).
///   2. Cross-check blob.content against the rendered content (the server
///      enforces this at write; readers re-verify — malicious-server case).
///   3. Binding (single-bind): blob.target_hash membership vs the direct
///      parent's {sha256(current blob)} ∪ prev_hashes — the parent comment
///      for replies (pass [replyToParent]), the post for top-level.
///
/// Pure crypto + parse, no network.
class CommentSignatureVerifier {
  static CommentVerificationResult verify(
    Comment comment,
    Post post, {
    Comment? replyToParent,
  }) {
    final hasBlob = comment.signedObject.isNotEmpty;
    final hasSig = comment.contentSignature.isNotEmpty;
    final hasSigner = comment.signerAddress.isNotEmpty;

    if (!hasBlob && !hasSig && !hasSigner) {
      return const CommentVerificationResult(
        signature: CommentSignatureState.unsigned,
        binding: CommentBindingState.unbound,
        reason: 'This comment is not signed.',
      );
    }

    if (!hasBlob || !hasSig || !hasSigner) {
      return const CommentVerificationResult(
        signature: CommentSignatureState.bad,
        binding: CommentBindingState.unbound,
        reason: 'Incomplete signature data.',
      );
    }

    final recovered = PublicOSSsp.recoverEip191Signer(
        comment.signedObject, comment.contentSignature);
    if (recovered == null) {
      return const CommentVerificationResult(
        signature: CommentSignatureState.bad,
        binding: CommentBindingState.unbound,
        reason: 'Signature could not be recovered.',
      );
    }
    if (recovered.toLowerCase() != comment.signerAddress.toLowerCase()) {
      return CommentVerificationResult(
        signature: CommentSignatureState.bad,
        binding: CommentBindingState.unbound,
        recoveredSigner: recovered,
        reason:
            'Recovered signer $recovered does not match ${comment.signerAddress}.',
      );
    }

    Map<String, dynamic> blob;
    try {
      final raw = jsonDecode(comment.signedObject);
      if (raw is! Map<String, dynamic>) {
        return CommentVerificationResult(
          signature: CommentSignatureState.bad,
          binding: CommentBindingState.unbound,
          recoveredSigner: recovered,
          reason: 'signed_object is not a JSON object.',
        );
      }
      blob = raw;
    } catch (e) {
      return CommentVerificationResult(
        signature: CommentSignatureState.bad,
        binding: CommentBindingState.unbound,
        recoveredSigner: recovered,
        reason: 'signed_object is not valid JSON: $e',
      );
    }

    final blobType = blob['type'] as String?;
    if (blobType != 'comment' && blobType != 'edit_comment') {
      return CommentVerificationResult(
        signature: CommentSignatureState.bad,
        binding: CommentBindingState.unbound,
        recoveredSigner: recovered,
        reason: 'signed_object type "$blobType" is not a comment blob.',
      );
    }

    // Content cross-check — skipped for deleted comments, whose content
    // column is replaced by the "[deleted]" placeholder server-side.
    if (!comment.isDeleted && blob['content'] != comment.content) {
      return CommentVerificationResult(
        signature: CommentSignatureState.bad,
        binding: CommentBindingState.unbound,
        recoveredSigner: recovered,
        reason:
            'Rendered content does not match signed_object — comment may '
            'have been tampered with after signing.',
      );
    }

    // Binding half — single-bind membership vs the DIRECT parent.
    final isReply = comment.replyToUid != null;
    final parentBlob =
        isReply ? (replyToParent?.signedObject ?? '') : (post.signedObject ?? '');
    final targetHash = blob['target_hash'] as String?;

    final CommentBindingState binding;
    String bindingNote;
    if (parentBlob.isEmpty) {
      binding = CommentBindingState.unbound;
      bindingNote = isReply && replyToParent == null
          ? 'Parent comment not provided — binding not checked.'
          : 'Parent is unsigned — nothing to bind to (URL-only targeting).';
    } else if (targetHash == null || targetHash.isEmpty) {
      // Fresh-start contract: the server never stores a signed child of a
      // signed parent without a hash — absence here means tampering.
      binding = CommentBindingState.broken;
      bindingNote =
          'Signed comment on a signed parent carries no target_hash — '
          'this row could not have been stored legitimately.';
    } else if (targetHash == targetHashOf(parentBlob)) {
      binding = CommentBindingState.bound;
      bindingNote = 'Bound to the content it was written under.';
    } else if (hashAcceptedBy(parentBlob, targetHash)) {
      binding = CommentBindingState.boundEarlier;
      bindingNote =
          'Written under an earlier version the author has acknowledged.';
    } else {
      binding = CommentBindingState.broken;
      bindingNote =
          'target_hash matches neither the parent\'s current content nor '
          'any acknowledged version — the comment may have been re-pointed.';
    }

    return CommentVerificationResult(
      signature: CommentSignatureState.checked,
      binding: binding,
      recoveredSigner: recovered,
      reason: bindingNote,
    );
  }
}
