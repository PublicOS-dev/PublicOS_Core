import 'package:publicos_core/src/utils/channel_url.dart' show postRefOf;
import 'package:publicos_core/src/utils/log.dart';
import 'package:wallet/wallet.dart';

/// RFC 3339 to the second, UTC, the `Z` form the PublicOS Feed signs
/// (`date_published`). `DateTime.toIso8601String` carries milliseconds and
/// is not what the server stores back, so the signed string is built here.
String rfc3339Seconds(DateTime t) {
  final u = t.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${u.year.toString().padLeft(4, '0')}-${two(u.month)}-${two(u.day)}'
      'T${two(u.hour)}:${two(u.minute)}:${two(u.second)}Z';
}

bool _isAddress(String s) =>
    s.length == 42 && RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(s);

String? _nonEmpty(Object? v) => v is String && v.isNotEmpty ? v : null;

int? _intOf(Object? v) => v is num ? v.toInt() : null;

/// A number written the way the servers marshal it: a whole value as an
/// integer (`17`, never `17.0`), a fractional one as is.
num _whole(num v) =>
    v is int ? v : (v.isFinite && v == v.roundToDouble() ? v.toInt() : v);

DateTime? _dateOf(Object? v) => v is String ? DateTime.tryParse(v) : null;

/// One media object of a PublicOS Feed item (spec § Media object): the shape
/// `hero_media`, `support_media` and `audio` all use. [toJson] writes the keys
/// in alphabetical order with nothing empty, which is the signed form.
class PostMedia {
  final String url;

  /// `image/jpeg`, `video/mp4`, `audio/mp4`, `application/pdf`... Empty when
  /// the source did not say (an RSS enclosure guessed from its URL); the card
  /// then dispatches on the URL.
  final String mimeType;

  /// SHA-256 of the file's bytes, lowercase hex. Signed with the post, so the
  /// file cannot be swapped behind the signature. Null when the source has
  /// none (the open web).
  final String? sha256;
  final int? sizeInBytes;

  /// Pixels. Required on hero items so a reader lays out before loading.
  final int? width;
  final int? height;

  /// A still that stands for the file before it loads. Stated, never built.
  final String? thumbnailUrl;

  /// Video and audio. May be fractional (`14.2`).
  final num? durationInSeconds;
  final String? title;
  final String? alt;

  /// Video and audio only: the author's intent. An ambient `audio` sets it.
  final bool loop;

  const PostMedia({
    required this.url,
    required this.mimeType,
    this.sha256,
    this.sizeInBytes,
    this.width,
    this.height,
    this.thumbnailUrl,
    this.durationInSeconds,
    this.title,
    this.alt,
    this.loop = false,
  });

  bool get isImage => mimeType.toLowerCase().startsWith('image/');
  bool get isVideo => mimeType.toLowerCase().startsWith('video/');
  bool get isAudio => mimeType.toLowerCase().startsWith('audio/');

  /// Renderable in a media slot: an image, a video, or a type the source left
  /// open (empty / octet-stream, dispatched on the URL at render time).
  bool get isRenderableMedia {
    final m = mimeType.toLowerCase();
    return m.isEmpty ||
        m == 'application/octet-stream' ||
        m.startsWith('image/') ||
        m.startsWith('video/');
  }

  factory PostMedia.fromJson(Map<String, dynamic> json) {
    final d = json['duration_in_seconds'];
    return PostMedia(
      url: json['url'] as String? ?? '',
      mimeType: json['mime_type'] as String? ?? '',
      sha256: _nonEmpty(json['sha256']),
      sizeInBytes: _intOf(json['size_in_bytes']),
      width: _intOf(json['width']),
      height: _intOf(json['height']),
      thumbnailUrl: _nonEmpty(json['thumbnail_url']),
      durationInSeconds: d is num ? _whole(d) : null,
      title: _nonEmpty(json['title']),
      alt: _nonEmpty(json['alt']),
      loop: json['loop'] == true,
    );
  }

  /// Alphabetical keys, empty values left out: the form the signed object
  /// carries and the body repeats.
  Map<String, dynamic> toJson() => {
        if (alt != null) 'alt': alt,
        if (durationInSeconds != null)
          'duration_in_seconds': _whole(durationInSeconds!),
        if (height != null) 'height': height,
        if (loop) 'loop': true,
        'mime_type': mimeType,
        if (sha256 != null) 'sha256': sha256,
        if (sizeInBytes != null) 'size_in_bytes': sizeInBytes,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        if (title != null) 'title': title,
        'url': url,
        if (width != null) 'width': width,
      };

  PostMedia copyWith({
    String? url,
    String? mimeType,
    String? sha256,
    int? sizeInBytes,
    int? width,
    int? height,
    String? thumbnailUrl,
    num? durationInSeconds,
    String? title,
    String? alt,
    bool? loop,
  }) =>
      PostMedia(
        url: url ?? this.url,
        mimeType: mimeType ?? this.mimeType,
        sha256: sha256 ?? this.sha256,
        sizeInBytes: sizeInBytes ?? this.sizeInBytes,
        width: width ?? this.width,
        height: height ?? this.height,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        durationInSeconds: durationInSeconds ?? this.durationInSeconds,
        title: title ?? this.title,
        alt: alt ?? this.alt,
        loop: loop ?? this.loop,
      );

  PostMediaItem toCarouselItem() => PostMediaItem(
        url: url,
        mimeType: mimeType,
        title: title,
        sizeInBytes: sizeInBytes,
        durationInSeconds: durationInSeconds?.round(),
      );

  static List<PostMedia> listFromJson(Object? raw) => raw is List
      ? raw
          .whereType<Map>()
          .map((m) => PostMedia.fromJson(m.cast<String, dynamic>()))
          .toList()
      : const [];
}

/// `{url, hash}`: the post another post quotes, reposts or answers
/// (spec § Quotes and reposts, § Replies). [hash] is null for an unsigned
/// original.
class PostPointer {
  final String url;
  final String? hash;

  const PostPointer({required this.url, this.hash});

  static PostPointer? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final url = raw['url'];
    if (url is! String || url.isEmpty) return null;
    return PostPointer(url: url, hash: _nonEmpty(raw['hash']));
  }

  Map<String, dynamic> toJson() => {
        if (hash != null) 'hash': hash,
        'url': url,
      };
}

/// The server's receipt for a signed post (spec § Dates): its signature over
/// the post hash and `date_received`, signed with the server's `stats_key`.
class PostReceipt {
  final String object;
  final String value;
  final String signer;

  const PostReceipt(
      {required this.object, required this.value, required this.signer});

  static PostReceipt? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final object = raw['object'], value = raw['value'];
    if (object is! String || value is! String) return null;
    return PostReceipt(
        object: object, value: value, signer: raw['signer'] as String? ?? '');
  }

  Map<String, dynamic> toJson() =>
      {'object': object, 'signer': signer, 'value': value};
}

/// A collaborator's signature over the post (spec § Collaborators). Stored
/// as served; whether it is valid is the reader's check.
class PostAcknowledgment {
  final String object;
  final String value;
  final String signer;

  const PostAcknowledgment(
      {required this.object, required this.value, required this.signer});

  static PostAcknowledgment? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final object = raw['object'], value = raw['value'];
    if (object is! String || value is! String) return null;
    return PostAcknowledgment(
        object: object, value: value, signer: raw['signer'] as String? ?? '');
  }

  static List<PostAcknowledgment> listFromJson(Object? raw) => raw is List
      ? raw.map(PostAcknowledgment.tryFromJson).whereType<PostAcknowledgment>().toList()
      : const [];

  Map<String, dynamic> toJson() =>
      {'object': object, 'signer': signer, 'value': value};
}

/// A post: one PublicOS Feed item, or one item of a JSON Feed / RSS / Atom
/// feed from the open web, in the one shape the card draws.
class Post {
  /// The item `id` (a server UUID on PublicOS; the feed's own id string on an
  /// outside JSON Feed; empty for RSS/Atom items).
  final String uid;

  final int? accountId;
  final int? channelId;

  /// Empty string for a post with no title.
  final String title;

  /// The body, plain text (`text`).
  final String? contentText;
  final String? summary;

  /// A page this post is about (`link`; an outside item's article URL).
  final String? externalUrl;

  final String? language;
  final List<String>? tags;

  /// The author line as the source wrote it. For a PublicOS item this is the
  /// `author` string; on a signed post it is the account's address, which
  /// [postAuthorAddress] then also carries.
  final List<PostAuthor>? authors;

  /// The post's lead media (spec § Hero and support media). Images, GIFs and
  /// videos, in the author's order, each with width and height.
  final List<PostMedia> heroMedia;

  /// Media that supports the text: any type.
  final List<PostMedia> supportMedia;

  /// The post's one sound track.
  final PostMedia? audio;

  /// The author wants the media to lead (spec § Media posts). Means something
  /// only with [heroMedia]; not signed.
  final bool mediaPost;

  /// The author's signed rating for this post. Null = the channel's.
  final bool? sensitive;

  /// `open` | `closed`. Null = the channel's (open).
  final String? commentPolicy;
  final bool? requireVerifiedComments;
  final String? reactionPolicy;
  final bool? requireVerifiedReactions;

  /// EIP-191 signature (`signature.value`) over the UTF-8 bytes of
  /// [signedObject]. Null or empty on an unsigned post.
  final String? signature;

  /// The signed object, stringified exactly as signed (`signature.object`).
  final String? signedObject;

  /// The signer the server names (`signature.signer`). A hint only: the
  /// verifier recovers the key itself and never trusts this field.
  final String? signerAddress;

  /// `date_published`: when the author says they posted. Signed.
  final DateTime createdAt;

  /// Set by the server only when the post was edited.
  final DateTime? dateModified;

  /// When the server received it.
  final DateTime? dateReceived;

  /// The server's signature over the post hash and [dateReceived].
  final PostReceipt? receipt;

  /// The post this one quotes or reposts, and the one it answers. Stored;
  /// drawn in a later version.
  final PostPointer? quote;
  final PostPointer? inReplyTo;

  /// Accounts the author credits (an author setting, not signed) and the
  /// collaborators' own signatures the server attached. Stored, not drawn.
  final List<String> collaborators;
  final List<PostAcknowledgment> acknowledgments;

  // Interactions: counts from the interactions call, never from the document.
  final int? commentsCount;
  final String? commentsUrl;

  /// `emoji:count,emoji:count`. See [parsedReactions].
  final String? reactions;

  /// Reactions endpoint for this post. Never a server field: synthesized by
  /// [withInteractionUrls] together with [commentsUrl], so neither feature
  /// can outlive the other.
  final String? reactionsUrl;

  /// The post's own interactions call, for a single post or a document of
  /// copies (`interactions_url`).
  final String? interactionsUrl;

  final int score;
  final int upvotes;
  final int downvotes;

  /// The reader's own vote: 1, -1, or null.
  final int? userVote;

  /// The emojis the reader reacted with. Null when not measured.
  final List<String>? viewerReactions;

  /// The server's answers for THIS reader on a signed interactions or
  /// comments call: may they comment (and vote) / react here. Null = not
  /// asked; then the post's own settings decide.
  final bool? canCommentAnswer;
  final bool? canReactAnswer;

  /// The account that wrote the post. Set only when the post is signed and
  /// its `author` is an address: an unsigned author is a display string and is
  /// never resolved to an account (spec § Authors).
  final String? postAuthorAddress;

  // Where the feed URL was found: the PublicOS account whose record tab (or
  // channel listing) carried this feed URL when the user added it. Route
  // metadata, not authorship.
  final String? feedFoundAtAccountAddress;

  /// The router `record.key` of the channel tab on [feedFoundAtAccountAddress]
  /// this post's feed was found through. Host-stamped, never parsed.
  final String? feedRecordKey;
  final String? feedTitle;
  final String? feedUrl;
  final String? channelSlug;

  /// The account that owns this post's channel.
  final String? channelOwnerAddress;

  /// Whether this post lives in a forum-style channel (`posting == "open"`).
  /// Null when the origin policy is unknown (the open web).
  final bool? isForumChannel;

  /// The server that hosts this post (`<scheme>://<host>`). Null for posts
  /// from the open web.
  final String? serverAddress;

  /// The post's permalink on its server.
  final String? url;

  Post({
    this.uid = '',
    this.accountId,
    this.channelId,
    required this.title,
    this.contentText,
    this.summary,
    this.externalUrl,
    this.language,
    this.tags,
    this.authors,
    this.heroMedia = const [],
    this.supportMedia = const [],
    this.audio,
    this.mediaPost = false,
    this.sensitive,
    this.commentPolicy,
    this.requireVerifiedComments,
    this.reactionPolicy,
    this.requireVerifiedReactions,
    this.signature,
    this.signedObject,
    this.signerAddress,
    required this.createdAt,
    this.dateModified,
    this.dateReceived,
    this.receipt,
    this.quote,
    this.inReplyTo,
    this.collaborators = const [],
    this.acknowledgments = const [],
    this.commentsCount,
    this.commentsUrl,
    this.reactions,
    this.reactionsUrl,
    this.interactionsUrl,
    this.score = 0,
    this.upvotes = 0,
    this.downvotes = 0,
    this.userVote,
    this.viewerReactions,
    this.canCommentAnswer,
    this.canReactAnswer,
    this.postAuthorAddress,
    this.feedFoundAtAccountAddress,
    this.feedRecordKey,
    this.feedTitle,
    this.feedUrl,
    this.channelSlug,
    this.channelOwnerAddress,
    this.isForumChannel,
    this.serverAddress,
    this.url,
  });

  /// The lossless local blob (bookmark rows). Flat, every field under one key;
  /// [Post.fromJson] is its exact inverse (test/post_roundtrip_test.dart).
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      if (accountId != null) 'account_id': accountId,
      if (channelId != null) 'channel_id': channelId,
      'title': title,
      if (contentText != null) 'content_text': contentText,
      if (summary != null) 'summary': summary,
      if (externalUrl != null) 'external_url': externalUrl,
      if (language != null) 'language': language,
      if (tags != null) 'tags': tags,
      if (authors != null) 'authors': authors!.map((a) => a.toJson()).toList(),
      if (heroMedia.isNotEmpty)
        'hero_media': heroMedia.map((m) => m.toJson()).toList(),
      if (supportMedia.isNotEmpty)
        'support_media': supportMedia.map((m) => m.toJson()).toList(),
      if (audio != null) 'audio': audio!.toJson(),
      if (mediaPost) 'media_post': true,
      if (sensitive != null) 'sensitive': sensitive,
      if (commentPolicy != null) 'comment_policy': commentPolicy,
      if (requireVerifiedComments != null)
        'require_verified_comments': requireVerifiedComments,
      if (reactionPolicy != null) 'reaction_policy': reactionPolicy,
      if (requireVerifiedReactions != null)
        'require_verified_reactions': requireVerifiedReactions,
      if (signature != null) 'signature': signature,
      if (signedObject != null) 'signed_object': signedObject,
      if (signerAddress != null) 'signer_address': signerAddress,
      'created_at': createdAt.toIso8601String(),
      if (dateModified != null) 'date_modified': dateModified!.toIso8601String(),
      if (dateReceived != null) 'date_received': dateReceived!.toIso8601String(),
      if (receipt != null) 'receipt': receipt!.toJson(),
      if (quote != null) 'quote': quote!.toJson(),
      if (inReplyTo != null) 'in_reply_to': inReplyTo!.toJson(),
      if (collaborators.isNotEmpty) 'collaborators': collaborators,
      if (acknowledgments.isNotEmpty)
        'acknowledgments': acknowledgments.map((a) => a.toJson()).toList(),
      if (commentsCount != null) 'comments_count': commentsCount,
      if (commentsUrl != null) 'comments_url': commentsUrl,
      if (reactions != null) 'reactions': reactions,
      if (reactionsUrl != null) 'reactions_url': reactionsUrl,
      if (interactionsUrl != null) 'interactions_url': interactionsUrl,
      'score': score,
      'upvotes': upvotes,
      'downvotes': downvotes,
      if (userVote != null) 'user_vote': userVote,
      if (viewerReactions != null) 'viewer_reactions': viewerReactions,
      if (canCommentAnswer != null) 'can_comment': canCommentAnswer,
      if (canReactAnswer != null) 'can_react': canReactAnswer,
      if (postAuthorAddress != null) 'author_address': postAuthorAddress,
      if (feedFoundAtAccountAddress != null)
        'feed_found_at_account_address': feedFoundAtAccountAddress,
      if (feedRecordKey != null) 'feed_record_key': feedRecordKey,
      if (feedTitle != null) 'feed_title': feedTitle,
      if (feedUrl != null) 'feed_url': feedUrl,
      if (channelSlug != null) 'channel_slug': channelSlug,
      if (channelOwnerAddress != null)
        'channel_owner_address': channelOwnerAddress,
      if (isForumChannel != null) 'is_forum_channel': isForumChannel,
      if (serverAddress != null) 'server_address': serverAddress,
      if (url != null) 'url': url,
    };
  }

  /// Exact inverse of [toJson]: the ONLY correct way to rehydrate a post
  /// stored via `jsonEncode(post.toJson())`. The feed factories take the
  /// feed-level enrichment as arguments a stored blob has no caller to supply.
  factory Post.fromJson(Map<String, dynamic> json) {
    final audio = json['audio'];
    return Post(
      uid: json['uid'] as String? ?? '',
      accountId: json['account_id'] as int?,
      channelId: json['channel_id'] as int?,
      title: json['title'] as String? ?? '',
      contentText: json['content_text'] as String?,
      summary: json['summary'] as String?,
      externalUrl: json['external_url'] as String?,
      language: json['language'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      authors: (json['authors'] as List<dynamic>?)
          ?.map((e) => PostAuthor.fromJson(e as Map<String, dynamic>))
          .toList(),
      heroMedia: PostMedia.listFromJson(json['hero_media']),
      supportMedia: PostMedia.listFromJson(json['support_media']),
      audio: audio is Map
          ? PostMedia.fromJson(audio.cast<String, dynamic>())
          : null,
      mediaPost: json['media_post'] == true,
      sensitive: json['sensitive'] as bool?,
      commentPolicy: json['comment_policy'] as String?,
      requireVerifiedComments: json['require_verified_comments'] as bool?,
      reactionPolicy: json['reaction_policy'] as String?,
      requireVerifiedReactions: json['require_verified_reactions'] as bool?,
      signature: json['signature'] as String?,
      signedObject: json['signed_object'] as String?,
      signerAddress: json['signer_address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      dateModified: _dateOf(json['date_modified']),
      dateReceived: _dateOf(json['date_received']),
      receipt: PostReceipt.tryFromJson(json['receipt']),
      quote: PostPointer.tryFromJson(json['quote']),
      inReplyTo: PostPointer.tryFromJson(json['in_reply_to']),
      collaborators:
          (json['collaborators'] as List<dynamic>?)?.cast<String>() ?? const [],
      acknowledgments: PostAcknowledgment.listFromJson(json['acknowledgments']),
      commentsCount: json['comments_count'] as int?,
      commentsUrl: json['comments_url'] as String?,
      reactions: json['reactions'] as String?,
      reactionsUrl: json['reactions_url'] as String?,
      interactionsUrl: json['interactions_url'] as String?,
      score: json['score'] as int? ?? 0,
      upvotes: json['upvotes'] as int? ?? 0,
      downvotes: json['downvotes'] as int? ?? 0,
      userVote: json['user_vote'] as int?,
      viewerReactions: (json['viewer_reactions'] as List<dynamic>?)?.cast<String>(),
      canCommentAnswer: json['can_comment'] as bool?,
      canReactAnswer: json['can_react'] as bool?,
      postAuthorAddress: json['author_address'] as String?,
      feedFoundAtAccountAddress:
          json['feed_found_at_account_address'] as String?,
      feedRecordKey: json['feed_record_key'] as String?,
      feedTitle: json['feed_title'] as String?,
      feedUrl: json['feed_url'] as String?,
      channelSlug: json['channel_slug'] as String?,
      channelOwnerAddress: json['channel_owner_address'] as String?,
      isForumChannel: json['is_forum_channel'] as bool?,
      serverAddress: json['server_address'] as String?,
      url: json['url'] as String?,
    );
  }

  /// One item of a PublicOS Feed document (spec § Item), or the single post
  /// `GET …/posts/:uid` answers. Counts and the reader's own facts are not in
  /// the item; the interactions call fills them (`ItemInteractions.applyTo`).
  ///
  /// The channel coordinates are read off the item's own `url` when the
  /// caller does not pass them, so an item copied into another document (a
  /// trending list) still points at its home server.
  factory Post.fromFeedV1Item(
    Map<String, dynamic> json, {
    String? feedFoundAtAccountAddress,
    String? feedTitle,
    String? feedUrl,
    String? channelSlug,
    String? channelOwnerAddress,
    bool? isForumChannel,
    String? serverAddress,
  }) {
    final url = _nonEmpty(json['url']);
    final ref = url == null ? null : postRefOf(url);

    final sig = json['signature'];
    final signedObject = sig is Map ? _nonEmpty(sig['object']) : null;
    final signature = sig is Map ? _nonEmpty(sig['value']) : null;
    final signer = sig is Map ? _nonEmpty(sig['signer']) : null;
    final isSigned = signedObject != null && signature != null;

    final author = json['author'] as String? ?? '';
    final audio = json['audio'];

    return Post(
      uid: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      contentText: json['text'] as String?,
      summary: json['summary'] as String?,
      externalUrl: json['link'] as String?,
      language: json['language'] as String?,
      tags: _parseTags(json['tags']),
      authors: author.isEmpty ? null : [PostAuthor(name: author)],
      heroMedia: PostMedia.listFromJson(json['hero_media']),
      supportMedia: PostMedia.listFromJson(json['support_media']),
      audio: audio is Map
          ? PostMedia.fromJson(audio.cast<String, dynamic>())
          : null,
      mediaPost: json['media_post'] == true,
      sensitive: json['sensitive'] as bool?,
      commentPolicy: json['comments'] as String?,
      requireVerifiedComments:
          json['comment_identity'] == 'citizen' ? true : null,
      reactionPolicy: json['reactions'] as String?,
      requireVerifiedReactions:
          json['reaction_identity'] == 'citizen' ? true : null,
      signature: signature,
      signedObject: signedObject,
      signerAddress: signer,
      createdAt: _dateOf(json['date_published']) ?? DateTime.now(),
      dateModified: _dateOf(json['date_modified']),
      dateReceived: _dateOf(json['date_received']),
      receipt: PostReceipt.tryFromJson(json['receipt']),
      quote: PostPointer.tryFromJson(json['quote']),
      inReplyTo: PostPointer.tryFromJson(json['in_reply_to']),
      collaborators: (json['collaborators'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      acknowledgments: PostAcknowledgment.listFromJson(json['acknowledgments']),
      commentsUrl: _nonEmpty(json['comments_url']),
      interactionsUrl: _nonEmpty(json['interactions_url']),
      postAuthorAddress: isSigned && _isAddress(author) ? author : null,
      feedFoundAtAccountAddress: feedFoundAtAccountAddress,
      feedTitle: feedTitle,
      feedUrl: feedUrl,
      channelSlug: channelSlug ?? ref?.slug,
      channelOwnerAddress: channelOwnerAddress ?? ref?.owner,
      isForumChannel: isForumChannel,
      serverAddress: serverAddress ?? ref?.server,
      url: url,
    );
  }

  /// One item of a JSON Feed 1.1 document from the open web. The item's
  /// `banner_image` (else `image`) leads as the hero; a second picture and the
  /// `attachments` support the text. The item `url` is the article it links to.
  factory Post.fromJsonFeedItem(
    Map<String, dynamic> json, {
    String? feedFoundAtAccountAddress,
    String? feedTitle,
    String? feedUrl,
    String? channelSlug,
    String? channelOwnerAddress,
    bool? isForumChannel,
    String? serverAddress,
  }) {
    List<PostAuthor>? authors;
    final authorsJson = json['authors'] as List<dynamic>?;
    if (authorsJson != null && authorsJson.isNotEmpty) {
      authors = authorsJson
          .whereType<Map>()
          .map((e) => PostAuthor.fromJson(e.cast<String, dynamic>()))
          .toList();
    }

    final image = _nonEmpty(json['image']);
    final banner = _nonEmpty(json['banner_image']);
    final lead = banner ?? image;
    final hero = <PostMedia>[];
    final support = <PostMedia>[];
    final seen = <String>{};
    if (lead != null) {
      hero.add(PostMedia(url: lead, mimeType: ''));
      seen.add(lead);
    }
    if (image != null && seen.add(image)) {
      support.add(PostMedia(url: image, mimeType: ''));
    }
    final attachments = json['attachments'];
    if (attachments is List) {
      for (final a in attachments.whereType<Map>()) {
        final aUrl = _nonEmpty(a['url']);
        if (aUrl == null || !seen.add(aUrl)) continue;
        final d = a['duration_in_seconds'];
        support.add(PostMedia(
          url: aUrl,
          mimeType: a['mime_type'] as String? ?? '',
          sizeInBytes: _intOf(a['size_in_bytes']),
          durationInSeconds: d is num ? _whole(d) : null,
          title: _nonEmpty(a['title']),
        ));
      }
    }

    return Post(
      uid: json['id'] is String ? json['id'] as String : '',
      title: json['title'] as String? ?? '',
      contentText: json['content_text'] as String?,
      summary: json['summary'] as String?,
      externalUrl: (json['external_url'] as String? ?? json['url'] as String?)
          ?.replaceAll('vitalik.ca', 'vitalik.eth.limo'),
      language: json['language'] as String?,
      tags: _parseTags(json['tags']),
      authors: authors,
      heroMedia: hero,
      supportMedia: support,
      createdAt: _dateOf(json['date_published']) ?? DateTime.now(),
      dateModified: _dateOf(json['date_modified']),
      feedFoundAtAccountAddress: feedFoundAtAccountAddress,
      feedTitle: feedTitle,
      feedUrl: feedUrl,
      channelSlug: channelSlug,
      channelOwnerAddress: channelOwnerAddress,
      isForumChannel: isForumChannel,
      serverAddress: serverAddress,
    );
  }

  /// One RSS / Atom item. The enclosure image (else the first picture in the
  /// body, else the first `media:content`) leads as the hero; the other
  /// pictures support the text.
  factory Post.fromXmlItemData({
    required String title,
    required String description,
    required String link,
    required DateTime publishedDate,
    String? enclosureImageUrl,
    String? descriptionImageUrl,
    String? author,
    List<String>? mediaContentUrls,
    String? feedFoundAtAccountAddress,
    String? feedTitle,
    String? feedUrl,
    String? channelSlug,
    String? serverAddress,
    String? url,
  }) {
    final primary = enclosureImageUrl ??
        descriptionImageUrl ??
        (mediaContentUrls?.isNotEmpty == true ? mediaContentUrls!.first : null);

    final hero = <PostMedia>[];
    final support = <PostMedia>[];
    final seen = <String>{};
    if (primary != null) {
      hero.add(PostMedia(url: primary, mimeType: ''));
      seen.add(primary);
    }
    if (descriptionImageUrl != null && seen.add(descriptionImageUrl)) {
      support.add(PostMedia(url: descriptionImageUrl, mimeType: ''));
    }
    for (final u in mediaContentUrls ?? const <String>[]) {
      if (seen.add(u)) support.add(PostMedia(url: u, mimeType: ''));
    }

    return Post(
      uid: '',
      title: title,
      contentText: _stripHtml(description),
      externalUrl: link,
      createdAt: publishedDate,
      // An outside XML feed carries no edit signal.
      dateModified: null,
      // No comment surface exists for an outside item.
      commentPolicy: 'closed',
      heroMedia: hero,
      supportMedia: support,
      feedFoundAtAccountAddress: feedFoundAtAccountAddress,
      feedTitle: feedTitle,
      feedUrl: feedUrl,
      channelSlug: channelSlug,
      serverAddress: serverAddress,
      url: url,
      authors: author != null && author.isNotEmpty
          ? [PostAuthor(name: author)]
          : null,
    );
  }

  /// Stamp the client-synthesized interaction endpoints, [commentsUrl] and
  /// [reactionsUrl], onto this post. Every load path that knows the channel
  /// coordinates calls this right after parsing, so both URLs are born
  /// together from the same base. Values already present win (the item's
  /// own `comments_url`). No-op for posts without a server UID.
  Post withInteractionUrls({
    required String baseUrl,
    required String ownerAddress,
    required String slug,
  }) {
    if (uid.isEmpty) return this;
    if (commentsUrl != null && reactionsUrl != null) return this;
    final postBase = '$baseUrl/api/$ownerAddress/channels/$slug/posts/$uid';
    return copyWith(
      commentsUrl: commentsUrl ?? '$postBase/comments',
      reactionsUrl: reactionsUrl ?? '$postBase/reactions',
    );
  }

  /// True when the item carries a signature pair. Whether it holds is the
  /// verifier's answer.
  bool get isSigned =>
      (signedObject?.isNotEmpty ?? false) && (signature?.isNotEmpty ?? false);

  /// The first hero item's URL: the one picture a banner slot shows.
  String? get bannerImage => heroMedia.isEmpty ? null : heroMedia.first.url;

  /// Get the content for display (always plain text)
  String? get displayContent => contentText;

  /// Get formatted description for list view
  String get formattedDescription {
    final text = summary ?? contentText ?? '';
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Parse reactions string into list of (emoji, count) pairs
  /// Format: "heart:1,fire:2" -> [('heart', 1), ('fire', 2)]
  List<(String emoji, int count)> get parsedReactions {
    if (reactions == null || reactions!.isEmpty) return [];

    final result = <(String, int)>[];
    final parts = reactions!.split(',');

    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;

      // Find the last colon (emoji might contain special chars)
      final lastColon = trimmed.lastIndexOf(':');
      if (lastColon == -1) continue;

      final emoji = trimmed.substring(0, lastColon);
      final countStr = trimmed.substring(lastColon + 1);
      final count = int.tryParse(countStr) ?? 0;

      if (emoji.isNotEmpty && count > 0) {
        result.add((emoji, count));
      }
    }

    return result;
  }

  /// Check if post has any reactions
  bool get hasReactions => reactions != null && reactions!.isNotEmpty;

  /// Get formatted date (relative time)
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'Just now';
      }
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
    }
  }

  /// The support media the carousel can render, as URLs: images and videos
  /// (the carousel's `TappableMedia` dispatches each URL on its extension),
  /// plus items whose type the source left open.
  List<String> get carouselImages => [
        for (final m in supportMedia)
          if (m.url.isNotEmpty && m.isRenderableMedia) m.url
      ];

  /// The whole support list WITH its types, files included: the card turns
  /// [PostMediaItem.isFile] entries into file tiles. [carouselImages] stays
  /// the media-only URL list for the aspect cache and the overlay.
  List<PostMediaItem> get carouselItems {
    final out = <PostMediaItem>[];
    final seen = <String>{};
    for (final m in supportMedia) {
      if (m.url.isEmpty || !seen.add(m.url)) continue;
      out.add(m.toCarouselItem());
    }
    return out;
  }

  /// Parse author address from authors array
  /// Expects format: "publicos.dev/0x1234..." in authors[0].url
  /// Returns the Ethereum address string for contact lookup
  String? get authorAddress {
    if (authors == null || authors!.isEmpty) return null;

    final author = authors!.first;
    if (author.url == null) return null;

    // Parse address from "publicos.dev/0x1234..." format
    final parts = author.url!.split('/');
    if (parts.length < 2) return null;

    final addressStr = parts.last; // Get the address part
    if (!addressStr.startsWith('0x')) return null;

    try {
      // Validate it's a proper Ethereum address
      EthereumAddress.fromHex(addressStr);
      return addressStr; // Return the hex string
    } catch (e) {
      Log.e('Post', 'Failed to parse author address from ${author.url}: $e');
      return null;
    }
  }

  /// The author line as written: a name on an RSS item, the `author` string
  /// of a PublicOS item (an address on a signed post). A label, never an
  /// identity.
  String? get authorName {
    if (authors == null || authors!.isEmpty) return null;
    return authors!.first.name;
  }

  /// Reactions to the `emoji:count,...` string the card reads. Accepts the
  /// interactions call's `{emoji: count}` map, the string itself, or a list
  /// of `{emoji, count}` rows.
  static String? parseReactions(dynamic reactions) {
    if (reactions == null) return null;
    if (reactions is String) return reactions.isEmpty ? null : reactions;
    if (reactions is Map) {
      final parts = <String>[];
      for (final e in reactions.entries) {
        final count = e.value is num ? (e.value as num).toInt() : 0;
        if (count > 0) parts.add('${e.key}:$count');
      }
      return parts.isEmpty ? null : parts.join(',');
    }
    if (reactions is List) {
      final parts = <String>[];
      for (final rc in reactions) {
        if (rc is Map) {
          final emoji = rc['emoji'] as String?;
          final count = rc['count'] is num ? (rc['count'] as num).toInt() : 0;
          if (emoji != null && count > 0) parts.add('$emoji:$count');
        }
      }
      return parts.isEmpty ? null : parts.join(',');
    }
    return null;
  }

  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&[^;]+;'), ' ')
        .trim();
  }

  /// Parse tags from JSON - handles both string arrays and tag objects
  static List<String>? _parseTags(dynamic tagsJson) {
    if (tagsJson == null) return null;
    if (tagsJson is! List) return null;

    final tags = <String>[];
    for (final tag in tagsJson) {
      if (tag is String) {
        tags.add(tag);
      } else if (tag is Map<String, dynamic>) {
        final name = tag['name'] as String?;
        if (name != null && name.isNotEmpty) {
          tags.add(name);
        }
      }
    }
    return tags.isEmpty ? null : tags;
  }

  Post copyWith({
    String? uid,
    int? accountId,
    int? channelId,
    String? title,
    String? contentText,
    String? summary,
    String? externalUrl,
    String? language,
    List<String>? tags,
    List<PostAuthor>? authors,
    List<PostMedia>? heroMedia,
    List<PostMedia>? supportMedia,
    PostMedia? audio,
    bool? mediaPost,
    bool? sensitive,
    String? commentPolicy,
    bool? requireVerifiedComments,
    String? reactionPolicy,
    bool? requireVerifiedReactions,
    String? signature,
    String? signedObject,
    String? signerAddress,
    DateTime? createdAt,
    DateTime? dateModified,
    DateTime? dateReceived,
    PostReceipt? receipt,
    PostPointer? quote,
    PostPointer? inReplyTo,
    List<String>? collaborators,
    List<PostAcknowledgment>? acknowledgments,
    int? commentsCount,
    String? commentsUrl,
    String? reactions,
    String? reactionsUrl,
    String? interactionsUrl,
    int? score,
    int? upvotes,
    int? downvotes,
    int? userVote,
    List<String>? viewerReactions,
    bool? canCommentAnswer,
    bool? canReactAnswer,
    String? postAuthorAddress,
    String? feedFoundAtAccountAddress,
    String? feedRecordKey,
    String? feedTitle,
    String? feedUrl,
    String? channelSlug,
    String? channelOwnerAddress,
    bool? isForumChannel,
    String? serverAddress,
    String? url,
  }) {
    return Post(
      uid: uid ?? this.uid,
      accountId: accountId ?? this.accountId,
      channelId: channelId ?? this.channelId,
      title: title ?? this.title,
      contentText: contentText ?? this.contentText,
      summary: summary ?? this.summary,
      externalUrl: externalUrl ?? this.externalUrl,
      language: language ?? this.language,
      tags: tags ?? this.tags,
      authors: authors ?? this.authors,
      heroMedia: heroMedia ?? this.heroMedia,
      supportMedia: supportMedia ?? this.supportMedia,
      audio: audio ?? this.audio,
      mediaPost: mediaPost ?? this.mediaPost,
      sensitive: sensitive ?? this.sensitive,
      commentPolicy: commentPolicy ?? this.commentPolicy,
      requireVerifiedComments:
          requireVerifiedComments ?? this.requireVerifiedComments,
      reactionPolicy: reactionPolicy ?? this.reactionPolicy,
      requireVerifiedReactions:
          requireVerifiedReactions ?? this.requireVerifiedReactions,
      signature: signature ?? this.signature,
      signedObject: signedObject ?? this.signedObject,
      signerAddress: signerAddress ?? this.signerAddress,
      createdAt: createdAt ?? this.createdAt,
      dateModified: dateModified ?? this.dateModified,
      dateReceived: dateReceived ?? this.dateReceived,
      receipt: receipt ?? this.receipt,
      quote: quote ?? this.quote,
      inReplyTo: inReplyTo ?? this.inReplyTo,
      collaborators: collaborators ?? this.collaborators,
      acknowledgments: acknowledgments ?? this.acknowledgments,
      commentsCount: commentsCount ?? this.commentsCount,
      commentsUrl: commentsUrl ?? this.commentsUrl,
      reactions: reactions ?? this.reactions,
      reactionsUrl: reactionsUrl ?? this.reactionsUrl,
      interactionsUrl: interactionsUrl ?? this.interactionsUrl,
      score: score ?? this.score,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      userVote: userVote ?? this.userVote,
      viewerReactions: viewerReactions ?? this.viewerReactions,
      canCommentAnswer: canCommentAnswer ?? this.canCommentAnswer,
      canReactAnswer: canReactAnswer ?? this.canReactAnswer,
      postAuthorAddress: postAuthorAddress ?? this.postAuthorAddress,
      feedFoundAtAccountAddress:
          feedFoundAtAccountAddress ?? this.feedFoundAtAccountAddress,
      feedRecordKey: feedRecordKey ?? this.feedRecordKey,
      feedTitle: feedTitle ?? this.feedTitle,
      feedUrl: feedUrl ?? this.feedUrl,
      channelSlug: channelSlug ?? this.channelSlug,
      channelOwnerAddress: channelOwnerAddress ?? this.channelOwnerAddress,
      isForumChannel: isForumChannel ?? this.isForumChannel,
      serverAddress: serverAddress ?? this.serverAddress,
      url: url ?? this.url,
    );
  }
}

/// One carousel entry of a post, type kept: see [Post.carouselItems].
class PostMediaItem {
  final String url;

  /// The source's MIME; '' when it gave none (URL-dispatched).
  final String mimeType;
  final String? title;
  final int? sizeInBytes;
  final int? durationInSeconds;

  const PostMediaItem({
    required this.url,
    required this.mimeType,
    this.title,
    this.sizeInBytes,
    this.durationInSeconds,
  });

  /// Not an image or a video by MIME: a document, an archive, audio, text...
  /// An empty or opaque MIME is media the card dispatches by URL.
  bool get isFile {
    final m = mimeType.toLowerCase();
    if (m.isEmpty || m == 'application/octet-stream') return false;
    return !m.startsWith('image/') && !m.startsWith('video/');
  }
}

class PostAuthor {
  final String name;
  final String? url;
  final String? avatar;

  PostAuthor({
    required this.name,
    this.url,
    this.avatar,
  });

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      name: json['name'] as String? ?? '',
      url: json['url'] as String?,
      avatar: json['avatar'] as String?,
    );
  }

  /// Alphabetical key order, the form a signed request body needs.
  Map<String, dynamic> toJson() {
    return {
      if (avatar != null) 'avatar': avatar,
      'name': name,
      if (url != null) 'url': url,
    };
  }
}
