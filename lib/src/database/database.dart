import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:publicos_core/src/utils/channel_url.dart';
import 'package:publicos_core/src/utils/log.dart';
import 'converters.dart';

part 'database.g.dart';

// =============================================================================
// TABLE DEFINITIONS
// =============================================================================

/// Messages table - stores XMTP messages
///
/// Scoped per-XMTP-key via [ownerInboxId]. `sessionAddress` is the PublicOS
/// account wallet (one per profile); `ownerInboxId` is the inbox ID of the
/// XMTP key that was active when the message was stored. A single profile
/// can hold multiple XMTP keys in its keychain, so filtering only by
/// `sessionAddress` leaks messages from other keys under the same account.
class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get idXmtp => text().nullable()();
  TextColumn get xmtpMessageData => text()();
  IntColumn get timestamp => integer()();
  TextColumn get conversationTopic => text()();
  TextColumn get senderInboxId => text().nullable()();
  TextColumn get sessionAddress => text()();
  TextColumn get ownerInboxId => text()();
  TextColumn get typeId => text().nullable()();
  BoolColumn get isPending => boolean().withDefault(const Constant(false))();
  BoolColumn get sendFailed => boolean().withDefault(const Constant(false))();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {idXmtp, ownerInboxId}
      ];
}

/// Contacts table - stores identity rows. One row per person OR group-stub.
///
/// After the 1.0 split, this table is pure identity. For people, rows carry
/// a publicosAddress and/or registeredInboxIDs. For XMTP group chats, a
/// lightweight stub row is created keyed by [xmtpConversationTopic] — just
/// enough for the Browser and ContactIcon to render the group as if it were
/// a contact. The group's metadata (image, description, members) still lives
/// on [Conversations]; the stub only carries local display name + profile
/// records (color, seeded avatar).
///
/// Dedup rules applied by `saveContactRaw`:
///   1. publicosAddress match (people with on-chain accounts)
///   2. any registeredInboxIDs entry match (XMTP-only people)
///   3. xmtpConversationTopic match (group stubs)
class Contacts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get publicosDisplayName => text().nullable()();
  TextColumn get publicosAddress => text().nullable()();
  TextColumn get displayName => text()();
  BoolColumn get isOrgAccount =>
      boolean().withDefault(const Constant(false))();
  TextColumn get sessions => text().nullable()();          // JSON List<ContactSession>
  TextColumn get records => text().nullable()();          // JSON List<Record>
  TextColumn get registeredInboxIDs => text().nullable()(); // JSON List<InboxEntry>
  TextColumn get orgMembers => text().nullable()();       // JSON List<EthAddress> — org members (may be partial/paginated)
  IntColumn get orgMemberCount => integer().nullable()(); // Total org member count from chain
  BoolColumn get isBlocked =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isSupport =>
      boolean().withDefault(const Constant(false))();
  TextColumn get createdBy => text().nullable()();
  /// For orgs: founder's account address (eip55 hex). Immutable once set —
  /// the view layer silently resolves it into a Contact for display.
  TextColumn get founderAddress => text().nullable()();
  TextColumn get createdAt => text().nullable()();
  IntColumn get updatedAt => integer()();
  TextColumn get sessionAddress => text()();
  /// Present only on group-chat stubs; null for people.
  TextColumn get xmtpConversationTopic => text().nullable()();
  /// On-chain citizenship, lazily enriched on profile view. null = unknown.
  BoolColumn get isCitizen => boolean().nullable()();
  /// Orgs only — public-org flag (admits only citizens). The org analog of
  /// [isCitizen]; lazily enriched, cached. null = unknown.
  BoolColumn get isPublicOrg => boolean().nullable()();
  /// Icon-managed NFT-avatar verdict cache (JSON: pointer + metadata +
  /// verifiedOwnership + checkedAt). Written by the contact icon. null = none.
  TextColumn get verifiedNftAvatar => text().nullable()();
  TextColumn get verifiedNftBanner => text().nullable()();
  /// User-set bookmark flag (default false). Reserved for an upcoming
  /// real-vs-searched contact distinction; not wired to UI yet.
  BoolColumn get bookmarked => boolean().withDefault(const Constant(false))();
}

/// Conversations table - stores XMTP messaging channels (DMs and groups).
///
/// Primary key is (topic, ownerInboxId). `sessionAddress` is the PublicOS
/// account wallet; `ownerInboxId` is the active XMTP key's inbox ID. A
/// profile can hold multiple XMTP keys, so scoping by sessionAddress alone
/// lets a key-B session see key-A's conversations on the same peer.
/// No foreign key to contacts — peer identity is resolved by the view
/// layer matching peerInboxId against any contact's registeredInboxIDs.
class Conversations extends Table {
  TextColumn get topic => text()();
  TextColumn get type => text()();                    // 'dm' | 'group'
  TextColumn get peerInboxId => text().nullable()();  // DMs only
  TextColumn get groupName => text().nullable()();
  TextColumn get groupImageUrl => text().nullable()();
  TextColumn get groupDescription => text().nullable()();
  TextColumn get pinnedFrameUrl => text().nullable()();
  TextColumn get membersJson => text().nullable()();  // JSON List<Member>
  IntColumn get createdAt => integer().nullable()();
  TextColumn get sessionAddress => text()();
  TextColumn get ownerInboxId => text()();

  @override
  Set<Column> get primaryKey => {topic, ownerInboxId};
}

/// Settings table - stores key-value settings per user
class Settings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text()();
  TextColumn get record => text()();
  TextColumn get sessionAddress => text()();
  IntColumn get updatedAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {key, sessionAddress}
      ];
}

/// Feed servers table - stores RSS/feed server configurations
class FeedServers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get feedServerAddress => text()();
  TextColumn get name => text().nullable()();
  BoolColumn get isDefault =>
      boolean().withDefault(const Constant(false))();
  TextColumn get sessionAddress => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {feedServerAddress, sessionAddress}
      ];
}

/// RPC servers table - stores user-added custom RPC endpoints (per account)
class RpcServers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get rpcUrl => text()();
  TextColumn get name => text().nullable()();
  BoolColumn get isDefault =>
      boolean().withDefault(const Constant(false))();
  TextColumn get sessionAddress => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {rpcUrl, sessionAddress}
      ];
}

/// FeedLists table - stores feed lists
@DataClassName('FeedListData')
class FeedLists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get icon => text().nullable()();
  TextColumn get sessionAddress => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  // List that wraps a single feed and presents itself as that feed.
  // UI invariant: when true, count(feeds in list) ≤ 1 — enforced at the
  // sheet layer (see add_to_lists_sheet), no DB constraint.
  BoolColumn get isSingle =>
      boolean().withDefault(const Constant(false))();
}

/// List feeds junction table - links feeds to lists
class ListFeeds extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get listId => integer().customConstraint(
      'NOT NULL REFERENCES feed_lists(id) ON DELETE CASCADE')();
  TextColumn get feedUrl => text()();
  TextColumn get feedTitle => text().nullable()();
  TextColumn get feedDescription => text().nullable()();
  TextColumn get feedFoundAtAccountAddress => text().nullable()();

  /// The owner's `record.key` for this channel, when the row is a CHANNEL
  /// FOLLOW rather than a raw URL snapshot. Null = raw URL: fetch [feedUrl] as
  /// stored. Non-null = re-resolve the URL from the owner's records by this
  /// key, so the follow survives the author re-pointing or renaming the
  /// channel.
  ///
  /// Read by `PublicOSFollows.resolveListFeeds` (the only re-resolving reader;
  /// raw `getFeedsInList` callers still see the stored URL). Note it is NOT
  /// carried onto the rendered `Post`: the direct half of `resolveListItems`
  /// and `ListRowFeedOrigin` drop it.
  TextColumn get feedRecordKey => text().nullable()();
  IntColumn get addedAt => integer()();
}

/// On-device cache of a feed's last response — one row per (feed, session).
///
/// Exists so a feed list can be **painted instantly from disk** while the
/// network revalidates behind it, and so an unchanged feed can be revalidated
/// with an HTTP conditional GET (`If-None-Match` / `If-Modified-Since`) instead
/// of being re-downloaded in full.
///
/// **The cache unit is the FEED, not the post.** A `304 Not Modified` says "this
/// entire feed is unchanged" — so the feed is the unit of invalidation, and the
/// cache should match it. (A posts table would be a *second* cache that has to
/// stay coherent with the validators, which live per-feed regardless. It would
/// also mean ~840 upserts per refresh of a 21-feed list instead of 21.)
///
/// **Raw body, re-parsed on read** — deliberately, and deliberately unoptimised.
/// Storing pre-parsed posts would be faster, and since v27 `Post` does have a
/// lossless `fromJson` (the `toJson` inverse bookmarks use) that would make it
/// safe — but the raw body is still the right unit here because the HTTP
/// validators (`ETag`) describe the *body*, and re-parsing keeps the cached
/// path byte-identical to the network path. If the re-parse cost turns out to
/// hurt, the next lever is an in-memory parsed cache keyed by
/// `(feedUrl, etag)` — it composes on top and changes nothing here. Measure
/// first.
class FeedCache extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get feedUrl => text()();

  /// The house convention for per-user rows. `publicos.sqlite` is ONE file
  /// shared by every account on the device, so every per-user table carries
  /// this: `Settings{key, sessionAddress}`, `FeedLists.sessionAddress`,
  /// `BookmarkedPosts{postUid, feedUrl, sessionAddress}`. Reads are always
  /// `WHERE sessionAddress = ? AND feedUrl = ?`, so no account can reach
  /// another's row — a `304` only ever validates the copy *you* hold.
  TextColumn get sessionAddress => text()();

  /// The raw response body, exactly as received. Re-parsed on read.
  TextColumn get body => text()();
  TextColumn get contentType => text().nullable()();

  /// HTTP validators, echoed back on the next fetch as `If-None-Match` /
  /// `If-Modified-Since`. Null when the server sent none (plenty don't) — in
  /// which case we simply re-download, exactly as we do today.
  TextColumn get etag => text().nullable()();
  TextColumn get lastModified => text().nullable()();

  /// Drives eviction: rows older than 7 days are swept (nothing else prunes
  /// this table, and raw bodies run 50-500KB each).
  IntColumn get fetchedAt => integer()();

  /// The private-feed verdict, persisted. Without this the "some feeds in this
  /// list are private" banner needs a live 403 to know, so it can't survive a
  /// cold start.
  BoolColumn get locked => boolean().withDefault(const Constant(false))();

  /// Last failure for this feed, so a dead feed can render as *dead* rather
  /// than as empty.
  TextColumn get lastError => text().nullable()();

  /// The last interactions answer for this document, raw JSON (v33).
  /// A PublicOS Feed document carries no counts by design (they
  /// vary per reader and per minute, the document does not), so without this
  /// the cached paint would show every post count-less until phase 2 lands.
  /// Written with every answer, on a 200 with the new body and on a 304 beside
  /// the kept one; read back into the cached posts. Per session like the row,
  /// so a signed answer's viewer facts stay with the reader they belong to.
  TextColumn get interactions => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {feedUrl, sessionAddress}
      ];
}

/// Attachment cache table - caches remote attachments
class AttachmentCache extends Table {
  TextColumn get contentDigest => text()();
  TextColumn get filename => text()();
  TextColumn get mimeType => text()();
  BlobColumn get data => blob()();
  IntColumn get size => integer()();
  IntColumn get cachedAt => integer()();
  IntColumn get lastAccessed => integer()();

  @override
  Set<Column> get primaryKey => {contentDigest};
}

/// The user's saved sticker library — the local store behind the composer's
/// sticker panel. Deliberately NOT [AttachmentCache]: that table is an LRU
/// cache (30-day expiry, 500 MB eviction), so a saved sticker would silently
/// disappear. These rows are owned by the user and only they delete them.
///
/// A sticker is an ordinary `xmtp.org/attachment` carrying `isSticker`
/// (see the xmtp_plugin codec), and intake is inline-only under a 1 MB cap —
/// so [data] always holds the real bytes and no fetch is ever needed to
/// render or send one.
///
/// Scoped by [sessionAddress] (the device's session key —
/// NOTHING local is keyed by the account) ONLY — matches
/// [BookmarkedPosts] / [BookmarkedApps]. A sticker library is a personal
/// collection, not XMTP-inbox state, so several keychain keys under one
/// account share it (no `ownerInboxId`).
///
/// [digest] is `sha256(data)`. The unique key gives free, silent dedup: a
/// re-save of a sticker already in the library is an `insertOnConflictUpdate`
/// no-op that still reports success.
@DataClassName('SavedStickerRow')
class SavedStickers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get digest => text()();
  TextColumn get filename => text()();
  TextColumn get mimeType => text()();
  BlobColumn get data => blob()();
  IntColumn get size => integer()();
  TextColumn get sessionAddress => text()();
  IntColumn get savedAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {digest, sessionAddress}
      ];
}

/// Per-channel "Sign in" preference.
///
/// A row EXISTS only once the feed's server has advertised envelope support —
/// the `PublicOS-Envelope` response header `RssParser` captures on a fetch.
/// That is what lets the UI show the sign-in toggle only for feeds that
/// support it, with no URL-shape guessing: no row, no toggle.
///
/// [enabled] is the user's choice and discovery seeds it OFF — privacy-first,
/// nothing is signed until the user opts in. The key is the literal
/// [feedUrl]: consent means "attach my identity to fetches of THIS endpoint",
/// and a channel that moves servers gets a new URL, an unset state, and a
/// fresh ask — deliberately (new operator, new disclosure decision).
@DataClassName('ChannelSigninPref')
/// One row per (channel, signed-in session).
///
/// The ROW is the fact "this channel accepts sign-in": seeded by any server
/// signal (the `PublicOS-Envelope` header on a served 200/304, or the 401
/// challenge), `mode` refreshed on every fetch, deleted when a served 200
/// carries no signal. Its existence is what the client's key icon renders.
class ChannelSigninPrefs extends Table {
  /// The CHANNEL BASE URL — `<server>/api/<owner>/channels/<slug>` — never a
  /// feed / post / comments URL (every reader normalises with
  /// `channelBaseOf` first). Column name kept across the v31 migration.
  TextColumn get feedUrl => text()();

  /// House convention for per-user rows — see [FeedCache.sessionAddress].
  TextColumn get sessionAddress => text()();

  /// The user's answer: null = not answered · `accepted` · `denied`. Written
  /// ONLY by the user's three actions (Allow / Deny / Forget) — a fetch never
  /// touches it. Replaced `enabled: bool` in v31 (true → accepted, false →
  /// null: the old bool could not tell "never asked" from "declined").
  TextColumn get decision => text().nullable()();

  /// The signalled mode as last seen: `optional` (public channel, sign-in is
  /// a choice) or `required` (gated — the dialog's copy).
  TextColumn get mode => text().withDefault(const Constant('optional'))();

  IntColumn get discoveredAt => integer()();

  @override
  Set<Column> get primaryKey => {feedUrl, sessionAddress};
}

/// One saved sticker WITHOUT its bytes.
///
/// The gallery grid needs to know what exists, not what it looks like — a
/// 200-sticker library selected whole is ~20 MB of `Uint8List` sitting in the
/// Dart heap. [AppDatabase.getSavedStickerMeta] returns these; each tile then
/// pulls its own bytes via [AppDatabase.getSavedStickerData] and lets Flutter's
/// image cache hold them. Do not add a `data` field here.
class SavedStickerMeta {
  final int id;
  final String digest;
  final String filename;
  final String mimeType;
  final int size;
  final int savedAt;

  const SavedStickerMeta({
    required this.id,
    required this.digest,
    required this.filename,
    required this.mimeType,
    required this.size,
    required this.savedAt,
  });
}

/// Bookmarked apps table - stores app bookmarks
class BookmarkedApps extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get appName => text()();
  TextColumn get ownerAddress => text()();
  TextColumn get displayName => text()();
  TextColumn get iconUrl => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get warnings => text().nullable()();
  TextColumn get categoryOne => text().nullable()();
  TextColumn get categoryTwo => text().nullable()();
  TextColumn get url => text().nullable()();
  TextColumn get appstoreLink => text().nullable()();
  TextColumn get playstoreLink => text().nullable()();
  TextColumn get apkDownload => text().nullable()();
  TextColumn get ipaDownload => text().nullable()();
  TextColumn get sessionAddress => text()();
  IntColumn get bookmarkedAt => integer()();
  IntColumn get nextUpdate => integer().nullable()(); // When to refresh from blockchain (epoch ms)

  @override
  List<Set<Column>> get uniqueKeys => [
        {appName, ownerAddress, sessionAddress}
      ];
}

/// Sites the user has connected to in the in-app browser.
///
/// A row IS the permission: its presence is what lets the bridge answer
/// `eth_accounts` with a real address for [origin]. No row, no address — the
/// injected provider carries no identity until one of these exists.
///
/// The identity of a grant is (origin, sessionAddress, grantedEoa) — all three:
///  · origin        — the unit the user reasons about ("I connected to Quests").
///  · sessionAddress — `publicos.sqlite` is ONE file shared by every account on
///                    the device (see [FeedCache]), so a grant made by one
///                    account must not apply to the next. Same house convention.
///  · grantedEoa    — the user consented to sharing AN IDENTITY, not a slot. A
///                    site granted your Session Key has no claim on a keychain
///                    EOA you switch to later. Not the same key => not granted.
///
/// [keyLabel] is DISPLAY ONLY (the connect sheet's copy, a future "connected
/// sites" list). A key rename is not a new identity, so it must never revoke a
/// grant — permission is decided by [grantedEoa] alone, never the label.
class ConnectedSites extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get origin => text()(); // scheme://host[:port] — ConnectGate.originKey
  TextColumn get sessionAddress => text()(); // account scope, lowercased
  TextColumn get grantedEoa => text()(); // lowercased — THE AUTHORITY
  TextColumn get keyLabel => text().nullable()(); // display only (null/'session' = session key)
  IntColumn get grantedAt => integer()();
  IntColumn get lastUsedAt => integer()(); // so a future "connected sites" list can sort
  // The site's ACTIVE key: at most one row per
  // (origin, session) carries true. Lives ON the grant row so an active key is
  // visible by construction and a revoke deletes the choice with the grant.
  BoolColumn get activeKey => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {origin, sessionAddress, grantedEoa}
      ];
}

/// Accounts the user follows. A row IS the follow.
///
/// The feed set a follow yields is NOT stored here. It is DERIVED at read time
/// from the account's own profile — its `RecordType.router` records of subtype
/// `channel` (see `PublicOSFollows.resolveProfileChannels`) — because that set
/// is the author's curated broadcast list and changes without our involvement.
/// Storing URLs at follow time would freeze a snapshot the author has since
/// moved on from. Follow the account; ask the profile what it publishes.
///
/// Deliberately NOT the SSP channel table: that answers "what does this server
/// hold for A", which silently over-includes channels A never enlisted.
///
/// [accountAddress] is stored `eip55With0x` to match [Contacts.publicosAddress]
/// (see [AppDatabase.getContactByPublicosAddress]) — the two are joined by
/// address on every read, so the casing must agree. Do NOT lowercase it here;
/// this table follows the contacts convention, not the [ConnectedSites] one.
///
/// There is no `channelsCheckedAt`. Freshness of the derived channel set lives
/// on the contact that holds it ([Contacts.updatedAt]), not on the follow — a
/// follow doesn't go stale, the profile snapshot does.
/// [listId] makes an account a MEMBER OF A LIST rather than a global follow.
/// Following the same account in "News" and in "Friends" is two rows, and a
/// mute placed in one does not silence it in the other — per-list scoping is
/// the whole point of the unified-list model.
class FollowedAccounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionAddress => text()(); // the viewer
  TextColumn get accountAddress => text()(); // the followed account, eip55With0x
  IntColumn get listId => integer().customConstraint(
      'NOT NULL REFERENCES feed_lists(id) ON DELETE CASCADE')();
  IntColumn get followedAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {sessionAddress, accountAddress, listId}
      ];
}

/// One muted channel inside a followed account. Subtracted at read time.
///
/// Keyed by [recordKey] — the owner's `record.key`, NOT the feed URL. A mute is
/// a statement about a CHANNEL, and a channel outlives its address: the author
/// can re-point it at a new URL or rename it, and a mute anchored on the URL
/// would silently lapse the moment they did. The record key is the only
/// identifier that survives both.
///
/// Scope is (sessionAddress, accountAddress, listId, recordKey). A `record.key`
/// is only unique WITHIN an owner's record set, so the account is part of the
/// key, not decoration — two accounts may both publish a channel keyed
/// `newsletter`. Muting under account A must never silence account B's.
///
/// A row may outlive its channel (the author un-enlists something you muted).
/// That orphan is harmless — it matches nothing — and is not worth a sweep.
/// Scope gains [listId]: a mute is placed INSIDE one list. Muting a channel in
/// "News" leaves the same channel audible in "Friends" — deliberate, and the
/// manage UI has to make that legible.
class MutedChannels extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionAddress => text()(); // the viewer
  TextColumn get accountAddress => text()(); // the followed account, eip55With0x
  IntColumn get listId => integer().customConstraint(
      'NOT NULL REFERENCES feed_lists(id) ON DELETE CASCADE')();
  TextColumn get recordKey => text()(); // the owner's record.key — stable id
  IntColumn get mutedAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {sessionAddress, accountAddress, listId, recordKey}
      ];
}

/// Bookmarked posts — a saved post stored AS AN OBJECT.
///
/// [postJson] (the full `Post.toJson()` blob, read back via the lossless
/// `Post.fromJson`) is the record; the other columns exist only for the
/// identity key, the `WHERE`/`ORDER BY`, and [title] as the key fallback for
/// uid-less external posts. Deliberately NO content columns: storing every
/// post twice (typed columns + the blob) gives two sources
/// of truth that drift — the render reads the blob while the key reads the
/// columns, which corrupts bookmark identity (the columns were dropped in
/// v27).
class BookmarkedPosts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get postUid => text()();
  TextColumn get title => text()();
  TextColumn get feedUrl => text().nullable()();
  TextColumn get postJson => text()();
  TextColumn get sessionAddress => text()();
  IntColumn get bookmarkedAt => integer()();

  /// Last successful server sync of [postJson] (ms epoch). Seeded to the
  /// bookmark time on insert; bumped by every refresh write-back (v28).
  /// Drives the Bookmarks view's staleness sweep.
  IntColumn get updatedAt => integer()();

  /// The server answered "gone" (`POST_NOT_FOUND` and kin) on the last
  /// refresh — the local blob may be the only copy left, so it is kept
  /// verbatim and surfaced with the cloud-off badge; retries back off to
  /// the slower cadence (v28).
  BoolColumn get unavailable => boolean().withDefault(const Constant(false))();

  /// The single-post read's `ETag` validator (v28). Echoed back as
  /// `If-None-Match` on the next refresh so an unchanged post revalidates
  /// with a 304 instead of a full body — same contract as [FeedCache].
  /// Null until the first successful refresh (the bookmark write itself has
  /// no response to take a validator from).
  TextColumn get etag => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {postUid, feedUrl, sessionAddress}
      ];
}

/// On-chain activity feed — contract events touching the user or their
/// contacts, polled client-side via `getLogs` (see `PublicOSActivity`).
///
/// Scoped by [sessionAddress] (the device's session key, as every per-user
/// table) ONLY — this is
/// blockchain-account data, not XMTP-inbox data, so unlike [Messages] it
/// carries no `ownerInboxId` (matches [BookmarkedPosts]). Dedup is
/// (txHash, logIndex, sessionAddress): one transaction can emit several
/// same-type events (e.g. a multi-record update fires several `RecordSet`),
/// so `eventType` alone would collapse them.
@DataClassName('ActivityEventRow')
class ActivityEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get eventType => text()(); // ActivityEventType.* slug
  TextColumn get actor => text()(); // primary subject, eip55
  TextColumn get target => text().nullable()(); // secondary subject, eip55
  IntColumn get blockNumber => integer()();
  IntColumn get logIndex => integer()();
  TextColumn get txHash => text()();
  IntColumn get timestamp => integer()(); // block ts, ms epoch
  TextColumn get data => text().withDefault(const Constant('{}'))(); // JSON blob
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  TextColumn get sessionAddress => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {txHash, logIndex, sessionAddress}
      ];
}

/// One row of the `used_nft_avatars` table — NFT avatars the current session
/// has *seen as owned by self*. A per-client history that powers the avatar
/// sheet's "Previously used" (EVM) and "Pick mine or used" (Solana) quick-pick
/// grids. EVM has no on-chain enumeration, so this history is the only way to
/// surface "my" EVM NFTs; Solana also stores its live-enumerated mints here so
/// the set persists and the two sources can be merged + deduped.
///
/// Rows carry a cached ownership verdict ([verifiedOwnership] + [checkedAt]) so
/// the grid renders shimmer/sparkles without a chain call, re-verifying only
/// when the verdict is past its TTL. Keyed by [pointerKey] (`ref.toCaip19()`)
/// + [sessionAddress].
///
/// NOTE: this table is served by a **raw-SQL DAO** ([usedNftAvatarsDdl],
/// [AppDatabase.getUsedNftAvatars], [AppDatabase.insertUsedNftAvatar]) rather
/// than a generated drift table. The pinned `drift_dev 2.22.1` codegen is
/// incompatible with the active Dart SDK 3.12 (the SDK dropped `_macros`, which
/// `analyzer ^6` → `macros` needs), so `build_runner` cannot regenerate
/// `database.g.dart` in this environment. The column names below match what a
/// drift `Table` would emit 1:1, so promoting to a normal drift table later
/// (add the `Table` class to the `@DriftDatabase` list + regen) migrates the
/// existing data transparently.
class UsedNftAvatarRow {
  final int id;
  final String pointerKey;
  final String namespace;
  final int chain;
  final String standard;
  final String contract;
  final String tokenId;
  final String? mint;
  final String? imageUrl;
  final String? chainName;
  final String? owner;
  final bool verifiedOwnership;
  final int checkedAt;
  final String sessionAddress;
  final int lastSeenAt;

  const UsedNftAvatarRow({
    required this.id,
    required this.pointerKey,
    required this.namespace,
    required this.chain,
    required this.standard,
    required this.contract,
    required this.tokenId,
    required this.mint,
    required this.imageUrl,
    required this.chainName,
    required this.owner,
    required this.verifiedOwnership,
    required this.checkedAt,
    required this.sessionAddress,
    required this.lastSeenAt,
  });

  factory UsedNftAvatarRow.fromRow(QueryRow r) => UsedNftAvatarRow(
        id: r.read<int>('id'),
        pointerKey: r.read<String>('pointer_key'),
        namespace: r.read<String>('namespace'),
        chain: r.read<int>('chain'),
        standard: r.read<String>('standard'),
        contract: r.read<String>('contract'),
        tokenId: r.read<String>('token_id'),
        mint: r.readNullable<String>('mint'),
        imageUrl: r.readNullable<String>('image_url'),
        chainName: r.readNullable<String>('chain_name'),
        owner: r.readNullable<String>('owner'),
        verifiedOwnership: r.read<int>('verified_ownership') != 0,
        checkedAt: r.read<int>('checked_at'),
        sessionAddress: r.read<String>('session_address'),
        lastSeenAt: r.read<int>('last_seen_at'),
      );
}

/// DDL for the raw-SQL `used_nft_avatars` table (see [UsedNftAvatarRow]).
const String usedNftAvatarsDdl = '''
CREATE TABLE IF NOT EXISTS used_nft_avatars (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  pointer_key TEXT NOT NULL,
  namespace TEXT NOT NULL,
  chain INTEGER NOT NULL DEFAULT 0,
  standard TEXT NOT NULL DEFAULT '',
  contract TEXT NOT NULL DEFAULT '',
  token_id TEXT NOT NULL DEFAULT '',
  mint TEXT,
  image_url TEXT,
  chain_name TEXT,
  owner TEXT,
  verified_ownership INTEGER NOT NULL DEFAULT 0,
  checked_at INTEGER NOT NULL DEFAULT 0,
  session_address TEXT NOT NULL,
  last_seen_at INTEGER NOT NULL,
  UNIQUE (pointer_key, session_address)
)''';

// =============================================================================
// DATABASE CLASS
// =============================================================================

@DriftDatabase(tables: [
  Messages,
  Contacts,
  Conversations,
  Settings,
  FeedServers,
  RpcServers,
  FeedLists,
  ListFeeds,
  FeedCache,
  AttachmentCache,
  BookmarkedApps,
  BookmarkedPosts,
  ActivityEvents,
  SavedStickers,
  ConnectedSites,
  FollowedAccounts,
  MutedChannels,
  ChannelSigninPrefs,
])
class AppDatabase extends _$AppDatabase {
  static const _tag = 'Database';

  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 33;

  /// Does [table] carry [column] right now? The ladder asks this before a
  /// step that would add or read a column, because `m.createTable` builds a
  /// table from its CURRENT definition: a DB that created `connected_sites`
  /// at v22 in this same run already has v30's `active_key`, and one that
  /// created `channel_signin_prefs` at v25 already has v31's `decision` and
  /// no `enabled`. A bare `addColumn` / `SELECT` there throws (see
  /// `migration` for how a throw is contained).
  Future<bool> _hasColumn(Migrator m, String table, String column) async {
    final cols =
        await m.database.customSelect('PRAGMA table_info($table)').get();
    return cols.any((r) => r.read<String>('name') == column);
  }

  /// Optional override for the resolved DB file path. When set, every caller
  /// of [resolveDbFile] (main isolate, bg sweep) opens this exact path
  /// instead of the default `<app support>/publicos.sqlite`. publicos_client
  /// uses this to relocate the DB into an iOS App Group container so the
  /// Notification Service Extension can read the contacts table. Set BEFORE
  /// the first `AppDatabase()` construction. The owner is responsible for
  /// moving any existing data into the new path first (no legacy probe is
  /// run when an override is active).
  static String? dbPathOverride;

  /// Resolves the canonical SQLite file path on native platforms. Single
  /// source of truth for both the main isolate's [_openConnection] and the
  /// Workmanager bg sweep's isolate, which must open the same file or
  /// reads return empty. Runs the legacy-docs-dir migration as a side
  /// effect on first call after upgrade.
  ///
  /// On Windows this resolves to `%APPDATA%\Roaming\<org>\<app>\publicos.sqlite`,
  /// outside any folder OneDrive Personal backs up by default. The previous
  /// `drift_flutter` one-liner defaulted to [getApplicationDocumentsDirectory]
  /// (i.e. `%USERPROFILE%\Documents`), and OneDrive re-uploaded the entire
  /// SQLite file on every commit.
  static Future<File> resolveDbFile() async {
    if (dbPathOverride != null) {
      final file = File(dbPathOverride!);
      await Directory(p.dirname(file.path)).create(recursive: true);
      return file;
    }
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'publicos.sqlite'));
    if (!await file.exists()) {
      await _migrateLegacyDocumentsDb(file);
    }
    return file;
  }

  /// Opens the database connection based on platform.
  static QueryExecutor _openConnection() {
    if (kIsWeb) {
      return driftDatabase(
        name: 'publicos',
        web: DriftWebOptions(
          sqlite3Wasm: Uri.parse('sqlite3.wasm'),
          driftWorker: Uri.parse('drift_worker.js'),
          // Use IndexedDB as fallback if WASM fails
          onResult: (result) {
            if (result.missingFeatures.isNotEmpty) {
              debugPrint(
                  'Drift web: Missing features: ${result.missingFeatures}');
            }
            debugPrint('Drift web: Using ${result.chosenImplementation}');
          },
        ),
      );
    }
    return LazyDatabase(() async {
      final file = await resolveDbFile();
      // createInBackground hosts sqlite in a background isolate. On Windows that
      // path is fragile across the dev loop: a hot restart orphans the isolate
      // (it keeps publicos.sqlite locked, so the next open hangs), and an
      // interrupted open can take the whole process down (exit -1).
      // Open on the main isolate on
      // Windows; mobile keeps the background isolate for UI smoothness.
      if (defaultTargetPlatform == TargetPlatform.windows) {
        return NativeDatabase(file);
      }
      return NativeDatabase.createInBackground(file);
    });
  }

  /// One-shot migration of the DB from the legacy location
  /// (`getApplicationDocumentsDirectory()/publicos.sqlite`) to the current
  /// application-support location. No-op once the new file exists or there is
  /// nothing at the legacy path.
  static Future<void> _migrateLegacyDocumentsDb(File target) async {
    try {
      final legacyDir = await getApplicationDocumentsDirectory();
      final legacy = File(p.join(legacyDir.path, 'publicos.sqlite'));
      if (!await legacy.exists()) return;
      await Directory(p.dirname(target.path)).create(recursive: true);
      await _moveFile(legacy, target);
      for (final ext in const ['-wal', '-shm', '-journal']) {
        final src = File('${legacy.path}$ext');
        if (await src.exists()) {
          await _moveFile(src, File('${target.path}$ext'));
        }
      }
      Log.i(_tag, 'Migrated legacy DB ${legacy.path} -> ${target.path}');
    } catch (e, st) {
      Log.e(_tag, 'Legacy DB migration failed: $e\n$st');
    }
  }

  static Future<void> _moveFile(File src, File dst) async {
    try {
      await src.rename(dst.path);
    } on FileSystemException {
      // Cross-volume rename fails on Windows; fall back to copy + delete.
      await src.copy(dst.path);
      await src.delete();
    }
  }

  /// Create a database instance for a specific file path (for testing or migration)
  static AppDatabase forPath(String path) {
    return AppDatabase(
      driftDatabase(
        name: path,
        native: const DriftNativeOptions(shareAcrossIsolates: false),
      ),
    );
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Raw-SQL table not in the drift codegen set (see UsedNftAvatarRow).
          await customStatement(usedNftAvatarsDdl);
          debugPrint('AppDatabase: Created all tables');
        },
        onUpgrade: (m, from, to) async {
          debugPrint('AppDatabase: Upgrading from $from to $to');
          // One transaction for the whole ladder (the idiom drift
          // documents in `VersionedSchema.runMigrationSteps`): drift runs
          // onUpgrade with NO transaction and stamps user_version only after
          // it returns, so without one a step that throws leaves the file at
          // the old version with the earlier steps already applied, and every
          // later launch fails earlier than the one before (e.g. on a
          // duplicate column). Inside the transaction a throw
          // rolls every step back and the next launch replays from a clean
          // old version. foreign_keys must be set OUTSIDE the transaction
          // (a no-op inside one); beforeOpen turns it back on.
          await customStatement('PRAGMA foreign_keys = OFF');
          await transaction(() async {
            if (from < 2) {
              // Add nextUpdate column to bookmarked_apps table
              await m.addColumn(bookmarkedApps, bookmarkedApps.nextUpdate);
              debugPrint('AppDatabase: Added nextUpdate column to bookmarked_apps');
            }
            if (from < 3) {
              // Create bookmarked_posts table
              await m.createTable(bookmarkedPosts);
              debugPrint('AppDatabase: Created bookmarked_posts table');
            }
            if (from < 4) {
              // Rename isGroupAccount → isOrgAccount column
              await customStatement(
                'ALTER TABLE contacts RENAME COLUMN is_group_account TO is_org_account',
              );
              debugPrint('AppDatabase: Renamed is_group_account to is_org_account');
            }
            if (from < 5) {
              // Add isRead column to messages table for unread tracking
              // Guard: column may already exist if DB was created with v5 schema
              // while still reporting v4 version
              try {
                await m.addColumn(messages, messages.isRead);
                debugPrint('AppDatabase: Added is_read column to messages');
              } catch (e) {
                debugPrint('AppDatabase: is_read column already exists, skipping');
              }
            }
            if (from < 6) {
              // Add RPC servers table for custom RPC endpoints
              await m.createTable(rpcServers);
              debugPrint('AppDatabase: Created rpc_servers table');
            }
            if (from < 7) {
              // Rename feed_slug → channel_slug in bookmarked_posts (Channel unification)
              try {
                await customStatement(
                  'ALTER TABLE bookmarked_posts RENAME COLUMN feed_slug TO channel_slug',
                );
                debugPrint('AppDatabase: Renamed feed_slug to channel_slug in bookmarked_posts');
              } catch (e) {
                debugPrint('AppDatabase: feed_slug rename failed (may not exist), skipping: $e');
              }
            }
            if (from < 8) {
              // Contact/Conversation split — fresh install for messaging state.
              // Drop and recreate contacts with the new person-only schema,
              // and create the new conversations table from scratch.
              await customStatement('DROP TABLE IF EXISTS contacts');
              await m.createTable(contacts);
              await m.createTable(conversations);
              debugPrint('AppDatabase: v8 — recreated contacts + created conversations');
            }
            if (from < 9) {
              // Add xmtpConversationTopic column to contacts for group-chat stubs.
              try {
                await m.addColumn(contacts, contacts.xmtpConversationTopic);
                debugPrint('AppDatabase: v9 — added xmtp_conversation_topic to contacts');
              } catch (e) {
                debugPrint('AppDatabase: xmtp_conversation_topic column add failed (may already exist): $e');
              }
            }
            if (from < 11) {
              // v10 + v11 folded: cross-XMTP-key isolation via a new
              // ownerInboxId column on messages + conversations. The first
              // cut (v10) used addColumn, which left the old primary key
              // `{topic, clientAddress}` in place and broke drift's
              // `ON CONFLICT(topic, owner_inbox_id)` upsert (SqliteException
              // "ON CONFLICT clause does not match any PRIMARY KEY or UNIQUE
              // constraint"). v11 drops + recreates both tables so the new
              // primary/unique keys take effect. Existing rows couldn't carry
              // a retroactive ownerInboxId anyway (clientAddress was the
              // account, not the key), so wiping is the right move — XMTP
              // re-syncs on next connect. Matches the v8 migration's "fresh
              // install for messaging state" precedent.
              await customStatement('DROP TABLE IF EXISTS messages');
              await customStatement('DROP TABLE IF EXISTS conversations');
              await m.createTable(messages);
              await m.createTable(conversations);
              debugPrint('AppDatabase: v11 — dropped + recreated messages + conversations with owner_inbox_id scoping');
            }
            if (from < 12) {
              // is_single flag on feed_lists — list wraps a single feed and
              // presents itself as that feed. Existing rows default to false
              // (plain multi-feed lists), so addColumn is sufficient.
              try {
                await m.addColumn(feedLists, feedLists.isSingle);
                debugPrint('AppDatabase: v12 — added is_single column to feed_lists');
              } catch (e) {
                debugPrint('AppDatabase: is_single column add failed (may already exist): $e');
              }
            }
            if (from < 13) {
              // is_citizen nullable flag on contacts — on-chain citizenship,
              // lazily enriched on profile view. Existing rows stay null
              // (unknown) until their profile is next opened, so addColumn
              // is sufficient.
              try {
                await m.addColumn(contacts, contacts.isCitizen);
                debugPrint('AppDatabase: v13 — added is_citizen column to contacts');
              } catch (e) {
                debugPrint('AppDatabase: is_citizen column add failed (may already exist): $e');
              }
            }
            if (from < 14) {
              // founder_address nullable column on contacts — for orgs, the
              // founder's account address (was previously only fetched live by
              // the profile page). Existing rows stay null until next synced,
              // so addColumn is sufficient.
              try {
                await m.addColumn(contacts, contacts.founderAddress);
                debugPrint('AppDatabase: v14 — added founder_address column to contacts');
              } catch (e) {
                debugPrint('AppDatabase: founder_address column add failed (may already exist): $e');
              }
            }
            if (from < 15) {
              // is_public_org + verified_nft_avatar nullable columns on contacts.
              // isPublicOrg: org analog of isCitizen (lazily enriched, cached).
              // verifiedNftAvatar: icon-managed NFT-avatar verdict cache (JSON).
              // Existing rows stay null until next enriched, so addColumn suffices.
              try {
                await m.addColumn(contacts, contacts.isPublicOrg);
                debugPrint('AppDatabase: v15 — added is_public_org column to contacts');
              } catch (e) {
                debugPrint('AppDatabase: is_public_org column add failed (may already exist): $e');
              }
              try {
                await m.addColumn(contacts, contacts.verifiedNftAvatar);
                debugPrint('AppDatabase: v15 — added verified_nft_avatar column to contacts');
              } catch (e) {
                debugPrint('AppDatabase: verified_nft_avatar column add failed (may already exist): $e');
              }
            }
            if (from < 16) {
              // Create used_nft_avatars (raw SQL — not in the drift codegen set,
              // see UsedNftAvatarRow) — per-client history of NFT avatars seen as
              // owned by self, backing the avatar sheet's quick-pick grids.
              await customStatement(usedNftAvatarsDdl);
              debugPrint('AppDatabase: v16 — created used_nft_avatars table');
            }
            if (from < 17) {
              // verifiedNftBanner: banner analog of verifiedNftAvatar — the
              // NftBanner widget's verdict cache (resolved image + ownership +
              // TTL anchor, JSON). Existing rows stay null until next rendered,
              // so addColumn suffices.
              try {
                await m.addColumn(contacts, contacts.verifiedNftBanner);
                debugPrint('AppDatabase: v17 — added verified_nft_banner column to contacts');
              } catch (e) {
                debugPrint('AppDatabase: verified_nft_banner column add failed (may already exist): $e');
              }
            }
            if (from < 18) {
              // Create activity_events table — on-chain activity feed cache
              // (vouches, citizenships, domain rent, name changes...) polled
              // client-side via getLogs. See PublicOSActivity.
              await m.createTable(activityEvents);
              debugPrint('AppDatabase: v18 — created activity_events table');
            }
            if (from < 19) {
              // bookmarked flag on contacts (user-set; DB default false). New
              // column, existing rows default to false, so addColumn suffices.
              try {
                await m.addColumn(contacts, contacts.bookmarked);
                debugPrint('AppDatabase: v19 — added bookmarked column to contacts');
              } catch (e) {
                debugPrint('AppDatabase: bookmarked column add failed (may already exist): $e');
              }
            }
            if (from < 20) {
              // The user's saved sticker library (see [SavedStickers]).
              await m.createTable(savedStickers);
              debugPrint('AppDatabase: v20 — created saved_stickers table');

              // Long-parked rename, bundled into this bump: the column never
              // meant "the account that originated the post", it meant "the
              // account whose profile we found this feed on". NOT wrapped in
              // try/catch — a rename that fails means the schema is not what we
              // think it is, and swallowing that would leave `.g.dart` reading a
              // column that doesn't exist. Fail loud, at migration time.
              //
              // v20 originally renamed the same column on bookmarked_posts too;
              // that table lost the column entirely in v27 (drop-and-recreate),
              // so the rename was removed here — any DB below 20 reaches v27 in
              // the same onUpgrade run and the recreate supersedes it.
              await m.renameColumn(listFeeds, 'originating_account_address',
                  listFeeds.feedFoundAtAccountAddress);
              debugPrint('AppDatabase: v20 — renamed originating_account_address '
                  '-> feed_found_at_account_address (list_feeds)');
            }

            if (from < 21) {
              // Feed cache (see [FeedCache]). Paints a feed list from disk while
              // the network revalidates behind it, and stores the HTTP validators
              // so an unchanged feed costs a 304 instead of a full download.
              // Purely additive: a fresh table, no existing column touched. On a
              // miss the readers fall straight through to the network, so an
              // empty table behaves exactly like today.
              await m.createTable(feedCache);
              debugPrint('AppDatabase: v21 — created feed_cache table');
            }

            if (from < 22) {
              // Per-origin browser connect grants (see [ConnectedSites]). Purely
              // additive: a fresh table, no existing column touched.
              //
              // An EMPTY table is the correct upgrade state and is NOT a
              // regression: nobody has granted anything yet, because until this
              // build nobody was ever asked — the address was simply baked into
              // the injected provider. Every site starts disconnected, including
              // ones the user opened yesterday. That is the point of the change,
              // not a side effect — do NOT backfill grants from bookmarked apps.
              await m.createTable(connectedSites);
              debugPrint('AppDatabase: v22 — created connected_sites table');
            }

            if (from < 23) {
              // Account-based follow (see [FollowedAccounts], [MutedChannels]).
              // Purely additive: two fresh tables, no existing column touched.
              //
              // Nothing is backfilled, and that is deliberate. The existing
              // single-feed follows (the `Following` list in [ListFeeds]) are NOT
              // migrated into account follows: a stored feed URL only tells us
              // where the feed was FOUND, never who owns it — `list_feeds`
              // carries `feedFoundAtAccountAddress`, which is nullable and is
              // provenance, not ownership. Deriving follows from it would
              // silently subscribe the user to sibling channels of an account
              // they never followed. The two stores coexist and are merged at
              // read time instead; see `PublicOSFollows.resolveFollowingFeeds`.
              await m.createTable(followedAccounts);
              await m.createTable(mutedChannels);
              debugPrint('AppDatabase: v23 — created followed_accounts + '
                  'muted_channels tables');
            }

            if (from < 24) {
              // Unified lists: accounts and mutes
              // become PER-LIST, mutes re-anchor from feed_url onto the owner's
              // record.key, and list_feeds gains the channel anchor.
              //
              // The mute re-anchor needs no separate step: the drop-and-recreate
              // below rebuilds muted_channels from the current definition, which
              // already carries record_key instead of feed_url.
              //
              // Why a v24 step at all, when v23 shipped to nobody? Because "not
              // shipped" is not "never run": a dev machine that ran the v23
              // build IS at 23, and amending the v23 definitions in place would
              // leave that DB with the old columns and NO migration to fix it
              // (migrations only run when the version increases). This step is
              // the cheap, honest fix.
              //
              // Drop-and-recreate rather than add-column: these two tables hold
              // only follow bookkeeping that re-derives from a single re-follow,
              // there are no real users, and ALTER-ing in a NOT NULL FK column
              // with no sensible default is worse than starting clean. Note
              // createTable uses the CURRENT definitions, so a device coming
              // from v22 gets the new shape at v23 and this step is a harmless
              // no-op re-create.
              await m.deleteTable('followed_accounts');
              await m.deleteTable('muted_channels');
              await m.createTable(followedAccounts);
              await m.createTable(mutedChannels);

              // list_feeds is a COMMITTED table with real rows — additive only,
              // guarded the way v19 does it. (Unlike v20's rename, which is
              // deliberately unguarded so a schema mismatch fails loud.)
              try {
                await m.addColumn(listFeeds, listFeeds.feedRecordKey);
              } catch (e) {
                debugPrint('AppDatabase: v24 — list_feeds.feed_record_key may '
                    'already exist: $e');
              }
              debugPrint('AppDatabase: v24 — per-list follows/mutes + '
                  'list_feeds.feed_record_key');
            }

            if (from < 25) {
              // Channel sign-in prefs. Purely additive: one
              // fresh table, discovery-seeded at fetch time, nothing backfilled
              // (a pref only exists once the server has advertised support).
              await m.createTable(channelSigninPrefs);
              debugPrint('AppDatabase: v25 — created channel_signin_prefs table');
            }

            if (from < 26) {
              // The v25 table briefly existed as `feed_signin_prefs` before the
              // same-day channel-vocabulary rename. "Not shipped" is not "never
              // run" (the v24 lesson): a dev DB that ran the pre-rename build IS
              // at 25 with the old name and would never get the new table —
              // every pref read then throws "no such table". Drop the old name
              // (discovery-seeded rows, they re-derive on the next fetch) and
              // create the new one; both statements are no-ops on a DB that
              // never saw the pre-rename build (createTable is IF NOT EXISTS).
              await m.database
                  .customStatement('DROP TABLE IF EXISTS feed_signin_prefs');
              await m.createTable(channelSigninPrefs);
              debugPrint(
                  'AppDatabase: v26 — feed_signin_prefs → channel_signin_prefs');
            }

            if (from < 27) {
              // Bookmarks rewrite:
              // the blob IS the record; the 9 content columns that duplicated it
              // (content_text, summary, external_url, image, feed_title,
              // channel_slug, feed_found_at_account_address, author_name,
              // author_url) are gone. They were written on every bookmark and
              // read by nothing — the render read the blob while the identity
              // key read the columns, two sources of truth that could (and did)
              // disagree.
              //
              // Drop-and-recreate, not ALTER: pre-v27 rows are corrupt anyway —
              // the old lossy read (`fromJsonFeedItem` on a `toJson` blob)
              // dropped `feed_url` on rehydration, so un-bookmarking from the
              // Bookmarks view no-oped and re-tapping inserted duplicate rows
              // with feed_url NULL. No users, dev data; wiping is the repair.
              await m.deleteTable('bookmarked_posts');
              await m.createTable(bookmarkedPosts);
              debugPrint('AppDatabase: v27 — bookmarked_posts rebuilt: blob is '
                  'the record, content columns dropped');
            }

            if (from < 28) {
              // Bookmark refresh:
              // `updated_at` (staleness sweep anchor) + `unavailable` (the
              // server-says-gone flag behind the cloud-off badge). A
              // sibling of v27, and a real step for the same reason v24 was:
              // "not shipped" is not "never ran" — a dev DB that ran a v27
              // build sits at 27 and amending v27 in place would strand it.
              // Drop-and-recreate again (v27's rationale carries: dev rows,
              // and `updated_at` is NOT NULL with no sensible backfill).
              await m.deleteTable('bookmarked_posts');
              await m.createTable(bookmarkedPosts);
              debugPrint('AppDatabase: v28 — bookmarked_posts + updated_at/'
                  'unavailable/etag (refresh sweep + conditional GET)');
            }

            if (from < 29) {
              // Scope homologation (the rule: NOTHING is keyed by
              // the account address — every per-user table keys on the CLIENT
              // address, the signing key). The apps had written bookmarked_posts
              // and connected_sites rows scoped by the ACCOUNT address.
              // Wrongly-scoped rows are invisible to correctly-scoped reads
              // (a write-back against them is a
              // silent 0-row UPDATE), and both tables hold cheap data:
              // bookmarks are re-bookmarkable, and being re-asked to connect is
              // the grant feature's own stated posture (see the v22 note). Wipe
              // rather than re-key — unlike the feed lists there are
              // no rows worth preserving.
              await m.deleteTable('bookmarked_posts');
              await m.createTable(bookmarkedPosts);
              await m.database.customStatement('DELETE FROM connected_sites');
              debugPrint('AppDatabase: v29 — scope homologation: '
                  'bookmarked_posts recreated, connected_sites cleared '
                  '(session-address scope everywhere)');
            }
            if (from < 30 &&
                !await _hasColumn(m, 'connected_sites', 'active_key')) {
              // Per-site ACTIVE key flag on the grant row.
              // Skipped when v22 created the table from the current definition
              // in this same run (see `_hasColumn`).
              await m.addColumn(connectedSites, connectedSites.activeKey);
              debugPrint('AppDatabase: v30 — connected_sites.active_key added');
            }
            if (from < 31 &&
                await _hasColumn(m, 'channel_signin_prefs', 'enabled')) {
              // Skipped when v25 created the table from the current definition
              // in this same run: it already has `decision`, nothing to re-key
              // (see `_hasColumn`).
              //
              // channel_signin_prefs:
              // `enabled` bool → nullable `decision` text, and the key becomes
              // the CHANNEL BASE URL. Rows are KEPT — they are the key icon —
              // and re-keyed in Dart, because two old rows for one channel
              // (…/json and …/rss) may collapse onto one key and the old bool
              // cannot tell "never asked" from "declined" (true → accepted,
              // false → null: ask again).
              final old = await m.database
                  .customSelect('SELECT feed_url, client_address, enabled, mode, '
                      'discovered_at FROM channel_signin_prefs')
                  .get();
              // The v32 client -> session rename is later than this
              // step: the table definition now says
              // `session_address`, and alterTable copies rows by the CURRENT
              // column names, so the old column is renamed first. The raw SELECT
              // above still reads the v30 name on purpose.
              await m.database.customStatement(
                  'ALTER TABLE channel_signin_prefs RENAME COLUMN client_address TO session_address');
              await m.alterTable(TableMigration(
                channelSigninPrefs,
                columnTransformer: {
                  channelSigninPrefs.decision: const CustomExpression<String>(
                      "CASE WHEN enabled = 1 THEN 'accepted' ELSE NULL END"),
                },
              ));
              final merged = <String, ChannelSigninPrefsCompanion>{};
              for (final r in old) {
                final rawUrl = r.read<String>('feed_url');
                final base = channelBaseOf(rawUrl) ?? rawUrl;
                final session = r.read<String>('client_address');
                final decision =
                    r.read<int>('enabled') == 1 ? 'accepted' : null;
                final key = '$base|$session';
                final prev = merged[key];
                if (prev == null ||
                    (prev.decision.value == null && decision != null)) {
                  merged[key] = ChannelSigninPrefsCompanion.insert(
                    feedUrl: base,
                    sessionAddress: session,
                    decision: Value(decision),
                    mode: Value(r.read<String>('mode')),
                    discoveredAt: r.read<int>('discovered_at'),
                  );
                }
              }
              await m.database
                  .customStatement('DELETE FROM channel_signin_prefs');
              for (final row in merged.values) {
                await into(channelSigninPrefs).insert(row);
              }
              debugPrint('AppDatabase: v31 — channel_signin_prefs: enabled → '
                  'decision, keyed on the channel base (${merged.length} rows kept)');
            }
            if (from < 32) {
              // A key is a SESSION. Every
              // per-user scope column `client_address` -> `session_address`, the
              // contacts' `clients` JSON -> `sessions`, and the raw-SQL
              // used_nft_avatars table. SQLite RENAME COLUMN keeps data, indices
              // and UNIQUE constraints; the rename is skipped where an earlier
              // step already rebuilt the table from the current definition
              // (v31's alterTable on channel_signin_prefs).
              Future<void> renameIfPresent(
                  String table, String oldName, String newName) async {
                final cols = await m.database
                    .customSelect('PRAGMA table_info($table)')
                    .get();
                if (cols.any((r) => r.read<String>('name') == oldName)) {
                  await m.database.customStatement(
                      'ALTER TABLE $table RENAME COLUMN $oldName TO $newName');
                }
              }
              for (final table in [
                'messages', 'contacts', 'conversations', 'settings', 'feed_servers',
                'rpc_servers', 'feed_lists', 'feed_cache', 'bookmarked_apps',
                'bookmarked_posts', 'activity_events', 'saved_stickers',
                'connected_sites', 'followed_accounts', 'muted_channels',
                'channel_signin_prefs', 'used_nft_avatars',
              ]) {
                await renameIfPresent(table, 'client_address', 'session_address');
              }
              await renameIfPresent('contacts', 'clients', 'sessions');
              // The keychain's default key label was 'client'; it is 'session' now.
              // (Guarded: a test DB opened at v30 may hold only one table.)
              final hasSites = (await m.database
                      .customSelect("SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'connected_sites'")
                      .get())
                  .isNotEmpty;
              if (hasSites) {
                await m.database.customStatement(
                    "UPDATE connected_sites SET key_label = 'session' WHERE key_label = 'client'");
              }
              debugPrint('AppDatabase: v32 — client -> session: scope columns, '
                  'contacts.sessions, used_nft_avatars, key labels');
            }
            if (from < 33) {
              // feed_cache.interactions: the last interactions
              // answer stored beside the cached document, so the cached paint
              // carries counts. Guarded twice: the table may be absent on a
              // file that never cached a feed (and in the ladder test), and the
              // column is already there when an earlier step created the table
              // from the current definition in this same run.
              final hasTable = (await m.database
                      .customSelect(
                          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'feed_cache'")
                      .get())
                  .isNotEmpty;
              if (hasTable &&
                  !await _hasColumn(m, 'feed_cache', 'interactions')) {
                await m.addColumn(feedCache, feedCache.interactions);
                debugPrint('AppDatabase: v33 — feed_cache.interactions added');
              }
            }
          });
        },
        beforeOpen: (details) async {
          // Enable foreign keys
          await customStatement('PRAGMA foreign_keys = ON');

          if (details.wasCreated) {
            debugPrint('AppDatabase: Database was created');
          }
        },
      );

  // ===========================================================================
  // MESSAGES QUERIES
  // ===========================================================================

  /// Get all messages for a conversation topic
  Future<List<Message>> getMessagesForConversation(
      String topic, String sessionAddr, String ownerInboxId) async {
    return (select(messages)
          ..where((m) =>
              m.conversationTopic.equals(topic) &
              m.sessionAddress.equals(sessionAddr) &
              m.ownerInboxId.equals(ownerInboxId))
          ..orderBy([(m) => OrderingTerm.asc(m.timestamp)]))
        .get();
  }

  /// Get messages after a specific timestamp
  Future<List<Message>> getMessagesAfterTimestamp(
      String topic, String sessionAddr, String ownerInboxId, int timestamp) async {
    return (select(messages)
          ..where((m) =>
              m.conversationTopic.equals(topic) &
              m.sessionAddress.equals(sessionAddr) &
              m.ownerInboxId.equals(ownerInboxId) &
              m.timestamp.isBiggerThanValue(timestamp))
          ..orderBy([(m) => OrderingTerm.asc(m.timestamp)]))
        .get();
  }

  /// Insert or replace a message
  /// Handles conflicts on (idXmtp, ownerInboxId) unique constraint
  Future<int> upsertMessage(MessagesCompanion message) async {
    return into(messages).insert(
      message,
      onConflict: DoUpdate(
        (old) => MessagesCompanion(
          xmtpMessageData: message.xmtpMessageData,
          timestamp: message.timestamp,
          conversationTopic: message.conversationTopic,
          senderInboxId: message.senderInboxId,
          typeId: message.typeId,
          isPending: message.isPending,
          sendFailed: message.sendFailed,
        ),
        target: [messages.idXmtp, messages.ownerInboxId],
      ),
    );
  }

  /// Delete messages for a conversation
  Future<int> deleteMessagesForConversation(
      String topic, String sessionAddr, String ownerInboxId) async {
    return (delete(messages)
          ..where((m) =>
              m.conversationTopic.equals(topic) &
              m.sessionAddress.equals(sessionAddr) &
              m.ownerInboxId.equals(ownerInboxId)))
        .go();
  }

  /// Re-point every stored message from [oldTopic] onto [newTopic] for the
  /// given session. Used to heal a stale DM topic onto the live one after a
  /// reset/duplicate-DM. Safe: the unique constraint is (idXmtp, ownerInboxId),
  /// independent of conversationTopic, so a topic rewrite can't collide.
  Future<int> migrateConversationTopic(String oldTopic, String newTopic,
      String sessionAddr, String ownerInboxId) async {
    return (update(messages)
          ..where((m) =>
              m.conversationTopic.equals(oldTopic) &
              m.sessionAddress.equals(sessionAddr) &
              m.ownerInboxId.equals(ownerInboxId)))
        .write(MessagesCompanion(conversationTopic: Value(newTopic)));
  }

  // ===========================================================================
  // UNREAD TRACKING
  // ===========================================================================

  /// Mark the latest message in a conversation as read.
  /// Returns the timestamp of the marked message, or null if no messages exist.
  Future<int?> markConversationAsRead(
      String topic, String sessionAddr, String ownerInboxId) async {
    // Find the latest message timestamp for this conversation
    final result = await customSelect(
      '''SELECT MAX(timestamp) as max_ts FROM messages
         WHERE conversation_topic = ? AND session_address = ? AND owner_inbox_id = ?
         AND send_failed = 0 AND is_pending = 0''',
      variables: [
        Variable.withString(topic),
        Variable.withString(sessionAddr),
        Variable.withString(ownerInboxId),
      ],
      readsFrom: {messages},
    ).getSingleOrNull();

    final maxTs = result?.read<int?>('max_ts');
    if (maxTs == null) return null;

    // Clear any previous isRead bookmark in this conversation
    await customStatement(
      '''UPDATE messages SET is_read = 0
         WHERE conversation_topic = ? AND session_address = ? AND owner_inbox_id = ? AND is_read = 1''',
      [topic, sessionAddr, ownerInboxId],
    );

    // Set isRead on the message with the latest timestamp (use subquery for single row)
    await customStatement(
      '''UPDATE messages SET is_read = 1
         WHERE id = (
           SELECT id FROM messages
           WHERE conversation_topic = ? AND session_address = ? AND owner_inbox_id = ?
           AND timestamp = ? AND send_failed = 0 AND is_pending = 0
           ORDER BY id DESC LIMIT 1
         )''',
      [topic, sessionAddr, ownerInboxId, maxTs],
    );

    return maxTs;
  }

  /// Get unread message counts for all conversations.
  /// Returns a map of conversationTopic → unread count.
  /// Only counts messages from others (not self) after the last isRead bookmark.
  Future<Map<String, int>> getUnreadCounts(
      String sessionAddr, String selfInboxId, String ownerInboxId) async {
    final results = await customSelect(
      '''SELECT m.conversation_topic, COUNT(*) as unread_count
         FROM messages m
         LEFT JOIN (
           SELECT conversation_topic, MAX(timestamp) as read_ts
           FROM messages
           WHERE session_address = ? AND owner_inbox_id = ? AND is_read = 1
           GROUP BY conversation_topic
         ) r ON m.conversation_topic = r.conversation_topic
         WHERE m.session_address = ?
           AND m.owner_inbox_id = ?
           AND m.send_failed = 0
           AND m.is_pending = 0
           AND m.sender_inbox_id != ?
           AND m.sender_inbox_id IS NOT NULL
           AND (r.read_ts IS NULL OR m.timestamp > r.read_ts)
         GROUP BY m.conversation_topic''',
      variables: [
        Variable.withString(sessionAddr),
        Variable.withString(ownerInboxId),
        Variable.withString(sessionAddr),
        Variable.withString(ownerInboxId),
        Variable.withString(selfInboxId),
      ],
      readsFrom: {messages},
    ).get();

    final counts = <String, int>{};
    for (final row in results) {
      counts[row.read<String>('conversation_topic')] =
          row.read<int>('unread_count');
    }
    return counts;
  }

  /// Get unread count for a single conversation.
  Future<int> getUnreadCountForConversation(
      String topic, String sessionAddr, String selfInboxId, String ownerInboxId) async {
    final result = await customSelect(
      '''SELECT COUNT(*) as unread_count
         FROM messages m
         LEFT JOIN (
           SELECT MAX(timestamp) as read_ts
           FROM messages
           WHERE conversation_topic = ? AND session_address = ? AND owner_inbox_id = ? AND is_read = 1
         ) r ON 1=1
         WHERE m.conversation_topic = ?
           AND m.session_address = ?
           AND m.owner_inbox_id = ?
           AND m.send_failed = 0
           AND m.is_pending = 0
           AND m.sender_inbox_id != ?
           AND m.sender_inbox_id IS NOT NULL
           AND (r.read_ts IS NULL OR m.timestamp > r.read_ts)''',
      variables: [
        Variable.withString(topic),
        Variable.withString(sessionAddr),
        Variable.withString(ownerInboxId),
        Variable.withString(topic),
        Variable.withString(sessionAddr),
        Variable.withString(ownerInboxId),
        Variable.withString(selfInboxId),
      ],
      readsFrom: {messages},
    ).getSingle();

    return result.read<int>('unread_count');
  }

  /// Get the isRead bookmark timestamp for a conversation.
  /// Returns the timestamp of the message marked as read, or null if none.
  Future<int?> getReadBookmarkTimestamp(
      String topic, String sessionAddr, String ownerInboxId) async {
    final result = await customSelect(
      '''SELECT timestamp FROM messages
         WHERE conversation_topic = ? AND session_address = ? AND owner_inbox_id = ? AND is_read = 1
         ORDER BY timestamp DESC LIMIT 1''',
      variables: [
        Variable.withString(topic),
        Variable.withString(sessionAddr),
        Variable.withString(ownerInboxId),
      ],
      readsFrom: {messages},
    ).getSingleOrNull();

    return result?.read<int?>('timestamp');
  }

  // ===========================================================================
  // CONTACTS QUERIES
  // ===========================================================================

  /// Get all contacts for a session
  Future<List<Contact>> getContactsForSession(String sessionAddr) async {
    return (select(contacts)
          ..where((c) => c.sessionAddress.equals(sessionAddr)))
        .get();
  }

  /// Get contact by publicos address
  Future<Contact?> getContactByPublicosAddress(
      String publicosAddress, String sessionAddr) async {
    return (select(contacts)
          ..where((c) =>
              c.publicosAddress.equals(publicosAddress) &
              c.sessionAddress.equals(sessionAddr))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Get a contact whose `registeredInboxIDs` JSON contains the given inbox ID.
  /// Uses a LIKE query on the JSON blob; expects inbox IDs to be stored as
  /// 64-char hex strings (canonical form). Returns null if no match.
  Future<Contact?> getContactByRegisteredInboxId(
      String inboxId, String sessionAddr) async {
    final result = await customSelect(
      '''SELECT * FROM contacts
         WHERE session_address = ?
           AND registered_inbox_i_ds LIKE ?
         LIMIT 1''',
      variables: [
        Variable.withString(sessionAddr),
        Variable.withString('%"$inboxId"%'),
      ],
      readsFrom: {contacts},
    ).getSingleOrNull();

    if (result == null) return null;
    return contacts.map(result.data);
  }

  /// Get a group-stub contact by its XMTP conversation topic. Returns null
  /// if no row (e.g. the stub hasn't been synced yet).
  Future<Contact?> getContactByTopic(
      String topic, String sessionAddr) async {
    return (select(contacts)
          ..where((c) =>
              c.xmtpConversationTopic.equals(topic) &
              c.sessionAddress.equals(sessionAddr))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Insert or replace a contact
  Future<int> upsertContact(ContactsCompanion contact) async {
    return into(contacts).insertOnConflictUpdate(contact);
  }

  /// Delete a contact
  Future<int> deleteContact(int id) async {
    return (delete(contacts)..where((c) => c.id.equals(id))).go();
  }

  // ===========================================================================
  // CONVERSATIONS QUERIES
  // ===========================================================================

  /// Get all conversations for a session.
  Future<List<Conversation>> getConversationsForSession(
      String sessionAddr, String ownerInboxId) async {
    return (select(conversations)
          ..where((c) =>
              c.sessionAddress.equals(sessionAddr) &
              c.ownerInboxId.equals(ownerInboxId)))
        .get();
  }

  /// Get a conversation by topic.
  Future<Conversation?> getConversationByTopic(
      String topic, String sessionAddr, String ownerInboxId) async {
    return (select(conversations)
          ..where((c) =>
              c.topic.equals(topic) &
              c.sessionAddress.equals(sessionAddr) &
              c.ownerInboxId.equals(ownerInboxId))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Get a DM conversation by peer inbox ID.
  Future<Conversation?> getConversationByPeerInboxId(
      String peerInboxId, String sessionAddr, String ownerInboxId) async {
    return (select(conversations)
          ..where((c) =>
              c.peerInboxId.equals(peerInboxId) &
              c.sessionAddress.equals(sessionAddr) &
              c.ownerInboxId.equals(ownerInboxId))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Insert or replace a conversation (keyed by topic + owner inbox ID).
  Future<void> upsertConversation(ConversationsCompanion conversation) async {
    await into(conversations).insertOnConflictUpdate(conversation);
  }

  /// Delete a conversation by topic.
  Future<int> deleteConversationByTopic(
      String topic, String sessionAddr, String ownerInboxId) async {
    return (delete(conversations)
          ..where((c) =>
              c.topic.equals(topic) &
              c.sessionAddress.equals(sessionAddr) &
              c.ownerInboxId.equals(ownerInboxId)))
        .go();
  }

  // ===========================================================================
  // SETTINGS QUERIES
  // ===========================================================================

  /// Get a setting by key
  Future<Setting?> getSetting(String key, String sessionAddr) async {
    return (select(settings)
          ..where(
              (s) => s.key.equals(key) & s.sessionAddress.equals(sessionAddr))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Get all settings for a session
  Future<List<Setting>> getSettingsForSession(String sessionAddr) async {
    return (select(settings)
          ..where((s) => s.sessionAddress.equals(sessionAddr)))
        .get();
  }

  /// Insert or replace a setting
  Future<int> upsertSetting(SettingsCompanion setting) async {
    return into(settings).insert(
      setting,
      onConflict: DoUpdate(
        (old) => SettingsCompanion(
          record: setting.record,
          updatedAt: setting.updatedAt,
        ),
        target: [settings.key, settings.sessionAddress],
      ),
    );
  }

  /// Delete a setting
  Future<int> deleteSetting(String key, String sessionAddr) async {
    return (delete(settings)
          ..where(
              (s) => s.key.equals(key) & s.sessionAddress.equals(sessionAddr)))
        .go();
  }

  // ===========================================================================
  // FEED SERVERS QUERIES
  // ===========================================================================

  /// Get all feed servers for a session
  Future<List<FeedServer>> getFeedServersForSession(String sessionAddr) async {
    return (select(feedServers)
          ..where((f) => f.sessionAddress.equals(sessionAddr)))
        .get();
  }

  /// Get default feed server
  Future<FeedServer?> getDefaultFeedServer(String sessionAddr) async {
    return (select(feedServers)
          ..where((f) =>
              f.sessionAddress.equals(sessionAddr) &
              f.isDefault.equals(true))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Insert or replace a feed server.
  ///
  /// Conflict target is the unique index, not the autoIncrement PK — see
  /// [upsertCachedFeed].
  Future<int> upsertFeedServer(FeedServersCompanion server) async {
    return into(feedServers).insert(
      server,
      onConflict: DoUpdate(
        (old) => server,
        target: [feedServers.feedServerAddress, feedServers.sessionAddress],
      ),
    );
  }

  /// Delete a feed server
  Future<int> deleteFeedServer(String address, String sessionAddr) async {
    return (delete(feedServers)
          ..where((f) =>
              f.feedServerAddress.equals(address) &
              f.sessionAddress.equals(sessionAddr)))
        .go();
  }

  // ===========================================================================
  // RPC SERVERS QUERIES
  // ===========================================================================

  /// Get all custom RPC servers for a session
  Future<List<RpcServer>> getRpcServersForSession(String sessionAddr) async {
    return (select(rpcServers)
          ..where((r) => r.sessionAddress.equals(sessionAddr)))
        .get();
  }

  /// Insert or update a custom RPC server.
  ///
  /// Conflict target is the unique index, not the autoIncrement PK — see
  /// [upsertCachedFeed].
  Future<int> upsertRpcServer(RpcServersCompanion server) async {
    return into(rpcServers).insert(
      server,
      onConflict: DoUpdate(
        (old) => server,
        target: [rpcServers.rpcUrl, rpcServers.sessionAddress],
      ),
    );
  }

  /// Delete a custom RPC server by ID and session address
  Future<int> deleteRpcServerById(int id, String sessionAddr) async {
    return (delete(rpcServers)
          ..where((r) =>
              r.id.equals(id) &
              r.sessionAddress.equals(sessionAddr)))
        .go();
  }

  // ===========================================================================
  // FEED LISTS QUERIES
  // ===========================================================================

  /// Get all feed lists for a session
  Future<List<FeedListData>> getListsForSession(String sessionAddr) async {
    return (select(feedLists)..where((l) => l.sessionAddress.equals(sessionAddr)))
        .get();
  }

  /// Insert a new feed list
  Future<int> insertList(FeedListsCompanion list) async {
    return into(feedLists).insert(list);
  }

  /// Update a feed list
  Future<bool> updateList(FeedListData list) async {
    return update(feedLists).replace(list);
  }

  /// Delete a feed list (cascade deletes list_feeds)
  /// Delete a list AND everything scoped to it, in one transaction.
  ///
  /// Belt AND braces. The `customConstraint('... REFERENCES feed_lists(id) ON
  /// DELETE CASCADE')` on the child tables IS live (verified: s15 rejects a
  /// follow pointing at a nonexistent list), so SQLite would cascade on its
  /// own — but only while `PRAGMA foreign_keys` is ON, which is set in
  /// `beforeOpen` and is therefore connection state, not a schema guarantee.
  ///
  /// Note the constraint is spelled with `customConstraint`, NOT the canonical
  /// `references(FeedLists, #id, onDelete: cascade)`. That form is silently
  /// DROPPED by drift_dev <=2.32.0 under analyzer >=10.2.0 — it warns "This
  /// parameter should be a simple class name" and emits no REFERENCES clause
  /// at all, so the cascade never fires and `deleteList` would
  /// quietly orphan `list_feeds` rows.
  /// Upstream fix is drift_dev 2.32.1, but taking it drags sqlite3 2.x -> 3.x
  /// and retires `sqlite3_flutter_libs`, so we use customConstraint instead.
  /// **Do not "tidy" these back to `.references()`.**
  ///
  /// Explicit deletion is also simply the deterministic thing: it does not
  /// depend on codegen resolving a symbol, nor on `PRAGMA foreign_keys` being
  /// on for the connection. Ordered children-then-parent, so it stays correct
  /// if the FKs ever do start generating (the cascade would just find nothing).
  Future<int> deleteList(int id) async {
    return transaction(() async {
      await (delete(listFeeds)..where((f) => f.listId.equals(id))).go();
      await (delete(followedAccounts)..where((r) => r.listId.equals(id))).go();
      await (delete(mutedChannels)..where((r) => r.listId.equals(id))).go();
      return (delete(feedLists)..where((l) => l.id.equals(id))).go();
    });
  }

  // ===========================================================================
  // LIST FEEDS QUERIES
  // ===========================================================================

  /// Get all feeds for a list
  Future<List<ListFeed>> getFeedsForList(int listId) async {
    return (select(listFeeds)..where((f) => f.listId.equals(listId))).get();
  }

  /// One-time re-key of `feed_lists.session_address` from an ACCOUNT address to
  /// a SESSION address.
  ///
  /// `FeedLists` was the lone table scoped by account while every other
  /// per-user table (`Settings`, `Messages`, `Conversations`, `BookmarkedPosts`)
  /// scoped by session. It is session-scoped now — but older rows still carry
  /// the account address, so without this every user's lists (including
  /// "Following" and their whole demo News list) would silently vanish the
  /// first time they opened the app on the new build.
  ///
  /// Idempotent: after the first run no row matches [fromAccount] any more.
  /// Runs at login, where both addresses are known — a Drift `onUpgrade` cannot
  /// do it, because at DB-open time we do not yet know who is signing in.
  Future<int> rekeyFeedListScope({
    required String fromAccount,
    required String toSession,
  }) async {
    if (fromAccount.toLowerCase() == toSession.toLowerCase()) return 0;
    return (update(feedLists)
          ..where((l) => l.sessionAddress.equals(fromAccount)))
        .write(FeedListsCompanion(sessionAddress: Value(toSession)));
  }

  /// Collapse same-name duplicate feed lists within one session scope, merging
  /// their feeds into a single keeper.
  ///
  /// **Why this exists.** `_ensureFollowing` (client + desktop) creates a
  /// "Following" list whenever the fetched list set contains none. When feed
  /// lists moved from account scope to session scope, any read that
  /// happened *before* [rekeyFeedListScope] had moved the legacy row would see
  /// zero lists and create a fresh, empty "Following" — and then the re-key
  /// would bring the real one across too. Result: two Following lists, one
  /// empty.
  ///
  /// Chasing the ordering is the wrong fix, because the same race can be lost by
  /// any future caller. Collapsing duplicates is idempotent and closes it
  /// permanently.
  ///
  /// **Non-destructive by construction:** the keeper is whichever duplicate has
  /// the MOST feeds, and every other duplicate's feeds are moved onto it before
  /// it is deleted (skipping URLs the keeper already holds, so the merge cannot
  /// introduce duplicate feeds). Nothing is dropped — an emptied husk is.
  Future<int> mergeDuplicateLists(String sessionAddress) async {
    final lists = await getListsForSession(sessionAddress);

    final byName = <String, List<FeedListData>>{};
    for (final l in lists) {
      byName.putIfAbsent(l.name, () => []).add(l);
    }

    var removed = 0;
    for (final group in byName.values) {
      if (group.length < 2) continue;

      final counts = <int, int>{};
      for (final l in group) {
        counts[l.id] = (await getFeedsForList(l.id)).length;
      }

      // Keeper = most feeds; ties break to the oldest (lowest id), so the
      // original list survives rather than the accident.
      final ordered = [...group]..sort((a, b) {
          final byCount = counts[b.id]!.compareTo(counts[a.id]!);
          return byCount != 0 ? byCount : a.id.compareTo(b.id);
        });
      final keeper = ordered.first;
      final keeperUrls =
          (await getFeedsForList(keeper.id)).map((f) => f.feedUrl).toSet();

      for (final dup in ordered.skip(1)) {
        for (final feed in await getFeedsForList(dup.id)) {
          if (keeperUrls.contains(feed.feedUrl)) continue; // already there
          await (update(listFeeds)..where((f) => f.id.equals(feed.id)))
              .write(ListFeedsCompanion(listId: Value(keeper.id)));
          keeperUrls.add(feed.feedUrl);
        }
        // Everything worth keeping has been moved; the rest cascades.
        await deleteList(dup.id);
        removed++;
      }
    }
    return removed;
  }

  // ── Feed cache (see [FeedCache]) ─────────────────

  /// Every cached row for the given feed URLs, in one query.
  ///
  /// Batched deliberately: a list load needs all of its feeds at once, and
  /// N round trips to SQLite on the way to painting the first frame is exactly
  /// the latency this cache exists to remove.
  Future<List<FeedCacheData>> getCachedFeeds(
    List<String> feedUrls,
    String sessionAddress,
  ) {
    if (feedUrls.isEmpty) return Future.value(const []);
    return (select(feedCache)
          ..where((f) =>
              f.feedUrl.isIn(feedUrls) & f.sessionAddress.equals(sessionAddress)))
        .get();
  }

  /// Insert-or-replace the cached response for one feed.
  ///
  /// The conflict target is the UNIQUE INDEX, not the primary key. `id` is
  /// autoIncrement and absent from the companion, so it can never collide —
  /// `insertOnConflictUpdate` (which targets the PK) would sail past the
  /// `DO UPDATE` branch and raise 2067 on `{feedUrl, sessionAddress}` for every
  /// write after the first. Same footgun as the sticker insert below.
  Future<void> upsertCachedFeed(FeedCacheCompanion row) async {
    await into(feedCache).insert(
      row,
      onConflict: DoUpdate(
        (old) => row,
        target: [feedCache.feedUrl, feedCache.sessionAddress],
      ),
    );
  }

  /// Refresh only the validators + timestamp after a `304 Not Modified`.
  ///
  /// A 304 means the body we hold is still current, so we must NOT rewrite it —
  /// but we DO advance `fetchedAt` (the row is proven fresh, and eviction keys
  /// off it) and take any updated `ETag` the server chose to send.
  Future<void> touchCachedFeed(
    String feedUrl,
    String sessionAddress, {
    String? etag,
    String? lastModified,
    String? interactions,
  }) async {
    await (update(feedCache)
          ..where((f) =>
              f.feedUrl.equals(feedUrl) & f.sessionAddress.equals(sessionAddress)))
        .write(FeedCacheCompanion(
      fetchedAt: Value(DateTime.now().millisecondsSinceEpoch),
      etag: etag == null ? const Value.absent() : Value(etag),
      lastModified:
          lastModified == null ? const Value.absent() : Value(lastModified),
      // The document is unchanged; its counts are not. A null answer keeps
      // the last one rather than erasing it.
      interactions:
          interactions == null ? const Value.absent() : Value(interactions),
    ));
  }

  /// Evict rows not fetched within [maxAge] (default 7 days).
  ///
  /// Nothing else prunes this table, and raw bodies run 50-500KB each — without
  /// this it grows with every feed the user has ever followed, forever. A feed
  /// evicted this way simply paints cold on its next open, which is the right
  /// trade: a week-stale body is not worth serving.
  Future<int> evictStaleFeedCache({
    Duration maxAge = const Duration(days: 7),
  }) async {
    final cutoff =
        DateTime.now().subtract(maxAge).millisecondsSinceEpoch;
    return (delete(feedCache)..where((f) => f.fetchedAt.isSmallerThanValue(cutoff)))
        .go();
  }

  /// Drop cached rows for feeds that are no longer in any list.
  ///
  /// The age sweep alone would keep a feed alive forever as long as it is
  /// refreshed, even after the user removed it from every list.
  Future<int> evictOrphanedFeedCache(String sessionAddress) async {
    final live = await (selectOnly(listFeeds, distinct: true)
          ..addColumns([listFeeds.feedUrl]))
        .map((r) => r.read(listFeeds.feedUrl)!)
        .get();
    return (delete(feedCache)
          ..where((f) =>
              f.sessionAddress.equals(sessionAddress) & f.feedUrl.isNotIn(live)))
        .go();
  }

  /// Insert a feed to a list
  Future<int> insertListFeed(ListFeedsCompanion feed) async {
    return into(listFeeds).insert(feed);
  }

  /// Delete a feed from a list
  Future<int> deleteListFeed(int id) async {
    return (delete(listFeeds)..where((f) => f.id.equals(id))).go();
  }

  /// Delete feeds by URL from a list
  Future<int> deleteListFeedByUrl(int listId, String feedUrl) async {
    return (delete(listFeeds)
          ..where((f) => f.listId.equals(listId) & f.feedUrl.equals(feedUrl)))
        .go();
  }

  // ===========================================================================
  // ATTACHMENT CACHE QUERIES
  // ===========================================================================

  /// Get a cached attachment by digest
  Future<AttachmentCacheData?> getCachedAttachment(String digest) async {
    return (select(attachmentCache)
          ..where((a) => a.contentDigest.equals(digest))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Insert or update a cached attachment
  Future<int> upsertCachedAttachment(
      AttachmentCacheCompanion attachment) async {
    return into(attachmentCache).insertOnConflictUpdate(attachment);
  }

  /// Update last accessed time
  Future<int> updateAttachmentLastAccessed(String digest, int timestamp) async {
    return (update(attachmentCache)
          ..where((a) => a.contentDigest.equals(digest)))
        .write(AttachmentCacheCompanion(lastAccessed: Value(timestamp)));
  }

  /// Get total cache size
  Future<int> getCacheTotalSize() async {
    final result = await customSelect(
      'SELECT SUM(size) as total FROM attachment_cache',
    ).getSingle();
    return result.read<int?>('total') ?? 0;
  }

  /// Get cache entries ordered by last accessed (LRU)
  Future<List<AttachmentCacheData>> getCacheEntriesLRU() async {
    return (select(attachmentCache)
          ..orderBy([(a) => OrderingTerm.asc(a.lastAccessed)]))
        .get();
  }

  /// Delete a cached attachment
  Future<int> deleteCachedAttachment(String digest) async {
    return (delete(attachmentCache)
          ..where((a) => a.contentDigest.equals(digest)))
        .go();
  }

  // ---------------------------------------------------------------------------
  // Saved stickers — the user's sticker library. See [SavedStickers].
  // ---------------------------------------------------------------------------

  /// Every saved sticker for [sessionAddress], newest first, **without bytes**.
  /// Backs the gallery grid; see [SavedStickerMeta] for why bytes are excluded.
  Future<List<SavedStickerMeta>> getSavedStickerMeta(
      String sessionAddress) async {
    final query = selectOnly(savedStickers)
      ..addColumns([
        savedStickers.id,
        savedStickers.digest,
        savedStickers.filename,
        savedStickers.mimeType,
        savedStickers.size,
        savedStickers.savedAt,
      ])
      ..where(savedStickers.sessionAddress.equals(sessionAddress))
      ..orderBy([OrderingTerm.desc(savedStickers.savedAt)]);

    final rows = await query.get();
    return rows
        .map((r) => SavedStickerMeta(
              id: r.read(savedStickers.id)!,
              digest: r.read(savedStickers.digest)!,
              filename: r.read(savedStickers.filename)!,
              mimeType: r.read(savedStickers.mimeType)!,
              size: r.read(savedStickers.size)!,
              savedAt: r.read(savedStickers.savedAt)!,
            ))
        .toList();
  }

  /// The bytes of one saved sticker. Null if the row is gone (deleted between
  /// the grid's meta query and the tile's byte fetch).
  Future<Uint8List?> getSavedStickerData(int id) async {
    final row = await (select(savedStickers)
          ..where((s) => s.id.equals(id))
          ..limit(1))
        .getSingleOrNull();
    return row?.data;
  }

  /// Insert a sticker, **ignoring** a `{digest, sessionAddress}` collision.
  /// Returns the new row, or **null** when the sticker was already saved.
  ///
  /// `insertOrIgnore` (not `insertOnConflictUpdate`) because the conflict we
  /// care about is on the unique index, not the autoIncrement primary key —
  /// `insertOnConflictUpdate` targets the PK and would throw on a re-save.
  ///
  /// `insertReturningOrNull` (not plain `insert`) because `insert` forwards
  /// sqlite's `last_insert_rowid()`, which on an *ignored* insert still holds
  /// the previous successful insert's id — never 0. Drift documents the return
  /// value as "inaccurate" for exactly this case. The `RETURNING` clause is the
  /// only way to learn whether a row actually landed.
  Future<SavedStickerRow?> insertSavedSticker(
      SavedStickersCompanion sticker) async {
    return into(savedStickers)
        .insertReturningOrNull(sticker, mode: InsertMode.insertOrIgnore);
  }

  /// Whether this exact sticker is already saved by this session.
  Future<SavedStickerRow?> getSavedStickerByDigest(
      String digest, String sessionAddress) async {
    return (select(savedStickers)
          ..where((s) =>
              s.digest.equals(digest) & s.sessionAddress.equals(sessionAddress))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Remove one sticker from the library.
  Future<int> deleteSavedSticker(int id) async {
    return (delete(savedStickers)..where((s) => s.id.equals(id))).go();
  }

  // ===========================================================================
  // CHANNEL SIGN-IN PREFS (per-channel envelope consent) — see [ChannelSigninPrefs]
  // ===========================================================================

  /// Record a server signal for [channelUrl] (a channel BASE url). First
  /// sight creates the row with `decision: null` (the row's existence is what
  /// makes the key icon appear); later sights only refresh [mode], NEVER
  /// touching the user's answer.
  Future<void> recordChannelSigninSignal({
    required String channelUrl,
    required String sessionAddress,
    required String mode,
  }) async {
    await into(channelSigninPrefs).insert(
      ChannelSigninPrefsCompanion.insert(
        feedUrl: channelUrl,
        sessionAddress: sessionAddress,
        mode: Value(mode),
        discoveredAt: DateTime.now().millisecondsSinceEpoch,
      ),
      onConflict: DoUpdate(
        (old) => ChannelSigninPrefsCompanion(mode: Value(mode)),
        target: [channelSigninPrefs.feedUrl, channelSigninPrefs.sessionAddress],
      ),
    );
  }

  /// A served 200 with no signal: the channel no longer accepts sign-in. The
  /// row — and the answer with it — goes. Returns rows deleted (0 is fine).
  Future<int> deleteChannelSigninPref(
      String channelUrl, String sessionAddress) async {
    return (delete(channelSigninPrefs)
          ..where((p) =>
              p.feedUrl.equals(channelUrl) &
              p.sessionAddress.equals(sessionAddress)))
        .go();
  }

  /// The row for one channel (BASE url), or null when its server has never
  /// signalled sign-in (which the UI renders as "no key icon").
  Future<ChannelSigninPref?> getChannelSigninPref(
      String channelUrl, String sessionAddress) async {
    return (select(channelSigninPrefs)
          ..where((p) =>
              p.feedUrl.equals(channelUrl) &
              p.sessionAddress.equals(sessionAddress))
          ..limit(1))
        .getSingleOrNull();
  }

  /// The user's answer for one channel: `accepted` / `denied` / null (Forget).
  /// Returns the number of rows touched — 0 means the channel never signalled,
  /// and the caller should treat that as a bug (no menu should exist there).
  Future<int> setChannelSigninDecision(
      String channelUrl, String sessionAddress, String? decision) async {
    return (update(channelSigninPrefs)
          ..where((p) =>
              p.feedUrl.equals(channelUrl) &
              p.sessionAddress.equals(sessionAddress)))
        .write(ChannelSigninPrefsCompanion(decision: Value(decision)));
  }

  // ===========================================================================
  // CONNECTED SITES (browser connect grants) — see [ConnectedSites]
  // ===========================================================================

  /// Record (or refresh) a connect grant for [origin] as the identity [eoa],
  /// scoped to the PublicOS account [session]. The row's PRESENCE is the
  /// permission; a re-grant of the same (origin, session, eoa) triple is an
  /// upsert that bumps [lastUsedAt] and re-carries the (display-only) label.
  ///
  /// [session] and [eoa] are lowercased here on the way IN, so [hasGrant] can be
  /// a plain `.equals()` match (drift has no `.equalsLower()`). Callers may pass
  /// mixed case; this is the single normalisation point.
  ///
  /// Conflict target is the UNIQUE INDEX, not the autoIncrement PK — an
  /// `onConflict` that targets the implicit rowid throws SQLite 2067 on the
  /// second write (see gotchas: `insertOnConflictUpdate` on autoIncrement +
  /// uniqueKeys). Same shape as [upsertCachedFeed].
  Future<void> grantSite({
    required String origin,
    required String session,
    required String eoa,
    String? keyLabel,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final row = ConnectedSitesCompanion.insert(
      origin: origin,
      sessionAddress: session.toLowerCase(),
      grantedEoa: eoa.toLowerCase(),
      keyLabel: Value(keyLabel),
      grantedAt: now,
      lastUsedAt: now,
    );
    await into(connectedSites).insert(
      row,
      onConflict: DoUpdate(
        (old) => ConnectedSitesCompanion(
          keyLabel: Value(keyLabel),
          lastUsedAt: Value(now),
        ),
        target: [
          connectedSites.origin,
          connectedSites.sessionAddress,
          connectedSites.grantedEoa,
        ],
      ),
    );
  }

  /// True iff [origin] has been granted the exact identity [eoa] under account
  /// [session]. Asks about the key that is ABOUT TO BE HANDED OVER — never merely
  /// "is this origin known". That single predicate is the whole per-key model:
  /// a key the site has not been granted is a key it does not get.
  Future<bool> hasGrant({
    required String origin,
    required String session,
    required String eoa,
  }) async {
    final row = await (select(connectedSites)
          ..where((r) =>
              r.origin.equals(origin) &
              r.sessionAddress.equals(session.toLowerCase()) &
              r.grantedEoa.equals(eoa.toLowerCase())))
        .getSingleOrNull();
    return row != null;
  }

  /// Bump [lastUsedAt] for an existing grant (sort key for a future "connected
  /// sites" list). No-op if the grant does not exist.
  Future<void> touchGrant({
    required String origin,
    required String session,
    required String eoa,
  }) async {
    await (update(connectedSites)
          ..where((r) =>
              r.origin.equals(origin) &
              r.sessionAddress.equals(session.toLowerCase()) &
              r.grantedEoa.equals(eoa.toLowerCase())))
        .write(ConnectedSitesCompanion(
      lastUsedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  /// Revoke a single grant. Drops exactly the (origin, session, eoa) row — a
  /// site connected under two keys keeps its other grant. Returns rows deleted.
  Future<int> revokeSite({
    required String origin,
    required String session,
    required String eoa,
  }) async {
    return (delete(connectedSites)
          ..where((r) =>
              r.origin.equals(origin) &
              r.sessionAddress.equals(session.toLowerCase()) &
              r.grantedEoa.equals(eoa.toLowerCase())))
        .go();
  }

  /// Every account [origin] may see under [session], lowercased.
  ///
  /// The site's permission IS this set. The table
  /// always allowed it — the unique key is `{origin, session, eoa}`, so N rows
  /// per origin has been legal since the table existed; nothing above it ever
  /// asked for more than one.
  ///
  /// Deliberately unordered: `accounts[0]` is decided by the preferred-key rule
  /// in `ConnectGate.orderAccounts`, NOT by this table. Ordering here by
  /// [ConnectedSites.lastUsedAt] would be worse than arbitrary — `touchGrant`
  /// fires on every `eth_accounts` read, so that column means "when the site
  /// last looked" and is identical across all of that site's keys.
  Future<List<String>> listGrantsForOrigin({
    required String origin,
    required String session,
  }) async {
    final rows = await (select(connectedSites)
          ..where((r) =>
              r.origin.equals(origin) &
              r.sessionAddress.equals(session.toLowerCase())))
        .get();
    return rows.map((r) => r.grantedEoa).toList();
  }

  /// Every grant held by account [session], newest use first — the backing query
  /// for the future "Connected sites" list in the keychain sheet.
  Future<List<ConnectedSite>> listGrants(String session) async {
    return (select(connectedSites)
          ..where((r) => r.sessionAddress.equals(session.toLowerCase()))
          ..orderBy([(r) => OrderingTerm.desc(r.lastUsedAt)]))
        .get();
  }

  /// Make [eoa] the ACTIVE key for [origin] under [session] — the address the
  /// site sees first (`accounts[0]`), overriding the global preferred key for
  /// this site only.
  ///
  /// The flag lives on the grant row, so the key must already be granted
  /// (visible): a choice naming an ungranted key is a no-op (0 rows written)
  /// rather than a dangling pointer. Clears the flag on the siblings first, so
  /// at most one row per (origin, session) is active.
  Future<void> setSiteActiveKey({
    required String origin,
    required String session,
    required String eoa,
  }) async {
    await transaction(() async {
      await clearSiteActiveKey(origin: origin, session: session);
      await (update(connectedSites)
            ..where((r) =>
                r.origin.equals(origin) &
                r.sessionAddress.equals(session.toLowerCase()) &
                r.grantedEoa.equals(eoa.toLowerCase())))
          .write(const ConnectedSitesCompanion(activeKey: Value(true)));
    });
  }

  /// Drop [origin]'s active-key choice under [session]; the site falls back to
  /// the global preferred key. Grants are untouched.
  Future<void> clearSiteActiveKey({
    required String origin,
    required String session,
  }) async {
    await (update(connectedSites)
          ..where((r) =>
              r.origin.equals(origin) &
              r.sessionAddress.equals(session.toLowerCase())))
        .write(const ConnectedSitesCompanion(activeKey: Value(false)));
  }

  /// The active key [origin] chose under [session], lowercased — or null when
  /// the site has no choice of its own (→ global preferred key).
  Future<String?> siteActiveKey({
    required String origin,
    required String session,
  }) async {
    final row = await (select(connectedSites)
          ..where((r) =>
              r.origin.equals(origin) &
              r.sessionAddress.equals(session.toLowerCase()) &
              r.activeKey.equals(true)))
        .getSingleOrNull();
    return row?.grantedEoa;
  }

  // ===========================================================================
  // ACCOUNT-BASED FOLLOW QUERIES (see [FollowedAccounts], [MutedChannels])
  // ===========================================================================
  //
  // [accountAddress]/[session] are stored VERBATIM (eip55With0x) — NOT
  // lowercased like [ConnectedSites]. These join to [Contacts.publicosAddress]
  // by a case-sensitive `.equals()`, and both come from the same producer
  // (`PublicOS.sessionBlockchainAddress` / `EthereumAddress.eip55With0x`), so the
  // casing already agrees. Lowercasing here would break that join.
  //
  // Conflict target on every upsert is the UNIQUE INDEX, never the
  // autoIncrement PK — targeting the implicit rowid throws SQLite 2067 on the
  // SECOND write (survives a happy-path smoke test). Same shape as [grantSite].

  /// Follow [account] as [session]. Idempotent: re-following an account already
  /// followed is a no-op that keeps the ORIGINAL [FollowedAccounts.followedAt]
  /// (you followed them when you followed them; a second tap is not new).
  Future<void> followAccount({
    required String session,
    required String account,
    required int listId,
  }) async {
    // `insertOrIgnore` (the house idiom — see [insertSavedSticker]): on a
    // `{sessionAddress, accountAddress, listId}` unique-index collision the
    // second follow is ignored and the original `followedAt` survives. NOT
    // `DoUpdate` with an empty companion — that emits `... DO UPDATE SET` with
    // no assignments, a SQL syntax error SQLite raises at prepare time on EVERY
    // insert (the whole statement compiles up front), so even the first follow
    // would throw.
    await into(followedAccounts).insert(
      FollowedAccountsCompanion.insert(
        sessionAddress: session,
        accountAddress: account,
        listId: listId,
        followedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// Unfollow [account], and drop every mute [session] held inside it, in one
  /// transaction so a crash can't strand the mutes without their follow.
  ///
  /// The mutes go with the follow BY DESIGN: a mute is a statement about a
  /// channel of an account you follow, so it has no meaning once you don't —
  /// and keeping them would make a re-follow silently arrive pre-muted. The
  /// contact row is deliberately NOT touched (it isn't follow-owned; browsing a
  /// profile creates it), and any single-feed follow of one of this account's
  /// channels lives in `list_feeds` and survives untouched.
  /// Scoped to [listId]: unfollowing an account in one list leaves it followed
  /// in every other list, and only THAT list's mutes are dropped.
  Future<void> unfollowAccount({
    required String session,
    required String account,
    required int listId,
  }) async {
    await transaction(() async {
      await (delete(followedAccounts)
            ..where((r) =>
                r.sessionAddress.equals(session) &
                r.accountAddress.equals(account) &
                r.listId.equals(listId)))
          .go();
      await (delete(mutedChannels)
            ..where((r) =>
                r.sessionAddress.equals(session) &
                r.accountAddress.equals(account) &
                r.listId.equals(listId)))
          .go();
    });
  }

  /// True iff [session] follows [account].
  ///
  /// [listId] null (the default) means **any list** — that is the profile
  /// Follow button's semantics: "following" iff the ACCOUNT ITSELF sits in at
  /// least one list, reverting to not-following only when it is in zero.
  /// Pass a [listId] for the per-list membership check the add-to-list sheet
  /// needs to pre-check its rows.
  Future<bool> isFollowingAccount({
    required String session,
    required String account,
    int? listId,
  }) async {
    final row = await (select(followedAccounts)
          ..where((r) {
            final base = r.sessionAddress.equals(session) &
                r.accountAddress.equals(account);
            return listId == null ? base : base & r.listId.equals(listId);
          })
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  /// Every list [account] is followed in, for [session]. Backs the add-to-list
  /// sheet's pre-checked rows (OQ3: the sheet doubles as the "where is this
  /// followed" manager).
  Future<Set<int>> listsContainingAccount({
    required String session,
    required String account,
  }) async {
    final rows = await (select(followedAccounts)
          ..where((r) =>
              r.sessionAddress.equals(session) &
              r.accountAddress.equals(account)))
        .get();
    return rows.map((r) => r.listId).toSet();
  }

  /// Every account [session] follows IN [listId], newest follow first.
  Future<List<FollowedAccount>> listFollowedAccounts({
    required String session,
    required int listId,
  }) async {
    return (select(followedAccounts)
          ..where((r) =>
              r.sessionAddress.equals(session) & r.listId.equals(listId))
          ..orderBy([(r) => OrderingTerm.desc(r.followedAt)]))
        .get();
  }

  /// Mute one channel (by url) inside a followed account. Idempotent via
  /// `insertOrIgnore` — same rule as [followAccount] (re-mute keeps the original
  /// row; an empty-companion `DoUpdate` would be a `DO UPDATE SET`-with-nothing
  /// syntax error that throws on the first mute).
  Future<void> muteChannel({
    required String session,
    required String account,
    required int listId,
    required String recordKey,
  }) async {
    await into(mutedChannels).insert(
      MutedChannelsCompanion.insert(
        sessionAddress: session,
        accountAddress: account,
        listId: listId,
        recordKey: recordKey,
        mutedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// Unmute one channel in one list. Returns rows deleted (0 if it wasn't
  /// muted there).
  Future<int> unmuteChannel({
    required String session,
    required String account,
    required int listId,
    required String recordKey,
  }) async {
    return (delete(mutedChannels)
          ..where((r) =>
              r.sessionAddress.equals(session) &
              r.accountAddress.equals(account) &
              r.listId.equals(listId) &
              r.recordKey.equals(recordKey)))
        .go();
  }

  /// Every mute [session] holds IN [listId], as `accountAddress -> {recordKey}`.
  /// ONE query for the whole read path, instead of a per-followed-account round
  /// trip.
  Future<Map<String, Set<String>>> allMutedKeys({
    required String session,
    required int listId,
  }) async {
    final rows = await (select(mutedChannels)
          ..where((r) =>
              r.sessionAddress.equals(session) & r.listId.equals(listId)))
        .get();
    final out = <String, Set<String>>{};
    for (final r in rows) {
      (out[r.accountAddress] ??= <String>{}).add(r.recordKey);
    }
    return out;
  }

  /// Delete old cache entries
  Future<int> deleteOldCacheEntries(int cutoffTimestamp) async {
    return (delete(attachmentCache)
          ..where((a) => a.cachedAt.isSmallerThanValue(cutoffTimestamp)))
        .go();
  }

  /// Clear all cache
  Future<int> clearAttachmentCache() async {
    return delete(attachmentCache).go();
  }

  // ===========================================================================
  // BOOKMARKED APPS QUERIES
  // ===========================================================================

  /// Get all bookmarked apps for a session
  Future<List<BookmarkedApp>> getBookmarkedAppsForSession(
      String sessionAddr) async {
    return (select(bookmarkedApps)
          ..where((b) => b.sessionAddress.equals(sessionAddr))
          ..orderBy([(b) => OrderingTerm.desc(b.bookmarkedAt)]))
        .get();
  }

  /// Get bookmarked apps by owner
  Future<List<BookmarkedApp>> getBookmarkedAppsByOwner(
      String ownerAddr, String sessionAddr) async {
    return (select(bookmarkedApps)
          ..where((b) =>
              b.ownerAddress.equals(ownerAddr) &
              b.sessionAddress.equals(sessionAddr))
          ..orderBy([(b) => OrderingTerm.desc(b.bookmarkedAt)]))
        .get();
  }

  /// Get a specific bookmarked app
  Future<BookmarkedApp?> getBookmarkedApp(
      String appName, String ownerAddr, String sessionAddr) async {
    return (select(bookmarkedApps)
          ..where((b) =>
              b.appName.equals(appName) &
              b.ownerAddress.equals(ownerAddr) &
              b.sessionAddress.equals(sessionAddr))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Insert or replace a bookmarked app
  Future<int> upsertBookmarkedApp(BookmarkedAppsCompanion app) async {
    return into(bookmarkedApps).insert(
      app,
      onConflict: DoUpdate(
        (old) => app,
        target: [bookmarkedApps.appName, bookmarkedApps.ownerAddress, bookmarkedApps.sessionAddress],
      ),
    );
  }

  /// Delete a bookmarked app
  Future<int> deleteBookmarkedApp(
      String appName, String ownerAddr, String sessionAddr) async {
    return (delete(bookmarkedApps)
          ..where((b) =>
              b.appName.equals(appName) &
              b.ownerAddress.equals(ownerAddr) &
              b.sessionAddress.equals(sessionAddr)))
        .go();
  }

  /// Get bookmarked apps that need refreshing (nextUpdate is null or in the past)
  Future<List<BookmarkedApp>> getAppsNeedingUpdate(
      String sessionAddr, int currentTimeMs) async {
    return (select(bookmarkedApps)
          ..where((b) =>
              b.sessionAddress.equals(sessionAddr) &
              (b.nextUpdate.isNull() | b.nextUpdate.isSmallerThanValue(currentTimeMs))))
        .get();
  }

  /// Update nextUpdate timestamp for a bookmarked app
  Future<int> updateAppNextUpdate(
      String appName, String ownerAddr, String sessionAddr, int nextUpdateMs) async {
    return (update(bookmarkedApps)
          ..where((b) =>
              b.appName.equals(appName) &
              b.ownerAddress.equals(ownerAddr) &
              b.sessionAddress.equals(sessionAddr)))
        .write(BookmarkedAppsCompanion(nextUpdate: Value(nextUpdateMs)));
  }

  // ===========================================================================
  // EXTENDED CONTACTS QUERIES
  // ===========================================================================

  /// Get all contacts for a session, ordered by display name.
  Future<List<Contact>> getStoredContacts(String sessionAddr) async {
    return (select(contacts)
          ..where((c) => c.sessionAddress.equals(sessionAddr))
          ..orderBy([(c) => OrderingTerm.asc(c.displayName)]))
        .get();
  }

  /// Search for a contact by display name, publicos display name, publicos
  /// address, any session address, any registered inbox ID, or the XMTP
  /// conversation topic (for group stubs). Mirrors the old catch-all lookup.
  Future<Contact?> searchContact(String searchString, String sessionAddr) async {
    final result = await customSelect(
      '''SELECT * FROM contacts
         WHERE (publicos_display_name = ?
            OR publicos_address = ? COLLATE NOCASE
            OR display_name = ?
            OR sessions LIKE ?
            OR registered_inbox_i_ds LIKE ?
            OR xmtp_conversation_topic = ?)
           AND session_address = ?
         LIMIT 1''',
      variables: [
        Variable.withString(searchString),
        Variable.withString(searchString),
        Variable.withString(searchString),
        Variable.withString('%"$searchString"%'),
        Variable.withString('%"$searchString"%'),
        Variable.withString(searchString),
        Variable.withString(sessionAddr),
      ],
      readsFrom: {contacts},
    ).getSingleOrNull();

    if (result == null) return null;
    return contacts.map(result.data);
  }

  /// Partial (substring) search over the names we store locally.
  /// [searchContact] above is exact-match on every
  /// name column, so a contact resolved as `pedroLopez.eth` only ever appears
  /// once the user typed all of it. This one backs the Messages/contacts
  /// search box, where typing `pedro` must find them.
  ///
  /// Names only (display name + PublicOS display name) — addresses, inbox IDs
  /// and topics stay exact in [searchContact], since a substring of a hex
  /// string is not a meaningful query.
  Future<List<Contact>> searchContactsLike(
    String query,
    String sessionAddr, {
    int limit = 20,
  }) async {
    final like = '%$query%';
    final result = await customSelect(
      '''SELECT * FROM contacts
         WHERE (display_name LIKE ? OR publicos_display_name LIKE ?)
           AND session_address = ?
         ORDER BY
           CASE
             WHEN LOWER(COALESCE(publicos_display_name, display_name)) = LOWER(?) THEN 0
             WHEN LOWER(COALESCE(publicos_display_name, display_name)) LIKE LOWER(?) THEN 1
             ELSE 2
           END,
           display_name ASC
         LIMIT ?''',
      variables: [
        Variable.withString(like),
        Variable.withString(like),
        Variable.withString(sessionAddr),
        Variable.withString(query),
        Variable.withString('$query%'),
        Variable.withInt(limit),
      ],
      readsFrom: {contacts},
    ).get();
    return result.map((row) => contacts.map(row.data)).toList();
  }

  /// TEMPORARY — delete this method and its call in `PublicOS.init` once
  /// existing installs have run it once.
  ///
  /// Rewrites the legacy `'unknown'` inbox label that non-PublicOS stubs were
  /// saved with to the empty string they now carry, so old contacts stop
  /// showing a chat tab literally named "unknown".
  ///
  /// Scoped to contacts with **no PublicOS account**: the inbox-label charset
  /// allows the word `unknown`, so a real account could have registered it on
  /// purpose and must not be touched.
  Future<int> scrubLegacyUnknownInboxLabels() async {
    return customUpdate(
      '''UPDATE contacts
            SET registered_inbox_i_ds =
                REPLACE(registered_inbox_i_ds, '"label":"unknown"', '"label":""')
          WHERE (publicos_address IS NULL OR publicos_address = '')
            AND registered_inbox_i_ds LIKE '%"label":"unknown"%' ''',
      updates: {contacts},
    );
  }

  /// Get support contacts for a session.
  Future<List<Contact>> getSupportContacts(String sessionAddr) async {
    return (select(contacts)
          ..where((c) =>
              c.isSupport.equals(true) & c.sessionAddress.equals(sessionAddr))
          ..orderBy([(c) => OrderingTerm.asc(c.displayName)]))
        .get();
  }

  /// Delete contact by publicos address.
  Future<int> deleteContactByAddress(
      String sessionAddr, String publicosAddress) async {
    return (delete(contacts)
          ..where((c) =>
              c.sessionAddress.equals(sessionAddr) &
              c.publicosAddress.equals(publicosAddress)))
        .go();
  }

  /// Upsert a contact. Dedup order:
  ///   1. publicosAddress (people with on-chain accounts)
  ///   2. any registered inbox ID LIKE match (XMTP-only people)
  ///   3. xmtpConversationTopic (group-chat stubs)
  Future<void> saveContactRaw(Map<String, dynamic> values) async {
    final publicosAddress = values['publicosAddress'] as String?;
    final registeredInboxIDs = values['registeredInboxIDs'] as String?;
    final xmtpConversationTopic = values['xmtpConversationTopic'] as String?;
    final sessionAddress = values['sessionAddress'] as String;

    Log.d(_tag, '[SAVE_CONTACT] displayName=${values['displayName']} addr=$publicosAddress topic=${xmtpConversationTopic ?? "-"}');

    Contact? existing;

    // 1. Match by PublicOS address (primary identity)
    if (publicosAddress != null) {
      existing = await (select(contacts)
            ..where((c) =>
                c.sessionAddress.equals(sessionAddress) &
                c.publicosAddress.equals(publicosAddress))
            ..limit(1))
          .getSingleOrNull();
    }

    // 2. Fallback: match by any registered inbox ID (XMTP-only contacts).
    //    Picks the first inbox ID from the JSON and LIKE-matches.
    if (existing == null && registeredInboxIDs != null && registeredInboxIDs.isNotEmpty) {
      final first = _firstInboxIdFromJson(registeredInboxIDs);
      if (first != null) {
        final result = await customSelect(
          '''SELECT * FROM contacts
             WHERE session_address = ?
               AND registered_inbox_i_ds LIKE ?
             LIMIT 1''',
          variables: [
            Variable.withString(sessionAddress),
            Variable.withString('%"$first"%'),
          ],
          readsFrom: {contacts},
        ).getSingleOrNull();
        if (result != null) existing = contacts.map(result.data);
      }
    }

    // 3. Fallback: match by conversation topic (group-chat stubs).
    if (existing == null && xmtpConversationTopic != null) {
      existing = await (select(contacts)
            ..where((c) =>
                c.sessionAddress.equals(sessionAddress) &
                c.xmtpConversationTopic.equals(xmtpConversationTopic))
            ..limit(1))
          .getSingleOrNull();
    }

    final companion = ContactsCompanion(
      publicosDisplayName: Value(values['publicosDisplayName'] as String?),
      publicosAddress: Value(publicosAddress),
      displayName: Value(values['displayName'] as String),
      isOrgAccount: Value((values['isOrgAccount'] as bool?) ?? false),
      sessions: Value(values['sessions'] as String?),
      records: Value(values['records'] as String?),
      registeredInboxIDs: Value(registeredInboxIDs),
      orgMembers: Value(values['orgMembers'] as String?),
      orgMemberCount: Value(values['orgMemberCount'] as int?),
      isBlocked: Value((values['isBlocked'] as bool?) ?? false),
      isSupport: Value((values['isSupport'] as bool?) ?? false),
      createdBy: Value(values['createdBy'] as String?),
      // null = "unknown, don't clobber" — founderAddress is immutable once
      // set; only an org fetch carries it, partial-contact save paths must
      // not wipe a cached value (same guard as isCitizen below).
      founderAddress: values['founderAddress'] == null
          ? const Value.absent()
          : Value(values['founderAddress'] as String?),
      // null = "unknown, don't clobber" — createdAt is the account creation
      // block timestamp, immutable once set. Most saveContact callers don't
      // carry it (fetchContact, group stubs, NFT-verdict re-saves), so an
      // unguarded Value(null) would wipe the cached value every time the
      // contact is touched — exactly the "Joined …" flicker the user saw
      // on second visit. Only the browser's `_withCreatedAt` enrichment
      // carries a non-null value, and that's the only path that should
      // write the column.
      createdAt: values['createdAt'] == null
          ? const Value.absent()
          : Value(values['createdAt'] as String?),
      updatedAt: Value(values['updatedAt'] as int),
      sessionAddress: Value(sessionAddress),
      xmtpConversationTopic: Value(xmtpConversationTopic),
      // null = "unknown, don't clobber" — only an explicit true/false from
      // the profile-view enrichment overwrites a cached citizenship value.
      // Most saveContact callers (chain re-fetch, contact resolution) carry
      // a null here and must not wipe an enriched flag.
      isCitizen: values['isCitizen'] == null
          ? const Value.absent()
          : Value(values['isCitizen'] as bool?),
      // null = "unknown, don't clobber" — same guard as isCitizen. Only an
      // explicit value from icon/profile enrichment overwrites a cached flag.
      isPublicOrg: values['isPublicOrg'] == null
          ? const Value.absent()
          : Value(values['isPublicOrg'] as bool?),
      verifiedNftAvatar: values['verifiedNftAvatar'] == null
          ? const Value.absent()
          : Value(values['verifiedNftAvatar'] as String?),
      // null = "unknown, don't clobber" — same guard as verifiedNftAvatar.
      verifiedNftBanner: values['verifiedNftBanner'] == null
          ? const Value.absent()
          : Value(values['verifiedNftBanner'] as String?),
      // null = "don't clobber" — a user-set bookmark must survive chain
      // re-fetches / partial saves that carry no value (same guard as isCitizen).
      bookmarked: values['bookmarked'] == null
          ? const Value.absent()
          : Value(values['bookmarked'] as bool),
    );

    if (existing != null) {
      await (update(contacts)..where((c) => c.id.equals(existing!.id)))
          .write(companion);
    } else {
      await into(contacts).insert(companion);
    }
  }

  /// Extract the first inbox ID from a registeredInboxIDs JSON string.
  /// Cheap string extraction — avoids a full JSON decode.
  static String? _firstInboxIdFromJson(String json) {
    const marker = '"inboxId":"';
    final idx = json.indexOf(marker);
    if (idx == -1) return null;
    final start = idx + marker.length;
    final end = json.indexOf('"', start);
    if (end == -1) return null;
    return json.substring(start, end);
  }

  // ===========================================================================
  // BOOKMARKED POSTS QUERIES
  // ===========================================================================

  /// Get all bookmarked posts for a session, newest first
  Future<List<BookmarkedPost>> getBookmarkedPosts(String sessionAddr) async {
    return (select(bookmarkedPosts)
          ..where((b) => b.sessionAddress.equals(sessionAddr))
          ..orderBy([(b) => OrderingTerm.desc(b.bookmarkedAt)]))
        .get();
  }

  /// Insert or update a bookmarked post
  Future<int> upsertBookmarkedPost(BookmarkedPostsCompanion post) async {
    return into(bookmarkedPosts).insert(
      post,
      onConflict: DoUpdate(
        (old) => post,
        target: [bookmarkedPosts.postUid, bookmarkedPosts.feedUrl, bookmarkedPosts.sessionAddress],
      ),
    );
  }

  /// Delete a bookmarked post
  Future<int> deleteBookmarkedPost(
      String postUid, String? feedUrl, String sessionAddr) async {
    return (delete(bookmarkedPosts)
          ..where((b) =>
              b.postUid.equals(postUid) &
              (feedUrl != null
                  ? b.feedUrl.equals(feedUrl)
                  : b.feedUrl.isNull()) &
              b.sessionAddress.equals(sessionAddr)))
        .go();
  }

  /// Write back a bookmark refresh verdict. Success passes the re-encoded
  /// blob and clears [BookmarkedPosts.unavailable]; a server-says-gone
  /// verdict passes `postJson: null` (the stored blob may be the only copy
  /// left — never overwrite it on failure) and sets the flag. Both bump
  /// [BookmarkedPosts.updatedAt] so the sweep backs off either way.
  Future<int> updateBookmarkedPostRefresh({
    required String postUid,
    required String? feedUrl,
    required String sessionAddr,
    String? postJson,
    String? etag,
    required int updatedAt,
    required bool unavailable,
  }) async {
    return (update(bookmarkedPosts)
          ..where((b) =>
              b.postUid.equals(postUid) &
              (feedUrl != null
                  ? b.feedUrl.equals(feedUrl)
                  : b.feedUrl.isNull()) &
              b.sessionAddress.equals(sessionAddr)))
        .write(BookmarkedPostsCompanion(
      postJson: postJson != null ? Value(postJson) : const Value.absent(),
      // The validator only moves with a fresh body — a 304 or a gone-verdict
      // keeps the stored one (it still names the bytes we hold).
      etag: etag != null ? Value(etag) : const Value.absent(),
      updatedAt: Value(updatedAt),
      unavailable: Value(unavailable),
    ));
  }

  /// Check if a post is bookmarked
  Future<bool> isPostBookmarked(
      String postUid, String? feedUrl, String sessionAddr) async {
    final result = await (select(bookmarkedPosts)
          ..where((b) =>
              b.postUid.equals(postUid) &
              (feedUrl != null
                  ? b.feedUrl.equals(feedUrl)
                  : b.feedUrl.isNull()) &
              b.sessionAddress.equals(sessionAddr))
          ..limit(1))
        .getSingleOrNull();
    return result != null;
  }

  // ===========================================================================
  // ACTIVITY EVENTS QUERIES (on-chain activity feed — see PublicOSActivity)
  // ===========================================================================

  /// Insert polled activity rows, ignoring any already present on the
  /// (txHash, logIndex, sessionAddress) unique key. Re-seen rows keep their
  /// existing `isRead` state (the badge reads unread from the table).
  Future<void> insertActivityEvents(List<ActivityEventsCompanion> rows) async {
    if (rows.isEmpty) return;
    await batch((b) {
      b.insertAll(activityEvents, rows, mode: InsertMode.insertOrIgnore);
    });
  }

  /// Insert ONE activity row unless (txHash, logIndex, sessionAddress) is
  /// already stored. Returns true when it was new. The single-row door the
  /// social push and the inbox pull use: a push
  /// that already popped must not pop again from the pull, and vice versa.
  Future<bool> insertActivityEventIfNew(ActivityEventsCompanion row) async {
    final txHash = row.txHash.value;
    final logIndex = row.logIndex.value;
    final session = row.sessionAddress.value;
    final existing = await (select(activityEvents)
          ..where((a) =>
              a.txHash.equals(txHash) &
              a.logIndex.equals(logIndex) &
              a.sessionAddress.equals(session))
          ..limit(1))
        .get();
    if (existing.isNotEmpty) return false;
    final id = await into(activityEvents)
        .insert(row, mode: InsertMode.insertOrIgnore);
    return id > 0;
  }

  /// Newest-first activity for a session (block, then log index, descending).
  Future<List<ActivityEventRow>> getActivityEvents(String sessionAddr,
      {int limit = 200}) async {
    return (select(activityEvents)
          ..where((a) => a.sessionAddress.equals(sessionAddr))
          // Newest first by TIME, not block: social rows
          // carry blockNumber 0, so a block sort would sink them to the bottom
          // and, past `limit`, off the list. Chain rows store
          // the block's ms timestamp, so block/log stay as tie-breakers only.
          ..orderBy([
            (a) => OrderingTerm.desc(a.timestamp),
            (a) => OrderingTerm.desc(a.blockNumber),
            (a) => OrderingTerm.desc(a.logIndex),
          ])
          ..limit(limit))
        .get();
  }

  /// Count of unread activity rows for a session (drives the bell badge).
  Future<int> getUnreadActivityCount(String sessionAddr) async {
    final rows = await (select(activityEvents)
          ..where((a) =>
              a.sessionAddress.equals(sessionAddr) & a.isRead.equals(false)))
        .get();
    return rows.length;
  }

  /// Mark every unread activity row for a session as read (on screen open).
  Future<void> markAllActivityRead(String sessionAddr) async {
    await (update(activityEvents)
          ..where((a) =>
              a.sessionAddress.equals(sessionAddr) & a.isRead.equals(false)))
        .write(const ActivityEventsCompanion(isRead: Value(true)));
  }

  /// Delete every cached activity row for a session. Backs the developer
  /// "clear chain notifications" action (see PublicOSActivity.clearStored).
  /// Returns the number of rows removed.
  Future<int> deleteActivityEventsForSession(String sessionAddr) async {
    return (delete(activityEvents)
          ..where((a) => a.sessionAddress.equals(sessionAddr)))
        .go();
  }

  // ===========================================================================
  // USED NFT AVATARS QUERIES (raw SQL — see UsedNftAvatarRow / usedNftAvatarsDdl)
  // ===========================================================================

  /// All seen-as-owned NFT avatars for a session, most-recently-seen first.
  /// Pass [namespace] (`'eip155'` / `'solana'`) to scope to one chain family.
  Future<List<UsedNftAvatarRow>> getUsedNftAvatars(String sessionAddr,
      {String? namespace}) async {
    final where = namespace == null
        ? 'session_address = ?'
        : 'session_address = ? AND namespace = ?';
    final vars = <Variable>[
      Variable.withString(sessionAddr),
      if (namespace != null) Variable.withString(namespace),
    ];
    final rows = await customSelect(
      'SELECT * FROM used_nft_avatars WHERE $where ORDER BY last_seen_at DESC',
      variables: vars,
    ).get();
    return rows.map((r) => UsedNftAvatarRow.fromRow(r)).toList();
  }

  /// Delete one used NFT-avatar row (keyed by pointer_key + session).
  Future<void> deleteUsedNftAvatar({
    required String pointerKey,
    required String sessionAddress,
  }) async {
    await customStatement(
      'DELETE FROM used_nft_avatars '
      'WHERE pointer_key = ? AND session_address = ?',
      [pointerKey, sessionAddress],
    );
  }

  /// Insert or update a used NFT-avatar row (keyed by pointer_key + session).
  Future<void> insertUsedNftAvatar({
    required String pointerKey,
    required String namespace,
    required int chain,
    required String standard,
    required String contract,
    required String tokenId,
    String? mint,
    String? imageUrl,
    String? chainName,
    String? owner,
    required bool verifiedOwnership,
    required int checkedAt,
    required String sessionAddress,
    required int lastSeenAt,
  }) async {
    await customStatement(
      'INSERT INTO used_nft_avatars '
      '(pointer_key, namespace, chain, standard, contract, token_id, mint, '
      'image_url, chain_name, owner, verified_ownership, checked_at, '
      'session_address, last_seen_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) '
      'ON CONFLICT (pointer_key, session_address) DO UPDATE SET '
      'namespace = excluded.namespace, chain = excluded.chain, '
      'standard = excluded.standard, contract = excluded.contract, '
      'token_id = excluded.token_id, mint = excluded.mint, '
      'image_url = excluded.image_url, chain_name = excluded.chain_name, '
      'owner = excluded.owner, verified_ownership = excluded.verified_ownership, '
      'checked_at = excluded.checked_at, last_seen_at = excluded.last_seen_at',
      [
        pointerKey,
        namespace,
        chain,
        standard,
        contract,
        tokenId,
        mint,
        imageUrl,
        chainName,
        owner,
        verifiedOwnership ? 1 : 0,
        checkedAt,
        sessionAddress,
        lastSeenAt,
      ],
    );
  }
}
