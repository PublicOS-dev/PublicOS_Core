/// PublicOS Core - The foundation for the PublicOS decentralized identity system.
///
/// This package provides the core functionality for PublicOS including:
/// - Blockchain interactions (Web3, smart contracts)
/// - XMTP messaging protocol
/// - Key management and account system
/// - Database layer (Drift/SQLite)
/// - Contact, profile, and feed management
library publicos_core;

// Core system (PublicOS + all extensions)
export 'src/core/core.dart';

// Exceptions surfaced from signed-write paths
export 'src/core/exceptions/ssp_gate_exception.dart';
// …and from gated READS (paid feeds).
export 'src/core/exceptions/paywall_exception.dart';
// …every other read-gate refusal (403 + the channel object) and the 401 challenge, typed.
export 'src/core/exceptions/feed_gate_exception.dart';

// Database (hide generated data classes that conflict with model names)
export 'src/database/database.dart'
    hide Contact, Message, FeedServer, ListFeed, Conversation;
export 'src/database/helpers.dart';
export 'src/database/converters.dart';

// Models
export 'src/models/contact.dart';
export 'src/models/activity_event.dart';
export 'src/models/social_notification.dart';
export 'src/models/xmtp_conversation.dart';
export 'src/models/message.dart';
export 'src/models/record_model.dart';
export 'src/models/social_links.dart';
export 'src/models/nft_avatar.dart';
export 'src/models/app_card.dart';
export 'src/models/member.dart';
export 'src/models/post.dart';
export 'src/models/trending.dart';
export 'src/models/comment.dart';
export 'src/models/reaction.dart';
export 'src/models/rss_models.dart';
export 'src/models/app_bookmark.dart';
export 'src/models/safe_transaction_details.dart';
export 'src/models/feed_server/feed_server_models.dart';
export 'src/models/feed_server/gate_tier.dart';

// Contracts (hide conflicting generated names across contracts)
export 'src/contracts/AccountManager.g.dart'; // owner of the shared Governable events AdminAdded / AdminRemoved
export 'src/contracts/AccountMemory.g.dart' hide AdminAdded, AdminRemoved, InheritanceSet;
export 'src/contracts/InvitationManager.g.dart'
    hide AdminAdded, AdminRemoved, InheritanceSet; // bootstrap-only
export 'src/contracts/AccountBlueprint.g.dart';
export 'src/contracts/OrgManager.g.dart' hide MemberAdded, MemberRemoved;
export 'src/contracts/RecordManager.g.dart' hide AdminAdded, AdminRemoved, InheritanceSet; // record writes
export 'src/contracts/AgreementManager.g.dart' hide AdminAdded, AdminRemoved, InheritanceSet; // agreements: protocolVersion for the create-account consent
export 'src/contracts/AgreementMemory.g.dart'; // agreements: the published texts (getVersion), read by the citizen claim sheet
export 'src/contracts/OrgAddPermitsManager.g.dart' hide AdminAdded, AdminRemoved, InheritanceSet; // who can add me to groups
export 'src/contracts/OrgCancelVoteMemory.g.dart'; // the org's vetoer
export 'src/contracts/OrgStorage.g.dart';
export 'src/contracts/SafeManager.g.dart';
export 'src/contracts/SoulboundKit.g.dart' hide Approval, ApprovalForAll, Transfer;
export 'src/contracts/SafeMemory.g.dart';
export 'src/contracts/WalletDirectoryManager.g.dart' hide AdminAdded, AdminRemoved, InheritanceSet, Eip712Domain, EIP712DomainChanged;
export 'src/contracts/WalletDirectoryMemory.g.dart';
export 'src/contracts/SafeAuth.g.dart';
export 'src/contracts/SafeModuleSetup.g.dart';
export 'src/contracts/XmtpManager.g.dart' hide AdminAdded, AdminRemoved, InheritanceSet;
export 'src/contracts/XmtpMemory.g.dart';
export 'src/contracts/RecoveryModule.g.dart' hide AdminAdded, AdminRemoved, InheritanceSet, VoteCancelled, VoteCast, VoteStarted;
// Voting: the Governor engine + VoteWeight store sit under the
// VOTING_MECHANISM slot.
export 'src/contracts/Governor.g.dart' hide AdminAdded, AdminRemoved, InheritanceSet, VoteCancelled, VoteCast, VoteExecuted, VoteStarted, VoteDurationSet;
export 'src/contracts/VoteWeight.g.dart';
// AppRegistryManager's admin events collide with XmtpManager's; XmtpManager
// stays the exposed copy.
export 'src/contracts/AppRegistryManager.g.dart' hide AdminAdded, AdminRemoved, InheritanceSet;
export 'src/contracts/AppRegistryMemory.g.dart' hide GetAllAppPointers, AppPointerRemoved, AppPointerSet, AppRegistered, AppRemoved, AppTitleUpdated;
export 'src/contracts/GenesisManager.g.dart' hide AccountCreated;
export 'src/contracts/ModuleRegistry.g.dart';
export 'src/contracts/TreasuryManager.g.dart' hide AdminAdded, AdminRemoved, InheritanceSet, MonthlyCapSet, PolicyRegistered, PolicyRemoved, TokensBurned, TokensMinted, TokensTransferred;
export 'src/contracts/TreasuryMemory.g.dart' hide MintCap;
// Domain-rights economy (replaces Rent / Dividend / Grant / ProviderPayment).
// `hide` clauses resolve event-name collisions across the new bindings:
// AdminSet/AdminRevoked are universal; BonusNameChangeGranted (Domain{Manager,Memory}),
// PeriodSet (DomainMemory/SubsMemory), the EIP-712 names (AccountManager/SubsManager), and the
// Grant* events (GrantsManager/GrantsMemory) each collide on one side.
export 'src/contracts/Accumulator.g.dart' hide AdminAdded, AdminRemoved, InheritanceSet;
export 'src/contracts/DomainManager.g.dart' hide AdminAdded, AdminRemoved, InheritanceSet, BonusNameChangeGranted;
export 'src/contracts/DomainMemory.g.dart' hide AdminAdded, AdminRemoved, InheritanceSet;
// Subscriptions: ONE manager + ONE memory for both axes (0 = BSP, 1 = SSP).
export 'src/contracts/SubsManager.g.dart' hide AdminAdded, AdminRemoved, InheritanceSet, Eip712Domain, EIP712DomainChanged;
export 'src/contracts/SubsMemory.g.dart' hide AdminAdded, AdminRemoved, InheritanceSet, PeriodSet;
export 'src/contracts/GrantsManager.g.dart' hide AdminAdded, AdminRemoved, InheritanceSet, GrantCancelled, GrantCreated, GrantProcessed;
export 'src/contracts/GrantsMemory.g.dart' hide GrantCancelled, GrantCreated;
export 'src/contracts/PublicOSToken.g.dart' hide Transfer, Approval, AccountFrozen;
export 'src/contracts/VouchManager.g.dart' hide AdminAdded, AdminRemoved, InheritanceSet, AllVouchesRemovedByDAO, GenesisBootstrapped, Vouched;
export 'src/contracts/VouchMemory.g.dart' hide AdminAdded, AdminRemoved, InheritanceSet, AllVouchesRemoved, GenesisAccountSet, VouchAdded;
export 'src/contracts/CitizenshipManager.g.dart' hide AdminAdded, AdminRemoved, InheritanceSet, CitizenshipGranted, CitizenshipRevoked, GrantingPaused;
export 'src/contracts/CitizenshipMemory.g.dart' hide AdminAdded, AdminRemoved, InheritanceSet, CitizenshipSet;
export 'src/contracts/BSPRegistryManager.g.dart' hide AdminAdded, AdminRemoved, InheritanceSet, GetAllBSPPointers;
export 'src/contracts/BSPRegistryMemory.g.dart' hide AdminAdded, AdminRemoved, InheritanceSet, BSPPointerRemoved, BSPPointerSet, BSPRegistered, BSPRemoved, BSPTitleUpdated;
export 'src/contracts/ContactOSGuard.g.dart';
// Paid feeds — the split ledger. The Memory is the address an access entry
// names; the Manager is swappable logic, discovered via `memory.manager()`.
//
// `Subscribed` / `TermsChanged` / `PaidUntilSet` / `OwnershipTransferred` are
// hidden where they collide with an already-exposed copy elsewhere in the
// barrel; no consumer needs the paid-feed event classes, since
// PublicOSPaidFeeds decodes receipts through the binding's ABI rather than the
// generated event types.
export 'src/contracts/PaidFeedsMemory.g.dart'
    hide TermsChanged, OwnershipTransferred, PaidUntilSet;
export 'src/contracts/PaidFeedsManager.g.dart'
    hide Subscribed, OwnershipTransferred;
export 'src/contracts/NodeRegistryManager.g.dart' hide GetAllAccountNodes, Eip712Domain, EIP712DomainChanged, AccountBanned, AccountUnbanned, AdminAdded, AdminRemoved, InheritanceSet;
export 'src/contracts/NodeRegistryMemory.g.dart' hide AdminAdded, AdminRemoved, InheritanceSet, GetAllAccountNodes, GetAllAccountNodes$3, GetAllNodePointers, NodePointerRemoved, NodePointerSet, NodeRemoved;
export 'src/contracts/OrgHierarchyStorage.g.dart';
export 'src/contracts/SocialServerRegistryManager.g.dart' hide AdminAdded, AdminRemoved, InheritanceSet, GetAllSocialServerPointers, AccountBanned, AccountUnbanned, RegistrationRestrictedSet, RegistrationAllowedSet;
export 'src/contracts/SocialServerRegistryMemory.g.dart' hide AdminAdded, AdminRemoved, InheritanceSet, NetworkAggregatorSet, SocialServerPointerRemoved, SocialServerPointerSet, SocialServerRegistered, SocialServerRemoved, SocialServerTitleUpdated;
// Enforcement surface: flags + notices, penalties, suspension notice,
// module-upgrade timelock, token time lock. Hides added per ambiguous_export.
export 'src/contracts/FlagRegistryManager.g.dart' hide Eip712Domain, AdminAdded, AdminRemoved, EIP712DomainChanged, InheritanceSet;
export 'src/contracts/FlagRegistryMemory.g.dart';
export 'src/contracts/PenaltiesManager.g.dart' hide AdminAdded, AdminRemoved, InheritanceSet;
export 'src/contracts/PenaltiesMemory.g.dart';
export 'src/contracts/SuspensionNotice.g.dart' hide AdminAdded, AdminRemoved, InheritanceSet;
export 'src/contracts/UpgradeTimelock.g.dart';
export 'src/contracts/TimeLock.g.dart';

// Utils
export 'src/utils/lexorank.dart';
// The PublicOS URL grammar, parsed. Pure (String in, value out) — dispatch is
// per-app and deliberately stays in the clients.
export 'src/utils/deep_link_parser.dart';
export 'src/utils/string_utils.dart';
export 'src/utils/rss_parser.dart';
export 'src/utils/channel_url.dart';
export 'src/utils/log.dart';
export 'src/utils/publicos_qr.dart' hide QrModuleShape, QrEyeShape;
export 'src/utils/tx_utils.dart';
export 'src/utils/post_signature_verifier.dart';
export 'src/utils/comment_signature_verifier.dart';
export 'src/utils/content_hash.dart';
export 'src/utils/pedia_crypto.dart';
export 'src/utils/social_crypto.dart';
export 'src/utils/display_name_validator.dart';
export 'src/utils/consent_uri.dart';

// Config
export 'src/config/profile_templates.dart';
export 'src/config/paid_feed_chains.dart';

// Re-exported dependencies (so consumers don't need separate imports)
export 'package:wallet/wallet.dart' show EthereumAddress, EthPrivateKey;
export 'package:xmtp_plugin/codecs.dart'
    show Reaction, ReactionAction, Reply, AttachmentContent, RemoteAttachmentContent, RemoteAttachmentCodec, MultiRemoteAttachmentContent, ReadReceipt, ContentType, GroupUpdated, ActionsContent, IntentContent, ActionsCodec, IntentCodec, TransactionReference, TransactionMetadata, WalletSendCalls, WalletCall, WalletCallMetadata;
export 'package:xmtp_plugin/xmtp_plugin.dart' show BackupElement, ArchiveMetadata;
