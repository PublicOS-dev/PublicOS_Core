import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/src/core/extensions/publicos_ssp.dart';
import 'package:publicos_core/src/core/publicos_core.dart';
import 'package:publicos_core/src/models/post.dart';
import 'package:publicos_core/src/utils/post_signature_verifier.dart';
import 'package:web3dart/web3dart.dart';

// PostSignatureVerifier over PublicOS Feed items (spec § Signatures). Each
// test signs a real object with a throwaway key, serves it as a v1 item
// through `Post.fromFeedV1Item`, and either leaves the item honest
// (→ checked) or bends one field (→ bad). The chain stage runs against an
// injected resolver.

const _privateKey =
    '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';

/// The session key the hardhat key is, lowercase.
const _signer = '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266';

/// The account the key belongs to in these tests (the signed `author`).
const _account = '0x5a1e9c3d4b7f8e2a6c0d1b3f5e7a9c2d4f6b8e0a';
const _other = '0x7c3b2a1f9e8d7c6b5a4f3e2d1c0b9a8f7e6d5c4b';

const _server = 'https://ssp.test';
const _slug = 'fieldnotes';
const _id = '3d5e51cb-d673-4f24-9856-844d427f016e';
const _date = '2026-10-26T16:02:11Z';
const _target = '/api/$_account/channels/$_slug/posts';
const _postUrl = '$_server/api/$_account/channels/$_slug/posts/$_id';

Map<String, dynamic> _hero({String url = 'https://ssp.test/media/a.mp4'}) => {
      'url': url,
      'mime_type': 'video/mp4',
      'sha256': 'ab' * 32,
      'width': 1080,
      'height': 1920,
      'thumbnail_url': '$url/poster',
      'duration_in_seconds': 14,
    };

/// The signed object the composer writes: content + author + date + target +
/// type, canonical JSON.
String _signedObject(Map<String, dynamic> content,
        {String author = _account, String date = _date, String target = _target}) =>
    PublicOSSsp.canonicalJson({
      ...content,
      'author': author,
      'date_published': date,
      'target_url': target,
      'type': 'post',
    });

/// A served item: the content as the server stores it, plus the signature
/// triple. [served] overrides what the server shows (a tampered column).
Post _item(
  Map<String, dynamic> content, {
  Map<String, dynamic> served = const {},
  String author = _account,
  String date = _date,
  String? signedObject,
  String url = _postUrl,
}) {
  final so = signedObject ?? _signedObject(content, author: author, date: date);
  final sig = PublicOSSsp.signMessage(so);
  return Post.fromFeedV1Item({
    'id': _id,
    'url': url,
    'author': author,
    'date_published': date,
    ...content,
    ...served,
    'signature': {'object': so, 'value': sig, 'signer': _signer},
  });
}

void main() {
  setUpAll(() {
    PublicOS.currentBlockchainPrivateKey = EthPrivateKey.fromHex(_privateKey);
  });
  setUp(PostSignatureVerifier.clearAccountCache);
  tearDown(() {
    PostSignatureVerifier.sessionAccountResolver =
        (_) async => throw StateError('no chain in tests');
  });

  group('content check (pure)', () {
    test('unsigned when the item carries no signature', () {
      final p = Post.fromFeedV1Item({
        'id': _id,
        'url': _postUrl,
        'author': 'Ana',
        'date_published': _date,
        'text': 'hello',
      });
      final r = PostSignatureVerifier.verifyContent(p);
      expect(r.state, PostSignatureState.unsigned);
      expect(p.postAuthorAddress, isNull, reason: 'an unsigned author is a string');
      expect(p.authorName, 'Ana');
    });

    test('bad on a partial signature', () {
      final p = Post(
        title: 'half',
        signedObject: '{"type":"post"}',
        createdAt: DateTime.parse(_date),
      );
      expect(PostSignatureVerifier.verifyContent(p).state, PostSignatureState.bad);
    });

    test('checked when every signed field matches the item as served', () {
      final content = {
        'title': 'Three clips',
        'text': 'Three clips from this morning.',
        'summary': 'clips',
        'link': 'https://example.com/story',
        'hero_media': [_hero()],
        'support_media': [
          {'url': 'https://ssp.test/media/n.pdf', 'mime_type': 'application/pdf', 'sha256': 'cd' * 32, 'title': 'notes'},
        ],
        'audio': {'url': 'https://ssp.test/media/t.m4a', 'mime_type': 'audio/mp4', 'sha256': 'ef' * 32, 'duration_in_seconds': 61, 'loop': true},
        'sensitive': false,
        'quote': {'url': '$_server/api/$_other/channels/q/posts/1', 'hash': '91c2' * 16},
        'in_reply_to': {'url': '$_server/api/$_other/channels/q/posts/2'},
      };
      final p = _item(content);
      final r = PostSignatureVerifier.verifyContent(p);
      expect(r.state, PostSignatureState.checked, reason: r.reason);
      expect(r.recoveredSigner, _signer);
      expect(r.author, _account);
      expect(p.postAuthorAddress, _account);
    });

    test('a whole number compares equal to its decimal form (14 == 14.0)', () {
      final content = {'text': 'clip', 'hero_media': [_hero()]};
      final served = {
        'hero_media': [
          {..._hero(), 'duration_in_seconds': 14.0, 'width': 1080.0}
        ]
      };
      final r = PostSignatureVerifier.verifyContent(_item(content, served: served));
      expect(r.state, PostSignatureState.checked, reason: r.reason);
    });

    test('bad when the text was changed after signing', () {
      final r = PostSignatureVerifier.verifyContent(
          _item({'text': 'honest'}, served: {'text': 'TAMPERED'}));
      expect(r.state, PostSignatureState.bad);
      expect(r.reason, contains('"text"'));
    });

    test('bad when a hero URL was swapped', () {
      final r = PostSignatureVerifier.verifyContent(_item(
        {'text': 'clip', 'hero_media': [_hero()]},
        served: {'hero_media': [_hero(url: 'https://evil.test/x.mp4')]},
      ));
      expect(r.state, PostSignatureState.bad);
      expect(r.reason, contains('hero_media'));
    });

    test('bad when a media sha256 was swapped', () {
      final r = PostSignatureVerifier.verifyContent(_item(
        {'text': 'clip', 'hero_media': [_hero()]},
        served: {'hero_media': [{..._hero(), 'sha256': 'ff' * 32}]},
      ));
      expect(r.state, PostSignatureState.bad);
      expect(r.reason, contains('hero_media'));
    });

    test('bad when a media item is added that was not signed', () {
      final r = PostSignatureVerifier.verifyContent(_item(
        {'text': 'no media signed'},
        served: {'support_media': [{'url': 'https://evil.test/s.png', 'mime_type': 'image/png'}]},
      ));
      expect(r.state, PostSignatureState.bad);
      expect(r.reason, contains('support_media'));
    });

    test('bad when the audio track was dropped by the server', () {
      final r = PostSignatureVerifier.verifyContent(_item(
        {'text': 'song', 'audio': {'url': 'https://ssp.test/media/t.m4a', 'mime_type': 'audio/mp4', 'sha256': 'ef' * 32}},
        served: {'audio': null},
      ));
      expect(r.state, PostSignatureState.bad);
      expect(r.reason, contains('audio'));
    });

    test('bad when a sensitive rating was taken off', () {
      final r = PostSignatureVerifier.verifyContent(
          _item({'text': 'x', 'sensitive': true}, served: {'sensitive': null}));
      expect(r.state, PostSignatureState.bad);
      expect(r.reason, contains('sensitive'));
    });

    test('bad when date_published was moved', () {
      final r = PostSignatureVerifier.verifyContent(_item(
        {'text': 'x'},
        served: {'date_published': '2026-10-26T17:02:11Z'},
      ));
      expect(r.state, PostSignatureState.bad);
      expect(r.reason, contains('date_published'));
    });

    test('the same instant in another offset is the same date', () {
      final r = PostSignatureVerifier.verifyContent(_item(
        {'text': 'x'},
        served: {'date_published': '2026-10-26T10:02:11-06:00'},
      ));
      expect(r.state, PostSignatureState.checked, reason: r.reason);
    });

    test('bad when the served author is not the signed author', () {
      final r = PostSignatureVerifier.verifyContent(
          _item({'text': 'x'}, served: {'author': _other}));
      expect(r.state, PostSignatureState.bad);
      expect(r.reason, contains('author'));
    });

    test('bad when the quote pointer was changed', () {
      final r = PostSignatureVerifier.verifyContent(_item(
        {'text': 'x', 'quote': {'url': 'https://a.test/api/$_other/channels/q/posts/1', 'hash': '11' * 32}},
        served: {'quote': {'url': 'https://a.test/api/$_other/channels/q/posts/1', 'hash': '22' * 32}},
      ));
      expect(r.state, PostSignatureState.bad);
      expect(r.reason, contains('quote'));
    });

    test('bad when the post sits in another channel than the one it was signed for', () {
      final r = PostSignatureVerifier.verifyContent(_item(
        {'text': 'x'},
        url: '$_server/api/$_account/channels/other/posts/$_id',
      ));
      expect(r.state, PostSignatureState.bad);
      expect(r.reason, contains('target_url'));
    });

    test('bad when the signed object is not a post', () {
      final so = PublicOSSsp.canonicalJson({
        'author': _account, 'date_published': _date, 'target_url': _target,
        'type': 'comment', 'text': 'x',
      });
      final r = PostSignatureVerifier.verifyContent(
          _item({'text': 'x'}, signedObject: so));
      expect(r.state, PostSignatureState.bad);
      expect(r.reason, contains('type'));
    });

    test('a signature moved onto another object recovers to a stranger key, and the chain rejects it', () async {
      final good = _signedObject({'text': 'good'});
      final sig = PublicOSSsp.signMessage(good);
      final tampered = _signedObject({'text': 'X'});
      final p = Post.fromFeedV1Item({
        'id': _id, 'url': _postUrl, 'author': _account, 'date_published': _date,
        'text': 'X',
        'signature': {'object': tampered, 'value': sig, 'signer': _signer},
      });
      // ecRecover over other bytes yields SOME key: the content stage alone
      // cannot tell it is nobody's, and never trusts the server's `signer`.
      final content = PostSignatureVerifier.verifyContent(p);
      expect(content.recoveredSigner, isNot(_signer));
      // The chain knows no account for that key: bad.
      PostSignatureVerifier.sessionAccountResolver =
          (signer) async => signer == _signer ? _account : null;
      final r = await PostSignatureVerifier.verify(p);
      expect(r.state, PostSignatureState.bad);
      expect(r.reason, contains('no account'));
    });

    test('key order and escaping in the signed object do not matter', () {
      final so = jsonEncode({
        'type': 'post', 'text': 'café <b>', 'target_url': _target,
        'date_published': _date, 'author': _account,
      });
      final r = PostSignatureVerifier.verifyContent(
          _item({'text': 'café <b>'}, signedObject: so));
      expect(r.state, PostSignatureState.checked, reason: r.reason);
    });
  });

  group('chain stage', () {
    final content = {'text': 'on chain'};

    test('checked when the key is a session key of the author', () async {
      PostSignatureVerifier.sessionAccountResolver = (signer) async {
        expect(signer, _signer);
        return _account;
      };
      final r = await PostSignatureVerifier.verify(_item(content));
      expect(r.state, PostSignatureState.checked, reason: r.reason);
    });

    test("bad when the key belongs to another account", () async {
      PostSignatureVerifier.sessionAccountResolver = (_) async => _other;
      final r = await PostSignatureVerifier.verify(_item(content));
      expect(r.state, PostSignatureState.bad);
      expect(r.chainUnavailable, isFalse);
      expect(r.reason, contains(_other));
    });

    test('bad when the key belongs to no account', () async {
      PostSignatureVerifier.sessionAccountResolver = (_) async => null;
      final r = await PostSignatureVerifier.verify(_item(content));
      expect(r.state, PostSignatureState.bad);
      expect(r.reason, contains('no account'));
    });

    test('bad, marked chainUnavailable, when the chain cannot be asked', () async {
      PostSignatureVerifier.sessionAccountResolver =
          (_) async => throw Exception('rpc down');
      final r = await PostSignatureVerifier.verify(_item(content));
      expect(r.state, PostSignatureState.bad);
      expect(r.chainUnavailable, isTrue);
      expect(r.reason, contains('could not be asked'));
    });

    test('a failed lookup is not cached; the next one asks again', () async {
      var calls = 0;
      PostSignatureVerifier.sessionAccountResolver = (_) async {
        calls++;
        if (calls == 1) throw Exception('rpc down');
        return _account;
      };
      expect((await PostSignatureVerifier.verify(_item(content))).state,
          PostSignatureState.bad);
      expect((await PostSignatureVerifier.verify(_item(content))).state,
          PostSignatureState.checked);
      expect(calls, 2);
    });

    test('one lookup per key, shared by every post it signed', () async {
      var calls = 0;
      PostSignatureVerifier.sessionAccountResolver = (_) async {
        calls++;
        return _account;
      };
      await PostSignatureVerifier.verify(_item(content));
      await PostSignatureVerifier.verify(_item({'text': 'another'}));
      expect(calls, 1);
    });

    test('a signed author that is not an address never reaches the chain', () async {
      PostSignatureVerifier.sessionAccountResolver =
          (_) async => fail('must not be asked');
      final r = await PostSignatureVerifier.verify(_item(content, author: 'Ana'));
      expect(r.state, PostSignatureState.bad);
      expect(r.reason, contains('not an account address'));
    });

    test('the unsigned post never reaches the chain either', () async {
      PostSignatureVerifier.sessionAccountResolver =
          (_) async => fail('must not be asked');
      final r = await PostSignatureVerifier.verify(
          Post(title: 'plain', createdAt: DateTime.parse(_date)));
      expect(r.state, PostSignatureState.unsigned);
    });
  });
}
