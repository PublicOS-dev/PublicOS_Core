import 'dart:convert';

/// Pointer stored in a `cardKind: 'app'` profile record's `value`.
///
/// An **app card** ("web_card") is a pair of endpoints authored by a registered
/// third-party app, not by the profile owner: an [image] that is always fetched
/// and is the card at rest, and an optional [live] page that the card *can* be
/// promoted to. A card with no [live] is a finished card, not a broken one --
/// that optionality is the whole protocol, and it is why every reader that
/// cannot run a webview (the docs site, a bot, a future web build) renders the
/// canonical state rather than a fallback.
///
/// Same shape as [NftAvatarRef]: the record's `value` is an encoded pointer and
/// the resolver branches on `metadata['cardKind']` alone -- the `card.` key
/// prefix is never checked, so this is a metadata value, not a new record type.
///
/// Wire format:
/// ```json
/// {
///   "v": 1,
///   "app": "petdemo",
///   "image": "https://cards.publicos.dev/petdemo/pet1/still.gif",
///   "live":  "https://cards.publicos.dev/petdemo/pet1/"
/// }
/// ```
///
/// Trust is NOT carried by this object. It names an App Registry slug; the
/// resolver reads that app's `card_origin` pointer from chain and checks both
/// URLs sit under it. See [isUnder], which is the entire security surface.
class AppCardRef {
  /// Wire format version this build writes and fully understands.
  static const int currentVersion = 1;

  /// Declared format version. May be greater than [currentVersion] -- see
  /// [isSupportedVersion].
  final int version;

  /// App Registry slug. Globally unique on chain (`mapping(string => App)` plus
  /// `require(!apps[slug].exists)`), which is why a card needs the slug alone
  /// and never an owner address.
  final String app;

  /// The card at rest. Always fetched; it is what decides the card's size.
  final Uri image;

  /// The interactive half. Null is a complete card, not a failure.
  final Uri? live;

  /// Keys this build did not read, kept verbatim.
  ///
  /// An older client that re-saves a card it does not fully understand must not
  /// drop what a newer one wrote. Round-tripping through [toMap] preserves them.
  final Map<String, dynamic> extra;

  const AppCardRef({
    required this.version,
    required this.app,
    required this.image,
    this.live,
    this.extra = const <String, dynamic>{},
  });

  /// Whether this build understands the declared version.
  ///
  /// A newer card is deliberately NOT an error: it still renders its image, it
  /// is simply never promotable, because we cannot know what a future `live`
  /// half expects of its host.
  bool get isSupportedVersion => version == currentVersion;

  /// Whether a tap may promote this card to its live half. Structural, not a
  /// runtime probe -- but still gated on the resolver's verdict downstream.
  bool get isPromotable => live != null && isSupportedVersion;

  /// Slug rules, mirroring `AppRegistryMemory._isValidSlug` exactly: 3-32
  /// chars, first char `[a-z0-9]`, body `[a-z0-9_-]`. Enforced on chain, so a
  /// slug that fails here could never have been registered.
  static bool isValidSlug(String s) {
    if (s.length < 3 || s.length > 32) return false;
    final first = s.codeUnitAt(0);
    final firstOk = (first >= 0x61 && first <= 0x7a) || // a-z
        (first >= 0x30 && first <= 0x39); //             0-9
    if (!firstOk) return false;
    for (final c in s.codeUnits) {
      final ok = (c >= 0x61 && c <= 0x7a) ||
          (c >= 0x30 && c <= 0x39) ||
          c == 0x2d || // -
          c == 0x5f; //  _
      if (!ok) return false;
    }
    return true;
  }

  /// Is [url] inside the app's declared `card_origin` prefix?
  ///
  /// **This is the entire security surface of the design, so it is deliberately
  /// boring.** A naive `url.startsWith(origin)` accepts
  /// `https://cards.example.app.evil.com/pet/1` against a declared
  /// `https://cards.example.app/pet/` -- the comparison must happen after
  /// parsing both sides, component by component.
  ///
  /// No wildcards. No regex. No query or fragment in the declared prefix. An
  /// origin that is not path-shaped is rejected rather than coerced, because
  /// coercing `https://example.app` into `https://example.app/` quietly widens
  /// it to the whole site.
  static bool isUnder(Uri url, Uri origin) {
    if (url.scheme != 'https' || origin.scheme != 'https') return false;
    if (url.host.isEmpty || origin.host.isEmpty) return false;
    if (url.host.toLowerCase() != origin.host.toLowerCase()) return false;
    if (url.port != origin.port) return false;
    if (url.userInfo.isNotEmpty || origin.userInfo.isNotEmpty) return false;
    if (origin.hasQuery || origin.hasFragment) return false;
    if (!origin.path.endsWith('/')) return false;
    // normalizePath collapses `..`/`.` so a traversal cannot climb out.
    return url.normalizePath().path.startsWith(origin.path);
  }

  /// Parse a record `value`. Null for anything that is not a well-formed app
  /// card -- malformed input is never half-accepted.
  static AppCardRef? tryParse(String? raw) {
    if (raw == null || !raw.trimLeft().startsWith('{')) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final j = decoded.cast<String, dynamic>();

      final v = j['v'];
      if (v is! num) return null; // version is required; absent means malformed
      final app = j['app'];
      if (app is! String || !isValidSlug(app)) return null;

      final image = _absHttps(j['image']);
      if (image == null) return null;

      final live = _absHttps(j['live']); // null when absent OR unusable

      final extra = <String, dynamic>{};
      for (final e in j.entries) {
        if (e.key == 'v' ||
            e.key == 'app' ||
            e.key == 'image' ||
            e.key == 'live') {
          continue;
        }
        extra[e.key] = e.value;
      }

      return AppCardRef(
        version: v.toInt(),
        app: app,
        image: image,
        live: live,
        extra: extra,
      );
    } catch (_) {
      return null;
    }
  }

  static Uri? _absHttps(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    final u = Uri.tryParse(raw);
    if (u == null || !u.isAbsolute || u.scheme != 'https') return null;
    if (u.host.isEmpty) return null;
    return u;
  }

  Map<String, dynamic> toMap() => {
        'v': version,
        'app': app,
        'image': image.toString(),
        if (live != null) 'live': live.toString(),
        ...extra,
      };

  /// JSON for the record's `value`.
  String encode() => jsonEncode(toMap());

  /// True when two refs name the same card instance.
  bool samePointer(AppCardRef o) =>
      app == o.app && image == o.image && live == o.live;

  @override
  String toString() => 'AppCardRef($app, image: $image, live: $live)';
}

/// What the resolver concluded about one app card, on the viewer's device.
///
/// Three outcomes from a single chain read (see `PublicOSContacts`):
/// - [ok]        render the image, and it may be promoted to [AppCardRef.live]
/// - [imageOnly] render the image, never promotable
/// - [broken]    do not render app content at all
///
/// [imageOnly] is the graceful-revocation state: an app that drops its
/// `card_origin` pointer, or leaves the registry, makes every card pointing
/// into it stop being tappable, on every device, at the next resolve. It does
/// not blank them, does not error, and does not notify. The app loses the
/// interactive half and keeps the picture the owner chose to display.
enum AppCardVerdict { ok, imageOnly, broken }

/// How many app cards may run their live half at once.
///
/// **This is the protocol/policy split, and it is the point.** The protocol
/// (see [AppCardRef]) says every card has two states: an image, and optionally
/// a live page. It says nothing about how many may be live at once, because
/// that is not a property of the card -- it is a property of the device showing
/// it. So both clients run ONE code path (image first, then live) and differ
/// only in which value of this enum they resolve at runtime.
///
/// The reason to restrict it at all is a memory ceiling on mobile that **has
/// never been measured**: no build has ever rendered two webviews at once. Every
/// expectation about it is an expectation, not an observation. Keeping the
/// count as a runtime policy rather than a design assumption means the
/// measurement, whenever it happens, moves a default and nothing else.
enum LivePolicy {
  /// Never promote. Edit mode, and any renderer without a webview.
  ///
  /// Not a degraded mode: the profile is completely readable, because the image
  /// is the card and the live half was always the enhancement.
  none,

  /// At most one card live at a time. Default on every platform today.
  ///
  /// Promoting demotes the incumbent, so the cost is bounded to "one frame,
  /// ever" no matter how many cards a profile carries.
  onTap,

  /// Every promotable card runs at once. Desktop, opt-in.
  ///
  /// Same code path -- the promotion is auto-fired instead of tap-fired.
  all,
}

/// The metadata keys the resolver stamps onto an app-card record, mirroring the
/// NFT card's `nftImage` / `nftOwned` / `nftCheckedAt` convention so the widget
/// layer stays purely presentational.
class AppCardMeta {
  static const String verdict = 'appCardVerdict';
  static const String image = 'appCardImage';
  static const String live = 'appCardLive';
  static const String appSlug = 'appCardSlug';
  static const String appTitle = 'appCardTitle';

  /// The app's declared `card_origin`, stamped only on an `ok` verdict.
  ///
  /// Carried through to the live frame so it can refuse off-origin navigation
  /// using the same [AppCardRef.isUnder] comparison that cleared the card in
  /// the first place. Without it the renderer would have to re-derive trust,
  /// which is exactly what stamping the verdict exists to avoid.
  static const String origin = 'appCardOrigin';

  /// True when the record DECLARED a live half and the trust walk refused it.
  ///
  /// Distinguishes the two things `imageOnly` otherwise flattens together, and
  /// they are not the same event at all:
  /// - **no live half declared** — a complete, correct, finished card.
  /// - **live half declared and refused** — the app was revoked, left the
  ///   registry, or the URL sits outside the declared origin. Something IS
  ///   wrong, even though the card still looks fine.
  ///
  /// Only the second is worth surfacing, and only to someone who can act on it
  /// (see the client's app-card renderer).
  static const String degraded = 'appCardDegraded';
  static const String checkedAt = 'appCardCheckedAt';

  /// Every key this class stamps. They are **view-time** facts -- the trust
  /// walk's answer on this device, now -- and must never be written to the
  /// chain: a stamped `origin` is a trust token, and persisting it would attach
  /// that token to a card no walk cleared. [Record.toChainValue] strips them at
  /// the single write boundary, so a re-save of a stamped record (the owner
  /// resizing an app card, a drag-reorder that rewrites the blob) emits only
  /// what the app itself published.
  static const Set<String> viewTimeKeys = {
    verdict, image, live, appSlug, appTitle, origin, degraded, checkedAt,
  };

  const AppCardMeta._();
}
