import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';

/// Tests for the PublicOS URL grammar.
///
/// The parser's job is as much about what it REFUSES as what it accepts: a
/// returned null means "hand this to the browser", so a false positive hijacks
/// a link that should have opened publicos.dev, and a false negative sends a
/// PublicOS link out of the app. Both directions are asserted here.
void main() {
  const addr = '0xA4C6507b22e7005f4f739DaEF8Cdde682b901F6d';
  const base = 'https://publicos.dev';

  group('claims PublicOS links', () {
    test('bare profile', () {
      final link = parse('$base/publicosAddress/$addr')!;
      expect(link.kind, DeepLinkKind.publicosAddress);
      expect(link.identifier, addr);
      expect(link.type, isNull);
      expect(link.key, isNull);
    });

    test('chat by label — the durable inbox address', () {
      final link = parse('$base/publicosAddress/$addr/chat/support')!;
      expect(link.type, DeepLinkTarget.chat);
      expect(link.key, 'support');
    });

    test('the live support-bot card link', () {
      // An exact URL as stored on chain (card.mus9zq4t / card.a5345646).
      final link = parse('$base/publicosAddress/$addr/chat/support')!;
      expect(link.kind, DeepLinkKind.publicosAddress);
      expect(link.identifier, addr);
    });

    test('tab, app, settings, management, profile', () {
      expect(parse('$base/publicosAddress/$addr/tab/mytab')!.type,
          DeepLinkTarget.tab);
      expect(parse('$base/publicosAddress/$addr/app/tequio')!.key, 'tequio');
      expect(parse('$base/publicosAddress/$addr/settings')!.type,
          DeepLinkTarget.settings);
      expect(parse('$base/publicosAddress/$addr/management')!.type,
          DeepLinkTarget.management);
      expect(parse('$base/publicosAddress/$addr/profile')!.type,
          DeepLinkTarget.profile);
    });

    test('inboxId and conversationTopic', () {
      expect(parse('$base/inboxId/abc123')!.kind, DeepLinkKind.inboxId);
      expect(parse('$base/inboxId/abc123')!.identifier, 'abc123');
      expect(parse('$base/conversationTopic/xyz')!.kind,
          DeepLinkKind.conversationTopic);
    });

    test('a percent-encoded conversation topic is decoded', () {
      final link = parse('$base/conversationTopic/%2Fxmtp%2F0%2Ftopic')!;
      expect(link.identifier, '/xmtp/0/topic');
    });

    test('www. is a different host and is also claimed', () {
      // Every OS-level claim we ship lists both hosts; the parser must agree
      // or a www link would open the browser on one surface and the app on
      // another.
      expect(parse('https://www.publicos.dev/publicosAddress/$addr'), isNotNull);
    });

    test('?message= is carried through', () {
      final link = parse('$base/publicosAddress/$addr/chat/support?message=hi')!;
      expect(link.message, 'hi');
      expect(link.key, 'support', reason: 'the query must not leak into :key');
    });

    test('a legacy dotted tab key survives intact', () {
      // Real shape on chain: jmsl's feed tab is keyed `rss.thefeed` — the
      // per-channel pin toggles still emit the legacy `rss.<slug>` key, which
      // is now just a unique id (the kind lives in routerSubtype). A parser
      // that split on the dot, or mistook it for an extension, would break
      // every pinned channel link.
      final link = parse('$base/publicosAddress/$addr/tab/rss.thefeed')!;
      expect(link.type, DeepLinkTarget.tab);
      expect(link.key, 'rss.thefeed');
    });

    test('an UNKNOWN :type yields a null type, not a guess', () {
      // The vocabulary is closed on purpose. A client that invents a landing
      // for a type it does not ship is worse than one that shows the profile.
      final link = parse('$base/publicosAddress/$addr/wormhole/x')!;
      expect(link.type, isNull);
      expect(link.kind, DeepLinkKind.publicosAddress);
    });
  });

  group('refuses everything else — these must reach the browser', () {
    test('publicos.dev paths we deliberately do not claim', () {
      // The marketing site, the lobby and the learning centre must keep
      // opening in a browser. Android scopes its intent filter to the same
      // three prefixes for exactly this reason.
      expect(parse('$base/'), isNull);
      expect(parse('$base/lobby/'), isNull);
      expect(parse('$base/learning_center'), isNull);
      expect(parse('$base/.well-known/windows-app-web-link'), isNull);
    });

    test('other hosts, including look-alikes', () {
      expect(parse('https://example.com/publicosAddress/$addr'), isNull);
      expect(parse('https://publicos.dev.evil.com/publicosAddress/$addr'),
          isNull);
      expect(parse('https://notpublicos.dev/publicosAddress/$addr'), isNull);
    });

    test('a malformed address is refused at the parser, not at a chain read', () {
      expect(parse('$base/publicosAddress/notanaddress'), isNull);
      expect(parse('$base/publicosAddress/0x123'), isNull);
      expect(parse('$base/publicosAddress/${addr}extra'), isNull);
      expect(parse('$base/publicosAddress/0xZZC6507b22e7005f4f739DaEF8Cdde682b901F6d'),
          isNull);
    });

    test('the custom scheme is NOT a sharing surface', () {
      // publicos:// is the QR-fired action family (add_session / new_account),
      // a security flow with its own consent UI. Parsing it here would route
      // a device-authorization payload as if it were a link.
      expect(parse('publicos://profile/$addr'), isNull);
      expect(parse('publicos://add_session/payload'), isNull);
    });

    test('garbage and empties', () {
      expect(parse(''), isNull);
      expect(parse('   '), isNull);
      expect(parse('not a url at all'), isNull);
      expect(parse('$base/publicosAddress'), isNull);
      expect(parse('$base/publicosAddress/'), isNull);
    });
  });

  group('isAddressedToPublicOs — the silence/complain split', () {
    // This is what decides whether a failed link SHOWS A SNACKBAR or is
    // ignored. A false positive nags the user about ordinary web links; a
    // false negative puts a broken link back to failing silently, which is
    // the bug it was added for.
    test('true for a claimed class, even when malformed', () {
      expect(isAddressedToPublicOs('$base/publicosAddress/notanaddress'), isTrue);
      expect(isAddressedToPublicOs('$base/publicosAddress/0x123'), isTrue);
      expect(isAddressedToPublicOs('$base/inboxId/'), isTrue);
      expect(isAddressedToPublicOs('$base/publicosAddress/$addr'), isTrue);
    });

    test('false for publicos.dev paths that were never ours', () {
      expect(isAddressedToPublicOs('$base/lobby/'), isFalse);
      expect(isAddressedToPublicOs('$base/learning_center'), isFalse);
      expect(isAddressedToPublicOs('$base/'), isFalse);
    });

    test('false for other hosts entirely', () {
      expect(isAddressedToPublicOs('https://example.com/publicosAddress/$addr'),
          isFalse);
      expect(isAddressedToPublicOs('publicos://profile/$addr'), isFalse);
      expect(isAddressedToPublicOs('garbage'), isFalse);
    });

    test('a malformed link is addressed-to-us but does NOT parse', () {
      // The exact pair the reporting logic keys off.
      const bad = 'https://publicos.dev/publicosAddress/notanaddress';
      expect(isAddressedToPublicOs(bad), isTrue);
      expect(parse(bad), isNull);
    });
  });

  group('isPublicOsLink mirrors parse', () {
    test('agrees on both directions', () {
      expect(isPublicOsLink('$base/publicosAddress/$addr'), isTrue);
      expect(isPublicOsLink('$base/lobby/'), isFalse);
      expect(isPublicOsLink('https://example.com'), isFalse);
    });
  });

  group('tolerates real-world shapes', () {
    test('surrounding whitespace', () {
      expect(parse('  $base/publicosAddress/$addr  '), isNotNull);
    });

    test('a trailing slash does not become an empty :type', () {
      final link = parse('$base/publicosAddress/$addr/')!;
      expect(link.type, isNull);
    });

    test('http is accepted as well as https', () {
      // We never emit http, but a link can be typed or pasted that way and
      // the OS will still hand it to us.
      expect(parse('http://publicos.dev/publicosAddress/$addr'), isNotNull);
    });
  });
}
