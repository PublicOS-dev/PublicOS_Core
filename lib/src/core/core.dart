/// PublicOS Core System
/// Provides centralized access to all PublicOS functionality through extensions.
/// Import this file to access all PublicOS features.
library;

// Core system with static state
export 'publicos_core.dart';

// Authentication and security
export 'extensions/publicos_auth.dart';

// Account management
export 'extensions/publicos_accounts.dart';

// BSP (Blockchain Service Provider) — chain client, contracts, RPC management
export 'extensions/publicos_bsp.dart';

// SSP (Social Service Provider) — server connection, media, account-wide moderation
export 'extensions/publicos_ssp.dart';

// XMTP identity layer — inbox IDs, installations, consent
export 'extensions/publicos_xmtp.dart';

// Conversation + message management (DMs, groups, sending, streams)
export 'extensions/publicos_conversations.dart';

// Contact (person) management + cross-chain identity resolution (ENS/Farcaster)
export 'extensions/publicos_contacts.dart';

// Profile records — merged into publicos_contacts.dart

// Channel content (posts, comments, reactions, per-channel moderation, follow requests)
export 'extensions/publicos_channels.dart';

// Feed lists (user-side feed curation + bookmarked posts)
export 'extensions/publicos_feed_lists.dart';

// Account-based follow (followed accounts + per-channel mutes, derived + merged)
export 'extensions/publicos_follows.dart';

// Attachment caching
export 'extensions/publicos_attachment_cache.dart';

// Per-channel "Sign in" consent
export 'extensions/publicos_channel_signin.dart';

// Saved sticker library
export 'extensions/publicos_stickers.dart';

// Settings
export 'extensions/publicos_settings.dart';

// FCM/APNs push notification lifecycle + decryption
export 'extensions/publicos_push_notifications.dart';

// Keychain management
export 'extensions/publicos_keychain.dart';

// Safe wallet management
export 'extensions/publicos_safe.dart';

// Soulbound starter kit (the five-piece art collection)
export 'extensions/publicos_citizen_kit.dart';
export 'extensions/publicos_soulbound.dart';

// Multi-protocol wallet directory
export 'extensions/publicos_wallets.dart';

// Account recovery
export 'extensions/publicos_recovery.dart';

// Governance — all org operations + voting infrastructure
export 'extensions/publicos_governance.dart';

// On-chain activity feed — contract-event poll (getLogs) → notification feed
export 'extensions/publicos_activity.dart';

// Wallet transfer notifications — Transfer-event poll over the user's OWN
// wallets. Sibling of publicos_activity: same table, same bell, different
// event set + scope (own wallets, not contacts).
export 'extensions/publicos_wallet_activity.dart';

// App registry
export 'extensions/publicos_app_registry.dart';

// Database
export 'extensions/publicos_database.dart';

// Treasury (universal income and org funding)
export 'extensions/publicos_treasury.dart';
export 'extensions/publicos_agreements.dart';
export 'extensions/publicos_community_standards.dart';

// Paid feeds — the PaidFeeds master contract, one identical deploy per chain.
// Ecosystem-blind on purpose: no ModuleRegistry, no module addresses, and it
// runs on chains where none of the above exists.
export 'extensions/publicos_paid_feeds.dart';
