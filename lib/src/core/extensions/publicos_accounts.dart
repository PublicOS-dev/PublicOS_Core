import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart';
import 'package:wallet/wallet.dart';
import 'package:publicos_core/src/core/core.dart';
import 'package:publicos_core/src/config/profile_templates.dart';
import 'package:publicos_core/src/models/record_model.dart';
import 'package:publicos_core/src/utils/consent_uri.dart';
import 'package:publicos_core/src/utils/display_name_validator.dart';
import 'package:publicos_core/src/utils/eip712_consent.dart' as eip712;
import 'package:publicos_core/src/utils/log.dart';
import 'package:publicos_core/src/utils/tx_utils.dart';

/// Account management extension for PublicOS.
/// Handles account creation, key management, and account selection.
extension PublicOSAccounts on PublicOS {
  static const _tag = 'Accounts';

  /// Generate a new private key
  static Uint8List _generatePrivateKey() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(32, (i) => random.nextInt(256)),
    );
  }

  /// Create a new temporary account for onboarding
  static Future<String> initializeTemporarySession() async {
    if (!PublicOS.isAuthenticated) {
      throw Exception('Authentication required');
    }

    try {
      Log.d(_tag, 'Creating new key pair private keys');

      // Generate and store new private key
      final privateKeyBytes = _generatePrivateKey(); // Renamed for clarity
      final dbKeyBytes = _generatePrivateKey(); // Renamed for clarity
      PublicOS.currentBlockchainPrivateKey = EthPrivateKey(privateKeyBytes);
      PublicOS.currentBlockchainDbKey = dbKeyBytes;
      Log.d(_tag, 'Temporary blockchain private key and DB key generated');

      // Store with temporary name
      await PublicOS.secureStorage.write(
        key: 'account_temporaryAccount_private_key',
        value: base64Encode(privateKeyBytes),
      );

      // Store with temporary name
      await PublicOS.secureStorage.write(
        key: 'account_temporaryAccount_encryption_key',
        value: base64Encode(dbKeyBytes),
      );

      // XMTP client initialization is no longer done here.
      // The address is derived directly from the blockchain private key.
      final String blockchainAddress = PublicOS.currentBlockchainPrivateKey!.address.eip55With0x;
      Log.d(_tag, 'Temporary blockchain session address derived: $blockchainAddress');

      // Remember the blockchain session address
      await PublicOS.secureStorage.write(
        key: 'temporaryAccountSessionAddress', // This stores the blockchain session address
        value: blockchainAddress,
      );

      // Set as selected account
      await PublicOS.secureStorage.write(
        key: 'selected_publicos_AccountAddress',
        value: 'temporaryAccount', // This will be updated upon activation
      );

      PublicOS.sessionBlockchainAddress = blockchainAddress;
      PublicOS.myPublicosAddress = null; // No on-chain account for a temporary, unactivated session

      Log.d(_tag, 'Temporary blockchain keys stored and sessionBlockchainAddress set to: $blockchainAddress');

      return blockchainAddress;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error creating temporary account: $e');
      rethrow;
    }
  }

  static Future<EthereumAddress?> getSelectedAccountAddress() async {
    if (!PublicOS.isAuthenticated) {
      throw Exception('Authentication required');
    }

    try {
      final selectedAccountAddress = await PublicOS.secureStorage.read(key: 'selected_publicos_AccountAddress');
      // final selectedAccountAddress = null;
      return EthereumAddress.fromHex(selectedAccountAddress!);
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting current session address: $e');
      return null;
    }
  }

  static Future<bool> doesTemporarySessionExist() async {
    try {
      return await PublicOS.secureStorage.containsKey(key: 'temporaryAccountSessionAddress');
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error checking new key pair existence: $e');
      return false;
    }
  }

  /// Delete New key pair and all associated data
  static Future<bool> deleteTemporarySession() async {
    if (!PublicOS.isAuthenticated) {
      throw Exception('Authentication required');
    }

    try {
      Log.d(_tag, 'Deleting new key pair');

      // Delete temporary private key
      await PublicOS.secureStorage.delete(key: 'account_temporaryAccount_private_key');

      // Delete temporary encryption key
      await PublicOS.secureStorage.delete(key: 'account_temporaryAccount_encryption_key');

      // Delete New key pair address
      await PublicOS.secureStorage.delete(key: 'temporaryAccountSessionAddress');

      // Delete signed link-device claim (bound to the temp key)
      await PublicOS.secureStorage.delete(key: 'account_temporaryAccount_signed_claim');

      Log.d(_tag, 'New key pair deleted successfully');
      return true;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error deleting new key pair: $e');
      return false;
    }
  }

  /// Check whether a pending temporary session address has been linked to an
  /// on-chain account yet. If so, promote the temp keys from the
  /// `temporaryAccount*` secure-storage slots into the account-scoped slots
  /// (`account_{address}_*`) so the account appears in the local list, and
  /// return the account address as a hex string.
  ///
  /// **This function does NOT load a session.** No keys are decrypted into
  /// memory, no contact is fetched, no RPC is swung. Callers that want to
  /// enter the logged-in state for the returned account must explicitly do:
  ///
  ///     final addr = await checkAndActivatePendingTemporarySession();
  ///     if (addr != null) {
  ///       await PublicOSAccounts.restoreSession(EthereumAddress.fromHex(addr));
  ///       await PublicOS.initBSP();
  ///       await PublicOS.initSSP();
  ///       await PublicOS.initXMTP();
  ///     }
  ///
  /// Typical first-login flows (mnemonic import → "am I linked?") just want
  /// the boolean + address and let the UI decide when to actually log in
  /// (e.g. after the user taps the account card in the select-account list).
  /// Session-swap flows (post-createAccount "become the friend I just made")
  /// explicitly call the restoreSession → initBSP chain after activation.
  ///
  /// Returns the EIP-55 account address on success, or `null` if the temp
  /// session isn't linked yet (still waiting for the on-chain registration).
  static Future<String?> checkAndActivatePendingTemporarySession() async {
    if (!PublicOS.isAuthenticated) {
      // Need auth to access secure storage potentially? Let's allow for now,
      // but activation requires subsequent loading which *does* need auth state.
      Log.w(_tag, 'Checking activation without prior auth');
    }
    final pendingSessionAddressHex = await PublicOS.secureStorage.read(key: "temporaryAccountSessionAddress"); // Replace with actual value or logic

    Log.d(_tag, 'Checking activation for pending session: $pendingSessionAddressHex');

    try {
      // Pure check: is the temp session linked to an on-chain account? This
      // read uses the hardcoded `accountManagerAddress` default from
      // PublicOSBsp, which matches the current deployment. We deliberately
      // do NOT call `resolveModuleAddresses` here — that's initBSP's job
      // and activation is meant to be a lightweight yes/no.
      final accountAddress = await PublicOSBsp.accountManagerContract.getAccountAddressForSession((sessionAddress: EthereumAddress.fromHex(pendingSessionAddressHex!)));

      if (accountAddress != EthereumAddress.fromHex("0x0000000000000000000000000000000000000000")) {
        Log.i(_tag, 'Activation detected! Account: ${accountAddress.eip55With0x} for Session: $pendingSessionAddressHex');
        // Promote temp keys to account-scoped secure-storage slots. This
        // is purely a storage rename + one chain read for the display name.
        // No session is loaded — that's the caller's job via restoreSession
        // + initBSP when/if they want to become this account.
        await _transferTemporarySessionTo(accountAddress.eip55With0x, pendingSessionAddressHex);
        Log.i(_tag, 'New key pair $pendingSessionAddressHex activated to ${accountAddress.eip55With0x}');
        return accountAddress.eip55With0x; // Return the activated account address
      } else {
        Log.d(_tag, 'Session $pendingSessionAddressHex is not yet associated with an account');
        return null; // Not activated
      }
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error checking/activating pending session $pendingSessionAddressHex: $e');
      return null;
    }
  }

  // / Convert temporary account to permanent account with username needs temporary account to be loaded
  static Future<bool> _transferTemporarySessionTo(String publicosAccountAddr, String sessionHex) async {
    Log.d(_tag, 'isAuthenticated: ${PublicOS.isAuthenticated}');
    if (!PublicOS.isAuthenticated) {
      throw Exception('Authentication and private key on OsuxCore required');
    }

    String publicosDisplayName = await PublicOSBsp.accountMemoryContract.getDisplayName((accountAddress: EthereumAddress.fromHex(publicosAccountAddr)));
    if (publicosDisplayName.isEmpty) {
      Log.e(_tag, 'Contact $publicosAccountAddr not found');
      return false;
    }

    try {
      Log.d(_tag, 'Transferring temp session to: $publicosDisplayName');

      final privateKeyStr = await PublicOS.secureStorage.read(key: 'account_temporaryAccount_private_key');
      final dbKeyStr = await PublicOS.secureStorage.read(key: 'account_temporaryAccount_encryption_key');
      final mnemonicStr = await PublicOS.secureStorage.read(key: 'account_temporaryAccount_mnemonic');

      if (privateKeyStr == null || dbKeyStr == null) {
        Log.e(_tag, 'Failed to restore private key or DB key');
        return false;
      }

      // Store account private Key with new account address
      await PublicOS.secureStorage.write(
        key: 'account_${publicosAccountAddr}_private_key',
        value: privateKeyStr,
      );
      Log.d(_tag, 'Stored private key to $publicosAccountAddr');

      // Store account encryption key with new account address
      await PublicOS.secureStorage.write(
        key: 'account_${publicosAccountAddr}_encryption_key',
        value: dbKeyStr,
      );
      Log.d(_tag, 'Stored encryption key to $publicosAccountAddr');

      // Store mnemonic if available
      if (mnemonicStr != null && mnemonicStr.isNotEmpty) {
        await PublicOS.secureStorage.write(
          key: 'account_${publicosAccountAddr}_mnemonic',
          value: mnemonicStr,
        );
        Log.d(_tag, 'Stored mnemonic to $publicosAccountAddr');
      }

      // OsuxDisplayName_Stored
      await PublicOS.secureStorage.write(
        key: 'account_${publicosAccountAddr}_displayName',
        value: publicosDisplayName,
      );

      // OsuxDisplayName_Stored
      await PublicOS.secureStorage.write(
        key: 'account_${publicosAccountAddr}_sessionAddress',
        value: sessionHex,
      );

      Log.d(_tag, 'Stored publicosAddress for $publicosDisplayName');

      // Update selected account
      await PublicOS.secureStorage.write(
        key: 'selected_publicos_AccountAddress',
        value: publicosAccountAddr,
      );

      // Delete temporary account
      await PublicOS.secureStorage.delete(key: 'account_temporaryAccount_private_key');
      await PublicOS.secureStorage.delete(key: 'account_temporaryAccount_encryption_key');
      await PublicOS.secureStorage.delete(key: 'temporaryAccountSessionAddress');
      await PublicOS.secureStorage.delete(key: 'account_temporaryAccount_signed_claim');

      Log.d(_tag, 'Deleted temporary keys');
      Log.i(_tag, 'Temp session transferred successfully to $publicosDisplayName');
      return true;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error converting temporary account: $e');
      return false;
    }
  }

  /// Restores a session for the given PublicOS account address.
  ///
  /// Sets global state: [PublicOS.currentBlockchainPrivateKey],
  /// [PublicOS.sessionBlockchainAddress], [PublicOS.myPublicosAddress]. The
  /// freshly fetched contact is saved to the local DB; consumers read it
  /// via `PublicOSContacts.getContact()` rather than from memory.
  ///
  /// **Multi-account pattern:** For contract calls on behalf of other accounts
  /// without switching the global session, pass `credentials: EthPrivateKey`
  /// directly to contract write methods (e.g. `contract.addSession(args,
  /// credentials: otherKey)`). All generated contract bindings accept this
  /// parameter. Use session switching for feed/message operations that rely on
  /// global state, and explicit credentials for isolated contract calls.
  ///
  /// **NOT concurrency-safe.** If multiple async loops call this on the same
  /// isolate, interleaving will corrupt global state. Consumers with concurrent
  /// session needs (e.g. poller + simulation) must implement their own mutex.
  static Future<bool> restoreSession(EthereumAddress? publicosAccountAddressToLoad) async {
    try {
      if (!PublicOS.isInitialized) {
        throw Exception('Core not initialized');
      }

      if (!PublicOS.isAuthenticated) {
        throw Exception('PublicOS Auth: Core not Authenticated');
      }
      Log.i(_tag, 'User authenticated successfully');

      // PublicOS.secureStorage.write(key: 'selected_publicos_AccountAddress', value: publicosAddressToBeRestored);

      Log.d(_tag, 'Reading selected account');
      final currentContactosDisplayName = await PublicOS.secureStorage.read(
        key: 'account_${publicosAccountAddressToLoad!.eip55With0x}_displayName',
      );

      if (currentContactosDisplayName == null) {
        Log.w(_tag, 'No display name found for account');
        return false;
      }

      Log.d(_tag, 'Reading selected account session');
      final currentContactosSessionAddress = await PublicOS.secureStorage.read(
        key: 'account_${publicosAccountAddressToLoad.eip55With0x}_sessionAddress',
      );

      if (currentContactosSessionAddress == null) {
        Log.w(_tag, 'No session address found for account');
        return false;
      }

      Log.d(_tag, 'Check session $currentContactosSessionAddress is session for selected account: ${publicosAccountAddressToLoad.eip55With0x}');
      final accountLinkedToSession = await PublicOSBsp.accountManagerContract.getAccountAddressForSession((sessionAddress: EthereumAddress.fromHex(currentContactosSessionAddress)));

      if (publicosAccountAddressToLoad != accountLinkedToSession) {
        Log.e(_tag, 'Account+Address mismatch');
        return false;
      }
      // Attempt to restore user's private key and XMTP client

      final privateKeyStr = await PublicOS.secureStorage.read(key: 'account_${publicosAccountAddressToLoad.eip55With0x}_private_key');
      final dbKeyStr = await PublicOS.secureStorage.read(key: 'account_${publicosAccountAddressToLoad.eip55With0x}_encryption_key');
      if (privateKeyStr == null || dbKeyStr == null) {
        Log.e(_tag, 'Failed to restore private key or DB key');
        return false;
      }

      // Decode private key (hex string format - new format)
      final privateKeyHex = utf8.decode(base64Decode(privateKeyStr));
      Log.d(_tag, 'Blockchain private key recovered successfully');

      PublicOS.currentBlockchainDbKey = base64Decode(dbKeyStr);
      Log.d(_tag, 'Blockchain DB key restored successfully');
      PublicOS.currentBlockchainPrivateKey = EthPrivateKey.fromHex(privateKeyHex);
      Log.d(_tag, 'Blockchain private key restored successfully');

      if (PublicOS.currentBlockchainDbKey == null || PublicOS.currentBlockchainPrivateKey == null) {
        Log.e(_tag, 'Failed to restore blockchain private key or DB key');
        return false;
      }

      // XMTP client initialization is now handled by PublicOS.loadLastUsedXmtpKey()
      // called from body_container.dart after session restoration.

      // Set sessionBlockchainAddress from the authoritative stored value.
      PublicOS.sessionBlockchainAddress = currentContactosSessionAddress;
      Log.d(_tag, 'Blockchain session address set to: ${PublicOS.sessionBlockchainAddress}');

      // Optional: Verify that the loaded private key corresponds to the stored session address.
      if (PublicOS.currentBlockchainPrivateKey!.address.eip55With0x.toLowerCase() != currentContactosSessionAddress.toLowerCase()) {
        Log.e(_tag, 'CRITICAL MISMATCH - Loaded private key ${PublicOS.currentBlockchainPrivateKey!.address.eip55With0x} does not match stored session address $currentContactosSessionAddress for the account');
        // Potentially return false or throw an error, as this indicates a serious inconsistency.
        // For now, just logging the critical error. Consider implications for app stability.
      } else {
        Log.d(_tag, 'Loaded private key corresponds to the stored session address');
      }

      // Fetch own contact from chain and persist to DB. We do NOT cache the
      // Contact object in memory — consumers read via PublicOSContacts.getContact().
      // requireRecords: this is the FIRST contact write of the session and it
      // targets our OWN row. A silent records:[] here blanks the self profile
      // at login and stamps it fresh. Note the self-gate inside fetchContact
      // can't help us — myPublicosAddress is only set below.
      //
      // Nested try, deliberately: a profile read that fails must NOT abort a
      // session restore that has otherwise succeeded. Keep whatever is already
      // stored; the next fetch refreshes it.
      try {
        final myContact = await PublicOSContacts.fetchContact(
          publicosAccountAddressToLoad,
          requireRecords: true,
        );
        await PublicOSContacts.saveContact(myContact);
      } catch (e) {
        Log.w(_tag,
            'restoreSession: profile refresh failed, keeping stored row: $e');
      }
      PublicOS.myPublicosAddress = publicosAccountAddressToLoad.eip55With0x;
      Log.i(_tag, 'Session restored, contact saved to DB');

      // Feed lists were the last table scoped by ACCOUNT while every other
      // per-user table scopes by SESSION (a user can hold several sessions for
      // one account on one device, and an account-scoped row cannot tell them
      // apart). This is the only point where BOTH
      // addresses are known, so the one-time re-key of legacy rows happens here
      // — a Drift onUpgrade cannot do it, because at DB-open time we do not yet
      // know who is signing in. Idempotent and non-fatal.
      await PublicOSFeedLists.migrateListScopeToSession();

      await PublicOS.secureStorage.write(
        key: 'selected_publicos_AccountAddress',
        value: publicosAccountAddressToLoad.eip55With0x,
      );

      // Save session address
      await PublicOS.secureStorage.write(
        key: 'selected_publicos_SessionAddress_${publicosAccountAddressToLoad.eip55With0x}',
        value: PublicOS.sessionBlockchainAddress!,
      );
      Log.d(_tag, 'Background sync session address saved');

      // RPC routing (BSP subscription → custom → public) is now PublicOS.initBSP's
      // responsibility. Consumer apps MUST call initBSP() after restoreSession().
      // We deliberately do NOT touch web3Client here — the session is set up,
      // but the RPC endpoint stays on whatever init() resolved (override or
      // public fallback) until initBSP swings it.

      return true;
    } on PlatformException catch (e) {
      PublicOS.lastError = 'Authentication failed: ${e.message}';
      Log.e(_tag, 'Platform error during authentication: $e');
      return false;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error during authentication: $e');
      return false;
    }
  }

  /// Get list of all account names
  static Future<Map<String, EthereumAddress>> getStoredAccountNames() async {
    if (!PublicOS.isAuthenticated) {
      throw Exception('Authentication required');
    }

    try {
      final allSecrets = await PublicOS.secureStorage.readAll();
      final entries = allSecrets.entries.where((entry) => entry.key.startsWith('account_') && entry.key.endsWith('_displayName')).where((entry) => entry.key != 'temp').map((entry) {
        final accountName = entry.key.replaceFirst('account_', '').replaceFirst('_displayName', '');
        return MapEntry(entry.value, EthereumAddress.fromHex(accountName));
      });

      // Convert the iterable of MapEntry objects to a Map
      return Map.fromEntries(entries);
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting account names: $e');
      return {};
    }
  }

  /// Delete an account and every secret + DB row tied to it on this device.
  ///
  /// Removes:
  ///   - every `account_${publicosAddr}_*` secure-storage entry (private key,
  ///     encryption key, mnemonic, displayName, sessionAddress)
  ///   - `selected_publicos_SessionAddress_${publicosAddr}`
  ///   - every secure-storage entry keyed by the account's session (signing)
  ///     address: `xmtp_selected_key_*`, `xmtp_last_key_*`,
  ///     `keychain_key_${session}_*`, `xmtp_db_key_${session}_*`,
  ///     `active_rpc_${session}`, `active_ssp_${session}`
  ///   - `selected_publicos_AccountAddress` if it pointed at this account
  ///   - every drift row (messages, contacts, conversations, settings,
  ///     feedServers, rpcServers, feedLists, bookmarkedApps, bookmarkedPosts)
  ///     scoped to the session address
  ///
  /// Pass the publicos account address (the on-chain account, not the session
  /// signing key). The on-chain account itself is untouched.
  static Future<bool> deleteStoredAccounts(
    EthereumAddress publicosAccountAddress,
  ) async {
    if (!PublicOS.isAuthenticated) {
      throw Exception('Authentication required');
    }

    final addressHex = publicosAccountAddress.eip55With0x;
    final addressLower = addressHex.toLowerCase();

    // Block deleting the currently active account. On the account selection
    // screen no account is loaded yet, in which case this check is a no-op.
    if (PublicOS.myPublicosAddress != null &&
        PublicOS.myPublicosAddress!.toLowerCase() == addressLower) {
      throw Exception('Cannot delete the currently active account');
    }

    try {
      Log.d(_tag, 'Deleting account: $addressHex');

      // Resolve the session (signing) address tied to this account so we can
      // also wipe XMTP/keychain/RPC entries that are keyed by it.
      final sessionAddress = await PublicOS.secureStorage.read(
        key: 'account_${addressHex}_sessionAddress',
      );
      final sessionLower = sessionAddress?.toLowerCase();

      // Wipe every secure-storage key that mentions either the publicos
      // address or the session address. Substring match (case-insensitive)
      // catches every prefix variant — present and future.
      final allSecrets = await PublicOS.secureStorage.readAll();
      final keysToDelete = <String>{};
      for (final key in allSecrets.keys) {
        final keyLower = key.toLowerCase();
        if (keyLower.contains(addressLower)) {
          keysToDelete.add(key);
          continue;
        }
        if (sessionLower != null &&
            sessionLower.isNotEmpty &&
            keyLower.contains(sessionLower)) {
          keysToDelete.add(key);
        }
      }
      for (final key in keysToDelete) {
        await PublicOS.secureStorage.delete(key: key);
      }

      // If this account was the last selected one, clear that pointer so the
      // next launch doesn't try to restore an account that no longer exists.
      final selected = await PublicOS.secureStorage.read(
        key: 'selected_publicos_AccountAddress',
      );
      if (selected != null && selected.toLowerCase() == addressLower) {
        await PublicOS.secureStorage.delete(
          key: 'selected_publicos_AccountAddress',
        );
      }

      // Scrub DB rows scoped to the session address. Every per-account drift
      // table uses sessionAddress as its tenancy column.
      if (sessionAddress != null && sessionAddress.isNotEmpty) {
        final db = PublicOS.database;
        await db.transaction(() async {
          await (db.delete(db.messages)
                ..where((m) => m.sessionAddress.equals(sessionAddress)))
              .go();
          await (db.delete(db.contacts)
                ..where((c) => c.sessionAddress.equals(sessionAddress)))
              .go();
          await (db.delete(db.conversations)
                ..where((c) => c.sessionAddress.equals(sessionAddress)))
              .go();
          await (db.delete(db.settings)
                ..where((s) => s.sessionAddress.equals(sessionAddress)))
              .go();
          await (db.delete(db.feedServers)
                ..where((f) => f.sessionAddress.equals(sessionAddress)))
              .go();
          await (db.delete(db.rpcServers)
                ..where((r) => r.sessionAddress.equals(sessionAddress)))
              .go();
          // ListFeeds rows cascade-delete via their FK to FeedLists.
          await (db.delete(db.feedLists)
                ..where((l) => l.sessionAddress.equals(sessionAddress)))
              .go();
          await (db.delete(db.bookmarkedApps)
                ..where((a) => a.sessionAddress.equals(sessionAddress)))
              .go();
          await (db.delete(db.bookmarkedPosts)
                ..where((p) => p.sessionAddress.equals(sessionAddress)))
              .go();
        });
      }

      Log.d(
        _tag,
        'Account $addressHex deleted (${keysToDelete.length} secrets, db scrubbed)',
      );
      return true;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error deleting account: $e');
      return false;
    }
  }

  /// Get the private key for the current account
  Future<Uint8List?> getCurrentPrivateKey() async {
    if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
      throw Exception('Authentication and selected account required');
    }

    try {
      // Account keys are stored under the publicos address (matching restoreSession).
      final privateKeyStr = await PublicOS.secureStorage.read(
        key: 'account_${PublicOS.myPublicosAddress!}_private_key',
      );

      if (privateKeyStr == null) return null;
      return base64Decode(privateKeyStr);
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting current private key: $e');
      return null;
    }
  }

  /// Get current db key
  Future<Uint8List?> getCurrentDbKey() async {
    if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
      throw Exception('Authentication and selected account required');
    }

    try {
      final dbKeyStr = await PublicOS.secureStorage.read(
        key: 'account_${PublicOS.myPublicosAddress!}_encryption_key',
      );

      if (dbKeyStr == null) return null;
      return base64Decode(dbKeyStr);
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting current db key: $e');
      return null;
    }
  }

  /// Check if account exists
  Future<bool> accountExists(String accountName) async {
    if (!PublicOS.isAuthenticated) {
      throw Exception('Authentication required');
    }

    try {
      return await PublicOS.secureStorage.containsKey(
        key: 'account_${accountName}_private_key',
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error checking account existence: $e');
      return false;
    }
  }

  static Future<EthereumAddress?> getAccountAddressForSession(EthereumAddress sessionAddress) async {
    try {
      final accountAddress = await Future.any([
        PublicOSBsp.accountManagerContract.getAccountAddressForSession(
          (sessionAddress: sessionAddress),
        ),
        Future.delayed(const Duration(seconds: 5)).then((_) => throw TimeoutException('getAccountAddressForSession timed out')),
      ]);
      if (accountAddress == EthereumAddress.fromHex('0x0000000000000000000000000000000000000000')) {
        return null;
      }
      return accountAddress;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting account address for session ${sessionAddress.eip55With0x}: $e');
      return null;
    }
  }

  /// Create a new on-chain account with [username] as the display name and
  /// [sessionAddress] as its first authorized session. The caller pays gas
  /// from the current session's private key; the resulting account is
  /// controlled by [sessionAddress], not the caller.
  ///
  /// Returns true only after the transaction is mined and the receipt
  /// reports success. On failure sets [PublicOS.lastError] with the
  /// underlying error message for the UI to surface (common cases:
  /// `NotRegisteredSender`, `Display name already taken`, send timeout,
  /// receipt revert).
  ///
  /// Caller can look up the resulting account address via
  /// [getAccountAddressForSession]. For the "I just created my own
  /// account and want to become it" flow, use
  /// [checkAndActivatePendingTemporarySession] which also performs the
  /// key transfer + session swap.
  /// Create a new on-chain account. Caller (msg.sender) is the minter — must
  /// be a registered session of a citizen account. The consent sig proves the
  /// new session's keyholder agreed to be bound to this `displayName`.
  ///
  /// Low-level path: caller supplies `(deadline, sig)` they assembled
  /// elsewhere (typically over QR/CBOR from the new device — see
  /// `eip712_consent.dart`). For the same-device case where the new key is
  /// in hand, use [createAccountWithLocalKey].
  static Future<bool> createAccount({
    required String displayName,
    required EthereumAddress firstSession,
    required BigInt deadline,
    required Uint8List sig,
  }) async {
    if (!PublicOS.isAuthenticated ||
        PublicOS.currentBlockchainPrivateKey == null) {
      PublicOS.lastError = 'createAccount: auth + private key required';
      Log.e(_tag, PublicOS.lastError!);
      return false;
    }
    if (displayName.isEmpty) {
      PublicOS.lastError = 'createAccount: displayName cannot be empty';
      Log.e(_tag, PublicOS.lastError!);
      return false;
    }

    try {
      Log.i(_tag, 'createAccount: $displayName → ${firstSession.eip55With0x}');

      // Pre-flight simulation: run the call via eth_call (from = sponsor)
      // before broadcasting. A revert here surfaces the contract's require()
      // reason, whereas gas estimation / sendTransaction strip it to a bare
      // "execution reverted". If it would revert, fail early with the real
      // reason instead of sending a doomed transaction.
      try {
        final contract = PublicOSBsp.accountManagerContract.self;
        await PublicOS.web3Client.call(
          sender: PublicOS.currentBlockchainPrivateKey!.address,
          contract: contract,
          function: contract.function('createAccount'),
          params: [displayName, firstSession, deadline, sig],
        );
      } catch (e) {
        PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
        Log.e(_tag, 'createAccount preflight reverted: ${PublicOS.lastError}');
        return false;
      }

      final txHash = await Future.any([
        PublicOSBsp.accountManagerContract.createAccount(
          (
            displayName: displayName,
            firstSessionAddress: firstSession,
            deadline: deadline,
            sig: sig,
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15))
            .then((_) => throw TimeoutException('createAccount send timed out')),
      ]);

      Log.i(_tag, 'createAccount tx sent: $txHash — waiting for receipt...');
      final confirmed = await TxUtils.waitForReceipt(
        txHash,
        label: 'createAccount($displayName)',
      );
      if (!confirmed) {
        PublicOS.lastError ??=
            'createAccount: transaction reverted or timed out';
      }
      return confirmed;
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, 'createAccount error: $e');
      return false;
    }
  }

  /// Convenience for the same-device case: signs the EIP-712
  /// `CreateAccountConsent` struct with `newSessionKey` locally, then
  /// submits via [createAccount]. The sponsor (minter) is the current
  /// blockchain key.
  static Future<bool> createAccountWithLocalKey({
    required String displayName,
    required EthPrivateKey newSessionKey,
    Duration validFor = const Duration(hours: 1),
  }) async {
    final newSession = newSessionKey.address;
    final signed = await signCreateAccountConsent(
      displayName: displayName,
      newSession: newSession,
      newSessionKey: newSessionKey,
      validFor: validFor,
    );
    return createAccount(
      displayName: displayName,
      firstSession: newSession,
      deadline: signed.deadline,
      sig: signed.sig,
    );
  }

  /// Build + sign a `CreateAccountConsent` for `newSession`. Returns the
  /// `(deadline, sig)` pair ready to feed [createAccount] or encode into a
  /// QR payload. `validFor` defaults to 1h (publicos_client UX default —
  /// the contract ceiling is 7d).
  static Future<({BigInt deadline, Uint8List sig})> signCreateAccountConsent({
    required String displayName,
    required EthereumAddress newSession,
    required EthPrivateKey newSessionKey,
    Duration validFor = const Duration(hours: 1),
    BigInt? protocolVersion, // agreements: the PROTOCOL version being accepted; read live when null
  }) async {
    final deadline = _deadlineSecs(validFor);
    final version = protocolVersion ?? await readProtocolAgreementVersion();
    final structHash = eip712.createAccountStructHash(
      displayName: displayName,
      newSession: newSession,
      deadline: deadline,
      protocolVersion: version,
    );
    final digest = _consentDigest(structHash);
    return (deadline: deadline, sig: eip712.signDigest(digest, newSessionKey));
  }

  ///*********************************************
  /// BOOTSTRAP INVITATION FLOW (temporary)
  ///
  /// Active only while the account manager has been swapped to
  /// AccountManagerWithInvite and the INVITATION_MANAGER module is registered
  /// (i.e. self-serve creation is paused — see [isAccountCreationPaused]).
  /// The new account's consent signature is IDENTICAL to the normal path
  /// (CreateAccountConsent, verified against the resolved ACCOUNT_MANAGER —
  /// which is AccountManagerWithInvite during the window). The only difference
  /// is the submit target: InvitationManager.createAccountWithInvite, which
  /// checks/decrements the sponsor's wave invite balance before forwarding.
  ///*********************************************

  /// The caller's account's current invite balance (lazy wave accounting).
  /// Returns 0 if the InvitationManager module isn't registered (outside the
  /// bootstrap window) or the caller has no account.
  static Future<int> myInvites() async {
    try {
      if (PublicOSBsp.invitationManagerAddress == null) return 0;
      final addrHex = PublicOS.myPublicosAddress;
      if (addrHex == null) return 0;
      final bal = await PublicOSBsp.invitationManagerContract
          .invitesOf((account: EthereumAddress.fromHex(addrHex)));
      return bal.toInt();
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'myInvites error: $e');
      return 0;
    }
  }

  /// The caller's current account display name (empty string on failure / no
  /// account). Read straight from AccountMemory.
  static Future<String> myDisplayName() async {
    try {
      final addrHex = PublicOS.myPublicosAddress;
      if (addrHex == null) return '';
      return await PublicOSBsp.accountMemoryContract
          .getDisplayName((accountAddress: EthereumAddress.fromHex(addrHex)));
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'myDisplayName error: $e');
      return '';
    }
  }

  /// Invite balance for an arbitrary account. 0 outside the bootstrap window.
  static Future<int> invitesOf(EthereumAddress account) async {
    try {
      if (PublicOSBsp.invitationManagerAddress == null) return 0;
      final bal = await PublicOSBsp.invitationManagerContract
          .invitesOf((account: account));
      return bal.toInt();
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'invitesOf error: $e');
      return 0;
    }
  }

  /// Spend one of the caller's invites to create a new account while self-serve
  /// creation is paused. Mirrors [createAccount] exactly (same consent sig,
  /// same preflight) but submits to InvitationManager instead of AccountManager.
  /// The minter is resolved on-chain from msg.sender; the citizen + invite
  /// checks live in the contract.
  static Future<bool> createAccountWithInvite({
    required String displayName,
    required EthereumAddress firstSession,
    required BigInt deadline,
    required Uint8List sig,
  }) async {
    if (!PublicOS.isAuthenticated ||
        PublicOS.currentBlockchainPrivateKey == null) {
      PublicOS.lastError = 'createAccountWithInvite: auth + private key required';
      Log.e(_tag, PublicOS.lastError!);
      return false;
    }
    if (PublicOSBsp.invitationManagerAddress == null) {
      PublicOS.lastError =
          'createAccountWithInvite: InvitationManager not registered';
      Log.e(_tag, PublicOS.lastError!);
      return false;
    }
    if (displayName.isEmpty) {
      PublicOS.lastError = 'createAccountWithInvite: displayName cannot be empty';
      Log.e(_tag, PublicOS.lastError!);
      return false;
    }

    try {
      Log.i(_tag,
          'createAccountWithInvite: $displayName → ${firstSession.eip55With0x}');

      // Pre-flight sim (from = sponsor) to surface the real revert reason.
      try {
        final contract = PublicOSBsp.invitationManagerContract.self;
        await PublicOS.web3Client.call(
          sender: PublicOS.currentBlockchainPrivateKey!.address,
          contract: contract,
          function: contract.function('createAccountWithInvite'),
          params: [displayName, firstSession, deadline, sig],
        );
      } catch (e) {
        PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
        Log.e(_tag,
            'createAccountWithInvite preflight reverted: ${PublicOS.lastError}');
        return false;
      }

      final txHash = await Future.any([
        PublicOSBsp.invitationManagerContract.createAccountWithInvite(
          (
            displayName: displayName,
            firstSessionAddress: firstSession,
            deadline: deadline,
            sig: sig,
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15)).then((_) =>
            throw TimeoutException('createAccountWithInvite send timed out')),
      ]);

      Log.i(_tag, 'createAccountWithInvite tx sent: $txHash — waiting...');
      final confirmed = await TxUtils.waitForReceipt(
        txHash,
        label: 'createAccountWithInvite($displayName)',
      );
      if (!confirmed) {
        PublicOS.lastError ??=
            'createAccountWithInvite: transaction reverted or timed out';
      }
      return confirmed;
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, 'createAccountWithInvite error: $e');
      return false;
    }
  }

  ///*********************************************
  /// SESSION MANAGEMENT METHODS
  ///*********************************************

  /// Get all sessions (authorized wallet addresses) for the current user's account
  static Future<List<EthereumAddress>> getMySessions() async {
    try {
      final accountAddress = PublicOS.myPublicosAddress != null ? EthereumAddress.fromHex(PublicOS.myPublicosAddress!) : null;
      if (accountAddress == null) {
        Log.w(_tag, 'No account address available');
        return [];
      }

      final sessions = await Future.any([
        PublicOSBsp.accountMemoryContract.getAccountSessions(
          (accountAddress: accountAddress),
        ),
        Future.delayed(const Duration(seconds: 5)).then((_) => throw TimeoutException('Request timed out')),
      ]);

      Log.d(_tag, 'Retrieved ${sessions.length} sessions for account ${accountAddress.eip55With0x}');
      return sessions;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting sessions: $e');
      return [];
    }
  }

  /// Add a new session (wallet address) to the current account. The consent
  /// sig proves the new session's keyholder agreed. Caller (msg.sender) must
  /// be a registered session of the account being extended.
  ///
  /// Agreements: the PROTOCOL agreement version a new account
  /// accepts. `createAccount` binds it into the consent and AccountManager
  /// re-reads it at submit time, so sign with the live value (kind 1 =
  /// AGREEMENT_KIND_PROTOCOL in AccountManager.sol).
  static Future<BigInt> readProtocolAgreementVersion() async {
    final v = await PublicOSBsp.agreementManagerContract
        .currentVersion((kind: BigInt.from(1)));
    return v;
  }

  /// Low-level path: caller supplies `(deadline, sig)` they assembled
  /// elsewhere. For the same-device case, use [addSessionWithLocalKey].
  static Future<bool> addSession({
    required EthereumAddress newSession,
    required BigInt deadline,
    required Uint8List sig,
    BigInt? ttl, // key expiry: seconds; null / 0 = permanent key. Must equal the ttl the consent was signed over.
  }) async {
    if (!PublicOS.isAuthenticated ||
        PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication and blockchain key required to add session');
      return false;
    }

    try {
      Log.d(_tag, 'Adding session ${newSession.eip55With0x}');

      final txHash = await Future.any([
        PublicOSBsp.accountManagerContract.addSession(
          (
            sessionToAdd: newSession,
            ttl: ttl ?? BigInt.zero,
            deadline: deadline,
            sig: sig,
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15))
            .then((_) => throw TimeoutException('addSession send timed out')),
      ]);

      Log.i(_tag, 'addSession tx sent: $txHash — waiting for receipt...');
      final confirmed = await TxUtils.waitForReceipt(
        txHash,
        label: 'addSession(${newSession.eip55With0x})',
      );
      if (!confirmed) {
        PublicOS.lastError ??= 'addSession: transaction reverted or timed out';
      }
      return confirmed;
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, 'addSession error: $e');
      return false;
    }
  }

  /// Same-device convenience: signs `SessionConsent` locally with
  /// `newSessionKey`, then submits via [addSession]. Veteran (current key) is
  /// the caller — must already be a registered session of the account.
  static Future<bool> addSessionWithLocalKey({
    required EthPrivateKey newSessionKey,
    Duration validFor = const Duration(hours: 1),
    BigInt? ttl, // key expiry: null / 0 = permanent key
  }) async {
    if (PublicOS.myPublicosAddress == null) {
      PublicOS.lastError = 'addSessionWithLocalKey: no account loaded';
      Log.e(_tag, PublicOS.lastError!);
      return false;
    }
    final newSession = newSessionKey.address;
    final account = EthereumAddress.fromHex(PublicOS.myPublicosAddress!);
    final signed = signAddSessionConsent(
      account: account,
      newSession: newSession,
      newSessionKey: newSessionKey,
      validFor: validFor,
      ttl: ttl,
    );
    return addSession(
      newSession: newSession,
      deadline: signed.deadline,
      sig: signed.sig,
      ttl: ttl,
    );
  }

  /// Build + sign `SessionConsent`. `account` is the account being
  /// extended (the veteran's account). `newSessionKey` produces both the
  /// address bound into the struct AND the signature.
  static ({BigInt deadline, Uint8List sig}) signAddSessionConsent({
    required EthereumAddress account,
    required EthereumAddress newSession,
    required EthPrivateKey newSessionKey,
    Duration validFor = const Duration(hours: 1),
    BigInt? ttl, // key expiry: signed into SessionConsent; null / 0 = permanent key
  }) {
    final deadline = _deadlineSecs(validFor);
    final structHash = eip712.sessionConsentStructHash(
      account: account,
      newSession: newSession,
      ttl: ttl ?? BigInt.zero,
      deadline: deadline,
    );
    final digest = _consentDigest(structHash);
    return (deadline: deadline, sig: eip712.signDigest(digest, newSessionKey));
  }

  ///*********************************************
  /// LINK-DEVICE CLAIM (new-device side of the consent signatures)
  ///
  /// The new device produces a signed, QR-ready consent for a sponsor to
  /// scan. All key handling + signing + persistence lives here so the UI
  /// (publicos_client / publicos_desktop) only renders the QR + countdown.
  ///*********************************************

  static const String _linkClaimStorageKey =
      'account_temporaryAccount_signed_claim';

  /// The temp session EOA on this device (becomes the new account's first
  /// session, or the session added to an existing account). Null if none.
  static Future<EthereumAddress?> getTemporarySessionAddress() async {
    final hex =
        await PublicOS.secureStorage.read(key: 'temporaryAccountSessionAddress');
    return hex == null ? null : EthereumAddress.fromHex(hex);
  }

  /// Decode the stored temp private key. PublicOSKeychain persists it as
  /// `base64(utf8(privateKeyHex))` — decode it the SAME way
  /// [PublicOSKeychain.loadTemporaryBlockchainKey] does. Decoding as raw
  /// bytes builds a bogus key whose address ≠ the real temp account.
  static Future<EthPrivateKey?> _loadTemporaryKey() async {
    final b64 = await PublicOS.secureStorage
        .read(key: 'account_temporaryAccount_private_key');
    if (b64 == null) return null;
    return EthPrivateKey.fromHex(utf8.decode(base64Decode(b64)));
  }

  /// Sign + persist a fresh link-device claim with the temp key. For
  /// [ConsentKind.newAccount] pass [displayName]; for [ConsentKind.addSession]
  /// pass [account]. Returns the QR-ready claim (whose `consentUri` the UI
  /// wraps in a `publicos://` deep link). `validFor` defaults to 1h.
  static Future<LinkDeviceClaim> signTemporaryLinkClaim({
    required ConsentKind kind,
    String? displayName,
    EthereumAddress? account,
    Duration validFor = const Duration(hours: 1),
    int ttlSeconds = 0, // key expiry, addSession only: 0 = permanent key
  }) async {
    final key = await _loadTemporaryKey();
    if (key == null) {
      throw StateError('signTemporaryLinkClaim: no temporary key on this device');
    }
    final newSession = key.address;
    final String consentUri;
    final BigInt deadline;
    final String input;
    if (kind == ConsentKind.newAccount) {
      if (displayName == null || displayName.isEmpty) {
        throw ArgumentError('displayName required for a newAccount claim');
      }
      final signed = await signCreateAccountConsent(
        displayName: displayName,
        newSession: newSession,
        newSessionKey: key,
        validFor: validFor,
      );
      deadline = signed.deadline;
      consentUri = encodeNewAccountUri(
        newSession: newSession,
        deadline: deadline,
        compactSig: toCompactSig(signed.sig),
        displayName: displayName,
      );
      input = displayName;
    } else {
      if (account == null) {
        throw ArgumentError('account required for an addSession claim');
      }
      final signed = signAddSessionConsent(
        account: account,
        newSession: newSession,
        newSessionKey: key,
        validFor: validFor,
        ttl: BigInt.from(ttlSeconds),
      );
      deadline = signed.deadline;
      consentUri = encodeAddSessionUri(
        newSession: newSession,
        deadline: deadline,
        compactSig: toCompactSig(signed.sig),
        account: account,
        ttl: BigInt.from(ttlSeconds), // `e` carries the signed lifetime to the sponsor, who must submit the same
      );
      input = account.eip55With0x;
    }
    final claim = LinkDeviceClaim(
      kind: kind,
      input: input,
      consentUri: consentUri,
      deadline: deadline,
      newSession: newSession,
      ttlSeconds: kind == ConsentKind.addSession ? ttlSeconds : 0,
    );
    await _persistLinkClaim(claim);
    Log.i(_tag,
        'signTemporaryLinkClaim: kind=$kind newSession=${newSession.eip55With0x} deadline=$deadline');
    return claim;
  }

  static Future<void> _persistLinkClaim(LinkDeviceClaim c) async {
    await PublicOS.secureStorage.write(
      key: _linkClaimStorageKey,
      value: jsonEncode({
        'kind': c.kind == ConsentKind.newAccount ? 'newAccount' : 'addSession',
        'input': c.input,
        'ttl': c.ttlSeconds,
        'newSession': c.newSession.eip55With0x,
        'deadline': c.deadline.toInt(),
        'uri': c.consentUri,
      }),
    );
  }

  /// Read + validate the persisted link claim against the current temp key.
  /// A claim bound to a since-replaced key (or corrupt) is stale — delete it
  /// and return null. Lets the UI reopen straight into the QR + countdown.
  static Future<LinkDeviceClaim?> loadTemporaryLinkClaim() async {
    try {
      final raw =
          await PublicOS.secureStorage.read(key: _linkClaimStorageKey);
      if (raw == null) return null;
      final key = await _loadTemporaryKey();
      if (key == null) {
        // No temp key → the claim is orphaned (unusable without its key). Wipe
        // it so a freshly generated/imported key never inherits a stale claim.
        await PublicOS.secureStorage.delete(key: _linkClaimStorageKey);
        return null;
      }
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final bound = (m['newSession'] as String?)?.toLowerCase();
      if (bound == null || bound != key.address.eip55With0x.toLowerCase()) {
        await PublicOS.secureStorage.delete(key: _linkClaimStorageKey);
        return null;
      }
      return LinkDeviceClaim(
        kind: m['kind'] == 'addSession'
            ? ConsentKind.addSession
            : ConsentKind.newAccount,
        input: m['input'] as String? ?? '',
        consentUri: m['uri'] as String,
        deadline: BigInt.from(m['deadline'] as int),
        newSession: key.address,
        ttlSeconds: (m['ttl'] as int?) ?? 0,
      );
    } catch (_) {
      await PublicOS.secureStorage.delete(key: _linkClaimStorageKey);
      return null;
    }
  }

  /// Remove a session (wallet address) from the current account
  /// Returns true on success, false on failure
  /// Note: Cannot remove the last session - at least one must remain
  static Future<bool> removeSession(EthereumAddress sessionToRemove) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication and blockchain key required to remove session');
      return false;
    }

    try {
      Log.d(_tag, 'Removing session ${sessionToRemove.eip55With0x}');

      // Get initial block number for confirmation
      int initialBlockNumber = await PublicOSBsp.getBlockNumber();

      await Future.any([
        PublicOSBsp.accountManagerContract.removeSession(
          (sessionToRemove: sessionToRemove),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 10)).then((_) => throw TimeoutException('Request timed out')),
      ]);

      // Wait for block confirmation
      final startTime = DateTime.now();
      final maxWaitTime = const Duration(seconds: 10);

      while (DateTime.now().difference(startTime) < maxWaitTime) {
        try {
          final currentBlockNumber = await PublicOSBsp.getBlockNumber();
          if (currentBlockNumber > initialBlockNumber) {
            Log.i(_tag, 'Session removed successfully - block confirmed');
            return true;
          }
        } catch (e) {
          Log.w(_tag, 'Could not check block: $e');
        }
        await Future.delayed(const Duration(seconds: 1));
      }

      Log.w(_tag, 'Session remove transaction sent but confirmation timed out');
      return true; // Transaction was sent, just couldn't confirm
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error removing session: $e');
      return false;
    }
  }

  /// Check if an address is a valid session for the current account
  static Future<bool> isValidSession(EthereumAddress session) async {
    try {
      final accountAddress = PublicOS.myPublicosAddress != null ? EthereumAddress.fromHex(PublicOS.myPublicosAddress!) : null;
      if (accountAddress == null) {
        return false;
      }

      final isValid = await Future.any([
        PublicOSBsp.accountManagerContract.isValidSessionForAccount(
          (accountAddress: accountAddress, sessionAddress: session),
        ),
        Future.delayed(const Duration(seconds: 5)).then((_) => throw TimeoutException('Request timed out')),
      ]);

      return isValid;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error checking session validity: $e');
      return false;
    }
  }

  /// Get the number of sessions for the current account
  static Future<int> getSessionCount() async {
    final sessions = await getMySessions();
    return sessions.length;
  }

  // ==========================================================================
  // VOUCHING (citizenship)
  //
  // Vouching is account lifecycle: it establishes whether an account
  // is a citizen (>= 25 vouches) which gates voting and other features.
  // ==========================================================================

  ///*********************************************
  /// VOUCHING (read-only queries)
  ///*********************************************

  /// Check if an account is a citizen.
  /// Citizenship is sticky once set — see Vouching #90 step-function threshold
  /// (`computeCurrentThreshold` scales 25 → 100 with `citizenCount`).
  static Future<bool> isCitizen(EthereumAddress account) async {
    try {
      return await PublicOSBsp.citizenshipManagerContract.isCitizen(
        (account: account),
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error checking citizen status: $e');
      rethrow;
    }
  }

  /// Get vouch count for an account
  static Future<BigInt> getVouchCount(EthereumAddress account) async {
    try {
      return await PublicOSBsp.vouchManagerContract.getVouchCount(
        (account: account),
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting vouch count: $e');
      rethrow;
    }
  }

  /// Get the list of addresses that vouched for an account.
  /// Reads from VouchMemory directly — VouchManager's wrapper returns empty.
  static Future<List<EthereumAddress>> getVouchersOf(EthereumAddress account) async {
    try {
      return await PublicOSBsp.vouchMemoryContract.getVouchersOf(
        (account: account),
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting vouchers: $e');
      rethrow;
    }
  }

  /// Get the list of addresses that an account has vouched for (reverse lookup).
  /// Reads from VouchMemory directly.
  static Future<List<EthereumAddress>> getVoucheesOf(EthereumAddress account) async {
    try {
      return await PublicOSBsp.vouchMemoryContract.getVoucheesOf(
        (account: account),
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting vouchees: $e');
      rethrow;
    }
  }

  /// Check if a specific account has vouched for a target
  static Future<bool> hasVouched(EthereumAddress voucher, EthereumAddress target) async {
    try {
      return await PublicOSBsp.vouchManagerContract.hasVouched(
        (voucher: voucher, target: target),
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error checking vouch: $e');
      rethrow;
    }
  }

  /// Get total citizen count
  static Future<BigInt> getCitizenCount() async {
    try {
      return await PublicOSBsp.citizenshipManagerContract.citizenCount();
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting citizen count: $e');
      rethrow;
    }
  }

  /// Live citizenship threshold from VouchMemory (step function: 25→40→60→80→95→100
  /// across `citizenCount` tiers <100/<100K/<10M/<100M/<1B/≥1B).
  static Future<BigInt> getCurrentVouchThreshold() async {
    try {
      return await PublicOSBsp.vouchManagerContract.computeCurrentThreshold();
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error reading current vouch threshold: $e');
      rethrow;
    }
  }

  /// Citizen's remaining vouching budget (live, includes pending regen).
  /// Cap=24, regen=1 unit per 30 days, use-it-or-lose-it (time at cap is lost).
  static Future<BigInt> getVouchBudget(EthereumAddress account) async {
    try {
      return await PublicOSBsp.vouchManagerContract.getBudget(
        (account: account),
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error reading vouch budget: $e');
      rethrow;
    }
  }

  /// Seconds until the next vouch budget unit accrues for this account.
  /// Returns 0 for non-citizens or accounts at cap (no pending regen).
  static Future<BigInt> getSecondsUntilNextVouchRegen(EthereumAddress account) async {
    try {
      return await PublicOSBsp.vouchManagerContract.secondsUntilNextRegen(
        (account: account),
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error reading secondsUntilNextRegen: $e');
      rethrow;
    }
  }

  /// True when citizenship granting is paused by the root DAO (the
  /// permanent-side brake on CitizenshipManager). While true, regular vouches
  /// AND genesis Midas grants revert; only `rootGrantCitizenship` (root/admin)
  /// and `removeAllVouches` remain available.
  static Future<bool> isGrantingPaused() async {
    try {
      return await PublicOSBsp.citizenshipManagerContract.grantingPaused();
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error reading grantingPaused: $e');
      rethrow;
    }
  }

  /// True when account creation is paused by the root DAO (emergency brake).
  /// `createAccount` and `createOrg` revert while true.
  static Future<bool> isAccountCreationPaused() async {
    try {
      return await PublicOSBsp.accountMemoryContract.accountCreationPaused();
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error reading accountCreationPaused: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // DISPLAY NAME POLICY
  //
  // Reads + writes for the display-name policy state in AccountMemory:
  // tier-length minimums, freed-name cooldown, annual rename window, bonus
  // counter (+1 per citizenship grant). Pair with [DisplayNameValidator] for
  // live UI validation. See contracts/libraries/DisplayNameValidator.sol +
  // contracts/AccountMemory.sol §"Account Creation Policy state (appended)".
  // ==========================================================================

  /// Snapshot the live (minRoot, minCitizen, minPublicOrg, minPrivate, maxChars)
  /// tier limits from DomainMemory (the name policy moved there under the
  /// domain-rights economy). Read once per surface (governance can tune these;
  /// we don't bake constants).
  static Future<NameTierLimits> getNameTierLimits() async {
    try {
      final results = await Future.wait([
        PublicOSBsp.domainMemoryContract.minCharsRoot(),
        PublicOSBsp.domainMemoryContract.minDomainChars(),
        PublicOSBsp.domainMemoryContract.minCharsPublicOrg(),
        PublicOSBsp.domainMemoryContract.minCharsNewAccount(),
        PublicOSBsp.domainMemoryContract.maxChars(),
      ]);
      return NameTierLimits(
        minRoot: results[0].toInt(),
        minCitizen: results[1].toInt(),
        minPublicOrg: results[2].toInt(),
        minPrivate: results[3].toInt(),
        maxChars: results[4].toInt(),
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error reading name tier limits: $e');
      rethrow;
    }
  }

  /// Returns the cooldown expiry (unix timestamp seconds) for the given
  /// display name, or 0 if unreserved/uncooled. A name is unclaimable while
  /// the returned value > `block.timestamp`.
  ///
  /// Used for the §5 pre-submit "this name is in cooldown / reserved" check
  /// before paying gas. Reservation = a 500-year cooldown, so a single read
  /// covers both cases (curated reservations + freed-name 180d cooldowns).
  ///
  /// Hashes [name] client-side via [DisplayNameValidator.computeHash] (ASCII
  /// A-Z → a-z fold, then keccak256) to match the on-chain
  /// `_getDisplayNameHash` exactly.
  static Future<BigInt> getNameCooldownUntil(String name) async {
    try {
      final hash = DisplayNameValidator.computeHash(name);
      return await PublicOSBsp.domainMemoryContract.nameCooldownUntil(
        (nameHash: hash),
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error reading name cooldown for "$name": $e');
      rethrow;
    }
  }

  /// Last block-timestamp the account consumed its annual user-initiated
  /// name change quota. 0 if never changed.
  static Future<BigInt> getLastDisplayNameChangeAt(
    EthereumAddress account,
  ) async {
    try {
      return await PublicOSBsp.domainMemoryContract.lastDisplayNameChangeAt(
        (account: account),
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error reading lastDisplayNameChangeAt: $e');
      rethrow;
    }
  }

  /// Bonus name-change counter for [account]. Increments by 1 on every
  /// citizenship grant (pushed VouchMemory → DomainManager.grantBonusNameChange)
  /// and on root grants. Consumed by a free `changeName` when the annual window
  /// has not elapsed. Lives in DomainMemory under the domain-rights economy.
  static Future<BigInt> getBonusNameChanges(EthereumAddress account) async {
    try {
      return await PublicOSBsp.domainMemoryContract.bonusNameChanges(
        (account: account),
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error reading bonusNameChanges: $e');
      rethrow;
    }
  }

  /// Annual window (seconds) between free user-initiated name changes
  /// (default 365 days). Used by the UI to compute when the next free change
  /// becomes available: `nextFreeAt = lastDisplayNameChangeAt + window`.
  static Future<BigInt> getNameChangeYearWindow() async {
    try {
      return await PublicOSBsp.domainMemoryContract.nameChangeYearWindow();
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error reading nameChangeYearWindow: $e');
      rethrow;
    }
  }

  /// Cooldown applied to a freed display name (default 180 days). Surfaced
  /// in change-confirmation dialogs ("alice99 will be unclaimable until X").
  static Future<BigInt> getNameCooldownPeriod() async {
    try {
      return await PublicOSBsp.domainMemoryContract.nameCooldownPeriod();
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error reading nameCooldownPeriod: $e');
      rethrow;
    }
  }

  /// Price a PROSPECTIVE new name for the current account (or [account]) — what
  /// `changeName` would actually charge. Mirrors the contract settle: free iff a
  /// citizen on a name `>= freeTierMinChars`, else `months` × the NEW name's
  /// length tier (multi-month discount applied). Unlike `priceFor`/`quoteDomain`
  /// (which price the account's CURRENT name), this prices the name you're ABOUT
  /// to take — use it for the cost preview before a rename. Returns (cost in wei,
  /// isFree). `account` defaults to [PublicOS.myPublicosAddress].
  static Future<({BigInt cost, bool isFree})> quoteName(
    String newName, {
    int months = 1,
    EthereumAddress? account,
  }) async {
    try {
      final acct =
          account ?? EthereumAddress.fromHex(PublicOS.myPublicosAddress!);
      final q = await PublicOSBsp.domainManagerContract.quoteForName(
        (account: acct, newName: newName, months: BigInt.from(months)),
      );
      return (cost: q.cost, isFree: q.isFree);
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error quoting name "$newName": $e');
      rethrow;
    }
  }

  /// The rename-quota state for the current account (or [account]) — the
  /// free-change ledger. A FREE rename (citizen → 5+) consumes the annual window
  /// or a bonus ticket and reverts if neither is available; PAID renames ignore
  /// it. Use to show "free now / next free in Nd / N tickets" and to block a free
  /// change that would otherwise revert. `account` defaults to
  /// [PublicOS.myPublicosAddress].
  static Future<({bool annualOpen, BigInt nextAnnualAt, BigInt bonusTickets})>
      getRenameQuota({EthereumAddress? account}) async {
    try {
      final acct =
          account ?? EthereumAddress.fromHex(PublicOS.myPublicosAddress!);
      final q = await PublicOSBsp.domainManagerContract.renameQuota(
        (account: acct),
      );
      return (
        annualOpen: q.annualOpen,
        nextAnnualAt: q.nextAnnualAt,
        bonusTickets: q.bonusTickets,
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error reading rename quota: $e');
      rethrow;
    }
  }

  /// Claimability of [newName] for the current account (or [account]), for the
  /// pre-submit preview. Returns the contract's status code:
  ///   0 available · 1 claimable by eviction (holder lapsed) · 2 held & not
  ///   evictable (blocked) · 3 unheld but in cooldown/reserved · 4 already held
  ///   by this account (no-op rename).
  /// Folds in the cooldown check, so it supersedes a standalone
  /// [getNameCooldownUntil] for the rename flow. `account` defaults to
  /// [PublicOS.myPublicosAddress].
  static Future<int> getNameClaimStatus(
    String newName, {
    EthereumAddress? account,
  }) async {
    try {
      final acct =
          account ?? EthereumAddress.fromHex(PublicOS.myPublicosAddress!);
      final s = await PublicOSBsp.domainManagerContract.nameClaimStatus(
        (account: acct, newName: newName),
      );
      return s.toInt();
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error reading name claim status for "$newName": $e');
      rethrow;
    }
  }

  /// Initiate a user-tier display name change. Wraps the contract's
  /// `setDisplayName(string)` (single-arg post-policy signature). The
  /// contract:
  ///   - validates [newName] against the caller's tier (citizen → minCitizen,
  ///     else minPrivate; both bounded by maxChars).
  ///   - rejects if [newName] is currently held OR in cooldown.
  ///   - consumes annual quota first, falls back to a bonus name change if
  ///     within the year window — caller can read `bonusNameChanges` +
  ///     `lastDisplayNameChangeAt` to predict which counter will be charged.
  ///   - auto-cools the OLD name for `nameCooldownPeriod` seconds (default
  ///     180 days) so it can't be rebound by anyone (including the original
  ///     holder) until the cooldown elapses.
  ///
  /// Returns true only after the receipt confirms success. On failure sets
  /// [PublicOS.lastError] with the decoded revert reason.
  ///
  /// On success the new name is written through to both local sources so it
  /// shows without a re-login: the `account_<addr>_displayName` secret (read
  /// by the select-account screen via [getStoredAccountNames]) and the local
  /// contact DB row (read via [PublicOSContacts.getContact]). Both are
  /// best-effort and never flip a confirmed result to false.
  ///
  /// **Always run [DisplayNameValidator.validate] client-side first** —
  /// charset / length errors revert on-chain otherwise and the user pays gas.
  ///
  /// Under the domain-rights economy the name-change front door is
  /// `DomainManager.changeName(newName, months)`: it claims an unheld name (or
  /// evicts a lapsed holder), charges `months × length-tier` (free for a
  /// free-tier 5+ citizen; paid renames bypass the rename quota), and writes the
  /// name slot via `AccountManager.applyNames`. `months` defaults to 1; a private
  /// renaming pays one period at the new name's tier.
  static Future<bool> setDisplayName(String newName, {int months = 1}) async {
    if (!PublicOS.isAuthenticated ||
        PublicOS.currentBlockchainPrivateKey == null) {
      PublicOS.lastError = 'setDisplayName: auth + private key required';
      Log.e(_tag, PublicOS.lastError!);
      return false;
    }
    if (newName.isEmpty) {
      PublicOS.lastError = 'setDisplayName: newName cannot be empty';
      return false;
    }

    try {
      Log.i(_tag, 'setDisplayName → "$newName"');
      final txHash = await Future.any([
        PublicOSBsp.domainManagerContract.changeName(
          (newName: newName, months: BigInt.from(months)),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15))
            .then((_) => throw TimeoutException('setDisplayName send timed out')),
      ]);
      final ok = await TxUtils.waitForReceipt(
        txHash,
        label: 'setDisplayName($newName)',
      );
      if (!ok) {
        PublicOS.lastError ??=
            'setDisplayName: transaction reverted or timed out';
        return false;
      }

      // Write-through both local name sources so the new name shows up
      // without a re-login. Both are best-effort: the chain write already
      // succeeded, so a local-refresh failure must not flip the result.
      //   1. The stored `account_<addr>_displayName` secret — what the
      //      select-account screen renders (via getStoredAccountNames). The
      //      key is in eip55 form, matching myPublicosAddress (set at load),
      //      so this overwrites the existing entry rather than adding one.
      //   2. The local contact DB row — what Account Center / profile read
      //      via PublicOSContacts.getContact. Mirrors the setRecord
      //      write-through (fetchContact → saveContact).
      final addr = PublicOS.myPublicosAddress;
      if (addr != null) {
        try {
          await PublicOS.secureStorage.write(
            key: 'account_${addr}_displayName',
            value: newName,
          );
        } catch (e) {
          Log.w(_tag, 'setDisplayName: stored-name refresh failed: $e');
        }
        try {
          // Persists → requireRecords. (Self-gated anyway, but be explicit:
          // the guarantee should not depend on addr happening to be self.)
          final fresh = await PublicOSContacts.fetchContact(
            EthereumAddress.fromHex(addr),
            requireRecords: true,
          );
          await PublicOSContacts.saveContact(fresh);
        } catch (e) {
          Log.w(_tag, 'setDisplayName: contact DB refresh failed: $e');
        }
      }

      return true;
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, 'setDisplayName error: $e');
      return false;
    }
  }

  // ==========================================================================
  // ORG CREATION RATE LIMIT
  //
  // `AccountManager.createOrg` blocks a creator until
  // `lastOrgCreationAt + cooldown`, where the cooldown is tier-split
  // (citizen vs non-citizen — derived from the CitizenshipManager at write
  // time). Surfaced in the create-org UI so the wait is visible *before*
  // the user fills the form / pays gas, instead of only as a post-submit
  // revert. See contracts/AccountManager.sol §createOrg + AccountMemory.sol.
  // ==========================================================================

  /// Snapshot the org-creation rate-limit state for [account]. Reads
  /// `lastOrgCreationAt`, both cooldown constants, `isCitizen`, and the latest
  /// block timestamp in parallel — five cheap view calls, no tx. The returned
  /// [OrgCreationCooldown] knows which tier applies and whether the account is
  /// currently within the cooldown window.
  static Future<OrgCreationCooldown> getOrgCreationCooldown(
    EthereumAddress account,
  ) async {
    try {
      // Kick all five reads off before the first await so they run in parallel.
      final lastAtF =
          PublicOSBsp.accountMemoryContract.lastOrgCreationAt((arg0: account));
      final citizenCdF =
          PublicOSBsp.accountMemoryContract.citizenOrgCreationCooldown();
      final nonCitizenCdF =
          PublicOSBsp.accountMemoryContract.nonCitizenOrgCreationCooldown();
      final citizenF = isCitizen(account);
      final blockF = PublicOS.web3Client.getBlockInformation();

      final lastAt = await lastAtF;
      final citizenCd = await citizenCdF;
      final nonCitizenCd = await nonCitizenCdF;
      final citizen = await citizenF;
      final block = await blockF;

      final cooldown =
          Duration(seconds: (citizen ? citizenCd : nonCitizenCd).toInt());
      // lastOrgCreationAt returns 0 when the account has never created an org.
      final lastCreationAt = lastAt == BigInt.zero
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastAt.toInt() * 1000);
      final nextAllowedAt = lastCreationAt?.add(cooldown);

      return OrgCreationCooldown(
        lastCreationAt: lastCreationAt,
        cooldown: cooldown,
        isCitizen: citizen,
        nextAllowedAt: nextAllowedAt,
        chainNow: block.timestamp,
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error reading org creation cooldown: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // ACCOUNT CREATION TIMESTAMP
  //
  // Lazy enrichment: derive an account's "joined date" from its on-chain
  // creation event. We don't store this on the account because the value is
  // both immutable per account and trivially recoverable from event logs —
  // an indexed-topic getLogs + one block fetch is cheaper than the SSTORE
  // it would replace, and it's only ever read from one surface (the contact
  // page). Persist the result on `Contact.createdAt` so future visits skip
  // the lookup.
  //
  // This MUST stay tail-of-flow: only fire on the contact the user is
  // actively viewing, never in list flows (one lookup per row is an n+1
  // trap).
  // ==========================================================================

  /// Look up the timestamp at which [account] was created on chain by
  /// querying the `AccountCreated` (or `OrgCreated` if [isOrg]) event filtered
  /// on its indexed account address. Returns null when no event is found or
  /// the RPC call fails — callers should treat that as "unknown, try again
  /// next visit" and not surface an error.
  ///
  /// Cost: 1 `eth_getLogs` (indexed topic, fast) + 1 `eth_getBlockByNumber`.
  /// Both are cheap reads. The value is immutable per account, so cache it on
  /// the [Contact] (`createdAt`) and skip the lookup on future visits.
  /// Genesis account (jmsl). Its `AccountCreated` event is emitted by the
  /// GenesisManager contract, not AccountManager, so the log scan below can't
  /// see it and would return null. Easter egg: hard-code April 4th, 1989.
  static final EthereumAddress _genesisAccount = EthereumAddress.fromHex(
    '0xcdac50Be80cAB95Ab6C989CF80f69D1C5F04d039',
  );

  static Future<DateTime?> getAccountCreatedAt(
    EthereumAddress account, {
    bool isOrg = false,
  }) async {
    if (account == _genesisAccount) {
      return DateTime(1989, 4, 4);
    }
    try {
      final contract = PublicOSBsp.accountManagerContract.self;
      final event = contract.event(isOrg ? 'OrgCreated' : 'AccountCreated');

      final paddedAddr =
          '0x${account.eip55With0x.substring(2).padLeft(64, '0')}';

      final currentBlock = await PublicOS.web3Client.getBlockNumber();
      final filter = FilterOptions(
        address: contract.address,
        fromBlock: const BlockNum.exact(0),
        toBlock: BlockNum.exact(currentBlock),
        topics: [
          [bytesToHex(event.signature, include0x: true)],
          [paddedAddr],
        ],
      );

      final logs = await PublicOS.web3Client.getLogs(filter);
      if (logs.isEmpty || logs.first.blockNum == null) {
        Log.d(_tag, 'getAccountCreatedAt: no event for ${account.eip55With0x}');
        return null;
      }

      final block = await PublicOS.web3Client.getBlockInformation(
        blockNumber: '0x${logs.first.blockNum!.toRadixString(16)}',
      );
      return block.timestamp;
    } catch (e) {
      Log.w(_tag, 'getAccountCreatedAt failed for ${account.eip55With0x}: $e');
      return null;
    }
  }

  /// Vouch for a target account. Caller must be a citizen.
  /// Returns the transaction hash on success.
  /// The vouch count an account needs today to be eligible for citizenship
  /// (VouchManager.computeCurrentThreshold — a step function of citizenCount).
  static Future<BigInt> getVouchThreshold() =>
      PublicOSBsp.vouchManagerContract.computeCurrentThreshold();

  /// Vouches received against today's threshold, for the account's own
  /// citizenship pill and the claim offer. `eligible` is what
  /// `VouchManager.onClaim` will answer: count >= the CURRENT threshold.
  static Future<({BigInt count, BigInt threshold, bool eligible})>
      getCitizenshipEligibility(EthereumAddress account) async {
    final reads = await Future.wait([
      getVouchCount(account),
      getVouchThreshold(),
    ]);
    final count = reads[0];
    final threshold = reads[1];
    return (count: count, threshold: threshold, eligible: count >= threshold);
  }

  /// The tenure of [session]: account, since, until (null =
  /// permanent). Null when the address was never a session key, or the read
  /// failed.
  static Future<SessionTenureInfo?> getSessionTenure(
      EthereumAddress session) async {
    try {
      final raw = await PublicOSBsp.accountMemoryContract
          .getSessionTenure((session: session));
      // Struct SessionTenure { address account; uint48 since; uint48 until }
      final f = raw as List<dynamic>;
      final account = f[0] as EthereumAddress;
      if (account.eip55With0x == '0x0000000000000000000000000000000000000000') {
        return null;
      }
      final since = (f[1] as BigInt).toInt();
      final until = (f[2] as BigInt).toInt();
      return SessionTenureInfo(
        account: account,
        since: DateTime.fromMillisecondsSinceEpoch(since * 1000),
        until: until == 0 ? null : DateTime.fromMillisecondsSinceEpoch(until * 1000),
      );
    } catch (e) {
      Log.w(_tag, 'getSessionTenure(${session.eip55With0x}) failed: $e');
      return null;
    }
  }

  /// The tenure of the session key THIS DEVICE holds for [account] (the
  /// `account_<addr>_sessionAddress` secret). Null when there is none or the
  /// read failed. Used by the select-account screens to show a countdown.
  static Future<SessionTenureInfo?> getStoredSessionTenure(
      EthereumAddress account) async {
    final hex = await PublicOS.secureStorage
        .read(key: 'account_${account.eip55With0x}_sessionAddress');
    if (hex == null || hex.isEmpty) return null;
    return getSessionTenure(EthereumAddress.fromHex(hex));
  }

  /// Whether the ACTIVE session key is permanent (`SessionTenure.until == 0`).
  /// The citizenship claim and the renounce are irreversible, so the contract
  /// takes them from a permanent key only; the app checks first so
  /// it can say so instead of showing a revert. `null` when it cannot tell.
  static Future<bool?> isActiveSessionPermanent() async {
    final key = PublicOS.currentBlockchainPrivateKey;
    if (key == null) return null;
    try {
      final raw = await PublicOSBsp.accountMemoryContract
          .getSessionTenure((session: key.address));
      // Struct SessionTenure { address account; uint48 since; uint48 until }
      final fields = raw as List<dynamic>;
      final until = fields[2] as BigInt;
      return until == BigInt.zero;
    } catch (e) {
      Log.w(_tag, 'isActiveSessionPermanent read failed: $e');
      return null;
    }
  }

  /// Citizenship is OPT-IN: vouches make the account
  /// eligible, the account CLAIMS and, in the same call, accepts the current
  /// CITIZEN agreement. The active session must be a PERMANENT key of an
  /// individual account. Reads the agreement version first.
  /// After a claim or a renounce our own citizen flag is stale: contacts keep
  /// it with no expiry (`_resolveMembership`, "citizenship is durable"). Re-read
  /// our own contact with the membership forced; `fetchContact` saves it and
  /// emits `selfContactUpdates`, so every self icon (explorer app bar, wallet,
  /// browser header) repaints with or without the ghost badge at once. Without
  /// this, the self icons keep the old citizen look until the app restarts.
  static Future<void> _refreshSelfMembership() async {
    final me = PublicOS.myPublicosAddress;
    if (me == null) return;
    try {
      await PublicOSContacts.fetchContact(EthereumAddress.fromHex(me),
          forceMembership: true);
    } catch (e) {
      Log.w(_tag, 'self membership refresh failed: $e');
    }
  }

  static Future<bool> claimCitizenship() async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication required');
      return false;
    }
    try {
      final version = await PublicOSBsp.agreementManagerContract
          .currentVersion((kind: BigInt.from(3))); // KIND_CITIZEN
      final txHash = await PublicOSBsp.citizenshipManagerContract
          .agreeTermsAndClaimCitizenship(
        (version: version),
        credentials: PublicOS.currentBlockchainPrivateKey!,
      );
      final ok = await TxUtils.waitForReceipt(txHash, label: 'claimCitizenship(v$version)');
      if (ok) await _refreshSelfMembership();
      return ok;
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, 'claimCitizenship failed: $e');
      return false;
    }
  }

  /// Give up citizenship: `CitizenshipManager.renounceCitizenship`
  /// (it asks `VouchManager.onRenounce`, the way a claim asks `onClaim`).
  /// Immediate and final: the vouches received are cleared, the domain lapses
  /// at once (a 5+ name becomes payable), the root-org seat and vote go, and a
  /// later return needs fresh vouches and starts with an empty vouch budget.
  /// Unclaimed payouts and unsettled subscriptions are NOT settled: the app
  /// tells the user to claim and settle first. Permanent key only; the genesis
  /// account is refused.
  static Future<bool> renounceCitizenship() async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication required');
      return false;
    }
    try {
      final txHash = await PublicOSBsp.citizenshipManagerContract.renounceCitizenship(
        credentials: PublicOS.currentBlockchainPrivateKey!,
      );
      final ok = await TxUtils.waitForReceipt(txHash, label: 'renounceCitizenship');
      if (ok) await _refreshSelfMembership();
      return ok;
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, 'renounceCitizenship failed: $e');
      return false;
    }
  }

  static Future<String?> vouch(EthereumAddress target) async {
    try {
      if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
        Log.w(_tag, 'Not authenticated or no credentials');
        return null;
      }

      Log.d(_tag, 'Vouching for $target...');
      final txHash = await PublicOSBsp.vouchManagerContract.vouch(
        (target: target),
        credentials: PublicOS.currentBlockchainPrivateKey!,
      );
      Log.i(_tag, 'Vouched for $target, tx: $txHash — waiting for receipt...');
      // Wait for the receipt so callers that re-read vouch count / vouchers
      // after this returns see the committed state (not a block before the
      // vouch landed). Returns null on revert/timeout so callers can treat a
      // non-null txHash as "confirmed".
      final confirmed = await TxUtils.waitForReceipt(
        txHash,
        label: 'vouch(${target.eip55With0x})',
      );
      if (!confirmed) {
        PublicOS.lastError ??= 'vouch: transaction reverted or timed out';
        Log.w(_tag, 'Vouch for $target not confirmed');
        return null;
      }
      Log.i(_tag, 'Vouch for $target confirmed, tx: $txHash');
      return txHash;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error vouching: $e');
      rethrow;
    }
  }

  // =========================================================================
  // Subdomains (account_subdomains)
  //
  // Account-tree primitive. Subdomains are pure DATA — they have no sessions of
  // their own; the top-level account's sessions drive the whole tree. So the
  // writers below need only the current account's key (the caller must be a
  // session of the parent's top-level); there is no per-subdomain consent sig
  // like the session lanes above. Slug rules (length, the reserved '.'
  // composition operator) are enforced in the contract — revert reasons
  // surface via PublicOS.lastError.
  //
  // No local-DB write-through after a create: a subdomain is just-another
  // account, so fetchContact stays the single source of truth and getContact
  // doesn't need a subdomain special-case. The first read resolves it.
  // =========================================================================

  /// Create subdomain `slug` under `parentAccount`. Paid tier burns a fee from
  /// the top-level's MainSafe; free tier up to the per-account cap. Returns
  /// true once the tx confirms.
  static Future<bool> createSubdomain({
    required EthereumAddress parentAccount,
    required String slug,
  }) async {
    if (!PublicOS.isAuthenticated ||
        PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'createSubdomain: auth + private key required');
      return false;
    }

    try {
      Log.d(_tag, 'createSubdomain "$slug" under ${parentAccount.eip55With0x}');
      final txHash = await Future.any([
        PublicOSBsp.accountManagerContract.createSubdomain(
          (parentAcc: parentAccount, slug: slug),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15)).then(
            (_) => throw TimeoutException('createSubdomain send timed out')),
      ]);
      Log.i(_tag, 'createSubdomain tx sent: $txHash — waiting for receipt...');
      final confirmed = await TxUtils.waitForReceipt(
        txHash,
        label: 'createSubdomain($slug)',
      );
      if (!confirmed) {
        PublicOS.lastError ??=
            'createSubdomain: transaction reverted or timed out';
      }
      return confirmed;
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, 'createSubdomain error: $e');
      return false;
    }
  }

  /// Rename `subAccount` to `newSlug`. Returns true once the tx confirms.
  static Future<bool> renameSubdomain({
    required EthereumAddress subAccount,
    required String newSlug,
  }) async {
    if (!PublicOS.isAuthenticated ||
        PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'renameSubdomain: auth + private key required');
      return false;
    }

    try {
      Log.d(_tag, 'renameSubdomain ${subAccount.eip55With0x} -> "$newSlug"');
      final txHash = await Future.any([
        PublicOSBsp.accountManagerContract.renameSubdomain(
          (subAccount: subAccount, newSlug: newSlug),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15)).then(
            (_) => throw TimeoutException('renameSubdomain send timed out')),
      ]);
      Log.i(_tag, 'renameSubdomain tx sent: $txHash — waiting for receipt...');
      final confirmed = await TxUtils.waitForReceipt(
        txHash,
        label: 'renameSubdomain(${subAccount.eip55With0x})',
      );
      if (!confirmed) {
        PublicOS.lastError ??=
            'renameSubdomain: transaction reverted or timed out';
      }
      return confirmed;
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, 'renameSubdomain error: $e');
      return false;
    }
  }

  /// Delete `subAccount`. Returns true once the tx confirms.
  static Future<bool> deleteSubdomain({
    required EthereumAddress subAccount,
  }) async {
    if (!PublicOS.isAuthenticated ||
        PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'deleteSubdomain: auth + private key required');
      return false;
    }

    try {
      Log.d(_tag, 'deleteSubdomain ${subAccount.eip55With0x}');
      final txHash = await Future.any([
        PublicOSBsp.accountManagerContract.deleteSubdomain(
          (subAccount: subAccount),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15)).then(
            (_) => throw TimeoutException('deleteSubdomain send timed out')),
      ]);
      Log.i(_tag, 'deleteSubdomain tx sent: $txHash — waiting for receipt...');
      final confirmed = await TxUtils.waitForReceipt(
        txHash,
        label: 'deleteSubdomain(${subAccount.eip55With0x})',
      );
      if (!confirmed) {
        PublicOS.lastError ??=
            'deleteSubdomain: transaction reverted or timed out';
      }
      return confirmed;
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, 'deleteSubdomain error: $e');
      return false;
    }
  }

  /// All subdomain account addresses under `parent`. Hides the contract's
  /// paged enumeration — walks pages of [pageSize] until the tail is reached.
  /// Default page size matches the citizen cap, so the common case is one
  /// round-trip. View, no auth.
  static Future<List<EthereumAddress>> getSubdomainsByParent(
    EthereumAddress parent, {
    int pageSize = 100,
  }) async {
    try {
      final out = <EthereumAddress>[];
      var offset = 0;
      while (true) {
        final page = await Future.any([
          PublicOSBsp.accountMemoryContract.getSubdomainsByParent(
            (
              parent: parent,
              offset: BigInt.from(offset),
              limit: BigInt.from(pageSize),
            ),
          ),
          Future.delayed(const Duration(seconds: 5)).then(
              (_) => throw TimeoutException('getSubdomainsByParent timed out')),
        ]);
        out.addAll(page);
        if (page.length < pageSize) break;
        offset += pageSize;
      }
      return out;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'getSubdomainsByParent error: $e');
      return const [];
    }
  }

  // =========================================================================
  // DAO break-glass — fullResetByDAO
  // =========================================================================

  /// DAO-authorized force-reset of a target account's sessions. Caller must
  /// be a DAO reset executor (`isDAOResetExecutor[msg.sender]` on
  /// AccountMemory). Consent sig is from the new sole session's key —
  /// post-sig the DAO cannot rescue an account into its own pocket.
  static Future<bool> fullResetByDAO({
    required EthereumAddress target,
    required EthereumAddress newSoleSession,
    required BigInt deadline,
    required Uint8List sig,
  }) async {
    if (!PublicOS.isAuthenticated ||
        PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'fullResetByDAO: auth + private key required');
      return false;
    }
    try {
      Log.i(
        _tag,
        'fullResetByDAO target=${target.eip55With0x} newSole=${newSoleSession.eip55With0x}',
      );
      final txHash = await Future.any([
        PublicOSBsp.accountManagerContract.fullResetByDAO(
          (
            targetAccountAddress: target,
            newSoleSession: newSoleSession,
            deadline: deadline,
            sig: sig,
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 20))
            .then((_) => throw TimeoutException('fullResetByDAO send timed out')),
      ]);
      final confirmed = await TxUtils.waitForReceipt(
        txHash,
        label: 'fullResetByDAO(${target.eip55With0x})',
      );
      if (!confirmed) {
        PublicOS.lastError ??=
            'fullResetByDAO: transaction reverted or timed out';
      }
      return confirmed;
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, 'fullResetByDAO error: $e');
      return false;
    }
  }

  /// Build + sign the shared `SessionConsent` for the DAO full-reset path.
  /// Same struct as add/reseed — the path's wider
  /// side effects (wipes contacts + resets threshold) are enforced in the
  /// contract + its distinct event, not by a separate typehash.
  static ({BigInt deadline, Uint8List sig}) signFullResetConsent({
    required EthereumAddress account,
    required EthereumAddress newSoleSession,
    required EthPrivateKey newSoleSessionKey,
    Duration validFor = const Duration(hours: 1),
  }) {
    final deadline = _deadlineSecs(validFor);
    final structHash = eip712.sessionConsentStructHash(
      account: account,
      newSession: newSoleSession,
      ttl: BigInt.zero, // break-glass installs a permanent key (AccountManager.fullResetByDAO signs ttl 0)
      deadline: deadline,
    );
    final digest = _consentDigest(structHash);
    return (
      deadline: deadline,
      sig: eip712.signDigest(digest, newSoleSessionKey),
    );
  }
}

// =========================================================================
// Private shared helpers for EIP-712 consent digests.
// =========================================================================

BigInt _deadlineSecs(Duration validFor) =>
    BigInt.from(DateTime.now().add(validFor).add(PublicOS.chainClockSkew).millisecondsSinceEpoch ~/ 1000);

Uint8List _consentDigest(Uint8List structHash) {
  final domainSep = eip712.domainSeparator(
    chainId: PublicOS.CHAIN_ID,
    verifyingContract: PublicOSBsp.accountManagerAddress,
  );
  return eip712.finalDigest(domainSep: domainSep, structHash: structHash);
}

/// A signed, QR-ready link-device consent produced by the new device for a
/// sponsor to scan. [consentUri] is the `publicos-claim:<base64>` message
/// (the signed bytes); the UI wraps it in a `publicos://` deep link for the
/// QR. Produced + restored by [PublicOSAccounts.signTemporaryLinkClaim] /
/// [PublicOSAccounts.loadTemporaryLinkClaim].
class LinkDeviceClaim {
  final ConsentKind kind;

  /// displayName (newAccount) or account address hex (addSession).
  final String input;

  /// The `publicos-claim:<base64-cbor>` consent URI.
  final String consentUri;

  /// Unix-seconds deadline after which the claim is expired.
  final BigInt deadline;

  /// The temp session address bound into the consent (== firstSession on chain).
  final EthereumAddress newSession;

  /// addSession only: the key's lifetime in seconds, signed into the consent
  /// (0 = permanent). A new account's first key is always permanent.
  final int ttlSeconds;

  const LinkDeviceClaim({
    required this.kind,
    required this.input,
    required this.consentUri,
    required this.deadline,
    required this.newSession,
    this.ttlSeconds = 0,
  });
}

/// A session key's tenure on chain (`AccountMemory.getSessionTenure`):
/// the account it belongs to, when it was added, and when it
/// ends. [until] null = a permanent key. Spans are never deleted, so an
/// expired key still reads here (with [isExpired] true).
class SessionTenureInfo {
  final EthereumAddress account;
  final DateTime since;
  final DateTime? until;

  const SessionTenureInfo({
    required this.account,
    required this.since,
    required this.until,
  });

  bool get isPermanent => until == null;
  bool get isExpired => until != null && DateTime.now().isAfter(until!);

  /// Time left on an expiring key (zero once expired); null when permanent.
  Duration? get remaining {
    final u = until;
    if (u == null) return null;
    final d = u.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }
}

/// Snapshot of an account's org-creation rate-limit state, as read by
/// [PublicOSAccounts.getOrgCreationCooldown]. All timestamps are absolute
/// instants — [chainNow] is the chain's latest-block time so the countdown
/// matches what `createOrg`'s `block.timestamp` check will see, not device
/// clock drift.
class OrgCreationCooldown {
  /// When this account last created an org, or null if it never has
  /// (in which case there is no cooldown — [isLimited] is false).
  final DateTime? lastCreationAt;

  /// The cooldown that applies to this account's tier (citizen vs non-citizen).
  final Duration cooldown;

  /// Whether the account is a citizen — determines which [cooldown] applies.
  final bool isCitizen;

  /// The earliest time the account may create another org, or null if it has
  /// never created one (can create now).
  final DateTime? nextAllowedAt;

  /// The chain's latest-block timestamp at read time. Compare against this,
  /// not `DateTime.now()`.
  final DateTime chainNow;

  const OrgCreationCooldown({
    required this.lastCreationAt,
    required this.cooldown,
    required this.isCitizen,
    required this.nextAllowedAt,
    required this.chainNow,
  });

  /// True while the account is still inside the cooldown window — `createOrg`
  /// will revert with "Org creation rate-limited".
  bool get isLimited =>
      nextAllowedAt != null && nextAllowedAt!.isAfter(chainNow);

  /// Time left until the account may create another org. `Duration.zero` when
  /// not currently limited.
  Duration get remaining =>
      isLimited ? nextAllowedAt!.difference(chainNow) : Duration.zero;
}
