/// Sort options for comments
enum CommentSort {
  best,
  top,
  newest,
  oldest;

  /// The query parameter value sent to the server
  String get serverParam {
    switch (this) {
      case CommentSort.best:
        return 'best';
      case CommentSort.top:
        return 'top';
      case CommentSort.newest:
        return 'new';
      case CommentSort.oldest:
        return 'old';
    }
  }

  /// Display label
  String get label {
    switch (this) {
      case CommentSort.best:
        return 'Best';
      case CommentSort.top:
        return 'Top';
      case CommentSort.newest:
        return 'New';
      case CommentSort.oldest:
        return 'Old';
    }
  }
}

/// The comments call's answer (spec § Comments): the thread, and, on a SIGNED
/// request, whether this reader may comment (votes follow it) and react on
/// the post. [canComment] / [canReact] are null when the request went
/// unsigned: the server answers `false` to a reader it does not know, and a
/// reader must treat that as unknown, never as "no".
class CommentsAnswer {
  final List<Comment> comments;
  final bool? canComment;
  final bool? canReact;

  const CommentsAnswer({
    required this.comments,
    this.canComment,
    this.canReact,
  });
}

class CommentReaction {
  final String uid;
  final String emoji;
  final int count;

  CommentReaction({
    required this.uid,
    required this.emoji,
    required this.count,
  });

  factory CommentReaction.fromJson(Map<String, dynamic> json) {
    return CommentReaction(
      uid: json['uid'] as String? ?? '',
      emoji: json['emoji'] as String,
      count: json['count'] as int,
    );
  }

  CommentReaction copyWith({int? count}) {
    return CommentReaction(
      uid: uid,
      emoji: emoji,
      count: count ?? this.count,
    );
  }
}

/// The post's author's own reaction on a comment: the first emoji they
/// added, and who they are (`post_author_reaction` on every comment the
/// server answers, absent when the author has not reacted). Lets a client show
/// "the author reacted" beside the comment's time.
class CommentAuthorReaction {
  final String address;
  final String emoji;

  const CommentAuthorReaction({required this.address, required this.emoji});

  static CommentAuthorReaction? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final address = json['address'] as String? ?? '';
    final emoji = json['emoji'] as String? ?? '';
    if (address.isEmpty || emoji.isEmpty) return null;
    return CommentAuthorReaction(address: address, emoji: emoji);
  }
}

class Comment {
  final String uid;
  final String accountAddress;
  final String? username;
  final String content;
  final String? replyToUid;
  final String targetUrl;
  final String? replyToUrl;
  final String signedObject;
  final String contentSignature;
  final String signerAddress;
  final DateTime createdAt;
  final List<Comment> replies;

  // Vote fields
  final int score;
  final int upvotes;
  final int downvotes;
  final int? userVote; // +1, -1, or null (no vote)

  // Reply metadata
  final int replyCount;
  final bool hasMore;

  // Edit/delete fields
  /// Last user-visible edit time (JSON Feed `date_modified`). Null when the
  /// comment has never been edited. Renamed from `editedAt` in Core 0.8.0 to
  /// align wire + DB + Dart on a single name. See post.dart `dateModified`.
  final DateTime? dateModified;
  final bool isDeleted;

  // Reaction fields
  final List<CommentReaction> reactions;
  final List<String> userReactionEmojis;

  /// The post's author's reaction on this comment, null when they have none.
  final CommentAuthorReaction? postAuthorReaction;

  Comment({
    required this.uid,
    required this.accountAddress,
    this.username,
    required this.content,
    this.replyToUid,
    required this.targetUrl,
    this.replyToUrl,
    required this.signedObject,
    required this.contentSignature,
    required this.signerAddress,
    required this.createdAt,
    this.replies = const [],
    this.score = 0,
    this.upvotes = 0,
    this.downvotes = 0,
    this.userVote,
    this.replyCount = 0,
    this.hasMore = false,
    this.dateModified,
    this.isDeleted = false,
    this.reactions = const [],
    this.userReactionEmojis = const [],
    this.postAuthorReaction,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      uid: json['uid'] as String? ?? '',
      accountAddress: json['account_address'] as String,
      username: json['username'] as String?,
      content: json['content'] as String,
      replyToUid: json['reply_to_uid'] as String?,
      targetUrl: json['target_url'] as String,
      replyToUrl: json['reply_to_url'] as String?,
      // Empty on unsigned comments (children are optional-sign since the
      // content-hash-binding change) — tolerate absent keys too.
      signedObject: json['signed_object'] as String? ?? '',
      contentSignature: json['content_signature'] as String? ?? '',
      signerAddress: json['signer_address'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      replies: (json['replies'] as List<dynamic>?)
          ?.map((r) => Comment.fromJson(r as Map<String, dynamic>))
          .toList() ?? const [],
      score: json['score'] as int? ?? 0,
      upvotes: json['upvotes'] as int? ?? 0,
      downvotes: json['downvotes'] as int? ?? 0,
      userVote: json['user_vote'] as int?,
      replyCount: json['reply_count'] as int? ?? 0,
      hasMore: json['has_more'] as bool? ?? false,
      dateModified: json['date_modified'] != null
          ? DateTime.parse(json['date_modified'] as String)
          : null,
      isDeleted: json['is_deleted'] as bool? ?? false,
      reactions: (json['reactions'] as List<dynamic>?)
          ?.map((r) => CommentReaction.fromJson(r as Map<String, dynamic>))
          .toList() ?? const [],
      userReactionEmojis: (json['user_reaction_emojis'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? const [],
      postAuthorReaction:
          CommentAuthorReaction.fromJson(json['post_author_reaction']),
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    String base;
    if (diff.inMinutes < 1) {
      base = 'Just now';
    } else if (diff.inHours < 1) {
      base = '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      base = '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      base = '${diff.inDays}d ago';
    } else {
      base = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
    }

    if (dateModified != null) {
      base += ' (edited)';
    }

    return base;
  }

  int get totalReplies => replies.length + replies.fold(0, (sum, r) => sum + r.totalReplies);

  Comment copyWith({
    String? uid,
    String? accountAddress,
    String? username,
    String? content,
    String? replyToUid,
    String? targetUrl,
    String? replyToUrl,
    String? signedObject,
    String? contentSignature,
    String? signerAddress,
    DateTime? createdAt,
    List<Comment>? replies,
    int? score,
    int? upvotes,
    int? downvotes,
    int? userVote,
    int? replyCount,
    bool? hasMore,
    DateTime? dateModified,
    bool? isDeleted,
    List<CommentReaction>? reactions,
    List<String>? userReactionEmojis,
    CommentAuthorReaction? postAuthorReaction,
  }) {
    return Comment(
      uid: uid ?? this.uid,
      accountAddress: accountAddress ?? this.accountAddress,
      username: username ?? this.username,
      content: content ?? this.content,
      replyToUid: replyToUid ?? this.replyToUid,
      targetUrl: targetUrl ?? this.targetUrl,
      replyToUrl: replyToUrl ?? this.replyToUrl,
      signedObject: signedObject ?? this.signedObject,
      contentSignature: contentSignature ?? this.contentSignature,
      signerAddress: signerAddress ?? this.signerAddress,
      createdAt: createdAt ?? this.createdAt,
      replies: replies ?? this.replies,
      score: score ?? this.score,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      userVote: userVote ?? this.userVote,
      replyCount: replyCount ?? this.replyCount,
      hasMore: hasMore ?? this.hasMore,
      dateModified: dateModified ?? this.dateModified,
      isDeleted: isDeleted ?? this.isDeleted,
      reactions: reactions ?? this.reactions,
      userReactionEmojis: userReactionEmojis ?? this.userReactionEmojis,
      postAuthorReaction: postAuthorReaction ?? this.postAuthorReaction,
    );
  }
}
