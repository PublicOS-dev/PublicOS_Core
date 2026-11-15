/// The social links a profile can show — a FIXED list: anything else is not
/// displayed.
///
/// A profile record is a social link only if its key is on this list; any
/// other key (a stray write, a DNS-style `TXT` record, anything the protocol
/// adds later) is classified `ProfileSubtype.unknown` and no surface renders
/// it. The apps' social picker, the social strip, the display names and the
/// web lobby (a JS copy in `Publicos.dev/lobby/lobby.js`) all read this one
/// list, so what a user can set and what a profile shows cannot drift apart.
///
/// Adding a network = one entry here (+ its glyph in the apps' icon table and
/// the lobby's copy). Removing one hides every existing record of it.
class SocialLink {
  /// The record key (reverse-DNS, ENS-style where one exists).
  final String key;

  /// What the picker and the rich strip call it.
  final String name;

  /// Placeholder for the editor's input.
  final String hint;

  /// The tap target built from what the user typed, or null when there is
  /// none (the tile then shows but does not open anything).
  final String? Function(String input) buildLink;

  const SocialLink(this.key, this.name, this.hint, this.buildLink);
}

String _handle(String s) => s.trim().replaceAll(RegExp(r'^[@u/]+'), '');

String? _prefixed(String prefix, String input) {
  final h = _handle(input);
  return h.isEmpty ? null : '$prefix$h';
}

String? _website(String input) {
  final v = input.trim();
  if (v.isEmpty) return null;
  return RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(v) ? v : 'https://$v';
}

String? _email(String input) {
  final v = input.trim();
  return v.contains('@') ? 'mailto:$v' : null;
}

abstract final class SocialLinks {
  static final List<SocialLink> all = [
    SocialLink('com.twitter', 'Twitter', '@handle',
        (v) => _prefixed('https://x.com/', v)),
    SocialLink('com.instagram', 'Instagram', '@username',
        (v) => _prefixed('https://instagram.com/', v)),
    SocialLink('com.github', 'GitHub', 'username',
        (v) => _prefixed('https://github.com/', v)),
    SocialLink('app.bsky', 'Bluesky', '@handle.bsky.social',
        (v) => _prefixed('https://bsky.app/profile/', v)),
    SocialLink('com.linkedin', 'LinkedIn', 'username or profile URL',
        (v) => _prefixed('https://linkedin.com/in/', v)),
    // Discord: commented out. A clickable link needs the
    // numeric user id (discord.com/users/<id>), which people do not know; a
    // username alone opens nothing. Uncomment to bring it back (records of it
    // are hidden while it is off).
    // SocialLink('com.discord', 'Discord', 'username', (_) => null),
    SocialLink('org.telegram', 'Telegram', '@username',
        (v) => _prefixed('https://t.me/', v)),
    SocialLink('com.reddit', 'Reddit', 'u/username',
        (v) => _prefixed('https://reddit.com/user/', v)),
    SocialLink('com.youtube', 'YouTube', '@channel', (v) {
      final h = _handle(v);
      return h.isEmpty ? null : 'https://youtube.com/@$h';
    }),
    SocialLink('xyz.farcaster', 'Farcaster', '@username',
        (v) => _prefixed('https://farcaster.xyz/', v)),
    SocialLink('url', 'Website', 'example.com', _website),
    SocialLink('email', 'Email', 'name@example.com', _email),
  ];

  static final Map<String, SocialLink> _byKey = {
    for (final l in all) l.key: l,
  };

  /// The entry for [key] (case-insensitive), or null when it is not a social
  /// link this build shows.
  static SocialLink? of(String key) => _byKey[key.toLowerCase()];

  static bool isKnown(String key) => of(key) != null;

  /// key → display name, for surfaces that only need the label.
  static final Map<String, String> names = {
    for (final l in all) l.key: l.name,
  };
}
