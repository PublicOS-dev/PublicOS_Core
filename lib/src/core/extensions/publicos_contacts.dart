import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:publicos_core/src/core/core.dart';
import 'package:publicos_core/src/utils/lexorank.dart';
import 'package:publicos_core/src/utils/log.dart';
import 'package:publicos_core/src/utils/string_utils.dart';
import 'package:publicos_core/src/utils/tx_utils.dart';
import 'package:publicos_core/src/models/contact.dart';
import 'package:publicos_core/src/database/database.dart' as db;
import 'package:publicos_core/src/database/helpers.dart';
import 'package:publicos_core/src/models/record_model.dart';
import 'package:publicos_core/src/models/nft_avatar.dart';
import 'package:publicos_core/src/models/app_card.dart';
import 'package:web3dart/web3dart.dart';
import 'package:wallet/wallet.dart';

/// Contact (person) management extension for PublicOS.
///
/// After the 1.0 split, this extension is **pure identity**. Everything
/// related to XMTP conversations (DMs, groups, topics) lives in
/// `publicos_conversations.dart`.
///
/// Sections:
///   1. STORAGE      — persist/retrieve contacts from the local DB
///   2. LOOKUP       — find contacts locally or on-chain (no side effects)
///   3. RESOLUTION   — enrich contacts with data from chain, XMTP, ENS
///   4. ORG MEMBERS  — paginated org membership queries
extension PublicOSContacts on PublicOS {
  static const _tag = 'Contacts';

  // ============================================================================
  // SECTION 1: STORAGE
  // ============================================================================

  /// Persist a contact to the local database.
  /// Dedups by `publicosAddress` first, falls back to any matching
  /// `registeredInboxIDs` entry.
  ///
  /// Side effect: if the contact has no `profile.color` record, one is
  /// generated (or carried over from the existing local row) and persisted
  /// with the contact. This guarantees `Contact.iconColor` returns the same
  /// value across every later read of the same address, even after a chain
  /// refresh that returns no `profile.color`.
  static Future<void> saveContact(Contact contact) async {
    if (PublicOS.sessionBlockchainAddress == null) {
      Log.w(_tag, 'Cannot save contact: no active session');
      return;
    }
    try {
      Contact toSave = contact;
      if (contact.publicosAddress != null &&
          contact.getRecord('profile.color') == null) {
        Record? colorRecord;
        try {
          final existing = await getContact(contact.publicosAddress!);
          colorRecord = existing?.getRecord('profile.color');
        } catch (_) {}
        colorRecord ??= _generateProfileColorRecord();
        toSave = contact.copyWith(records: [...contact.records, colorRecord]);
      }

      final values = DatabaseHelpers.contactToMap(
        toSave,
        PublicOS.sessionBlockchainAddress!,
      );
      await PublicOS.database.saveContactRaw(values);
      Log.d(_tag, '[SAVE] ${toSave.displayName} '
          '(${toSave.publicosAddress?.eip55With0x ?? "no-address"})');
    } catch (e) {
      Log.e(_tag, '[SAVE] Error: $e');
      rethrow;
    }
  }

  static Record _generateProfileColorRecord() {
    final color = Colors.primaries[Random().nextInt(Colors.primaries.length)];
    return Record.asProfile(
      key: 'profile.color',
      value: color.toARGB32().toString(),
    );
  }

  /// Remove a contact by publicos address.
  static Future<void> removeContact(Contact contact) async {
    if (PublicOS.sessionBlockchainAddress == null) return;
    if (contact.publicosAddress == null) return;
    try {
      await PublicOS.database.deleteContactByAddress(
        PublicOS.sessionBlockchainAddress!,
        contact.publicosAddress!.eip55With0x,
      );
    } catch (e) {
      Log.e(_tag, '[REMOVE] Error: $e');
      rethrow;
    }
  }

  // ============================================================================
  // SECTION 2: LOOKUP
  // ============================================================================

  /// Get all stored contacts for the current session.
  static Future<List<Contact>> getStoredContacts() async {
    if (PublicOS.sessionBlockchainAddress == null) return [];
    try {
      final rows = await PublicOS.database.getStoredContacts(
        PublicOS.sessionBlockchainAddress!,
      );
      return rows.map(DatabaseHelpers.contactFromRow).toList();
    } catch (e) {
      Log.e(_tag, '[STORED] Error: $e');
      return [];
    }
  }

  /// Get support contacts for the current session.
  static Future<List<Contact>> getSupportContacts() async {
    if (PublicOS.sessionBlockchainAddress == null) return [];
    try {
      final rows = await PublicOS.database.getSupportContacts(
        PublicOS.sessionBlockchainAddress!,
      );
      return rows.map(DatabaseHelpers.contactFromRow).toList();
    } catch (e) {
      Log.e(_tag, '[SUPPORT] Error: $e');
      return [];
    }
  }

  /// Local search by display name, publicos address, publicos display name,
  /// or any inbox ID / session address.
  static Future<Contact?> searchContacts(String query) async {
    if (PublicOS.sessionBlockchainAddress == null) return null;
    try {
      final row = await PublicOS.database.searchContact(
        query,
        PublicOS.sessionBlockchainAddress!,
      );
      if (row == null) return null;
      return DatabaseHelpers.contactFromRow(row);
    } catch (e) {
      Log.e(_tag, '[SEARCH] Error: $e');
      return null;
    }
  }

  /// Local **partial** search by name — what a search box wants.
  /// [searchContacts] above is exact-match, so a locally stored
  /// `pedroLopez.eth` never surfaces for `pedro`. Exact matches sort first,
  /// then prefix, then the rest; addresses and inbox IDs are not substring-
  /// matched (see the DB method).
  static Future<List<Contact>> searchContactsByName(String query,
      {int limit = 20}) async {
    if (PublicOS.sessionBlockchainAddress == null) return const [];
    final q = query.trim();
    if (q.isEmpty) return const [];
    try {
      final rows = await PublicOS.database.searchContactsLike(
        q,
        PublicOS.sessionBlockchainAddress!,
        limit: limit,
      );
      return rows.map(DatabaseHelpers.contactFromRow).toList();
    } catch (e) {
      Log.e(_tag, '[SEARCH-LIKE] Error: $e');
      return const [];
    }
  }

  /// Find a group-chat stub Contact by its XMTP conversation topic. Returns
  /// null if no stub exists yet (e.g. listGroups sync hasn't run or this
  /// client isn't in the group). Use `ensureGroupStub` to create one.
  static Future<Contact?> findContactByTopic(String topic) async {
    if (PublicOS.sessionBlockchainAddress == null) return null;
    try {
      final row = await PublicOS.database.getContactByTopic(
        topic,
        PublicOS.sessionBlockchainAddress!,
      );
      if (row == null) return null;
      return DatabaseHelpers.contactFromRow(row);
    } catch (e) {
      Log.e(_tag, '[FIND_BY_TOPIC] Error: $e');
      return null;
    }
  }

  /// Ensure a group-stub Contact exists for the given XMTP group conversation.
  /// Idempotent: creates on first sight, otherwise refreshes displayName /
  /// avatar record from the conversation's latest metadata while preserving
  /// any locally-added records (e.g. a user-customized color).
  ///
  /// Safe to call on every listGroups sync — see `PublicOSConversations`.
  static Future<Contact> ensureGroupStub({
    required String topic,
    required String groupName,
    String? groupImageUrl,
  }) async {
    final existing = await findContactByTopic(topic);
    if (existing == null) {
      final stub = Contact.groupStub(
        topic: topic,
        displayName: groupName.isNotEmpty ? groupName : 'Unnamed Group',
        imageUrl: groupImageUrl,
      );
      await saveContact(stub);
      return stub;
    }

    // Refresh: if the group's name on XMTP changed and the local stub still
    // matches what we previously stored, update. If the user renamed locally,
    // we assume the rename was also pushed to XMTP (see updateGroup), so the
    // two stay aligned. We only overwrite when the fresh value is non-empty.
    final records = [...existing.records];
    if (groupImageUrl != null && groupImageUrl.isNotEmpty) {
      records.removeWhere((r) => r.key == 'profile.avatar');
      records.add(Record.asProfile(
        key: 'profile.avatar',
        value: groupImageUrl,
      ));
    }
    final refreshed = existing.copyWith(
      displayName: groupName.isNotEmpty ? groupName : existing.displayName,
      records: records,
    );
    await saveContact(refreshed);
    return refreshed;
  }

  /// Find a locally stored contact whose `registeredInboxIDs` contains the
  /// given inbox ID. This is the view layer's primary resolution hook:
  /// given a conversation's `peerInboxId`, find the Contact to display.
  static Future<Contact?> findContactByInboxId(String inboxId) async {
    if (PublicOS.sessionBlockchainAddress == null) return null;
    final normalized = Contact.normalizeInboxId(inboxId);
    if (normalized == null) return null;
    try {
      final row = await PublicOS.database.getContactByRegisteredInboxId(
        normalized,
        PublicOS.sessionBlockchainAddress!,
      );
      if (row == null) return null;
      return DatabaseHelpers.contactFromRow(row);
    } catch (e) {
      Log.e(_tag, '[FIND_BY_INBOX] Error: $e');
      return null;
    }
  }

  /// Look up a contact by identifier. The identifier may be:
  ///   - A PublicOS display name ("alice")
  ///   - An Ethereum address (0x...)
  ///   - A 64-char hex XMTP inbox ID
  ///
  /// Resolution order:
  ///   1. Local match (any of the above)
  ///   2. On-chain: display name → account → fetchContact
  ///   3. On-chain: address → account → fetchContact
  ///   4. On-chain: inbox ID → account → fetchContact
  ///
  /// Returns null if nothing matches. Never creates a conversation.
  static Future<Contact?> resolveByIdentifier(String identifier) async {
    // 1. Local
    final local = await searchContacts(identifier);
    if (local != null && local.publicosAddress != null) {
      // Refresh from chain if possible, otherwise return local.
      if (PublicOS.web3Connected) {
        try {
          // requireRecords: ~10 callers persist what this returns. Failing to
          // the local copy beats handing them a blank-records contact to save.
          return await fetchContact(local.publicosAddress!,
              requireRecords: true);
        } catch (_) {
          return local;
        }
      }
      return local;
    }
    if (local != null) return local;

    if (!PublicOS.web3Connected) return null;

    // 2. Display name on chain
    try {
      final addr = await getPublicosAddressByPublicosDisplayName(identifier);
      if (addr != null &&
          addr != EthereumAddress.fromHex('0x0000000000000000000000000000000000000000')) {
        return await fetchContact(addr, requireRecords: true);
      }
    } catch (_) {}

    // 3. ETH address on chain
    if (identifier.startsWith('0x') && identifier.length == 42) {
      try {
        final addr = EthereumAddress.fromHex(identifier);
        final name = await getPublicosDisplayNameByAccountAddress(addr);
        if (name != null) return await fetchContact(addr, requireRecords: true);
      } catch (_) {}

      // 3b. ETH address might be a session address
      try {
        final sessionAddr = EthereumAddress.fromHex(identifier);
        final accountAddress = await getSessionOsuxId(sessionAddr.eip55With0x);
        if (accountAddress != null) {
          final publicosAddr = await getPublicosAddressByPublicosDisplayName(accountAddress);
          if (publicosAddr != null) {
            return await fetchContact(publicosAddr, requireRecords: true);
          }
        }
      } catch (_) {}
    }

    // 4. Inbox ID on chain
    if (identifier.length == 64 && !identifier.startsWith('0x')) {
      try {
        final bytes = StringToBytes(identifier);
        final addr = await PublicOSXmtp.getAccountAddressByInboxId(bytes);
        if (addr != null) return await fetchContact(addr, requireRecords: true);
      } catch (_) {}
    }

    return null;
  }

  /// Fetch a full PublicOS profile from chain for the given account address.
  /// Requires `web3Connected`. Throws on chain error.
  ///
  /// [requireRecords] — when true, a failed RECORDS read throws instead of
  /// silently yielding a contact with `records: []`. **Pass true from any caller
  /// that persists the result**, otherwise a transient RPC blip is written to
  /// the shared contacts row as "this profile has no records" (and stamped
  /// fresh, so it isn't re-read for `channelSetMaxAge`). Defaults to false so
  /// display-only callers keep today's degrade-gracefully behavior.
  static Future<Contact> fetchContact(
    EthereumAddress publicosAccountAddress, {
    bool forceMembership = false,
    bool requireRecords = false,
  }) async {
    try {
      // Self is ALWAYS persisted at the tail of this method, so self ALWAYS
      // needs the checked read — regardless of what the caller asked for.
      // Without this, every display-only fetch of your own profile is a
      // potential self-blanking write.
      final selfAddr = PublicOS.myPublicosAddress;
      final isSelf = selfAddr != null &&
          publicosAccountAddress.eip55With0x.toLowerCase() ==
              selfAddr.toLowerCase();

      final records = (requireRecords || isSelf)
          ? await getAllUserRecordsOrThrow(publicosAccountAddress)
          : await getAllUserRecords(publicosAccountAddress);
      final displayName = await getPublicosDisplayNameByAccountAddress(publicosAccountAddress);

      // All inbox IDs for this account
      List<InboxEntry>? registeredInboxIDs;
      try {
        final accountInboxIds = await PublicOSXmtp.getAllAccountInboxIds(publicosAccountAddress);
        if (accountInboxIds != null) {
          registeredInboxIDs = [];
          for (int i = 0; i < accountInboxIds.inboxIds.length; i++) {
            try {
              final inboxIdStr = bytes32ToString(accountInboxIds.inboxIds[i]);
              registeredInboxIDs.add(InboxEntry(
                inboxId: inboxIdStr,
                label: accountInboxIds.labels[i],
              ));
            } catch (e) {
              Log.e(_tag, '[fetchContact] Invalid inbox id at $i: $e');
            }
          }
        }
      } catch (e) {
        Log.w(_tag, '[fetchContact] Could not fetch registered inbox ids: $e');
      }

      // Org status
      bool isOrgAccount = false;
      String? createdBy;
      EthereumAddress? founderAddress;
      int? orgMemberCount;
      try {
        isOrgAccount = await PublicOSGovernance.isOrgAccount(publicosAccountAddress);
        if (isOrgAccount) {
          final creator = await PublicOSGovernance.getOrgCreator(publicosAccountAddress);
          if (creator != null &&
              creator != EthereumAddress.fromHex('0x0000000000000000000000000000000000000000')) {
            // Keep the address (immutable, persisted — the view resolves it)
            // as well as the displayName (kept for back-compat consumers).
            founderAddress = creator;
            createdBy = await getPublicosDisplayNameByAccountAddress(creator);
          }
          // Member count only — full member list is lazy via fetchOrgMembers()
          orgMemberCount = await _getOrgMemberCountSafe(publicosAccountAddress);
        }
      } catch (e) {
        Log.w(_tag, '[fetchContact] Org status check failed: $e');
      }

      var contact = Contact(
        displayName: displayName ?? publicosAccountAddress.eip55With0x,
        publicosDisplayName: displayName,
        publicosAddress: publicosAccountAddress,
        isOrgAccount: isOrgAccount,
        records: records,
        registeredInboxIDs: registeredInboxIDs,
        orgMemberCount: orgMemberCount,
        createdBy: createdBy,
        founderAddress: founderAddress,
      );

      // Enrichment — UNIFORM for every contact. Lifted out of the presentation
      // widget (GlassContactIcon) so the data layer hands every surface a
      // complete, already-verified Contact: the class membership flag
      // (isCitizen / isPublicOrg) and the NFT-avatar verdict. Both reuse the
      // persisted DB row when it's still valid (membership has no TTL — it's
      // durable; the NFT verdict re-verifies on a pointer change or 7-day
      // expiry) and resave only when they recompute, so warm reads do no extra
      // work. fetchContact is therefore a writer on (re)compute — consistent
      // with the existing setRecord write-through.
      final prior = await getContact(publicosAccountAddress);
      contact = await _resolveMembership(contact, prior, force: forceMembership);
      contact = await _resolveAndVerifyNft(contact, prior);
      contact = await _resolveAndVerifyNftBanner(contact, prior);
      contact = await _resolveAndVerifyNftCards(contact, prior);
      contact = await _resolveAndVerifyAppCards(contact);

      // SELF only: persist the full fresh row and emit it once on the root
      // stream so the live self-surfaces (explorer icon, wallet card, browser
      // self-header) repaint. Other contacts refresh lazily on their next
      // fetch; the verdict they need is already persisted above.
      if (isSelf) {
        await saveContact(contact);
        // Record self's current NFT avatar (EVM or Solana) into the per-session
        // used-avatar history so the sheet's quick-pick grids can surface it.
        // The verdict was just computed by _resolveAndVerifyNft.
        final verdict = contact.verifiedNftAvatarData;
        if (verdict != null) {
          await recordUsedNftAvatar(
            verdict.pointer,
            imageUrl: verdict.imageUrl,
            verifiedOwnership: verdict.verifiedOwnership,
            checkedAt: verdict.checkedAt,
          );
        }
        // Same for the NFT banner — its pointer joins the quick-pick pool
        // so a banner NFT shows up in the picker's "Previously used" grid too.
        final bannerVerdict = contact.verifiedNftBannerData;
        if (bannerVerdict != null) {
          await recordUsedNftAvatar(
            bannerVerdict.pointer,
            imageUrl: bannerVerdict.imageUrl,
            verifiedOwnership: bannerVerdict.verifiedOwnership,
            checkedAt: bannerVerdict.checkedAt,
          );
        }
        // Same for every NFT used as a profile card — each one joins the
        // quick-pick pool too, so a card NFT shows up in the picker's
        // "Previously used" grid alongside avatar/banner NFTs. The per-card
        // verdict was just computed by _resolveAndVerifyNftCards and lives in
        // each record's metadata; only record cards that actually resolved
        // (nftCheckedAt present → a verdict was produced, not a bad pointer).
        for (final r in contact.records) {
          if (r.metadata['cardKind'] != 'nft') continue;
          final checkedMs = (r.metadata['nftCheckedAt'] as num?)?.toInt();
          if (checkedMs == null) continue;
          final cardRef = NftAvatarRef.tryParse(r.value);
          if (cardRef == null) continue;
          await recordUsedNftAvatar(
            cardRef,
            imageUrl: r.metadata['nftImage'] as String?,
            verifiedOwnership: r.metadata['nftOwned'] == true,
            checkedAt: DateTime.fromMillisecondsSinceEpoch(checkedMs),
          );
        }
        PublicOS.emitSelfContactUpdate(
            await getContact(publicosAccountAddress) ?? contact);
      }
      return contact;
    } catch (e) {
      Log.e(_tag, '[fetchContact] Error: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // CONTACT ENRICHMENT (lifted from GlassContactIcon — see fetchContact)
  // Verify-at-fetch: resolution + ownership verification + membership now run
  // here, uniformly for every contact, so the icon is purely presentational.
  // ===========================================================================

  /// NFT-verdict TTL. A cached verdict whose pointer still matches and that is
  /// within this window is reused with no network / chain call.
  static const Duration _nftTtl = Duration(days: 7);

  /// False when a cached image [url] is an IPFS path on a gateway that is no
  /// longer in [ipfsGateways] (e.g. a cached `ipfs.io` URL):
  /// the verdict is treated as stale and re-resolved once, instead of showing
  /// a dead image for the rest of its TTL.
  static bool _imageOnLiveGateway(Object? url) {
    if (url is! String || _ipfsPath(url) == null) return true;
    return ipfsGateways.any(url.startsWith);
  }

  /// Resolve the class-relevant membership flag (isCitizen for individuals,
  /// isPublicOrg for orgs), reusing the persisted [prior] value when present
  /// (no TTL — citizenship / public-org status is durable) and persisting on a
  /// fresh compute (uniform cache, restart-surviving). Returns [c] with the
  /// flag set; on any chain error leaves it null (→ no badge) without failing
  /// the fetch.
  ///
  /// Pass [force] to bypass the [prior] cache and always re-read the flag from
  /// chain. Citizenship/public-org status is durable but not immutable (a user
  /// can be vouched in or out), so surfaces that must reflect the latest status
  /// — e.g. onboarding's provider steps — force a fresh read.
  static Future<Contact> _resolveMembership(
    Contact c,
    Contact? prior, {
    bool force = false,
  }) async {
    final acct = c.publicosAddress;
    if (acct == null) return c;
    try {
      if (c.isOrgAccount) {
        if (!force && prior?.isPublicOrg != null) {
          return c.copyWith(isPublicOrg: prior!.isPublicOrg);
        }
        final v = await PublicOSGovernance.isPublicOrg(acct);
        final updated = c.copyWith(isPublicOrg: v);
        try {
          await saveContact(updated);
        } catch (_) {}
        return updated;
      }
      if (!force && prior?.isCitizen != null) {
        return c.copyWith(isCitizen: prior!.isCitizen);
      }
      final v = await PublicOSAccounts.isCitizen(acct);
      final updated = c.copyWith(isCitizen: v);
      try {
        await saveContact(updated);
      } catch (_) {}
      return updated;
    } catch (_) {
      return c;
    }
  }

  /// Resolve the NFT-avatar metadata + ownership verdict for [c]. Reuses the
  /// [prior] cached verdict when its pointer matches and it's [_nftTtl]-fresh
  /// (no work); otherwise (re)resolves metadata, re-verifies ownership,
  /// persists the verdict (uniform cache), and returns the updated Contact.
  /// No-op when there's no `profile.avatar.nft` pointer.
  static Future<Contact> _resolveAndVerifyNft(Contact c, Contact? prior) async {
    final ref = c.nftAvatar;
    if (ref == null) return c;
    final acct = c.publicosAddress;
    if (acct == null) return c;

    final cached = prior?.verifiedNftAvatarData;
    if (cached != null && cached.matches(ref) && cached.isFresh(_nftTtl) &&
        _imageOnLiveGateway(cached.metadata['image'])) {
      return c.copyWith(verifiedNftAvatar: cached.encode());
    }

    final meta = ref.isSolana
        ? await PublicOSWallets.resolveSolanaNftData(ref.mint!)
        : await resolveNftAvatarData(ref);
    if (meta == null) return c; // bad pointer / unsupported chain → fallback URL

    final owned = await verifyNftOwnership(ref, acct);
    final verdict = VerifiedNftAvatar(
      pointer: ref,
      metadata: meta,
      verifiedOwnership: owned,
      checkedAt: DateTime.now(),
    );
    final verified = c.copyWith(verifiedNftAvatar: verdict.encode());
    try {
      await saveContact(verified);
    } catch (_) {}
    return verified;
  }

  /// Banner analog of [_resolveAndVerifyNft] — resolves `profile.banner.nft`
  /// and verifies ownership into the [verifiedNftBanner] column. Same TTL,
  /// same cache reuse, same persist-on-recompute. No-op when there's no
  /// `profile.banner.nft` pointer. The `NftBanner` widget reads the verdict
  /// this writes; it never recomputes on the render path.
  static Future<Contact> _resolveAndVerifyNftBanner(
      Contact c, Contact? prior) async {
    final ref = c.nftBanner;
    if (ref == null) return c;
    final acct = c.publicosAddress;
    if (acct == null) return c;

    final cached = prior?.verifiedNftBannerData;
    if (cached != null && cached.matches(ref) && cached.isFresh(_nftTtl) &&
        _imageOnLiveGateway(cached.metadata['image'])) {
      return c.copyWith(verifiedNftBanner: cached.encode());
    }

    final meta = ref.isSolana
        ? await PublicOSWallets.resolveSolanaNftData(ref.mint!)
        : await resolveNftAvatarData(ref);
    if (meta == null) return c; // bad pointer / unsupported chain → fallback URL

    final owned = await verifyNftOwnership(ref, acct);
    final verdict = VerifiedNftAvatar(
      pointer: ref,
      metadata: meta,
      verifiedOwnership: owned,
      checkedAt: DateTime.now(),
    );
    final verified = c.copyWith(verifiedNftBanner: verdict.encode());
    try {
      await saveContact(verified);
    } catch (_) {}
    return verified;
  }

  /// Card analog of [_resolveAndVerifyNft] — for every NFT card record
  /// (`metadata['cardKind'] == 'nft'`) the contact carries, resolve the art and
  /// verify ownership **against the record owner** ([c.publicosAddress], same as
  /// avatar/banner — never the viewer), then stash the verdict in that record's
  /// own metadata (`nftImage` / `nftOwned` / `nftCheckedAt`, plus the full
  /// [VerifiedNftAvatar] verdict under `nftVerified` — same payload the
  /// avatar/banner columns hold, so the NFT info dialog renders cards as richly
  /// as avatars). Per-record so it scales to N cards with no extra column.
  /// Reuses a [prior] verdict when its pointer is unchanged and it's
  /// [_nftTtl]-fresh; persists only on recompute. `RecordButton` reads this
  /// metadata purely presentationally.
  /// Resolve and verify every **app card** (`cardKind == 'app'`) the contact
  /// carries, stamping the verdict into each record's own metadata so the
  /// widget layer stays purely presentational -- the same shape
  /// [_resolveAndVerifyNftCards] uses for `nftImage`/`nftOwned`.
  ///
  /// The walk, per distinct app (see the web_card spec, section 04):
  ///   1. parse the record value             -> [AppCardRef.tryParse]
  ///   2. `getAppOwner(slug)`                -> registered at all?
  ///   3. `getAppPointer(slug,'card_origin')`-> the declared prefix
  ///   4. image is under the prefix          -> else `broken`
  ///   5. live is under the prefix           -> else `imageOnly`
  ///
  /// What it proves is **authorship**, never possession: a registered app owned
  /// by a nameable citizen declared this URL space as its own. It says nothing
  /// about whether the card belongs to the profile displaying it, which is why
  /// nothing here stamps an ownership badge.
  ///
  /// **No verdict cache, deliberately.** The NFT resolver reuses a prior verdict
  /// for 7 days to avoid per-icon chain reads. Doing that here would make
  /// `card_origin` -- the entire revocation surface -- take a week to bite, and
  /// revocation latency IS the feature. Cost is bounded instead by memoising
  /// within a single pass, so a profile carrying N cards from one app does two
  /// reads, not 2N. Revisit only if profile-fetch latency actually shows it.
  static Future<Contact> _resolveAndVerifyAppCards(Contact c) async {
    final hasAny =
        c.records.any((r) => r.metadata['cardKind'] == _kAppCardKind);
    if (!hasAny) return c;

    // slug -> (owner, cardOrigin); one entry per app, for this pass only.
    final resolved = <String, (EthereumAddress?, String?)>{};

    final out = <Record>[];
    for (final r in c.records) {
      if (r.metadata['cardKind'] != _kAppCardKind) {
        out.add(r);
        continue;
      }

      final ref = AppCardRef.tryParse(r.value);
      if (ref == null) {
        out.add(_stampAppCard(r, AppCardVerdict.broken, null, null));
        continue;
      }

      if (!resolved.containsKey(ref.app)) {
        final owner = await PublicOSAppRegistry.getAppOwnerBySlug(ref.app);
        final origin = owner == null
            ? null
            : await PublicOSAppRegistry.getPointerBySlug(ref.app, 'card_origin');
        resolved[ref.app] = (owner, origin);
      }
      final (owner, originRaw) = resolved[ref.app]!;

      out.add(_stampAppCard(
          r, _appCardVerdict(ref, owner, originRaw), ref, originRaw));
    }

    return c.copyWith(records: out);
  }

  static const String _kAppCardKind = 'app';

  /// The verdict ladder. Split out so it is readable in one screen and so the
  /// image/live asymmetry is explicit: a bad **image** is `broken` (the app is
  /// accountable for everything the card shows), a bad **live** is only
  /// `imageOnly` (the picture the owner chose still stands).
  static AppCardVerdict _appCardVerdict(
      AppCardRef ref, EthereumAddress? owner, String? originRaw) {
    if (owner == null) return AppCardVerdict.imageOnly; // app left the registry
    if (originRaw == null || originRaw.isEmpty) {
      return AppCardVerdict.imageOnly; // pointer dropped -> revoked, gracefully
    }
    final origin = Uri.tryParse(originRaw);
    if (origin == null) return AppCardVerdict.imageOnly;

    if (!AppCardRef.isUnder(ref.image, origin)) return AppCardVerdict.broken;
    if (ref.live == null || !AppCardRef.isUnder(ref.live!, origin)) {
      return AppCardVerdict.imageOnly;
    }
    return ref.isSupportedVersion
        ? AppCardVerdict.ok
        : AppCardVerdict.imageOnly;
  }

  static Record _stampAppCard(
      Record r, AppCardVerdict v, AppCardRef? ref, String? origin) {
    return r.copyWith(metadata: {
      ...r.metadata,
      AppCardMeta.verdict: v.name,
      AppCardMeta.checkedAt: DateTime.now().millisecondsSinceEpoch,
      if (ref != null) AppCardMeta.appSlug: ref.app,
      // Only on `ok` — the frame this feeds is only ever built for `ok`, and a
      // stamped origin on any other verdict would be a trust token attached to
      // a card the walk did not clear.
      if (v == AppCardVerdict.ok && origin != null)
        AppCardMeta.origin: origin,
      // The card wanted a live half and did not get one -- as opposed to never
      // having asked for one, which is a complete card and not a fault.
      if (ref?.live != null && v != AppCardVerdict.ok)
        AppCardMeta.degraded: true,
      // Only surface URLs the walk actually cleared. A `broken` card must not
      // hand the renderer an image it just refused.
      if (ref != null && v != AppCardVerdict.broken)
        AppCardMeta.image: ref.image.toString(),
      if (ref != null && v == AppCardVerdict.ok && ref.live != null)
        AppCardMeta.live: ref.live.toString(),
    });
  }

  static Future<Contact> _resolveAndVerifyNftCards(
      Contact c, Contact? prior) async {
    final acct = c.publicosAddress;
    if (acct == null) return c;

    final priorByKey = <String, Record>{};
    if (prior != null) {
      for (final r in prior.records) {
        if (r.metadata['cardKind'] == 'nft') priorByKey[r.key] = r;
      }
    }

    bool anyCard = false;
    bool recomputed = false;
    final out = <Record>[];
    for (final r in c.records) {
      if (r.metadata['cardKind'] != 'nft') {
        out.add(r);
        continue;
      }
      final ref = NftAvatarRef.tryParse(r.value);
      if (ref == null) {
        out.add(r);
        continue;
      }
      anyCard = true;

      // Reuse a fresh prior verdict (same pointer, within TTL) — no chain call.
      // A prior that predates the `nftVerified` full-verdict cache (cached by an
      // older build) is intentionally NOT reused: falling through recomputes
      // once to backfill `nftVerified`, so the NFT info dialog goes rich without
      // waiting out the 7-day TTL.
      final p = priorByKey[r.key];
      final pCheckedMs = (p?.metadata['nftCheckedAt'] as num?)?.toInt();
      if (p != null &&
          p.value == r.value &&
          pCheckedMs != null &&
          p.metadata['nftVerified'] != null &&
          _imageOnLiveGateway(p.metadata['nftImage']) &&
          DateTime.now().difference(
                  DateTime.fromMillisecondsSinceEpoch(pCheckedMs)) <
              _nftTtl) {
        out.add(r.copyWith(metadata: {
          ...r.metadata,
          if (p.metadata['nftImage'] != null)
            'nftImage': p.metadata['nftImage'],
          'nftOwned': p.metadata['nftOwned'] == true,
          'nftCheckedAt': pCheckedMs,
          if (p.metadata['nftVerified'] != null)
            'nftVerified': p.metadata['nftVerified'],
        }));
        continue;
      }

      final meta = ref.isSolana
          ? await PublicOSWallets.resolveSolanaNftData(ref.mint!)
          : await resolveNftAvatarData(ref);
      if (meta == null) {
        out.add(r);
        continue;
      }
      final img = (meta['image'] ?? meta['image_url']) as String?;
      final owned = await verifyNftOwnership(ref, acct);
      // Stash the full verdict (pointer + metadata + ownership) so the NFT info
      // dialog can render the card with name/traits/links, same as avatar/banner.
      final verdict = VerifiedNftAvatar(
        pointer: ref,
        metadata: meta,
        verifiedOwnership: owned,
        checkedAt: DateTime.now(),
      );
      out.add(r.copyWith(metadata: {
        ...r.metadata,
        if (img != null) 'nftImage': img,
        'nftOwned': owned,
        'nftCheckedAt': verdict.checkedAt.millisecondsSinceEpoch,
        'nftVerified': verdict.encode(),
      }));
      recomputed = true;
    }

    if (!anyCard) return c;
    final updated = c.copyWith(records: out);
    if (recomputed) {
      try {
        await saveContact(updated);
      } catch (_) {}
    }
    return updated;
  }

  /// Propagate a freshly-refreshed ownership verdict into the **self** contact's
  /// verdict cache — the [verifiedNftAvatar] / [verifiedNftBanner] columns and
  /// any matching `cardKind == 'nft'` record metadata that the *rendered*
  /// profile reads. The avatar/banner picker's manual Refresh writes only its
  /// own `used_nft_avatars` history (the grid's shimmer); without this the two
  /// stores drift, so refreshing the tile that happens to be your current
  /// avatar/banner/card never updated the live profile badge. This closes that
  /// gap by mirroring the same [VerifiedNftAvatar] payload [_resolveAndVerifyNft]
  /// writes, reusing the [metadata] + [owned] the picker already computed — no
  /// extra RPC.
  ///
  /// No-op when [metadata] didn't resolve (don't clobber a good verdict with a
  /// blank — same guard as [_resolveAndVerifyNft]) or when [ref] isn't any of
  /// the self contact's current avatar/banner/card pointers. Scoped to the
  /// active session's self-contact via [getContact]; persists at most one
  /// [saveContact].
  static Future<void> syncSelfNftVerdict(
    EthereumAddress account,
    NftAvatarRef ref, {
    required Map<String, dynamic>? metadata,
    required bool owned,
  }) async {
    if (metadata == null) return;
    final c = await getContact(account);
    if (c == null) return;

    final verdict = VerifiedNftAvatar(
      pointer: ref,
      metadata: metadata,
      verifiedOwnership: owned,
      checkedAt: DateTime.now(),
    );

    Contact updated = c;
    bool changed = false;

    final av = c.nftAvatar;
    if (av != null && av.samePointer(ref)) {
      updated = updated.copyWith(verifiedNftAvatar: verdict.encode());
      changed = true;
    }

    final bn = c.nftBanner;
    if (bn != null && bn.samePointer(ref)) {
      updated = updated.copyWith(verifiedNftBanner: verdict.encode());
      changed = true;
    }

    // NFT card records carry their verdict inline in their own metadata.
    final img = (metadata['image'] ?? metadata['image_url']) as String?;
    bool cardTouched = false;
    final out = <Record>[];
    for (final r in updated.records) {
      if (r.metadata['cardKind'] == 'nft') {
        final cardRef = NftAvatarRef.tryParse(r.value);
        if (cardRef != null && cardRef.samePointer(ref)) {
          out.add(r.copyWith(metadata: {
            ...r.metadata,
            if (img != null) 'nftImage': img,
            'nftOwned': owned,
            'nftCheckedAt': verdict.checkedAt.millisecondsSinceEpoch,
            'nftVerified': verdict.encode(),
          }));
          cardTouched = true;
          continue;
        }
      }
      out.add(r);
    }
    if (cardTouched) {
      updated = updated.copyWith(records: out);
      changed = true;
    }

    if (!changed) return;
    try {
      await saveContact(updated);
    } catch (e) {
      Log.e(_tag, 'syncSelfNftVerdict error: $e');
    }
  }

  /// Does the NFT [ref] resolve to an address [acct] owns? The owned set is
  /// `sessions ∪ on-chain-verified EVM WalletDirectory wallets` (main Safe
  /// included) via [PublicOSWallets.ownedAddresses]. ERC-1155 checks `balanceOf`
  /// over that set; ERC-721 checks `ownerOf` membership, with a SafeMemory
  /// owner-account fallback for any registered Safe. Solana dispatches to the
  /// link-verified SPL-ownership path.
  ///
  /// Public so the avatar-sheet quick-pick grids can re-verify a cached
  /// [UsedNftAvatar] row whose verdict has aged past its TTL and refresh the
  /// shimmer state without a full `fetchContact`.
  static Future<bool> verifyNftOwnership(
      NftAvatarRef ref, EthereumAddress acct) async {
    if (ref.isSolana) return _verifySolanaNftOwnership(ref, acct);
    try {
      final owned = await PublicOSWallets.ownedAddresses(acct);
      if (ref.isErc1155) {
        for (final a in owned) {
          if (await nftBalanceOf(ref, a) > BigInt.zero) return true;
        }
        return false;
      }
      final owner = await nftOwnerOf(ref);
      if (owner == null) return false;
      final ownerHex = owner.eip55With0x.toLowerCase();
      if (owned.any((a) => a.eip55With0x.toLowerCase() == ownerHex)) return true;
      final safeOwner = await PublicOSSafe.getSafeOwnerAccount(owner);
      if (safeOwner != null && safeOwner == acct) return true;
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Solana ownership: does any of the account's linked **and link-verified**
  /// Solana wallets currently hold the [ref] mint? The chain stores Solana
  /// entries CLAIMED, so re-verify the ed25519 link proof before trusting a
  /// wallet, then check on-chain SPL ownership.
  static Future<bool> _verifySolanaNftOwnership(
      NftAvatarRef ref, EthereumAddress acct) async {
    final mint = ref.mint;
    if (mint == null) return false;
    try {
      final wallets = await PublicOSWallets.getWallets(acct);
      for (final w in wallets) {
        if (w.protocol != PublicOSWallets.protoSolana) continue;
        if (!PublicOSWallets.verifySolanaWalletLink(account: acct, wallet: w)) {
          continue;
        }
        final ownerB58 = utf8.decode(w.addressData); // non-EVM: utf8 of base58
        if (await PublicOSWallets.accountOwnsSolanaMint(ownerB58, mint)) {
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ===========================================================================
  // USED NFT AVATARS (per-session "seen as owned" history)
  // Backs the avatar sheet's "Previously used" (EVM) and "Pick mine or used"
  // (Solana) quick-pick grids. EVM has no on-chain enumeration, so this local
  // history is the only way to surface "my" EVM NFTs; Solana also persists its
  // live-enumerated mints here so the two sources can be merged + deduped.
  // ===========================================================================

  /// Canonical CAIP-2 chain-id → human label. Single source for both the
  /// avatar sheet's chain dropdown and the used-avatar corner badge.
  static const Map<int, String> nftChainNames = {
    4489: 'PublicOS',
    1: 'Ethereum',
    10: 'Optimism',
    137: 'Polygon',
    8453: 'Base',
    42161: 'Arbitrum',
    999: 'HyperEVM',
  };

  /// Human label for an NFT pointer's chain (Solana → 'Solana').
  static String nftChainLabel(NftAvatarRef ref) =>
      ref.isSolana ? 'Solana' : (nftChainNames[ref.chain] ?? 'Chain ${ref.chain}');

  /// Read the current session's used-NFT-avatar history, most-recent first.
  /// Pass [namespace] (`'eip155'` / `'solana'`) to scope to one chain family.
  static Future<List<db.UsedNftAvatarRow>> getUsedNftAvatars(
      {String? namespace}) async {
    if (PublicOS.sessionBlockchainAddress == null) return [];
    try {
      return await PublicOS.database.getUsedNftAvatars(
        PublicOS.sessionBlockchainAddress!,
        namespace: namespace,
      );
    } catch (e) {
      Log.e(_tag, 'getUsedNftAvatars error: $e');
      return [];
    }
  }

  /// Upsert one NFT into the used-avatar history with a freshly-known verdict.
  /// Called from [fetchContact] (self's current avatar) and the Solana grid
  /// (each live-enumerated owned mint). No-op without an active client.
  static Future<void> recordUsedNftAvatar(
    NftAvatarRef ref, {
    String? imageUrl,
    required bool verifiedOwnership,
    DateTime? checkedAt,
  }) async {
    final session = PublicOS.sessionBlockchainAddress;
    if (session == null) return;
    final now = DateTime.now();
    try {
      await PublicOS.database.insertUsedNftAvatar(
        pointerKey: ref.toCaip19(),
        namespace: ref.namespace,
        chain: ref.chain,
        standard: ref.standard,
        contract: ref.contract,
        tokenId: ref.tokenId,
        mint: ref.mint,
        imageUrl: imageUrl,
        chainName: nftChainLabel(ref),
        owner: ref.owner,
        verifiedOwnership: verifiedOwnership,
        checkedAt: (checkedAt ?? now).millisecondsSinceEpoch,
        sessionAddress: session,
        lastSeenAt: now.millisecondsSinceEpoch,
      );
    } catch (e) {
      Log.e(_tag, 'recordUsedNftAvatar error: $e');
    }
  }

  /// Delete one NFT from the current session's used-avatar history (the picker
  /// grid's "remove from recents"). Only clears the persisted history row —
  /// a live-enumerated Solana holding re-appears on the next grid load, which
  /// is why the picker doesn't offer removal for those tiles.
  static Future<void> removeUsedNftAvatar(NftAvatarRef ref) async {
    final session = PublicOS.sessionBlockchainAddress;
    if (session == null) return;
    try {
      await PublicOS.database.deleteUsedNftAvatar(
        pointerKey: ref.toCaip19(),
        sessionAddress: session,
      );
    } catch (e) {
      Log.e(_tag, 'removeUsedNftAvatar error: $e');
    }
  }

  /// Rebuild an [NftAvatarRef] from a stored used-avatar row.
  static NftAvatarRef refFromUsedRow(db.UsedNftAvatarRow row) =>
      row.namespace == 'solana'
          ? NftAvatarRef.solana(mint: row.mint ?? '', owner: row.owner)
          : NftAvatarRef(
              chain: row.chain,
              standard: row.standard,
              contract: row.contract,
              tokenId: row.tokenId,
              owner: row.owner,
            );

  /// Get the profile for an inbox ID **without** creating a DM.
  /// Used by the view when rendering a group member or an unknown DM peer.
  /// If the inbox is linked to a PublicOS account, returns the full profile.
  /// Otherwise returns a minimal stub with the ETH addresses extracted from
  /// inbox state.
  static Future<Contact?> findContactInfoOnly(String inboxId) async {
    final normalized = Contact.normalizeInboxId(inboxId);
    if (normalized == null) return null;

    // 1. Local hit
    final local = await findContactByInboxId(normalized);
    if (local != null) return local;

    // 2. Try chain: inbox ID → PublicOS account
    if (PublicOS.web3Connected) {
      try {
        final bytes = StringToBytes(normalized);
        final addr = await PublicOSXmtp.getAccountAddressByInboxId(bytes);
        if (addr != null &&
            addr != EthereumAddress.fromHex('0x0000000000000000000000000000000000000000')) {
          final contact = await fetchContact(addr, requireRecords: true);
          await saveContact(contact);
          return contact;
        }
      } catch (e) {
        Log.d(_tag, '[FIND_INFO] Inbox → account lookup failed: $e');
      }
    }

    // 3. Fall back to XMTP inbox state for a minimal stub
    if (PublicOS.xmtpConnected) {
      try {
        final states = await PublicOSXmtp.getInboxStates([normalized], refreshFromNetwork: true);
        if (states == null || states.isEmpty) return null;

        final addresses = _extractAddressesFromInboxState(states.first);
        final sessionsList = <ContactSession>[];
        for (int i = 0; i < addresses.length; i++) {
          try {
            sessionsList.add(ContactSession(
              address: EthereumAddress.fromHex(addresses[i]),
              label: i == 0 ? 'recovery' : 'identity_$i',
            ));
          } catch (e) {
            Log.e(_tag, '[FIND_INFO] Invalid address ${addresses[i]}: $e');
          }
        }

        final stub = Contact(
          displayName: _shortInboxId(normalized),
          sessions: sessionsList.isNotEmpty ? sessionsList : null,
          // EMPTY label, not a made-up one: a peer with no
          // PublicOS account has no inbox directory, so there IS no label to
          // store. Every renderer already falls back on an empty label (the
          // profile's chat tabs show "Chat"); a placeholder like 'unknown' is
          // a non-empty string, so it would defeat that fallback and print
          // literally as the tab name.
          registeredInboxIDs: [InboxEntry(inboxId: normalized, label: '')],
          records: [
            Record.asSettings(
              key: 'xmtp_sessions_resolve_after',
              value: DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
              isSystem: true,
            ),
          ],
        );
        await saveContact(stub);
        return stub;
      } catch (e) {
        Log.e(_tag, '[FIND_INFO] Inbox state fetch failed: $e');
      }
    }

    return null;
  }

  // ============================================================================
  // SECTION 3: RESOLUTION
  // ============================================================================

  /// Enrich a contact with data from on-chain + XMTP + ENS.
  /// Stage 1: If it has an inbox ID, check if it maps to a PublicOS account.
  /// Stage 2: If it's not a PublicOS contact, extract ETH addresses from
  ///          its inbox state (sessions).
  /// Stage 3: If it has sessions, try ENS/Farcaster resolution.
  /// PublicOS contacts skip stages 2–3.
  static Future<Contact> resolveContact(Contact contact, {bool forceResolve = false}) async {
    // PublicOS contacts are already resolved by fetchContact
    if (contact.publicosAddress != null) {
      if (forceResolve && PublicOS.web3Connected) {
        try {
          final fresh =
              await fetchContact(contact.publicosAddress!, requireRecords: true);
          await saveContact(fresh);
          return fresh;
        } catch (e) {
          // Falls back to the caller's copy — which is exactly right, and only
          // reachable now that a failed records read actually throws.
          Log.w(_tag, '[RESOLVE] Could not refresh PublicOS contact: $e');
          return contact;
        }
      }
      return contact;
    }

    // Non-PublicOS: has at least one registered inbox?
    final firstInboxId = contact.registeredInboxIDs?.firstOrNull?.inboxId;
    if (firstInboxId == null) return contact;

    // Stage 1: Check if inbox links to a PublicOS account
    var updated = await resolveInboxIdToPublicOSAccount(contact, force: forceResolve);
    if (updated.publicosAddress != null) return updated;

    // Stage 2: sessions
    updated = await resolveSessions(updated, force: forceResolve);

    // Stage 3: identity
    updated = await resolveIdentity(updated, force: forceResolve);

    return updated;
  }

  /// Stage 1: Check if the contact's first registered inbox ID maps to a
  /// registered PublicOS account. If yes, replace the contact with the full
  /// PublicOS profile. Cache: 1 hour.
  static Future<Contact> resolveInboxIdToPublicOSAccount(Contact contact, {bool force = false}) async {
    final inboxId = contact.registeredInboxIDs?.firstOrNull?.inboxId;
    if (inboxId == null) return contact;
    if (!PublicOS.web3Connected) return contact;
    if (!force && !PublicOSXmtp.shouldResolveAccountAddress(contact)) return contact;

    try {
      final bytes = StringToBytes(inboxId);
      final accountAddress = await PublicOSXmtp.getAccountAddressByInboxId(
        bytes,
        existingContact: contact,
        forceRefresh: true,
      );

      if (accountAddress != null &&
          accountAddress != EthereumAddress.fromHex('0x0000000000000000000000000000000000000000')) {
        final publicosContact =
            await fetchContact(accountAddress, requireRecords: true);
        final withCache = addResolveAfterRecord(
          publicosContact,
          'inbox_account_resolve_after',
          const Duration(hours: 1),
        );
        await saveContact(withCache);
        return withCache;
      } else {
        final updated = addResolveAfterRecord(contact, 'inbox_account_resolve_after', const Duration(hours: 1));
        await saveContact(updated);
        return updated;
      }
    } catch (e) {
      Log.e(_tag, '[RESOLVE_ACCOUNT] $e');
      return contact;
    }
  }

  /// Stage 2: Fetch XMTP inbox state and extract ETH addresses into `sessions`.
  /// Cache: 1 hour.
  static Future<Contact> resolveSessions(Contact contact, {bool force = false}) async {
    final inboxId = contact.registeredInboxIDs?.firstOrNull?.inboxId;
    if (inboxId == null) return contact;
    if (!PublicOS.xmtpConnected) return contact;
    if (!force && !needsSessions(contact)) return contact;

    try {
      final states = await PublicOSXmtp.getInboxStates([inboxId]);
      if (states == null || states.isEmpty) return contact;

      final addresses = _extractAddressesFromInboxState(states.first);
      if (addresses.isEmpty) return contact;

      final xmtpSessions = <ContactSession>[];
      for (int i = 0; i < addresses.length; i++) {
        try {
          xmtpSessions.add(ContactSession(
            address: EthereumAddress.fromHex(addresses[i]),
            label: i == 0 ? 'recovery' : 'identity_$i',
          ));
        } catch (e) {
          Log.e(_tag, '[RESOLVE_CLIENTS] Bad address ${addresses[i]}: $e');
        }
      }

      final updatedRecords = List<Record>.from(contact.records)
        ..removeWhere((r) => r.key == 'xmtp_sessions_resolve_after')
        ..add(Record.asSettings(
          key: 'xmtp_sessions_resolve_after',
          value: DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
          isSystem: true,
        ));

      final updated = contact.copyWith(
        records: updatedRecords,
        sessions: xmtpSessions.isNotEmpty ? xmtpSessions : null,
      );
      await saveContact(updated);
      return updated;
    } catch (e) {
      Log.e(_tag, '[RESOLVE_CLIENTS] $e');
      return contact;
    }
  }

  /// Stage 3: Resolve ENS/Farcaster identity for the contact's sessions.
  /// Cache: 24h on success, 1h on failure.
  static Future<Contact> resolveIdentity(Contact contact, {bool force = false}) async {
    if (!PublicOS.web3Connected) return contact;
    if (!force && !needsIdentity(contact)) return contact;
    if (contact.sessions == null || contact.sessions!.isEmpty) return contact;

    try {
      for (final c in contact.sessions!) {
        final ensData = await resolveAddressToENS(c.address.eip55With0x);
        if (ensData == null || ensData['name'] == null) continue;

        Log.i(_tag, '[RESOLVE_IDENTITY] ENS: ${ensData['name']}');
        final updatedRecords = List<Record>.from(contact.records);

        // Avatar
        if (ensData['avatar'] != null) {
          updatedRecords.removeWhere((r) => r.key == 'profile.avatar' || r.key == 'profile.avatar.resolved');
          updatedRecords.add(Record.asSettings(
            key: 'profile.avatar',
            value: ensData['avatar']!,
            isSystem: true,
          ));
          if (ensData['avatar']!.startsWith('eip155:')) {
            final resolved = await resolveNftAvatarUri(ensData['avatar']!);
            if (resolved != null) {
              updatedRecords.add(Record.asSettings(
                key: 'profile.avatar.resolved',
                value: resolved,
                isSystem: true,
              ));
            }
          }
        }

        // Bio
        if (ensData['bio'] != null && ensData['bio']!.isNotEmpty) {
          updatedRecords.removeWhere((r) => r.profileSubtype == ProfileSubtype.text);
          updatedRecords.add(Record.asProfile(
            key: 'profile.bio',
            value: ensData['bio']!,
            isExpired: false,
            icon: Icons.person_rounded.codePoint,
            customMetadataAttributes: {
              'bioTextColor': Colors.white.value,
              'bioBorderVisible': false,
              'bioBorderColor': Colors.grey.shade300.value,
              'bioBorderWidth': 1.0,
              'borderRadius': 8.0,
            },
            alignment: 'left',
            opacity: 1.0,
          ));
        }

        // ENS source flag
        updatedRecords.removeWhere((r) => r.key == 'ens_source');
        updatedRecords.add(Record.asSettings(
          key: 'ens_source',
          value: ensData['source'] ?? 'true',
          isSystem: true,
        ));

        // Social records
        const socialMap = <String, (String, String, String?)>{
          'com.twitter': ('com.twitter', 'Twitter', 'https://x.com/'),
          'com.github': ('com.github', 'GitHub', 'https://github.com/'),
          'com.discord': ('com.discord', 'Discord', null),
          'org.telegram': ('org.telegram', 'Telegram', 'https://t.me/'),
          'url': ('url', 'Website', null),
          'email': ('email', 'Email', 'mailto:'),
          'com.linkedin': ('com.linkedin', 'LinkedIn', 'https://linkedin.com/in/'),
          'com.reddit': ('com.reddit', 'Reddit', 'https://reddit.com/user/'),
          'com.instagram': ('com.instagram', 'Instagram', 'https://instagram.com/'),
        };
        const cardColor = Color.fromARGB(255, 25, 55, 107);
        for (final entry in socialMap.entries) {
          final ensKey = entry.key;
          final (recordKey, displayName, urlPrefix) = entry.value;
          final rawValue = ensData[ensKey];
          if (rawValue == null || rawValue.isEmpty) continue;
          final cleanValue = rawValue.startsWith('@') ? rawValue.substring(1) : rawValue;
          String? link;
          if (urlPrefix != null) {
            link = '$urlPrefix$cleanValue';
          } else if (ensKey == 'url') {
            link = rawValue.startsWith('http') ? rawValue : 'https://$rawValue';
          }
          updatedRecords.removeWhere((r) => r.key == recordKey);
          updatedRecords.add(Record.asProfile(
            key: recordKey,
            value: cleanValue,
            isExpired: false,
            link: link,
            color: cardColor.withOpacity(.3),
            alignment: 'left',
            opacity: 1.0,
            customMetadataAttributes: {'name': displayName},
          ));
        }

        // 24h cache on success
        updatedRecords.removeWhere((r) => r.key == 'resolve_after');
        updatedRecords.add(Record.asSettings(
          key: 'resolve_after',
          value: DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
          isSystem: true,
        ));

        final updated = contact.copyWith(
          displayName: ensData['name']!,
          records: updatedRecords,
        );
        await saveContact(updated);
        return updated;
      }

      // No ENS match — 1h retry
      final updated = addResolveAfterRecord(contact, 'resolve_after', const Duration(hours: 1));
      await saveContact(updated);
      return updated;
    } catch (e) {
      Log.e(_tag, '[RESOLVE_IDENTITY] $e');
      try {
        final updated = addResolveAfterRecord(contact, 'resolve_after', const Duration(hours: 1));
        await saveContact(updated);
        return updated;
      } catch (_) {}
      return contact;
    }
  }

  /// True if sessions need refetching (1h TTL).
  static bool needsSessions(Contact contact) {
    final cacheStr = contact.getRecordValue('xmtp_sessions_resolve_after');
    if (cacheStr == null) return true;
    try {
      return DateTime.now().isAfter(DateTime.parse(cacheStr));
    } catch (_) {
      return true;
    }
  }

  /// True if ENS/identity needs refetching (24h TTL).
  static bool needsIdentity(Contact contact) {
    if (contact.sessions == null || contact.sessions!.isEmpty) return false;
    final cacheStr = contact.getRecordValue('resolve_after');
    if (cacheStr == null) return true;
    try {
      return DateTime.now().isAfter(DateTime.parse(cacheStr));
    } catch (_) {
      return true;
    }
  }

  /// Attach or refresh a `resolve_after` record on a contact.
  static Contact addResolveAfterRecord(Contact contact, String key, Duration duration) {
    final updatedRecords = List<Record>.from(contact.records)
      ..removeWhere((r) => r.key == key)
      ..add(Record.asSettings(
        key: key,
        value: DateTime.now().add(duration).toIso8601String(),
        isSystem: true,
      ));
    return contact.copyWith(records: updatedRecords);
  }

  /// True if a group member contact is due for re-resolution. 12h TTL,
  /// tracked via `group_member_resolve_after` system record.
  static bool _shouldResolveGroupMember(Contact contact) {
    final cacheStr = contact.getRecordValue('group_member_resolve_after');
    if (cacheStr == null) return true;
    try {
      return DateTime.now().isAfter(DateTime.parse(cacheStr));
    } catch (_) {
      return true;
    }
  }

  /// Resolve the membership of one or more groups in the background.
  ///
  /// Collects every unique peer inbox ID across the provided group stubs
  /// (via `PublicOSConversations.listGroupMembers`), removes own, then for
  /// each member: loads or creates a Contact stub via `findContactInfoOnly`
  /// and runs the full `resolveContact` pipeline — which includes the ENS
  /// / Farcaster fallback in `resolveIdentity` for members with no PublicOS
  /// account. Results are persisted so downstream lookups
  /// (`findContactByInboxId`) return a rich display name + avatar.
  ///
  /// Rate-limited (100ms between members) and cached for 12h per member
  /// (`group_member_resolve_after` record). Safe to call on every
  /// conversation sync — idempotent.
  static Future<List<Contact>> resolveGroupMembers(
    List<Contact> groupContacts,
  ) async {
    Log.d(_tag, '[GROUP_MEMBERS] resolveGroupMembers(${groupContacts.length} groups)');
    if (PublicOS.xmtpClient == null) {
      Log.w(_tag, '[GROUP_MEMBERS] XMTP not initialized — skipping');
      return [];
    }

    final Set<String> uniqueInboxIds = {};
    for (final group in groupContacts) {
      final topic = group.xmtpConversationTopic;
      if (topic == null) continue;
      try {
        final members = await PublicOSConversations.listGroupMembers(topic);
        for (final member in members) {
          final inboxId = member['inboxId'] as String?;
          if (inboxId != null && inboxId.isNotEmpty) uniqueInboxIds.add(inboxId);
        }
      } catch (e) {
        Log.e(_tag, '[GROUP_MEMBERS] listGroupMembers($topic) failed: $e');
      }
    }

    final ownInboxId = PublicOS.clientXmtpInboxId;
    if (ownInboxId != null) uniqueInboxIds.remove(ownInboxId);

    if (uniqueInboxIds.isEmpty) return [];

    Log.d(_tag, '[GROUP_MEMBERS] resolving ${uniqueInboxIds.length} unique members');
    final resolved = <Contact>[];
    int skipped = 0;
    int errors = 0;

    for (final inboxId in uniqueInboxIds) {
      try {
        Contact? member = await findContactByInboxId(inboxId);

        // 12h cache on the member — skip if still fresh.
        if (member != null && !_shouldResolveGroupMember(member)) {
          skipped++;
          continue;
        }

        member ??= await findContactInfoOnly(inboxId);
        if (member == null) {
          errors++;
          continue;
        }

        member = await resolveContact(member);
        member = addResolveAfterRecord(
          member,
          'group_member_resolve_after',
          const Duration(hours: 12),
        );
        await saveContact(member);
        resolved.add(member);

        // Gentle pacing — avoids hammering the RPC on large groups.
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        errors++;
        Log.e(_tag, '[GROUP_MEMBERS] resolve($inboxId) failed: $e');
      }
    }

    Log.i(
      _tag,
      '[GROUP_MEMBERS] done — resolved=${resolved.length} skipped=$skipped errors=$errors',
    );
    return resolved;
  }

  // ============================================================================
  // SECTION 4: ORG MEMBERS (paginated)
  // ============================================================================

  /// Fetch a page of org member addresses for an org contact.
  /// Requires `web3Connected`. Returns empty list on failure or for non-orgs.
  /// The caller is responsible for merging results into the contact.
  static Future<List<EthereumAddress>> fetchOrgMembers(
    EthereumAddress orgAddress, {
    int offset = 0,
    int limit = 50,
  }) async {
    if (!PublicOS.web3Connected) return [];
    try {
      return await PublicOSGovernance.getOrgMembersPaginated(
        orgAddress,
        offset: offset,
        limit: limit,
      );
    } catch (e) {
      Log.e(_tag, '[fetchOrgMembers] $e');
      return [];
    }
  }

  // ============================================================================
  // PRIVATE HELPERS
  // ============================================================================

  /// Safely fetch the org member count. Returns null on failure.
  static Future<int?> _getOrgMemberCountSafe(EthereumAddress orgAddress) async {
    try {
      final count = await PublicOSGovernance.getOrgMemberCount(orgAddress);
      return count;
    } catch (e) {
      Log.d(_tag, '[member count] $e');
      return null;
    }
  }

  /// Extract ETH addresses from an XMTP inbox state, prioritizing the
  /// recovery identity then each additional identity.
  static List<String> _extractAddressesFromInboxState(Map<String, dynamic> state) {
    final addresses = <String>[];

    final recoveryRaw = state['recoveryIdentity'];
    if (recoveryRaw is Map) {
      final recovery = Map<String, dynamic>.from(recoveryRaw);
      if (recovery['kind'] == 'ethereum') {
        final id = recovery['identifier'] as String?;
        if (id != null && id.isNotEmpty) addresses.add(id);
      }
    }

    final identitiesRaw = state['identities'];
    if (identitiesRaw is List) {
      for (final identityRaw in identitiesRaw) {
        if (identityRaw is Map) {
          final identity = Map<String, dynamic>.from(identityRaw);
          if (identity['kind'] == 'ethereum') {
            final id = identity['identifier'] as String?;
            if (id != null && id.isNotEmpty && !addresses.contains(id)) {
              addresses.add(id);
            }
          }
        }
      }
    }

    return addresses;
  }

  /// Truncated inbox id for display stubs: "abcdef..123456".
  static String _shortInboxId(String inboxId) {
    if (inboxId.length < 12) return inboxId;
    return '${inboxId.substring(0, 6)}..${inboxId.substring(inboxId.length - 6)}';
  }

  /// For consumers needing raw access.
  static Uint8List inboxIdToBytes(String inboxId) => StringToBytes(inboxId);

  // ==========================================================================
  // CROSS-CHAIN IDENTITY RESOLUTION
  // ENS, Farcaster, NFT avatar — uses mainnet RPCs + external APIs,
  // not the PublicOS chain. Used by resolveIdentity().
  // ==========================================================================
  ///*********************************************
  /// ENS RESOLUTION (Mainnet)
  ///*********************************************

  // ENS Constants
  // publicnode — the previous eth.llamarpc.com was returning HTTP 525, which
  // silently broke ALL ENS name + avatar resolution for XMTP contacts.
  static const String _ensRpcUrl = 'https://ethereum-rpc.publicnode.com';
  static const String _universalResolver = '0xce01f8eee7E479C928F8919abD53E553a36CeF67';

  // Function selectors
  static const String _selectorResolve = '9061b923';      // resolve(bytes,bytes)
  static const String _selectorName = '691f3431';         // name(bytes32)
  static const String _selectorText = '59d1d43c';         // text(bytes32,string)
  static const String _selectorOffchainLookup = '556f1830'; // OffchainLookup error

  // Base chain fallback for reverse resolution
  static const String _baseRpcUrl = 'https://mainnet.base.org';
  static const String _baseResolver = '0xC6d566A56A1aFf6508b41f6c90ff131615583BCD';

  // Farcaster Hub API for profile resolution
  static const String _farcasterHubUrl = 'https://hub.pinata.cloud/v1';

  // Farcaster On-Chain (Optimism Mainnet - Chain ID 10)
  static const String _optimismRpcUrl = 'https://mainnet.optimism.io';
  static const String _farcasterIdRegistry = '0x00000000fc6c5f01fc30151999387bb99a9f489b';
  static const String _selectorIdOf = 'd94fe832'; // idOf(address) -> uint256

  // Neynar API for verified address resolution
  // The key is supplied at build time with --dart-define=NEYNAR_API_KEY=...
  // (free keys at https://neynar.com). Without it this lookup step is skipped.
  static const String _neynarApiKey = String.fromEnvironment('NEYNAR_API_KEY');

  // Web3.bio API (LAST RESORT - aggregator, not on-chain source of truth)
  static const String _web3bioApiUrl = 'https://api.web3.bio';

  /// Resolve an Ethereum address to ENS name and avatar via reverse resolution.
  /// Returns {name: "vitalik.eth", avatar: "https://..."} or null if not found.
  /// Skips NFT avatars (eip155:...) - only returns direct URL avatars.
  static Future<Map<String, String>?> resolveAddressToENS(String address) async {
    final client = http.Client();
    try {
      final addressClean = address.toLowerCase().replaceAll('0x', '');
      final reverseName = '$addressClean.addr.reverse';

      Log.d(_tag, 'ENS reverse resolving 0x${addressClean.substring(0, 6)}...${addressClean.substring(addressClean.length - 4)}');


      final dnsName = _dnsEncode(reverseName);
      final node = _namehash(reverseName);

      // 1. Get name
      final nameCalldata = _selectorName + _abiEncode(['bytes32'], [node]);
      var nameResult = await _resolveRecord(client, dnsName, nameCalldata);
      String resolvedSource = 'ens'; // Track which resolver succeeded

      // Fallback to Base resolver if Universal Resolver fails
      if (nameResult == null || nameResult.isEmpty) {
        Log.d(_tag, 'No ENS name via Universal Resolver, trying Base resolver...');
        final baseCalldata = '0x$_selectorName${_bytesToHex(node).padLeft(64, '0')}';
        final baseResult = await _ethCall(client, _baseResolver, baseCalldata, rpcUrl: _baseRpcUrl);

        if (baseResult['result'] != null && baseResult['result'] != '0x') {
          try {
            nameResult = _hexToBytes((baseResult['result'] as String).substring(2));
            resolvedSource = 'base';
            Log.d(_tag, 'Got result from Base resolver');
          } catch (e) {
            Log.e(_tag, 'Base resolver decode failed: $e');
          }
        }
      }

      if (nameResult == null || nameResult.isEmpty) {
        // Try Farcaster fallback
        Log.d(_tag, 'No ENS/Base name found, trying Farcaster...');
        final farcasterResult = await _resolveAddressViaFarcaster(client, address);
        if (farcasterResult != null) {
          return farcasterResult;
        }
        // LAST RESORT: web3.bio (untrusted aggregator)
        Log.d(_tag, 'No Farcaster, trying web3.bio (last resort)...');
        final web3bioResult = await _resolveAddressViaWeb3Bio(client, address);
        if (web3bioResult != null) {
          return web3bioResult;
        }
        Log.d(_tag, 'No name found for address');
        return null;
      }

      String? name;
      try {
        name = _abiDecodeString(nameResult);
        if (name == null || name.isEmpty) {
          // Try Farcaster fallback for empty name
          Log.d(_tag, 'Empty ENS name, trying Farcaster...');
          final farcasterResult = await _resolveAddressViaFarcaster(client, address);
          if (farcasterResult != null) {
            return farcasterResult;
          }
          // LAST RESORT: web3.bio (untrusted aggregator)
          Log.d(_tag, 'No Farcaster, trying web3.bio (last resort)...');
          final web3bioResult = await _resolveAddressViaWeb3Bio(client, address);
          if (web3bioResult != null) {
            return web3bioResult;
          }
          Log.d(_tag, 'No name found for address');
          return null;
        }
        Log.i(_tag, 'ENS name resolved: $name');
      } catch (e) {
        // Try Farcaster fallback on decode error
        Log.w(_tag, 'ENS decode failed, trying Farcaster...');
        final farcasterResult = await _resolveAddressViaFarcaster(client, address);
        if (farcasterResult != null) {
          return farcasterResult;
        }
        // LAST RESORT: web3.bio (untrusted aggregator)
        Log.d(_tag, 'No Farcaster, trying web3.bio (last resort)...');
        final web3bioResult = await _resolveAddressViaWeb3Bio(client, address);
        if (web3bioResult != null) {
          return web3bioResult;
        }
        Log.e(_tag, 'Failed to decode ENS name: $e');
        return null;
      }

      final result = <String, String>{'name': name, 'source': resolvedSource};

      // 2. Get avatar using the resolved name
      try {
        final nameDns = _dnsEncode(name);
        final nameNode = _namehash(name);
        final avatarCalldata = _selectorText + _abiEncodeTextRecord(nameNode, 'avatar');
        final avatarResult = await _resolveRecord(client, nameDns, avatarCalldata);

        if (avatarResult != null && avatarResult.isNotEmpty) {
          final avatar = _abiDecodeString(avatarResult);
          if (avatar != null && avatar.isNotEmpty) {
            result['avatar'] = avatar;
            if (avatar.startsWith('eip155:')) {
              Log.d(_tag, 'ENS avatar is NFT reference: ${avatar.length > 60 ? '${avatar.substring(0, 60)}...' : avatar}');
            } else {
              Log.d(_tag, 'ENS avatar resolved: ${avatar.length > 60 ? '${avatar.substring(0, 60)}...' : avatar}');
            }
          }
        }
      } catch (e) {
        Log.e(_tag, 'Failed to fetch ENS avatar: $e');
        // Continue without avatar
      }

      // 3. Get description (bio) using the resolved name
      try {
        final nameDns = _dnsEncode(name);
        final nameNode = _namehash(name);
        final descriptionCalldata = _selectorText + _abiEncodeTextRecord(nameNode, 'description');
        final descriptionResult = await _resolveRecord(client, nameDns, descriptionCalldata);

        if (descriptionResult != null && descriptionResult.isNotEmpty) {
          final description = _abiDecodeString(descriptionResult);
          if (description != null && description.isNotEmpty) {
            result['bio'] = description;
            Log.d(_tag, 'ENS description resolved: ${description.length > 60 ? '${description.substring(0, 60)}...' : description}');
          }
        }
      } catch (e) {
        Log.e(_tag, 'Failed to fetch ENS description: $e');
        // Continue without description
      }

      // 4. Get social text records using the resolved name
      const socialRecordKeys = [
        'com.twitter',
        'com.github',
        'com.discord',
        'org.telegram',
        'url',
        'email',
        'com.linkedin',
        'com.reddit',
        'com.instagram',
      ];

      try {
        final nameDns = _dnsEncode(name);
        final nameNode = _namehash(name);

        for (final key in socialRecordKeys) {
          try {
            final recordCalldata = _selectorText + _abiEncodeTextRecord(nameNode, key);
            final recordResult = await _resolveRecord(client, nameDns, recordCalldata);

            if (recordResult != null && recordResult.isNotEmpty) {
              final value = _abiDecodeString(recordResult);
              if (value != null && value.isNotEmpty) {
                result[key] = value;
                Log.d(_tag, 'ENS $key resolved: ${value.length > 40 ? '${value.substring(0, 40)}...' : value}');
              }
            }
          } catch (e) {
            // Continue with next record
          }
        }
      } catch (e) {
        Log.e(_tag, 'Failed to fetch ENS social records: $e');
        // Continue without social records
      }

      return result;
    } catch (e) {
      Log.e(_tag, 'ENS resolution failed: $e');
      return null;
    } finally {
      client.close();
    }
  }

  /// Resolve address via Farcaster.
  /// Returns profile data including name, avatar, displayname, bio.
  ///
  /// Resolution order:
  /// 1. On-chain Id Registry lookup (custody addresses) - FREE
  /// 2. Neynar API lookup (verified addresses) - requires API key
  static Future<Map<String, String>?> _resolveAddressViaFarcaster(http.Client client, String address) async {
    final addressClean = address.toLowerCase();
    final addressWithPrefix = addressClean.startsWith('0x') ? addressClean : '0x$addressClean';

    Log.d(_tag, 'Trying Farcaster resolution for ${addressWithPrefix.substring(0, 10)}...');

    // Step 1: Try on-chain custody lookup (FREE)
    final fid = await _getFidFromCustodyOnchain(client, addressWithPrefix);
    if (fid != null && fid > 0) {
      Log.d(_tag, 'Found custody FID on-chain: $fid');
      final profile = await _getProfileFromHub(client, fid);
      if (profile != null && profile.containsKey('name')) {
        profile['source'] = 'farcaster_custody';
        return profile;
      }
    }

    // Step 2: Try Neynar API for verified addresses
    Log.d(_tag, 'Not a custody address, trying Neynar API...');
    final neynarResult = await _resolveAddressViaNeynar(client, addressWithPrefix);
    if (neynarResult != null) {
      return neynarResult;
    }

    Log.d(_tag, 'No Farcaster identity found');
    return null;
  }

  /// Query Optimism Id Registry for custody address -> FID (FREE, on-chain)
  static Future<int?> _getFidFromCustodyOnchain(http.Client client, String address) async {
    try {
      final addressClean = address.toLowerCase().replaceAll('0x', '');
      final paddedAddress = addressClean.padLeft(64, '0');
      final calldata = '0x$_selectorIdOf$paddedAddress';

      final response = await client.post(
        Uri.parse(_optimismRpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'eth_call',
          'params': [{'to': _farcasterIdRegistry, 'data': calldata}, 'latest'],
          'id': 1,
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final result = jsonDecode(response.body) as Map<String, dynamic>;
      final resultHex = result['result'] as String?;

      if (resultHex == null || resultHex == '0x' || resultHex == '0x${'0' * 64}') {
        return null;
      }

      final fid = int.tryParse(resultHex.replaceAll('0x', ''), radix: 16);
      return (fid != null && fid > 0) ? fid : null;
    } catch (e) {
      Log.e(_tag, 'On-chain FID lookup failed: $e');
      return null;
    }
  }

  /// Fetch user profile from Farcaster Hub by FID
  static Future<Map<String, String>?> _getProfileFromHub(http.Client client, int fid) async {
    try {
      final userResponse = await client.get(
        Uri.parse('$_farcasterHubUrl/userDataByFid?fid=$fid'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (userResponse.statusCode != 200) return null;

      final userData = jsonDecode(userResponse.body) as Map<String, dynamic>;
      final messages = userData['messages'] as List<dynamic>?;

      if (messages == null || messages.isEmpty) return null;

      final result = <String, String>{};

      for (final msg in messages) {
        final body = (msg['data'] as Map<String, dynamic>?)?['userDataBody'] as Map<String, dynamic>?;
        if (body == null) continue;

        final dataType = body['type'] as String? ?? '';
        final value = body['value'] as String? ?? '';

        if (value.isEmpty) continue;

        switch (dataType) {
          case 'USER_DATA_TYPE_USERNAME':
            result['name'] = value;
            break;
          case 'USER_DATA_TYPE_PFP':
            result['avatar'] = value;
            break;
          case 'USER_DATA_TYPE_DISPLAY':
            result['displayname'] = value;
            break;
          case 'USER_DATA_TYPE_BIO':
            result['bio'] = value;
            break;
        }
      }

      // If name doesn't have a domain (like .base.eth), append .farcaster.eth
      if (result.containsKey('name') && !result['name']!.contains('.')) {
        result['name'] = '${result['name']}.farcaster.eth';
      }

      return result.containsKey('name') ? result : null;
    } catch (e) {
      Log.e(_tag, 'Hub profile fetch failed: $e');
      return null;
    }
  }

  /// Resolve address via Neynar API (works for both custody and verified addresses)
  static Future<Map<String, String>?> _resolveAddressViaNeynar(http.Client client, String address) async {
    if (_neynarApiKey.isEmpty) return null;
    try {
      final response = await client.get(
        Uri.parse('https://api.neynar.com/v2/farcaster/user/bulk-by-address?addresses=$address'),
        headers: {
          'Accept': 'application/json',
          'x-api-key': _neynarApiKey,
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        Log.e(_tag, 'Neynar API error: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final users = data[address.toLowerCase()] as List<dynamic>?;

      if (users == null || users.isEmpty) {
        Log.d(_tag, 'No Farcaster user found via Neynar');
        return null;
      }

      final user = users[0] as Map<String, dynamic>;
      final custodyAddr = (user['custody_address'] as String?)?.toLowerCase() ?? '';
      final verifiedAddrs = ((user['verified_addresses'] as Map<String, dynamic>?)?['eth_addresses'] as List<dynamic>?)
          ?.map((e) => e.toString().toLowerCase())
          .toList() ?? [];

      String source;
      if (address.toLowerCase() == custodyAddr) {
        source = 'farcaster_custody';
      } else if (verifiedAddrs.contains(address.toLowerCase())) {
        source = 'farcaster_verified';
      } else {
        source = 'farcaster';
      }

      final result = <String, String>{
        'source': source,
      };

      if (user['username'] != null) {
        String username = user['username'] as String;
        // If username doesn't have a domain (like .base.eth), append .farcaster.eth
        if (!username.contains('.')) {
          username = '$username.farcaster.eth';
        }
        result['name'] = username;
      }
      if (user['pfp_url'] != null) result['avatar'] = user['pfp_url'] as String;

      final bio = (user['profile'] as Map<String, dynamic>?)?['bio'] as Map<String, dynamic>?;
      if (bio != null && bio['text'] != null) {
        result['bio'] = bio['text'] as String;
      }

      if (!result.containsKey('name')) {
        Log.d(_tag, 'Neynar profile has no username');
        return null;
      }

      Log.i(_tag, 'Farcaster profile resolved via Neynar: ${result['name']} (${result['source']})');
      return result;
    } catch (e) {
      Log.e(_tag, 'Neynar resolution failed: $e');
      return null;
    }
  }

  // =============================================================================
  // WEB3.BIO RESOLUTION (LAST RESORT - UNTRUSTED AGGREGATOR)
  // =============================================================================

  /// LAST RESORT: Resolve address via web3.bio API.
  /// This is an aggregator - NOT an on-chain source of truth.
  static Future<Map<String, String>?> _resolveAddressViaWeb3Bio(http.Client client, String address) async {
    try {
      final addressClean = address.toLowerCase();
      final addressWithPrefix = addressClean.startsWith('0x') ? addressClean : '0x$addressClean';

      Log.d(_tag, 'Trying web3.bio resolution for ${addressWithPrefix.substring(0, 10)}...');

      final response = await client.get(
        Uri.parse('$_web3bioApiUrl/profile/$addressWithPrefix'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        Log.e(_tag, 'web3.bio API error: ${response.statusCode}');
        return null;
      }

      final profiles = jsonDecode(response.body);
      if (profiles == null || profiles is! List || profiles.isEmpty) {
        Log.d(_tag, 'No profiles found via web3.bio');
        return null;
      }

      // Find the best identity (prefer ens/basenames over just ethereum)
      Map<String, dynamic>? bestProfile;
      for (final profile in profiles) {
        if (profile is! Map<String, dynamic>) continue;

        final platform = profile['platform'] as String? ?? '';
        final identity = profile['identity'] as String? ?? '';

        // Skip if it's just the raw address
        if (identity.toLowerCase() == addressWithPrefix.toLowerCase()) {
          continue;
        }

        // Prefer ENS and basenames
        if (platform == 'ens' || platform == 'basenames' || platform == 'unstoppabledomains') {
          bestProfile = profile;
          break;
        }
        // Otherwise take first non-address identity
        if (bestProfile == null && identity.isNotEmpty) {
          bestProfile = profile;
        }
      }

      if (bestProfile == null) {
        Log.d(_tag, 'No suitable identity found via web3.bio');
        return null;
      }

      final identity = bestProfile['identity'] as String? ?? '';
      if (identity.isEmpty || identity.toLowerCase() == addressWithPrefix.toLowerCase()) {
        Log.d(_tag, 'web3.bio identity is empty or same as address');
        return null;
      }

      final result = <String, String>{
        'name': identity, // Mark as untrusted
        'source': 'web3bio_${bestProfile['platform'] ?? 'unknown'}',
      };

      // Map web3.bio fields to our format
      if (bestProfile['avatar'] != null) {
        result['avatar'] = bestProfile['avatar'] as String;
      }
      if (bestProfile['description'] != null) {
        result['bio'] = bestProfile['description'] as String;
      }

      // Map web3.bio links format to our com.* format
      final links = bestProfile['links'] as Map<String, dynamic>?;
      if (links != null) {
        if (links['twitter'] != null && (links['twitter'] as Map<String, dynamic>)['handle'] != null) {
          result['com.twitter'] = (links['twitter'] as Map<String, dynamic>)['handle'] as String;
        }
        if (links['github'] != null && (links['github'] as Map<String, dynamic>)['handle'] != null) {
          result['com.github'] = (links['github'] as Map<String, dynamic>)['handle'] as String;
        }
        if (links['website'] != null && (links['website'] as Map<String, dynamic>)['link'] != null) {
          result['url'] = (links['website'] as Map<String, dynamic>)['link'] as String;
        }
      }

      Log.i(_tag, 'web3.bio resolved: ${result['name']} (source: ${result['source']})');
      return result;
    } catch (e) {
      Log.e(_tag, 'web3.bio resolution failed: $e');
      return null;
    }
  }

  // =============================================================================
  // NFT AVATAR RESOLUTION (CAIP-19)
  // =============================================================================

  // Chain ID to RPC URL mapping
  // publicnode endpoints across the board. (A dead endpoint here silently
  // breaks NFT-avatar resolution for that chain's NFTs — the eth_call fails,
  // so the metadata never resolves.)
  static const Map<int, String> _chainRpcUrls = {
    1: 'https://ethereum-rpc.publicnode.com', // Ethereum Mainnet
    10: 'https://optimism-rpc.publicnode.com', // Optimism
    137: 'https://polygon-bor-rpc.publicnode.com', // Polygon
    8453: 'https://base-rpc.publicnode.com', // Base
    42161: 'https://arbitrum-one-rpc.publicnode.com', // Arbitrum One
    // Hyperliquid HyperEVM. No publicnode endpoint exists; official public RPC
    // (eth_chainId -> 0x3e7). ~100 req/min, HTTP-only —
    // fine for occasional tokenURI/ownerOf reads; swap to a paid provider if hot.
    999: 'https://rpc.hyperliquid.xyz/evm',
  };

  // ERC-721 tokenURI(uint256) selector
  static const String _selectorTokenUri = 'c87b56dd';
  // ERC-1155 uri(uint256) selector
  static const String _selectorUri = '0e89341c';
  // ERC-721 ownerOf(uint256) selector
  static const String _selectorOwnerOf = '6352211e';
  // ERC-1155 balanceOf(address,uint256) selector
  static const String _selectorBalanceOf = '00fdd58e';

  /// RPC endpoint for [chainId]. Chain 4489 (PublicOS) uses the live active
  /// RPC (failover-aware); external chains use the static public endpoints in
  /// [_chainRpcUrls]. Null for an unsupported chain → callers fall back to the
  /// plain `profile.avatar` URL. NFT pointers carry their own chain, so this is
  /// the single chooser for any NFT read (image / ownerOf / balanceOf).
  static String? _rpcForChain(int chainId) =>
      chainId == 4489 ? PublicOS.activeRpcUrl : _chainRpcUrls[chainId];

  /// Resolve an NFT avatar URI (CAIP-19 format) to the actual image URL.
  ///
  /// Supports formats like:
  /// - eip155:1/erc721:0x.../tokenId
  /// - eip155:1/erc1155:0x.../tokenId
  ///
  /// Returns the resolved image URL or null if resolution fails.
  static Future<String?> resolveNftAvatarUri(String eipUri) async {
    final client = http.Client();
    try {
      Log.d(_tag, 'Resolving NFT avatar: ${eipUri.length > 60 ? '${eipUri.substring(0, 60)}...' : eipUri}');

      // Parse CAIP-19 URI: eip155:{chainId}/{standard}:{contract}/{tokenId}
      final parsed = _parseCaip19Uri(eipUri);
      if (parsed == null) {
        Log.w(_tag, 'Failed to parse CAIP-19 URI');
        return null;
      }

      final chainId = parsed['chainId'] as int;
      final standard = parsed['standard'] as String;
      final contract = parsed['contract'] as String;
      final tokenId = parsed['tokenId'] as String;

      Log.d(_tag, 'NFT - Chain: $chainId, Standard: $standard, Contract: ${contract.substring(0, 10)}..., TokenId: ${tokenId.length > 20 ? '${tokenId.substring(0, 20)}...' : tokenId}');

      // Get RPC URL for chain
      final rpcUrl = _rpcForChain(chainId);
      if (rpcUrl == null) {
        Log.w(_tag, 'Unsupported chain ID: $chainId');
        return null;
      }

      // Build calldata for uri(tokenId) or tokenURI(tokenId)
      final selector = standard == 'erc1155' ? _selectorUri : _selectorTokenUri;
      final tokenIdBigInt = BigInt.parse(tokenId);
      final tokenIdHex = tokenIdBigInt.toRadixString(16).padLeft(64, '0');
      final calldata = '0x$selector$tokenIdHex';

      // Call the contract
      final response = await _ethCall(client, contract, calldata, rpcUrl: rpcUrl);

      if (response['error'] != null || response['result'] == null || response['result'] == '0x') {
        Log.e(_tag, 'NFT contract call failed: ${response['error']}');
        return null;
      }

      // Decode the URI string from response
      final resultBytes = _hexToBytes((response['result'] as String).substring(2));
      final metadataUri = _abiDecodeString(resultBytes);

      if (metadataUri == null || metadataUri.isEmpty) {
        Log.w(_tag, 'NFT metadata URI is empty');
        return null;
      }

      Log.d(_tag, 'NFT metadata URI: ${metadataUri.length > 60 ? '${metadataUri.substring(0, 60)}...' : metadataUri}');

      // Resolve the metadata URI (handle ipfs://, ar://, ERC-1155 {id}, etc.)
      final resolvedUri = _resolveMetadataUri(
          standard == 'erc1155' ? _substituteTokenId(metadataUri, tokenIdHex) : metadataUri);

      // Fetch metadata JSON (decode inline for on-chain data: URIs).
      String metadataBody;
      if (resolvedUri.startsWith('data:')) {
        final decoded = _decodeDataUri(resolvedUri);
        if (decoded == null) {
          Log.w(_tag, 'Could not decode data: metadata URI');
          return null;
        }
        metadataBody = decoded;
      } else {
        final body = await _fetchMetadataBody(client, resolvedUri);
        if (body == null) {
          Log.e(_tag, 'Failed to fetch NFT metadata: $resolvedUri');
          return null;
        }
        metadataBody = body;
      }

      final metadata = jsonDecode(metadataBody) as Map<String, dynamic>;

      // Extract image URL (try common fields)
      String? imageUrl = metadata['image'] as String?
          ?? metadata['image_url'] as String?
          ?? metadata['animation_url'] as String?;

      if (imageUrl == null || imageUrl.isEmpty) {
        Log.w(_tag, 'No image found in NFT metadata');
        return null;
      }

      // Resolve the image URI (handle ipfs://, ar://, etc.)
      imageUrl = _resolveMetadataUri(imageUrl);

      Log.i(_tag, 'NFT avatar resolved: ${imageUrl.length > 60 ? '${imageUrl.substring(0, 60)}...' : imageUrl}');
      return imageUrl;
    } catch (e) {
      Log.e(_tag, 'NFT avatar resolution failed: $e');
      return null;
    } finally {
      client.close();
    }
  }

  /// Resolve an NFT [ref] to its full metadata JSON — `image` / `name` /
  /// `attributes` / `animation_url`, with `image` and `animation_url`
  /// normalized to HTTP. Used by the contact icon's verdict cache and the NFT
  /// info dialog. Multichain: reads on `ref.chain` via [_rpcForChain].
  /// Returns null on any failure (unsupported chain, bad pointer, fetch error)
  /// → caller falls back to the plain `profile.avatar` URL.
  static Future<Map<String, dynamic>?> resolveNftAvatarData(NftAvatarRef ref) async {
    final client = http.Client();
    try {
      final rpcUrl = _rpcForChain(ref.chain);
      if (rpcUrl == null) {
        Log.w(_tag, 'NFT data: unsupported chain ${ref.chain}');
        return null;
      }

      // tokenURI(tokenId) (ERC-721) or uri(tokenId) (ERC-1155)
      final selector = ref.isErc1155 ? _selectorUri : _selectorTokenUri;
      final tokenIdHex = BigInt.parse(ref.tokenId).toRadixString(16).padLeft(64, '0');
      final calldata = '0x$selector$tokenIdHex';

      final response = await _ethCall(client, ref.contract, calldata, rpcUrl: rpcUrl);
      if (response['error'] != null || response['result'] == null || response['result'] == '0x') {
        Log.e(_tag, 'NFT data: tokenURI call failed: ${response['error']}');
        return null;
      }

      final metadataUri = _abiDecodeString(_hexToBytes((response['result'] as String).substring(2)));
      if (metadataUri == null || metadataUri.isEmpty) {
        Log.w(_tag, 'NFT data: empty metadata URI');
        return null;
      }

      final resolvedMetaUri = _resolveMetadataUri(
          ref.isErc1155 ? _substituteTokenId(metadataUri, tokenIdHex) : metadataUri);
      String metaBody;
      if (resolvedMetaUri.startsWith('data:')) {
        // On-chain metadata — decode inline (an HTTP GET on data: throws).
        final decoded = _decodeDataUri(resolvedMetaUri);
        if (decoded == null) {
          Log.w(_tag, 'NFT data: could not decode data: metadata URI');
          return null;
        }
        metaBody = decoded;
      } else {
        final body = await _fetchMetadataBody(client, resolvedMetaUri);
        if (body == null) {
          Log.e(_tag, 'NFT data: metadata fetch failed on every try: $resolvedMetaUri');
          return null;
        }
        metaBody = body;
      }

      final metadata = jsonDecode(metaBody) as Map<String, dynamic>;

      // Normalize image + animation_url to HTTP so the renderer uses them directly.
      final image = (metadata['image'] ?? metadata['image_url']) as String?;
      if (image != null && image.isNotEmpty) metadata['image'] = _resolveMetadataUri(image);
      final anim = metadata['animation_url'] as String?;
      if (anim != null && anim.isNotEmpty) metadata['animation_url'] = _resolveMetadataUri(anim);

      return metadata;
    } catch (e) {
      Log.e(_tag, 'NFT data resolution failed: $e');
      return null;
    } finally {
      client.close();
    }
  }

  /// ERC-721 `ownerOf(tokenId)` on `ref.chain`. Returns null for ERC-1155
  /// (no `ownerOf` — use [nftBalanceOf]), an unsupported chain, the zero
  /// address, or any failure.
  static Future<EthereumAddress?> nftOwnerOf(NftAvatarRef ref) async {
    if (ref.isErc1155) return null;
    final client = http.Client();
    try {
      final rpcUrl = _rpcForChain(ref.chain);
      if (rpcUrl == null) return null;
      final tokenIdHex = BigInt.parse(ref.tokenId).toRadixString(16).padLeft(64, '0');
      final calldata = '0x$_selectorOwnerOf$tokenIdHex';
      final response = await _ethCall(client, ref.contract, calldata, rpcUrl: rpcUrl);
      final result = response['result'] as String?;
      if (response['error'] != null || result == null || result.length < 66) return null;
      // 32-byte word → address = last 20 bytes (last 40 hex chars).
      final addrHex = result.substring(result.length - 40);
      if (BigInt.parse(addrHex, radix: 16) == BigInt.zero) return null;
      return EthereumAddress.fromHex('0x$addrHex');
    } catch (e) {
      Log.e(_tag, 'nftOwnerOf failed: $e');
      return null;
    } finally {
      client.close();
    }
  }

  /// ERC-1155 `balanceOf(holder, tokenId)` on `ref.chain`. `> 0` ⇒ [holder]
  /// owns at least one. Returns 0 on an unsupported chain or any failure.
  static Future<BigInt> nftBalanceOf(NftAvatarRef ref, EthereumAddress holder) async {
    final client = http.Client();
    try {
      final rpcUrl = _rpcForChain(ref.chain);
      if (rpcUrl == null) return BigInt.zero;
      final holderHex = holder.eip55With0x.substring(2).toLowerCase().padLeft(64, '0');
      final tokenIdHex = BigInt.parse(ref.tokenId).toRadixString(16).padLeft(64, '0');
      final calldata = '0x$_selectorBalanceOf$holderHex$tokenIdHex';
      final response = await _ethCall(client, ref.contract, calldata, rpcUrl: rpcUrl);
      final result = response['result'] as String?;
      if (response['error'] != null || result == null || result == '0x') return BigInt.zero;
      return BigInt.parse(result.substring(2), radix: 16);
    } catch (e) {
      Log.e(_tag, 'nftBalanceOf failed: $e');
      return BigInt.zero;
    } finally {
      client.close();
    }
  }

  // ---------------------------------------------------------------------
  // ERC-721 OWNED-TOKEN ENUMERATION
  // ---------------------------------------------------------------------

  static const String _selectorErc721BalanceOf = '70a08231'; // balanceOf(address)
  static const String _selectorTokenOfOwnerByIndex = '2f745c59';
  static const String _selectorSupportsInterface = '01ffc9a7';
  static const String _selectorTokensOf = '5a3f2672'; // tokensOf(address), ours only

  /// ERC-165 id of `IERC721Enumerable`.
  static const String _ifaceErc721Enumerable = '780e9d63';

  /// Cap on how many ids we will pull for one contract. A whale holding
  /// thousands would otherwise mean thousands of round trips through a public
  /// RPC; the picker is a chooser, not an inventory.
  static const int _enumerateCap = 200;

  /// Every token id [account] holds in [contract] on [chain], across ALL the
  /// addresses that count as theirs.
  ///
  /// **This is the one to call from UI.** PublicOS assets live on the
  /// **MainSafe**, not the account contract — the account cannot hold or move
  /// anything — so enumerating the account address alone finds nothing. The set
  /// is the same one [verifyNftOwnership] checks against
  /// ([PublicOSWallets.ownedAddresses]): sessions ∪ MainSafe ∪ on-chain-verified
  /// linked EVM wallets. Keeping both on one definition of "mine" is what stops
  /// the grid and the shimmer from disagreeing.
  static Future<List<String>> listOwnedErc721ForAccount(
    String contract,
    EthereumAddress account, {
    required int chain,
  }) async {
    final owners = await PublicOSWallets.ownedAddresses(account);
    if (owners.isEmpty) return const [];
    final seen = <String>{};
    final out = <String>[];
    for (final o in owners) {
      final ids = await listOwnedErc721(contract, o, chain: chain);
      for (final id in ids) {
        if (seen.add(id)) out.add(id);
      }
      if (out.length >= _enumerateCap) break;
    }
    return out;
  }

  /// List the token ids [owner] holds in [contract] on [chain].
  ///
  /// Single-address. Most callers want [listOwnedErc721ForAccount] instead.
  ///
  /// **There is no `tokensOf` in the ERC-721 standard.** Base ERC-721 has no
  /// enumeration at all — that is why the avatar picker's EVM source is
  /// history-only. The optional `ERC721Enumerable` extension is what makes this
  /// possible, and it is genuinely optional: it costs an array write on every
  /// transfer, so most large collections skip it.
  ///
  /// Order of attempts:
  ///  1. `tokensOf(address)` — a non-standard convenience our own contracts
  ///     expose. One round trip instead of N+1, so it is worth trying first.
  ///  2. ERC-165 probe for `IERC721Enumerable`, then `balanceOf` +
  ///     `tokenOfOwnerByIndex` in a loop.
  ///
  /// Returns an EMPTY list when the contract simply does not support
  /// enumeration. That is the common case on mainnet and is **not an error** —
  /// callers should fall back to manual token-id entry, not show a failure.
  static Future<List<String>> listOwnedErc721(
    String contract,
    EthereumAddress owner, {
    required int chain,
  }) async {
    final client = http.Client();
    try {
      final rpcUrl = _rpcForChain(chain);
      if (rpcUrl == null) return const [];
      final ownerHex = owner.eip55With0x.substring(2).toLowerCase().padLeft(64, '0');

      // 1. tokensOf(address) — ours, one round trip.
      final direct = await _ethCall(
        client,
        contract,
        '0x$_selectorTokensOf$ownerHex',
        rpcUrl: rpcUrl,
      );
      final directResult = direct['result'] as String?;
      if (direct['error'] == null && directResult != null && directResult.length > 130) {
        final ids = _abiDecodeUintArray(directResult);
        if (ids != null) return ids.take(_enumerateCap).toList();
      }

      // 2. ERC-165 probe, then the standard index walk.
      final probe = await _ethCall(
        client,
        contract,
        '0x$_selectorSupportsInterface${_ifaceErc721Enumerable.padRight(64, '0')}',
        rpcUrl: rpcUrl,
      );
      final probeResult = probe['result'] as String?;
      final enumerable = probe['error'] == null &&
          probeResult != null &&
          probeResult.length >= 66 &&
          BigInt.parse(probeResult.substring(2), radix: 16) == BigInt.one;
      if (!enumerable) {
        // 3. Not Enumerable. On OUR chain the Transfer log is still a complete
        //    record and getLogs is uncapped, so we can enumerate anything.
        //    Anywhere else there is no cheap answer and an empty list is the
        //    honest one — the caller falls back to manual token-id entry.
        if (chain == 4489) {
          return _listOwnedByTransferScan(client, contract, ownerHex, rpcUrl);
        }
        Log.d(_tag, 'listOwnedErc721: $contract is not ERC721Enumerable');
        return const [];
      }

      final balRes = await _ethCall(
        client,
        contract,
        '0x$_selectorErc721BalanceOf$ownerHex',
        rpcUrl: rpcUrl,
      );
      final balResult = balRes['result'] as String?;
      if (balRes['error'] != null || balResult == null || balResult == '0x') return const [];
      final count = BigInt.parse(balResult.substring(2), radix: 16).toInt();
      if (count == 0) return const [];

      final n = count > _enumerateCap ? _enumerateCap : count;
      final out = <String>[];
      for (var i = 0; i < n; i++) {
        final idxHex = BigInt.from(i).toRadixString(16).padLeft(64, '0');
        final r = await _ethCall(
          client,
          contract,
          '0x$_selectorTokenOfOwnerByIndex$ownerHex$idxHex',
          rpcUrl: rpcUrl,
        );
        final rr = r['result'] as String?;
        if (r['error'] != null || rr == null || rr == '0x') break;
        out.add(BigInt.parse(rr.substring(2), radix: 16).toString());
      }
      if (count > _enumerateCap) {
        Log.w(_tag, 'listOwnedErc721: $contract holds $count, capped at $_enumerateCap');
      }
      return out;
    } catch (e) {
      Log.e(_tag, 'listOwnedErc721 failed: $e');
      return const [];
    } finally {
      client.close();
    }
  }

  /// `Transfer(address,address,uint256)` — mandatory in ERC-721, all three
  /// params indexed, so `tokenId` rides in topic[3].
  static const String _topicErc721Transfer =
      '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef';

  /// Enumerate by scanning `Transfer` logs to [owner], then confirming each
  /// candidate with `ownerOf`.
  ///
  /// **Only offered on chain 4489.** Transfer is mandatory, so this works on
  /// ANY ERC-721 regardless of whether it implements the Enumerable extension —
  /// but it needs a full-history `eth_getLogs`, and public RPCs on mainnet and
  /// the L2s cap block range (commonly 10k blocks) and result count. On our own
  /// chain there is no such cap and the history is short. This is the reason
  /// "EVM has no on-chain enumeration" is true in general and false for us.
  static Future<List<String>> _listOwnedByTransferScan(
    http.Client client,
    String contract,
    String ownerHex,
    String rpcUrl,
  ) async {
    try {
      final response = await client
          .post(
            Uri.parse(rpcUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'jsonrpc': '2.0',
              'method': 'eth_getLogs',
              'params': [
                {
                  'fromBlock': '0x0',
                  'toBlock': 'latest',
                  'address': contract,
                  // [sig, from(any), to(owner)] — tokenId is topic[3].
                  'topics': [_topicErc721Transfer, null, '0x$ownerHex'],
                }
              ],
              'id': 1,
            }),
          )
          .timeout(const Duration(seconds: 12));
      final body = response.body.trim();
      if (!body.startsWith('{')) return const [];
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final logs = decoded['result'] as List<dynamic>?;
      if (logs == null) return const [];

      // Received-ever, de-duplicated and newest-first.
      final seen = <String>{};
      final candidates = <String>[];
      for (final l in logs.reversed) {
        final topics = (l as Map<String, dynamic>)['topics'] as List<dynamic>?;
        if (topics == null || topics.length < 4) continue;
        final id = BigInt.parse((topics[3] as String).substring(2), radix: 16).toString();
        if (seen.add(id)) candidates.add(id);
        if (candidates.length >= _enumerateCap) break;
      }

      // "Received once" is not "owns now" — confirm each.
      final owned = <String>[];
      for (final id in candidates) {
        final idHex = BigInt.parse(id).toRadixString(16).padLeft(64, '0');
        final r = await _ethCall(client, contract, '0x$_selectorOwnerOf$idHex', rpcUrl: rpcUrl);
        final rr = r['result'] as String?;
        if (r['error'] != null || rr == null || rr.length < 66) continue;
        if (rr.substring(rr.length - 40).toLowerCase() ==
            ownerHex.substring(ownerHex.length - 40).toLowerCase()) {
          owned.add(id);
        }
      }
      return owned;
    } catch (e) {
      Log.w(_tag, 'transfer-scan enumeration failed: $e');
      return const [];
    }
    // No `finally client.close()` here on purpose: the client is borrowed from
    // listOwnedErc721, whose own finally owns it. Closing it here would break
    // the caller mid-flight.
  }

  /// Decode an ABI-encoded `uint256[]` return into decimal strings.
  static List<String>? _abiDecodeUintArray(String hex) {
    try {
      final b = hex.startsWith('0x') ? hex.substring(2) : hex;
      // [0] offset, [offset] length, then the words.
      final offset = int.parse(b.substring(0, 64), radix: 16) * 2;
      final len = int.parse(b.substring(offset, offset + 64), radix: 16);
      final out = <String>[];
      for (var i = 0; i < len; i++) {
        final s = offset + 64 + i * 64;
        if (s + 64 > b.length) return null;
        out.add(BigInt.parse(b.substring(s, s + 64), radix: 16).toString());
      }
      return out;
    } catch (_) {
      return null;
    }
  }

  /// Parse CAIP-19 URI into components.
  /// Format: eip155:{chainId}/{standard}:{contract}/{tokenId}
  static Map<String, dynamic>? _parseCaip19Uri(String uri) {
    try {
      // eip155:1/erc1155:0x495f947276749ce646f68ac8c248420045cb7b5e/8112316025873927737505937898915153732580103913704334048512380490797008551937
      final regex = RegExp(r'^eip155:(\d+)/(erc721|erc1155):([0-9a-fA-Fx]+)/(\d+)$');
      final match = regex.firstMatch(uri);

      if (match == null) {
        return null;
      }

      return {
        'chainId': int.parse(match.group(1)!),
        'standard': match.group(2)!.toLowerCase(),
        'contract': match.group(3)!,
        'tokenId': match.group(4)!,
      };
    } catch (e) {
      Log.e(_tag, 'Failed to parse CAIP-19 URI: $e');
      return null;
    }
  }

  /// Public IPFS path gateways, in the order they are tried. ipfs.io and the
  /// rest of the Shipyard family (dweb.link, w3s.link, nftstorage.link) no
  /// longer serve path requests (429 "service worker gateway only").
  /// Ordered by measured response time: filebase ~0.3 s, pinata ~5 s, then
  /// 4everland, last because it stopped answering (its 301
  /// to the subdomain times out); kept in case it comes back.
  static const List<String> ipfsGateways = [
    'https://ipfs.filebase.io/ipfs/',
    'https://gateway.pinata.cloud/ipfs/',
    'https://4everland.io/ipfs/',
  ];

  /// The `<cid>/<path>` part of an IPFS reference, or null when [uri] is not
  /// one: `ipfs://` (incl. the mis-encoded `ipfs://ipfs/`), a bare `Qm…` /
  /// `bafy…` CID, or any gateway URL with an `/ipfs/` path (so a URL pinned to
  /// a dead gateway is re-routed too). Same rule as the lobby's `nft.ipfsPath`.
  static String? _ipfsPath(String uri) {
    if (uri.startsWith('ipfs://')) {
      final p = uri.substring(7);
      return p.startsWith('ipfs/') ? p.substring(5) : p;
    }
    final m = RegExp(r'^https?://[^/]+/ipfs/(.+)$').firstMatch(uri);
    if (m != null) return m.group(1);
    if (uri.startsWith('Qm') || uri.startsWith('bafy')) return uri;
    return null;
  }

  /// Resolve metadata URI protocols (ipfs://, ar://, data:, etc.) to HTTP URLs.
  /// An IPFS reference gets the FIRST gateway; the metadata fetch walks the
  /// rest itself ([_fetchMetadataBody]).
  static String _resolveMetadataUri(String uri) {
    final ipfs = _ipfsPath(uri);
    if (ipfs != null) return '${ipfsGateways.first}$ipfs';
    if (uri.startsWith('ar://')) return 'https://arweave.net/${uri.substring(5)}';
    return uri; // data: (decoded by the caller) and plain http(s)
  }

  /// ERC-1155 metadata URIs are templates: `{id}` is the token id as 64-char
  /// lowercase hex (EIP-1155 § Metadata). ERC-721 URIs pass through.
  static String _substituteTokenId(String uri, String tokenIdHex) =>
      uri.replaceAll('{id}', tokenIdHex.toLowerCase());

  /// GET a metadata JSON body. An IPFS URL is tried on each gateway in turn
  /// (non-200, timeout or network error → next); anything else is one GET.
  /// Returns null when every try fails.
  static Future<String?> _fetchMetadataBody(http.Client client, String url) async {
    final ipfs = _ipfsPath(url);
    final tries = ipfs == null ? [url] : [for (final g in ipfsGateways) '$g$ipfs'];
    for (final u in tries) {
      try {
        final r = await client
            .get(Uri.parse(u), headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 10));
        if (r.statusCode == 200) return r.body;
        Log.w(_tag, 'metadata fetch ${r.statusCode}: $u');
      } catch (e) {
        Log.w(_tag, 'metadata fetch failed: $u ($e)');
      }
    }
    return null;
  }

  /// Decode a `data:` URI body to a string (for on-chain metadata JSON).
  /// Handles `data:[<mime>][;base64],<payload>` — base64 or URL-encoded.
  /// Returns null if it isn't a parseable data: URI. Fully-on-chain NFTs (e.g.
  /// data:application/json metadata) must be decoded inline; an HTTP GET on a
  /// data: URI throws "No host specified in URI".
  static String? _decodeDataUri(String uri) {
    if (!uri.startsWith('data:')) return null;
    final comma = uri.indexOf(',');
    if (comma < 0) return null;
    final meta = uri.substring(5, comma);
    final payload = uri.substring(comma + 1);
    try {
      if (meta.contains('base64')) {
        return utf8.decode(base64.decode(payload));
      }
      return Uri.decodeComponent(payload);
    } catch (e) {
      Log.w(_tag, 'data: URI decode failed: $e');
      return null;
    }
  }

  /// Internal: resolve any record type, handling CCIP Read if needed
  static Future<Uint8List?> _resolveRecord(http.Client client, Uint8List dnsName, String innerCalldata) async {
    // Build resolve(bytes,bytes) calldata
    final resolveCalldata = '0x$_selectorResolve${_abiEncode(['bytes', 'bytes'], [dnsName, _hexToBytes(innerCalldata)])}';

    final response = await Future.any([
      _ethCall(client, _universalResolver, resolveCalldata),
      Future.delayed(const Duration(seconds: 8)).then((_) => throw TimeoutException('ENS resolve timed out')),
    ]);

    // Handle CCIP Read (OffchainLookup error)
    if (response['error'] != null) {
      final errorData = response['error']['data'] as String?;
      if (errorData != null && errorData.startsWith('0x$_selectorOffchainLookup')) {
        Log.d(_tag, 'CCIP Read triggered');
        return await _handleCcipRead(client, errorData);
      }
      return null;
    }

    final resultHex = response['result'] as String?;
    if (resultHex == null || resultHex == '0x') {
      return null;
    }

    // Decode outer resolve result: (bytes, address)
    final resultBytes = _hexToBytes(resultHex.substring(2));
    return _decodeResolveResult(resultBytes);
  }

  /// Handle CCIP Read (EIP-3668) for offchain names like base.eth
  static Future<Uint8List?> _handleCcipRead(http.Client client, String errorData) async {
    try {
      // Decode OffchainLookup error: (address sender, string[] urls, bytes callData, bytes4 callbackFunction, bytes extraData)
      final decoded = _decodeOffchainLookup(errorData);
      if (decoded == null) return null;

      final sender = decoded['sender'] as String;
      final urls = decoded['urls'] as List<String>;
      final callData = decoded['callData'] as Uint8List;
      final callbackFunction = decoded['callbackFunction'] as Uint8List;
      final extraData = decoded['extraData'] as Uint8List;

      // Try each gateway URL
      Uint8List? gatewayResponse;
      for (final urlTemplate in urls) {
        try {
          gatewayResponse = await _ccipFetch(client, urlTemplate, sender, callData);
          if (gatewayResponse != null) break;
        } catch (e) {
          Log.e(_tag, 'CCIP gateway failed: $e');
          continue;
        }
      }

      if (gatewayResponse == null) {
        Log.e(_tag, 'All CCIP gateways failed');
        return null;
      }

      // Call callback function with gateway response
      final callbackCalldata = '0x${_bytesToHex(callbackFunction)}${_abiEncode(['bytes', 'bytes'], [gatewayResponse, extraData])}';
      final callbackResult = await _ethCall(client, sender, callbackCalldata);

      if (callbackResult['error'] != null || callbackResult['result'] == null || callbackResult['result'] == '0x') {
        return null;
      }

      final resultBytes = _hexToBytes((callbackResult['result'] as String).substring(2));
      return _decodeResolveResult(resultBytes);
    } catch (e) {
      Log.e(_tag, 'CCIP Read handling failed: $e');
      return null;
    }
  }

  /// Fetch from CCIP gateway
  static Future<Uint8List?> _ccipFetch(http.Client client, String urlTemplate, String sender, Uint8List callData) async {
    final senderHex = sender.toLowerCase();
    final callDataHex = '0x${_bytesToHex(callData)}';

    final url = urlTemplate
        .replaceAll('{sender}', senderHex)
        .replaceAll('{data}', callDataHex);

    try {
      http.Response response;
      if (urlTemplate.contains('{data}')) {
        // GET request
        response = await client.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      } else {
        // POST request
        response = await client.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'sender': senderHex, 'data': callDataHex}),
        ).timeout(const Duration(seconds: 8));
      }

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'] ?? json;
        if (data is String && data.startsWith('0x')) {
          return _hexToBytes(data.substring(2));
        }
      }
    } catch (e) {
      Log.e(_tag, 'CCIP fetch error: $e');
    }
    return null;
  }

  /// Make eth_call to RPC
  static Future<Map<String, dynamic>> _ethCall(http.Client client, String to, String data, {String? rpcUrl}) async {
    final response = await client.post(
      Uri.parse(rpcUrl ?? _ensRpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'method': 'eth_call',
        'params': [{'to': to, 'data': data}, 'latest'],
        'id': 1,
      }),
    ).timeout(const Duration(seconds: 8));

    // Handle rate limiting and non-JSON responses
    if (response.statusCode == 429) {
      Log.w(_tag, 'RPC rate limited (429)');
      return {'error': {'message': 'Rate limited', 'code': 429}};
    }

    // Check if response is JSON before parsing (Cloudflare 1015 returns HTML)
    final body = response.body.trim();
    if (!body.startsWith('{')) {
      Log.w(_tag, 'RPC returned non-JSON response (status: ${response.statusCode})');
      return {'error': {'message': 'Non-JSON response', 'code': response.statusCode}};
    }

    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      Log.e(_tag, 'Failed to parse RPC response: $e');
      return {'error': {'message': 'Parse error', 'code': response.statusCode}};
    }
  }

  /// Compute namehash for ENS name
  static Uint8List _namehash(String name) {
    var node = Uint8List(32); // Start with 32 zero bytes
    if (name.isEmpty) return node;

    final labels = name.split('.').reversed;
    for (final label in labels) {
      final labelHash = keccak256(Uint8List.fromList(utf8.encode(label)));
      node = keccak256(Uint8List.fromList([...node, ...labelHash]));
    }
    return node;
  }

  /// DNS-encode a name for ENS resolution
  static Uint8List _dnsEncode(String name) {
    if (name.isEmpty) return Uint8List.fromList([0]);

    final result = <int>[];
    for (final label in name.split('.')) {
      final labelBytes = utf8.encode(label);
      result.add(labelBytes.length);
      result.addAll(labelBytes);
    }
    result.add(0); // Null terminator
    return Uint8List.fromList(result);
  }

  /// Simple ABI encoding for specific types
  static String _abiEncode(List<String> types, List<dynamic> values) {
    final result = StringBuffer();
    var dynamicOffset = types.length * 32;
    final dynamicData = StringBuffer();

    for (var i = 0; i < types.length; i++) {
      final type = types[i];
      final value = values[i];

      if (type == 'bytes32') {
        result.write(_bytesToHex(value as Uint8List).padLeft(64, '0'));
      } else if (type == 'bytes') {
        // Dynamic type - write offset
        result.write(dynamicOffset.toRadixString(16).padLeft(64, '0'));
        final bytes = value as Uint8List;
        // Length + data (padded to 32 bytes)
        dynamicData.write(bytes.length.toRadixString(16).padLeft(64, '0'));
        dynamicData.write(_bytesToHex(bytes).padRight((bytes.length + 31) ~/ 32 * 64, '0'));
        dynamicOffset += 32 + ((bytes.length + 31) ~/ 32 * 32);
      }
    }

    return result.toString() + dynamicData.toString();
  }

  /// ABI encode for text record query: bytes32 node + string key
  static String _abiEncodeTextRecord(Uint8List node, String key) {
    final keyBytes = utf8.encode(key);
    final result = StringBuffer();

    // bytes32 node
    result.write(_bytesToHex(node).padLeft(64, '0'));
    // offset for string (64 bytes = 0x40)
    result.write('0000000000000000000000000000000000000000000000000000000000000040');
    // string length
    result.write(keyBytes.length.toRadixString(16).padLeft(64, '0'));
    // string data (padded)
    result.write(_bytesToHex(Uint8List.fromList(keyBytes)).padRight((keyBytes.length + 31) ~/ 32 * 64, '0'));

    return result.toString();
  }

  /// Decode the inner bytes from resolve() result
  static Uint8List? _decodeResolveResult(Uint8List data) {
    if (data.length < 64) return null;

    // First 32 bytes: offset to bytes data
    // Second 32 bytes: offset to address (we don't need this)
    // At offset: length + data

    final offset = _bytesToInt(data.sublist(0, 32));
    if (offset >= data.length) return null;

    final length = _bytesToInt(data.sublist(offset, offset + 32));
    if (offset + 32 + length > data.length) return null;

    return data.sublist(offset + 32, offset + 32 + length);
  }

  /// Decode OffchainLookup error data
  static Map<String, dynamic>? _decodeOffchainLookup(String errorData) {
    try {
      // Skip selector (4 bytes = 8 hex chars + 0x)
      final data = _hexToBytes(errorData.substring(10));

      // Decode: address sender, string[] urls, bytes callData, bytes4 callbackFunction, bytes extraData
      var pos = 0;

      // sender (address, 32 bytes padded)
      final sender = '0x${_bytesToHex(data.sublist(pos + 12, pos + 32))}';
      pos += 32;

      // urls offset
      final urlsOffset = _bytesToInt(data.sublist(pos, pos + 32));
      pos += 32;

      // callData offset
      final callDataOffset = _bytesToInt(data.sublist(pos, pos + 32));
      pos += 32;

      // callbackFunction (bytes4)
      final callbackFunction = data.sublist(pos, pos + 4);
      pos += 32;

      // extraData offset
      final extraDataOffset = _bytesToInt(data.sublist(pos, pos + 32));

      // Decode urls array
      final urlsLength = _bytesToInt(data.sublist(urlsOffset, urlsOffset + 32));
      final urls = <String>[];
      for (var i = 0; i < urlsLength; i++) {
        final strOffset = urlsOffset + 32 + _bytesToInt(data.sublist(urlsOffset + 32 + i * 32, urlsOffset + 64 + i * 32));
        final strLength = _bytesToInt(data.sublist(strOffset, strOffset + 32));
        urls.add(utf8.decode(data.sublist(strOffset + 32, strOffset + 32 + strLength)));
      }

      // Decode callData
      final callDataLength = _bytesToInt(data.sublist(callDataOffset, callDataOffset + 32));
      final callData = data.sublist(callDataOffset + 32, callDataOffset + 32 + callDataLength);

      // Decode extraData
      final extraDataLength = _bytesToInt(data.sublist(extraDataOffset, extraDataOffset + 32));
      final extraData = data.sublist(extraDataOffset + 32, extraDataOffset + 32 + extraDataLength);

      return {
        'sender': sender,
        'urls': urls,
        'callData': callData,
        'callbackFunction': callbackFunction,
        'extraData': extraData,
      };
    } catch (e) {
      Log.e(_tag, 'Failed to decode OffchainLookup: $e');
      return null;
    }
  }

  /// Decode a string from ABI-encoded bytes
  static String? _abiDecodeString(Uint8List data) {
    if (data.length < 64) return null;

    final offset = _bytesToInt(data.sublist(0, 32));
    if (offset >= data.length) return null;

    final length = _bytesToInt(data.sublist(offset, offset + 32));
    if (offset + 32 + length > data.length) return null;

    return utf8.decode(data.sublist(offset + 32, offset + 32 + length));
  }

  // Helper: hex string to bytes
  static Uint8List _hexToBytes(String hex) {
    final h = hex.startsWith('0x') ? hex.substring(2) : hex;
    final result = Uint8List(h.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(h.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }

  // Helper: bytes to hex string
  static String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  // Helper: bytes to int (big-endian)
  static int _bytesToInt(Uint8List bytes) {
    var result = 0;
    for (final b in bytes) {
      result = (result << 8) | b;
    }
    return result;
  }

  // ==========================================================================
  // PROFILE RECORDS (merged from publicos_profile.dart)
  //
  // After 1.0, records live here with the rest of the Contact identity data.
  // Write-through pattern: setRecord/deleteRecord call the chain, then
  // re-fetch the full contact from chain and save to DB. Consumer UIs
  // re-read via `getContact(address)` to see the fresh data.
  // ==========================================================================

  /// Read a cached contact from the local database by publicos account
  /// address. This is the primary read path for "show me this person's
  /// profile data" — returns whatever is currently in the DB without any
  /// network calls.
  ///
  /// Returns null if the contact has never been saved locally. Callers that
  /// need fresh-from-chain data should use [fetchContact] and then [saveContact].
  static Future<Contact?> getContact(EthereumAddress address) async {
    if (PublicOS.sessionBlockchainAddress == null) return null;
    try {
      final row = await PublicOS.database.getContactByPublicosAddress(
        address.eip55With0x,
        PublicOS.sessionBlockchainAddress!,
      );
      if (row == null) return null;
      return DatabaseHelpers.contactFromRow(row);
    } catch (e) {
      Log.e(_tag, '[GET_CONTACT] Error for $address: $e');
      return null;
    }
  }

  /// LOCAL-DB read of an account's OWN cached self-contact, scoped to that
  /// account's OWN session address — NOT the active `sessionBlockchainAddress`.
  ///
  /// ⚠️⚠️ SELECT-ACCOUNT PICKER ONLY. ⚠️⚠️
  /// Every other surface MUST use [getContact] (active-session scoped). This
  /// exists solely because the logged-out account picker has NO active session
  /// yet wants to show each account's last-known avatar/banner from when it was
  /// used. Each account saved its own enriched self-contact under its own
  /// session at login (see [fetchContact]'s self-save), so reading
  /// `(accountAddress, ownSessionAddress)` returns that account's freshest local
  /// copy with no network call.
  ///
  /// Passing a foreign session anywhere else returns another account's
  /// self-cache and breaks the per-session isolation the contacts table is built
  /// on. Do NOT reuse this outside the select-account screen.
  static Future<Contact?> getContactForAccountPicker(
      EthereumAddress accountAddress, EthereumAddress ownSessionAddress) async {
    try {
      final row = await PublicOS.database.getContactByPublicosAddress(
        accountAddress.eip55With0x,
        ownSessionAddress.eip55With0x,
      );
      if (row == null) return null;
      return DatabaseHelpers.contactFromRow(row);
    } catch (e) {
      Log.e(_tag, '[GET_CONTACT_PICKER] Error for $accountAddress: $e');
      return null;
    }
  }

  /// Set an on-chain record for the current user, then refresh the local
  /// DB copy of their contact. Returns true only if the transaction is
  /// confirmed on-chain AND the DB refresh succeeds.
  ///
  /// Flow: chain write → wait for receipt → fetchContact → saveContact → true.
  /// Consumers should re-read via [getContact] after this returns true.
  static Future<bool> setRecord(Record record) async {
    if (!PublicOS.isAuthenticated ||
        PublicOS.currentBlockchainPrivateKey == null ||
        PublicOS.myPublicosAddress == null) {
      Log.e(_tag, 'setRecord: auth + private key + account required');
      return false;
    }

    final tooBig = record.chainSizeProblem;
    if (tooBig != null) {
      PublicOS.lastError = tooBig;
      Log.w(_tag, 'setRecord: ${record.key} refused before sending (${record.chainValueBytes} bytes)');
      return false;
    }

    try {
      Log.i(_tag, 'setRecord: ${record.key}');

      final subtypeStr = record.subtype ?? '';
      final recordValueJson = record.toChainJson();

      final txHash = await Future.any([
        PublicOSBsp.recordManagerContract.setRecord(
          (
            target: EthereumAddress.fromHex(PublicOS.myPublicosAddress!),
            key: record.key,
            value: recordValueJson,
            expiration: record.chainExpiration,
            recordType: BigInt.from(record.type.index),
            customType: subtypeStr,
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15))
            .then((_) => throw TimeoutException('setRecord send timed out')),
      ]);

      Log.i(_tag, 'setRecord tx sent: $txHash — waiting for receipt...');
      final confirmed = await TxUtils.waitForReceipt(
        txHash,
        label: 'setRecord(${record.key})',
      );
      if (!confirmed) return false;

      // Write-through: re-fetch from chain and update the DB row so
      // consumer UIs see the new record on their next getContact() call.
      try {
        final fresh = await fetchContact(
          EthereumAddress.fromHex(PublicOS.myPublicosAddress!),
        );
        await saveContact(fresh);
      } catch (e) {
        Log.w(_tag, 'setRecord: post-commit refresh failed (chain write succeeded): $e');
      }

      return true;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'setRecord error: $e');
      return false;
    }
  }

  /// Batch-write multiple records for the current user in one transaction.
  ///
  /// The single on-chain write that backs the profile "bake" (assigning ranks
  /// to a whole profile at once) and any future bulk record op. Encodes each
  /// record's value as JSON exactly like [setRecord], delegates to the
  /// AccountManager `setMultipleRecords` (one atomic tx, one RecordSet per
  /// record), then write-through refreshes the local DB copy.
  ///
  /// Returns true only if the tx is confirmed on-chain. The DB refresh is
  /// best-effort (a failure there is logged, not fatal — the chain write held).
  static Future<bool> setMultipleRecords(List<Record> records) async {
    if (!PublicOS.isAuthenticated ||
        PublicOS.currentBlockchainPrivateKey == null ||
        PublicOS.myPublicosAddress == null) {
      Log.e(_tag, 'setMultipleRecords: auth + private key + account required');
      return false;
    }
    if (records.isEmpty) {
      Log.w(_tag, 'setMultipleRecords: empty batch, nothing to do');
      return false;
    }

    for (final r in records) {
      final tooBig = r.chainSizeProblem;
      if (tooBig != null) {
        PublicOS.lastError = tooBig;
        Log.w(_tag, 'setMultipleRecords: ${r.key} refused before sending (${r.chainValueBytes} bytes)');
        return false;
      }
    }

    try {
      Log.i(_tag, 'setMultipleRecords: ${records.length} records');

      final keys = [for (final r in records) r.key];
      final values = [for (final r in records) r.toChainJson()];
      final expirations = [
        for (final r in records)
          r.chainExpiration
      ];
      final recordTypes = [for (final r in records) BigInt.from(r.type.index)];
      final customTypes = [for (final r in records) r.subtype ?? ''];

      final txHash = await Future.any([
        PublicOSBsp.recordManagerContract.setMultipleRecords(
          (
            target: EthereumAddress.fromHex(PublicOS.myPublicosAddress!),
            keys: keys,
            values: values,
            expirations: expirations,
            recordTypes: recordTypes,
            customTypes: customTypes,
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 20)).then(
            (_) => throw TimeoutException('setMultipleRecords send timed out')),
      ]);

      Log.i(_tag,
          'setMultipleRecords tx sent: $txHash — waiting for receipt...');
      final confirmed = await TxUtils.waitForReceipt(
        txHash,
        label: 'setMultipleRecords(${records.length})',
      );
      if (!confirmed) return false;

      // Write-through: re-fetch from chain and update the DB row so consumer
      // UIs see the new ranks on their next getContact() call.
      try {
        final fresh = await fetchContact(
          EthereumAddress.fromHex(PublicOS.myPublicosAddress!),
        );
        await saveContact(fresh);
      } catch (e) {
        Log.w(_tag,
            'setMultipleRecords: post-commit refresh failed (chain write succeeded): $e');
      }

      return true;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'setMultipleRecords error: $e');
      return false;
    }
  }

  /// Assigns fresh, evenly-spaced LexoRank ranks to [orderedRecords] in their
  /// given visual order, returning new Record copies (rank written into
  /// metadata via [Record.copyWith]). The building block for the own-profile
  /// "bake": pass the grid records in display order, then persist the result in
  /// one shot via [setMultipleRecords] (individual) or the governance batch
  /// (org). Pure — does no I/O.
  static List<Record> withRanks(List<Record> orderedRecords) {
    final ranks = nKeysBetween(null, null, orderedRecords.length);
    return [
      for (var i = 0; i < orderedRecords.length; i++)
        orderedRecords[i].copyWith(rank: ranks[i]),
    ];
  }

  /// Delete an on-chain record for the current user, then refresh the local
  /// DB copy. Same write-through pattern as [setRecord].
  static Future<bool> deleteRecord(String key) async {
    if (!PublicOS.isAuthenticated ||
        PublicOS.currentBlockchainPrivateKey == null ||
        PublicOS.myPublicosAddress == null) {
      Log.e(_tag, 'deleteRecord: auth + private key + account required');
      return false;
    }

    try {
      final txHash = await Future.any([
        PublicOSBsp.recordManagerContract.deleteRecord(
          (
            target: EthereumAddress.fromHex(PublicOS.myPublicosAddress!),
            key: key,
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15))
            .then((_) => throw TimeoutException('deleteRecord send timed out')),
      ]);

      Log.i(_tag, 'deleteRecord tx sent: $txHash — waiting for receipt...');
      final confirmed =
          await TxUtils.waitForReceipt(txHash, label: 'deleteRecord($key)');
      if (!confirmed) return false;

      try {
        final fresh = await fetchContact(
          EthereumAddress.fromHex(PublicOS.myPublicosAddress!),
        );
        await saveContact(fresh);
      } catch (e) {
        Log.w(_tag, 'deleteRecord: post-commit refresh failed: $e');
      }

      return true;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'deleteRecord error: $e');
      return false;
    }
  }

  /// Delete EVERY record of the signed-in account.
  /// Calls `RecordManager.clearAllRecords(me, 50)`
  /// pass after pass until the account holds no records, or a pass removes
  /// nothing (what is left is system-reserved keys, which the contract skips).
  /// Reports progress through [onProgress] (removed so far, still on chain).
  /// Returns how many records were removed, or null when a pass failed
  /// ([PublicOS.lastError] says why). Re-fetches the self contact at the end,
  /// so `selfContactUpdates` repaints the profile.
  static Future<int?> clearAllMyRecords({
    void Function(int removed, int left)? onProgress,
  }) async {
    if (!PublicOS.isAuthenticated ||
        PublicOS.currentBlockchainPrivateKey == null ||
        PublicOS.myPublicosAddress == null) {
      Log.e(_tag, 'clearAllMyRecords: auth + private key + account required');
      return null;
    }
    final me = EthereumAddress.fromHex(PublicOS.myPublicosAddress!);
    final blueprint = PublicOSBsp.accountFromHex(me.eip55With0x);
    var removed = 0;
    try {
      var left = (await blueprint.getRecordCount()).toInt();
      onProgress?.call(removed, left);
      for (var pass = 0; pass < 40 && left > 0; pass++) {
        final txHash = await PublicOSBsp.recordManagerContract.clearAllRecords(
          (target: me, limit: BigInt.from(50)),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        );
        final ok = await TxUtils.waitForReceipt(txHash,
            label: 'clearAllRecords(pass ${pass + 1})');
        if (!ok) {
          PublicOS.lastError ??= 'clearAllRecords: transaction reverted or timed out';
          return null;
        }
        final now = (await blueprint.getRecordCount()).toInt();
        if (now >= left) break; // only reserved keys remain
        removed += left - now;
        left = now;
        onProgress?.call(removed, left);
      }
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, 'clearAllMyRecords error: $e');
      return null;
    }
    try {
      final fresh = await fetchContact(me);
      await saveContact(fresh);
    } catch (e) {
      Log.w(_tag, 'clearAllMyRecords: post-commit refresh failed: $e');
    }
    return removed;
  }

  /// Get a single record from chain for the given account (defaults to the
  /// current user). Read-only, doesn't touch the DB.
  static Future<Record?> getRecord(
      String key, EthereumAddress? targetAccountAddress) async {
    var addr = targetAccountAddress;
    if (addr == null && PublicOS.myPublicosAddress != null) {
      addr = EthereumAddress.fromHex(PublicOS.myPublicosAddress!);
    }
    if (addr == null) return null;

    try {
      final result = await Future.any([
        PublicOSBsp.accountFromHex(addr.eip55With0x).getRecord((key: key)),
        Future.delayed(const Duration(seconds: 5))
            .then((_) => throw TimeoutException('getRecord timed out')),
      ]);
      // Expiration + expiry status come from the contract (the single source of
      // truth), not the value blob. See [Record.toChainValue].
      return Record.fromJson(jsonDecode(result.value)).copyWith(
        expiration:
            Record.expirationFromChain(result.expiration),
        isExpired: result.expired,
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'getRecord($key) error: $e');
      return null;
    }
  }

  /// Get all records of a type for an account.
  static Future<List<Record>> getRecordsByType(
    RecordType type, {
    EthereumAddress? targetAccountAddress,
    String? publicosId,
  }) async {
    try {
      EthereumAddress? address;
      if (targetAccountAddress != null) {
        address = targetAccountAddress;
      } else if (publicosId != null) {
        address = await getPublicosAddressByPublicosDisplayName(publicosId);
      } else if (PublicOS.myPublicosAddress != null) {
        address = EthereumAddress.fromHex(PublicOS.myPublicosAddress!);
      }
      if (address == null) return [];

      final all = await getAllUserRecords(address);
      return all.where((r) => r.type == type).toList();
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'getRecordsByType($type) error: $e');
      return [];
    }
  }

  /// Fetch all records for an account from chain (non-paginated).
  /// Results are sorted: profile card/social records by their `order` field.
  ///
  /// **Best-effort — returns `[]` on ANY failure** (timeout, RPC error, revert).
  /// That makes a failed read INDISTINGUISHABLE from a genuinely empty profile.
  /// Callers that persist the result, or that must tell "this profile is empty"
  /// from "the chain was unreachable", MUST use [getAllUserRecordsOrThrow] —
  /// otherwise a transient blip is written to the DB as fact.
  static Future<List<Record>> getAllUserRecords(EthereumAddress accountAddress) async {
    try {
      return await getAllUserRecordsOrThrow(accountAddress);
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'getAllUserRecords error: $e');
      return [];
    }
  }

  /// Like [getAllUserRecords], but a failed chain read **throws** instead of
  /// collapsing to `[]`.
  ///
  /// With this variant an empty list provably means "this account has no
  /// records" and never "the read failed" — which is what makes a write-through
  /// safe (you can't persist an outage as an empty profile) and a "no longer
  /// available" verdict honest.
  ///
  /// Malformed INDIVIDUAL records are still skipped rather than thrown on: a
  /// single bad blob shouldn't sink an otherwise good read. Only a failure of
  /// the read ITSELF propagates.
  static Future<List<Record>> getAllUserRecordsOrThrow(
      EthereumAddress accountAddress) async {
    try {
      final result = await Future.any([
        PublicOSBsp.accountFromHex(accountAddress.eip55With0x).getAllRecords(),
        Future.delayed(const Duration(seconds: 10))
            .then((_) => throw TimeoutException('getAllUserRecords timed out')),
      ]);

      final expiredFlags = result.expired as List<dynamic>;
      final records = <Record>[];
      for (var i = 0; i < result.keys.length; i++) {
        try {
          final decodedMap = jsonDecode(result.values[i]) as Map<String, dynamic>;
          // Expiration + expiry status come from the contract (the single source
          // of truth), not the value blob. See [Record.toChainValue].
          records.add(Record.fromJson(decodedMap).copyWith(
            expiration: Record.expirationFromChain(
                result.expirations[i]),
            isExpired: expiredFlags[i] as bool,
          ));
        } catch (e) {
          Log.e(_tag, 'getAllUserRecords: malformed record at $i: $e');
          continue;
        }
      }

      // Mixed-read ordering for grid + social-strip records:
      // ranked records first (by their LexoRank
      // string), then unranked records in chain-enumeration order. Applied only
      // among card/social records and spliced back into the exact slots they
      // occupied, so identity/text/status records never move. This read path
      // only ORDERS — it never synthesizes ephemeral ranks (those are a display
      // concern assigned by the client; synthesizing here would leak into the
      // DB on saveContact and blur the ranked/unranked distinction).
      bool gridSortable(Record r) =>
          r.type == RecordType.profile &&
          (r.profileSubtype == ProfileSubtype.card ||
              r.profileSubtype == ProfileSubtype.social);

      final slots = <int>[];
      for (var i = 0; i < records.length; i++) {
        if (gridSortable(records[i])) slots.add(i);
      }
      if (slots.length > 1) {
        final sortable = [for (final i in slots) records[i]];
        final ranked = sortable.where((r) => r.rank != null).toList()
          ..sort((a, b) => a.rank!.compareTo(b.rank!));
        final unranked = sortable.where((r) => r.rank == null).toList();
        final ordered = [...ranked, ...unranked];
        for (var k = 0; k < slots.length; k++) {
          records[slots[k]] = ordered[k];
        }
      }

      return records;
    } catch (e) {
      // Log and propagate. Swallowing the error here would turn every
      // downstream stale-fallback into dead code.
      Log.e(_tag, 'getAllUserRecordsOrThrow error: $e');
      rethrow;
    }
  }

  /// Check if a PublicOS display name is registered on chain.
  static Future<bool> isUsernameRegistered(String username) async {
    try {
      final address = await getPublicosAddressByPublicosDisplayName(username);
      return address != null &&
          address != EthereumAddress.fromHex('0x0000000000000000000000000000000000000000');
    } catch (e) {
      PublicOS.lastError = e.toString();
      return false;
    }
  }

  /// Check if a session address is authorized for a specific account.
  /// For "is X a session of the current user?" use [PublicOSAccounts.isValidSession].
  static Future<bool> isSession(
      String accountAddressHex, String sessionAddressHex) async {
    try {
      return await Future.any([
        PublicOSBsp.accountManagerContract.isValidSessionForAccount((
          accountAddress: EthereumAddress.fromHex(accountAddressHex),
          sessionAddress: EthereumAddress.fromHex(sessionAddressHex),
        )),
        Future.delayed(const Duration(seconds: 5))
            .then((_) => throw TimeoutException('isSession timed out')),
      ]);
    } catch (e) {
      PublicOS.lastError = e.toString();
      return false;
    }
  }

  /// Get all session addresses for any account (chain read).
  static Future<List<String>> getUserSessions(EthereumAddress accountAddress) async {
    try {
      final addresses = await Future.any([
        PublicOSBsp.accountMemoryContract
            .getAccountSessions((accountAddress: accountAddress)),
        Future.delayed(const Duration(seconds: 5))
            .then((_) => throw TimeoutException('getUserSessions timed out')),
      ]);
      return addresses.map((a) => a?.eip55With0x).whereType<String>().toList();
    } catch (e) {
      PublicOS.lastError = e.toString();
      return [];
    }
  }

  /// Get the PublicOS display name for a session address, or null if the
  /// session isn't linked to any registered account.
  static Future<String?> getSessionOsuxId(String sessionAddressHex) async {
    try {
      final accountAddress = await Future.any([
        PublicOSBsp.accountManagerContract.getAccountAddressForSession(
          (sessionAddress: EthereumAddress.fromHex(sessionAddressHex)),
        ),
        Future.delayed(const Duration(seconds: 5))
            .then((_) => throw TimeoutException('getSessionOsuxId timed out')),
      ]);

      if (accountAddress ==
          EthereumAddress.fromHex('0x0000000000000000000000000000000000000000')) {
        return null;
      }
      return getPublicosDisplayNameByAccountAddress(accountAddress);
    } catch (e) {
      PublicOS.lastError = e.toString();
      return null;
    }
  }

  /// Resolve a PublicOS display name to an account address.
  static Future<EthereumAddress?> getPublicosAddressByPublicosDisplayName(
      String displayName) async {
    try {
      final address = await Future.any([
        PublicOSBsp.accountMemoryContract
            .getAccountAddressByDisplayName((displayName: displayName)),
        Future.delayed(const Duration(seconds: 5))
            .then((_) => throw TimeoutException('displayName lookup timed out')),
      ]);
      if (address ==
          EthereumAddress.fromHex('0x0000000000000000000000000000000000000000')) {
        return null;
      }
      return address;
    } catch (e) {
      PublicOS.lastError = e.toString();
      return null;
    }
  }

  /// Resolve an account address to a PublicOS display name.
  static Future<String?> getPublicosDisplayNameByAccountAddress(
      EthereumAddress accountAddress) async {
    try {
      final displayName = await Future.any([
        PublicOSBsp.accountMemoryContract
            .getDisplayName((accountAddress: accountAddress)),
        Future.delayed(const Duration(seconds: 5))
            .then((_) => throw TimeoutException('displayName lookup timed out')),
      ]);
      return displayName.isEmpty ? null : displayName;
    } catch (e) {
      PublicOS.lastError = e.toString();
      return null;
    }
  }
}
