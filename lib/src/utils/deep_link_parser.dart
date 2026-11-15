/// Parses a PublicOS link into the thing it points at.
///
/// PURE: a `String` in, a value out. No Flutter, no navigation, no chain reads,
/// no `BuildContext`. It lives in Core because the *grammar* is protocol, shared
/// by every client — but **dispatch is per-app** and deliberately stays out of
/// here: publicos_client pushes a GoRouter route, publicos_desktop swaps a pane
/// through its `AppNav` shim, and the website does neither.
///
/// ## Why this exists at all
///
/// It looks like it should have been lifted out of publicos_client. It could
/// not be: the client never parses these URLs. `_parseDeepLinkToRoute`'s https
/// branch is a one-line pass-through (`return uri.path`) and **GoRouter's
/// matcher** does the real work, with the `:type`/`:key` resolution living in
/// `browser.dart`'s `_resolveLandingTab`, welded to widget `State`. So there was
/// nothing to extract, and this is new code rather than a refactor.
///
/// ## The grammar (identifier-class-first)
///
/// ```
/// https://publicos.dev/publicosAddress/0xAddr
/// https://publicos.dev/publicosAddress/0xAddr/<type>
/// https://publicos.dev/publicosAddress/0xAddr/<type>/<key>
/// https://publicos.dev/inboxId/<inboxId>
/// https://publicos.dev/conversationTopic/<topic>
/// ```
///
/// The first path segment is the identifier CLASS, not a purpose. `<type>` is a
/// closed vocabulary; `<key>` is a record key (`tab`), an inbox label (`chat`)
/// or an app name (`app`). The two tiers exist so an inbox label can never
/// collide with a type name.
library;

/// Which identifier class a link names.
enum DeepLinkKind {
  /// `/publicosAddress/:address` and its `:type`/`:key` children.
  publicosAddress,

  /// `/inboxId/:inboxId` — a direct XMTP inbox pointer. Dies if the inbox is
  /// abandoned; the durable alias is `publicosAddress/:a/chat/:label`.
  inboxId,

  /// `/conversationTopic/:topic` — a group chat by XMTP topic.
  conversationTopic,
}

/// The closed `:type` vocabulary of a `/publicosAddress/…` link.
///
/// Closed on purpose: an unknown type is a link we must NOT guess at, so
/// [DeepLink.type] is null for one and the caller falls back to the profile.
enum DeepLinkTarget { profile, settings, management, tab, chat, app }

/// A parsed PublicOS link.
class DeepLink {
  final DeepLinkKind kind;

  /// The identifier: the account address, the inbox ID, or the (already
  /// percent-decoded) conversation topic.
  final String identifier;

  /// The `:type` segment, for [DeepLinkKind.publicosAddress] only.
  /// Null when the link is a bare profile, or names a type we do not know.
  final DeepLinkTarget? type;

  /// The `:key` segment: record key (`tab`), inbox label (`chat`), app name
  /// (`app`). Null when the link carries no key.
  final String? key;

  /// `?message=` — pre-fills the composer on a `chat` link, once, never sent.
  /// Carried here so the desktop and web paths get it for free; today only the
  /// client consumes it.
  final String? message;

  const DeepLink({
    required this.kind,
    required this.identifier,
    this.type,
    this.key,
    this.message,
  });

  @override
  String toString() =>
      'DeepLink(${kind.name}, $identifier, type: ${type?.name}, key: $key)';
}

/// Hosts we treat as ours. `www.` is a genuinely different host to every
/// OS-level claim (Android's intent filter, the iOS AASA, the Windows
/// appUriHandler all list both), so it is matched here too.
const Set<String> _publicosHosts = {'publicos.dev', 'www.publicos.dev'};

/// The three claimed path prefixes. Anything else on publicos.dev is
/// deliberately NOT ours — the marketing site, the lobby, `/manual`
/// must keep opening in a browser. The Android manifest scopes its intent
/// filter to exactly these three for the same reason.
const Set<String> _claimedClasses = {
  'publicosAddress',
  'inboxId',
  'conversationTopic',
};

/// True when [url] is a PublicOS link this parser would claim.
///
/// The cheap pre-check for a link interceptor: a tap handler calls this and
/// launches the browser when it is false. Kept separate from [parse] so a
/// caller can ask the question without building a result.
bool isPublicOsLink(String url) => parse(url) != null;

/// True when [url] was *addressed to us* — our host and one of the three
/// claimed identifier classes — **even if it does not parse**.
///
/// The difference from [isPublicOsLink] is the whole point: `parse` returns
/// null both for a link that was never ours (`publicos.dev/lobby/`, someone
/// else's domain) and for one that was clearly meant for us but is malformed
/// (`/publicosAddress/notanaddress`). A caller that wants to TELL THE USER
/// something went wrong must not conflate those — the first is a normal
/// browser link and deserves silence, the second is a broken link and
/// deserves a message.
bool isAddressedToPublicOs(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return false;
  if (uri.scheme != 'https' && uri.scheme != 'http') return false;
  if (!_publicosHosts.contains(uri.host.toLowerCase())) return false;
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  return segments.isNotEmpty && _claimedClasses.contains(segments[0]);
}

/// Parses [url], or returns null when it is not a link we claim.
///
/// Null means **hand it to the browser** — not "error". A `publicos.dev` URL
/// outside the three claimed classes returns null on purpose.
DeepLink? parse(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return null;

  // `publicos://` is the QR-fired ACTION family (add_session / new_account),
  // never a sharing surface — those payloads are a security flow with their own
  // consent UI, so they are deliberately not parsed here.
  if (!uri.hasScheme || (uri.scheme != 'https' && uri.scheme != 'http')) {
    return null;
  }
  if (!_publicosHosts.contains(uri.host.toLowerCase())) return null;

  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.length < 2) return null;

  final className = segments[0];
  if (!_claimedClasses.contains(className)) return null;

  final identifier = Uri.decodeComponent(segments[1]);
  if (identifier.isEmpty) return null;

  final message = uri.queryParameters['message'];

  switch (className) {
    case 'inboxId':
      return DeepLink(
        kind: DeepLinkKind.inboxId,
        identifier: identifier,
        message: message,
      );
    case 'conversationTopic':
      return DeepLink(
        kind: DeepLinkKind.conversationTopic,
        identifier: identifier,
        message: message,
      );
    case 'publicosAddress':
      // Guard the address shape here so no caller has to: a malformed address
      // would otherwise reach a chain read and fail far from the cause.
      if (!_looksLikeAddress(identifier)) return null;
      return DeepLink(
        kind: DeepLinkKind.publicosAddress,
        identifier: identifier,
        type: segments.length > 2 ? _targetFrom(segments[2]) : null,
        key: segments.length > 3 ? Uri.decodeComponent(segments[3]) : null,
        message: message,
      );
  }
  return null;
}

/// Null for an unknown type, which the caller treats as "land on the profile".
/// A closed vocabulary is the point: never guess at a type we do not ship.
DeepLinkTarget? _targetFrom(String segment) {
  for (final t in DeepLinkTarget.values) {
    if (t.name == segment) return t;
  }
  return null;
}

bool _looksLikeAddress(String value) {
  if (value.length != 42 || !value.startsWith('0x')) return false;
  for (var i = 2; i < value.length; i++) {
    final c = value.codeUnitAt(i);
    final isDigit = c >= 0x30 && c <= 0x39;
    final isLower = c >= 0x61 && c <= 0x66;
    final isUpper = c >= 0x41 && c <= 0x46;
    if (!isDigit && !isLower && !isUpper) return false;
  }
  return true;
}
