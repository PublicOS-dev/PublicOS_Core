// The bookmark round-trip gate.
//
// A bookmark is a full signed shareable object: `jsonEncode(post.toJson())`
// goes into the drift blob and `Post.fromJson` must rebuild the identical
// post — every field, no exceptions. Against the pre-fix code (blobs read
// through the feed factory) this property failed on 10 fields, which is
// exactly the bug that made bookmarked posts lose comments, reactions, and
// their own identity key.
//
// If you add a field to Post: it must land in toJson, fromJson, and copyWith
// together, and this test's `_fullPost` must populate it — a field this test
// never sees is a field the round-trip can silently lose again.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';

Post _fullPost() => Post(
      uid: 'a3f2c882-1111-2222-3333-444455556666',
      accountId: 7,
      channelId: 12,
      title: 'A fully populated post',
      contentText: 'Body text with unicode — áéí 🌵',
      summary: 'Short summary',
      externalUrl: 'https://example.com/article',
      language: 'es',
      tags: ['one', 'two'],
      authors: [
        PostAuthor(
          name: '0x1234567890abcdef1234567890abcdef12345678',
          url: 'publicos.dev/0x1234567890abcdef1234567890abcdef12345678',
          avatar: 'https://cdn.example.com/avatar.png',
        ),
      ],
      heroMedia: [
        PostMedia(
          url: 'https://cdn.example.com/clip.mp4',
          mimeType: 'video/mp4',
          sha256: 'ab' * 32,
          sizeInBytes: 2097152,
          width: 1080,
          height: 1920,
          thumbnailUrl: 'https://cdn.example.com/clip.mp4/poster',
          durationInSeconds: 14.2,
          loop: true,
        ),
        PostMedia(
          url: 'https://cdn.example.com/img.jpg',
          mimeType: 'image/jpeg',
          sha256: 'cd' * 32,
          width: 1080,
          height: 1350,
          alt: 'a cactus',
        ),
      ],
      supportMedia: [
        PostMedia(
          url: 'https://cdn.example.com/notes.pdf',
          mimeType: 'application/pdf',
          sha256: 'ef' * 32,
          sizeInBytes: 1048576,
          title: 'notes',
        ),
      ],
      audio: PostMedia(
        url: 'https://cdn.example.com/track.m4a',
        mimeType: 'audio/mp4',
        sha256: '01' * 32,
        durationInSeconds: 61,
        loop: true,
      ),
      mediaPost: true,
      sensitive: false,
      commentPolicy: 'open',
      requireVerifiedComments: true,
      reactionPolicy: 'closed',
      requireVerifiedReactions: false,
      signature: '0xdeadbeef',
      signedObject: '{"author":"0x1234","type":"post"}',
      signerAddress: '0x1234567890abcdef1234567890abcdef12345678',
      createdAt: DateTime(2026, 7, 16, 12, 34, 56, 789),
      dateModified: DateTime(2026, 7, 17, 1, 2, 3),
      dateReceived: DateTime(2026, 7, 16, 12, 34, 58),
      receipt: const PostReceipt(
          object: '{"type":"receipt"}', value: '0x5d0a', signer: '0x3e7b'),
      quote: PostPointer(
          url: 'https://ssp.example/api/0xq/channels/q/posts/1',
          hash: '91c2' * 16),
      inReplyTo: const PostPointer(
          url: 'https://ssp.example/api/0xr/channels/r/posts/2'),
      collaborators: const ['0x7c3b2a1f9e8d7c6b5a4f3e2d1c0b9a8f7e6d5c4b'],
      acknowledgments: const [
        PostAcknowledgment(
            object: '{"type":"acknowledge"}', value: '0x2b7e', signer: '0x0f13'),
      ],
      commentsCount: 5,
      commentsUrl:
          'https://ssp.example.com/api/0xOwner/channels/daily/posts/a3f2/comments',
      reactions: 'heart:3,fire:1',
      reactionsUrl:
          'https://ssp.example.com/api/0xOwner/channels/daily/posts/a3f2/reactions',
      interactionsUrl:
          'https://ssp.example.com/api/0xOwner/channels/daily/posts/a3f2/interactions',
      score: 9,
      upvotes: 11,
      downvotes: 2,
      userVote: 1,
      viewerReactions: const ['heart'],
      canCommentAnswer: true,
      canReactAnswer: false,
      postAuthorAddress: '0x1234567890abcdef1234567890abcdef12345678',
      feedFoundAtAccountAddress: '0xAAAA567890abcdef1234567890abcdef12345678',
      feedRecordKey: 'rss.daily',
      feedTitle: 'The Daily',
      feedUrl: 'https://ssp.example.com/api/0xOwner/channels/daily/json',
      channelSlug: 'daily',
      channelOwnerAddress: '0xBBBB567890abcdef1234567890abcdef12345678',
      isForumChannel: true,
      serverAddress: 'https://ssp.example.com',
      url: 'https://ssp.example.com/api/0xOwner/channels/daily/posts/a3f2',
    );

void _expectSameMedia(List<PostMedia> back, List<PostMedia> original) {
  expect(back.length, original.length);
  for (var i = 0; i < original.length; i++) {
    expect(back[i].toJson(), original[i].toJson());
  }
}

void _expectSamePost(Post back, Post original) {
  expect(back.uid, original.uid);
  expect(back.accountId, original.accountId);
  expect(back.channelId, original.channelId);
  expect(back.title, original.title);
  expect(back.contentText, original.contentText);
  expect(back.summary, original.summary);
  expect(back.externalUrl, original.externalUrl);
  expect(back.language, original.language);
  expect(back.tags, original.tags);
  expect(back.authors?.length, original.authors?.length);
  for (var i = 0; i < (original.authors?.length ?? 0); i++) {
    expect(back.authors![i].toJson(), original.authors![i].toJson());
  }
  _expectSameMedia(back.heroMedia, original.heroMedia);
  _expectSameMedia(back.supportMedia, original.supportMedia);
  expect(back.audio?.toJson(), original.audio?.toJson());
  expect(back.mediaPost, original.mediaPost);
  expect(back.sensitive, original.sensitive);
  expect(back.commentPolicy, original.commentPolicy);
  expect(back.requireVerifiedComments, original.requireVerifiedComments);
  expect(back.reactionPolicy, original.reactionPolicy);
  expect(back.requireVerifiedReactions, original.requireVerifiedReactions);
  expect(back.signature, original.signature);
  expect(back.signedObject, original.signedObject);
  expect(back.signerAddress, original.signerAddress);
  expect(back.createdAt, original.createdAt);
  expect(back.dateModified, original.dateModified);
  expect(back.dateReceived, original.dateReceived);
  expect(back.receipt?.toJson(), original.receipt?.toJson());
  expect(back.quote?.toJson(), original.quote?.toJson());
  expect(back.inReplyTo?.toJson(), original.inReplyTo?.toJson());
  expect(back.collaborators, original.collaborators);
  expect(back.acknowledgments.map((a) => a.toJson()).toList(),
      original.acknowledgments.map((a) => a.toJson()).toList());
  expect(back.commentsCount, original.commentsCount);
  expect(back.commentsUrl, original.commentsUrl);
  expect(back.reactions, original.reactions);
  expect(back.reactionsUrl, original.reactionsUrl);
  expect(back.interactionsUrl, original.interactionsUrl);
  expect(back.score, original.score);
  expect(back.upvotes, original.upvotes);
  expect(back.downvotes, original.downvotes);
  expect(back.userVote, original.userVote);
  expect(back.viewerReactions, original.viewerReactions);
  expect(back.canCommentAnswer, original.canCommentAnswer);
  expect(back.canReactAnswer, original.canReactAnswer);
  expect(back.postAuthorAddress, original.postAuthorAddress);
  expect(
      back.feedFoundAtAccountAddress, original.feedFoundAtAccountAddress);
  expect(back.feedRecordKey, original.feedRecordKey);
  expect(back.feedTitle, original.feedTitle);
  expect(back.feedUrl, original.feedUrl);
  expect(back.channelSlug, original.channelSlug);
  expect(back.channelOwnerAddress, original.channelOwnerAddress);
  expect(back.isForumChannel, original.isForumChannel);
  expect(back.serverAddress, original.serverAddress);
  expect(back.url, original.url);
}

void main() {
  group('Post round-trip (toJson → fromJson)', () {
    test('fully populated post survives losslessly', () {
      final original = _fullPost();
      final back = Post.fromJson(original.toJson());
      _expectSamePost(back, original);
    });

    test('survives the actual storage path (jsonEncode → jsonDecode)', () {
      final original = _fullPost();
      final blob = jsonEncode(original.toJson());
      final back = Post.fromJson(jsonDecode(blob) as Map<String, dynamic>);
      _expectSamePost(back, original);
    });

    test('minimal post: absent fields stay null, defaults hold', () {
      final original = Post(
        title: 'Bare external post',
        createdAt: DateTime(2026, 1, 2, 3, 4, 5),
      );
      final back = Post.fromJson(
          jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>);
      _expectSamePost(back, original);
      expect(back.uid, '');
      expect(back.score, 0);
      expect(back.heroMedia, isEmpty);
      expect(back.supportMedia, isEmpty);
      expect(back.audio, isNull);
      expect(back.mediaPost, isFalse);
      expect(back.sensitive, isNull);
      expect(back.commentsUrl, isNull);
      expect(back.reactionsUrl, isNull);
    });

    test('toJson emits every field the model carries (map-level identity)',
        () {
      final original = _fullPost();
      final once = original.toJson();
      final twice = Post.fromJson(once).toJson();
      expect(twice, once);
    });
  });

  group('PostMedia.toJson', () {
    test('keys are alphabetical and a whole duration is an integer', () {
      final m = PostMedia(
        url: 'https://x/a.mp4',
        mimeType: 'video/mp4',
        sha256: 'ab' * 32,
        width: 1,
        height: 2,
        durationInSeconds: 17.0,
      );
      final keys = m.toJson().keys.toList();
      expect(keys, [...keys]..sort());
      expect(jsonEncode(m.toJson()), contains('"duration_in_seconds":17,'));
      expect(jsonEncode(m.toJson()), isNot(contains('17.0')));
    });

    test('a fractional duration stays fractional; empty values are absent',
        () {
      const m = PostMedia(
          url: 'u', mimeType: 'audio/mp4', durationInSeconds: 14.2);
      final j = m.toJson();
      expect(j['duration_in_seconds'], 14.2);
      expect(j.containsKey('loop'), isFalse);
      expect(j.containsKey('sha256'), isFalse);
    });
  });

  group('Post getters over the media lists', () {
    test('bannerImage is the first hero; carousel items are the support list',
        () {
      final p = _fullPost();
      expect(p.bannerImage, 'https://cdn.example.com/clip.mp4');
      expect(p.carouselItems.map((i) => i.url),
          ['https://cdn.example.com/notes.pdf']);
      expect(p.carouselItems.single.isFile, isTrue);
      expect(p.carouselImages, isEmpty, reason: 'a PDF is not renderable media');
    });

    test('a post with no hero has no banner', () {
      expect(Post(title: 't', createdAt: DateTime(2026)).bannerImage, isNull);
    });
  });

  group('withInteractionUrls', () {
    test('stamps both URLs together from the same base', () {
      final post = Post(
        uid: 'abc',
        title: 't',
        createdAt: DateTime(2026),
      ).withInteractionUrls(
        baseUrl: 'https://ssp.example.com',
        ownerAddress: '0xOwner',
        slug: 'daily',
      );
      expect(post.commentsUrl,
          'https://ssp.example.com/api/0xOwner/channels/daily/posts/abc/comments');
      expect(post.reactionsUrl,
          'https://ssp.example.com/api/0xOwner/channels/daily/posts/abc/reactions');
    });

    test('no-op for uid-less external posts', () {
      final post = Post(
        title: 'rss item',
        createdAt: DateTime(2026),
      ).withInteractionUrls(
        baseUrl: 'https://ssp.example.com',
        ownerAddress: '0xOwner',
        slug: 'daily',
      );
      expect(post.commentsUrl, isNull);
      expect(post.reactionsUrl, isNull);
    });

    test('existing values win, missing sibling still fills', () {
      final post = Post(
        uid: 'abc',
        title: 't',
        createdAt: DateTime(2026),
        commentsUrl: 'https://already.example.com/comments',
      ).withInteractionUrls(
        baseUrl: 'https://ssp.example.com',
        ownerAddress: '0xOwner',
        slug: 'daily',
      );
      expect(post.commentsUrl, 'https://already.example.com/comments');
      expect(post.reactionsUrl,
          'https://ssp.example.com/api/0xOwner/channels/daily/posts/abc/reactions');
    });
  });
}
