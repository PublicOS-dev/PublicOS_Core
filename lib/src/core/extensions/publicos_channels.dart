import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:publicos_core/src/core/publicos_core.dart';
import 'package:publicos_core/src/core/extensions/publicos_channel_signin.dart';
import 'package:publicos_core/src/core/extensions/publicos_contacts.dart';
import 'package:publicos_core/src/core/extensions/publicos_ssp.dart';
import 'package:publicos_core/src/models/feed_server/feed_server_models.dart';
import 'package:publicos_core/src/models/post.dart';
import 'package:publicos_core/src/models/comment.dart';
import 'package:publicos_core/src/models/reaction.dart';
import 'package:publicos_core/src/models/trending.dart';
import 'package:publicos_core/src/utils/rss_parser.dart';
import 'package:publicos_core/src/utils/content_hash.dart';
import 'package:publicos_core/src/utils/channel_url.dart';
import 'package:publicos_core/src/utils/log.dart';


/// Unified channel extension for PublicOS.
/// Handles channel (feed + forum) and post management with the social server.
/// All API routes use /channels/ instead of /feeds/ or /forums/.
extension PublicOSChannels on PublicOS {
  static const _tag = 'Channels';


  ///*********************************************
  /// CHANNEL MANAGEMENT
  ///*********************************************

  /// GET /api/<owner>/channels/<slug> — the channel OBJECT:
  /// the same row the listing returns,
  /// for surfaces that are NOT reading the feed — the list manager, profile
  /// tabs, channel settings. Not a read event on the server. Signs a
  /// `list_channels` envelope under the same per-channel rule as a read, so a
  /// denied channel never learns who is asking. Anonymous still gets every
  /// public fact (is_private, is_paid, read_identity, access_entries,
  /// post_count); signed adds follow_status and subscription.
  static Future<FeedServerApiResponse<Channel>> getChannel({
    required String ownerAddress,
    required String slug,
    String? serverAddress,
  }) async {
    try {
      final base = await PublicOSSsp.resolveBaseUrl(serverAddress);
      if (base.isEmpty) {
        return FeedServerApiResponse.error(
            {'code': 'NO_SERVER', 'message': 'No server available'});
      }
      final url = '$base/api/$ownerAddress/channels/$slug';
      final wantSigned = await PublicOSChannelSignin.shouldSign(url);
      final response = wantSigned
          ? await PublicOSSsp.signedRequestAtUrl(
              method: 'GET',
              url: url,
              action: 'list_channels',
            )
          : await http
              .get(Uri.parse(url))
              .timeout(PublicOS.serverRequestTimeout);
      if (response.statusCode != 200) {
        Map<String, dynamic>? err;
        try {
          err = (jsonDecode(response.body)['error'] as Map?)
              ?.cast<String, dynamic>();
        } catch (_) {}
        return FeedServerApiResponse.error(err ??
            {
              'code': 'HTTP_${response.statusCode}',
              'message': 'channel object read failed'
            });
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = data['channel'];
      if (raw is! Map) {
        return FeedServerApiResponse.error(
            {'code': 'BAD_RESPONSE', 'message': 'no channel object in body'});
      }
      return FeedServerApiResponse.success(
        Channel.fromJson(raw.cast<String, dynamic>(), serverAddress: base)
            .copyWith(ownerAddress: ownerAddress),
      );
    } catch (e) {
      return FeedServerApiResponse.error(
          {'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Get list of user's channels (requires authentication)
  static Future<FeedServerApiResponse<ChannelListResponse>> getChannels({String? serverAddress}) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated or no publicos address'});
      }

      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final response = await PublicOSSsp.signedRequest(
        method: 'GET',
        endpoint: '/api/$accountAddress/channels',
        action: 'list_channels',
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final channelsResponse = ChannelListResponse.fromJson(data);
        // Set ownerAddress on own channels
        final ownChannels = channelsResponse.channels
            .map((ch) => ch.copyWith(ownerAddress: accountAddress))
            .toList();
        return FeedServerApiResponse.success(
          ChannelListResponse(channels: ownChannels, count: channelsResponse.count),
        );
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Get channels for a specific account address.
  ///
  /// Anonymous (default): public endpoint. Returns the channel list with no
  /// per-user `follow_status` — that field is omitted across the response.
  ///
  /// Authenticated ([asSigner] = true): the call sends a signed envelope
  /// (`action: 'list_channels'`) so the server can populate `follow_status`
  /// for the signer on each private channel. Without signing, no
  /// per-user state surfaces, so a caller cannot ask about anyone else.
  ///
  /// `follow_status` values when present:
  ///   - `'blocked'` — signer is on the channel/account-wide blacklist
  ///   - `'approved'` — signer has an active whitelist row
  ///   - `'pending'` — most-recent FollowRequest is pending OR ignored
  ///     (collapsed; ignored is owner-only metadata)
  ///   - omitted — no relationship, or zombie-approved-with-no-whitelist
  ///
  /// The whitelist/blacklist match runs both directly against the signer's
  /// session address AND against their resolved PublicOS account, so
  /// listing an account address grants access to all its sessions.
  ///
  /// Returns a record with the channel list and the server-side
  /// [FeedAccount] object embedded in the response.
  static Future<
      FeedServerApiResponse<
          ({List<Channel> channels, FeedAccount? account})>> getChannelsByAddress(
    String accountAddress, {
    String? serverAddress,
    bool asSigner = false,
  }) async {
    try {
      final endpoint = '/api/$accountAddress/channels';

      // Signed → envelope v2 unlocks per-channel `follow_status` and
      // private-channel visibility. Anonymous → public-only filter at
      // the SQL layer (server step A).
      final wantSigned = asSigner &&
          PublicOS.myPublicosAddress != null &&
          PublicOS.currentBlockchainPrivateKey != null;
      final response = wantSigned
          ? await PublicOSSsp.signedRequest(
              method: 'GET',
              endpoint: endpoint,
              action: 'list_channels',
              serverAddress: serverAddress,
            )
          : await PublicOSSsp.makeRequest(
              'GET',
              endpoint,
              serverAddress: serverAddress,
            );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Resolve owner address from account object or URL parameter
        final resolvedOwner = (data['account']?['account_address'] as String?) ?? accountAddress;
        final channelsList = (data['channels'] as List)
            .map((ch) => Channel.fromJson(ch, serverAddress: serverAddress)
                .copyWith(ownerAddress: resolvedOwner))
            .toList();
        final rawAccount = data['account'];
        final account = rawAccount is Map<String, dynamic>
            ? FeedAccount.fromJson(rawAccount)
            : null;
        return FeedServerApiResponse.success((
          channels: channelsList,
          account: account,
        ));
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Get channels from all configured servers (SSP + custom DB servers).
  /// Deduplicates by server URL so SSP and a matching custom server don't double-fetch.
  static Future<FeedServerApiResponse<ChannelListResponse>> getChannelsFromAllServers() async {
    try {
      final servers = await PublicOSSsp.getFeedServers();
      final seenUrls = <String>{};
      List<Channel> allChannels = [];

      // 1. SSP server first
      final sspUrl = await PublicOSSsp.getSSPServerAddress();
      if (sspUrl != null) {
        seenUrls.add(sspUrl);
        try {
          final response = await getChannels(serverAddress: sspUrl);
          if (response.success && response.data != null) {
            final channelsWithServerInfo = response.data!.channels.map((channel) =>
              channel.copyWith(serverAddress: sspUrl)
            ).toList();
            allChannels.addAll(channelsWithServerInfo);
          }
        } catch (e) {
          Log.e(_tag, 'Error getting channels from SSP server $sspUrl: $e');
        }
      }

      // 2. Custom DB servers (skip if URL matches SSP)
      for (final server in servers) {
        if (seenUrls.contains(server.feedServerAddress)) continue;
        seenUrls.add(server.feedServerAddress);
        try {
          final response = await getChannels(serverAddress: server.feedServerAddress);
          if (response.success && response.data != null) {
            final channelsWithServerInfo = response.data!.channels.map((channel) =>
              channel.copyWith(serverAddress: server.feedServerAddress, serverId: server.id)
            ).toList();
            allChannels.addAll(channelsWithServerInfo);
          }
        } catch (e) {
          Log.e(_tag, 'Error getting channels from server ${server.feedServerAddress}: $e');
        }
      }

      if (allChannels.isEmpty && servers.isEmpty && sspUrl == null) {
        return FeedServerApiResponse.error({'code': 'NO_SERVERS', 'message': 'No servers configured'});
      }

      final aggregatedResponse = ChannelListResponse(
        channels: allChannels,
        count: allChannels.length,
      );
      return FeedServerApiResponse.success(aggregatedResponse);
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Create a new channel
  static Future<FeedServerApiResponse<Channel>> createChannel({
    required String name,
    required String description,
    required String slug,
    String? postingPolicy,
    int? maxPosts,
    int? maxDays,
    String? iconUrl,
    String? language,
    bool? isPrivate,
    int? postRateLimit,
    bool? requireRent,
    bool? requireVerifiedRead,
    bool? requireVerifiedPosting,
    bool? requireVerifiedComments,
    // -- The identity ladder. Send these; the four booleans above are the
    // retired shape, kept only so an older server still understands a request.
    // When both arrive the server takes the tier, because a client that knows
    // the new field is the one that knows what it is asking for.
    String? readIdentity,
    String? commentIdentity,
    String? reactionIdentity,
    String? postingIdentity,
    // -- Which lists each gate consults. Independent switches, unioned.
    // is_private is NOT settable any more: the server derives it from the two
    // read switches, so sending it only means anything from an older client.
    bool? readUseFriends,
    bool? readUseChannelList,
    bool? interactUseFriends,
    bool? interactUseChannelList,
    bool? interactUseInteractionList,
    // The listing filter — drops the channel from listings/stats/rankings for
    // everyone but the owner. Orthogonal to the read gate; see Channel.secret.
    bool? secret,
    List<ChannelAccessEntry>? accessEntries,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated or no publicos address'});
      }

      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      // Create data in alphabetical order to match backend JSON marshalling
      final data = <String, dynamic>{
        if (accessEntries != null)
          'access_entries': accessEntries.map((e) => e.toJson()).toList(),
        'description': description,
        if (iconUrl != null) 'icon_url': iconUrl,
        if (isPrivate != null) 'is_private': isPrivate,
        if (language != null) 'language': language,
        if (maxDays != null) 'max_days': maxDays,
        if (maxPosts != null) 'max_posts': maxPosts,
        'name': name,
        if (postRateLimit != null) 'post_rate_limit': postRateLimit,
        if (postingPolicy != null) 'posting_policy': postingPolicy,
        if (requireRent != null) 'require_rent': requireRent,
        if (requireVerifiedComments != null)
          'require_verified_comments': requireVerifiedComments,
        if (requireVerifiedPosting != null)
          'require_verified_posting': requireVerifiedPosting,
        if (requireVerifiedRead != null)
          'require_verified_read': requireVerifiedRead,
        if (readIdentity != null) 'read_identity': readIdentity,
        if (commentIdentity != null) 'comment_identity': commentIdentity,
        if (reactionIdentity != null) 'reaction_identity': reactionIdentity,
        if (postingIdentity != null) 'posting_identity': postingIdentity,
        if (readUseFriends != null) 'read_use_friends': readUseFriends,
        if (readUseChannelList != null)
          'read_use_channel_list': readUseChannelList,
        if (interactUseFriends != null)
          'interact_use_friends': interactUseFriends,
        if (interactUseChannelList != null)
          'interact_use_channel_list': interactUseChannelList,
        if (interactUseInteractionList != null)
          'interact_use_interaction_list': interactUseInteractionList,
        if (secret != null) 'secret': secret,
        'slug': slug,
      };

      final accountAddress = PublicOS.myPublicosAddress!;
      final response = await PublicOSSsp.signedRequest(
        method: 'POST',
        endpoint: '/api/$accountAddress/channels',
        action: 'create_channel',
        data: data,
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final channelData = responseData['channel'];
        if (channelData == null) {
          return FeedServerApiResponse.error({'code': 'INVALID_RESPONSE', 'message': 'No channel data in response'});
        }
        final usedServerAddress = serverAddress ?? (await PublicOSSsp.getCurrentFeedServer())?.feedServerAddress;
        final channel = Channel.fromJson(channelData, serverAddress: usedServerAddress);
        Log.i(_tag, 'Channel created: ${channel.name} (ID: ${channel.id})');
        return FeedServerApiResponse.success(channel);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Update an existing channel
  static Future<FeedServerApiResponse<Channel>> updateChannel({
    required String slug,
    String? name,
    String? description,
    String? newSlug,
    int? maxPosts,
    int? maxDays,
    String? iconUrl,
    String? language,
    bool? isPrivate,
    String? postingPolicy,
    int? postRateLimit,
    bool? requireRent,
    bool? requireVerifiedRead,
    bool? requireVerifiedPosting,
    bool? requireVerifiedComments,
    // -- The identity ladder. Send these; the four booleans above are the
    // retired shape, kept only so an older server still understands a request.
    // When both arrive the server takes the tier, because a client that knows
    // the new field is the one that knows what it is asking for.
    String? readIdentity,
    String? commentIdentity,
    String? reactionIdentity,
    String? postingIdentity,
    // -- Which lists each gate consults. Independent switches, unioned.
    // is_private is NOT settable any more: the server derives it from the two
    // read switches, so sending it only means anything from an older client.
    bool? readUseFriends,
    bool? readUseChannelList,
    bool? interactUseFriends,
    bool? interactUseChannelList,
    bool? interactUseInteractionList,
    // The listing filter — drops the channel from listings/stats/rankings for
    // everyone but the owner. Orthogonal to the read gate; see Channel.secret.
    bool? secret,
    // PublicOS Feed v1: `open` / `closed`.
    String? quotePolicy,
    String? repostPolicy,
    String? replyPolicy,
    List<ChannelAccessEntry>? accessEntries,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated or no publicos address'});
      }

      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;

      // Create data in alphabetical order to match backend JSON marshalling
      final data = <String, dynamic>{};
      // ABSENT ≠ EMPTY, and getting this wrong un-paywalls a channel silently.
      // A null [accessEntries] omits the key, which the server reads as "leave
      // the paywall alone" — so a client patching a description never touches
      // it. An EMPTY list is the only way to express "remove the paywall", and
      // a non-empty one REPLACES the whole set rather than merging into it.
      if (accessEntries != null) {
        data['access_entries'] = accessEntries.map((e) => e.toJson()).toList();
      }
      if (description != null) data['description'] = description;
      if (iconUrl != null) data['icon_url'] = iconUrl;
      if (isPrivate != null) data['is_private'] = isPrivate;
      if (language != null) data['language'] = language;
      if (maxDays != null) data['max_days'] = maxDays;
      if (maxPosts != null) data['max_posts'] = maxPosts;
      if (name != null) data['name'] = name;
      if (postRateLimit != null) data['post_rate_limit'] = postRateLimit;
      if (postingPolicy != null) data['posting_policy'] = postingPolicy;
      if (requireRent != null) data['require_rent'] = requireRent;
      if (requireVerifiedComments != null) {
        data['require_verified_comments'] = requireVerifiedComments;
      }
      if (requireVerifiedPosting != null) {
        data['require_verified_posting'] = requireVerifiedPosting;
      }
      if (requireVerifiedRead != null) {
        data['require_verified_read'] = requireVerifiedRead;
      }
      if (readIdentity != null) data['read_identity'] = readIdentity;
      if (commentIdentity != null) data['comment_identity'] = commentIdentity;
      if (reactionIdentity != null) {
        data['reaction_identity'] = reactionIdentity;
      }
      if (postingIdentity != null) data['posting_identity'] = postingIdentity;
      if (readUseFriends != null) data['read_use_friends'] = readUseFriends;
      if (readUseChannelList != null) {
        data['read_use_channel_list'] = readUseChannelList;
      }
      if (interactUseFriends != null) {
        data['interact_use_friends'] = interactUseFriends;
      }
      if (interactUseChannelList != null) {
        data['interact_use_channel_list'] = interactUseChannelList;
      }
      if (interactUseInteractionList != null) {
        data['interact_use_interaction_list'] = interactUseInteractionList;
      }
      if (secret != null) data['secret'] = secret;
      if (newSlug != null) data['slug'] = newSlug;
      if (quotePolicy != null) data['quote_policy'] = quotePolicy;
      if (repostPolicy != null) data['repost_policy'] = repostPolicy;
      if (replyPolicy != null) data['reply_policy'] = replyPolicy;

      final response = await PublicOSSsp.signedRequest(
        method: 'PUT',
        endpoint: '/api/$accountAddress/channels/$slug',
        action: 'update_channel',
        data: data,
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final channelData = responseData['channel'] ?? responseData;
        return FeedServerApiResponse.success(Channel.fromJson(channelData));
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Delete a channel and all its posts
  static Future<FeedServerApiResponse<bool>> deleteChannel({required String slug, String? serverAddress}) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated or no publicos address'});
      }

      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final response = await PublicOSSsp.signedRequest(
        method: 'DELETE',
        endpoint: '/api/$accountAddress/channels/$slug',
        action: 'delete_channel',
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return FeedServerApiResponse.success(true);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Export channel data
  static Future<FeedServerApiResponse<Map<String, dynamic>>> exportChannel({required String slug, String? serverAddress}) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated or no publicos address'});
      }

      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final response = await PublicOSSsp.signedRequest(
        method: 'GET',
        endpoint: '/api/$accountAddress/channels/$slug/export',
        action: 'export_channel',
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FeedServerApiResponse.success(data);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  ///*********************************************
  /// POST MANAGEMENT
  ///*********************************************

  /// Get posts for a specific channel using cached channel information.
  /// Supports pagination via [offset] and [limit]. Response includes [hasMore].
  ///
  /// Kept for the publicos_desktop fork of posts_list.dart — new code should
  /// call [listChannelPosts]: same endpoint (`/api/<owner>/channels/<slug>/json`,
  /// signed `read_feed`, server-side private gate), plus `?sort=`, minus the
  /// channelId→Channel resolve and the auth requirement.
  @Deprecated('Use listChannelPosts(ownerAddress, slug) — same endpoint, '
      'plus sort, no channelId resolve.')
  static Future<FeedServerApiResponse<List<Post>>> getPostsForChannel(int channelId, {Channel? channelInfo, String? serverAddress, int offset = 0, int limit = 20}) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated or no publicos address'});
      }

      Channel channel;
      if (channelInfo != null) {
        channel = channelInfo;
      } else {
        // Only call getChannels() if we don't have the channel info cached
        final channelsResponse = await getChannels(serverAddress: serverAddress);

        if (!channelsResponse.success) {
          return FeedServerApiResponse.error(channelsResponse.error ?? {'code': 'CHANNEL_LIST_FAILED', 'message': 'Could not get channels list'});
        }

        final foundChannel = channelsResponse.data!.channels.where((ch) => ch.id == channelId).firstOrNull;
        if (foundChannel == null) {
          return FeedServerApiResponse.error({'code': 'CHANNEL_NOT_FOUND', 'message': 'Channel not found'});
        }
        channel = foundChannel;
      }

      final currentUserAddress = PublicOS.myPublicosAddress!;
      // Use channel owner's address for the URL — not the current user's
      final ownerAddress = channel.ownerAddress ?? currentUserAddress;
      return listChannelPosts(
        ownerAddress: ownerAddress,
        slug: channel.slug,
        limit: limit,
        offset: offset,
        serverAddress: serverAddress,
      );
    } catch (e) {
      return FeedServerApiResponse.error({
        'code': 'REQUEST_FAILED',
        'message': e.toString()
      });
    }
  }

  /// List posts in a channel with sorting and pagination.
  /// [sort]: "new" (default), "top", "hot", "controversial"
  ///
  /// Reads the channel's PublicOS Feed document
  /// (`GET /api/<owner>/channels/<slug>/feed`), then the page's interactions
  /// call for the counts and, on a signed read, the reader's own facts
  /// (spec § Interactions). Both sign under the reader's per-channel answer.
  /// `feedFoundAtAccountAddress` is route metadata — on a channel-direct read
  /// the answer is the channel owner.
  static Future<FeedServerApiResponse<List<Post>>> listChannelPosts({
    required String ownerAddress,
    required String slug,
    String sort = 'new',
    int limit = 50,
    int offset = 0,
    String? serverAddress,
  }) async {
    try {
      final baseUrl = await PublicOSSsp.resolveBaseUrl(serverAddress);
      if (baseUrl.isEmpty) {
        return FeedServerApiResponse.error(
            {'code': 'NO_SERVER', 'message': 'No server available'});
      }
      final channelBase = '$baseUrl/api/$ownerAddress/channels/$slug';
      final query = 'sort=$sort&limit=$limit&offset=$offset';
      final documentUrl = '$channelBase/feed?$query';
      // Identity on a READ is the user's per-channel answer.
      final wantSigned = await PublicOSChannelSignin.shouldSign(documentUrl);
      const headers = {'Accept': RssParser.feedAccept};

      final response = wantSigned
          ? await PublicOSSsp.signedRequestAtUrl(
              method: 'GET',
              url: documentUrl,
              action: 'read_feed',
              headers: headers,
            )
          : await http
              .get(Uri.parse(documentUrl), headers: headers)
              .timeout(PublicOS.serverRequestTimeout);

      if (response.statusCode == 200) {
        final doc = jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
        var parsed = RssParser.parseFeedV1(
          doc,
          link: documentUrl,
          feedFoundAtAccountAddress: ownerAddress,
        );
        final interactions = await RssParser.fetchInteractions(
          parsed.interactionsUrl ?? '$channelBase/feed/interactions?$query',
          signed: wantSigned,
        );
        if (interactions != null) parsed = parsed.withInteractions(interactions);

        final posts = [
          for (final post in parsed.posts)
            post.withInteractionUrls(
              baseUrl: baseUrl,
              ownerAddress: ownerAddress,
              slug: slug,
            )
        ];
        return FeedServerApiResponse.success(posts,
            hasMore: parsed.hasMore,
            channelStats: parsed.stats,
            description: parsed.description,
            postingPolicy: parsed.postingPolicy);
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return FeedServerApiResponse.error(
              (errorData['error'] as Map<String, dynamic>?) ??
                  {'code': 'UNKNOWN', 'message': 'Unknown error (status ${response.statusCode})'});
        } catch (_) {
          return FeedServerApiResponse.error(
              {'code': 'UNKNOWN', 'message': 'Failed to fetch channel posts (status ${response.statusCode})'});
        }
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Reads one post from its own permalink ([Post.url],
  /// `<server>/api/<owner>/channels/<slug>/posts/<uid>`). The server is the
  /// URL's own host, never the reader's SSP, and the owner segment is used
  /// verbatim. Same response contract as [getPost]; a URL that isn't a
  /// post permalink answers `BAD_POST_URL` without touching the network.
  static Future<FeedServerApiResponse<Post>> getPostByUrl(
    String url, {
    String? ifNoneMatch,
  }) {
    final ref = postRefOf(url);
    if (ref == null) {
      return Future.value(FeedServerApiResponse.error(
          {'code': 'BAD_POST_URL', 'message': 'Not a post URL: $url'}));
    }
    return getPost(
      ownerAddress: ref.owner,
      slug: ref.slug,
      postUid: ref.uid,
      serverAddress: ref.server,
      ifNoneMatch: ifNoneMatch,
    );
  }

  /// Fetch ONE comment by its anchor URL (`<post url>#comment-<uid>`), the
  /// `item_url` a social notification carries for a comment, a reply or a
  /// comment reaction. `GET …/posts/:uid/comments/:commentUid`:
  /// the popup's preview is
  /// read from where the comment is published, never from the sender. Signs
  /// with `read_feed` when the reader signs that channel, like [getPost].
  static Future<FeedServerApiResponse<Comment>> getCommentByUrl(
      String itemUrl) async {
    const marker = '#comment-';
    final hash = itemUrl.indexOf(marker);
    final ref = hash < 0 ? null : postRefOf(itemUrl.substring(0, hash));
    final commentUid = hash < 0 ? '' : itemUrl.substring(hash + marker.length);
    if (ref == null || commentUid.isEmpty) {
      return FeedServerApiResponse.error(
          {'code': 'BAD_COMMENT_URL', 'message': 'Not a comment URL: $itemUrl'});
    }
    try {
      final baseUrl = await PublicOSSsp.resolveBaseUrl(ref.server);
      if (baseUrl.isEmpty) {
        return FeedServerApiResponse.error(
            {'code': 'NO_SERVER', 'message': 'No server available'});
      }
      final url = '$baseUrl/api/${ref.owner}/channels/${ref.slug}'
          '/posts/${ref.uid}/comments/$commentUid';
      final wantSigned = await PublicOSChannelSignin.shouldSign(url);
      final response = wantSigned
          ? await PublicOSSsp.signedRequestAtUrl(
              method: 'GET', url: url, action: 'read_feed')
          : await http
              .get(Uri.parse(url))
              .timeout(PublicOS.serverRequestTimeout);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return FeedServerApiResponse.success(
            Comment.fromJson(body['comment'] as Map<String, dynamic>));
      }
      final errorData = jsonDecode(response.body);
      return FeedServerApiResponse.error(errorData['error'] ??
          {'code': 'UNKNOWN', 'message': 'Unknown error'});
    } catch (e) {
      return FeedServerApiResponse.error(
          {'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Create a new post in a channel.
  ///
  /// [ownerAddress] — When null, uses current user (owner posting to own channel).
  /// When set, posts to someone else's channel (community posting).
  ///
  /// Fetch ONE post — the server's single-post read
  /// (`GET /api/:owner/channels/:slug/posts/:uid`): the same PublicOS Feed
  /// item the channel document carries, then the post's own interactions call
  /// for its counts and the reader's own facts. The bookmark refresh
  /// primitive: a stale local copy re-fetches just its post instead of
  /// paging through the feed hoping it is still inside the page window.
  ///
  /// Signs under the reader's per-channel answer — covers private channels.
  /// On failure the response error carries the server code: `POST_NOT_FOUND`
  /// / `CHANNEL_NOT_FOUND` / `ACCOUNT_NOT_FOUND` mean the post is GONE from
  /// the server — callers surface that rather than delete anything local
  /// (the local copy may be the only copy left).
  ///
  /// Conditional read: pass the stored validator as [ifNoneMatch] and an
  /// unchanged post answers `304` → `notModified: true` ("your copy is
  /// byte-current", same contract as the feed's conditional GET). A `200`
  /// carries the fresh item plus its new `etag` for the next round. The item
  /// is one body for every reader, so the validator holds across signed and
  /// anonymous reads.
  static Future<FeedServerApiResponse<Post>> getPost({
    required String ownerAddress,
    required String slug,
    required String postUid,
    String? serverAddress,
    String? ifNoneMatch,
  }) async {
    try {
      final endpoint = '/api/$ownerAddress/channels/$slug/posts/$postUid';
      final baseUrl = await PublicOSSsp.resolveBaseUrl(serverAddress);
      if (baseUrl.isEmpty) {
        return FeedServerApiResponse.error(
            {'code': 'NO_SERVER', 'message': 'No server available'});
      }
      final url = '$baseUrl$endpoint';
      final headers = <String, String>{
        'Accept': RssParser.feedAccept,
        if (ifNoneMatch != null) 'If-None-Match': ifNoneMatch,
      };
      // Identity on a READ is the user's per-channel answer.
      final wantSigned = await PublicOSChannelSignin.shouldSign(url);
      final response = wantSigned
          ? await PublicOSSsp.signedRequestAtUrl(
              method: 'GET',
              url: url,
              action: 'read_feed',
              headers: headers,
            )
          : await http
              .get(Uri.parse(url), headers: headers)
              .timeout(PublicOS.serverRequestTimeout);

      if (response.statusCode == 304) {
        return FeedServerApiResponse.notModified();
      }
      if (response.statusCode != 200) {
        Log.w(_tag,
            'getPost $slug/$postUid: http ${response.statusCode} '
            '${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');
      }
      if (response.statusCode == 200) {
        final item = jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
        var post = Post.fromFeedV1Item(
          item,
          channelSlug: slug,
          channelOwnerAddress: ownerAddress,
          serverAddress: serverAddress,
          feedFoundAtAccountAddress: ownerAddress,
        );
        final interactions = await RssParser.fetchInteractions(
          post.interactionsUrl ?? '$url/interactions',
          signed: wantSigned,
        );
        final mine = interactions?.items[post.uid];
        if (mine != null) post = mine.applyTo(post);
        post = post.withInteractionUrls(
          baseUrl: _extractServerUrl(url),
          ownerAddress: ownerAddress,
          slug: slug,
        );
        return FeedServerApiResponse.success(post,
            etag: response.headers['etag']);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// The content fields of a post body, as the PublicOS Feed writes them
  /// (spec § Item): present only when set, media as alphabetical-key maps.
  /// The same maps go into the signed object and the body.
  static Map<String, dynamic> _v1Content({
    String? title,
    String? text,
    String? summary,
    String? link,
    List<PostMedia>? heroMedia,
    List<PostMedia>? supportMedia,
    PostMedia? audio,
    bool? sensitive,
    PostPointer? quote,
    PostPointer? inReplyTo,
  }) =>
      {
        if (title != null && title.isNotEmpty) 'title': title,
        if (text != null && text.isNotEmpty) 'text': text,
        if (summary != null && summary.isNotEmpty) 'summary': summary,
        if (link != null && link.isNotEmpty) 'link': link,
        if (heroMedia != null && heroMedia.isNotEmpty)
          'hero_media': heroMedia.map((m) => m.toJson()).toList(),
        if (supportMedia != null && supportMedia.isNotEmpty)
          'support_media': supportMedia.map((m) => m.toJson()).toList(),
        if (audio != null) 'audio': audio.toJson(),
        // The one signed key where false is a statement (spec § Sensitive).
        if (sensitive != null) 'sensitive': sensitive,
        if (quote != null) 'quote': quote.toJson(),
        if (inReplyTo != null) 'in_reply_to': inReplyTo.toJson(),
      };

  /// The author's settings, outside the signed object. A `comments` /
  /// `reactions` value travels only as `closed` (`open` is the default and
  /// never stricter than the channel).
  static Map<String, dynamic> _v1Settings({
    String? commentPolicy,
    String? reactionPolicy,
    bool? requireVerifiedComments,
    bool? requireVerifiedReactions,
    String? language,
    List<String>? tags,
    bool mediaPost = false,
    List<String>? collaborators,
  }) =>
      {
        if (commentPolicy == 'closed') 'comments': 'closed',
        if (reactionPolicy == 'closed') 'reactions': 'closed',
        if (requireVerifiedComments != null)
          'require_verified_comments': requireVerifiedComments,
        if (requireVerifiedReactions != null)
          'require_verified_reactions': requireVerifiedReactions,
        if (language != null && language.isNotEmpty) 'language': language,
        if (tags != null) 'tags': tags,
        if (mediaPost) 'media_post': true,
        if (collaborators != null && collaborators.isNotEmpty)
          'collaborators': collaborators,
      };

  /// Sign a post's content (spec § Signatures): the object is the content
  /// plus `author` (the account, lowercase), `date_published`, `target_url`
  /// (`/api/<owner lowercase>/channels/<slug>/posts`) and `type: post`, and
  /// `prev_hashes` on an edit; keys sorted at every depth, signed EIP-191
  /// over the UTF-8 bytes. Returns the signed object string and the
  /// signature.
  static ({String object, String signature}) _signV1Post({
    required Map<String, dynamic> content,
    required String author,
    required String datePublished,
    required String owner,
    required String slug,
    List<String> prevHashes = const [],
  }) {
    final object = PublicOSSsp.canonicalJson({
      ...content,
      'author': author.toLowerCase(),
      'date_published': datePublished,
      'target_url': '/api/${owner.toLowerCase()}/channels/$slug/posts',
      'type': 'post',
      if (prevHashes.isNotEmpty) 'prev_hashes': prevHashes,
    });
    return (object: object, signature: PublicOSSsp.signMessage(object));
  }

  /// The server's answer to a create or an update: the post as a PublicOS
  /// Feed item, with the interaction URLs stamped so the post the user is
  /// about to see is commentable and reactable at once.
  static Post _postFromWriteAnswer(
    http.Response response, {
    required String owner,
    required String slug,
    String? serverAddress,
  }) =>
      Post.fromFeedV1Item(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
        channelSlug: slug,
        channelOwnerAddress: owner,
        serverAddress: serverAddress,
        feedFoundAtAccountAddress: owner,
      ).withInteractionUrls(
        baseUrl: _extractServerUrl(response.request!.url.toString()),
        ownerAddress: owner,
        slug: slug,
      );

  /// Create a signed post in a channel (spec § Item, § Signatures).
  ///
  /// [ownerAddress] — null posts to the user's own channel; set, to someone
  /// else's (community posting).
  ///
  /// Content (signed): [title], [text], [summary], [link], [heroMedia]
  /// (images and videos, each with width, height and sha256), [supportMedia]
  /// (any type, each with sha256), [audio], [sensitive] (the author's rating
  /// for this post; null = the channel's). A post needs at least one of
  /// title, text, media, audio or link.
  ///
  /// Settings (not signed): [commentPolicy] / [reactionPolicy] ('open' |
  /// 'closed'), [requireVerifiedComments] / [requireVerifiedReactions],
  /// [language], [tags], [mediaPost] (the media leads; needs hero media).
  ///
  /// [publishedAt] (RFC 3339) and [uid] replay a post with its original date
  /// and id — bridge and re-post tools only; the apps leave both null.
  static Future<FeedServerApiResponse<Post>> createPost({
    required String slug,
    String? ownerAddress,
    String? title,
    String? text,
    String? summary,
    String? link,
    List<PostMedia>? heroMedia,
    List<PostMedia>? supportMedia,
    PostMedia? audio,
    bool? sensitive,
    String? commentPolicy,
    String? reactionPolicy,
    bool? requireVerifiedComments,
    bool? requireVerifiedReactions,
    String? language,
    List<String>? tags,
    bool mediaPost = false,
    String? publishedAt,
    String? uid,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated or no publicos address'});
      }

      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final account = PublicOS.myPublicosAddress!;
      final owner = ownerAddress ?? account;
      final datePublished = publishedAt ?? rfc3339Seconds(DateTime.now());

      final content = _v1Content(
        title: title,
        text: text,
        summary: summary,
        link: link,
        heroMedia: heroMedia,
        supportMedia: supportMedia,
        audio: audio,
        sensitive: sensitive,
      );
      final signed = _signV1Post(
        content: content,
        author: account,
        datePublished: datePublished,
        owner: owner,
        slug: slug,
      );

      // The body: the content byte-for-byte as signed, the signature pair,
      // and the settings. `account_address` is added by the envelope.
      final data = <String, dynamic>{
        ...content,
        'author': account.toLowerCase(),
        'date_published': datePublished,
        'signed_object': signed.object,
        'content_signature': signed.signature,
        ..._v1Settings(
          commentPolicy: commentPolicy,
          reactionPolicy: reactionPolicy,
          requireVerifiedComments: requireVerifiedComments,
          requireVerifiedReactions: requireVerifiedReactions,
          language: language,
          tags: tags,
          mediaPost: mediaPost,
        ),
        if (uid != null && uid.isNotEmpty) 'uid': uid,
      };

      final response = await PublicOSSsp.signedRequest(
        method: 'POST',
        endpoint: '/api/$owner/channels/$slug/posts',
        action: 'create_post',
        data: data,
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final post = _postFromWriteAnswer(response,
            owner: owner, slug: slug, serverAddress: serverAddress);
        Log.i(_tag, 'Post created: ${post.title} (UID: ${post.uid})');
        return FeedServerApiResponse.success(post);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Edit a post: the whole post again, signed again (spec § Edits).
  /// `PUT /api/:owner/channels/:slug/posts/:uid`.
  ///
  /// [post] is the post as it is now: its id, channel, `date_published`
  /// (an edit keeps it) and current signed object (the new object carries
  /// `prev_hashes`: the current object's own list plus the current object's
  /// hash, so children bound to any earlier version stay valid). Every field
  /// not passed is re-sent as [post] carries it; a value passed wins, and
  /// `''` / an empty list clears. [removeAudio] drops the sound track.
  static Future<FeedServerApiResponse<Post>> updatePost({
    required Post post,
    String? title,
    String? text,
    String? summary,
    String? link,
    List<PostMedia>? heroMedia,
    List<PostMedia>? supportMedia,
    PostMedia? audio,
    bool removeAudio = false,
    bool? sensitive,
    String? commentPolicy,
    String? reactionPolicy,
    bool? requireVerifiedComments,
    bool? requireVerifiedReactions,
    String? language,
    List<String>? tags,
    bool? mediaPost,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated or no publicos address'});
      }

      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }
      final slug = post.channelSlug;
      if (post.uid.isEmpty || slug == null || slug.isEmpty) {
        return FeedServerApiResponse.error(
            {'code': 'BAD_POST', 'message': 'The post has no id or channel'});
      }

      final account = PublicOS.myPublicosAddress!;
      final owner = post.channelOwnerAddress ?? account;
      final datePublished = rfc3339Seconds(post.createdAt);
      final prevHashes = chainedPrevHashes(post.signedObject ?? '');

      final content = _v1Content(
        title: title ?? post.title,
        text: text ?? post.contentText,
        summary: summary ?? post.summary,
        link: link ?? post.externalUrl,
        heroMedia: heroMedia ?? post.heroMedia,
        supportMedia: supportMedia ?? post.supportMedia,
        audio: removeAudio ? null : (audio ?? post.audio),
        sensitive: sensitive ?? post.sensitive,
        quote: post.quote,
        inReplyTo: post.inReplyTo,
      );
      final signed = _signV1Post(
        content: content,
        author: account,
        datePublished: datePublished,
        owner: owner,
        slug: slug,
        prevHashes: prevHashes,
      );

      final data = <String, dynamic>{
        ...content,
        'author': account.toLowerCase(),
        'date_published': datePublished,
        'signed_object': signed.object,
        'content_signature': signed.signature,
        ..._v1Settings(
          commentPolicy: commentPolicy ?? post.commentPolicy,
          reactionPolicy: reactionPolicy ?? post.reactionPolicy,
          requireVerifiedComments:
              requireVerifiedComments ?? post.requireVerifiedComments,
          requireVerifiedReactions:
              requireVerifiedReactions ?? post.requireVerifiedReactions,
          language: language ?? post.language,
          tags: tags ?? post.tags,
          mediaPost: mediaPost ?? post.mediaPost,
          collaborators: post.collaborators,
        ),
      };

      final response = await PublicOSSsp.signedRequest(
        method: 'PUT',
        endpoint: '/api/$owner/channels/$slug/posts/${post.uid}',
        action: 'update_post',
        data: data,
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200) {
        return FeedServerApiResponse.success(_postFromWriteAnswer(response,
            owner: owner, slug: slug, serverAddress: serverAddress));
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Delete a post
  /// URL: DELETE /api/:address/channels/:slug/posts/:postUid
  static Future<FeedServerApiResponse<bool>> deletePost({
    required String postUid,
    required String slug,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated or no publicos address'});
      }

      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;

      final response = await PublicOSSsp.signedRequest(
        method: 'DELETE',
        endpoint: '/api/$accountAddress/channels/$slug/posts/$postUid',
        action: 'delete_post',
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return FeedServerApiResponse.success(true);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }


  ///*********************************************
  /// COMMENTS & REACTIONS
  ///*********************************************

  /// Whether the reader may comment on (and vote on) this post. The server's
  /// own answer for this reader ([Post.canCommentAnswer], from a signed
  /// interactions or comments call) decides when present; otherwise the
  /// post's setting: closed is no, null/missing is open (server default). A
  /// post with no comments URL has nowhere to comment.
  static bool canComment(Post post) {
    if (post.uid.isEmpty ||
        post.commentsUrl == null ||
        post.commentsUrl!.isEmpty) {
      return false;
    }
    return post.canCommentAnswer ?? post.commentPolicy != 'closed';
  }

  /// Whether the reader may react to this post. Independent of [canComment]:
  /// the server's [Post.canReactAnswer] decides when present, else the post's
  /// reaction setting. Gates on the post's OWN [Post.reactionsUrl] — never on
  /// [Post.commentsUrl]; gating reactions on the comments URL would couple
  /// the two, and one lost field would kill both features.
  static bool canReact(Post post) {
    if (post.uid.isEmpty || post.reactionsUrl == null) return false;
    return post.canReactAnswer ?? post.reactionPolicy != 'closed';
  }

  /// Fetch comments for a post with pagination and sorting.
  /// [sort]: Sort order (default best). See [CommentSort].
  /// [offset]: Skip first N comments (default 0).
  /// [limit]: Max comments to return (default 100).
  /// The thread only; [getCommentsAnswer] also carries the server's
  /// `can_comment` / `can_react` for the reader.
  static Future<List<Comment>> getComments(
    Post post, {
    CommentSort sort = CommentSort.best,
    int offset = 0,
    int limit = 100,
  }) async =>
      (await getCommentsAnswer(post, sort: sort, offset: offset, limit: limit))
          .comments;

  /// The comments call (spec § Comments): the thread, and, when the request
  /// went SIGNED, whether this reader may comment (votes follow it) and react
  /// on the post. Unsigned, the server does not know the reader and the
  /// answer carries null for both (an unsigned `false` is unknown, never
  /// "no"). Signed under the reader's per-channel answer, so a denied
  /// reader is not identified on the comment thread either; the signed call
  /// is also what counts a post read.
  static Future<CommentsAnswer> getCommentsAnswer(
    Post post, {
    CommentSort sort = CommentSort.best,
    int offset = 0,
    int limit = 100,
  }) async {
    // A post open fires the comments GET even when comments are closed: the
    // request IS the read signal (the server records it before its
    // closed-policy return). A post with no commentsUrl has nothing to hit.
    if (post.uid.isEmpty || post.commentsUrl == null || post.commentsUrl!.isEmpty) {
      return const CommentsAnswer(comments: []);
    }

    try {
      final url = post.commentsUrl!;
      final queryParams = <String, String>{
        'sort': sort.serverParam,
        if (offset > 0) 'offset': offset.toString(),
        if (limit != 100) 'limit': limit.toString(),
      };

      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final wantSigned = await PublicOSChannelSignin.shouldSign(url);

      final response = wantSigned
          ? await PublicOSSsp.signedRequestAtUrl(
              method: 'GET',
              url: uri.toString(),
              action: 'read_feed',
            )
          : await http
              .get(uri)
              .timeout(PublicOS.serverRequestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
        final comments = (data['comments'] as List<dynamic>? ?? const [])
            .map((c) => Comment.fromJson(c as Map<String, dynamic>))
            .toList();
        return CommentsAnswer(
          comments: comments,
          canComment: wantSigned ? data['can_comment'] as bool? : null,
          canReact: wantSigned ? data['can_react'] as bool? : null,
        );
      } else if (response.statusCode == 404) {
        return const CommentsAnswer(comments: []);
      } else {
        throw Exception('Failed to load comments: ${response.statusCode}');
      }
    } catch (e) {
      Log.e(_tag, '$e');
      rethrow;
    }
  }

  /// Vote on a comment (+1 upvote, -1 downvote). Toggle: same value removes vote.
  /// Returns updated vote data: {action, score, upvotes, downvotes, user_vote}
  static Future<Map<String, dynamic>> voteComment({
    required Post post,
    required Comment comment,
    required int value,
  }) async {
    if (!canComment(post)) {
      throw Exception('Post does not support comments');
    }

    if (PublicOS.myPublicosAddress == null) {
      throw Exception('No account address available');
    }

    if (PublicOS.currentBlockchainPrivateKey == null) {
      throw Exception('Not authenticated');
    }

    final accountAddress = PublicOS.myPublicosAddress!;
    final commentsUrl = post.commentsUrl!;

    // Build signed_object -- alphabetical key order. Single-bind: the
    // direct parent is the COMMENT being voted on — its url AND its hash.
    final signedObject = {
      'author': accountAddress,
      'comment_uid': comment.uid,
      if (comment.signedObject.isNotEmpty)
        'target_hash': targetHashOf(comment.signedObject),
      'target_url': '$commentsUrl/${comment.uid}',
      'type': 'vote',
      'value': value,
    };

    final signedObjectJSON = json.encode(signedObject);
    final contentSignature =
        await PublicOSSsp.signMessageAsync(signedObjectJSON);

    final data = {
      'signed_object': signedObjectJSON,
      'content_signature': contentSignature,
      'value': value,
    };

    final voteUrl = '$commentsUrl/${comment.uid}/vote';

    final response = await PublicOSSsp.signedRequestAtUrl(
      method: 'POST',
      url: voteUrl,
      action: 'vote_comment',
      data: data,
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      return responseData;
    } else {
      final error = json.decode(response.body) as Map<String, dynamic>;
      final errorMsg = error['error']?['message'] as String? ?? 'Unknown error';
      Log.e(_tag, 'Failed to vote: $errorMsg');
      throw Exception(errorMsg);
    }
  }

  /// Fetch paginated replies for a specific comment
  static Future<List<Comment>> getCommentReplies(
    Post post,
    Comment comment, {
    CommentSort sort = CommentSort.best,
    int offset = 0,
    int limit = 20,
  }) async {
    if (!canComment(post)) {
      return [];
    }

    try {
      final commentsUrl = post.commentsUrl!;
      final queryParams = <String, String>{
        'sort': sort.serverParam,
        if (offset > 0) 'offset': offset.toString(),
        if (limit != 20) 'limit': limit.toString(),
      };

      // Sign with `read_feed` envelope when authed (see getComments
      // for rationale). Anonymous fallback gets no per-user enrichment.
      final repliesUrl = '$commentsUrl/${comment.uid}/replies';
      final uri = Uri.parse(repliesUrl).replace(queryParameters: queryParams);
      // Identity on a READ is the user's per-channel answer.
      final wantSigned = await PublicOSChannelSignin.shouldSign(repliesUrl);

      final response = wantSigned
          ? await PublicOSSsp.signedRequestAtUrl(
              method: 'GET',
              url: uri.toString(),
              action: 'read_feed',
            )
          : await http
              .get(uri)
              .timeout(PublicOS.serverRequestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final replies = (data['replies'] as List<dynamic>)
            .map((c) => Comment.fromJson(c as Map<String, dynamic>))
            .toList();

        return replies;
      } else {
        throw Exception('Failed to load replies: ${response.statusCode}');
      }
    } catch (e) {
      Log.e(_tag, '$e');
      rethrow;
    }
  }

  /// Edit a comment's content (author-only)
  static Future<Comment> editComment({
    required Post post,
    required Comment comment,
    required String newContent,
  }) async {
    if (!canComment(post)) {
      throw Exception('Post does not support comments');
    }

    if (PublicOS.myPublicosAddress == null) {
      throw Exception('No account address available');
    }

    if (PublicOS.currentBlockchainPrivateKey == null) {
      throw Exception('Not authenticated');
    }

    final accountAddress = PublicOS.myPublicosAddress!;
    final commentsUrl = post.commentsUrl!;
    final basePostUrl = commentsUrl.replaceAll('/comments', '');

    // Single-bind edit: the blob REPLACES the comment's stored blob, so it
    // must (1) acknowledge the comment's own version history (prev_hashes =
    // old prev list + hash of the old blob) and (2) re-carry the binding to
    // the comment's DIRECT parent — the parent comment for replies, the
    // post for top-level. The carried hash stays membership-valid via the
    // parent's acknowledged chain even if the parent was edited meanwhile.
    final oldBlob = comment.signedObject;
    Map<String, dynamic> oldBlobMap = const {};
    if (oldBlob.isNotEmpty) {
      try {
        oldBlobMap = jsonDecode(oldBlob) as Map<String, dynamic>;
      } catch (_) {}
    }
    final isReply = comment.replyToUid != null;
    final targetUrl =
        isReply ? '$commentsUrl/${comment.replyToUid}' : basePostUrl;
    final targetHash = oldBlobMap['target_hash'] as String? ??
        ((!isReply && (post.signedObject?.isNotEmpty ?? false))
            ? targetHashOf(post.signedObject!)
            : null);
    final prevHashes = chainedPrevHashes(oldBlob);
    final signedObject = {
      'author': accountAddress,
      'comment_uid': comment.uid,
      'content': newContent,
      if (prevHashes.isNotEmpty) 'prev_hashes': prevHashes,
      if (targetHash != null && targetHash.isNotEmpty)
        'target_hash': targetHash,
      'target_url': targetUrl,
      'type': 'edit_comment',
    };

    final signedObjectJSON = json.encode(signedObject);
    final contentSignature =
        await PublicOSSsp.signMessageAsync(signedObjectJSON);

    final data = {
      'content': newContent,
      'signed_object': signedObjectJSON,
      'content_signature': contentSignature,
    };

    final editUrl = '$commentsUrl/${comment.uid}';

    final response = await PublicOSSsp.signedRequestAtUrl(
      method: 'PUT',
      url: editUrl,
      action: 'edit_comment',
      data: data,
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      final updated = Comment.fromJson(responseData['comment'] as Map<String, dynamic>);
      Log.i(_tag, 'Comment ${comment.uid} edited successfully');
      return updated;
    } else {
      final error = json.decode(response.body) as Map<String, dynamic>;
      final errorMsg = error['error']?['message'] as String? ?? 'Unknown error';
      Log.e(_tag, 'Failed to edit comment: $errorMsg');
      throw Exception(errorMsg);
    }
  }

  /// Delete a comment (author-only, soft-delete)
  static Future<void> deleteComment({
    required Post post,
    required Comment comment,
  }) async {
    if (!canComment(post)) {
      throw Exception('Post does not support comments');
    }

    if (PublicOS.myPublicosAddress == null) {
      throw Exception('No account address available');
    }

    if (PublicOS.currentBlockchainPrivateKey == null) {
      throw Exception('Not authenticated');
    }

    final accountAddress = PublicOS.myPublicosAddress!;
    final commentsUrl = post.commentsUrl!;

    // Build signed_object -- alphabetical key order. Single-bind: a
    // delete's target is the comment it removes (server ignores this blob;
    // signed for the author's own record).
    final signedObject = {
      'author': accountAddress,
      'comment_uid': comment.uid,
      if (comment.signedObject.isNotEmpty)
        'target_hash': targetHashOf(comment.signedObject),
      'target_url': '$commentsUrl/${comment.uid}',
      'type': 'delete_comment',
    };

    final signedObjectJSON = json.encode(signedObject);
    final contentSignature =
        await PublicOSSsp.signMessageAsync(signedObjectJSON);

    final data = {
      'signed_object': signedObjectJSON,
      'content_signature': contentSignature,
    };

    final deleteUrl = '$commentsUrl/${comment.uid}';

    final response = await PublicOSSsp.signedRequestAtUrl(
      method: 'DELETE',
      url: deleteUrl,
      action: 'delete_comment',
      data: data,
    );

    if (response.statusCode == 200) {
      Log.i(_tag, 'Comment ${comment.uid} deleted successfully');
    } else {
      final error = json.decode(response.body) as Map<String, dynamic>;
      final errorMsg = error['error']?['message'] as String? ?? 'Unknown error';
      Log.e(_tag, 'Failed to delete comment: $errorMsg');
      throw Exception(errorMsg);
    }
  }

  /// Create a new comment
  static Future<Comment> createComment({
    required Post post,
    required String content,
    String? replyToUid,
    Comment? replyTo,
  }) async {
    if (!canComment(post)) {
      throw Exception('Post does not support comments');
    }

    if (PublicOS.myPublicosAddress == null) {
      throw Exception('No account address available');
    }

    if (PublicOS.currentBlockchainPrivateKey == null) {
      throw Exception('Not authenticated');
    }

    // Get addresses + display name (DB read for the latter)
    final accountAddress = PublicOS.myPublicosAddress!;
    final myContact = await PublicOSContacts.getContact(
      EthereumAddress.fromHex(accountAddress),
    );
    final username = myContact?.publicosDisplayName ?? 'Anonymous';

    // Build target URLs -- use the full post URL from commentsUrl
    // From: http://server/api/address/channels/slug/posts/14/comments
    // To:   http://server/api/address/channels/slug/posts/14
    final commentsUrl = post.commentsUrl!;
    final baseUrl = commentsUrl.replaceAll('/comments', '');
    final effectiveReplyToUid = replyTo?.uid ?? replyToUid;

    // Single-bind: the ONE target is the direct parent — the parent
    // comment for replies, the post for top-level comments. The blob
    // carries only that parent's url + hash; the conversation root is
    // reachable by walking the chain.
    final String targetUrl;
    final String? parentBlob;
    if (effectiveReplyToUid != null) {
      targetUrl = '$commentsUrl/$effectiveReplyToUid';
      parentBlob = replyTo?.signedObject;
    } else {
      targetUrl = baseUrl;
      parentBlob = post.signedObject;
    }

    // Build signed_object for content signature
    // IMPORTANT: Keys must be in alphabetical order to match Go's json.Marshal
    final signedObject = {
      'author': accountAddress,
      'content': content,
      if (parentBlob != null && parentBlob.isNotEmpty)
        'target_hash': targetHashOf(parentBlob),
      'target_url': targetUrl,
      'type': 'comment',
    };

    // Convert to JSON string with alphabetically sorted keys
    final signedObjectJSON = json.encode(signedObject);

    // Sign the content (reuse existing signing)
    final contentSignature =
        await PublicOSSsp.signMessageAsync(signedObjectJSON);

    // Build request data
    // Send signed_object as JSON string, not as map, to preserve exact format for verification
    final data = {
      'content': content,
      'username': username,
      if (effectiveReplyToUid != null) 'reply_to_uid': effectiveReplyToUid,
      'signed_object': signedObjectJSON,
      'content_signature': contentSignature,
    };

    final url = post.commentsUrl!;

    final response = await PublicOSSsp.signedRequestAtUrl(
      method: 'POST',
      url: url,
      action: 'create_comment',
      data: data,
    );

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      final comment = Comment.fromJson(responseData['comment'] as Map<String, dynamic>);
      Log.i(_tag, 'Comment created: ${comment.uid}');
      return comment;
    } else {
      final error = json.decode(response.body) as Map<String, dynamic>;
      final errorMsg = error['error']['message'] as String;
      Log.e(_tag, 'Failed to create comment: $errorMsg');
      throw Exception(errorMsg);
    }
  }

  /// Fetch reactions for a post
  static Future<ReactionsData?> getReactions(Post post) async {
    if (!canReact(post)) {
      return null;
    }

    try {
      final url = _buildReactionsUrl(post);

      // Sign with `read_feed` envelope when authed — covers private
      // channels (server-side dual-lookup) plus per-user reaction-state
      // hint. Anonymous fallback works for public channels only.
      // Identity on a READ is the user's per-channel answer.
      final wantSigned = await PublicOSChannelSignin.shouldSign(url);
      final response = wantSigned
          ? await PublicOSSsp.signedRequestAtUrl(
              method: 'GET',
              url: url,
              action: 'read_feed',
            )
          : await http
              .get(Uri.parse(url))
              .timeout(PublicOS.serverRequestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final reactionsData = ReactionsData.fromJson(data);
        return reactionsData;
      } else {
        Log.e(_tag, 'Failed to fetch reactions: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      Log.e(_tag, '$e');
      rethrow;
    }
  }

  /// Toggle a reaction (add if not present, remove if present)
  /// Returns true if added, false if removed
  static Future<bool> toggleReaction({
    required Post post,
    required String emoji,
  }) async {
    if (!canReact(post)) {
      throw Exception('Post does not support reactions');
    }

    if (PublicOS.myPublicosAddress == null) {
      throw Exception('No account address available');
    }

    if (PublicOS.currentBlockchainPrivateKey == null) {
      throw Exception('Not authenticated');
    }

    // Get addresses
    final accountAddress = PublicOS.myPublicosAddress!;

    // Build target URL -- the post base, derived from the reaction path's own
    // field (never commentsUrl — the reaction path must not depend on it)
    // From: http://server/api/address/channels/slug/posts/14/reactions
    // To:   http://server/api/address/channels/slug/posts/14
    final reactionsUrl = post.reactionsUrl!;
    final targetUrl = reactionsUrl.replaceAll('/reactions', '');

    // Build signed_object
    // IMPORTANT: Keys must be in alphabetical order to match Go's json.Marshal
    final postBlob = post.signedObject;
    final signedObject = {
      'author': accountAddress,
      'emoji': emoji,
      if (postBlob != null && postBlob.isNotEmpty)
        'target_hash': targetHashOf(postBlob),
      'target_url': targetUrl,
      'type': 'reaction',
    };

    // Convert to JSON string with alphabetically sorted keys
    final signedObjectJSON = json.encode(signedObject);

    // Sign the content
    final contentSignature =
        await PublicOSSsp.signMessageAsync(signedObjectJSON);

    // Build request data
    // Send signed_object as JSON string, not as map, to preserve exact format for verification
    final data = {
      'emoji': emoji,
      'signed_object': signedObjectJSON,
      'content_signature': contentSignature,
    };

    final url = _buildReactionsUrl(post);

    final response = await PublicOSSsp.signedRequestAtUrl(
      method: 'POST',
      url: url,
      action: 'add_reaction',
      data: data,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      final action = responseData['action'] as String;
      final wasAdded = action == 'added';
      return wasAdded;
    } else {
      final error = json.decode(response.body) as Map<String, dynamic>;
      final errorMsg = error['error']['message'] as String;
      Log.e(_tag, 'Failed to toggle reaction: $errorMsg');
      throw Exception(errorMsg);
    }
  }

  /// Helper: the post's reactions endpoint. A real field since
  /// fix_bookmarks_comments_reactions — synthesized at load alongside
  /// commentsUrl, never derived from it. Callers gate on [canReact] first,
  /// which guarantees non-null.
  static String _buildReactionsUrl(Post post) {
    return post.reactionsUrl!;
  }

  /// Helper: Extract base server URL from comments URL
  static String _extractServerUrl(String commentsUrl) {
    final uri = Uri.parse(commentsUrl);
    final port = (uri.port == 80 || uri.port == 443) ? '' : ':${uri.port}';
    return '${uri.scheme}://${uri.host}$port';
  }

  // -- Comment Reactions -----------------------------------------------

  /// Build comment reactions URL from a comment's target URL
  /// From: http://server/api/0xABC.../channels/slug/posts/14/comments
  /// To:   http://server/api/0xABC.../channels/slug/posts/14/comments/42/reactions
  static String _buildCommentReactionsUrl(Post post, Comment comment) {
    final commentsUrl = post.commentsUrl!;
    return '$commentsUrl/${comment.uid}/reactions';
  }

  /// Fetch who reacted to a comment (`GET …/comments/:uid/reactions`): the
  /// same shape as a post's answer (`reactions`, `user_reactions`,
  /// `current_user_reactions`), so it parses as [ReactionsData]; its
  /// `postUid` is left empty (the server answers `comment_uid`). The twin of
  /// [getReactions], for the comment reactions sheet.
  static Future<ReactionsData?> getCommentReactions({
    required Post post,
    required Comment comment,
  }) async {
    if (!canReact(post) || post.commentsUrl == null) {
      return null;
    }

    try {
      final url = _buildCommentReactionsUrl(post, comment);
      final wantSigned = await PublicOSChannelSignin.shouldSign(url);
      final response = wantSigned
          ? await PublicOSSsp.signedRequestAtUrl(
              method: 'GET',
              url: url,
              action: 'read_feed',
            )
          : await http
              .get(Uri.parse(url))
              .timeout(PublicOS.serverRequestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return ReactionsData.fromJson(data);
      } else {
        Log.e(_tag, 'Failed to fetch comment reactions: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      Log.e(_tag, '$e');
      rethrow;
    }
  }

  /// Toggle a reaction on a comment (add if not present, remove if present)
  /// Returns true if added, false if removed
  static Future<bool> toggleCommentReaction({
    required Post post,
    required Comment comment,
    required String emoji,
  }) async {
    if (!canReact(post)) {
      throw Exception('Post does not support reactions');
    }

    if (PublicOS.myPublicosAddress == null) {
      throw Exception('No account address available');
    }

    if (PublicOS.currentBlockchainPrivateKey == null) {
      throw Exception('Not authenticated');
    }

    final accountAddress = PublicOS.myPublicosAddress!;

    // Build target URL including comment ID
    final commentsUrl = post.commentsUrl!;
    final targetUrl = '$commentsUrl/${comment.uid}';

    // Build signed_object (alphabetical key order). target_hash binds to
    // the COMMENT being reacted to (the direct parent), not the post.
    final signedObject = {
      'author': accountAddress,
      'comment_uid': comment.uid,
      'emoji': emoji,
      if (comment.signedObject.isNotEmpty)
        'target_hash': targetHashOf(comment.signedObject),
      'target_url': targetUrl,
      'type': 'comment_reaction',
    };

    final signedObjectJSON = json.encode(signedObject);
    final contentSignature =
        await PublicOSSsp.signMessageAsync(signedObjectJSON);

    final data = {
      'emoji': emoji,
      'signed_object': signedObjectJSON,
      'content_signature': contentSignature,
    };

    final url = _buildCommentReactionsUrl(post, comment);
    final response = await PublicOSSsp.signedRequestAtUrl(
      method: 'POST',
      url: url,
      action: 'add_comment_reaction',
      data: data,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      final action = responseData['action'] as String;
      return action == 'added';
    } else {
      final error = json.decode(response.body) as Map<String, dynamic>;
      final errorMsg = (error['error'] as Map<String, dynamic>)['message'] as String;
      throw Exception(errorMsg);
    }
  }


  ///*********************************************
  /// POST VOTING
  ///*********************************************

  /// Vote on a post (upvote or downvote).
  /// [value] must be 1 (upvote) or -1 (downvote).
  /// Toggle behavior: same vote again removes it; opposite vote flips it.
  static Future<FeedServerApiResponse<VoteResult>> votePost({
    required String ownerAddress,
    required String slug,
    required String postUid,
    required int value,
    String? serverAddress,
    Post? post,
  }) async {
    try {
      if (PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;

      // Build signed_object (alphabetical key order). Was a bare
      // {'type': 'vote'} — trivially replayable across posts; now commits
      // author, target and value, plus the content-hash binding when the
      // caller passes the [post] (required for votes on signed posts —
      // the server rejects signed votes without target_hash there).
      final postBlob = post?.signedObject;
      final signedObject = {
        'author': accountAddress,
        if (postBlob != null && postBlob.isNotEmpty)
          'target_hash': targetHashOf(postBlob),
        'target_url': '/api/$ownerAddress/channels/$slug/posts/$postUid',
        'type': 'vote',
        'value': value,
      };
      final signedObjectJSON = json.encode(signedObject);
      final contentSignature =
        await PublicOSSsp.signMessageAsync(signedObjectJSON);

      final data = <String, dynamic>{
        'account_address': accountAddress,
        'content_signature': contentSignature,
        'signed_object': signedObjectJSON,
        'value': value,
      };

      final response = await PublicOSSsp.signedRequest(
        method: 'POST',
        endpoint: '/api/$ownerAddress/channels/$slug/posts/$postUid/vote',
        action: 'vote_post',
        data: data,
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return FeedServerApiResponse.success(VoteResult.fromJson(responseData));
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  ///*********************************************
  /// CHANNEL MODERATION
  ///*********************************************

  /// Add address as an approved poster for a channel (owner only)
  static Future<FeedServerApiResponse<void>> addPoster({
    required String slug,
    required String address,
    String? expiresAt,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final data = <String, dynamic>{'address': address};
      if (expiresAt != null) data['expires_at'] = expiresAt;

      final response = await PublicOSSsp.signedRequest(
        method: 'POST',
        endpoint: '/api/$accountAddress/channels/$slug/posters',
        action: 'add_poster',
        data: data,
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return FeedServerApiResponse.success(null);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Remove address from channel posters (owner only)
  static Future<FeedServerApiResponse<void>> removePoster({
    required String slug,
    required String address,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final response = await PublicOSSsp.signedRequest(
        method: 'DELETE',
        endpoint: '/api/$accountAddress/channels/$slug/posters/$address',
        action: 'remove_poster',
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200) {
        return FeedServerApiResponse.success(null);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// List channel poster entries (owner only)
  static Future<FeedServerApiResponse<List<PostPermissionEntry>>> listPosters({
    required String slug,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final response = await PublicOSSsp.signedRequest(
        method: 'GET',
        endpoint: '/api/$accountAddress/channels/$slug/posters',
        action: 'list_posters',
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Server may return raw array or {"posters": [...]}
        final list = data is List ? data : (data['posters'] as List? ?? []);
        final entries = list.map((e) => PostPermissionEntry.fromJson(e as Map<String, dynamic>)).toList();
        return FeedServerApiResponse.success(entries);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Ban address from channel (owner only)
  static Future<FeedServerApiResponse<void>> ban({
    required String slug,
    required String address,
    String? reason,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final data = <String, dynamic>{'address': address};
      if (reason != null) data['reason'] = reason;

      final response = await PublicOSSsp.signedRequest(
        method: 'POST',
        endpoint: '/api/$accountAddress/channels/$slug/bans',
        action: 'add_ban',
        data: data,
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return FeedServerApiResponse.success(null);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Unban address from channel (owner only)
  static Future<FeedServerApiResponse<void>> unban({
    required String slug,
    required String address,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final response = await PublicOSSsp.signedRequest(
        method: 'DELETE',
        endpoint: '/api/$accountAddress/channels/$slug/bans/$address',
        action: 'remove_ban',
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200) {
        return FeedServerApiResponse.success(null);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// List channel bans (owner only)
  static Future<FeedServerApiResponse<List<BanEntry>>> listBans({
    required String slug,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final response = await PublicOSSsp.signedRequest(
        method: 'GET',
        endpoint: '/api/$accountAddress/channels/$slug/bans',
        action: 'list_bans',
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data is List ? data : (data['bans'] as List? ?? []);
        final entries = list.map((e) => BanEntry.fromJson(e as Map<String, dynamic>)).toList();
        return FeedServerApiResponse.success(entries);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Update channel policy (rate limit + rent gating)
  static Future<FeedServerApiResponse<void>> updatePolicy({
    required String slug,
    int? postRateLimit,
    bool? requireRent,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final data = <String, dynamic>{};
      if (postRateLimit != null) data['post_rate_limit'] = postRateLimit;
      if (requireRent != null) data['require_rent'] = requireRent;

      final response = await PublicOSSsp.signedRequest(
        method: 'PUT',
        endpoint: '/api/$accountAddress/channels/$slug/policy',
        action: 'update_policy',
        data: data,
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200) {
        return FeedServerApiResponse.success(null);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  ///*********************************************
  /// FOLLOW MANAGEMENT
  ///*********************************************

  /// Request to follow a private channel (signed, global contract auth).
  ///
  /// The door is NOT the channel's read filter (accept-and-badge):
  /// a filter-blocked request LANDS, badged
  /// `blocked` on the owner's list. What gates the request instead is a fixed
  /// floor, the same on every channel — an account in good standing:
  ///   - `STANDING_REQUIRED` (403) — "follow requests require an account in
  ///     good standing". Bare wallets and lapsed accounts can't flood the
  ///     request box; an owner who wants one in adds it by hand to the
  ///     whitelist, which accepts any address.
  ///
  /// Server gates the request before creating a row — surfaced as error codes
  /// on the returned response when 2xx fails:
  ///   - `BLACKLISTED` (403) — caller is on the channel/account-wide blacklist.
  ///   - `ALREADY_WHITELISTED` (409) — caller already has read access (no
  ///     point in re-requesting until the whitelist row is removed).
  ///   - `FOLLOW_REQUEST_EXISTS` (409) — caller already has a `pending` or
  ///     `ignored` request open. After approve→revoke, the historical
  ///     `approved` row does NOT block — re-request goes through.
  static Future<FeedServerApiResponse<Map<String, dynamic>>> requestFollow({
    required String ownerAddress,
    required String slug,
    String? serverAddress,
  }) async {
    try {
      if (PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;

      // Build signed_object (alphabetical key order)
      final signedObject = {
        'channel_slug': slug,
        'owner': ownerAddress,
        'requester': accountAddress,
        'type': 'follow_request',
      };

      final signedObjectJSON = json.encode(signedObject);
      final contentSignature =
        await PublicOSSsp.signMessageAsync(signedObjectJSON);

      final data = {
        'content_signature': contentSignature,
        'signed_object': signedObjectJSON,
      };

      final response = await PublicOSSsp.signedRequest(
        method: 'POST',
        endpoint: '/api/$ownerAddress/channels/$slug/follow',
        action: 'request_follow',
        data: data,
        serverAddress: serverAddress,
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return FeedServerApiResponse.success(responseData);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Cancel a follow request for a private channel (signed, global contract auth)
  static Future<FeedServerApiResponse<void>> cancelFollow({
    required String ownerAddress,
    required String slug,
    String? serverAddress,
  }) async {
    try {
      if (PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final response = await PublicOSSsp.signedRequest(
        method: 'DELETE',
        endpoint: '/api/$ownerAddress/channels/$slug/follow',
        action: 'cancel_follow',
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200) {
        return FeedServerApiResponse.success(null);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// List follow requests for a channel (channel owner only).
  ///
  /// Each row carries `FollowRequest.filterStatus` (`passes` / `blocked` /
  /// `unknown`), evaluated live against the channel's CURRENT read filter —
  /// the accept-and-badge half: the Requests UI badges blocked requesters
  /// instead of the server refusing them at the door.
  ///
  /// Filters (all optional):
  ///   - [statuses] — subset of `pending`, `ignored`, `approved`. Sent to
  ///     the server as a comma-joined `?status=` query value. Omit for all.
  ///   - [startDate] / [endDate] — RFC3339 range applied to the row's
  ///     `created_at`. Either may be omitted for an open-ended range.
  ///
  /// Two example call shapes that drive client UX:
  ///   - Left-nav "N pending" badge: `statuses: ['pending'], startDate:
  ///     DateTime.now().subtract(Duration(days: 14))` → use response `count`.
  ///   - Manage-channel paged list: `statuses: ['pending', 'ignored',
  ///     'approved']` plus an `endDate` cursor for older slices.
  static Future<FeedServerApiResponse<FollowRequestListResponse>> listFollowers({
    required String slug,
    String? serverAddress,
    List<String>? statuses,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;

      final query = <String, String>{};
      if (statuses != null && statuses.isNotEmpty) {
        query['status'] = statuses.join(',');
      }
      if (startDate != null) {
        query['start_date'] = startDate.toUtc().toIso8601String();
      }
      if (endDate != null) {
        query['end_date'] = endDate.toUtc().toIso8601String();
      }
      var endpoint = '/api/$accountAddress/channels/$slug/followers';
      if (query.isNotEmpty) {
        endpoint += '?${query.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
      }

      // Envelope target is path-only (server compares c.Request.URL.Path),
      // so signedRequest's computeTarget strips the query string for us.
      final response = await PublicOSSsp.signedRequest(
        method: 'GET',
        endpoint: endpoint,
        action: 'list_followers',
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FeedServerApiResponse.success(FollowRequestListResponse.fromJson(data));
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Approve a follow request (channel owner only).
  ///
  /// [requestUid] is the UUID PK on the server (`follow_requests.uid`),
  /// surfaced as `FollowRequest.uid` after `listFollowers`.
  ///
  /// Allowed transitions: `pending → approved`, `ignored → approved`. An
  /// already-`approved` row returns `INVALID_TRANSITION` (409) — to revoke
  /// access, remove the whitelist entry instead. Approval also creates the
  /// backing whitelist row server-side.
  static Future<FeedServerApiResponse<FollowRequest>> approveFollower({
    required String slug,
    required String requestUid,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final response = await PublicOSSsp.signedRequest(
        method: 'PUT',
        endpoint: '/api/$accountAddress/channels/$slug/followers/$requestUid',
        action: 'approve_follower',
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FeedServerApiResponse.success(FollowRequest.fromJson(data['follow_request']));
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Soft-ignore a pending follow request (channel owner only).
  ///
  /// The row stays in the database with `status = ignored` so the requester
  /// gets a stable history and the owner keeps an audit trail. No DELETE on
  /// follow requests is exposed to the owner — the only way to remove a row
  /// is the requester's `cancelFollow` (prevents "I never got your request"
  /// gaslighting).
  ///
  /// Allowed transitions: `pending → ignored` only. Ignoring an already-
  /// `ignored` or `approved` request returns `INVALID_TRANSITION` (409).
  /// Returns the updated `FollowRequest` row on success.
  static Future<FeedServerApiResponse<FollowRequest>> ignoreFollower({
    required String slug,
    required String requestUid,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final response = await PublicOSSsp.signedRequest(
        method: 'PUT',
        endpoint: '/api/$accountAddress/channels/$slug/followers/$requestUid/ignore',
        action: 'ignore_follower',
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FeedServerApiResponse.success(FollowRequest.fromJson(data['follow_request']));
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }


  ///*********************************************
  /// CHANNEL-SPECIFIC READ ACCESS (Whitelist)
  ///*********************************************

  /// Add address to channel whitelist (read access, owner only)
  static Future<FeedServerApiResponse<void>> addToWhitelist({
    required String slug,
    required String address,
    String? expiresAt,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final data = <String, dynamic>{'address': address};
      if (expiresAt != null) data['expires_at'] = expiresAt;

      final response = await PublicOSSsp.signedRequest(
        method: 'POST',
        endpoint: '/api/$accountAddress/channels/$slug/whitelist',
        action: 'add_whitelist',
        data: data,
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return FeedServerApiResponse.success(null);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Remove address from channel whitelist (owner only)
  static Future<FeedServerApiResponse<void>> removeFromWhitelist({
    required String slug,
    required String address,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final response = await PublicOSSsp.signedRequest(
        method: 'DELETE',
        endpoint: '/api/$accountAddress/channels/$slug/whitelist/$address',
        action: 'remove_whitelist',
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200) {
        return FeedServerApiResponse.success(null);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// List channel whitelist entries (owner only)
  static Future<FeedServerApiResponse<List<WhitelistEntry>>> listWhitelist({
    required String slug,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final response = await PublicOSSsp.signedRequest(
        method: 'GET',
        endpoint: '/api/$accountAddress/channels/$slug/whitelist',
        action: 'list_whitelist',
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data is List ? data : (data['whitelist'] as List? ?? []);
        final entries = list.map((e) => WhitelistEntry.fromJson(e as Map<String, dynamic>)).toList();
        return FeedServerApiResponse.success(entries);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  ///*********************************************
  /// CHANNEL INTERACTION LIST (the "Custom" commenters list)
  ///*********************************************
  ///
  /// The owner-facing surface for the list behind
  /// `interact_use_interaction_list` — who may comment/react when that switch
  /// is on. Mirrors the whitelist trio exactly: same owner auth, same expiry
  /// semantics, and the address is never validated against the chain — a raw
  /// wallet key is a first-class member (the wallet door). Entries reuse
  /// [WhitelistEntry]: the server row shape is identical.

  /// Add address to the channel's interaction (commenters) list (owner only).
  static Future<FeedServerApiResponse<void>> addToInteractionList({
    required String slug,
    required String address,
    String? expiresAt,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final data = <String, dynamic>{'address': address};
      if (expiresAt != null) data['expires_at'] = expiresAt;

      final response = await PublicOSSsp.signedRequest(
        method: 'POST',
        endpoint: '/api/$accountAddress/channels/$slug/interaction-list',
        action: 'add_interaction_list',
        data: data,
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return FeedServerApiResponse.success(null);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Remove address from the channel's interaction list (owner only).
  static Future<FeedServerApiResponse<void>> removeFromInteractionList({
    required String slug,
    required String address,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final response = await PublicOSSsp.signedRequest(
        method: 'DELETE',
        endpoint: '/api/$accountAddress/channels/$slug/interaction-list/$address',
        action: 'remove_interaction_list',
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200) {
        return FeedServerApiResponse.success(null);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// List the channel's interaction-list entries (owner only).
  static Future<FeedServerApiResponse<List<WhitelistEntry>>>
      listInteractionList({
    required String slug,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final response = await PublicOSSsp.signedRequest(
        method: 'GET',
        endpoint: '/api/$accountAddress/channels/$slug/interaction-list',
        action: 'list_interaction_list',
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Server answers with a raw array of entry rows.
        final list = data is List ? data : (data['entries'] as List? ?? []);
        final entries = list
            .map((e) => WhitelistEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        return FeedServerApiResponse.success(entries);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  ///*********************************************
  /// PER-POST INTERACTION RULES
  ///*********************************************
  ///
  /// One rule row gates BOTH a comment AND a reaction attempt by that
  /// address against the post; owner uses the post's CommentPolicy /
  /// ReactionPolicy enums for asymmetric access.

  /// Add a per-post interaction rule (allow or deny) for a specific address.
  /// Affects both comment and reaction attempts.
  /// URL: POST /api/:address/channels/:slug/posts/:postUid/interaction-rules
  static Future<FeedServerApiResponse<PostInteractionRule>>
      addPostInteractionRule({
    required String slug,
    required String postUid,
    required String address,
    required PostInteractionRuleType type,
    String? expiresAt,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final data = <String, dynamic>{
        'address': address,
        'rule': type.wireValue,
      };
      if (expiresAt != null) data['expires_at'] = expiresAt;

      final response = await PublicOSSsp.signedRequest(
        method: 'POST',
        endpoint:
            '/api/$accountAddress/channels/$slug/posts/$postUid/interaction-rules',
        action: 'add_interaction_rule',
        data: data,
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        // Server returns the rule object directly. Don't unwrap a 'rule' key
        // here — the entry itself has a string field named 'rule' ("allow"
        // or "deny") that would shadow a wrapper lookup.
        final ruleData = responseData.containsKey('uid') &&
                responseData.containsKey('address')
            ? responseData
            : (responseData['rule'] as Map<String, dynamic>? ?? responseData);
        return FeedServerApiResponse.success(
          PostInteractionRule.fromJson(ruleData),
        );
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// List all per-post interaction rules for a post (owner only).
  /// URL: GET /api/:address/channels/:slug/posts/:postUid/interaction-rules
  static Future<FeedServerApiResponse<List<PostInteractionRule>>>
      listPostInteractionRules({
    required String slug,
    required String postUid,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final response = await PublicOSSsp.signedRequest(
        method: 'GET',
        endpoint:
            '/api/$accountAddress/channels/$slug/posts/$postUid/interaction-rules',
        action: 'list_interaction_rules',
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data is List ? data : (data['rules'] as List? ?? []);
        final entries = list
            .map((e) => PostInteractionRule.fromJson(e as Map<String, dynamic>))
            .toList();
        return FeedServerApiResponse.success(entries);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Remove a per-post interaction rule by address + rule type (owner only).
  /// Allow + deny rules for the same (post, address) coexist independently —
  /// [type] is required so we delete only the targeted one.
  /// URL: DELETE /api/:address/channels/:slug/posts/:postUid/interaction-rules/:addr/:rule
  static Future<FeedServerApiResponse<void>> removePostInteractionRule({
    required String slug,
    required String postUid,
    required String address,
    required PostInteractionRuleType type,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final response = await PublicOSSsp.signedRequest(
        method: 'DELETE',
        endpoint:
            '/api/$accountAddress/channels/$slug/posts/$postUid/interaction-rules/$address/${type.wireValue}',
        action: 'remove_interaction_rule',
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return FeedServerApiResponse.success(null);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  ///*********************************************
  /// ACCOUNT PROFILE (server-side)
  ///*********************************************

  /// Update the server-side account profile for the signed-in user.
  ///
  /// This edits the feed server's own [FeedAccount] row (`display_name`,
  /// `bio`, `avatar_url`) via `PUT /api/account`. It does NOT touch the
  /// on-chain [Contact] — for that, use `PublicOSContacts.setRecord`.
  /// The two stores are independent: servers keep a lightweight mirror
  /// so they can render feeds without a chain round-trip.
  ///
  /// `username` is intentionally not in the signature — the server's
  /// `UpdateAccount` handler does not accept it. Username is set at
  /// account creation and immutable from this endpoint.
  ///
  /// Returns the refreshed [FeedAccount] on success.
  static Future<FeedServerApiResponse<FeedAccount>> updateFeedAccount({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final data = <String, dynamic>{};
      if (displayName != null) data['display_name'] = displayName;
      if (bio != null) data['bio'] = bio;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;

      if (data.isEmpty) {
        return FeedServerApiResponse.error({'code': 'NO_UPDATES', 'message': 'No fields to update'});
      }

      final response = await PublicOSSsp.signedRequest(
        method: 'PUT',
        endpoint: '/api/account',
        action: 'update_account',
        data: data,
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final accountMap = decoded is Map<String, dynamic>
            ? (decoded['account'] as Map<String, dynamic>? ?? decoded)
            : <String, dynamic>{};
        return FeedServerApiResponse.success(FeedAccount.fromJson(accountMap));
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  ///*********************************************
  /// ACCOUNT-WIDE MODERATION
  ///*********************************************
  //
  // Account-wide bans / posters / whitelist apply across every channel
  // the account owns. Takes precedence over channel-scoped rules (a
  // global ban always wins). The server uses the same action strings as
  // the channel-scoped variants — the routing (no `/channels/:slug/`
  // segment) is what selects the account-wide handler.
  //
  // Response shapes reuse `BanEntry` / `PostPermissionEntry` /
  // `WhitelistEntry` since all three already carry nullable `channelId`
  // (channelId==null on these rows). See model comments for details.

  // ---- Account bans -------------------------------------------------------

  /// Ban an address across **every** channel owned by the signed-in
  /// user. Route: `POST /api/:address/bans`.
  static Future<FeedServerApiResponse<void>> addAccountBan({
    required String address,
    String? reason,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final data = <String, dynamic>{'address': address};
      if (reason != null) data['reason'] = reason;

      final response = await PublicOSSsp.signedRequest(
        method: 'POST',
        endpoint: '/api/$accountAddress/bans',
        action: 'add_ban',
        data: data,
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return FeedServerApiResponse.success(null);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Remove an account-wide ban. Route: `DELETE /api/:address/bans/:addr`.
  static Future<FeedServerApiResponse<void>> removeAccountBan({
    required String address,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final response = await PublicOSSsp.signedRequest(
        method: 'DELETE',
        endpoint: '/api/$accountAddress/bans/$address',
        action: 'remove_ban',
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return FeedServerApiResponse.success(null);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// List all account-wide bans. Route: `GET /api/:address/bans`.
  static Future<FeedServerApiResponse<List<BanEntry>>> listAccountBans({
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final response = await PublicOSSsp.signedRequest(
        method: 'GET',
        endpoint: '/api/$accountAddress/bans',
        action: 'list_bans',
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data is List ? data : (data['bans'] as List? ?? []);
        final entries = list
            .map((e) => BanEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        return FeedServerApiResponse.success(entries);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  // ---- Account whitelist --------------------------------------------------

  /// Whitelist an address across **every** private channel owned by the
  /// signed-in user. Route: `POST /api/:address/whitelist`.
  static Future<FeedServerApiResponse<void>> addAccountToWhitelist({
    required String address,
    String? expiresAt,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final data = <String, dynamic>{'address': address};
      if (expiresAt != null) data['expires_at'] = expiresAt;

      final response = await PublicOSSsp.signedRequest(
        method: 'POST',
        endpoint: '/api/$accountAddress/whitelist',
        action: 'add_whitelist',
        data: data,
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return FeedServerApiResponse.success(null);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// Remove an account-wide whitelist entry.
  /// Route: `DELETE /api/:address/whitelist/:addr`.
  static Future<FeedServerApiResponse<void>> removeAccountFromWhitelist({
    required String address,
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final response = await PublicOSSsp.signedRequest(
        method: 'DELETE',
        endpoint: '/api/$accountAddress/whitelist/$address',
        action: 'remove_whitelist',
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return FeedServerApiResponse.success(null);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  /// List all account-wide whitelist entries.
  /// Route: `GET /api/:address/whitelist`.
  static Future<FeedServerApiResponse<List<WhitelistEntry>>>
      listAccountWhitelist({
    String? serverAddress,
  }) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'User not authenticated'});
      }
      if (PublicOS.currentBlockchainPrivateKey == null) {
        return FeedServerApiResponse.error({'code': 'UNAUTHORIZED', 'message': 'No blockchain private key available'});
      }

      final accountAddress = PublicOS.myPublicosAddress!;
      final response = await PublicOSSsp.signedRequest(
        method: 'GET',
        endpoint: '/api/$accountAddress/whitelist',
        action: 'list_whitelist',
        serverAddress: serverAddress,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data is List ? data : (data['whitelist'] as List? ?? []);
        final entries = list
            .map((e) => WhitelistEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        return FeedServerApiResponse.success(entries);
      } else {
        final errorData = jsonDecode(response.body);
        return FeedServerApiResponse.error(errorData['error'] ?? {'code': 'UNKNOWN', 'message': 'Unknown error'});
      }
    } catch (e) {
      return FeedServerApiResponse.error({'code': 'REQUEST_FAILED', 'message': e.toString()});
    }
  }

  ///*********************************************
  /// TRENDING (Explore)
  ///*********************************************

  /// A post permalink on its own server: base, owner, slug, uid.
  static final _trendingPostUrl = RegExp(
      r'^(https?://[^/]+)/api/(0x[0-9a-fA-F]{40})/channels/([^/]+)/posts/([^/?#]+)$');

  /// A channel URL on its own server: base, owner, slug.
  static final _trendingChannelUrl =
      RegExp(r'^(https?://[^/]+)/api/(0x[0-9a-fA-F]{40})/channels/([^/?#]+)$');

  /// GET /api/stats/trending/feed on the user's own SSP. null = nothing held
  /// yet (`{"trending": null}`) or the request failed.
  static Future<Map<String, dynamic>?> _getTrendingFeed(
      String kind, String? cut, String metric) async {
    final query = <String, String>{
      'kind': kind,
      'metric': metric,
      if (cut != null) 'cut': cut,
    };
    final endpoint = Uri(path: '/api/stats/trending/feed', queryParameters: query)
        .toString();
    try {
      final response = await PublicOSSsp.makeRequest('GET', endpoint);
      if (response.statusCode != 200) {
        Log.d(_tag, 'trending feed HTTP ${response.statusCode}');
        return null;
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body.containsKey('trending') && body['trending'] == null) return null;
      return body;
    } catch (e) {
      Log.d(_tag, 'trending feed failed: $e');
      return null;
    }
  }

  static TrendingList<T> _trendingList<T>(Map<String, dynamic> meta, List<T> items) {
    return TrendingList<T>(
      round: (meta['round'] as num?)?.toInt() ?? 0,
      closedAt: DateTime.fromMillisecondsSinceEpoch(
          ((meta['closed_at'] as num?)?.toInt() ?? 0) * 1000,
          isUtc: true),
      cut: meta['cut'] as String? ?? '',
      metric: meta['metric'] as String? ?? '',
      items: items,
    );
  }

  /// The trending posts of one window ([TrendingCut], null = the server's
  /// suggested window) and one list ([TrendingMetric]), in rank order.
  ///
  /// The posts come from the user's own SSP as a PublicOS Feed document of
  /// copies (spec § Documents of copies): each item as its own server served
  /// it, with the round facts beside it as `trending`. Each post keeps its
  /// canonical URL (owner, channel, server), so comments, reactions, Go to
  /// feed and the read beacon all go to the post's own server. The document
  /// has no page-level interactions call, so each item's own is fetched for
  /// its counts (plain, or signed where the reader signs that channel).
  /// Reading this list records no read anywhere.
  static Future<TrendingList<TrendingPost>?> getTrendingPosts({
    String? cut,
    String metric = TrendingMetric.readers,
  }) async {
    final body = await _getTrendingFeed('post', cut, metric);
    if (body == null) return null;
    final meta = body['trending'] as Map<String, dynamic>?;
    if (meta == null) return null;
    final items = body['items'] as List? ?? const [];
    final entries = meta['entries'] as List? ?? const [];
    final out = <TrendingPost>[];
    for (var i = 0; i < items.length && i < entries.length; i++) {
      final item = items[i];
      final entry = entries[i];
      if (item is! Map<String, dynamic> || entry is! Map) continue;
      final m = _trendingPostUrl.firstMatch(item['url'] as String? ?? '');
      if (m == null) continue;
      final base = m.group(1)!, owner = m.group(2)!, slug = m.group(3)!;
      var post = Post.fromFeedV1Item(
        item,
        channelOwnerAddress: owner,
        channelSlug: slug,
        serverAddress: base,
        feedUrl: '$base/api/$owner/channels/$slug/json',
        feedFoundAtAccountAddress: owner,
      );
      final ixUrl = post.interactionsUrl ?? '${post.url}/interactions';
      final interactions = await RssParser.fetchInteractions(ixUrl,
          signed: await PublicOSChannelSignin.shouldSign(post.url ?? ixUrl));
      final mine = interactions?.items[post.uid];
      if (mine != null) post = mine.applyTo(post);
      post = post.withInteractionUrls(baseUrl: base, ownerAddress: owner, slug: slug);
      out.add(TrendingPost(
        post: post,
        value: (entry['value'] as num?)?.toInt() ?? 0,
        ssp: entry['ssp'] as String? ?? '',
        verified: entry['verified'] == true,
      ));
    }
    return _trendingList(meta, out);
  }

  /// Explore's Latest: the network's newest public posts from the user's own
  /// SSP (`GET /api/stats/latest/feed`), in the list's order. Same document
  /// of copies as [getTrendingPosts], so each post keeps its canonical URL and
  /// everything it does goes home; each item's counts come from its own
  /// interactions call, fetched in parallel batches (a list can hold 100).
  /// null = nothing filled yet (`{"latest": null}`) or the request failed.
  /// Reading this list records no read anywhere.
  static Future<LatestList?> getLatestPosts() async {
    Map<String, dynamic> body;
    try {
      final response = await PublicOSSsp.makeRequest('GET', '/api/stats/latest/feed');
      if (response.statusCode != 200) {
        Log.d(_tag, 'latest feed HTTP ${response.statusCode}');
        return null;
      }
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      Log.d(_tag, 'latest feed failed: $e');
      return null;
    }
    final meta = body['latest'];
    if (meta is! Map<String, dynamic>) return null;
    final items = body['items'] as List? ?? const [];
    final entries = meta['entries'] as List? ?? const [];

    final parsed = <({Post post, String base, String owner, String slug, Map entry})>[];
    for (var i = 0; i < items.length && i < entries.length; i++) {
      final item = items[i];
      final entry = entries[i];
      if (item is! Map<String, dynamic> || entry is! Map) continue;
      final m = _trendingPostUrl.firstMatch(item['url'] as String? ?? '');
      if (m == null) continue;
      final base = m.group(1)!, owner = m.group(2)!, slug = m.group(3)!;
      parsed.add((
        post: Post.fromFeedV1Item(
          item,
          channelOwnerAddress: owner,
          channelSlug: slug,
          serverAddress: base,
          feedUrl: '$base/api/$owner/channels/$slug/json',
          feedFoundAtAccountAddress: owner,
        ),
        base: base,
        owner: owner,
        slug: slug,
        entry: entry,
      ));
    }

    Future<LatestPost> withCounts(
        ({Post post, String base, String owner, String slug, Map entry}) p) async {
      var post = p.post;
      try {
        final ixUrl = post.interactionsUrl ?? '${post.url}/interactions';
        final interactions = await RssParser.fetchInteractions(ixUrl,
            signed: await PublicOSChannelSignin.shouldSign(post.url ?? ixUrl));
        final mine = interactions?.items[post.uid];
        if (mine != null) post = mine.applyTo(post);
      } catch (_) {
        // No counts: the post still lists.
      }
      post = post.withInteractionUrls(
          baseUrl: p.base, ownerAddress: p.owner, slug: p.slug);
      return LatestPost(
        post: post,
        ssp: p.entry['ssp'] as String? ?? '',
        receivedAt: DateTime.tryParse(p.entry['received_at'] as String? ?? '')?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
    }

    const batch = 12;
    final out = <LatestPost>[];
    for (var i = 0; i < parsed.length; i += batch) {
      final end = i + batch < parsed.length ? i + batch : parsed.length;
      out.addAll(await Future.wait(parsed.sublist(i, end).map(withCounts)));
    }
    return LatestList(
      filledAt: DateTime.tryParse(meta['filled_at'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      items: out,
    );
  }

  /// The trending channels of one window and one list, in rank order. Each
  /// carries its channel URL on its own server; open [TrendingChannel.feedUrl]
  /// to read it there (where the read counts).
  static Future<TrendingList<TrendingChannel>?> getTrendingChannels({
    String? cut,
    String metric = TrendingMetric.readers,
  }) async {
    final body = await _getTrendingFeed('feed', cut, metric);
    final meta = body?['trending'] as Map<String, dynamic>?;
    if (meta == null) return null;
    final out = <TrendingChannel>[];
    for (final e in meta['channels'] as List? ?? const []) {
      if (e is! Map) continue;
      final url = e['url'] as String? ?? '';
      final m = _trendingChannelUrl.firstMatch(url);
      final raw = e['channel'];
      if (m == null || raw is! Map) continue;
      out.add(TrendingChannel(
        channel: Channel.fromJson(raw.cast<String, dynamic>(), serverAddress: m.group(1)),
        ownerAddress: m.group(2)!,
        channelUrl: url,
        value: (e['value'] as num?)?.toInt() ?? 0,
        ssp: e['ssp'] as String? ?? '',
        verified: e['verified'] == true,
      ));
    }
    return _trendingList(meta, out);
  }
}
