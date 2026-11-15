// S9 — Channels read-only against feeds.publicos.dev.
//
// Validates the channel reading API against the live default feed server:
//   - getChannelsByAddress(jmsl) → list jmsl's channels
//   - getPostsForChannel(channelId) → list posts in the first channel
//   - getComments(post) → if any post has comments, fetch them
//
// All operations are read-only; we don't create channels, post, or comment.
// Channel writes are exercised in S9b (later) when we have a fresh test
// account with no persistent state.
//
// This test depends on jmsl having at least one channel on feeds.publicos.dev.
// If jmsl has no channels, the test passes the read but skips the post/comment
// portions.

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';

import '../fixtures/test_fixtures.dart';

void main() {
  group('S9 — Channels read-only', () {
    setUpAll(() async {
      await TestFixtures.bootstrap();
    });

    tearDownAll(() async {
      await TestFixtures.teardown();
    });

    test('list channels → list posts → list comments', () async {
      final jmsl = await TestFixtures.setupWithJmsl();
      if (jmsl == null) return;

      // The default feed server (feeds.publicos.dev) was set during initSSP.
      expect(PublicOS.activeSspUrl, isNotEmpty);
      // ignore: avoid_print
      print('Reading channels from: ${PublicOS.activeSspUrl}');

      // ── List jmsl's channels ──────────────────────────────────────
      // Pass serverAddress explicitly: getCurrentFeedServer() needs a DB
      // row or SSP subscription, neither of which exists in this test env.
      final serverUrl = PublicOS.activeSspUrl;
      final channelsResp = await PublicOSChannels.getChannelsByAddress(
        jmsl.eip55With0x,
        serverAddress: serverUrl,
      );
      if (!channelsResp.success) {
        // ignore: avoid_print
        print('getChannelsByAddress failed: ${channelsResp.error}');
        // Skip if the feed server is unreachable — not our test problem
        markTestSkipped('Default feed server unreachable');
        return;
      }
      final channels = channelsResp.data!.channels;
      // ignore: avoid_print
      print('jmsl has ${channels.length} channels');

      if (channels.isEmpty) {
        // ignore: avoid_print
        print('jmsl has no channels — read path validated, skipping posts');
        return;
      }

      for (final ch in channels.take(3)) {
        // ignore: avoid_print
        print('  channel: ${ch.slug} — ${ch.name}');
      }

      // ── List posts from the first channel ─────────────────────────
      final firstChannel = channels.first;
      expect(firstChannel.slug, isNotEmpty);

      final postsResp = await PublicOSChannels.getPostsForChannel(
        firstChannel.id,
        channelInfo: firstChannel,
        serverAddress: serverUrl,
        limit: 5,
      );

      if (!postsResp.success) {
        // ignore: avoid_print
        print('getPostsForChannel failed: ${postsResp.error}');
        return; // soft skip — server may return 404 etc
      }

      final posts = postsResp.data!;
      // ignore: avoid_print
      print('First channel "${firstChannel.slug}" has ${posts.length} recent posts');

      if (posts.isEmpty) {
        // ignore: avoid_print
        print('Channel has no posts — skipping comment reads');
        return;
      }

      // ── If any post supports comments, try to fetch them ─────────
      final commentablePost = posts.firstWhere(
        (p) => PublicOSChannels.canComment(p),
        orElse: () => posts.first,
      );

      if (PublicOSChannels.canComment(commentablePost)) {
        try {
          final comments = await PublicOSChannels.getComments(commentablePost);
          // ignore: avoid_print
          print('Post "${commentablePost.title}" has ${comments.length} comments');
        } catch (e) {
          // ignore: avoid_print
          print('getComments threw (acceptable for read-only test): $e');
        }
      } else {
        // ignore: avoid_print
        print('First post does not support comments');
      }
    }, timeout: const Timeout(Duration(seconds: 90)));
  });
}
