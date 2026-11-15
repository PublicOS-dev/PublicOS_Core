import 'dart:convert';

import 'package:flutter/foundation.dart' show compute, debugPrint;
import 'package:wallet/wallet.dart' show EthereumAddress;

import 'package:publicos_core/src/core/extensions/publicos_bsp.dart';
import 'package:publicos_core/src/core/extensions/publicos_ssp.dart';
import 'package:publicos_core/src/models/post.dart';
import 'package:publicos_core/src/utils/channel_url.dart' show postRefOf;

/// Outcome of a post-signature check.
enum PostSignatureState {
  /// The post carries no signature: the author chose not to sign.
  unsigned,

  /// The signature recovers to a key, every signed content field equals the
  /// post as served, and the key is a session key of the signed `author` on
  /// chain.
  checked,

  /// Anything else on a signed post: a missing half, a signature that does
  /// not recover, a content field that differs from the signed object, a key
  /// that is not the author's, or a chain that could not be asked (see
  /// [PostVerificationResult.chainUnavailable]).
  bad,
}

class PostVerificationResult {
  final PostSignatureState state;

  /// The EOA recovered from the signature (lowercase), when it recovered.
  final String? recoveredSigner;

  /// The `author` the signed object names (lowercase), when it parsed.
  final String? author;

  /// True when the verdict is [PostSignatureState.bad] only because the chain
  /// could not answer whether the key belongs to the author. How to mark that
  /// is the client's call.
  final bool chainUnavailable;
  final String reason;

  const PostVerificationResult({
    required this.state,
    this.recoveredSigner,
    this.author,
    this.chainUnavailable = false,
    required this.reason,
  });

  bool get verified => state == PostSignatureState.checked;
  bool get isUnsigned => state == PostSignatureState.unsigned;
  bool get isBad => state == PostSignatureState.bad;

  PostVerificationResult _bad(String reason, {bool chainUnavailable = false}) =>
      PostVerificationResult(
        state: PostSignatureState.bad,
        recoveredSigner: recoveredSigner,
        author: author,
        chainUnavailable: chainUnavailable,
        reason: reason,
      );
}

/// Verifies a [Post]'s signature the way the PublicOS Feed asks a reader to
/// (spec § Signatures):
///
///  1. recover the signer from `signature.value` over the UTF-8 bytes of
///     `signature.object`;
///  2. parse the object and compare every content field with the post as
///     served, as parsed values (`14` equals `14.0`, key order and escaping
///     do not matter): `type`, `title`, `text`, `summary`, `link`,
///     `hero_media`, `support_media`, `audio`, `sensitive`,
///     `date_published`, `author`, `quote`, `in_reply_to`, `target_url`;
///  3. ask the chain whether the signer is a session key of `author`
///     (`AccountManager.getAccountAddressForSession`), cached per key.
///
/// Steps 1 and 2 are pure ([verifyContent]) and run off the UI thread; step 3
/// is a chain read and runs after. The server's `signature.signer` is never
/// consulted: the key is whatever the signature recovers to.
class PostSignatureVerifier {
  /// Session key (lowercase) → the account it belongs to (lowercase), or null
  /// when the chain knows no account for it. Throws when the chain could not
  /// be asked. Replaceable for tests.
  static Future<String?> Function(String signer) sessionAccountResolver =
      _chainSessionAccount;

  static const _zeroAddress = '0x0000000000000000000000000000000000000000';

  static Future<String?> _chainSessionAccount(String signer) async {
    final account = await PublicOSBsp.accountManagerContract
        .getAccountAddressForSession(
            (sessionAddress: EthereumAddress.fromHex(signer)));
    final hex = account.eip55With0x.toLowerCase();
    return hex == _zeroAddress ? null : hex;
  }

  /// One chain lookup per signing key, shared by every post it signed.
  static final Map<String, Future<String?>> _accountBySigner = {};

  /// Forget the cached key → account answers (a session rotation, a test).
  static void clearAccountCache() => _accountBySigner.clear();

  /// The whole check: content, then the chain.
  static Future<PostVerificationResult> verify(Post post) =>
      _checkAuthorOnChain(verifyContent(post));

  /// Steps 1 and 2 only: no network. A `checked` answer here means the
  /// content holds and the key is still to be matched to the author on chain
  /// ([verify] / [verdictOf] do that).
  static PostVerificationResult verifyContent(Post post) {
    final hasSignedObject = post.signedObject?.isNotEmpty ?? false;
    final hasSignature = post.signature?.isNotEmpty ?? false;

    if (!hasSignedObject && !hasSignature) {
      return const PostVerificationResult(
        state: PostSignatureState.unsigned,
        reason: 'This post is not signed.',
      );
    }
    if (!hasSignedObject || !hasSignature) {
      return const PostVerificationResult(
        state: PostSignatureState.bad,
        reason: 'Incomplete signature data.',
      );
    }

    final recovered = PublicOSSsp.recoverEip191Signer(
        post.signedObject!, post.signature!)?.toLowerCase();
    if (recovered == null) {
      return const PostVerificationResult(
        state: PostSignatureState.bad,
        reason: 'Signature could not be recovered.',
      );
    }

    Map<String, dynamic> so;
    try {
      final raw = jsonDecode(post.signedObject!);
      if (raw is! Map<String, dynamic>) {
        return PostVerificationResult(
          state: PostSignatureState.bad,
          recoveredSigner: recovered,
          reason: 'The signed object is not a JSON object.',
        );
      }
      so = raw;
    } catch (e) {
      return PostVerificationResult(
        state: PostSignatureState.bad,
        recoveredSigner: recovered,
        reason: 'The signed object is not valid JSON: $e',
      );
    }

    final author = so['author'] is String
        ? (so['author'] as String).toLowerCase()
        : null;
    final mismatch = _findMismatch(post, so);
    if (mismatch != null) {
      return PostVerificationResult(
        state: PostSignatureState.bad,
        recoveredSigner: recovered,
        author: author,
        reason:
            'Field "$mismatch" does not match the signed object — the post '
            'may have been changed after signing.',
      );
    }

    return PostVerificationResult(
      state: PostSignatureState.checked,
      recoveredSigner: recovered,
      author: author,
      reason: 'Signature verified on this device.',
    );
  }

  /// Step 3: the recovered key must be a session key of the signed author.
  static Future<PostVerificationResult> _checkAuthorOnChain(
      PostVerificationResult content) async {
    if (content.state != PostSignatureState.checked) return content;
    final signer = content.recoveredSigner!;
    final author = content.author;
    if (author == null || !_isAddress(author)) {
      return content._bad('The signed author is not an account address.');
    }
    final String? account;
    // [SIGCHK] tagged logs for diagnosing slow lookups on a bad connection.
    final cached = _accountBySigner.containsKey(signer);
    final sw = Stopwatch()..start();
    debugPrint('[SIGCHK] ask $signer cached=$cached');
    try {
      account = await (_accountBySigner[signer] ??=
          sessionAccountResolver(signer));
      debugPrint('[SIGCHK] done $signer -> $account in ${sw.elapsedMilliseconds} ms');
    } catch (e) {
      debugPrint('[SIGCHK] FAIL $signer after ${sw.elapsedMilliseconds} ms: $e');
      _accountBySigner.remove(signer);
      return content._bad(
        'The chain could not be asked whether the signing key belongs to '
        'the author ($e).',
        chainUnavailable: true,
      );
    }
    if (account == null) {
      return content._bad('The signing key belongs to no account on chain.');
    }
    if (account.toLowerCase() != author) {
      return content._bad(
          'The signing key belongs to $account, not to the author $author.');
    }
    return content;
  }

  /// The verdict a card can read with no crypto at all:
  /// [PostSignatureState.unsigned] when the post carries no signature data,
  /// else null (a signed post: ask [verdictOf]).
  static PostSignatureState? quickState(Post post) {
    final none = (post.signedObject?.isEmpty ?? true) &&
        (post.signature?.isEmpty ?? true);
    return none ? PostSignatureState.unsigned : null;
  }

  static final Expando<Future<PostVerificationResult>> _verdicts =
      Expando<Future<PostVerificationResult>>('postSignatureVerdict');

  /// The verdict, computed ONCE per [Post] instance and shared by every
  /// reader of it: verified at arrival, then passed along already
  /// checked, so views only display the status. Unsigned posts answer
  /// at once; signed posts run ecRecover + the content check off the UI
  /// thread through [compute] (pure-Dart secp256k1 is tens of ms per post,
  /// and a feed page is fifty of them), then the chain lookup, cached per
  /// key, on this isolate. The feed cache re-parses the raw body on every
  /// read, so a cached page is a fresh arrival too.
  static Future<PostVerificationResult> verdictOf(Post post) {
    final existing = _verdicts[post];
    if (existing != null) return existing;
    final Future<PostVerificationResult> f;
    if (quickState(post) == PostSignatureState.unsigned) {
      f = Future.value(verifyContent(post));
    } else {
      f = compute(_verifyContentJson, post.toJson()).then(_checkAuthorOnChain);
    }
    _verdicts[post] = f;
    return f;
  }

  /// Isolate entry: rebuild the post from its lossless [Post.toJson] blob
  /// and run the pure half there.
  static PostVerificationResult _verifyContentJson(Map<String, dynamic> json) =>
      verifyContent(Post.fromJson(json));

  static bool _isAddress(String s) =>
      RegExp(r'^0x[0-9a-f]{40}$').hasMatch(s);

  /// The first signed content field that differs from the post as served, or
  /// null when every field agrees.
  static String? _findMismatch(Post post, Map<String, dynamic> so) {
    if (so['type'] != 'post') return 'type';
    if (!_textEquals(post.title, so['title'])) return 'title';
    if (!_textEquals(post.contentText, so['text'])) return 'text';
    if (!_textEquals(post.summary, so['summary'])) return 'summary';
    if (!_textEquals(post.externalUrl, so['link'])) return 'link';
    if (!_mediaListEquals(post.heroMedia, so['hero_media'])) {
      return 'hero_media';
    }
    if (!_mediaListEquals(post.supportMedia, so['support_media'])) {
      return 'support_media';
    }
    if (!_mediaEquals(post.audio, so['audio'])) return 'audio';
    if (!_sensitiveEquals(post.sensitive, so['sensitive'])) return 'sensitive';
    if (!_dateEquals(post.createdAt, so['date_published'])) {
      return 'date_published';
    }
    if (!_authorEquals(post, so['author'])) return 'author';
    if (!_pointerEquals(post.quote, so['quote'])) return 'quote';
    if (!_pointerEquals(post.inReplyTo, so['in_reply_to'])) {
      return 'in_reply_to';
    }
    if (!_targetEquals(post, so['target_url'])) return 'target_url';
    return null;
  }

  /// Text fields: null and "" are both absent (an empty value is never
  /// written into the signed object).
  static bool _textEquals(String? postSide, dynamic blobSide) {
    final postAbsent = postSide == null || postSide.isEmpty;
    final blobAbsent =
        blobSide == null || (blobSide is String && blobSide.isEmpty);
    if (postAbsent && blobAbsent) return true;
    if (postAbsent != blobAbsent) return false;
    return blobSide is String && postSide == blobSide;
  }

  /// Numbers compared as values: `14` equals `14.0`.
  static bool _numEquals(num? postSide, dynamic blobSide) {
    if (postSide == null && blobSide == null) return true;
    if (postSide == null || blobSide is! num) return false;
    return postSide.toDouble() == blobSide.toDouble();
  }

  static bool _boolEquals(bool postSide, dynamic blobSide) =>
      postSide == (blobSide == true);

  static bool _mediaListEquals(List<PostMedia> postSide, dynamic blobSide) {
    final blobAbsent = blobSide == null || (blobSide is List && blobSide.isEmpty);
    if (postSide.isEmpty && blobAbsent) return true;
    if (postSide.isEmpty != blobAbsent) return false;
    if (blobSide is! List || blobSide.length != postSide.length) return false;
    for (var i = 0; i < postSide.length; i++) {
      if (!_mediaEquals(postSide[i], blobSide[i])) return false;
    }
    return true;
  }

  static bool _mediaEquals(PostMedia? m, dynamic blobSide) {
    final blobAbsent = blobSide == null || (blobSide is Map && blobSide.isEmpty);
    if (m == null && blobAbsent) return true;
    if ((m == null) != blobAbsent) return false;
    if (blobSide is! Map) return false;
    return _textEquals(m!.url, blobSide['url']) &&
        _textEquals(m.mimeType, blobSide['mime_type']) &&
        _textEquals(m.sha256, blobSide['sha256']) &&
        _numEquals(m.sizeInBytes, blobSide['size_in_bytes']) &&
        _numEquals(m.width, blobSide['width']) &&
        _numEquals(m.height, blobSide['height']) &&
        _textEquals(m.thumbnailUrl, blobSide['thumbnail_url']) &&
        _numEquals(m.durationInSeconds, blobSide['duration_in_seconds']) &&
        _textEquals(m.title, blobSide['title']) &&
        _textEquals(m.alt, blobSide['alt']) &&
        _boolEquals(m.loop, blobSide['loop']);
  }

  /// `sensitive` is the one signed key where `false` is written: present on
  /// one side and absent on the other is a mismatch.
  static bool _sensitiveEquals(bool? postSide, dynamic blobSide) {
    if (postSide == null) return blobSide == null;
    return blobSide is bool && blobSide == postSide;
  }

  /// `date_published`: the same instant, however either side writes it.
  static bool _dateEquals(DateTime createdAt, dynamic blobSide) {
    if (blobSide is! String) return false;
    final signed = DateTime.tryParse(blobSide);
    return signed != null && signed.isAtSameMomentAs(createdAt);
  }

  /// `author`: the account the post names ([Post.postAuthorAddress] on a
  /// signed post; the author line as written otherwise), lowercase.
  static bool _authorEquals(Post post, dynamic blobSide) {
    if (blobSide is! String || blobSide.isEmpty) return false;
    final shown = post.postAuthorAddress ?? post.authorName;
    return shown != null && shown.toLowerCase() == blobSide.toLowerCase();
  }

  static bool _pointerEquals(PostPointer? p, dynamic blobSide) {
    final blobAbsent = blobSide == null || (blobSide is Map && blobSide.isEmpty);
    if (p == null && blobAbsent) return true;
    if ((p == null) != blobAbsent) return false;
    if (blobSide is! Map) return false;
    return _textEquals(p!.url, blobSide['url']) &&
        _textEquals(p.hash, blobSide['hash']);
  }

  /// `target_url` is `/api/<owner>/channels/<slug>/posts`, the channel the
  /// post was posted to. Checked against the post's own permalink when it has
  /// one, so a server cannot move a signed post into another channel.
  static bool _targetEquals(Post post, dynamic blobSide) {
    if (blobSide is! String || blobSide.isEmpty) return false;
    final url = post.url;
    if (url == null) return true;
    final ref = postRefOf(url);
    if (ref == null) return true;
    final signedPath = Uri.tryParse(blobSide)?.path ?? blobSide;
    final want = '/api/${ref.owner}/channels/${ref.slug}/posts';
    return signedPath.toLowerCase() == want.toLowerCase();
  }
}
