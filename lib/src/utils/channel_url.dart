/// `<scheme>://<authority>/api/<owner>/channels/<slug>` for any URL under a
/// PublicOS channel — the feed (`/json`, `/rss`, `/atom`), a post, its
/// comments, replies, reactions, or the channel object route itself — or
/// null for any other shape (external RSS, a profile, a media URL).
///
/// Pure and dependency-free on purpose: the drift migration, the sign-in
/// extension and `RssParser` all key on it, and the client's
/// `channelStubFromFeedUrl` derives its stub from the same parse
/// (one row per channel, whatever URL
/// under it the caller happens to hold).
///
/// The owner segment is kept **as-is** — casing is the server's concern
/// (feed handlers resolve the address verbatim), and normalising it here
/// would make two rows for one channel disagree with the wire.
String? channelBaseOf(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme || uri.authority.isEmpty) return null;
  final segs = uri.pathSegments;
  if (segs.length < 4 || segs[0] != 'api' || segs[2] != 'channels') {
    return null;
  }
  final owner = segs[1];
  final slug = segs[3];
  if (owner.isEmpty || slug.isEmpty) return null;
  return '${uri.scheme}://${uri.authority}/api/$owner/channels/$slug';
}

/// The coordinates inside a post permalink,
/// `<server>/api/<owner>/channels/<slug>/posts/<uid>` — the item `url` the
/// SSP emits for every post (`buildJSONItem`). Everything is kept verbatim:
/// the server resolves the owner case-sensitively, so a re-cased owner reads
/// a different (or no) account.
class PostRef {
  final String server;
  final String owner;
  final String slug;
  final String uid;
  const PostRef(this.server, this.owner, this.slug, this.uid);
}

/// Parses a post permalink into a [PostRef], or null for any other shape
/// (a feed URL, a comment URL, an external RSS article link).
PostRef? postRefOf(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme || uri.authority.isEmpty) return null;
  final segs = uri.pathSegments;
  if (segs.length != 6 ||
      segs[0] != 'api' ||
      segs[2] != 'channels' ||
      segs[4] != 'posts') {
    return null;
  }
  if (segs[1].isEmpty || segs[3].isEmpty || segs[5].isEmpty) return null;
  return PostRef(
      '${uri.scheme}://${uri.authority}', segs[1], segs[3], segs[5]);
}

/// `<scheme>://<authority>` of [url], or null when it has neither.
String? serverOf(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme || uri.authority.isEmpty) return null;
  return '${uri.scheme}://${uri.authority}';
}
