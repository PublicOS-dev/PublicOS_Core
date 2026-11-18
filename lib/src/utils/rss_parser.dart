import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:publicos_core/src/core/extensions/publicos_channel_signin.dart';
import 'package:publicos_core/src/core/extensions/publicos_ssp.dart';
import 'package:publicos_core/src/core/exceptions/feed_gate_exception.dart';
import 'package:publicos_core/src/core/exceptions/paywall_exception.dart';
import 'package:publicos_core/src/core/publicos_core.dart';
import 'package:publicos_core/src/models/feed_server/feed_server_models.dart';
import 'package:publicos_core/src/models/rss_models.dart';
import 'package:publicos_core/src/models/post.dart';
import 'package:publicos_core/src/utils/channel_url.dart';
import 'package:publicos_core/src/utils/log.dart';

class RssParser {
  static const _tag = 'RssParser';
  static const Duration _timeout = Duration(seconds: 30);

  /// Extract channel slug from URL pattern: /api/$address/channels/$slug/json or /api/$address/channels/$slug
  /// Returns null if the URL doesn't match the expected pattern
  static String? _extractSlugFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // Look for pattern: api / $address / channels / $slug / [json|rss|atom]
      // or: api / $address / channels / $slug
      final channelsIndex = pathSegments.indexOf('channels');
      if (channelsIndex == -1 || channelsIndex + 1 >= pathSegments.length) {
        return null;
      }

      // The slug is the segment right after 'channels'
      final slug = pathSegments[channelsIndex + 1];

      // Don't return format suffixes as slugs
      if (slug == 'json' || slug == 'rss' || slug == 'atom') {
        return null;
      }

      return slug.isNotEmpty ? slug : null;
    } catch (e) {
      Log.e(_tag, 'Error extracting slug from URL: $e');
      return null;
    }
  }

  /// Injectable HTTP client for tests (mock the 401 → assert ONE request).
  /// Production leaves it null and uses the package-level `http.get`.
  static http.Client? httpClient;

  /// True when [response] is the RFC 7235 envelope challenge:
  /// 401 + `WWW-Authenticate: PublicOS-Envelope …`, or the generic
  /// ENVELOPE_MISSING body for proxies that strip the header.
  static bool _isEnvelopeChallenge(http.Response response) {
    if (response.statusCode != 401) return false;
    final wa = response.headers['www-authenticate'] ?? '';
    if (wa.startsWith('PublicOS-Envelope')) return true;
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return body['error']?['code'] == 'ENVELOPE_MISSING';
    } catch (_) {
      return false;
    }
  }

  /// What a feed read accepts: the PublicOS Feed document first, then the
  /// open web's formats.
  static const feedAccept =
      'application/publicos-feed+json, application/feed+json, application/json, '
      'application/rss+xml, application/xml, text/xml';

  /// The plain-GET half of the fetch: the unsigned baseline, and the one
  /// retry a failed signed attempt falls back to.
  static Future<http.Response> _plainGet(
      String url, Map<String, String> conditional) {
    final headers = <String, String>{
      'User-Agent': 'PublicOS Feed Reader/1.0',
      'Accept': feedAccept,
      'Accept-Charset': 'utf-8',
      ...conditional,
    };
    final client = httpClient;
    final request = client == null
        ? http.get(Uri.parse(url), headers: headers)
        : client.get(Uri.parse(url), headers: headers);
    return request.timeout(_timeout);
  }

  /// A PublicOS channel URL (`/api/<owner>/channels/<slug>`, alone or with
  /// one of the four documents `/json` `/rss` `/atom` `/feed` after it) as
  /// its channel base plus the query it carried, or null for any other shape.
  /// Records and lists keep pointing at the export URLs; the reader asks the
  /// channel for its PublicOS Feed document at `<base>/feed` instead.
  static ({String base, String query})? channelDocumentTarget(String url) {
    final base = channelBaseOf(url);
    if (base == null) return null;
    final uri = Uri.parse(url);
    final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    const documents = {'json', 'rss', 'atom', 'feed'};
    final ok = segs.length == 4 ||
        (segs.length == 5 && documents.contains(segs[4]));
    if (!ok) return null;
    return (base: base, query: uri.query);
  }

  static String _withQuery(String url, String query) =>
      query.isEmpty ? url : '$url?$query';

  /// The second call of a page read (spec § Interactions): counts for every
  /// item and, when [signed], the reader's own facts. Signed when the reader
  /// signs this channel, and that is where a channel read is counted; a failed
  /// signed call falls back to the plain, counts-only answer once. Null when
  /// the server did not answer: the posts then stay "not measured", never
  /// zero.
  static Future<FeedInteractions?> fetchInteractions(String url,
      {required bool signed}) async {
    http.Response? response;
    if (signed) {
      try {
        response = await PublicOSSsp.signedRequestAtUrl(
          method: 'GET',
          url: url,
          action: 'read_feed',
          headers: const {'Accept': 'application/json'},
        ).timeout(_timeout);
      } catch (e) {
        Log.d(_tag, 'Signed interactions failed ($e) — one plain retry');
      }
      if (response != null && response.statusCode != 200) {
        Log.d(_tag,
            'Signed interactions answered ${response.statusCode} — one plain retry');
        response = null;
      }
    }
    try {
      response ??= await _plainGet(url, const {});
      if (response.statusCode != 200) {
        Log.d(_tag, 'Interactions $url answered ${response.statusCode}');
        return null;
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) return null;
      return FeedInteractions.fromJson(decoded);
    } catch (e) {
      Log.d(_tag, 'Interactions $url failed: $e');
      return null;
    }
  }

  /// Fetch a feed: a PublicOS channel's document, or a JSON Feed / RSS / Atom
  /// feed from the open web. Returns ParsedFeed with List<Post> directly.
  ///
  /// A PublicOS channel URL (see [channelDocumentTarget]) is read as its
  /// PublicOS Feed document at `<channel base>/feed`, whatever document the
  /// stored URL names; the posts keep the URL as given in `feedUrl`. A server
  /// that has no `/feed` (a 404) is read at the URL as given, plainly, like
  /// any outside feed. After the document, the page's interactions call fills
  /// the counts and the reader's own facts ([fetchInteractions]).
  ///
  /// Signing is governed by ONE input:
  /// the user's per-channel answer with the reader-wide default behind it —
  /// `PublicOSChannelSignin.shouldSign`. No session memory, no policy
  /// switch, no silent retry: a 401 challenge is a SIGNAL (it seeds the
  /// channel's row and surfaces typed as [FeedSigninRequired]), never a
  /// trigger to sign.
  /// [etag] / [lastModified] — HTTP validators from a previous fetch (see
  /// `FeedCache`). When supplied they are sent as `If-None-Match` /
  /// `If-Modified-Since`; an unchanged feed then answers **`304 Not Modified`
  /// with an empty body**, and this returns `ParsedFeed.notModifiedResult()` —
  /// nothing downloaded, nothing parsed. Callers MUST check
  /// [ParsedFeed.notModified] before reading `posts`: on a 304 the list is
  /// empty because the feed is *unchanged*, not because it is empty.
  ///
  /// Passing neither is exactly today's behaviour: a full download, every time.
  static Future<ParsedFeed> fetchFeed(
    String url, {
    String? feedFoundAtAccountAddress,
    String? feedTitle,
    String? etag,
    String? lastModified,
  }) async {
    // Keep original URL for storing on posts (must match ListFeed.feedUrl)
    final originalUrl = url;

    // A channel URL is asked for its document; the request URL is the only
    // thing that changes, the stored URL never does.
    final target = channelDocumentTarget(url);
    var requestUrl = target == null
        ? url
        : _withQuery('${target.base}/feed', target.query);
    // The page's interactions call, derivable without the body (a 304 has
    // none): the server names the same page on its own `interactions_url`.
    final derivedInteractionsUrl = target == null
        ? null
        : _withQuery('${target.base}/feed/interactions', target.query);

    // Whether this fetch carries the user's identity is decided by ONE input
    // — the user's answer for this channel (with the reader-wide default
    // behind it), and only with a key loaded. A gated channel answers its
    // document only to a signed read, so the document and the interactions
    // call sign under the same rule.
    final canSign = PublicOS.myPublicosAddress != null &&
        PublicOS.currentBlockchainPrivateKey != null;
    final wantSigned = await PublicOSChannelSignin.shouldSign(url);

    // Conditional-GET validators. Sent on BOTH paths — omitting them on the
    // signed path would mean the cache could only ever revalidate unsigned
    // fetches.
    final conditional = <String, String>{
      if (etag != null) 'If-None-Match': etag,
      if (lastModified != null) 'If-Modified-Since': lastModified,
    };

    Log.d(_tag,
        'fetchFeed called with URL: $requestUrl (signedFirst: $wantSigned, conditional: ${conditional.isNotEmpty})');
    try {
      Log.d(_tag, 'Making HTTP request...');
      http.Response response;
      if (wantSigned) {
        // Pre-send path: the reader signs this channel.
        http.Response? signed;
        try {
          signed = await PublicOSSsp.signedRequestAtUrl(
            method: 'GET',
            url: requestUrl,
            action: 'read_feed',
            headers: {'Accept': feedAccept, ...conditional},
          ).timeout(_timeout);
        } catch (e) {
          Log.d(_tag, 'Signed fetch failed ($e) — one unsigned retry');
        }
        // The signed answer STANDS unless it never happened (transport
        // error → null), the server says the ENVELOPE itself was the problem
        // (401 stale/replay/bad-sig — a plain retry can still serve a public
        // feed), or the server blew up (5xx). A 403 is an AUTHORITATIVE
        // denial and must surface as-is: falling back to plain swaps
        // PRIVATE_FEED_NOT_APPROVED (→ the locked gate) for the generic 401
        // challenge (→ a raw error screen) — the first live-test regression.
        final ok = signed != null &&
            signed.statusCode != 401 &&
            signed.statusCode < 500;
        response = ok ? signed : await _plainGet(requestUrl, conditional);
      } else {
        // Plain GET. A 401 challenge is a SIGNAL, never a trigger to
        // sign — there is no silent signed retry.
        response = await _plainGet(requestUrl, conditional);
      }

      // A channel-shaped URL on a server with no PublicOS Feed document: the
      // URL as given is read plainly, like any outside feed.
      var publicosDocument = target != null;
      if (publicosDocument &&
          requestUrl != originalUrl &&
          response.statusCode == 404) {
        Log.d(_tag, 'No /feed at ${target!.base} — reading $originalUrl as given');
        publicosDocument = false;
        requestUrl = originalUrl;
        response = await _plainGet(requestUrl, conditional);
      }

      Log.d(_tag, 'HTTP response received with status: ${response.statusCode}');

      // ── The sign-in signal ──────────────────────────────────────────
      // Served: the `PublicOS-Envelope` header is the signal; its ABSENCE on
      // a served 200 of a channel URL means the channel stopped accepting
      // sign-in (a header-less 304 is "no information" — a stripping proxy
      // must not delete the row on every revalidation).
      // Challenged (401): the challenge is the signal, mode `required` —
      // recorded only with a key loaded (rows are per signed-in session) and
      // surfaced TYPED so the client can ask (no decision) or lock (denied).
      // Core never opens a dialog. Without a key the plain
      // FEED_ERROR:ENVELOPE_MISSING below keeps today's gate screen.
      // Awaited (single PK writes) so the UI's post-load row query never
      // races the write.
      final adv = response.headers['publicos-envelope'];
      if (response.statusCode == 200 || response.statusCode == 304) {
        if (adv != null && adv.isNotEmpty) {
          await PublicOSChannelSignin.recordSignal(originalUrl, adv);
        } else if (response.statusCode == 200) {
          await PublicOSChannelSignin.clearSignal(originalUrl);
        }
      } else if (canSign && _isEnvelopeChallenge(response)) {
        await PublicOSChannelSignin.recordSignal(originalUrl, 'required');
        throw FeedSigninRequired(channelUrl: originalUrl);
      }

      // The whole point: an unchanged feed costs a round trip and nothing else.
      // Checked BEFORE the != 200 branch below, which would otherwise throw a
      // FEED_ERROR on the single most successful outcome we have.
      if (response.statusCode == 304) {
        Log.d(_tag, '304 Not Modified — serving from cache: $originalUrl');
        // The document is unchanged; its counts never were in it. The
        // interactions ride on the result for the caller's cached re-parse.
        final interactions = publicosDocument && derivedInteractionsUrl != null
            ? await fetchInteractions(derivedInteractionsUrl,
                signed: wantSigned && canSign)
            : null;
        return ParsedFeed.notModifiedResult(
          etag: response.headers['etag'] ?? etag,
          lastModified: response.headers['last-modified'] ?? lastModified,
          interactions: interactions,
        );
      }

      if (response.statusCode != 200) {
        String errorCode = 'HTTP_${response.statusCode}';
        Map<String, dynamic>? errorMap;
        try {
          final errorJson = jsonDecode(utf8.decode(response.bodyBytes));
          final rawError = errorJson is Map ? errorJson['error'] : null;
          if (rawError is Map) {
            errorMap = rawError.cast<String, dynamic>();
            if (errorMap['code'] is String) {
              errorCode = errorMap['code'] as String;
            }
          } else if (rawError is String) {
            // The feed handlers on older servers answer a bare string
            // (`{"error":"channel not found"}`), not the typed object.
            errorCode = switch (rawError.toLowerCase()) {
              'channel not found' => 'CHANNEL_NOT_FOUND',
              'account not found' => 'ACCOUNT_NOT_FOUND',
              _ => errorCode,
            };
          }
        } catch (_) {}
        // GONE: the feed no longer exists there.
        // Typed so the list renders "Channel not found" instead of filing it
        // as a blip and keeping a stale cached copy on screen.
        if (response.statusCode == 404) throw FeedGoneException(errorCode);
        // A refusal carries what its screen needs: a paywall the payable
        // entries + lapsed_at, and every 403 the channel object
        // (`error.channel`, server A4) — follow_status for the private lock,
        // is_private / read_identity for the rest. Collapsing that into a
        // `FEED_ERROR:<code>` string throws it away and forces the lock to
        // re-read the server itself. Both types still stringify to
        // `FEED_ERROR:<code>`, so callers matching on the message keep working.
        final server = serverOf(originalUrl);
        final paywall = PaywallException.tryFromErrorMap(
            response.statusCode, errorMap,
            serverAddress: server);
        if (paywall != null) throw paywall;
        final gate = FeedGateException.tryFromErrorMap(
            response.statusCode, errorMap,
            serverAddress: server);
        if (gate != null) throw gate;
        throw Exception('FEED_ERROR:$errorCode');
      }

      // Explicitly decode as UTF-8
      final responseBody = utf8.decode(response.bodyBytes);
      Log.d(_tag, 'Response body length: ${responseBody.length} characters');

      // Format detection now lives in [parseBody], so a cached body and a live
      // one go through exactly the same sniffing.
      final contentType = response.headers['content-type'] ?? '';

      var result = parseBody(
        responseBody,
        originalUrl,
        contentType: contentType,
        feedFoundAtAccountAddress: feedFoundAtAccountAddress,
        feedTitle: feedTitle,
      );

      // The second call: counts and the reader's own facts for this page.
      // The document names the call; a document without one is a curated
      // list and its items carry their own.
      if (result.isFeedV1) {
        final ixUrl = result.interactionsUrl ??
            (publicosDocument ? derivedInteractionsUrl : null);
        if (ixUrl != null) {
          final interactions =
              await fetchInteractions(ixUrl, signed: wantSigned && canSign);
          if (interactions != null) result = result.withInteractions(interactions);
        }
      }

      // Hand the raw body + validators back so the caller can cache them. The
      // body is what FeedCache stores; the validators are what make the NEXT
      // fetch a 304.
      return result.copyWithHttp(
        rawBody: responseBody,
        contentType: contentType,
        etag: response.headers['etag'],
        lastModified: response.headers['last-modified'],
      );
    } on FeedGateException {
      // Must escape TYPED (PaywallException is one). The catch-all below
      // rewraps everything into a generic Exception, which would erase the
      // entry list, the lapsed date and the channel object the lock screens
      // exist to render — while still looking fine, because the message
      // survives.
      rethrow;
    } on FeedSigninRequired {
      rethrow;
    } on FeedGoneException {
      rethrow;
    } catch (e) {
      Log.e(_tag, 'Exception in fetchFeed: $e');
      throw Exception('Error fetching feed: $e');
    }
  }

  /// Parse a feed body that is already in hand — no network.
  ///
  /// Split out of [fetchFeed] so a body served from `FeedCache` re-parses
  /// through **exactly the same code path** as a freshly-downloaded one. If the
  /// cached and live paths could parse differently, the cache would be a source
  /// of subtle divergence rather than a speed-up.
  ///
  /// [contentType] is optional; format is otherwise sniffed from the URL, the
  /// same way the live path does it.
  static ParsedFeed parseBody(
    String body,
    String originalUrl, {
    String? contentType,
    String? feedFoundAtAccountAddress,
    String? feedTitle,
  }) {
    final ct = contentType ?? '';
    final isJsonByUrl =
        originalUrl.endsWith('/json') || originalUrl.contains('/json?');
    final isJsonByContentType = ct.contains('json');
    // A channel URL names an export (`/rss`) while its body is the PublicOS
    // Feed document; the body itself is the third signal.
    final isJsonByBody = body.trimLeft().startsWith('{');

    if (isJsonByUrl || isJsonByContentType || isJsonByBody) {
      Map<String, dynamic>? json;
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) json = decoded;
      } catch (e) {
        Log.e(_tag, 'Error parsing JSON feed: $e');
      }
      if (json == null) {
        return ParsedFeed(
          title: 'JSON Feed (Parse Error)',
          description: 'The body is not a JSON object',
          link: originalUrl,
          posts: [],
          lastUpdated: DateTime.now(),
          parseError: 'The body is not a JSON object',
        );
      }
      Log.i(_tag,
          '[FeedDiag] parseBody url=$originalUrl ct=$ct len=${body.length} version=${json['version']}');
      if (json['version'] == ParsedFeed.feedV1) {
        Log.d(_tag, 'Detected PublicOS Feed document');
        final result = parseFeedV1(
          json,
          link: originalUrl,
          feedUrl: originalUrl,
          feedFoundAtAccountAddress: feedFoundAtAccountAddress,
          feedTitle: feedTitle,
        );
        Log.d(_tag, 'PublicOS Feed parsed, posts: ${result.posts.length}');
        return result;
      }
      Log.d(_tag, 'Detected JSON Feed format');
      final result = _parseJson(
        json,
        originalUrl,
        feedFoundAtAccountAddress: feedFoundAtAccountAddress,
        feedTitle: feedTitle,
      );
      Log.d(_tag, 'JSON parsing completed, posts: ${result.posts.length}');
      return result;
    }
    Log.d(_tag, 'Detected XML (RSS/Atom) format');
    final result = _parseXml(
      body,
      originalUrl,
      feedFoundAtAccountAddress: feedFoundAtAccountAddress,
      feedTitle: feedTitle,
    );
    Log.d(_tag, 'XML parsing completed, posts: ${result.posts.length}');
    return result;
  }

  /// A PublicOS Feed document (spec § The document), decoded. [link] is the
  /// URL the document was read at (or the stored URL it stands for); [feedUrl]
  /// is what the posts record as their feed, the URL as the user holds it.
  /// Counts and the reader's own facts are not in the document: see
  /// [fetchInteractions] and [ParsedFeed.withInteractions].
  static ParsedFeed parseFeedV1(
    Map<String, dynamic> doc, {
    required String link,
    String? feedUrl,
    String? feedFoundAtAccountAddress,
    String? feedTitle,
  }) {
    final channel = doc['channel'] is Map
        ? (doc['channel'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final access = channel['access'] is Map
        ? (channel['access'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final owner = _nonEmpty(channel['owner']);
    final slug = _nonEmpty(channel['slug']);
    final posting = _nonEmpty(channel['posting']);
    // A forum = more than one author: `open` (anyone who may) and
    // `approved` (the people on its posters list). Only `owner`
    // is a single-author feed.
    final bool? isForumChannel =
        posting == null ? null : (posting == 'open' || posting == 'approved');
    final title = feedTitle ?? _nonEmpty(channel['title']) ?? 'PublicOS Feed';
    final description = channel['description'] as String? ?? '';
    final icon = _nonEmpty(channel['icon']);
    final language = _nonEmpty(channel['language']);
    final server = serverOf(link);

    final items = doc['items'];
    final posts = <Post>[];
    if (items is List) {
      for (final item in items.whereType<Map>()) {
        final map = item.cast<String, dynamic>();
        try {
          posts.add(Post.fromFeedV1Item(
            map,
            feedFoundAtAccountAddress: feedFoundAtAccountAddress,
            feedTitle: title,
            feedUrl: feedUrl,
            channelSlug: slug,
            channelOwnerAddress: owner,
            isForumChannel: isForumChannel,
          ));
        } catch (e) {
          // DIAG: which item, and the runtime type of every field
          // the item parser casts to String?.
          final types = {
            for (final k in [
              'id', 'title', 'text', 'summary', 'link', 'language', 'author',
              'comments', 'reactions', 'comment_identity', 'reaction_identity',
              'date_published', 'date_modified', 'comments_url',
              'interactions_url', 'url', 'signature', 'receipt', 'audio',
              'quote', 'in_reply_to', 'collaborators', 'acknowledgments',
              'hero_media', 'support_media', 'tags',
            ])
              if (map.containsKey(k)) k: map[k].runtimeType.toString(),
          };
          Log.e(_tag,
              '[FeedDiag] v1 item ${map['id']} failed: $e types=$types');
          rethrow;
        }
      }
    }

    final tags = channel['tags'] is List
        ? (channel['tags'] as List).whereType<String>().toList()
        : null;
    String tier(String key) => channel.isEmpty ? '' : (access[key] as String? ?? '');

    return ParsedFeed(
      title: title,
      description: description,
      link: link,
      imageUrl: icon,
      lastUpdated: DateTime.now(),
      posts: posts,
      language: language,
      version: ParsedFeed.feedV1,
      postingPolicy: posting,
      isPrivate: access['private'] == true,
      sensitive: channel['sensitive'] == true,
      tags: tags == null || tags.isEmpty ? null : tags,
      hasMore: _nonEmpty(doc['next_url']) != null,
      nextUrl: _nonEmpty(doc['next_url']),
      total: doc['total'] is num ? (doc['total'] as num).toInt() : null,
      interactionsUrl: _nonEmpty(doc['interactions_url']),
      channel: Channel(
        id: 0,
        accountId: 0,
        name: _nonEmpty(channel['title']) ?? '',
        description: description,
        slug: slug ?? '',
        iconUrl: icon,
        language: language ?? 'en',
        isPrivate: access['private'] == true,
        isPaid: access['paid'] == true,
        postingPolicy: posting ?? 'owner',
        readIdentity: tier('read_identity'),
        commentIdentity: tier('comment_identity'),
        reactionIdentity: tier('reaction_identity'),
        postingIdentity: tier('posting_identity'),
        ownerAddress: owner,
        serverAddress: server,
        createdAt: '',
        updatedAt: '',
      ),
    );
  }

  /// A JSON Feed 1.1 document from the open web, decoded.
  static ParsedFeed _parseJson(
    Map<String, dynamic> json,
    String feedUrl, {
    String? feedFoundAtAccountAddress,
    String? feedTitle,
  }) {
    Log.d(_tag, 'Starting JSON Feed parsing');
    try {
      final parsedFeedTitle = feedTitle ?? json['title'] as String? ?? 'JSON Feed';
      final feedDescription = json['description'] as String? ?? '';
      final feedImage = json['icon'] as String? ?? '';

      Log.d(_tag, 'Feed title: "$parsedFeedTitle"');

      final channelSlug = _extractSlugFromUrl(feedUrl);

      final items = (json['items'] as List<dynamic>?) ?? [];
      Log.d(_tag, 'Found ${items.length} items');

      final posts = <Post>[];
      for (final item in items.whereType<Map>()) {
        final itemMap = item.cast<String, dynamic>();
        final title = itemMap['title'] as String? ?? '';
        final contentText = itemMap['content_text'] as String? ?? '';
        // Include items that have a title OR content (microblog posts have no title)
        if (title.isNotEmpty || contentText.isNotEmpty) {
          posts.add(Post.fromJsonFeedItem(
            itemMap,
            feedFoundAtAccountAddress: feedFoundAtAccountAddress,
            feedTitle: parsedFeedTitle,
            feedUrl: feedUrl,
            channelSlug: channelSlug,
          ));
        }
      }

      Log.d(_tag, 'Successfully parsed ${posts.length} posts from JSON Feed');

      return ParsedFeed(
        title: parsedFeedTitle,
        description: feedDescription,
        link: feedUrl,
        posts: posts,
        lastUpdated: DateTime.now(),
        imageUrl: feedImage,
        siteUrl: _nonEmpty(json['home_page_url']),
        language: _nonEmpty(json['language']),
        version: _nonEmpty(json['version']),
      );
    } catch (e) {
      Log.e(_tag, '[FeedDiag] plain JSON Feed branch failed url=$feedUrl: $e');
      return ParsedFeed(
        title: 'JSON Feed (Parse Error)',
        description: 'Error parsing JSON Feed: $e',
        link: feedUrl,
        posts: [],
        lastUpdated: DateTime.now(),
        parseError: 'Error parsing JSON Feed: $e',
      );
    }
  }

  /// Parse XML RSS/Atom format - returns ParsedFeed with List<Post>
  static ParsedFeed _parseXml(
    String xmlData,
    String feedUrl, {
    String? feedFoundAtAccountAddress,
    String? feedTitle,
  }) {
    Log.d(_tag, 'Starting XML parsing for feed: $feedUrl');
    Log.d(_tag, 'XML data length: ${xmlData.length} characters');

    try {
      // Basic validation - check if this looks like XML
      if (!xmlData.trim().startsWith('<')) {
        throw Exception('Data does not appear to be XML');
      }

      // Clean up the XML data - remove any null bytes or control characters
      xmlData = xmlData.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');

      String parsedFeedTitle = feedTitle ?? _extractValue(xmlData, r'<title[^>]*>(.*?)</title>') ?? 'RSS Feed';
      String feedLink = _extractValue(xmlData, r'<link[^>]*>(.*?)</link>') ?? feedUrl;
      String? feedImage = _extractFeedImage(xmlData);
      // Feed-level fields come from the HEAD only (before the first item /
      // entry): otherwise a feed with no description of its own would borrow
      // its first item's.
      final head = _feedHead(xmlData);
      String feedDescription =
          _extractValue(head, r'<description[^>]*>(.*?)</description>') ??
              _extractValue(head, r'<subtitle[^>]*>(.*?)</subtitle>') ?? // Atom
              '';
      final siteUrl = _xmlSiteUrl(head);
      final language =
          _extractValue(head, r'<language[^>]*>(.*?)</language>') ??
              _extractValue(head, r'<dc:language[^>]*>(.*?)</dc:language>') ??
              _extractValue(head, r'''<feed\b[^>]*\bxml:lang=["']([^"']+)["']''');

      Log.d(_tag, 'Feed title: "$parsedFeedTitle"');
      Log.d(_tag, 'Feed description length: ${feedDescription.length}');

      // Handle both RSS and Atom feeds
      List<Post> posts = [];

      // Try RSS format first
      List<String> itemBlocks = _extractBlocks(xmlData, r'<item[^>]*>(.*?)</item>');

      // If no RSS items found, try Atom format
      if (itemBlocks.isEmpty) {
        Log.d(_tag, 'No RSS items found, trying Atom format');
        itemBlocks = _extractBlocks(xmlData, r'<entry[^>]*>(.*?)</entry>');
      }

      Log.d(_tag, 'Found ${itemBlocks.length} item blocks');

      int successfulItems = 0;
      for (int i = 0; i < itemBlocks.length; i++) {
        try {
          final post = _parseXmlItemToPost(
            itemBlocks[i],
            feedFoundAtAccountAddress: feedFoundAtAccountAddress,
            feedTitle: parsedFeedTitle,
            feedUrl: feedUrl,
          );
          if (post != null) {
            posts.add(post);
            successfulItems++;
          }
        } catch (e) {
          Log.w(_tag, 'Failed to parse item $i: $e');
          // Skip items that fail to parse
          continue;
        }
      }

      Log.d(_tag, 'Successfully parsed $successfulItems out of ${itemBlocks.length} items');

      // Sort posts by date (newest first)
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return ParsedFeed(
        title: _cleanText(parsedFeedTitle),
        description: _cleanText(feedDescription),
        link: feedLink.trim(),
        posts: posts,
        lastUpdated: DateTime.now(),
        imageUrl: feedImage,
        siteUrl: siteUrl,
        language: language?.trim(),
      );
    } catch (e) {
      Log.e(_tag, 'Error in _parseXml: $e');
      // Return a basic feed with error information
      return ParsedFeed(
        title: 'RSS Feed (Parse Error)',
        description: 'Error parsing RSS feed: $e',
        link: feedUrl,
        posts: [],
        lastUpdated: DateTime.now(),
        imageUrl: null,
        parseError: 'Error parsing RSS feed: $e',
      );
    }
  }

  static List<String> _extractBlocks(String xml, String pattern) {
    try {
      final regex = RegExp(pattern, caseSensitive: false, dotAll: true);
      final matches = regex.allMatches(xml);
      final blocks = <String>[];

      for (final match in matches) {
        final block = match.group(1);
        if (block != null && block.trim().isNotEmpty) {
          blocks.add(block);
        }
      }

      Log.d(_tag, 'Extracted ${blocks.length} blocks with pattern: $pattern');
      return blocks;
    } catch (e) {
      Log.e(_tag, 'Error extracting blocks with pattern $pattern: $e');
      return [];
    }
  }

  /// The feed's own header: everything before the first `<item` (RSS) or
  /// `<entry` (Atom). Feed-level reads run on this so an item's fields can
  /// never pose as the feed's.
  static String _feedHead(String xml) {
    final m = RegExp(r'<(item|entry)\b', caseSensitive: false).firstMatch(xml);
    return m == null ? xml : xml.substring(0, m.start);
  }

  /// The website the feed declares, from its [head]. RSS: `<link>url</link>`.
  /// Atom: the `<link href>` with `rel="alternate"` or no `rel` (the Atom
  /// default); `rel="self"` is the feed itself and is skipped. Null if none.
  static String? _xmlSiteUrl(String head) {
    final rss = _extractValue(head, r'<link>(.*?)</link>');
    if (rss != null && rss.startsWith('http')) return rss;
    for (final m in RegExp(r'<link\b([^>]*)/?>', caseSensitive: false)
        .allMatches(head)) {
      final attrs = m.group(1) ?? '';
      final rel = RegExp(r'''\brel=["']([^"']*)["']''', caseSensitive: false)
          .firstMatch(attrs)
          ?.group(1)
          ?.toLowerCase();
      if (rel != null && rel != 'alternate') continue;
      final href = RegExp(r'''\bhref=["']([^"']+)["']''', caseSensitive: false)
          .firstMatch(attrs)
          ?.group(1);
      if (href != null && href.startsWith('http')) return href;
    }
    return null;
  }

  static String? _nonEmpty(Object? v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  static String? _extractValue(String xml, String pattern) {
    try {
      final regex = RegExp(pattern, caseSensitive: false, dotAll: true);
      final match = regex.firstMatch(xml);
      final value = match?.group(1)?.trim();

      if (value != null && value.isNotEmpty) {
        return value;
      }
      return null;
    } catch (e) {
      Log.e(_tag, 'Error extracting value with pattern $pattern: $e');
      return null;
    }
  }

  static String? _extractFeedImage(String xml) {
    // Try different image formats in order of preference
    
    // 1. RSS 2.0 format: <image><url>...</url></image>
    String? imageUrl = _extractValue(xml, r'<image[^>]*>.*?<url[^>]*>(.*?)</url>.*?</image>');
    
    // 2. Atom format: <logo>...</logo>
    imageUrl ??= _extractValue(xml, r'<logo[^>]*>(.*?)</logo>');
    
    // 3. Simple format: <image>URL</image> (only if it looks like a URL)
    if (imageUrl == null) {
      final simpleImage = _extractValue(xml, r'<image[^>]*>(.*?)</image>');
      if (simpleImage != null && _isValidUrl(simpleImage.trim())) {
        imageUrl = simpleImage;
      }
    }
    
    return imageUrl?.trim();
  }
  
  static bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && 
             (uri.scheme == 'http' || uri.scheme == 'https') &&
             uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Parse XML item directly to Post
  static Post? _parseXmlItemToPost(
    String itemXml, {
    String? feedFoundAtAccountAddress,
    String? feedTitle,
    String? feedUrl,
  }) {
    String? title = _extractValue(itemXml, r'<title[^>]*>(.*?)</title>');
    String? description = _extractValue(itemXml, r'<description[^>]*>(.*?)</description>');
    String? summary = _extractValue(itemXml, r'<summary[^>]*>(.*?)</summary>');
    String? content = _extractValue(itemXml, r'<content[^>]*>(.*?)</content>');
    String? contentEncoded = _extractValue(itemXml, r'<content:encoded[^>]*>(.*?)</content:encoded>');

    String? link = _extractValue(itemXml, r'<link[^>]*>(.*?)</link>');
    String? guid = _extractValue(itemXml, r'<guid[^>]*>(.*?)</guid>');
    String? author = _extractValue(itemXml, r'<author[^>]*>(.*?)</author>');
    String? creator = _extractValue(itemXml, r'<dc:creator[^>]*>(.*?)</dc:creator>');

    // Handle Atom link format
    if (link == null || link.isEmpty) {
      final atomLinkMatch = RegExp("<link[^>]*href=[\"'](.*?)[\"'][^>]*>", caseSensitive: false)
          .firstMatch(itemXml);
      link = atomLinkMatch?.group(1);
    }

    // Prefer content:encoded > content > description > summary
    description = contentEncoded ?? content ?? description ?? summary ?? '';
    description = _stripCDATA(description);

    String cleanLink = _stripCDATA(link ?? guid ?? '').trim();
    // vitalik.ca no longer resolves — use the ENS gateway
    cleanLink = cleanLink.replaceAll('vitalik.ca', 'vitalik.eth.limo');

    // Parse publication date
    DateTime pubDate = _parseDate(itemXml) ?? DateTime.now().subtract(const Duration(days: 1));

    // Extract images from various sources
    String? enclosureImageUrl = _extractEnclosureImageUrl(itemXml);
    String? descriptionImageUrl = _extractImageFromDescription(description);
    List<String>? mediaContentUrls = _extractMediaContentUrls(itemXml);

    // Skip items with neither title nor description (nothing to display)
    if ((title == null || title.trim().isEmpty) && description.trim().isEmpty) {
      return null;
    }

    return Post.fromXmlItemData(
      title: _cleanText(title ?? ''),
      description: description,
      link: cleanLink,
      publishedDate: pubDate,
      enclosureImageUrl: enclosureImageUrl,
      descriptionImageUrl: descriptionImageUrl,
      author: _cleanText(author ?? creator ?? ''),
      mediaContentUrls: mediaContentUrls,
      feedFoundAtAccountAddress: feedFoundAtAccountAddress,
      feedTitle: feedTitle,
      feedUrl: feedUrl,
    );
  }


  static DateTime? _parseDate(String itemXml) {
    // Try different date formats
    String? pubDate = _extractValue(itemXml, r'<pubDate[^>]*>(.*?)</pubDate>');
    pubDate ??= _extractValue(itemXml, r'<published[^>]*>(.*?)</published>');
    pubDate ??= _extractValue(itemXml, r'<updated[^>]*>(.*?)</updated>');
    pubDate ??= _extractValue(itemXml, r'<dc:date[^>]*>(.*?)</dc:date>');

    if (pubDate == null) return null;

    pubDate = pubDate.trim();
    Log.d(_tag, 'Parsing date: "$pubDate"');

    try {
      // Try to parse ISO 8601 format (Atom) first
      if (pubDate.contains('T')) {
        try {
          // Extract timezone offset if present
          int timezoneOffsetMinutes = 0;
          String dateWithoutTz = pubDate;

          // Check for Z (UTC) indicator
          if (pubDate.endsWith('Z')) {
            dateWithoutTz = pubDate.substring(0, pubDate.length - 1);
            timezoneOffsetMinutes = 0;
          } else {
            // Check for numeric timezone offset (+00:00, +0000, -05:00, etc.)
            final tzMatch = RegExp(r'([+-])(\d{2}):?(\d{2})\s*$').firstMatch(pubDate);
            if (tzMatch != null) {
              final sign = tzMatch.group(1) == '+' ? 1 : -1;
              final hours = int.parse(tzMatch.group(2)!);
              final minutes = int.parse(tzMatch.group(3)!);
              timezoneOffsetMinutes = sign * (hours * 60 + minutes);
              dateWithoutTz = pubDate.substring(0, tzMatch.start);
              Log.d(_tag, 'Parsed ISO 8601 timezone offset: $timezoneOffsetMinutes minutes');
            }
          }

          // Parse the date portion
          final parsed = DateTime.parse(dateWithoutTz);

          // Convert to UTC by subtracting the timezone offset
          final utcDate = parsed.subtract(Duration(minutes: timezoneOffsetMinutes));

          Log.d(_tag, 'Successfully parsed ISO 8601 date: $utcDate UTC (original: $pubDate)');
          return utcDate;
        } catch (e) {
          Log.d(_tag, 'Failed to parse as ISO 8601: $e');
        }
      }

      // Try to parse RFC 2822 format (e.g., "Fri, 19 Sep 2024 01:23:59 GMT")
      if (pubDate.contains(',')) {
        final months = {
          'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
          'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
        };

        // Split on comma and take the date part
        final datePart = pubDate.split(',').last.trim();
        final parts = datePart.split(RegExp(r'\s+'));

        // Expected format: "19 Sep 2024 01:23:59 GMT" or "19 Sep 2024 01:23:59 +0000"
        if (parts.length >= 3) {
          final day = int.tryParse(parts[0]);
          final monthStr = parts[1];
          final year = int.tryParse(parts[2]);

          final month = months[monthStr];

          if (day != null && month != null && year != null) {
            // Try to parse time if available
            int hour = 0, minute = 0, second = 0;
            if (parts.length >= 4 && parts[3].contains(':')) {
              final timeParts = parts[3].split(':');
              hour = int.tryParse(timeParts[0]) ?? 0;
              minute = int.tryParse(timeParts[1]) ?? 0;
              if (timeParts.length > 2) {
                second = int.tryParse(timeParts[2]) ?? 0;
              }
            }

            // Parse timezone offset if present
            int timezoneOffsetMinutes = 0;
            if (parts.length >= 5) {
              final tzString = parts[4];

              // Handle numeric offsets like +0000, -0500, +0530
              final numericTzMatch = RegExp(r'^([+-])(\d{2})(\d{2})$').firstMatch(tzString);
              if (numericTzMatch != null) {
                final sign = numericTzMatch.group(1) == '+' ? 1 : -1;
                final hours = int.parse(numericTzMatch.group(2)!);
                final minutes = int.parse(numericTzMatch.group(3)!);
                timezoneOffsetMinutes = sign * (hours * 60 + minutes);
                Log.d(_tag, 'Parsed timezone offset: $tzString = $timezoneOffsetMinutes minutes');
              } else {
                // Handle named timezones (GMT, UTC, EST, etc.)
                final namedTimezones = {
                  'GMT': 0, 'UTC': 0, 'UT': 0,
                  'EST': -300, 'EDT': -240,
                  'CST': -360, 'CDT': -300,
                  'MST': -420, 'MDT': -360,
                  'PST': -480, 'PDT': -420,
                };
                timezoneOffsetMinutes = namedTimezones[tzString.toUpperCase()] ?? 0;
                if (namedTimezones.containsKey(tzString.toUpperCase())) {
                  Log.d(_tag, 'Parsed named timezone: $tzString = $timezoneOffsetMinutes minutes');
                }
              }
            }

            // Create UTC DateTime and adjust for timezone offset
            final utcDate = DateTime.utc(year, month, day, hour, minute, second);
            final adjustedDate = utcDate.subtract(Duration(minutes: timezoneOffsetMinutes));

            Log.d(_tag, 'Successfully parsed RFC 2822 date: $adjustedDate UTC (original: $pubDate)');
            return adjustedDate;
          }
        }
      }

      // Fallback: try simplified formats
      final parts = pubDate.split(RegExp(r'[\s\-/]+'));
      if (parts.length >= 3) {
        final year = int.tryParse(parts[0]) ?? int.tryParse(parts[2]);
        final month = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]) ?? int.tryParse(parts[0]);

        if (year != null && month != null && day != null) {
          final parsed = DateTime(year, month, day);
          Log.d(_tag, 'Successfully parsed simple date format: $parsed');
          return parsed;
        }
      }

    } catch (e) {
      Log.e(_tag, 'Exception parsing date "$pubDate": $e');
    }

    // Return null instead of DateTime.now() to indicate parsing failure
    Log.w(_tag, 'Failed to parse date "$pubDate", returning null');
    return null;
  }

  static String? _extractImageFromDescription(String description) {
    // Extract image URLs from description HTML
    final imgRegex = RegExp("<img[^>]+src=[\"'](.*?)[\"']", caseSensitive: false);
    final match = imgRegex.firstMatch(description);
    return match?.group(1);
  }

  /// Extract image URL from <enclosure> tag with image/* MIME type
  static String? _extractEnclosureImageUrl(String itemXml) {
    // Match enclosure tags with type="image/..." (jpeg, png, gif, webp, etc.)
    final enclosureRegex = RegExp(
      r'<enclosure[^>]+url\s*=\s*["\x27]([^"\x27]+)["\x27][^>]+type\s*=\s*["\x27]image/[^"\x27]+["\x27][^>]*>',
      caseSensitive: false,
    );

    var match = enclosureRegex.firstMatch(itemXml);
    if (match != null) {
      return match.group(1);
    }

    // Try reversed attribute order (type before url)
    final enclosureRegexReversed = RegExp(
      r'<enclosure[^>]+type\s*=\s*["\x27]image/[^"\x27]+["\x27][^>]+url\s*=\s*["\x27]([^"\x27]+)["\x27][^>]*>',
      caseSensitive: false,
    );

    match = enclosureRegexReversed.firstMatch(itemXml);
    if (match != null) {
      return match.group(1);
    }

    return null;
  }

  /// Scan `<media:content …>` opening tags attribute-order-agnostically,
  /// accept the `url=` value when ANY of:
  ///   - `medium="image"` is set (the historical CMS convention)
  ///   - `type="image/…"` is set
  ///   - the URL ends in a common image extension
  /// Many CMS-driven feeds emit `<media:content url="…">` with no `medium`
  /// attribute at all (e.g. expansion.mx), so a `medium="image"`-only
  /// match leaves the image undiscovered. The relaxation here keeps the
  /// legacy behavior as the first condition and adds two looser
  /// signals; false-positive risk is low because non-image media kinds
  /// (audio, video) carry their own `medium` or `type` that we don't
  /// match on.
  static List<String>? _extractMediaContentUrls(String itemXml) {
    final urls = <String>[];
    final tagRegex = RegExp(r'<media:content\b([^>]*)>', caseSensitive: false);
    for (final match in tagRegex.allMatches(itemXml)) {
      final attrs = match.group(1) ?? '';
      final url = _readAttr(attrs, 'url');
      if (url == null || url.isEmpty) continue;
      final medium = _readAttr(attrs, 'medium');
      final type = _readAttr(attrs, 'type');
      final looksImage = (medium != null && medium.toLowerCase() == 'image') ||
          (type != null && type.toLowerCase().startsWith('image/')) ||
          _hasImageExtension(url);
      if (looksImage && !urls.contains(url)) urls.add(url);
    }
    return urls.isEmpty ? null : urls;
  }

  static String? _readAttr(String attrs, String name) {
    final regex = RegExp(
      '\\b${RegExp.escape(name)}\\s*=\\s*["\\x27]([^"\\x27]+)["\\x27]',
      caseSensitive: false,
    );
    return regex.firstMatch(attrs)?.group(1);
  }

  static bool _hasImageExtension(String url) {
    final lower = url.split('?').first.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp') ||
        lower.endsWith('.avif') ||
        lower.endsWith('.heic');
  }

  /// Strip CDATA wrappers. Handles both literal `<![CDATA[…]]>` AND the
  /// entity-encoded anti-pattern `&lt;![CDATA[…]]&gt;` shipped by some
  /// CMS-driven feeds (e.g. expansion.mx) that escape their whole HTML
  /// payload as entities — including the CDATA delimiters themselves.
  /// For clean feeds the fast path returns identical bytes to the
  /// historical implementation. The entity-decode slow path engages
  /// only when `&lt;![CDATA[` is detected.
  static String _stripCDATA(String text) {
    if (text.isEmpty) return '';
    if (text.contains('<![CDATA[')) {
      return text.replaceAllMapped(
        RegExp(r'<!\[CDATA\[(.*?)\]\]>', dotAll: true),
        (match) => match.group(1) ?? '',
      );
    }
    if (text.contains('&lt;![CDATA[')) {
      final decoded = _decodeXmlEntities(text);
      return decoded.replaceAllMapped(
        RegExp(r'<!\[CDATA\[(.*?)\]\]>', dotAll: true),
        (match) => match.group(1) ?? '',
      );
    }
    return text;
  }

  /// Decode the 5 XML predefined entities. Used only as part of the
  /// `_stripCDATA` entity-encoded fallback — numeric entities are left
  /// to downstream rendering since they never change CDATA recognition.
  static String _decodeXmlEntities(String s) {
    return s
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&');
  }

  static String _cleanText(String text) {
    if (text.isEmpty) return '';

    try {
      // First extract CDATA content
      text = text.replaceAllMapped(RegExp(r'<!\[CDATA\[(.*?)\]\]>', dotAll: true), (match) {
        return match.group(1) ?? '';
      });

      // Remove HTML/XML tags but preserve content
      text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');

      // Handle common HTML entities
      final entities = {
        '&quot;': '"',
        '&amp;': '&',
        '&lt;': '<',
        '&gt;': '>',
        '&apos;': "'",
        '&nbsp;': ' ',
        '&hellip;': '...',
        '&mdash;': '—',
        '&ndash;': '–',
        '&rsquo;': "'",
        '&lsquo;': "'",
        '&rdquo;': '"',
        '&ldquo;': '"',
      };

      entities.forEach((entity, replacement) {
        text = text.replaceAll(entity, replacement);
      });

      // Handle numeric entities
      text = text.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
        try {
          final charCode = int.parse(match.group(1)!);
          return String.fromCharCode(charCode);
        } catch (e) {
          return ' ';
        }
      });

      // Handle hex entities
      text = text.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
        try {
          final charCode = int.parse(match.group(1)!, radix: 16);
          return String.fromCharCode(charCode);
        } catch (e) {
          return ' ';
        }
      });

      // Clean up any remaining entities
      text = text.replaceAll(RegExp(r'&[^;]+;'), ' ');

      // Normalize whitespace
      text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

      return text;
    } catch (e) {
      Log.e(_tag, 'Error cleaning text: $e');
      return text.trim();
    }
  }
}