# PublicOS Core

Public source under the Business Source License 1.1. Free to use for anything built on the PublicOS network. Each version becomes AGPL-3.0-or-later four years after its release. See [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md).

The Dart SDK for building PublicOS client applications.

PublicOS is a decentralized identity + messaging + publishing protocol. Core
packages the on-chain identity, secure-storage key handling, messaging
(XMTP), and feed (channels/posts) integrations behind a single static
`PublicOS` class so a Flutter app can talk to the full protocol without
re-implementing any of it.

This package is consumed by `publicos_client` (mobile/tablet) and
`publicos_desktop` (Windows/macOS/Linux). Everything you see in those
apps routes through here.

---

## Architecture at a glance

```
┌───────────────────────────────────────────────────────────┐
│                      PublicOS (core)                      │
│  static fields · streams · 4-stage init · shared state    │
└───────────────────────────────────────────────────────────┘
           │              │              │
┌──────────┴─────┐ ┌──────┴─────┐ ┌──────┴─────┐   INFRA
│  PublicOSBsp   │ │ PublicOSSsp│ │PublicOSXmtp│   providers
│  (chain/RPC)   │ │ (feeds)    │ │ (messages) │
└────────────────┘ └────────────┘ └────────────┘
           │              │              │
┌──────────┴──────────────┴──────────────┴─────────────────┐
│               Consumer extensions                        │
│                                                          │
│  Accounts · Contacts · Conversations · Channels          │
│  FeedLists · Governance · Treasury · Safe · AppRegistry  │
│  Settings · Recovery · Keychain · Auth · Database · ...  │
└──────────────────────────────────────────────────────────┘
```

- **Infrastructure layer** — `BSP`, `SSP`, `XMTP`. These wrap the three
  protocol-level providers (blockchain service provider, social service
  provider, XMTP messaging network). Everything else talks through them.
- **Consumer extensions** — the actual feature surfaces: identity,
  messaging, feeds, governance, settings, etc.
- **`PublicOS` itself** — a static class holding session state, service
  clients, and the boot sequence. Every extension is implemented as
  Dart static methods on a class that reads/writes this shared state.

Source layout:

```
lib/src/
├── core/
│   ├── publicos_core.dart          # the PublicOS class: state + 4-stage init
│   └── extensions/                 # one file per consumer surface (18 of them)
│       ├── publicos_accounts.dart
│       ├── publicos_contacts.dart
│       ├── publicos_conversations.dart
│       ├── publicos_channels.dart
│       ├── publicos_feed_lists.dart
│       ├── publicos_governance.dart
│       ├── publicos_treasury.dart
│       ├── publicos_safe.dart
│       ├── publicos_app_registry.dart
│       ├── publicos_settings.dart
│       ├── publicos_recovery.dart
│       ├── publicos_keychain.dart
│       ├── publicos_auth.dart
│       ├── publicos_database.dart
│       ├── publicos_attachment_cache.dart
│       ├── publicos_bsp.dart       # (infra) chain + 36 contract bindings
│       ├── publicos_ssp.dart       # (infra) feed server resolution + transport
│       └── publicos_xmtp.dart      # (infra) inbox IDs, installations, identity
├── models/                         # Contact, XmtpConversation, Record, Post,
│                                   # Comment, Reaction, Message, Member, ...
├── database/                       # drift (SQLite) — contacts, conversations,
│                                   # messages, channels, feed_servers, ...
└── contracts/                      # generated web3dart bindings (39 contracts)
```

---

## Installation

```yaml
dependencies:
  publicos_core:
    path: ../PublicOS_Core   # or git: ... / pub.dev once published
```

Consumers also need `xmtp_plugin ^1.0.1` from pub.dev for the native XMTP
bindings (Android/iOS/Web/Windows/macOS/Linux). Core re-exports the
public surface — `import 'package:publicos_core/publicos_core.dart';` is
usually enough.

---

## Setup

- **Neynar lookup (optional).** Build with `--dart-define=NEYNAR_API_KEY=<your key>` to enable the Neynar step of Farcaster name resolution. Without it that step is skipped.
- **Integration test key.** Set the environment variable `PUBLICOS_TEST_KEY_FILE` to the path of the JSON key file the local deploy signs with (it holds a `privateKey` field).
- **Local node.** Integration tests expect a local node at `127.0.0.1:8545` and the contracts repo (`ContactOS_Contracts`) checked out beside this one.

---

## The 4-stage init

Core boots in four explicit stages. Each stage is idempotent and
independent enough that the app can stall at a stage, show UI, and
resume later when preconditions are met (chain back up, user signs in,
XMTP keys loaded).

```dart
import 'package:publicos_core/publicos_core.dart';

// Stage 1 — infrastructure (DB, secure storage, public RPC, notifications)
await PublicOS.init();

// Biometric / PIN gate. In dev, set `PublicOS.debugNoAuthNeeded = true`
// to bypass the prompt.
await PublicOSAuth.authenticate();

// Stage 2 — enter authenticated session state, then connect to the chain.
// The account address is the PublicOS account (not the wallet EOA).
//
// `restoreSession(address)` loads keys, verifies client↔account on chain,
// fetches + saves the user's own contact, and sets `myPublicosAddress`.
// It does NOT swing the RPC — that's initBSP's job. Call them in order.
//
// `initBSP()` is parameterless now. It reads `myPublicosAddress` to decide
// whether to resolve a BSP subscription and swing the RPC. Apps without a
// session (e.g. an admin tool's bootstrap) can skip restoreSession and
// call initBSP() directly — it'll resolve modules, start polling, and
// leave the RPC on whatever init() set up (override URL or public).
final account = EthereumAddress.fromHex(storedAccountAddress);
await PublicOSAccounts.restoreSession(account);
await PublicOS.initBSP();

// Stage 3 — resolve the feed server.
// Order: override → custom (DB) → SSP subscription → bootstrap default.
await PublicOS.initSSP();

// Stage 4 — start the XMTP client + inbox streams.
// No-op if there is no XMTP key in secure storage yet.
await PublicOS.initXMTP();
```

After this runs, the app reads session info via static fields:

| Field                             | Meaning                                  |
| --------------------------------- | ---------------------------------------- |
| `PublicOS.myPublicosAddress`      | Current account address (String, EIP-55)|
| `PublicOS.clientBlockchainAddress`| Wallet EOA tied to the current session   |
| `PublicOS.activeRpcUrl / Source`  | Which RPC endpoint we resolved to        |
| `PublicOS.activeSspUrl / Source`  | Which feed server we resolved to         |
| `PublicOS.web3Connected`          | Chain reachable right now?               |
| `PublicOS.sspConnected`           | Feed server reachable right now?         |
| `PublicOS.xmtpConnected`          | XMTP client alive and streaming?         |

And each provider layer has a broadcast stream the UI can subscribe to
for "infra status" pills in the status bar:

```dart
PublicOS.web3Status.stream.listen((up) => ...);
PublicOS.sspStatus.stream.listen((up) => ...);
PublicOS.xmtpStatus.stream.listen((up) => ...);
```

### Graceful degradation

Core never blocks the app on an unreachable dependency. If the chain is
down, `initBSP` still loads keys from secure storage and reads the last
cached contact; chain-call sites just fail at call-time until
`PublicOS.upgradeRpcPostAuth()` recovers (polled every 60 min by
default). SSP down means feed screens show an empty state. XMTP down
means the chat screen stalls but everything else keeps working.

### RPC / SSP overrides

Override the resolver entirely (for example, to pin every session to a
local dev chain):

```dart
PublicOS.setRpcOverride('http://127.0.0.1:8545', 'local');
PublicOS.setSspOverride('http://localhost:8081', 'local');
// clear with PublicOS.clearRpcOverride() / clearSspOverride()
```

---

## Session model

The session is minimal. Core keeps a single account cached:

```dart
PublicOS.myPublicosAddress;   // String? — the only "who am I" pointer
```

Everything else (avatar, bio, records, orgs) is stored in the local DB
and read with `PublicOSContacts.getContact(address)`. There is no
`currentMyContact` / `currentUser` / `my.profile` cached object. The
canonical read is always:

```dart
final me = await PublicOSContacts.getContact(
  EthereumAddress.fromHex(PublicOS.myPublicosAddress!),
);
print('hi ${me!.displayName}');
print('avatar: ${me.avatarUrl}');
print('bio:    ${me.getRecord('profile.bio')?.value}');
```

### Switching accounts

`PublicOSAccounts.restoreSession(address)` tears down the current
session state and loads another account from secure storage. Used by
the "switch account" flow in the client apps.

The full "just created a new friend account" activation flow is:

```dart
// 1. temp EOA stored under `account_temporaryAccount_*` keys
final friendEoa = generateNewEoa();
await saveTempKeys(friendEoa);

// 2. someone with gas creates the on-chain account
await PublicOSAccounts.createAccount('alice', friendEoa.eip55With0x);

// 3. poll until the new account resolves
EthereumAddress? newAccount;
while (newAccount == null) {
  newAccount = await PublicOSAccounts.getAccountAddressForClient(friendEoa);
  await Future.delayed(Duration(seconds: 1));
}

// 4. renames `temporaryAccount` keys to `account_<newAccount>_*`
//    and calls restoreSession for you
await PublicOSAccounts.checkAndActivatePendingTemporaryClient();
// PublicOS.myPublicosAddress is now the friend's new on-chain account.
```

### Multi-account signing without swapping sessions

For contract calls on behalf of another account *without* changing the
global session, pass `credentials: EthPrivateKey` directly to the
contract write. Every generated binding in `PublicOSBsp.*Contract`
accepts it. Use this when you need to temporarily sign as another key
(e.g. an admin tool minting accounts on behalf of seed users).

### Concurrency note

`restoreSession` mutates global static state. It is **not** safe to call
concurrently from multiple isolates or async loops sharing this state.
Consumers with concurrent session needs (like a poller running beside a
simulation) must implement their own mutex.

---

## The write-through pattern

Any chain mutation on a contact (records, clients, display name, inbox
IDs, …) follows the same flow:

```
setX()  ──►  chain tx  ──►  waitForReceipt  ──►  fetchContact (fresh)
                                                       │
                                             saveContact (local DB)
                                                       │
                                                  return true
```

Callers that want up-to-date data just call `getContact(address)` again
after the write returns. No "manually invalidate cache" step, no
"refresh after you think the tx committed" — if the function returned
`true`, the DB is already fresh.

```dart
final ok = await PublicOSContacts.setRecord(
  Record.asProfile(
    key: 'profile.bio',
    value: 'hello world',
    expiration: DateTime.now().add(Duration(days: 365)),
  ),
);
assert(ok);

final me = await PublicOSContacts.getContact(myAddress);
assert(me!.getRecord('profile.bio')!.value == 'hello world');
```

`setRecord`, `deleteRecord`, `addClient`, `removeClient`, inbox
registration, and all `PublicOSContacts.*` / `PublicOSAccounts.*` writes
behave this way.

---

## Data models

### `Contact` (person or org)

One record per PublicOS account. Person-only fields — messaging
conversations are a separate model. 14 core fields:

| Field                 | Purpose                                           |
| --------------------- | ------------------------------------------------- |
| `displayName`         | Local display string (always present)             |
| `publicosDisplayName` | On-chain username (`"alice"`)                     |
| `publicosAddress`     | Account Blueprint contract address                |
| `isOrgAccount`        | True for orgs/DAOs                                |
| `clients`             | ETH addresses associated with this person        |
| `records`             | `List<Record>` — profile, social links, whatever  |
| `registeredInboxIDs`  | `List<InboxEntry>` — every XMTP inbox ID they own |
| `orgMembers`          | (orgs only) member addresses, lazy-loaded         |
| `orgMemberCount`      | (orgs only) total member count from chain         |
| `isBlocked`           | Local flag                                        |
| `isSupport`           | Local flag (support contact)                      |
| `createdBy`           | (orgs only) founder's display name                |
| `createdAt`           | Local timestamp                                   |
| `updatedAt`           | Local timestamp                                   |

Helpers on the model: `.avatarUrl`, `.iconColor`, `.getRecord(key)`,
`.getAddressesByLabel(label)`.

### `XmtpConversation` (channel/topic)

One record per XMTP topic. Identity is decoupled from conversation:

| Field            | Purpose                                        |
| ---------------- | ---------------------------------------------- |
| `topic`          | XMTP topic string (primary key with client)    |
| `type`           | `dm` or `group`                                |
| `peerInboxId`    | (DMs only) 64-char hex                         |
| `groupName`      | (groups only)                                  |
| `groupImageUrl`  | (groups only)                                  |
| `groupDescription` | (groups only)                                |
| `pinnedFrameUrl` | (groups only) pinned mini-app URL              |
| `members`        | (groups only) `List<Member>`                   |
| `createdAt`      | From XMTP, nullable                            |
| `contact`        | Resolved peer `Contact` — populated by the view layer via `findContactByInboxId(peerInboxId)`, NOT persisted |

The `contact` field is always re-resolved on load — conversations and
people are stored separately, so renaming/blocking/editing a contact
never requires touching the conversations table.

### `Record`

Generic on-chain key/value with an expiration. Records are grouped by
type (`profile.*`, `social.*`, `apps.*`, custom).

```dart
final bio = Record.asProfile(
  key: 'profile.bio',
  value: 'building public goods',
  expiration: DateTime.now().add(Duration(days: 365)),
);
```

---

## Extensions reference

Everything is accessed as `PublicOSX.method(...)`. These are all static
classes — no instances.

### Infrastructure
- **`PublicOSBsp`** — the Web3Client, 36 contract bindings, RPC
  resolution (cached→fresh→custom→public), custom-RPC CRUD, module
  address resolution + polling, block helpers.
- **`PublicOSSsp`** — feed server resolution (override→custom→
  subscription→bootstrap default), custom-server CRUD, EIP-191 request
  signing, HTTP transport, media upload/list/delete, account-wide
  whitelist/banning of posters.
- **`PublicOSXmtp`** — inbox IDs (on-chain pointer), installation
  management, consent, XMTP identity account ops, account-level XMTP
  network queries. **Not** conversation CRUD — that's in `Conversations`.

### Identity
- **`PublicOSAuth`** — biometric/PIN gate, `authenticate()`, debug bypass.
- **`PublicOSAccounts`** — account lifecycle (`createAccount`,
  `createOrg`), client management (`addClient`, `removeClient`),
  vouching & citizenship (`isCitizen`, `getVouchCount`, `getVouchersOf`,
  `getVoucheesOf`, `vouch`), session (`restoreSession`,
  `checkAndActivatePendingTemporaryClient`), temp-to-permanent key
  transfer.
- **`PublicOSContacts`** — canonical contact DB. `getContact`,
  `saveContact`, `fetchContact` (chain), `resolveByIdentifier` (any
  form → person), `findContactByInboxId` (XMTP peer lookup),
  `setRecord`/`deleteRecord`/`getRecord` (write-through), ENS/Farcaster/
  NFT avatar resolution, `fetchOrgMembers` (paginated).
- **`PublicOSGovernance`** — all org operations: `createOrg` (private/
  public), membership queries (`getOrgMembers`, `getOrgMemberCount`,
  `isOrgMember`, `getOrgThreshold`, `getOrgCreator`,
  `getOrgsForAccount`), voting wrappers (`startVoteRegisterWallet`,
  `startVoteAddSafeModule`, `startVoteSetThreshold`,
  `startVoteRegisterApp`, ...), `castVote`, `getActiveVote`,
  `getVotingHistory`, org inbox ID management.

### Messaging
- **`PublicOSConversations`** — conversation CRUD, XMTP stream
  lifecycle, message store and query, `syncAll`/`syncConversation`,
  group management, drafts, read receipts, notifications, remote
  attachment encryption. This is the big file (~1800 lines) and owns
  both conversations and the messages inside them.

### Feeds & publishing
- **`PublicOSChannels`** — channel CRUD, posts, comments, reactions,
  read paths (`getChannelsByAddress`, `getPostsForChannel`,
  `getComments`), public read endpoints, EIP-191-signed write endpoints.
- **`PublicOSFeedLists`** — "feeds" in the home tab sense — lists of
  channels the user aggregates, bookmarked posts.

### App & data
- **`PublicOSAppRegistry`** — mini-app registry, URL pointers, install
  state, bookmarks, "app of the week".
- **`PublicOSSettings`** — user preferences persisted locally
  (notifications, polling, post mode, theme).
- **`PublicOSTreasury`** — balance, rent payments, claims,
  subscription state.
- **`PublicOSSafe`** — Safe module wrappers for org multisig ops.
- **`PublicOSRecovery`** — account recovery via backup key and/or
  vouched recovery.
- **`PublicOSKeychain`** — the hybrid key store. The blockchain private
  key and DB encryption key live in secure storage, keyed by
  `account_<address>_*`. Multiple accounts can coexist — session swap
  just rewrites pointers.
- **`PublicOSDatabase`** — drift (SQLite) database bootstrap + table
  access. Schema v12 at time of writing. Contacts, conversations,
  messages, channels, feed_servers, custom_rpcs, attachments,
  bookmarks, feed_lists.
- **`PublicOSAttachmentCache`** — local cache of decrypted XMTP
  attachments (invalidated on session swap).

---

## Testing

Core ships a scenario-test harness under `test/` that runs against a
live local PublicOS chain. It mocks the platform plugins
(`FlutterSecureStorage`, `LocalAuth`, `PathProvider`, `SharedPreferences`,
`Notifications`, `Workmanager`) so the tests boot headless.

```bash
# single scenario
flutter test test/scenarios/s0_init_test.dart

# full suite (serial — chain writes are idempotent by timestamping)
flutter test test/scenarios/ --concurrency=1
```

Pre-conditions:

1. A local PublicOS chain reachable (default `http://127.0.0.1:8545`).
2. A local key file with the test account's (jmsl) client private key;
   its path comes from the environment variable `PUBLICOS_TEST_KEY_FILE`.

Current suite (~60s serial):

| File                          | What it covers                                    |
| ----------------------------- | -------------------------------------------------- |
| `s0_init_test.dart`           | 4-stage init + status streams                      |
| `s1_contact_crud_test.dart`   | save/read/search/dedup/delete                      |
| `s2_profile_record_test.dart` | setRecord write-through, chain→DB refresh          |
| `s3_settings_test.dart`       | post mode, notifications, polling config           |
| `s4_friend_account_test.dart` | `createAccount` for a fresh EOA + reverse lookup   |
| `s5_session_swap_test.dart`   | full activation → `myPublicosAddress` flip         |
| `s9_channels_test.dart`       | channels/posts/comments read path                  |
| `s10_vouching_test.dart`      | citizenship + vouch graph reads                    |
| `s11_subscriptions_test.dart` | BSP/SSP resolution + UI list builders              |
| `s12_governance_test.dart`    | `createOrg` + all 7 org metadata queries           |
| `s13_reset_test.dart`         | full state reset cycle                             |

XMTP scenarios (DMs, groups, messages, key lifecycle) need the native
XMTP plugin and don't run headless — those are exercised in the
consumer app integration test suites.

The test harness itself lives in `test/fixtures/test_fixtures.dart`:

- `bootstrap()` — install plugin mocks + defeat HttpOverrides.
- `initCoreForTesting()` — substitute for `PublicOS.init()` with an
  in-memory drift DB (`NativeDatabase.memory()`).
- `loadJmslFromManager()` — reads the local key file, resolves
  jmsl's on-chain account, writes the canonical secure-storage keys.
- `generateFriend()` — fresh random EOA stored under the
  `temporaryAccount` slot (ready for the activation flow).
- `setupWithJmsl({withXmtp})` — one-shot: bootstrap + initCore +
  authenticate + RPC override + loadJmsl + initBSP + initSSP [+ initXMTP].

Look at `s4_friend_account_test.dart` and `s5_session_swap_test.dart`
for the idiomatic "create a fresh friend and verify chain state" pattern.

---

## Design notes & gotchas

**Identity is a person, not a conversation.** `Contact` is
*strictly* a person/org. XMTP conversations live in `XmtpConversation`
and carry an unresolved `peerInboxId`; the view layer looks up the
person via `findContactByInboxId(peerInboxId)` when rendering. Editing
a contact never touches the conversations table.

**Write-through, not cache-invalidation.** Every chain mutation
refetches the fresh state from chain and saves it to the local DB
before returning. Callers read via `getContact` and trust it's fresh.

**Session state is minimal.** `myPublicosAddress` is the only cached
pointer. Everything else is DB-backed. Switching accounts = rewriting
pointers + re-reading from DB.

**Multi-account contract calls.** You don't have to swap sessions to
sign as another key — every generated `web3dart` binding accepts an
explicit `credentials:` parameter. Use session swap for feeds/messages
(global state), explicit credentials for isolated chain writes.

**SSP is subscription-only by design.** There is no "public SSP
service" in the protocol — users subscribe to an SSP provider or
self-host. The `DEFAULT_SSP_URL` bootstrap constant exists for dev
convenience; a real deployment expects a subscription or a custom
server. Calls that can't resolve a server surface a `NO_SERVER` error
rather than silently falling back.

**Public RPC is for reads and discovery.** Writes should use the
user's subscribed BSP where possible. Core picks a write RPC via
`upgradeRpcPostAuth()` after session restore, polling for
reachability every 60 min.

**The default feed URL is an architectural courtesy, not a
guarantee.** Same reasoning as SSP: consumer apps should assume it
may disappear and handle the "no server available" state
cleanly.

**The core is not concurrency-safe.** Static state is shared process-
wide. Multi-isolate or multi-loop consumers need their own locks.

**`web3dart` package is pinned.** See `pubspec.yaml` — a downstream
audit is tracked separately. Don't bump it without re-running the full
scenario suite.

**XMTP plugin version is pinned.** `xmtp_plugin: ^1.0.1` from pub.dev.
FRB runtime/codegen mismatches crash on load; do not mix with
`xmtp_plugin`'s source repo (`xmtp_flutter`) in the same workspace.

---

## Where to go next

- **Protocol docs (public):** https://publicos.dev
