// ignore_for_file: unused_import
import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:publicos_core/src/core/publicos_core.dart';
import 'package:publicos_core/src/core/extensions/publicos_bsp.dart';
import 'package:publicos_core/src/core/extensions/publicos_accounts.dart';
import 'package:publicos_core/src/contracts/AppRegistryManager.g.dart' as AppRegistryManagerContract;
import 'package:publicos_core/src/database/database.dart' as db;
import 'package:publicos_core/src/core/extensions/publicos_settings.dart';
import 'package:publicos_core/src/models/app_bookmark.dart';
import 'package:publicos_core/src/models/record_model.dart';
import 'package:publicos_core/src/utils/log.dart';
import 'package:publicos_core/src/utils/tx_utils.dart';
import 'package:web3dart/web3dart.dart';
import 'package:wallet/wallet.dart';

/// Extension on PublicOS to manage App Registry (bookmarks/apps).
extension PublicOSAppRegistry on PublicOS {
  static const _tag = 'AppRegistry';

  // ============================================
  // WRITE OPERATIONS (require authentication)
  // ============================================

  /// Registers a new app with a given name and display name.
  /// Waits for tx receipt so the app exists on-chain before returning.
  static Future<bool> registerApp(String appName, String displayName) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication and private key required to register app.');
      return false;
    }
    try {
      Log.d(_tag, 'Registering App: $appName, Display Name: $displayName');
      final txHash = await Future.any([
        PublicOSBsp.appRegistryManagerContract.registerApp(
          (slug: appName, title: displayName),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15)).then((_) => throw TimeoutException('Registering app timed out')),
      ]);
      Log.i(_tag, 'registerApp tx sent: $txHash — polling for receipt...');
      return await TxUtils.waitForReceipt(txHash, label: 'registerApp($appName)');
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error registering app: $e');
      return false;
    }
  }

  /// Removes an app by name.
  /// Waits for tx receipt confirmation.
  static Future<bool> removeApp(String appName) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication and private key required to remove app.');
      return false;
    }
    try {
      Log.d(_tag, 'Removing App: $appName');
      final txHash = await Future.any([
        PublicOSBsp.appRegistryManagerContract.removeApp(
          (slug: appName),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 10)).then((_) => throw TimeoutException('Removing app timed out')),
      ]);
      Log.i(_tag, 'removeApp tx sent: $txHash — polling for receipt...');
      return await TxUtils.waitForReceipt(txHash, label: 'removeApp($appName)');
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error removing app: $e');
      return false;
    }
  }

  /// Updates the display name for an existing app.
  /// Waits for tx receipt confirmation.
  static Future<bool> updateAppDisplayName(String appName, String newDisplayName) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication and private key required to update app display name.');
      return false;
    }
    try {
      Log.d(_tag, 'Updating App Display Name for: $appName to $newDisplayName');
      final txHash = await Future.any([
        PublicOSBsp.appRegistryManagerContract.updateAppTitle(
          (slug: appName, newTitle: newDisplayName),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 10)).then((_) => throw TimeoutException('Updating app display name timed out')),
      ]);
      Log.i(_tag, 'updateAppDisplayName tx sent: $txHash — polling for receipt...');
      return await TxUtils.waitForReceipt(txHash, label: 'updateAppDisplayName($appName)');
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error updating app display name: $e');
      return false;
    }
  }

  /// Sets a pointer (key-value pair) for an app.
  /// Waits for tx receipt so the pointer is on-chain before returning.
  static Future<bool> setAppPointer(String appName, String pointerType, String value) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication and private key required to set app pointer.');
      return false;
    }
    try {
      Log.d(_tag, 'Setting App Pointer for: $appName, Type: $pointerType, Value: $value');
      final txHash = await Future.any([
        PublicOSBsp.appRegistryManagerContract.setAppPointer(
          (slug: appName, pointerType: pointerType, value: value),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 15)).then((_) => throw TimeoutException('Setting app pointer timed out')),
      ]);
      Log.i(_tag, 'setAppPointer tx sent: $txHash — polling for receipt...');
      return await TxUtils.waitForReceipt(txHash, label: 'setAppPointer($appName.$pointerType)');
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error setting app pointer: $e');
      return false;
    }
  }

  /// Removes a pointer from an app.
  /// Waits for tx receipt confirmation.
  static Future<bool> removeAppPointer(String appName, String pointerType) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication and private key required to remove app pointer.');
      return false;
    }
    try {
      Log.d(_tag, 'Removing App Pointer for: $appName, Type: $pointerType');
      final txHash = await Future.any([
        PublicOSBsp.appRegistryManagerContract.removeAppPointer(
          (slug: appName, pointerType: pointerType),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        ),
        Future.delayed(const Duration(seconds: 10)).then((_) => throw TimeoutException('Removing app pointer timed out')),
      ]);
      Log.i(_tag, 'removeAppPointer tx sent: $txHash — polling for receipt...');
      return await TxUtils.waitForReceipt(txHash, label: 'removeAppPointer($appName.$pointerType)');
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error removing app pointer: $e');
      return false;
    }
  }

  // ============================================
  // READ OPERATIONS
  // ============================================

  /// Retrieves all app names for a given account address.
  static Future<List<String>?> getAccountApps(EthereumAddress accountAddress) async {
    try {
      Log.d(_tag, 'Getting all apps for Account: ${accountAddress.eip55With0x}');
      final appNames = await Future.any([
        PublicOSBsp.appRegistryManagerContract.getAppsByOwner(
          (owner: accountAddress),
        ),
        Future.delayed(const Duration(seconds: 5)).then((_) => throw TimeoutException('Get account apps timed out')),
      ]);
      Log.d(_tag, 'Retrieved ${appNames.length} apps for Account: ${accountAddress.eip55With0x}');
      return appNames;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error retrieving account apps: $e');
      return null;
    }
  }

  /// Retrieves an app by name for a given account address.
  static Future<AppBookmark?> getApp(EthereumAddress accountAddress, String appName) async {
    try {
      Log.d(_tag, 'Getting App: $appName for Account: ${accountAddress.eip55With0x}');
      final appData = await Future.any([
        PublicOSBsp.appRegistryManagerContract.getAppBySlug(
          (slug: appName),
        ),
        Future.delayed(const Duration(seconds: 5)).then((_) => throw TimeoutException('Get app timed out')),
      ]);

      // The tuple is (bool exists, string slug, string title, address owner).
      //
      // Index 1 is the SLUG, not the display name: reading it as the title
      // reports every app's slug as its title and drops `owner` entirely.
      // `refreshStaleBookmarks` below decodes the identical call the same
      // way. App cards need the real title for attribution and must never
      // read an owner the caller supplied.
      if (appData is List && appData.length >= 4) {
        final exists = appData[0] as bool;
        // appData[1] is the slug, which the caller already has.
        final displayName = appData[2] as String;
        final ownerAddressRaw = appData[3];

        if (!exists) {
          Log.d(_tag, 'App $appName does not exist for Account: ${accountAddress.eip55With0x}');
          return null;
        }

        // Get all pointers for this app
        final pointersData = await getAllAppPointers(accountAddress, appName);
        List<AppPointer> pointers = [];
        if (pointersData != null) {
          for (int i = 0; i < pointersData.pointerTypes.length; i++) {
            pointers.add(AppPointer(
              type: pointersData.pointerTypes[i],
              value: pointersData.values[i],
            ));
          }
        }

        // Owner comes from CHAIN, not from the caller's `accountAddress`
        // argument. The contract call is slug-only, so echoing the argument
        // back would make this field the caller's own guess — and anything
        // making a trust decision on it would be checking its own input.
        EthereumAddress ownerAddress;
        if (ownerAddressRaw is EthereumAddress) {
          ownerAddress = ownerAddressRaw;
        } else if (ownerAddressRaw is String) {
          ownerAddress = EthereumAddress.fromHex(ownerAddressRaw);
        } else {
          Log.w(_tag,
              'Unknown owner address type for "$appName": ${ownerAddressRaw.runtimeType}');
          return null;
        }

        final app = AppBookmark(
          appName: appName,
          displayName: displayName,
          ownerAccountAddress: ownerAddress,
          pointers: pointers,
        );

        Log.d(_tag, 'Retrieved App: $appName (owner ${ownerAddress.eip55With0x})');
        return app;
      }

      Log.w(_tag, 'Unexpected app data format for App: $appName');
      return null;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error retrieving app: $e');
      return null;
    }
  }

  /// Retrieves all pointers for a given app.
  static Future<AppRegistryManagerContract.GetAllAppPointers?> getAllAppPointers(
      EthereumAddress accountAddress, String appName) async {
    try {
      Log.d(_tag, 'Getting all pointers for App: $appName, Account: ${accountAddress.eip55With0x}');
      final result = await Future.any([
        PublicOSBsp.appRegistryManagerContract.getAllAppPointers(
          (slug: appName),
        ),
        Future.delayed(const Duration(seconds: 5)).then((_) => throw TimeoutException('Get all app pointers timed out')),
      ]);
      Log.d(_tag, 'Retrieved ${result.pointerTypes.length} pointers for App: $appName');
      return result;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error retrieving all app pointers: $e');
      return null;
    }
  }

  /// Retrieves a specific pointer value for an app.
  static Future<String?> getAppPointer(EthereumAddress accountAddress, String appName, String pointerType) async {
    try {
      Log.d(_tag, 'Getting pointer $pointerType for App: $appName, Account: ${accountAddress.eip55With0x}');
      final value = await Future.any([
        PublicOSBsp.appRegistryManagerContract.getAppPointer(
          (slug: appName, pointerType: pointerType),
        ),
        Future.delayed(const Duration(seconds: 5)).then((_) => throw TimeoutException('Get app pointer timed out')),
      ]);
      if (value.isEmpty) {
        Log.d(_tag, 'No pointer $pointerType found for App: $appName (empty string)');
        return null;
      }
      Log.d(_tag, 'Retrieved pointer $pointerType = $value for App: $appName');
      return value;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error retrieving app pointer: $e');
      return null;
    }
  }

  // ============================================
  // SLUG-ONLY READS
  // ============================================
  //
  // The chain's App Registry is keyed by slug ALONE -- `apps` is a
  // `mapping(string => App)` with `require(!apps[slug].exists)` on register, so
  // slugs are globally unique and every read function above takes only a slug.
  // The `accountAddress` parameter on the older wrappers is therefore
  // decorative: it is used for logging and to stamp `ownerAccountAddress` on the
  // returned bookmark, which means that field echoes the CALLER'S OWN INPUT
  // rather than what the chain says. Anything making a trust decision must not
  // read it. These two wrappers ask the chain the question directly.

  /// The app's registered owner account, straight from chain.
  ///
  /// Returns null when the app does not exist -- `apps[slug].owner` is the zero
  /// address for an unregistered slug (`AppRegistryMemory.sol:415`), so this one
  /// call answers both "does it exist" and "whose is it".
  static Future<EthereumAddress?> getAppOwnerBySlug(String slug) async {
    try {
      final owner = await Future.any([
        PublicOSBsp.appRegistryManagerContract.getAppOwner((slug: slug)),
        Future.delayed(const Duration(seconds: 5))
            .then((_) => throw TimeoutException('Get app owner timed out')),
      ]);
      if (owner.eip55With0x.toLowerCase() ==
          '0x0000000000000000000000000000000000000000') {
        Log.d(_tag, 'App $slug is not registered');
        return null;
      }
      return owner;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error retrieving app owner for $slug: $e');
      return null;
    }
  }

  /// One pointer value for an app, by slug. Null when unset or unreadable.
  ///
  /// Note this reads from CHAIN every time. The `BookmarkedApps` row caches only
  /// a fixed well-known set of pointer types, and a key nobody flattens is
  /// stored on chain and silently never surfaced -- so anything reading a
  /// pointer outside that set must come through here.
  static Future<String?> getPointerBySlug(String slug, String pointerType) async {
    try {
      final value = await Future.any([
        PublicOSBsp.appRegistryManagerContract.getAppPointer(
          (slug: slug, pointerType: pointerType),
        ),
        Future.delayed(const Duration(seconds: 5))
            .then((_) => throw TimeoutException('Get app pointer timed out')),
      ]);
      if (value.isEmpty) return null;
      return value;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error retrieving pointer $pointerType for $slug: $e');
      return null;
    }
  }

  /// Checks if an app exists for a given account.
  static Future<bool> appExists(EthereumAddress accountAddress, String appName) async {
    try {
      Log.d(_tag, 'Checking if App $appName exists for Account: ${accountAddress.eip55With0x}');
      final exists = await Future.any([
        PublicOSBsp.appRegistryManagerContract.appExists(
          (slug: appName),
        ),
        Future.delayed(const Duration(seconds: 5)).then((_) => throw TimeoutException('App exists check timed out')),
      ]);
      Log.d(_tag, 'App $appName exists: $exists');
      return exists;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error checking if app exists: $e');
      return false;
    }
  }

  /// Checks if a pointer exists for a given app.
  static Future<bool> pointerExists(EthereumAddress accountAddress, String appName, String pointerType) async {
    try {
      Log.d(_tag, 'Checking if pointer $pointerType exists for App: $appName');
      final exists = await Future.any([
        PublicOSBsp.appRegistryManagerContract.pointerExists(
          (slug: appName, pointerType: pointerType),
        ),
        Future.delayed(const Duration(seconds: 5)).then((_) => throw TimeoutException('Pointer exists check timed out')),
      ]);
      Log.d(_tag, 'Pointer $pointerType for App $appName exists: $exists');
      return exists;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error checking if pointer exists: $e');
      return false;
    }
  }

  // ============================================
  // CONVENIENCE METHODS
  // ============================================

  /// Retrieves all apps with their pointers for a given account.
  static Future<List<AppBookmark>?> getAllAccountApps(EthereumAddress accountAddress) async {
    try {
      Log.d(_tag, 'Getting all apps with pointers for Account: ${accountAddress.eip55With0x}');
      final appNames = await getAccountApps(accountAddress);

      Log.d(_tag, 'getAccountApps returned: $appNames');

      if (appNames == null || appNames.isEmpty) {
        Log.d(_tag, 'No apps found for Account: ${accountAddress.eip55With0x}');
        return [];
      }

      Log.d(_tag, 'Processing ${appNames.length} apps...');
      List<AppBookmark> apps = [];
      for (final name in appNames) {
        Log.d(_tag, 'Fetching app "$name"...');
        final app = await getApp(accountAddress, name);
        if (app != null) {
          Log.d(_tag, 'Successfully fetched "$name" — display: ${app.displayName}, pointers: ${app.pointers.length}, URL: ${app.url ?? "NO URL"}');
          apps.add(app);
        } else {
          Log.w(_tag, 'Failed to fetch "$name" (returned null)');
        }
      }

      Log.d(_tag, 'Retrieved ${apps.length} complete apps for Account: ${accountAddress.eip55With0x}');
      return apps;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error retrieving all account apps: $e');
      Log.e(_tag, 'Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Retrieves all apps for the current authenticated user.
  /// Uses cache-first strategy: loads cached apps immediately, then syncs with blockchain.
  static Future<List<AppBookmark>?> getCurrentUserApps() async {
    final accountAddress = await PublicOSAccounts.getSelectedAccountAddress();
    if (accountAddress == null) {
      Log.w(_tag, 'No current account address available.');
      return null;
    }
    return getAllAccountApps(accountAddress);
  }

  /// Gets cached apps owned by the current user (for instant display).
  /// Returns apps from local storage where owner_address matches current user.
  static Future<List<AppBookmark>> getCachedMyApps() async {
    if (PublicOS.sessionBlockchainAddress == null) {
      Log.w(_tag, 'Session address not available.');
      return [];
    }

    try {
      final accountAddress = await PublicOSAccounts.getSelectedAccountAddress();
      if (accountAddress == null) {
        Log.w(_tag, 'No current account address available.');
        return [];
      }

      Log.d(_tag, 'Getting cached apps owned by: ${accountAddress.eip55With0x}');

      final rows = await PublicOS.database.getBookmarkedAppsByOwner(
        accountAddress.eip55With0x,
        PublicOS.sessionBlockchainAddress!,
      );

      final apps = rows.map((row) => _appBookmarkFromRow(row)).toList();
      Log.d(_tag, 'Retrieved ${apps.length} cached "My Apps".');
      return apps;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting cached my apps: $e');
      return [];
    }
  }

  /// Syncs user's apps with blockchain and updates local cache.
  /// Returns fresh list from blockchain and updates cache accordingly.
  static Future<List<AppBookmark>?> syncMyAppsWithBlockchain() async {
    try {
      final accountAddress = await PublicOSAccounts.getSelectedAccountAddress();
      if (accountAddress == null) {
        Log.w(_tag, 'No current account address available for sync.');
        return null;
      }

      Log.d(_tag, 'Syncing My Apps with blockchain for: ${accountAddress.eip55With0x}');

      // Fetch fresh data from blockchain
      final freshApps = await getAllAccountApps(accountAddress);
      if (freshApps == null) {
        Log.e(_tag, 'Failed to fetch apps from blockchain.');
        return null;
      }

      // Get current cached apps
      final cachedApps = await getCachedMyApps();
      final cachedAppNames = cachedApps.map((app) => app.appName).toSet();
      final freshAppNames = freshApps.map((app) => app.appName).toSet();

      // Delete apps that are no longer on blockchain
      final appsToDelete = cachedAppNames.difference(freshAppNames);
      for (final appName in appsToDelete) {
        Log.d(_tag, 'Removing deleted app from cache: $appName');
        await removeBookmark(appName, accountAddress);
      }

      // Update/add apps from blockchain
      for (final app in freshApps) {
        await bookmarkApp(app); // This uses REPLACE conflict algorithm
      }

      Log.i(_tag, 'Sync complete. ${freshApps.length} apps in cache.');
      return freshApps;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error syncing my apps: $e');
      return null;
    }
  }

  /// Registers a new app with initial pointers (convenience method).
  static Future<bool> registerAppWithPointers(
    String appName,
    String displayName,
    Map<String, String> pointers,
  ) async {
    // First register the app
    final registered = await registerApp(appName, displayName);
    if (!registered) {
      return false;
    }

    // Then set all pointers
    for (final entry in pointers.entries) {
      final success = await setAppPointer(appName, entry.key, entry.value);
      if (!success) {
        Log.w(_tag, 'Failed to set pointer ${entry.key} for app $appName');
        // Continue with other pointers, don't fail completely
      }
    }

    return true;
  }

  // ============================================
  // GLOBAL APP SEARCH
  // ============================================

  /// Searches for apps by title across all registered apps.
  /// Returns a list of app slugs matching the search query.
  static Future<List<String>?> searchAppsByTitle(String query) async {
    if (query.trim().isEmpty) {
      Log.d(_tag, 'Empty search query.');
      return [];
    }

    try {
      Log.d(_tag, 'Searching apps with title containing: "$query"');
      final slugs = await Future.any([
        PublicOSBsp.appRegistryManagerContract.searchByTitle(
          (title: query),
        ),
        Future.delayed(const Duration(seconds: 10)).then((_) => throw TimeoutException('App search timed out')),
      ]);
      Log.d(_tag, 'Found ${slugs.length} apps matching "$query"');
      return slugs;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error searching apps: $e');
      return null;
    }
  }

  /// Searches for apps by title and returns full AppBookmark objects.
  /// Fetches each app's details including pointers.
  static Future<List<AppBookmark>?> searchAppsWithDetails(String query) async {
    final slugs = await searchAppsByTitle(query);
    if (slugs == null) return null;
    if (slugs.isEmpty) return [];

    try {
      Log.d(_tag, 'Fetching details for ${slugs.length} apps...');
      final apps = <AppBookmark>[];

      for (final slug in slugs) {
        try {
          // Get app info by slug (owner-agnostic lookup)
          final appData = await Future.any([
            PublicOSBsp.appRegistryManagerContract.getAppBySlug(
              (slug: slug),
            ),
            Future.delayed(const Duration(seconds: 5)).then((_) => throw TimeoutException('Get app timed out')),
          ]);

          // appData is a tuple: (exists: bool, slug: string, title: string, owner: address)
          // It comes back as a List from the contract
          if (appData is List && appData.length >= 4) {
            final exists = appData[0] as bool;
            // appData[1] is slug (we already have it)
            final displayName = appData[2] as String;
            final ownerAddressRaw = appData[3];

            if (!exists) continue;

            // Parse owner address - it may come as EthereumAddress or String
            EthereumAddress ownerAddress;
            if (ownerAddressRaw is EthereumAddress) {
              ownerAddress = ownerAddressRaw;
            } else if (ownerAddressRaw is String) {
              ownerAddress = EthereumAddress.fromHex(ownerAddressRaw);
            } else {
              Log.w(_tag, 'Unknown owner address type for "$slug": ${ownerAddressRaw.runtimeType}');
              continue;
            }

            // Get pointers for this app
            final pointersData = await getAllAppPointers(ownerAddress, slug);
            List<AppPointer> pointers = [];
            if (pointersData != null) {
              for (int i = 0; i < pointersData.pointerTypes.length; i++) {
                pointers.add(AppPointer(
                  type: pointersData.pointerTypes[i],
                  value: pointersData.values[i],
                ));
              }
            }

            apps.add(AppBookmark(
              appName: slug,
              displayName: displayName,
              ownerAccountAddress: ownerAddress,
              pointers: pointers,
            ));
          }
        } catch (e) {
          Log.e(_tag, 'Error fetching app "$slug": $e');
          // Continue with other apps
        }
      }

      Log.d(_tag, 'Retrieved ${apps.length} apps with details.');
      return apps;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error fetching app details: $e');
      return null;
    }
  }

  // ============================================
  // LOCAL BOOKMARK OPERATIONS (SQLite)
  // ============================================

  /// Duration before a bookmarked app needs refreshing from blockchain
  static const Duration refreshInterval = Duration(hours: 24);

  /// Saves an app as a local bookmark for the current session.
  static Future<bool> bookmarkApp(AppBookmark app) async {
    if (PublicOS.sessionBlockchainAddress == null) {
      Log.w(_tag, 'Session address not available.');
      return false;
    }

    try {
      Log.d(_tag, 'Bookmarking app: ${app.appName} from ${app.ownerAccountAddress.eip55With0x}');

      final now = DateTime.now();
      final nextUpdate = now.add(refreshInterval);

      final companion = db.BookmarkedAppsCompanion(
        appName: Value(app.appName),
        ownerAddress: Value(app.ownerAccountAddress.eip55With0x),
        displayName: Value(app.displayName),
        iconUrl: Value(app.icon),
        description: Value(app.description),
        warnings: Value(app.getPointer('warnings')?.value),
        categoryOne: Value(app.getPointer('category_one')?.value),
        categoryTwo: Value(app.getPointer('category_two')?.value),
        url: Value(app.url),
        appstoreLink: Value(app.getPointer('appstore_link')?.value),
        playstoreLink: Value(app.getPointer('playstore_link')?.value),
        apkDownload: Value(app.getPointer('apk_download')?.value),
        ipaDownload: Value(app.getPointer('ipa_download')?.value),
        sessionAddress: Value(PublicOS.sessionBlockchainAddress!),
        bookmarkedAt: Value(now.millisecondsSinceEpoch),
        nextUpdate: Value(nextUpdate.millisecondsSinceEpoch),
      );

      await PublicOS.database.upsertBookmarkedApp(companion);

      Log.i(_tag, 'App bookmarked successfully. Next update: $nextUpdate');
      return true;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error bookmarking app: $e');
      return false;
    }
  }

  /// Removes an app from local bookmarks.
  static Future<bool> removeBookmark(String appName, EthereumAddress ownerAddress) async {
    if (PublicOS.sessionBlockchainAddress == null) {
      Log.w(_tag, 'Session address not available.');
      return false;
    }

    try {
      Log.d(_tag, 'Removing bookmark: $appName from ${ownerAddress.eip55With0x}');

      final count = await PublicOS.database.deleteBookmarkedApp(
        appName,
        ownerAddress.eip55With0x,
        PublicOS.sessionBlockchainAddress!,
      );

      if (count > 0) {
        Log.i(_tag, 'Bookmark removed successfully.');
        return true;
      } else {
        Log.d(_tag, 'Bookmark not found.');
        return false;
      }
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error removing bookmark: $e');
      return false;
    }
  }

  /// Gets all bookmarked apps for the current session.
  static Future<List<AppBookmark>> getBookmarkedApps() async {
    if (PublicOS.sessionBlockchainAddress == null) {
      Log.w(_tag, 'Session address not available.');
      return [];
    }

    try {
      Log.d(_tag, 'Getting bookmarked apps for session: ${PublicOS.sessionBlockchainAddress}');

      final rows = await PublicOS.database.getBookmarkedAppsForSession(
        PublicOS.sessionBlockchainAddress!,
      );

      final apps = rows.map((row) => _appBookmarkFromRow(row)).toList();
      Log.d(_tag, 'Retrieved ${apps.length} bookmarked apps.');
      return apps;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting bookmarked apps: $e');
      return [];
    }
  }

  /// Checks if an app is bookmarked.
  static Future<bool> isAppBookmarked(String appName, EthereumAddress ownerAddress) async {
    if (PublicOS.sessionBlockchainAddress == null) {
      return false;
    }

    try {
      final row = await PublicOS.database.getBookmarkedApp(
        appName,
        ownerAddress.eip55With0x,
        PublicOS.sessionBlockchainAddress!,
      );

      return row != null;
    } catch (e) {
      Log.e(_tag, 'Error checking if app is bookmarked: $e');
      return false;
    }
  }

  /// Gets a specific bookmarked app.
  static Future<AppBookmark?> getBookmarkedApp(String appName, EthereumAddress ownerAddress) async {
    if (PublicOS.sessionBlockchainAddress == null) {
      return null;
    }

    try {
      final row = await PublicOS.database.getBookmarkedApp(
        appName,
        ownerAddress.eip55With0x,
        PublicOS.sessionBlockchainAddress!,
      );

      if (row != null) {
        return _appBookmarkFromRow(row);
      }
      return null;
    } catch (e) {
      Log.e(_tag, 'Error getting bookmarked app: $e');
      return null;
    }
  }

  /// Converts a database row to an AppBookmark.
  static AppBookmark _appBookmarkFromRow(db.BookmarkedApp row) {
    final pointers = <AppPointer>[];

    // Add standard pointers if they exist
    if (row.iconUrl != null) {
      pointers.add(AppPointer(type: 'icon', value: row.iconUrl!));
    }
    if (row.description != null) {
      pointers.add(AppPointer(type: 'description', value: row.description!));
    }
    if (row.warnings != null) {
      pointers.add(AppPointer(type: 'warnings', value: row.warnings!));
    }
    if (row.categoryOne != null) {
      pointers.add(AppPointer(type: 'category_one', value: row.categoryOne!));
    }
    if (row.categoryTwo != null) {
      pointers.add(AppPointer(type: 'category_two', value: row.categoryTwo!));
    }
    if (row.url != null) {
      pointers.add(AppPointer(type: 'url', value: row.url!));
    }
    if (row.appstoreLink != null) {
      pointers.add(AppPointer(type: 'appstore_link', value: row.appstoreLink!));
    }
    if (row.playstoreLink != null) {
      pointers.add(AppPointer(type: 'playstore_link', value: row.playstoreLink!));
    }
    if (row.apkDownload != null) {
      pointers.add(AppPointer(type: 'apk_download', value: row.apkDownload!));
    }
    if (row.ipaDownload != null) {
      pointers.add(AppPointer(type: 'ipa_download', value: row.ipaDownload!));
    }

    return AppBookmark(
      appName: row.appName,
      displayName: row.displayName,
      ownerAccountAddress: EthereumAddress.fromHex(row.ownerAddress),
      pointers: pointers,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.bookmarkedAt),
    );
  }

  // ============================================
  // REFRESH STALE BOOKMARKS
  // ============================================

  /// Refreshes bookmarked apps that are stale (nextUpdate is null or in the past).
  /// When [force] is true, refreshes ALL bookmarked apps regardless of staleness.
  /// Fetches fresh data from blockchain and updates local cache.
  /// Returns the number of apps refreshed.
  static Future<int> refreshStaleBookmarks({bool force = false}) async {
    if (PublicOS.sessionBlockchainAddress == null) {
      Log.w(_tag, 'Session address not available.');
      return 0;
    }

    try {
      final staleApps = force
          ? await PublicOS.database.getBookmarkedAppsForSession(
              PublicOS.sessionBlockchainAddress!,
            )
          : await PublicOS.database.getAppsNeedingUpdate(
              PublicOS.sessionBlockchainAddress!,
              DateTime.now().millisecondsSinceEpoch,
            );

      if (staleApps.isEmpty) {
        Log.d(_tag, 'No apps need refreshing.');
        return 0;
      }

      Log.d(_tag, 'Found ${staleApps.length} apps needing refresh.');

      int refreshedCount = 0;
      for (final row in staleApps) {
        try {
          final ownerAddress = EthereumAddress.fromHex(row.ownerAddress);
          Log.d(_tag, 'Refreshing app "${row.appName}" from ${row.ownerAddress}...');

          // Fetch fresh data from blockchain
          final freshApp = await getApp(ownerAddress, row.appName);

          if (freshApp != null) {
            // Update the bookmark with fresh data (this also updates nextUpdate)
            await bookmarkApp(freshApp);
            // The open history keeps its own snapshot of title/icon/url;
            // bring it along so an old history row stops painting a
            // re-pointed icon.
            await _refreshHistoryEntry(freshApp);
            refreshedCount++;
            Log.d(_tag, 'Refreshed "${row.appName}" successfully.');
          } else {
            // App no longer exists on blockchain - just update nextUpdate to avoid repeated checks
            final nextUpdate = DateTime.now().add(refreshInterval).millisecondsSinceEpoch;
            await PublicOS.database.updateAppNextUpdate(
              row.appName,
              row.ownerAddress,
              PublicOS.sessionBlockchainAddress!,
              nextUpdate,
            );
            Log.d(_tag, 'App "${row.appName}" not found on blockchain, skipping.');
          }
        } catch (e) {
          Log.e(_tag, 'Error refreshing app "${row.appName}": $e');
          // Continue with other apps even if one fails
        }
      }

      Log.i(_tag, 'Refreshed $refreshedCount of ${staleApps.length} apps.');
      return refreshedCount;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error refreshing stale bookmarks: $e');
      return 0;
    }
  }

  // ============================================
  // LOCAL OPEN HISTORY (settings-backed, v1)
  // ============================================
  //
  // "Last visited apps": every time an app tab becomes the current tab in a
  // client's browser, the app is recorded here. Local-only, per session, like
  // bookmarks — nothing on chain knows you opened anything.
  //
  // v1 stores the list as ONE settings row (`PublicOSSettings`, key
  // [recentAppsSettingKey]) holding a JSON array, most recent first, deduped
  // by slug, capped at [recentAppsMax]. Chosen over a Drift table so the
  // feature ships with no schema migration in either app. Each entry keeps
  // only what a launcher needs to paint offline
  // — slug, title, owner, and the `icon` + `url` pointers — plus `openedAt`.
  //
  // Possible v2: promote to its own table once the list is consumed
  // by more than a launcher rail (per-open timestamps for stats, joins against
  // BookmarkedApps, pruning by owner). The API below is the contract; the
  // storage behind it can change without touching consumers.

  /// Settings key holding the open history (JSON array, most recent first).
  static const String recentAppsSettingKey = 'app_open_history';

  /// Hard cap on the history length. Oldest entries fall off past this.
  static const int recentAppsMax = 100;

  static const String _openedAtKey = 'openedAt';
  static const String _appKey = 'app';

  /// Trim an [AppBookmark] to the pointers a launcher paints with.
  static AppBookmark _historyShape(AppBookmark app) {
    return AppBookmark(
      appName: app.appName,
      displayName: app.displayName,
      ownerAccountAddress: app.ownerAccountAddress,
      pointers: [
        for (final type in const ['icon', 'url'])
          if (app.getPointer(type) != null) app.getPointer(type)!,
      ],
    );
  }

  /// Read the raw history rows (`{app, openedAt}`), most recent first.
  /// Malformed rows are skipped, never thrown on.
  static Future<List<Map<String, dynamic>>> _readHistoryRows() async {
    if (!PublicOS.isAuthenticated || PublicOS.sessionBlockchainAddress == null) {
      return const [];
    }
    try {
      final record = await PublicOSSettings.getSetting(recentAppsSettingKey);
      if (record == null || record.value.isEmpty) return const [];
      final decoded = jsonDecode(record.value);
      if (decoded is! List) return const [];
      return [
        for (final row in decoded)
          if (row is Map<String, dynamic> && row[_appKey] is Map<String, dynamic>) row,
      ];
    } catch (e) {
      Log.e(_tag, 'Error reading app open history: $e');
      return const [];
    }
  }

  static Future<bool> _writeHistoryRows(List<Map<String, dynamic>> rows) async {
    try {
      final record = Record.asSettings(
        key: recentAppsSettingKey,
        value: jsonEncode(rows),
        isSystem: true,
      );
      return await PublicOSSettings.setSetting(recentAppsSettingKey, record);
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error writing app open history: $e');
      return false;
    }
  }

  /// Record that [app] was just opened. Moves it to the front of the history
  /// (deduped by slug — slugs are globally unique on chain), refreshing the
  /// stored title/icon/url from [app], and drops entries past [recentAppsMax].
  static Future<bool> recordAppOpen(AppBookmark app) async {
    if (!PublicOS.isAuthenticated || PublicOS.sessionBlockchainAddress == null) {
      Log.w(_tag, 'Session address not available; app open not recorded.');
      return false;
    }
    final rows = await _readHistoryRows();
    final kept = [
      for (final row in rows)
        if ((row[_appKey] as Map<String, dynamic>)['appName'] != app.appName) row,
    ];
    final next = <Map<String, dynamic>>[
      {
        _appKey: _historyShape(app).toJson(),
        _openedAtKey: DateTime.now().toIso8601String(),
      },
      ...kept,
    ];
    if (next.length > recentAppsMax) next.removeRange(recentAppsMax, next.length);
    final ok = await _writeHistoryRows(next);
    if (ok) Log.d(_tag, 'App open recorded: ${app.appName} (${next.length} in history)');
    return ok;
  }

  /// Rewrite [app]'s history entry, if any, with its fresh title/icon/url.
  /// Position and `openedAt` are kept, so this is not an "open". Only a row
  /// with the SAME owner is touched: a slug re-registered by someone else
  /// must not inherit an old history row. No-op (and no write) when absent
  /// or unchanged.
  static Future<void> _refreshHistoryEntry(AppBookmark app) async {
    if (!PublicOS.isAuthenticated || PublicOS.sessionBlockchainAddress == null) {
      return;
    }
    final rows = await _readHistoryRows();
    final fresh = _historyShape(app).toJson();
    var changed = false;
    final next = <Map<String, dynamic>>[
      for (final row in rows)
        () {
          final stored = row[_appKey] as Map<String, dynamic>;
          final sameApp = stored['appName'] == app.appName &&
              '${stored['ownerAccountAddress']}'.toLowerCase() ==
                  '${fresh['ownerAccountAddress']}'.toLowerCase();
          if (!sameApp || jsonEncode(stored) == jsonEncode(fresh)) return row;
          changed = true;
          return {...row, _appKey: fresh};
        }(),
    ];
    if (!changed) return;
    final ok = await _writeHistoryRows(next);
    if (ok) Log.d(_tag, 'History entry refreshed: ${app.appName}');
  }

  /// The open history, most recent first. Empty when nothing was ever opened
  /// or the session is not authenticated.
  static Future<List<AppBookmark>> getRecentApps() async {
    final rows = await _readHistoryRows();
    final apps = <AppBookmark>[];
    for (final row in rows) {
      try {
        apps.add(AppBookmark.fromJson(row[_appKey] as Map<String, dynamic>));
      } catch (e) {
        Log.w(_tag, 'Skipping malformed history row: $e');
      }
    }
    return apps;
  }

  /// Remove one app (by slug) from the history — the user's "remove from
  /// history". A slug that is not present is a successful no-op.
  static Future<bool> removeFromRecentApps(String appName) async {
    if (!PublicOS.isAuthenticated || PublicOS.sessionBlockchainAddress == null) {
      return false;
    }
    final rows = await _readHistoryRows();
    final kept = [
      for (final row in rows)
        if ((row[_appKey] as Map<String, dynamic>)['appName'] != appName) row,
    ];
    if (kept.length == rows.length) return true;
    return _writeHistoryRows(kept);
  }

  /// Clear the whole history.
  static Future<bool> clearRecentApps() async {
    if (!PublicOS.isAuthenticated || PublicOS.sessionBlockchainAddress == null) {
      return false;
    }
    return _writeHistoryRows(const []);
  }
}
