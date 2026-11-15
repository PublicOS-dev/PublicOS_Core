import 'post.dart';
import 'feed_server/feed_server_models.dart';

/// The network trending lists (my_rss_server network stats, Explore).
///
/// Every 10 minutes the registered SSPs agree on the most read, most commented
/// and most reacted posts and channels over four rolling windows. The user's
/// own SSP copies the top entries from the servers that host them and serves
/// them at `GET /api/stats/trending/feed`, so Explore fills with one call.
/// Reading this list records nothing; opening an item goes to its own server,
/// which is where the read counts.

/// The four windows, as the server names them.
abstract final class TrendingCut {
  static const now = 'now'; // the last 10 minutes
  static const hour = 'hour';
  static const h12 = '12h';
  static const h24 = '24h';
  static const all = [now, hour, h12, h24];
}

/// The three lists of each window.
abstract final class TrendingMetric {
  static const readers = 'readers';
  static const comments = 'comments';
  static const reactions = 'reactions';
}

/// One trending post: the post as its own server emits it (with comments,
/// reactions and feed URLs pointing home), plus the network's count.
class TrendingPost {
  final Post post;

  /// The count for the list asked for (readers, comments or reactions).
  final int value;

  /// Slug of the SSP that hosts the post (its owner of record).
  final String ssp;

  /// That SSP passed this round's spot check and has no recent fail.
  final bool verified;

  const TrendingPost({
    required this.post,
    required this.value,
    required this.ssp,
    required this.verified,
  });
}

/// One trending channel: its channel object from its own server, plus the
/// network's count.
class TrendingChannel {
  final Channel channel;
  final String ownerAddress;

  /// The channel URL on its own server (`…/api/<owner>/channels/<slug>`).
  final String channelUrl;

  final int value;
  final String ssp;
  final bool verified;

  const TrendingChannel({
    required this.channel,
    required this.ownerAddress,
    required this.channelUrl,
    required this.value,
    required this.ssp,
    required this.verified,
  });

  /// The JSON Feed on the channel's own server: reading it counts there.
  String get feedUrl => '$channelUrl/json';
}

/// One trending list, for one window and one metric.
class TrendingList<T> {
  /// The network round the list comes from (closes every 10 minutes).
  final int round;
  final DateTime closedAt;

  /// The window: one of [TrendingCut.all].
  final String cut;
  final String metric;
  final List<T> items;

  const TrendingList({
    required this.round,
    required this.closedAt,
    required this.cut,
    required this.metric,
    required this.items,
  });
}
