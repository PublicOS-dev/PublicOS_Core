import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:publicos_core/src/core/core.dart';
import 'package:publicos_core/src/utils/log.dart';
import 'package:web3dart/web3dart.dart';
import 'package:wallet/wallet.dart';
import 'package:xmtp_plugin/xmtp_plugin.dart';

/// Thrown when XMTP client initialization fails because the local database
/// already exists with a different encryption key. The caller should offer
/// the user a choice: provide the original DB key, or wipe the local DB.
class XmtpDbKeyMismatchException implements Exception {
  final String walletAddress;
  final String message;
  XmtpDbKeyMismatchException({required this.walletAddress, this.message = ''});

  @override
  String toString() => 'XmtpDbKeyMismatchException($walletAddress): '
      'Local XMTP database exists with a different encryption key. $message';
}

/// Thrown when XMTP client initialization fails because the key's inbox has
/// reached the protocol maximum of 10 registered installations
/// (libxmtp `TooManyInstallations`, "not retryable"). This is NETWORK state —
/// wiping the local database cannot fix it and must never be offered as the
/// remedy. Recovery = revoke installations (selectively on a device where the
/// key still works, or revoke-all signed by this key).
class XmtpInstallationCapException implements Exception {
  final String walletAddress;
  final String message;
  XmtpInstallationCapException({required this.walletAddress, this.message = ''});

  @override
  String toString() => 'XmtpInstallationCapException($walletAddress): '
      'This key\'s inbox is at XMTP\'s 10-installation limit. $message';
}

/// Whether a key is set up for XMTP messaging ON THIS DEVICE.
/// - [ready]: the DB encryption key is stored and (when checkable) the local
///   database file is present — activation can open it silently, no cost.
/// - [missing]: no local setup for this key on this device — the user must
///   choose to create fresh (registers a new installation) or restore a
///   database backup.
/// - [broken]: the encryption key is stored but the database file is gone
///   (e.g. app data cleared) — offer restore, or create fresh.
enum XmtpSetupStatus { ready, missing, broken }

/// Thrown by [PublicOSKeychain.selectKey] when a key is not set up for XMTP on
/// this device. The caller must run [PublicOSKeychain.setupFreshXmtp] or
/// [PublicOSKeychain.restoreXmtpBackup] first — activation never creates a
/// database implicitly.
class XmtpNotSetUpException implements Exception {
  final String walletAddress;
  final XmtpSetupStatus status;
  XmtpNotSetUpException({required this.walletAddress, required this.status});

  @override
  String toString() =>
      'XmtpNotSetUpException($walletAddress): messaging is not set up for this '
      'key on this device (status: ${status.name}).';
}

/// Extension on PublicOS to manage protocol-agnostic keychain operations.
/// Handles key generation, storage, retrieval, import/export, and selection.
extension PublicOSKeychain on PublicOS {
  static const _tag = 'Keychain';

  ///*********************************************
  /// STORAGE KEY HELPERS
  ///*********************************************

  /// Generate storage key for a private key
  static String _getKeyStorageKey(String userAddress, String label) {
    return '${PublicOS.keychainKeyPrefix}${userAddress}_$label';
  }

  /// Generate storage key for key metadata
  static String _getMetadataStorageKey(String userAddress, String label) {
    return '${PublicOS.keychainMetadataPrefix}${userAddress}_$label';
  }

  /// Generate storage key for the keychain index
  static String _getIndexStorageKey(String userAddress) {
    return '${PublicOS.keychainIndexPrefix}$userAddress';
  }

  /// Generate storage key for XMTP DB key (indexed by wallet address, not label)
  static String _getXmtpDbKeyStorageKey(String userAddress, String walletAddress) {
    return '${PublicOS.xmtpDbKeyPrefix}${userAddress}_${walletAddress.toLowerCase()}';
  }

  /// Map an XMTP client-init failure during key import to a typed exception.
  ///
  /// The installation cap (libxmtp `TooManyInstallations`) is checked FIRST —
  /// it is network state and must never be answered with the local-DB wipe
  /// dialog. The DB-key mismatch mapping only fires on genuine SQLCipher
  /// wrong-key signatures; everything else passes through with libxmtp's
  /// message intact. (Blanket-mapping any `CLIENT_INITIALIZATION_FAILED` to a
  /// DB mismatch would route cap-limited users into a destructive, useless
  /// local wipe.)
  static Never _throwMappedInitError(Object initError, String address) {
    Log.e(_tag, 'XMTP client init failed during import for $address: $initError');
    final errStr = initError.toString().toLowerCase();
    if (errStr.contains('too many installations') ||
        errStr.contains('toomanyinstallations') ||
        errStr.contains('max installation')) {
      throw XmtpInstallationCapException(
          walletAddress: address, message: initError.toString());
    }
    if (errStr.contains('hmac') ||
        errStr.contains('malformed') ||
        errStr.contains('notadb') ||
        errStr.contains('not a database') ||
        errStr.contains('pragma key') ||
        errStr.contains('sql logic error')) {
      throw XmtpDbKeyMismatchException(
          walletAddress: address, message: initError.toString());
    }
    // ignore: only_throw_errors
    throw initError;
  }

  /// Generate storage key for XMTP selected key
  static String _getXmtpSelectedKeyStorageKey(String userAddress) {
    return '${PublicOS.xmtpSelectedKeyPrefix}$userAddress';
  }

  /// Generate storage key for XMTP last used key
  static String _getXmtpLastKeyStorageKey(String userAddress) {
    return '${PublicOS.xmtpLastKeyPrefix}$userAddress';
  }

  ///*********************************************
  /// HELPER FUNCTIONS FOR KEY FORMAT CONVERSION
  ///*********************************************

  /// Converts hex string (with or without '0x' prefix) to Uint8List
  static Uint8List hexToBytes(String hex) {
    hex = hex.startsWith('0x') ? hex.substring(2) : hex;
    if (hex.length % 2 != 0) {
      hex = '0$hex'; // Pad with leading zero if odd length
    }
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      final byteString = hex.substring(i, i + 2);
      bytes.add(int.parse(byteString, radix: 16));
    }
    return Uint8List.fromList(bytes);
  }

  /// Converts Uint8List to hex string with optional '0x' prefix
  static String bytesToHex(Uint8List bytes, {bool prefix = true}) {
    final hexChars = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return (prefix ? '0x' : '') + hexChars;
  }

  /// Converts BigInt to 32-byte Uint8List (for private keys)
  static Uint8List bigIntToBytes(BigInt value) {
    final hex = value.toRadixString(16).padLeft(64, '0'); // 64 hex chars = 32 bytes
    return hexToBytes(hex);
  }

  /// Derives private key from mnemonic using BIP44 Ethereum path
  /// Returns: {privateKey: EthPrivateKey, privateKeyHex: String, address: String}
  static Map<String, dynamic> deriveKeyFromMnemonic(List<String> mnemonicList) {
    // Convert mnemonic to seed
    final seed = mnemonicToSeed(mnemonicList);

    // Derive key using BIP44 path for Ethereum
    const path = "m/44'/60'/0'/0/0";
    final master = ExtendedPrivateKey.master(seed, xprv);
    final root = master.forPath(path);

    // Extract private key
    final extendedPrivateKey = root as ExtendedPrivateKey;
    final privateKeyBigInt = extendedPrivateKey.key;
    final privateKeyBytes = bigIntToBytes(privateKeyBigInt);
    final privateKeyHex = bytesToHex(privateKeyBytes, prefix: true);

    // Create EthPrivateKey and derive address
    final ethPrivateKey = EthPrivateKey.fromHex(privateKeyHex);
    final address = ethPrivateKey.address.eip55With0x;

    return {
      'privateKey': ethPrivateKey,
      'privateKeyHex': privateKeyHex,
      'address': address,
    };
  }

  ///*********************************************
  /// INDEX MANAGEMENT
  ///*********************************************

  /// Get list of key labels for a user
  static Future<List<String>> getKeyIndex(String userAddress) async {
    final indexKey = _getIndexStorageKey(userAddress);
    final String? indexString = await PublicOS.secureStorage.read(key: indexKey);

    if (indexString == null || indexString.isEmpty) {
      return [];
    }

    final List<dynamic> keyLabels = jsonDecode(indexString);
    return keyLabels.cast<String>();
  }

  /// Add a label to the index
  static Future<void> addToIndex(String userAddress, String label) async {
    final indexKey = _getIndexStorageKey(userAddress);
    final List<String> keyLabels = await getKeyIndex(userAddress);

    if (!keyLabels.contains(label)) {
      keyLabels.add(label);
      await PublicOS.secureStorage.write(key: indexKey, value: jsonEncode(keyLabels));
    }
  }

  /// Remove a label from the index
  static Future<void> removeFromIndex(String userAddress, String label) async {
    final indexKey = _getIndexStorageKey(userAddress);
    final List<String> keyLabels = await getKeyIndex(userAddress);

    keyLabels.remove(label);
    await PublicOS.secureStorage.write(key: indexKey, value: jsonEncode(keyLabels));
  }

  /// Update a label in the index
  static Future<void> updateIndexLabel(String userAddress, String oldLabel, String newLabel) async {
    final indexKey = _getIndexStorageKey(userAddress);
    final List<String> keyLabels = await getKeyIndex(userAddress);

    final index = keyLabels.indexOf(oldLabel);
    if (index != -1) {
      keyLabels[index] = newLabel;
      await PublicOS.secureStorage.write(key: indexKey, value: jsonEncode(keyLabels));
    }
  }

  ///*********************************************
  /// KEY STORAGE & RETRIEVAL
  ///*********************************************

  /// Fetch all keys for a user
  /// Returns a list of key data maps with metadata
  static Future<List<Map<String, dynamic>>> fetchKeys(String userAddress) async {
    try {
      final List<String> keyLabels = await getKeyIndex(userAddress);
      final List<Map<String, dynamic>> fetchedKeys = [];

      for (String label in keyLabels) {
        final keyKey = _getKeyStorageKey(userAddress, label);
        final metadataKey = _getMetadataStorageKey(userAddress, label);

        final String? keyString = await PublicOS.secureStorage.read(key: keyKey);
        final String? metadataString = await PublicOS.secureStorage.read(key: metadataKey);

        if (keyString != null && keyString.isNotEmpty) {
          try {
            final privateKeyBytes = base64Decode(keyString);
            final privateKeyHex = utf8.decode(privateKeyBytes);

            Map<String, dynamic> metadata = {};
            if (metadataString != null && metadataString.isNotEmpty) {
              metadata = jsonDecode(metadataString);
            }

            // Generate address from private key if not in metadata
            String address = metadata['address'] ?? 'Unknown';
            if (address == 'Unknown') {
              try {
                final privateKey = EthPrivateKey.fromHex(privateKeyHex);
                address = privateKey.address.eip55With0x;
              } catch (e) {
                Log.e(_tag, 'Error generating address for key $label: $e');
              }
            }

            fetchedKeys.add({
              'label': label,
              'privateKey': privateKeyHex,
              'address': address,
              'inboxId': metadata['inboxId'] ?? 'pending_initialization',
              'isGroupKey': metadata['isGroupKey'] ?? false,
              'orgAddress': metadata['orgAddress'] ?? metadata['groupAddress'],
              'color': metadata['color'] ?? Colors.blue.value,
              'emoji': metadata['emoji'] ?? '🔑',
              'walletEnabled': metadata['walletEnabled'] ?? false,
              'relatedOsuxAccount': metadata['relatedOsuxAccount'] ?? 'unknown',
              'timestamp': metadata['timestamp'],
              'mnemonic': metadata['mnemonic'], // May be null
            });
          } catch (e) {
            Log.e(_tag, 'Error parsing key data for label $label: $e');
            fetchedKeys.add({
              'label': label,
              'privateKey': 'Error loading key',
              'address': 'Unknown',
              'inboxId': 'Error',
              'isGroupKey': false,
              'orgAddress': null,
              'color': Colors.grey.value,
              'emoji': '🔑',
              'walletEnabled': false,
              'relatedOsuxAccount': 'unknown',
              'timestamp': null,
              'mnemonic': null,
            });
          }
        }
      }

      // Sort by label
      fetchedKeys.sort((a, b) => (a['label'] as String).toLowerCase().compareTo((b['label'] as String).toLowerCase()));
      return fetchedKeys;
    } catch (e) {
      Log.e(_tag, 'Error fetching keys: $e');
      throw Exception('Error fetching keychain keys: $e');
    }
  }

  /// Save a key with metadata
  /// [privateKeyHex] should be hex string with 0x prefix
  static Future<void> saveKey(
    String userAddress,
    String label,
    String privateKeyHex,
    Map<String, dynamic> metadata,
  ) async {
    try {
      // Store the private key (base64 encoded, without 0x prefix)
      final cleanHex = privateKeyHex.startsWith('0x') ? privateKeyHex.substring(2) : privateKeyHex;
      final base64Pk = base64Encode(utf8.encode(cleanHex));
      final keyKey = _getKeyStorageKey(userAddress, label);
      await PublicOS.secureStorage.write(key: keyKey, value: base64Pk);

      // Store metadata
      final metadataKey = _getMetadataStorageKey(userAddress, label);
      await PublicOS.secureStorage.write(key: metadataKey, value: jsonEncode(metadata));

      // Add to index
      await addToIndex(userAddress, label);

      Log.i(_tag, 'Key "$label" saved successfully for user $userAddress');
    } catch (e) {
      Log.e(_tag, 'Error saving key: $e');
      throw Exception('Error saving keychain key: $e');
    }
  }

  /// Delete a key and all associated data
  /// Note: The XMTP DB key (indexed by wallet address) is NOT deleted here,
  /// because the DB file persists on disk and another label could share the same wallet.
  static Future<void> deleteKey(String userAddress, String label) async {
    try {
      // Delete the key and metadata (DB key is kept — see note above)
      final keyKey = _getKeyStorageKey(userAddress, label);
      final metadataKey = _getMetadataStorageKey(userAddress, label);

      await PublicOS.secureStorage.delete(key: keyKey);
      await PublicOS.secureStorage.delete(key: metadataKey);

      // Remove from index
      await removeFromIndex(userAddress, label);

      // Clear selection if this was the selected key
      final selectedKey = await getXmtpSelectedKey(userAddress);
      if (selectedKey == label) {
        await clearXmtpSelectedKey(userAddress);

        // Clear core XMTP variables if this was the active key
        if (PublicOS.currentXmtpKeyLabel == label) {
          PublicOS.currentXMTPPrivateKey = null;
          PublicOS.clientXmtpAddress = null;
          PublicOS.clientXmtpInboxId = null;
          PublicOS.currentXmtpDbKey = null;
          PublicOS.currentXmtpKeyLabel = null;
        }
      }

      Log.i(_tag, 'Key "$label" deleted successfully');
    } catch (e) {
      Log.e(_tag, 'Error deleting key: $e');
      throw Exception('Error deleting keychain key: $e');
    }
  }

  /// Update a key's label
  /// Note: XMTP DB key is not affected — it's indexed by wallet address, not label.
  static Future<void> updateKeyLabel(String userAddress, String oldLabel, String newLabel) async {
    try {
      // Get existing data
      final oldKeyKey = _getKeyStorageKey(userAddress, oldLabel);
      final oldMetadataKey = _getMetadataStorageKey(userAddress, oldLabel);

      final keyData = await PublicOS.secureStorage.read(key: oldKeyKey);
      final metadataData = await PublicOS.secureStorage.read(key: oldMetadataKey);

      if (keyData == null) {
        throw Exception('Key data not found for label: $oldLabel');
      }

      // Update metadata with new label
      Map<String, dynamic> metadata = {};
      if (metadataData != null) {
        metadata = jsonDecode(metadataData);
        metadata['label'] = newLabel;
      }

      // Create new storage keys with new label
      final newKeyKey = _getKeyStorageKey(userAddress, newLabel);
      final newMetadataKey = _getMetadataStorageKey(userAddress, newLabel);

      // Store with new label
      await PublicOS.secureStorage.write(key: newKeyKey, value: keyData);
      if (metadata.isNotEmpty) {
        await PublicOS.secureStorage.write(key: newMetadataKey, value: jsonEncode(metadata));
      }

      // Update the index
      await updateIndexLabel(userAddress, oldLabel, newLabel);

      // Update selection if this was the selected key
      final selectedKey = await getXmtpSelectedKey(userAddress);
      if (selectedKey == oldLabel) {
        await setXmtpSelectedKey(userAddress, newLabel);

        // Update core state
        PublicOS.currentXmtpKeyLabel = newLabel;
      }

      // Delete old storage entries
      await PublicOS.secureStorage.delete(key: oldKeyKey);
      await PublicOS.secureStorage.delete(key: oldMetadataKey);

      Log.i(_tag, 'Key label updated from "$oldLabel" to "$newLabel"');
    } catch (e) {
      Log.e(_tag, 'Error updating key label: $e');
      throw Exception('Error updating key label: $e');
    }
  }

  ///*********************************************
  /// KEY GENERATION
  ///*********************************************

  /// Generate a new mnemonic phrase (12 words)
  static String generateMnemonicPhrase() {
    final mnemonicList = generateMnemonic();
    return mnemonicList.join(' ');
  }

  /// Generate a new key with mnemonic
  /// Returns complete key data including mnemonic, private key, address, and inbox ID
  /// [emoji] is the key's avatar glyph, chosen by the user at creation;
  /// omitted falls back to the default. Purely cosmetic and
  /// changeable later with [setKeyEmoji] — nothing keys off it.
  static Future<Map<String, dynamic>> generateNewKey(
    String userAddress,
    String label, {
    bool isGroupKey = false,
    EthereumAddress? orgAddress,
    String? emoji,
  }) async {
    try {
      Log.d(_tag, 'Generating new key with label "$label"');

      // Check if label already exists
      final existingKeys = await getKeyIndex(userAddress);
      if (existingKeys.contains(label)) {
        throw Exception('A key with this label already exists');
      }

      // 1. Generate 12-word mnemonic
      final mnemonicList = generateMnemonic();
      final mnemonic = mnemonicList.join(' ');

      // 2. Derive private key from mnemonic
      final keyInfo = deriveKeyFromMnemonic(mnemonicList);
      final newPrivateKey = keyInfo['privateKey'] as EthPrivateKey;
      final privateKeyHex = keyInfo['privateKeyHex'] as String;
      final address = keyInfo['address'] as String;

      // 3. PASSIVE generation — no XMTP client is booted (see importFromMnemonic).
      // A fresh key has no inbox yet; both the inboxId and the DB encryption
      // key are established at first activation (setupFreshXmtp).
      final colors = [Colors.blue, Colors.purple, Colors.green, Colors.orange, Colors.red, Colors.teal];
      final selectedColor = colors[Random().nextInt(colors.length)];

      // 4. Create metadata
      final metadata = {
        'label': label,
        'address': address,
        'inboxId': null, // stamped at first activation
        'mnemonic': mnemonic,
        'timestamp': DateTime.now().toIso8601String(),
        'createdBy': userAddress,
        'relatedOsuxAccount': userAddress,
        'color': selectedColor.value,
        'emoji': (emoji != null && emoji.isNotEmpty) ? emoji : '🔑',
        'walletEnabled': false,
        'isGroupKey': isGroupKey,
        'orgAddress': orgAddress?.eip55With0x,
      };

      // 5. Save the key
      await saveKey(userAddress, label, privateKeyHex, metadata);

      Log.i(_tag, 'Key "$label" generated successfully (passive — not activated)');

      return {
        'label': label,
        'privateKey': newPrivateKey,
        'privateKeyHex': privateKeyHex,
        'address': address,
        'inboxId': null,
        'mnemonic': mnemonic,
        'metadata': metadata,
      };
    } catch (e) {
      Log.e(_tag, 'Error generating new key: $e');
      throw Exception('Error generating new key: $e');
    }
  }

  ///*********************************************
  /// IMPORT/EXPORT
  ///*********************************************

  /// Import a key from mnemonic phrase
  static Future<Map<String, dynamic>> importFromMnemonic(
    String userAddress,
    String mnemonic,
    String label, {
    bool isGroupKey = false,
    EthereumAddress? orgAddress,
    // The key's avatar glyph, picked in the import prompt (same
    // field and default as generateNewKey's).
    String? emoji,
  }) async {
    try {
      Log.d(_tag, 'Importing key from mnemonic with label "$label"');

      // Check if label already exists
      final existingKeys = await getKeyIndex(userAddress);
      if (existingKeys.contains(label)) {
        throw Exception('A key with this label already exists');
      }

      // Parse and validate mnemonic
      final mnemonicList = mnemonic.split(' ').where((s) => s.isNotEmpty).toList();

      if (!validateMnemonic(mnemonicList)) {
        throw Exception('Invalid mnemonic phrase');
      }

      // Derive private key from mnemonic
      final keyInfo = deriveKeyFromMnemonic(mnemonicList);
      final newPrivateKey = keyInfo['privateKey'] as EthPrivateKey;
      final privateKeyHex = keyInfo['privateKeyHex'] as String;
      final address = keyInfo['address'] as String;

      // PASSIVE import — no XMTP client is booted here. Importing a key must
      // never touch the network: booting a client to read the inboxId would
      // register an installation (burning one of the inbox's 10 slots) for a
      // key the user might never activate. The inboxId is stamped later, at
      // first activation (setupFreshXmtp / restoreXmtpBackup), from the real
      // client. The DB encryption key is likewise generated at setup time, not
      // here — its presence is the "set up on this device" signal.
      final colors = [Colors.blue, Colors.purple, Colors.green, Colors.orange, Colors.red, Colors.teal];
      final selectedColor = colors[Random().nextInt(colors.length)];

      final metadata = {
        'label': label,
        'address': address,
        'inboxId': null, // stamped at first activation
        'mnemonic': mnemonic,
        'timestamp': DateTime.now().toIso8601String(),
        'createdBy': userAddress,
        'relatedOsuxAccount': userAddress,
        'color': selectedColor.value,
        'emoji': (emoji != null && emoji.isNotEmpty) ? emoji : '🔑',
        'walletEnabled': false,
        'isGroupKey': isGroupKey,
        'orgAddress': orgAddress?.eip55With0x,
      };

      // Save the key
      await saveKey(userAddress, label, privateKeyHex, metadata);

      Log.i(_tag, 'Key imported from mnemonic successfully (passive — not activated)');

      return {
        'label': label,
        'privateKey': newPrivateKey,
        'privateKeyHex': privateKeyHex,
        'address': address,
        'inboxId': null,
        'metadata': metadata,
      };
    } catch (e) {
      Log.e(_tag, 'Error importing from mnemonic: $e');
      throw Exception('Error importing from mnemonic: $e');
    }
  }

  /// Import a key from private key hex string
  static Future<Map<String, dynamic>> importFromPrivateKey(
    String userAddress,
    String privateKeyHex,
    String label, {
    bool isGroupKey = false,
    EthereumAddress? orgAddress,
    // The key's avatar glyph, picked in the import prompt (same
    // field and default as generateNewKey's).
    String? emoji,
  }) async {
    try {
      Log.d(_tag, 'Importing key from private key hex with label "$label"');

      // Check if label already exists
      final existingKeys = await getKeyIndex(userAddress);
      if (existingKeys.contains(label)) {
        throw Exception('A key with this label already exists');
      }

      // Parse private key hex (with or without 0x prefix)
      String cleanHex = privateKeyHex.trim();
      if (!cleanHex.startsWith('0x')) {
        cleanHex = '0x$cleanHex';
      }

      // Create private key from hex
      final newPrivateKey = EthPrivateKey.fromHex(cleanHex);
      final address = newPrivateKey.address.eip55With0x;

      // PASSIVE import — no XMTP client is booted (see importFromMnemonic).
      // inboxId + DB key are established at first activation, not here.
      final colors = [Colors.blue, Colors.purple, Colors.green, Colors.orange, Colors.red, Colors.teal];
      final selectedColor = colors[Random().nextInt(colors.length)];

      final metadata = {
        'label': label,
        'address': address,
        'inboxId': null, // stamped at first activation
        // No mnemonic for private key import
        'timestamp': DateTime.now().toIso8601String(),
        'createdBy': userAddress,
        'relatedOsuxAccount': userAddress,
        'color': selectedColor.value,
        'emoji': (emoji != null && emoji.isNotEmpty) ? emoji : '🔑',
        'walletEnabled': false,
        'isGroupKey': isGroupKey,
        'orgAddress': orgAddress?.eip55With0x,
      };

      // Save the key
      await saveKey(userAddress, label, cleanHex, metadata);

      Log.i(_tag, 'Key imported from private key hex successfully (passive — not activated)');

      return {
        'label': label,
        'privateKey': newPrivateKey,
        'privateKeyHex': cleanHex,
        'address': address,
        'inboxId': null,
        'metadata': metadata,
      };
    } catch (e) {
      Log.e(_tag, 'Error importing from private key: $e');
      throw Exception('Error importing from private key: $e');
    }
  }

  /// Wipe the local XMTP database for a wallet address and retry the import.
  /// Call this after catching [XmtpDbKeyMismatchException] when the user
  /// confirms they don't have the original DB key and accepts losing local messages.
  static Future<Map<String, dynamic>> retryImportAfterDbWipe(
    String userAddress,
    String walletAddress,
    String privateKeyHex,
    String label, {
    String? mnemonic,
    bool isGroupKey = false,
    EthereumAddress? orgAddress,
    String? emoji,
  }) async {
    Log.i(_tag, 'Wiping local XMTP DB for $walletAddress and retrying import');

    // 1. Look up the real inbox ID from the network (handles addAccount remapping)
    final inboxId = await XmtpPlugin.staticGetInboxIdForAddress(walletAddress);

    // 2. Delete the local database. Must target the same directory the client
    // opened the DB in — publicos_client points xmtpDbDirectory at the iOS App
    // Group container, and deleting from Documents instead is a silent no-op
    // that leaves the wrong-key DB in place and re-triggers the mismatch.
    if (inboxId != null) {
      await XmtpPlugin.staticDeleteLocalDatabase(walletAddress, inboxId,
          dbDirectory: PublicOS.xmtpDbDirectory);
    }

    // 3. Clear the stored DB key so a fresh one is generated
    final xmtpDbKeyKey = _getXmtpDbKeyStorageKey(userAddress, walletAddress);
    await PublicOS.secureStorage.delete(key: xmtpDbKeyKey);

    // 4. Retry the import (will generate a fresh DB key + fresh local DB)
    if (mnemonic != null) {
      return importFromMnemonic(userAddress, mnemonic, label,
          isGroupKey: isGroupKey, orgAddress: orgAddress, emoji: emoji);
    } else {
      return importFromPrivateKey(userAddress, privateKeyHex, label,
          isGroupKey: isGroupKey, orgAddress: orgAddress, emoji: emoji);
    }
  }

  /// Recover from the XMTP 10-installation cap for a key being imported:
  /// fetch the inbox's installations from the network and revoke them ALL,
  /// signed by the imported key (the recovery address — already in hand
  /// during import). After this, retry the import; the fresh registration
  /// becomes the inbox's only installation.
  ///
  /// Uses the plugin's true static path — no active client needed and no
  /// throwaway inbox created. If a platform ever loses static parity, the
  /// fallback is the ephemeral-client bootstrap.
  ///
  /// No fallbacks in the flow itself: any failure throws with the native
  /// message. Returns the number of installations revoked.
  static Future<int> revokeAllInstallationsForCap(
      Uint8List importedPrivateKey, String walletAddress) async {
    Log.i(_tag, 'Cap recovery: revoking ALL installations for $walletAddress');
    final inboxId = await XmtpPlugin.staticGetInboxIdForAddress(walletAddress);
    if (inboxId == null) {
      throw Exception('Key $walletAddress has no XMTP inbox on the network');
    }
    final states = await XmtpPlugin.staticInboxStatesForInboxIds([inboxId]);
    if (states.isEmpty) {
      throw Exception('No inbox state on the network for inbox $inboxId');
    }
    final state = states.first;
    // GUARD: the imported key must be the inbox's recovery address — a
    // non-recovery signer would be rejected by the network anyway, but fail
    // here with a message that names both addresses.
    final recovery = ((state['recoveryIdentity'] as Map?)?['identifier']
            as String?)
        ?.toLowerCase();
    if (recovery != null && recovery != walletAddress.toLowerCase()) {
      throw Exception(
          'Key $walletAddress is not the recovery address ($recovery) of inbox $inboxId');
    }
    final installations = (state['installations'] as List?) ?? const [];
    final ids = installations
        .map((i) => (i as Map)['id'] as String)
        .toList(growable: false);
    if (ids.isEmpty) {
      Log.w(_tag, 'Cap recovery: inbox $inboxId has no installations to revoke');
      return 0;
    }
    await XmtpPlugin.staticRevokeInstallations(
      signerPrivateKey: importedPrivateKey,
      inboxId: inboxId,
      installationIds: ids,
    );
    Log.i(_tag,
        'Cap recovery: revoked ${ids.length} installations of inbox $inboxId');
    return ids.length;
  }

  /// Delete the on-disk libxmtp MLS database (`.db3` + `-wal`/`-shm`) for a
  /// single wallet address, without re-importing. Used by the factory-reset
  /// flow ([SelectAccountScreen._resetApp]) to clear stale group state so a
  /// reset device can't re-materialize a dead conversation topic.
  ///
  /// Best-effort and non-throwing: a failed inbox lookup (e.g. offline) skips
  /// the delete on iOS/Android — which need the inbox id to build the DB path —
  /// rather than aborting the whole reset. Mirrors the delete half of
  /// [retryImportAfterDbWipe]; targets [PublicOS.xmtpDbDirectory] so the iOS
  /// App Group container is hit (deleting from Documents is a silent no-op).
  static Future<void> deleteLocalXmtpDatabase(String walletAddress) async {
    try {
      final inboxId = await XmtpPlugin.staticGetInboxIdForAddress(walletAddress);
      if (inboxId != null) {
        await XmtpPlugin.staticDeleteLocalDatabase(walletAddress, inboxId,
            dbDirectory: PublicOS.xmtpDbDirectory);
        Log.i(_tag, 'Deleted local XMTP DB for $walletAddress');
      } else {
        Log.w(_tag,
            'No inbox id for $walletAddress; skipping local XMTP DB delete');
      }
    } catch (e) {
      // Non-fatal: orphan .db3 files are unusable once the DB key is wiped.
      Log.e(_tag, 'Error deleting local XMTP DB for $walletAddress: $e');
    }
  }

  /// Export private key as hex string
  static Future<String?> exportPrivateKey(String userAddress, String label) async {
    try {
      final keyKey = _getKeyStorageKey(userAddress, label);
      final String? keyString = await PublicOS.secureStorage.read(key: keyKey);

      if (keyString == null || keyString.isEmpty) {
        return null;
      }

      // Decode the private key to hex string with 0x prefix
      final privateKeyBytes = base64Decode(keyString);
      final privateKeyHex = utf8.decode(privateKeyBytes);

      // Ensure it has 0x prefix
      final privateKeyWithPrefix = privateKeyHex.startsWith('0x') ? privateKeyHex : '0x$privateKeyHex';

      return privateKeyWithPrefix;
    } catch (e) {
      Log.e(_tag, 'Error exporting private key: $e');
      return null;
    }
  }

  /// Export mnemonic phrase if available
  static Future<String?> exportMnemonic(String userAddress, String label) async {
    try {
      final metadataKey = _getMetadataStorageKey(userAddress, label);
      final String? metadataString = await PublicOS.secureStorage.read(key: metadataKey);

      if (metadataString == null || metadataString.isEmpty) {
        return null;
      }

      final Map<String, dynamic> metadata = jsonDecode(metadataString);
      return metadata['mnemonic'] as String?;
    } catch (e) {
      Log.e(_tag, 'Error exporting mnemonic: $e');
      return null;
    }
  }

  ///*********************************************
  /// KEY SELECTION & ACTIVE STATE (XMTP-specific)
  ///*********************************************

  /// Get the currently selected key for XMTP
  static Future<String?> getXmtpSelectedKey(String userAddress) async {
    final selectedKeyKey = _getXmtpSelectedKeyStorageKey(userAddress);
    return await PublicOS.secureStorage.read(key: selectedKeyKey);
  }

  ///*********************************************
  /// WEB/SIGNING KEY SELECTION
  ///*********************************************

  /// Storage key for web selected key
  static String _getWebSelectedKeyStorageKey(String userAddress) {
    return 'web_selected_key_$userAddress';
  }

  /// Get the currently selected key for web/signing
  /// Returns null if session key should be used (default)
  /// Returns 'session' if session key is explicitly selected
  /// Returns key label if a keychain key is selected
  static Future<String?> getWebSelectedKey(String userAddress) async {
    final storageKey = _getWebSelectedKeyStorageKey(userAddress);
    return await PublicOS.secureStorage.read(key: storageKey);
  }

  /// Set the currently selected key for web/signing
  /// Use 'session' to explicitly select the session key
  /// Use a key label to select a keychain key
  static Future<void> setWebSelectedKey(String userAddress, String label) async {
    final storageKey = _getWebSelectedKeyStorageKey(userAddress);
    await PublicOS.secureStorage.write(key: storageKey, value: label);
    PublicOS.webSelectedKey = label;
    Log.i(_tag, 'Web key set to "$label"');
  }

  /// Clear the web selected key (reverts to session key)
  static Future<void> clearWebSelectedKey(String userAddress) async {
    final storageKey = _getWebSelectedKeyStorageKey(userAddress);
    await PublicOS.secureStorage.delete(key: storageKey);
    PublicOS.webSelectedKey = null;
    Log.i(_tag, 'Web key cleared (using session key)');
  }

  /// Load web selected key into PublicOS on app startup
  static Future<void> loadWebSelectedKey(String userAddress) async {
    final selectedKey = await getWebSelectedKey(userAddress);
    PublicOS.webSelectedKey = selectedKey;
    Log.d(_tag, 'Loaded web selected key: ${selectedKey ?? "session (default)"}');
  }

  /// The private key for the PREFERRED web key, or null.
  ///
  /// `null` / `'session'` still means the session key -- that is the pointer's
  /// own spelling for it, not a fallback.
  ///
  /// **A MISS RETURNS NULL.** The session key is NOT substituted when the
  /// label names a key that no longer exists. The pointer is only a
  /// *preference*, not an authority that decides who you are, and
  /// a miss that quietly signs as a different identity is a correctness bug:
  /// the caller asked for a specific key and got someone else's signature, one
  /// that does not recover to the address anybody was shown.
  static Future<EthPrivateKey?> getWebSigningKey(String userAddress) async {
    final selectedKey = PublicOS.webSelectedKey;

    if (selectedKey == null || selectedKey == 'session') {
      return PublicOS.currentBlockchainPrivateKey;
    }

    final privateKeyHex = await exportPrivateKey(userAddress, selectedKey);
    if (privateKeyHex == null) {
      Log.w(_tag, 'Preferred web key "$selectedKey" not found - returning null');
      return null;
    }

    return EthPrivateKey.fromHex(privateKeyHex);
  }

  /// The address of the PREFERRED web key, or null.
  ///
  /// Same rule as [getWebSigningKey]: a miss is null, never the session
  /// address. It also no longer invents `0x000...0` when there is no session
  /// address -- a zero address is a real, spendable-looking value that would
  /// flow into a grant row and an `eth_accounts` answer.
  static Future<String?> getWebSelectedAddress(String userAddress) async {
    final selectedKey = PublicOS.webSelectedKey;

    if (selectedKey == null || selectedKey == 'session') {
      return PublicOS.sessionBlockchainAddress;
    }

    final privateKeyHex = await exportPrivateKey(userAddress, selectedKey);
    if (privateKeyHex == null) {
      Log.w(_tag, 'Preferred web key "$selectedKey" not found - returning null');
      return null;
    }

    try {
      final privateKey = EthPrivateKey.fromHex(privateKeyHex);
      return privateKey.address.eip55With0x;
    } catch (e) {
      Log.e(_tag, 'Error deriving address from web key: $e');
      return null;
    }
  }

  /// Set the currently selected key for XMTP
  static Future<void> setXmtpSelectedKey(String userAddress, String label) async {
    final selectedKeyKey = _getXmtpSelectedKeyStorageKey(userAddress);
    final lastKeyKey = _getXmtpLastKeyStorageKey(userAddress);

    await PublicOS.secureStorage.write(key: selectedKeyKey, value: label);
    await PublicOS.secureStorage.write(key: lastKeyKey, value: label);
  }

  /// Clear the currently selected key for XMTP
  static Future<void> clearXmtpSelectedKey(String userAddress) async {
    final selectedKeyKey = _getXmtpSelectedKeyStorageKey(userAddress);
    final lastKeyKey = _getXmtpLastKeyStorageKey(userAddress);

    await PublicOS.secureStorage.delete(key: selectedKeyKey);
    await PublicOS.secureStorage.delete(key: lastKeyKey);
  }

  /// Short, non-secret fingerprint of a 32-byte DB key (first + last 3 bytes)
  /// for comparing "is this the same key" across download and restore in logs.
  /// Not the key — you cannot reconstruct the key from this.
  static String _keyFingerprint(Uint8List key) {
    String hex(List<int> b) =>
        b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    if (key.length < 6) return 'len${key.length}';
    return '${hex(key.sublist(0, 3))}..${hex(key.sublist(key.length - 3))}';
  }

  /// Read the stored XMTP inbox id for a key label (stamped at first
  /// activation). Null when the key was never activated on this device.
  static Future<String?> _storedInboxId(String userAddress, String label) async {
    final metadataKey = _getMetadataStorageKey(userAddress, label);
    final metadataString = await PublicOS.secureStorage.read(key: metadataKey);
    if (metadataString == null || metadataString.isEmpty) return null;
    try {
      final inboxId = (jsonDecode(metadataString) as Map)['inboxId'];
      return (inboxId is String && inboxId.isNotEmpty) ? inboxId : null;
    } catch (_) {
      return null;
    }
  }

  /// Re-read every key's inbox from the XMTP network and re-stamp the ones
  /// that moved. A key's inbox changes when it is added to another inbox
  /// (addAccount with reassign, e.g. scanned from this key's QR on another
  /// phone); the stamp written at first activation would otherwise keep
  /// naming the old inbox. Only keys already activated here (stamped) and
  /// actually on the network are touched: on Android/iOS the lookup
  /// COMPUTES an id for an unregistered address, so it is never trusted
  /// alone. Needs a loaded client; returns the labels whose inbox changed
  /// (empty when nothing moved or no client is loaded).
  static Future<List<String>> refreshInboxStamps(String userAddress) async {
    final client = PublicOS.xmtpClient;
    if (client == null) return const [];
    final changed = <String>[];
    for (final label in await getKeyIndex(userAddress)) {
      try {
        final stamped = await _storedInboxId(userAddress, label);
        if (stamped == null || !RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(stamped)) {
          continue;
        }
        final privateKeyHex = await exportPrivateKey(userAddress, label);
        if (privateKeyHex == null) continue;
        final address = EthPrivateKey.fromHex(privateKeyHex).address.eip55With0x;
        if (!await client.canMessageByAddress(address)) continue;
        final live = (await client.inboxIdFromAddress(address))?.toLowerCase();
        if (live == null || live.isEmpty || live == stamped.toLowerCase()) {
          continue;
        }
        await _mergeMetadata(userAddress, label, {'inboxId': live});
        changed.add(label);
        Log.i(_tag, 'Key "$label" moved inbox: re-stamped');
      } catch (e) {
        Log.e(_tag, 'refreshInboxStamps("$label"): $e');
      }
    }
    return changed;
  }

  /// Merge fields into a key's stored metadata (e.g. stamp the real inboxId
  /// once the client has been created for the first time).
  static Future<void> _mergeMetadata(
      String userAddress, String label, Map<String, dynamic> patch) async {
    final metadataKey = _getMetadataStorageKey(userAddress, label);
    final metadataString = await PublicOS.secureStorage.read(key: metadataKey);
    final Map<String, dynamic> metadata =
        (metadataString != null && metadataString.isNotEmpty)
            ? Map<String, dynamic>.from(jsonDecode(metadataString))
            : {};
    metadata.addAll(patch);
    await PublicOS.secureStorage.write(
        key: metadataKey, value: jsonEncode(metadata));
  }

  /// Whether a key is set up for XMTP messaging on THIS device.
  ///
  /// The authoritative signal is the stored DB encryption key: it is written
  /// only when a setup completes here ([setupFreshXmtp] / [restoreXmtpBackup]),
  /// and a passive import never writes one. When the key is present we also
  /// verify the database FILE exists (a secondary integrity check — catches
  /// cleared app data); on Android/iOS that check needs the inboxId, so when
  /// the inboxId isn't known yet the DB-key presence is trusted.
  static Future<XmtpSetupStatus> xmtpSetupStatusFor(
      String userAddress, String label) async {
    final privateKeyHex = await exportPrivateKey(userAddress, label);
    if (privateKeyHex == null) return XmtpSetupStatus.missing;
    final walletAddress = EthPrivateKey.fromHex(privateKeyHex).address.eip55With0x;

    final xmtpDbKeyKey = _getXmtpDbKeyStorageKey(userAddress, walletAddress);
    final base64DbKey = await PublicOS.secureStorage.read(key: xmtpDbKeyKey);
    if (base64DbKey == null || base64DbKey.isEmpty) {
      return XmtpSetupStatus.missing;
    }

    // DB key present → setup happened here. Verify the file when we can.
    final inboxId = await _storedInboxId(userAddress, label);
    try {
      final exists = await XmtpPlugin.staticLocalDatabaseExists(
        walletAddress,
        inboxId: inboxId,
        dbDirectory: PublicOS.xmtpDbDirectory,
      );
      if (exists) return XmtpSetupStatus.ready;
      // Android/iOS with no known inboxId cannot check — trust the DB key.
      if (inboxId == null) return XmtpSetupStatus.ready;
      return XmtpSetupStatus.broken;
    } catch (e) {
      Log.e(_tag, 'DB-exists check failed for $walletAddress: $e — trusting stored key');
      return XmtpSetupStatus.ready;
    }
  }

  /// Load an ALREADY-SET-UP key into the XMTP client. Throws
  /// [XmtpNotSetUpException] if the key has no local database on this device —
  /// activation never creates a database implicitly. The client orchestrates
  /// the not-set-up case ([setupFreshXmtp] / [restoreXmtpBackup]).
  static Future<void> selectKey(String userAddress, String label) async {
    try {
      Log.d(_tag, 'Selecting key "$label" for XMTP');

      final privateKeyHex = await exportPrivateKey(userAddress, label);
      if (privateKeyHex == null) {
        throw Exception('Private key not found for label: $label');
      }

      final privateKey = EthPrivateKey.fromHex(privateKeyHex);
      final walletAddress = privateKey.address.eip55With0x;

      // GATE: never create a DB implicitly. The key must already be set up
      // here — otherwise the caller decides create-fresh vs restore-backup.
      final status = await xmtpSetupStatusFor(userAddress, label);
      if (status != XmtpSetupStatus.ready) {
        throw XmtpNotSetUpException(walletAddress: walletAddress, status: status);
      }

      final xmtpDbKeyKey = _getXmtpDbKeyStorageKey(userAddress, walletAddress);
      final base64DbKey = await PublicOS.secureStorage.read(key: xmtpDbKeyKey);
      final dbKey = base64Decode(base64DbKey!);

      // Restart XMTP client with the selected key + its stored DB key (opens
      // the existing database — no new installation is registered).
      await PublicOS.reinitializeXmtpClientWithKeys(privateKey, label, existingDbKey: dbKey);

      // Stamp the real inboxId whenever it differs from the stored one, not
      // only the first time: a key added to ANOTHER inbox (addAccount with
      // reassign, e.g. the QR key handoff) now resolves to that inbox, and a
      // stale stamp makes [xmtpSetupStatusFor] check the old inbox's
      // database on the next activation.
      final live = PublicOS.clientXmtpInboxId;
      if (live != null && await _storedInboxId(userAddress, label) != live) {
        await _mergeMetadata(userAddress, label, {'inboxId': live});
      }

      await setXmtpSelectedKey(userAddress, label);
      Log.i(_tag, 'Key "$label" selected and XMTP client reinitialized successfully');
    } on XmtpNotSetUpException {
      rethrow;
    } catch (e) {
      Log.e(_tag, 'Error selecting key: $e');
      throw Exception('Error selecting key: $e');
    }
  }

  /// Set up messaging for a key by creating a FRESH local database and
  /// registering a new installation on the network. This is the ONLY path in
  /// the app that registers an installation (consuming one of the inbox's 10
  /// slots). Generates + persists the DB encryption key, stamps the real
  /// inboxId, and selects the key.
  ///
  /// Surfaces [XmtpInstallationCapException] when the inbox is at 10/10 — the
  /// client offers the revoke-all recovery ([revokeAllInstallationsForCap]).
  /// Does this key ALREADY have an XMTP inbox on the network?
  ///
  /// Answers without loading a client and without registering anything: the
  /// plugin's [XmtpPlugin.staticCanMessage] asks from a throwaway
  /// unregistered client (no signature, no installation spent).
  ///
  /// Exists so the activation gate only offers "restore a backup" when there
  /// IS an inbox to restore — a key generated seconds ago has nothing to
  /// restore, and asking reads as a trick question.
  ///
  /// Returns **null when the question could not be answered** (offline, or a
  /// platform without the probe — web throws). Callers must treat null as
  /// *unknown* and keep asking the user; never as "no inbox".
  ///
  /// ⚠ Do NOT use [XmtpPlugin.staticGetInboxIdForAddress] for this: on
  /// Android/iOS it COMPUTES an inbox id when the network has none, so it
  /// never answers "not registered" there (it does on Windows).
  static Future<bool?> isKeyOnXmtpNetwork(
      String userAddress, String label) async {
    try {
      final privateKeyHex = await exportPrivateKey(userAddress, label);
      if (privateKeyHex == null) {
        Log.w(_tag, 'isKeyOnXmtpNetwork: no private key for "$label"');
        return null;
      }
      final walletAddress = EthPrivateKey.fromHex(privateKeyHex).address.eip55With0x;
      // Bounded: this sits in front of a tap (the keychain SIM), so a dead
      // network must fall through to "unknown" quickly rather than hang.
      final answer = await XmtpPlugin.staticCanMessage([walletAddress])
          .timeout(const Duration(seconds: 8));
      final registered = answer[walletAddress];
      Log.i(_tag,
          'isKeyOnXmtpNetwork "$label" ($walletAddress) -> ${registered ?? "unknown"}');
      return registered;
    } catch (e) {
      // Unknown, NOT false: an offline user must still be offered the restore
      // path for a key whose backup they hold.
      Log.w(_tag, 'isKeyOnXmtpNetwork failed for "$label": $e');
      return null;
    }
  }

  static Future<void> setupFreshXmtp(String userAddress, String label) async {
    Log.i(_tag, '[SETUP-FRESH] start label="$label"');
    final privateKeyHex = await exportPrivateKey(userAddress, label);
    if (privateKeyHex == null) {
      throw Exception('Private key not found for label: $label');
    }
    final privateKey = EthPrivateKey.fromHex(privateKeyHex);
    final walletAddress = privateKey.address.eip55With0x;
    Log.d(_tag, '[SETUP-FRESH] wallet=$walletAddress');

    // Generate + persist the DB key BEFORE init (a failed init must not leave
    // a DB encrypted with a discarded key).
    final xmtpDbKeyKey = _getXmtpDbKeyStorageKey(userAddress, walletAddress);
    final dbKey = Uint8List.fromList(
        List<int>.generate(32, (i) => Random.secure().nextInt(256)));
    await PublicOS.secureStorage.write(
        key: xmtpDbKeyKey, value: base64Encode(dbKey));

    try {
      Log.d(_tag, '[SETUP-FRESH] initializing client (registers a new installation)…');
      await PublicOS.reinitializeXmtpClientWithKeys(privateKey, label, existingDbKey: dbKey);
      Log.d(_tag, '[SETUP-FRESH] client ready, inbox=${PublicOS.clientXmtpInboxId}');
    } catch (initError) {
      Log.e(_tag, '[SETUP-FRESH] client init FAILED: $initError');
      // On failure, drop the DB key we just wrote so a retry starts clean.
      await PublicOS.secureStorage.delete(key: xmtpDbKeyKey);
      _throwMappedInitError(initError, walletAddress);
    }

    await _mergeMetadata(userAddress, label, {'inboxId': PublicOS.clientXmtpInboxId});
    await setXmtpSelectedKey(userAddress, label);
    Log.i(_tag, '[SETUP-FRESH] DONE for "$label" — inbox ${PublicOS.clientXmtpInboxId}');
  }

  /// Set up messaging for a key by RESTORING a raw database backup: places the
  /// backup `.db3` at the platform-conventional path and opens it with the
  /// given [base64Key]. The network sees the SAME installation the backup was
  /// taken from — no new installation is registered, no inbox slot is spent
  /// (unlike an SDK archive import). Stamps the inboxId and selects the key.
  ///
  /// [sourcePath] is the picked backup file. On a wrong key the placed file is
  /// removed and a typed [XmtpDbKeyMismatchException] is thrown.
  static Future<void> restoreXmtpBackup(
    String userAddress,
    String label,
    String sourcePath,
    String base64Key,
  ) async {
    Log.i(_tag, '[RESTORE] start label="$label" sourcePath="$sourcePath" keyLen=${base64Key.trim().length}');
    final privateKeyHex = await exportPrivateKey(userAddress, label);
    if (privateKeyHex == null) {
      throw Exception('Private key not found for label: $label');
    }
    final privateKey = EthPrivateKey.fromHex(privateKeyHex);
    final walletAddress = privateKey.address.eip55With0x;
    Log.d(_tag, '[RESTORE] wallet=$walletAddress dbDirectory=${PublicOS.xmtpDbDirectory}');

    final trimmedKey = base64Key.trim();
    final Uint8List dbKey;
    try {
      dbKey = base64Decode(trimmedKey);
    } catch (e) {
      Log.e(_tag, '[RESTORE] key is not valid base64: $e');
      throw Exception('The encryption key is not valid base64');
    }
    if (dbKey.length != 32) {
      Log.e(_tag, '[RESTORE] key wrong length: ${dbKey.length} bytes (need 32)');
      throw Exception('The encryption key must be 32 bytes (got ${dbKey.length})');
    }
    Log.d(_tag, '[RESTORE] key fingerprint=${_keyFingerprint(dbKey)} (compare to the [DOWNLOAD]/[COPY-KEY] fingerprint of the source device)');

    // Resolve the inbox id needed to place the file on Android/iOS (Windows
    // keys on the address and ignores it). Prefer the stored id; if unknown
    // (key never activated here), fall back to the network — SAFE here because
    // a key with a backup is a REGISTERED inbox, so the lookup returns the real
    // id, not a fabricated one. Last resort: let the plugin parse the filename.
    String? placeInboxId = await _storedInboxId(userAddress, label);
    Log.d(_tag, '[RESTORE] storedInboxId=$placeInboxId');
    if (placeInboxId == null) {
      try {
        placeInboxId =
            await XmtpPlugin.staticGetInboxIdForAddress(walletAddress);
        Log.d(_tag, '[RESTORE] network inboxId for $walletAddress = $placeInboxId');
      } catch (e) {
        Log.w(_tag, '[RESTORE] network inbox lookup failed ($e) — will rely on the filename');
      }
    }

    // Place the backup file at the conventional local path (refuses to
    // overwrite an existing DB — the caller wipes first if replacing).
    Log.d(_tag, '[RESTORE] placing DB via staticImportLocalDatabase (inboxId=$placeInboxId)');
    try {
      await XmtpPlugin.staticImportLocalDatabase(
        sourcePath,
        walletAddress,
        inboxId: placeInboxId,
        dbDirectory: PublicOS.xmtpDbDirectory,
      );
      Log.d(_tag, '[RESTORE] DB file placed OK');
    } catch (e) {
      Log.e(_tag, '[RESTORE] staticImportLocalDatabase FAILED: $e');
      rethrow;
    }

    // Persist the key + open the restored DB.
    final xmtpDbKeyKey = _getXmtpDbKeyStorageKey(userAddress, walletAddress);
    await PublicOS.secureStorage.write(key: xmtpDbKeyKey, value: trimmedKey);
    Log.d(_tag, '[RESTORE] key stored, opening client…');
    try {
      await PublicOS.reinitializeXmtpClientWithKeys(privateKey, label, existingDbKey: dbKey);
      Log.d(_tag, '[RESTORE] client opened, inbox=${PublicOS.clientXmtpInboxId}');
    } catch (initError) {
      Log.e(_tag, '[RESTORE] client init FAILED on restored DB: $initError');
      // Wrong key or a corrupt/foreign backup — undo so the user can retry.
      await PublicOS.secureStorage.delete(key: xmtpDbKeyKey);
      try {
        await XmtpPlugin.staticDeleteLocalDatabase(walletAddress, placeInboxId ?? '',
            dbDirectory: PublicOS.xmtpDbDirectory);
      } catch (_) {}
      final s = initError.toString().toLowerCase();
      if (s.contains('hmac') || s.contains('pragma key') || s.contains('not a database') ||
          s.contains('malformed') || s.contains('notadb') || s.contains('sql logic error')) {
        throw XmtpDbKeyMismatchException(
            walletAddress: walletAddress,
            message: 'The encryption key does not match this backup file.');
      }
      rethrow;
    }

    await _mergeMetadata(userAddress, label, {'inboxId': PublicOS.clientXmtpInboxId});
    await setXmtpSelectedKey(userAddress, label);
    Log.i(_tag, '[RESTORE] DONE for "$label" — inbox ${PublicOS.clientXmtpInboxId}');
  }

  /// Download the currently-active key's local database file to [destPath] for
  /// a raw-DB backup. Closes the client to release the file, copies it, then
  /// re-opens the client so messaging continues. The exported file plus the
  /// key's DB encryption key ([exportXmtpDbKeyForLabel]) restore the SAME
  /// installation on another device.
  static Future<void> downloadXmtpDatabase(
      String userAddress, String label, String destPath) async {
    Log.i(_tag, '[DOWNLOAD] start label="$label" destPath="$destPath"');
    final privateKeyHex = await exportPrivateKey(userAddress, label);
    if (privateKeyHex == null) {
      throw Exception('Private key not found for label: $label');
    }
    final privateKey = EthPrivateKey.fromHex(privateKeyHex);
    final walletAddress = privateKey.address.eip55With0x;
    // The live client's inbox id is authoritative for locating the file on
    // Android/iOS; fall back to the stamped metadata.
    final inboxId = (PublicOS.currentXmtpKeyLabel == label
            ? PublicOS.clientXmtpInboxId
            : null) ??
        await _storedInboxId(userAddress, label);
    Log.d(_tag, '[DOWNLOAD] wallet=$walletAddress inboxId=$inboxId');

    final xmtpDbKeyKey = _getXmtpDbKeyStorageKey(userAddress, walletAddress);
    final base64DbKey = await PublicOS.secureStorage.read(key: xmtpDbKeyKey);
    if (base64DbKey == null || base64DbKey.isEmpty) {
      Log.e(_tag, '[DOWNLOAD] no stored DB key — key not set up on this device');
      throw Exception('No database to download — this key is not set up on this device');
    }
    final dbKey = base64Decode(base64DbKey);
    Log.d(_tag, '[DOWNLOAD] key fingerprint=${_keyFingerprint(dbKey)} — this is the key that unlocks the exported file');

    final wasActive = PublicOS.currentXmtpKeyLabel == label;
    // Close the client so the sqlite file is safe to copy.
    Log.d(_tag, '[DOWNLOAD] closing client (wasActive=$wasActive)…');
    await PublicOS.xmtpClient?.closeClient();
    try {
      Log.d(_tag, '[DOWNLOAD] exporting DB via staticExportLocalDatabase…');
      await XmtpPlugin.staticExportLocalDatabase(
        destPath,
        walletAddress,
        inboxId: inboxId,
        dbDirectory: PublicOS.xmtpDbDirectory,
      );
      Log.d(_tag, '[DOWNLOAD] export OK');
    } catch (e) {
      Log.e(_tag, '[DOWNLOAD] staticExportLocalDatabase FAILED: $e');
      rethrow;
    } finally {
      // Re-open the client so messaging keeps working after the download.
      if (wasActive) {
        Log.d(_tag, '[DOWNLOAD] re-opening client…');
        await PublicOS.reinitializeXmtpClientWithKeys(privateKey, label, existingDbKey: dbKey);
      }
    }
    Log.i(_tag, '[DOWNLOAD] DONE → $destPath');
  }

  /// Export the stored DB encryption key for a specific label as base64 (the
  /// companion secret to [downloadXmtpDatabase]). Null when not set up here.
  static Future<String?> exportXmtpDbKeyForLabel(
      String userAddress, String label) async {
    final privateKeyHex = await exportPrivateKey(userAddress, label);
    if (privateKeyHex == null) return null;
    final walletAddress = EthPrivateKey.fromHex(privateKeyHex).address.eip55With0x;
    final xmtpDbKeyKey = _getXmtpDbKeyStorageKey(userAddress, walletAddress);
    final base64DbKey = await PublicOS.secureStorage.read(key: xmtpDbKeyKey);
    if (base64DbKey == null || base64DbKey.isEmpty) return null;
    try {
      Log.d(_tag, '[COPY-KEY] key fingerprint=${_keyFingerprint(base64Decode(base64DbKey))} for "$label"');
    } catch (_) {}
    return base64DbKey;
  }

  ///*********************************************
  /// XMTP DB KEY IMPORT/EXPORT
  ///*********************************************

  /// Import an XMTP database key for the current identity.
  /// The key should be base64 encoded (same format as exported).
  /// Returns true if successful, throws an exception on error.
  static Future<bool> importXmtpDbKey(String base64Key) async {
    try {
      // Validate we have a current user
      final userAddress = PublicOS.myPublicosAddress;
      if (userAddress == null) {
        throw Exception('No current user address available');
      }

      // Get the wallet address from the current XMTP private key
      final currentPk = PublicOS.currentXMTPPrivateKey;
      if (currentPk == null) {
        throw Exception('No XMTP identity selected');
      }
      final walletAddress = currentPk.address.eip55With0x;

      // Validate and decode the base64 key
      final String trimmedKey = base64Key.trim();
      if (trimmedKey.isEmpty) {
        throw Exception('Database key cannot be empty');
      }

      Uint8List decodedKey;
      try {
        decodedKey = base64Decode(trimmedKey);
      } catch (e) {
        throw Exception('Invalid base64 format');
      }

      // Validate key length (should be 32 bytes)
      if (decodedKey.length != 32) {
        throw Exception('Invalid key length: expected 32 bytes, got ${decodedKey.length}');
      }

      // Store the key in secure storage (indexed by wallet address)
      final dbKeyStorageKey = _getXmtpDbKeyStorageKey(userAddress, walletAddress);
      await PublicOS.secureStorage.write(key: dbKeyStorageKey, value: trimmedKey);

      // Update in-memory key
      PublicOS.currentXmtpDbKey = decodedKey;

      Log.i(_tag, 'Successfully imported XMTP DB key for wallet $walletAddress');
      return true;
    } catch (e) {
      Log.e(_tag, 'Error importing XMTP DB key: $e');
      rethrow;
    }
  }

  /// Export the current XMTP database key as base64.
  /// Returns null if no key is available.
  static String? exportXmtpDbKey() {
    final dbKey = PublicOS.currentXmtpDbKey;
    if (dbKey == null) return null;
    return base64Encode(dbKey);
  }

  ///*********************************************
  /// WALLET INTEGRATION
  ///*********************************************

  /// Toggle wallet enabled state for a key
  static Future<void> setWalletEnabled(String userAddress, String label, bool enabled) async {
    try {
      final metadataKey = _getMetadataStorageKey(userAddress, label);
      final String? metadataString = await PublicOS.secureStorage.read(key: metadataKey);

      if (metadataString == null) {
        throw Exception('Key metadata not found');
      }

      final Map<String, dynamic> metadata = jsonDecode(metadataString);
      metadata['walletEnabled'] = enabled;

      await PublicOS.secureStorage.write(key: metadataKey, value: jsonEncode(metadata));
      Log.i(_tag, 'Wallet ${enabled ? 'enabled' : 'disabled'} for key "$label"');
    } catch (e) {
      Log.e(_tag, 'Error setting wallet enabled: $e');
      throw Exception('Error setting wallet enabled: $e');
    }
  }

  /// Get wallet enabled state for a key
  static Future<bool> getWalletEnabled(String userAddress, String label) async {
    try {
      final metadataKey = _getMetadataStorageKey(userAddress, label);
      final String? metadataString = await PublicOS.secureStorage.read(key: metadataKey);

      if (metadataString == null) return false;

      final Map<String, dynamic> metadata = jsonDecode(metadataString);
      return metadata['walletEnabled'] ?? false;
    } catch (e) {
      Log.e(_tag, 'Error getting wallet enabled: $e');
      return false;
    }
  }

  /// Update emoji for a key
  static Future<void> setKeyEmoji(String userAddress, String label, String emoji) async {
    try {
      final metadataKey = _getMetadataStorageKey(userAddress, label);
      final String? metadataString = await PublicOS.secureStorage.read(key: metadataKey);

      if (metadataString == null) {
        throw Exception('Key metadata not found');
      }

      final Map<String, dynamic> metadata = jsonDecode(metadataString);
      metadata['emoji'] = emoji;

      await PublicOS.secureStorage.write(key: metadataKey, value: jsonEncode(metadata));
      Log.i(_tag, 'Emoji updated to "$emoji" for key "$label"');
    } catch (e) {
      Log.e(_tag, 'Error setting emoji: $e');
      throw Exception('Error setting emoji: $e');
    }
  }

  /// Get all keys with wallet enabled
  static Future<List<Map<String, dynamic>>> getKeysWithWalletEnabled(String userAddress) async {
    try {
      final allKeys = await fetchKeys(userAddress);
      return allKeys.where((key) => key['walletEnabled'] == true).toList();
    } catch (e) {
      Log.e(_tag, 'Error fetching wallet-enabled keys: $e');
      return [];
    }
  }

  ///*********************************************
  /// BLOCKCHAIN TEMPORARY KEY MANAGEMENT
  ///*********************************************

  /// Generate a temporary blockchain key (for login screen onboarding)
  /// Returns: {privateKey: EthPrivateKey, privateKeyHex: String, address: String, mnemonic: String, dbKey: Uint8List}
  static Future<Map<String, dynamic>> generateTemporaryBlockchainKey() async {
    try {
      Log.d(_tag, 'Generating temporary blockchain key...');

      // 1. Generate 12-word mnemonic
      final mnemonicList = generateMnemonic();
      final mnemonic = mnemonicList.join(' ');

      // 2. Derive private key from mnemonic
      final keyInfo = deriveKeyFromMnemonic(mnemonicList);
      final privateKey = keyInfo['privateKey'] as EthPrivateKey;
      final privateKeyHex = keyInfo['privateKeyHex'] as String;
      final address = keyInfo['address'] as String;

      // 3. Generate random DB encryption key
      final dbKey = Uint8List.fromList(List<int>.generate(32, (i) => Random.secure().nextInt(256)));

      // 4. Store temporary keys
      await PublicOS.secureStorage.write(
        key: 'account_temporaryAccount_private_key',
        value: base64Encode(utf8.encode(privateKeyHex)), // Store as hex string (new format)
      );

      await PublicOS.secureStorage.write(
        key: 'account_temporaryAccount_encryption_key',
        value: base64Encode(dbKey),
      );

      await PublicOS.secureStorage.write(
        key: 'account_temporaryAccount_mnemonic',
        value: mnemonic,
      );

      await PublicOS.secureStorage.write(
        key: 'temporaryAccountSessionAddress',
        value: address,
      );

      Log.i(_tag, 'Temporary blockchain key generated successfully');
      Log.d(_tag, 'Address: $address');

      return {
        'privateKey': privateKey,
        'privateKeyHex': privateKeyHex,
        'address': address,
        'mnemonic': mnemonic,
        'dbKey': dbKey,
      };
    } catch (e) {
      Log.e(_tag, 'Error generating temporary blockchain key: $e');
      throw Exception('Error generating temporary blockchain key: $e');
    }
  }

  /// Import temporary blockchain key from mnemonic
  static Future<Map<String, dynamic>> importTemporaryBlockchainKeyFromMnemonic(String mnemonic) async {
    try {
      Log.d(_tag, 'Importing temporary blockchain key from mnemonic...');

      // Parse and validate mnemonic
      final mnemonicList = mnemonic.split(' ').where((s) => s.isNotEmpty).toList();

      if (!validateMnemonic(mnemonicList)) {
        throw Exception('Invalid mnemonic phrase');
      }

      // Derive private key from mnemonic
      final keyInfo = deriveKeyFromMnemonic(mnemonicList);
      final privateKey = keyInfo['privateKey'] as EthPrivateKey;
      final privateKeyHex = keyInfo['privateKeyHex'] as String;
      final address = keyInfo['address'] as String;

      // Generate random DB encryption key
      final dbKey = Uint8List.fromList(List<int>.generate(32, (i) => Random.secure().nextInt(256)));

      // Store temporary keys
      await PublicOS.secureStorage.write(
        key: 'account_temporaryAccount_private_key',
        value: base64Encode(utf8.encode(privateKeyHex)), // Store as hex string (new format)
      );

      await PublicOS.secureStorage.write(
        key: 'account_temporaryAccount_encryption_key',
        value: base64Encode(dbKey),
      );

      await PublicOS.secureStorage.write(
        key: 'account_temporaryAccount_mnemonic',
        value: mnemonic,
      );

      await PublicOS.secureStorage.write(
        key: 'temporaryAccountSessionAddress',
        value: address,
      );

      Log.i(_tag, 'Temporary blockchain key imported from mnemonic successfully');
      Log.d(_tag, 'Address: $address');

      return {
        'privateKey': privateKey,
        'privateKeyHex': privateKeyHex,
        'address': address,
        'mnemonic': mnemonic,
        'dbKey': dbKey,
      };
    } catch (e) {
      Log.e(_tag, 'Error importing from mnemonic: $e');
      throw Exception('Error importing from mnemonic: $e');
    }
  }

  /// Import temporary blockchain key from private key hex
  static Future<Map<String, dynamic>> importTemporaryBlockchainKeyFromPrivateKey(String privateKeyHex) async {
    try {
      Log.d(_tag, 'Importing temporary blockchain key from private key hex...');

      // Parse private key hex (with or without 0x prefix)
      String cleanHex = privateKeyHex.trim();
      if (!cleanHex.startsWith('0x')) {
        cleanHex = '0x$cleanHex';
      }

      // Create private key from hex
      final privateKey = EthPrivateKey.fromHex(cleanHex);
      final address = privateKey.address.eip55With0x;

      // Generate random DB encryption key
      final dbKey = Uint8List.fromList(List<int>.generate(32, (i) => Random.secure().nextInt(256)));

      // Store temporary keys (no mnemonic for private key import)
      await PublicOS.secureStorage.write(
        key: 'account_temporaryAccount_private_key',
        value: base64Encode(utf8.encode(cleanHex)), // Store as hex string (new format)
      );

      await PublicOS.secureStorage.write(
        key: 'account_temporaryAccount_encryption_key',
        value: base64Encode(dbKey),
      );

      // No mnemonic for private key import
      await PublicOS.secureStorage.delete(key: 'account_temporaryAccount_mnemonic');

      await PublicOS.secureStorage.write(
        key: 'temporaryAccountSessionAddress',
        value: address,
      );

      Log.i(_tag, 'Temporary blockchain key imported from private key hex successfully');
      Log.d(_tag, 'Address: $address');

      return {
        'privateKey': privateKey,
        'privateKeyHex': cleanHex,
        'address': address,
        'dbKey': dbKey,
      };
    } catch (e) {
      Log.e(_tag, 'Error importing from private key: $e');
      throw Exception('Error importing from private key: $e');
    }
  }

  /// Get the mnemonic for temporary blockchain key (if available)
  static Future<String?> getTemporaryBlockchainKeyMnemonic() async {
    try {
      return await PublicOS.secureStorage.read(key: 'account_temporaryAccount_mnemonic');
    } catch (e) {
      Log.e(_tag, 'Error getting temporary mnemonic: $e');
      return null;
    }
  }

  /// Delete temporary blockchain key
  static Future<bool> deleteTemporaryBlockchainKey() async {
    try {
      Log.d(_tag, 'Deleting temporary blockchain key...');

      await PublicOS.secureStorage.delete(key: 'account_temporaryAccount_private_key');
      await PublicOS.secureStorage.delete(key: 'account_temporaryAccount_encryption_key');
      await PublicOS.secureStorage.delete(key: 'account_temporaryAccount_mnemonic');
      await PublicOS.secureStorage.delete(key: 'temporaryAccountSessionAddress');
      // Signed link-device claim is bound to this temp key — wipe it too.
      await PublicOS.secureStorage.delete(key: 'account_temporaryAccount_signed_claim');

      Log.i(_tag, 'Temporary blockchain key deleted successfully');
      return true;
    } catch (e) {
      Log.e(_tag, 'Error deleting temporary blockchain key: $e');
      return false;
    }
  }

  /// Load temporary blockchain key into PublicOS
  static Future<void> loadTemporaryBlockchainKey() async {
    try {
      Log.d(_tag, 'Loading temporary blockchain key into PublicOS...');

      final privateKeyStr = await PublicOS.secureStorage.read(key: 'account_temporaryAccount_private_key');
      final dbKeyStr = await PublicOS.secureStorage.read(key: 'account_temporaryAccount_encryption_key');
      final address = await PublicOS.secureStorage.read(key: 'temporaryAccountSessionAddress');

      if (privateKeyStr == null || dbKeyStr == null || address == null) {
        throw Exception('Temporary blockchain key not found');
      }

      // Decode private key (hex string format)
      final privateKeyHex = utf8.decode(base64Decode(privateKeyStr));
      final privateKey = EthPrivateKey.fromHex(privateKeyHex);

      // Decode DB key
      final dbKey = base64Decode(dbKeyStr);

      // Load into PublicOS
      PublicOS.currentBlockchainPrivateKey = privateKey;
      PublicOS.currentBlockchainDbKey = dbKey;
      PublicOS.sessionBlockchainAddress = address;

      Log.i(_tag, 'Temporary blockchain key loaded into PublicOS successfully');
      Log.d(_tag, 'Address: $address');
    } catch (e) {
      Log.e(_tag, 'Error loading temporary blockchain key: $e');
      throw Exception('Error loading temporary blockchain key: $e');
    }
  }
}
