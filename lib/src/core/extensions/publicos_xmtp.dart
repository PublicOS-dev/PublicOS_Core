// ignore_for_file: unused_import
import 'dart:async'; // Import for TimeoutException
import 'dart:convert';
import 'dart:typed_data';
import 'package:drift/drift.dart';
import 'package:publicos_core/src/core/publicos_core.dart';
import 'package:publicos_core/src/core/extensions/publicos_bsp.dart';
import 'package:publicos_core/src/core/extensions/publicos_conversations.dart';
import 'package:publicos_core/src/contracts/XmtpManager.g.dart' as XmtpManagerContract;
import 'package:publicos_core/src/database/database.dart' as db;
import 'package:publicos_core/src/utils/string_utils.dart'; // Added for bytes32ToString
import 'package:publicos_core/src/utils/log.dart';
import 'package:publicos_core/src/utils/tx_utils.dart';
import 'package:publicos_core/src/models/contact.dart';
import 'package:web3dart/web3dart.dart';
import 'package:wallet/wallet.dart';
import 'package:xmtp_plugin/xmtp_plugin.dart' show BackupElement, ArchiveMetadata, XmtpPlugin;

/// Extension on PublicOS to manage XMTP Inbox IDs.
extension PublicOSXmtp on PublicOS {
  static const _tag = 'Xmtp';

  // ============================================================================
  // CONSENT + INSTALLATION SYNC (identity-level, not per conversation)
  //
  // Note: `syncAll()` and `syncConversation(topic)` live in
  // `publicos_conversations.dart` since they operate on conversations.
  // ============================================================================

  /// Sync consent preferences across devices.
  /// Call this to sync block/allow lists with other installations.
  static Future<bool> syncConsentPreferences() async {
    Log.d(_tag, '[SYNC] syncConsentPreferences() called');
    try {
      final result = await PublicOS.xmtpClient!.syncConsentPreferences();
      Log.i(_tag, '[SYNC] syncConsentPreferences() complete - result: $result');
      return result;
    } catch (e) {
      Log.e(_tag, '[SYNC] syncConsentPreferences() failed: $e');
      return false;
    }
  }

  /// Request message history sync from other installations.
  /// Call this on a new device after client creation to trigger
  /// existing installations to upload their message history.
  static Future<bool> sendSyncRequest() async {
    Log.d(_tag, '[SYNC] sendSyncRequest() called');
    try {
      final result = await PublicOS.xmtpClient!.sendSyncRequest();
      Log.i(_tag, '[SYNC] sendSyncRequest() complete - result: $result');
      return result;
    } catch (e) {
      Log.e(_tag, '[SYNC] sendSyncRequest() failed: $e');
      return false;
    }
  }

  // ============================================================================
  // ACCOUNT ADDRESS RESOLUTION - With cache checking
  // ============================================================================

  /// Check if we need to resolve account address (1 hour cycle)
  /// Uses 'inbox_account_resolve_after' record key
  static bool shouldResolveAccountAddress(Contact contact) {
    final resolveAfterStr = contact.getRecordValue('inbox_account_resolve_after');
    final contactId = contact.registeredInboxIDs?.firstOrNull?.inboxId ?? contact.displayName;

    if (resolveAfterStr == null) {
      Log.d(_tag, '[ACCOUNT_CACHE] $contactId - No inbox_account_resolve_after record, should resolve: true');
      return true;
    }

    try {
      final resolveAfter = DateTime.parse(resolveAfterStr);
      final now = DateTime.now();
      final shouldResolve = now.isAfter(resolveAfter);
      Log.d(_tag, '[ACCOUNT_CACHE] $contactId - inbox_account_resolve_after: $resolveAfterStr, now: ${now.toIso8601String()}, should resolve: $shouldResolve');
      return shouldResolve;
    } catch (e) {
      Log.e(_tag, '[ACCOUNT_CACHE] $contactId - Failed to parse inbox_account_resolve_after "$resolveAfterStr": $e, should resolve: true');
      return true;
    }
  }
  /// Registers a new inbox ID with a given label.
  static Future<bool> registerInboxId(Uint8List inboxId, String label) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication and private key required to register inbox ID.');
      return false; // Return false instead of throwing
    }
    try {
      Log.d(_tag, 'Registering Inbox ID: ${bytes32ToString(inboxId)}, Label: $label');
      final txHash = await Future.any([
        PublicOSBsp.xmtpManagerContract.registerInboxId(
          (inboxId: inboxId, label: label),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15)).then((_) => throw TimeoutException('Registering inbox ID send timed out')),
      ]);
      Log.i(_tag, 'registerInboxId tx sent: $txHash — waiting for receipt...');
      final confirmed = await TxUtils.waitForReceipt(
        txHash,
        label: 'registerInboxId(${bytes32ToString(inboxId)})',
      );
      if (!confirmed) return false;
      Log.i(_tag, 'Inbox ID registered successfully.');
      return true;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error registering inbox ID: $e');
      return false; // Return false on error
    }
  }

  /// Removes an inbox ID.
  static Future<bool> removeInboxId(Uint8List inboxId) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication and private key required to remove inbox ID.');
      return false; // Return false instead of throwing
    }
    try {
      Log.d(_tag, 'Removing Inbox ID: ${bytes32ToString(inboxId)}');
      final txHash = await Future.any([
        PublicOSBsp.xmtpManagerContract.removeInboxId(
          (inboxId: inboxId),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15)).then((_) => throw TimeoutException('Removing inbox ID send timed out')),
      ]);
      Log.i(_tag, 'removeInboxId tx sent: $txHash — waiting for receipt...');
      final confirmed = await TxUtils.waitForReceipt(
        txHash,
        label: 'removeInboxId(${bytes32ToString(inboxId)})',
      );
      if (!confirmed) return false;
      Log.i(_tag, 'Inbox ID removed successfully.');
      return true;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error removing inbox ID: $e');
      return false; // Return false on error
    }
  }

  /// Updates the label for an existing inbox ID.
  static Future<bool> updateInboxIdLabel(Uint8List inboxId, String newLabel) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication and private key required to update inbox ID label.');
      return false; // Return false instead of throwing
    }
    try {
      Log.d(_tag, 'Updating Inbox ID Label for: ${bytes32ToString(inboxId)} to $newLabel');
      final txHash = await Future.any([
        PublicOSBsp.xmtpManagerContract.updateInboxIdLabel(
          (inboxId: inboxId, newLabel: newLabel),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15)).then((_) => throw TimeoutException('Updating inbox ID label send timed out')),
      ]);
      Log.i(_tag, 'updateInboxIdLabel tx sent: $txHash — waiting for receipt...');
      final confirmed = await TxUtils.waitForReceipt(
        txHash,
        label: 'updateInboxIdLabel(${bytes32ToString(inboxId)})',
      );
      if (!confirmed) return false;
      Log.i(_tag, 'Inbox ID label updated successfully.');
      return true;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error updating inbox ID label: $e');
      return false; // Return false on error
    }
  }

  /// Retrieves the account address associated with a given inbox ID.
  ///
  /// [inboxId] - The inbox ID bytes to look up
  /// [existingContact] - Optional contact to check cache. If provided and cache is valid,
  ///                     returns cached publicosAddress without blockchain call.
  /// [forceRefresh] - If true, ignores cache and always fetches from blockchain
  ///
  /// Returns the account address, or null if not found or on error.
  /// The caller is responsible for updating the contact's 'inbox_account_resolve_after' record.
  static Future<EthereumAddress?> getAccountAddressByInboxId(
    Uint8List inboxId, {
    Contact? existingContact,
    bool forceRefresh = false,
  }) async {
    final inboxIdStr = bytes32ToString(inboxId);

    // Check cache if contact provided and not forcing refresh
    if (!forceRefresh && existingContact != null) {
      if (!shouldResolveAccountAddress(existingContact)) {
        Log.d(_tag, '[ACCOUNT_CACHE] Using cached publicosAddress for $inboxIdStr: ${existingContact.publicosAddress?.eip55With0x ?? 'null'}');
        return existingContact.publicosAddress;
      }
    }

    // Fetch from blockchain
    try {
      Log.d(_tag, '[BLOCKCHAIN] Getting account address for InboxID: $inboxIdStr');
      final address = await Future.any([
        PublicOSBsp.xmtpManagerContract.getAccountAddressByInboxId(
          (inboxId: inboxId),
        ),
        Future.delayed(const Duration(seconds: 5)).then((_) => throw TimeoutException('Get account address by inbox ID timed out')),
      ]);
      if (address == EthereumAddress.fromHex("0x0000000000000000000000000000000000000000")) {
        Log.d(_tag, '[BLOCKCHAIN] No account address found for InboxID: $inboxIdStr (zero address)');
        return null; // Return null if not found (zero address)
      }
      Log.d(_tag, '[BLOCKCHAIN] Retrieved account address ${address.eip55With0x} for InboxID: $inboxIdStr');
      return address;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, '[BLOCKCHAIN] Error retrieving account address by inbox ID: $e');
      return null; // Return null on error
    }
  }

  /// Retrieves the inbox ID associated with a given account address and label.
  static Future<Uint8List?> getAccountInboxIdByLabel(EthereumAddress accountAddress, String label) async {
    try {
      Log.d(_tag, 'Getting InboxID for Account: ${accountAddress.eip55With0x}, Label: $label');
      final inboxId = await Future.any([
        PublicOSBsp.xmtpManagerContract.getAccountInboxIdByLabel(
          (accountAddress: accountAddress, label: label),
        ),
        Future.delayed(const Duration(seconds: 5)).then((_) => throw TimeoutException('Get account inbox ID by label timed out')),
      ]);
      // Assuming an empty Uint8List might indicate "not found"
      if (inboxId.isEmpty || inboxId.every((byte) => byte == 0)) {
        Log.d(_tag, 'No InboxID found for Account: ${accountAddress.eip55With0x}, Label: $label (empty or zero bytes)');
        return null;
      }
      Log.d(_tag, 'Retrieved InboxID: ${bytes32ToString(inboxId)} for Account: ${accountAddress.eip55With0x}, Label: $label');
      return inboxId;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error retrieving inbox ID by label: $e');
      return null; // Return null on error
    }
  }

  /// Retrieves the label for a given account address and inbox ID.
  static Future<String?> getLabelByAccountInboxId(EthereumAddress accountAddress, Uint8List inboxId) async {
    try {
      Log.d(_tag, 'Getting Label for Account: ${accountAddress.eip55With0x}, InboxID: ${bytes32ToString(inboxId)}');
      final label = await Future.any([
        PublicOSBsp.xmtpManagerContract.getAccountInboxIdLabel(
          (accountAddress: accountAddress, inboxId: inboxId),
        ),
        Future.delayed(const Duration(seconds: 5)).then((_) => throw TimeoutException('Get account inbox ID label timed out')),
      ]);
      if (label.isEmpty) {
        Log.d(_tag, 'No label found for Account: ${accountAddress.eip55With0x}, InboxID: ${bytes32ToString(inboxId)} (empty string)');
        return null; // Return null if label is empty
      }
      Log.d(_tag, 'Retrieved Label: $label for Account: ${accountAddress.eip55With0x}, InboxID: ${bytes32ToString(inboxId)}');
      return label;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error retrieving inbox ID label: $e');
      return null; // Return null on error
    }
  }

  /// Retrieves all inbox IDs and their labels for a given account address.
  /// Chain read, not an XMTP network op — used primarily by
  /// `PublicOSContacts.fetchContact` to populate `Contact.registeredInboxIDs`.
  /// Logs under `Xmtp.Contacts` so the call site is obvious in traces.
  static Future<XmtpManagerContract.GetAllAccountInboxIds?> getAllAccountInboxIds(EthereumAddress accountAddress) async {
    const tag = 'Xmtp.Contacts';
    try {
      Log.d(tag, 'Retrieving all inbox IDs for Account: ${accountAddress.eip55With0x}');
      final result = await Future.any([
        PublicOSBsp.xmtpManagerContract.getAllAccountInboxIds(
          (accountAddress: accountAddress),
        ),
        Future.delayed(const Duration(seconds: 5)).then((_) => throw TimeoutException('Get all account inbox IDs timed out')),
      ]);
      Log.d(tag, 'Retrieved all inbox IDs for Account: ${accountAddress.eip55With0x}. Found ${result.inboxIds.length} IDs.');
      return result;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(tag, 'Error retrieving all inbox IDs: $e');
      return null; // Return null on error
    }
  }

  /// Checks if an inbox ID exists for the current account.
  static Future<bool> accountInboxIdExists(Uint8List inboxId) async {
    try {
      Log.d(_tag, 'Checking if InboxID ${bytes32ToString(inboxId)} exists.');
      final exists = await Future.any([
        PublicOSBsp.xmtpManagerContract.accountInboxIdExists(
          (inboxId: inboxId),
        ),
        Future.delayed(const Duration(seconds: 5)).then((_) => throw TimeoutException('Account inbox ID exists check timed out')),
      ]);
      Log.d(_tag, 'InboxID ${bytes32ToString(inboxId)} exists: $exists');
      return exists;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error checking if inbox ID exists: $e');
      return false; // Return false on error
    }
  }

  /// Checks if a label exists for a given account address.
  static Future<bool> accountLabelExists(EthereumAddress accountAddress, String label) async {
    try {
      Log.d(_tag, 'Checking if Label $label exists for account ${accountAddress.eip55With0x}.');
      final exists = await Future.any([
        PublicOSBsp.xmtpManagerContract.accountLabelExists(
          (accountAddress: accountAddress, label: label),
        ),
        Future.delayed(const Duration(seconds: 5)).then((_) => throw TimeoutException('Account label exists check timed out')),
      ]);
      Log.d(_tag, 'Label $label for account ${accountAddress.eip55With0x} exists: $exists');
      return exists;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error checking if label exists: $e');
      return false; // Return false on error
    }
  }

  // ============================================================================
  // INBOX MANAGEMENT - Installation and identity management for XMTP inbox
  // ============================================================================

  /// Get the current client's installation ID.
  /// This is the unique identifier for this specific device/app installation.
  static Future<String?> getInstallationId() async {
    try {
      Log.d(_tag, '[INBOX] Getting installation ID');
      final installationId = await PublicOS.xmtpClient!.getInstallationId();
      Log.d(_tag, '[INBOX] Installation ID: ${installationId.substring(0, 16)}...');
      return installationId;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, '[INBOX] Error getting installation ID: $e');
      return null;
    }
  }

  /// Get the current client's inbox state.
  /// Returns information about all identities and installations associated with this inbox.
  ///
  /// Returns map containing:
  /// - inboxId: String
  /// - identities: List of {identifier: String, kind: 'ethereum' | 'passkey'}
  /// - installations: List of {id: String, createdAt: int?}
  /// - recoveryIdentity: {identifier: String, kind: 'ethereum' | 'passkey'}
  static Future<Map<String, dynamic>?> getInboxState({bool refreshFromNetwork = false}) async {
    try {
      Log.d(_tag, '[INBOX] Getting inbox state (refreshFromNetwork: $refreshFromNetwork)');
      final state = await Future.any([
        PublicOS.xmtpClient!.inboxState(refreshFromNetwork: refreshFromNetwork),
        Future.delayed(const Duration(seconds: 10)).then((_) => throw TimeoutException('Get inbox state timed out')),
      ]);
      final installations = state['installations'] as List? ?? [];
      final identities = state['identities'] as List? ?? [];
      Log.i(_tag, '[INBOX] Inbox state retrieved - ${installations.length} installations, ${identities.length} identities');
      return state;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, '[INBOX] Error getting inbox state: $e');
      return null;
    }
  }

  /// Revoke specific installations by their IDs.
  /// This removes the ability for those installations to send/receive messages.
  ///
  /// [xmtpPrivateKey] - The XMTP private key used to sign the revocation
  /// [installationIds] - List of installation IDs to revoke
  static Future<bool> revokeInstallations(Uint8List xmtpPrivateKey, List<String> installationIds) async {
    try {
      Log.d(_tag, '[INBOX] Revoking ${installationIds.length} installations');
      await Future.any([
        PublicOS.xmtpClient!.revokeInstallations(xmtpPrivateKey, installationIds),
        Future.delayed(const Duration(seconds: 15)).then((_) => throw TimeoutException('Revoke installations timed out')),
      ]);
      Log.i(_tag, '[INBOX] Successfully revoked ${installationIds.length} installations');
      return true;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, '[INBOX] Error revoking installations: $e');
      return false;
    }
  }

  /// Revoke all installations except the current one.
  /// This is useful for "log out all other devices" functionality.
  ///
  /// [xmtpPrivateKey] - The XMTP private key used to sign the revocation
  static Future<bool> revokeAllOtherInstallations(Uint8List xmtpPrivateKey) async {
    try {
      Log.d(_tag, '[INBOX] Revoking all other installations');
      await Future.any([
        PublicOS.xmtpClient!.revokeAllOtherInstallations(xmtpPrivateKey),
        Future.delayed(const Duration(seconds: 15)).then((_) => throw TimeoutException('Revoke all other installations timed out')),
      ]);
      Log.i(_tag, '[INBOX] Successfully revoked all other installations');
      return true;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, '[INBOX] Error revoking all other installations: $e');
      return false;
    }
  }

  /// Add a new account/identity to the current inbox.
  ///
  /// WARNING: If [allowReassignInboxId] is true and the new account was already
  /// associated with a different inbox, it will LOSE ACCESS to that inbox permanently!
  ///
  /// [newAccountPrivateKey] - The private key of the new account to add
  /// [allowReassignInboxId] - If true, allows reassigning an inbox ID (dangerous!)
  static Future<bool> addAccountToInbox(Uint8List newAccountPrivateKey, {bool allowReassignInboxId = false}) async {
    try {
      Log.d(_tag, '[INBOX] Adding account to inbox (allowReassignInboxId: $allowReassignInboxId)');
      await Future.any([
        PublicOS.xmtpClient!.addAccount(newAccountPrivateKey, allowReassignInboxId: allowReassignInboxId),
        Future.delayed(const Duration(seconds: 15)).then((_) => throw TimeoutException('Add account timed out')),
      ]);
      Log.i(_tag, '[INBOX] Successfully added account to inbox');
      return true;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, '[INBOX] Error adding account to inbox: $e');
      return false;
    }
  }

  /// Remove an identity from the current inbox.
  /// The identity being removed cannot be the recovery identity.
  ///
  /// [recoveryPrivateKey] - The private key of the recovery account (to authorize the removal)
  /// [identifierToRemove] - The address/identifier of the identity to remove
  static Future<bool> removeAccountFromInbox(Uint8List recoveryPrivateKey, String identifierToRemove) async {
    try {
      Log.d(_tag, '[INBOX] Removing account $identifierToRemove from inbox');
      await Future.any([
        PublicOS.xmtpClient!.removeAccount(recoveryPrivateKey, identifierToRemove),
        Future.delayed(const Duration(seconds: 15)).then((_) => throw TimeoutException('Remove account timed out')),
      ]);
      Log.i(_tag, '[INBOX] Successfully removed account from inbox');
      return true;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, '[INBOX] Error removing account from inbox: $e');
      return false;
    }
  }

  /// Revoke installations without an active client.
  /// Useful for "security wipe all devices" when the user is logged out.
  ///
  /// Routes to the plugin's true static path (`XmtpPlugin.staticRevokeInstallations`),
  /// which needs no active client and signs for the given [inboxId] — the
  /// signer key alone authorizes the revocation, so this works for inboxes
  /// other than the active client's. (Routing to the
  /// ACTIVE client's instance method would silently drop [inboxId].)
  ///
  /// [signerPrivateKey] - The recovery key of the target inbox (signs the revocation)
  /// [inboxId] - The inbox ID to revoke installations for
  /// [installationIds] - List of installation IDs to revoke
  static Future<bool> staticRevokeInstallations({
    required Uint8List signerPrivateKey,
    required String inboxId,
    required List<String> installationIds,
  }) async {
    try {
      Log.d(_tag, '[INBOX] Static revoking ${installationIds.length} installations for inbox ${inboxId.substring(0, 16)}...');
      await Future.any([
        XmtpPlugin.staticRevokeInstallations(
          signerPrivateKey: signerPrivateKey,
          inboxId: inboxId,
          installationIds: installationIds,
        ),
        Future.delayed(const Duration(seconds: 30)).then((_) => throw TimeoutException('Static revoke installations timed out')),
      ]);
      Log.i(_tag, '[INBOX] Successfully static revoked ${installationIds.length} installations');
      return true;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, '[INBOX] Error static revoking installations: $e');
      return false;
    }
  }

  /// Change the recovery identifier for this inbox.
  ///
  /// NOTE: This is only supported on web platforms.
  /// On mobile platforms, this will throw an error.
  ///
  /// [signerPrivateKey] - The current recovery key to authorize the change
  /// [newRecoveryIdentifier] - The new recovery address/identifier
  static Future<bool> changeRecoveryIdentifier(Uint8List signerPrivateKey, String newRecoveryIdentifier) async {
    try {
      Log.d(_tag, '[INBOX] Changing recovery identifier to $newRecoveryIdentifier');
      await Future.any([
        PublicOS.xmtpClient!.changeRecoveryIdentifier(signerPrivateKey, newRecoveryIdentifier),
        Future.delayed(const Duration(seconds: 15)).then((_) => throw TimeoutException('Change recovery identifier timed out')),
      ]);
      Log.i(_tag, '[INBOX] Successfully changed recovery identifier');
      return true;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, '[INBOX] Error changing recovery identifier: $e');
      return false;
    }
  }

  // ============================================================================
  // INBOX STATE QUERIES
  // ============================================================================

  /// Get inbox states (including ETH addresses) for given inbox IDs.
  /// Returns list of states containing inboxId, identities, recoveryIdentity, installations.
  /// Each identity has {identifier: String (ETH address), kind: 'ethereum' | 'passkey'}
  static Future<List<Map<String, dynamic>>?> getInboxStates(
    List<String> inboxIds,
    {bool refreshFromNetwork = true}
  ) async {
    try {
      Log.d(_tag, 'Getting inbox states for ${inboxIds.length} inbox IDs${inboxIds.isNotEmpty ? ' - first: ${inboxIds.first}' : ''}');
      final result = await Future.any([
        PublicOS.xmtpClient!.inboxStatesForInboxIds(inboxIds, refreshFromNetwork: refreshFromNetwork),
        Future.delayed(const Duration(seconds: 8)).then((_) => throw TimeoutException('Get inbox states timed out')),
      ]);
      Log.d(_tag, 'Retrieved ${result.length} inbox states');
      return result;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting inbox states: $e');
      return null;
    }
  }

  // ============================================================================
  // NATIVE ARCHIVE BACKUP (libxmtp encrypted archive export/import into the MLS
  // store). Thin pass-throughs to the xmtp_plugin facade, which derives the
  // encryption key from the password (Argon2id, salt = inbox_id) before the
  // native call.
  // ============================================================================

  /// Export an encrypted archive of the active inbox to [path] (a `.xmtpBak`
  /// file). An empty [elements] archives both Messages + Consent (the default).
  /// [password] derives the encryption key; the key never leaves the plugin.
  static Future<void> exportArchive(
    String path,
    String password, {
    List<BackupElement> elements = const [],
    int? startNs,
    int? endNs,
    bool excludeDisappearing = false,
  }) async {
    final client = PublicOS.xmtpClient;
    if (client == null) {
      throw StateError('No active XMTP session — cannot export an archive.');
    }
    final sw = Stopwatch()..start();
    Log.i(_tag,
        '[ARCHIVE] export → $path (elements=${elements.isEmpty ? 'all' : elements.map((e) => e.name).join('+')})');
    await client.exportArchive(
      path,
      password,
      elements: elements,
      startNs: startNs,
      endNs: endNs,
      excludeDisappearing: excludeDisappearing,
    );
    Log.i(_tag, '[ARCHIVE] export DONE in ${sw.elapsedMilliseconds}ms → $path');
  }

  /// Read an archive's header (scope/counts/time range) without importing.
  /// A wrong [password] (or an archive from a different inbox) fails to decrypt
  /// and throws — surface a "wrong password / not your archive" message.
  static Future<ArchiveMetadata> archiveMetadata(String path, String password) async {
    final client = PublicOS.xmtpClient;
    if (client == null) {
      throw StateError('No active XMTP session — cannot read an archive.');
    }
    return client.archiveMetadata(path, password);
  }

  /// Decrypt + import an archive at [path] into the active inbox's MLS store
  /// (additive). A wrong [password] / foreign-inbox archive simply fails to
  /// decrypt — nothing is imported. This cryptographic scope guard replaces the
  /// old strict-match `(sessionAddress, ownerInboxId)` JSON check.
  ///
  /// Imports land directly in the MLS store, so libxmtp lists the restored
  /// conversations natively — there is NO display gap and no topic-heal.
  /// **Callers MUST run a full conversation/message reload afterward** (the
  /// full-reload-after-tx convention) — the SDK can't repaint the UI, and that
  /// reload also repopulates the Drift mirror via the normal sync+load path.
  ///
  /// Pauses the live incoming-message stream for the duration of the import.
  /// The importer is a local-only DB insert, but on Android/iOS it shares
  /// libxmtp's single tokio runtime + SQLite with the `streamAllMessages` loop;
  /// a busy stream (e.g. a forked group thrashing recovery-sync) starves the
  /// import so it never returns — the "Restoring backup…" overlay hangs forever.
  /// Pausing → import → resuming runs the import in a quiet runtime. The stream
  /// is only resumed if it was active going in, so no caller can forget. (On
  /// Windows this pause is a harmless no-op — import never hangs there.)
  static Future<void> importArchive(String path, String password) async {
    final client = PublicOS.xmtpClient;
    if (client == null) {
      throw StateError('No active XMTP session — cannot import an archive.');
    }
    final wasStreaming = PublicOSConversations.isStreamActive;
    if (wasStreaming) {
      await PublicOSConversations.disposeMessages();
    }
    final sw = Stopwatch()..start();
    try {
      Log.i(_tag, '[ARCHIVE] import ← $path (stream paused=$wasStreaming)');
      await client.importArchive(path, password);
      Log.i(_tag,
          '[ARCHIVE] import DONE in ${sw.elapsedMilliseconds}ms — caller must full-reload conversations');
    } finally {
      if (wasStreaming) {
        await PublicOSConversations.initializeMessages();
      }
    }
  }
}
