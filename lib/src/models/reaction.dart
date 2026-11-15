class FeedReaction {
  final String uid;
  final String emoji;
  final int count;

  FeedReaction({
    required this.uid,
    required this.emoji,
    required this.count,
  });

  factory FeedReaction.fromJson(Map<String, dynamic> json) {
    return FeedReaction(
      uid: json['uid'] as String? ?? '',
      emoji: json['emoji'] as String,
      count: json['count'] as int,
    );
  }

  FeedReaction copyWith({int? count}) {
    return FeedReaction(
      uid: uid,
      emoji: emoji,
      count: count ?? this.count,
    );
  }
}

class UserReaction {
  final String uid;
  final String accountAddress;
  final String emoji;
  final String targetUrl;
  final String signedObject;
  final String contentSignature;
  final String signerAddress;
  final DateTime createdAt;

  UserReaction({
    required this.uid,
    required this.accountAddress,
    required this.emoji,
    required this.targetUrl,
    required this.signedObject,
    required this.contentSignature,
    required this.signerAddress,
    required this.createdAt,
  });

  factory UserReaction.fromJson(Map<String, dynamic> json) {
    return UserReaction(
      uid: json['uid'] as String? ?? '',
      accountAddress: json['account_address'] as String,
      emoji: json['emoji'] as String,
      targetUrl: json['target_url'] as String,
      // Empty on unsigned reactions (children are optional-sign since the
      // content-hash-binding change) — tolerate absent keys too.
      signedObject: json['signed_object'] as String? ?? '',
      contentSignature: json['content_signature'] as String? ?? '',
      signerAddress: json['signer_address'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ReactionsData {
  final List<FeedReaction> reactions;
  final List<UserReaction> userReactions;

  /// Emojis the signed reader reacted with on this post — server-curated
  /// from the envelope-derived signer.
  /// Empty for anonymous callers or when the signer hasn't
  /// reacted. Use this for badge state instead of filtering [userReactions]
  /// client-side.
  final List<String> currentUserReactions;

  final String postUid;

  ReactionsData({
    required this.reactions,
    required this.userReactions,
    required this.currentUserReactions,
    required this.postUid,
  });

  factory ReactionsData.fromJson(Map<String, dynamic> json) {
    return ReactionsData(
      reactions: (json['reactions'] as List<dynamic>)
          .map((r) => FeedReaction.fromJson(r as Map<String, dynamic>))
          .toList(),
      userReactions: (json['user_reactions'] as List<dynamic>)
          .map((r) => UserReaction.fromJson(r as Map<String, dynamic>))
          .toList(),
      currentUserReactions: (json['current_user_reactions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      postUid: json['post_uid'] as String? ?? '',
    );
  }

  /// True if the signed reader has reacted with [emoji]. Prefer this over
  /// scanning [userReactions] — it consults the server-curated
  /// [currentUserReactions] list which is O(small) per post.
  bool currentUserHasReaction(String emoji) {
    return currentUserReactions.contains(emoji);
  }

  /// Legacy lookup against the full per-user list. Kept for third-party
  /// verifier code that needs to check arbitrary addresses.
  bool hasUserReacted(String userAddress, String emoji) {
    return userReactions.any((ur) =>
      ur.accountAddress.toLowerCase() == userAddress.toLowerCase() &&
      ur.emoji == emoji
    );
  }

  FeedReaction? getReaction(String emoji) {
    try {
      return reactions.firstWhere((r) => r.emoji == emoji);
    } catch (e) {
      return null;
    }
  }
}
