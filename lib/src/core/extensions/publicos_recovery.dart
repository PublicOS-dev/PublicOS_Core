import 'dart:async';
import 'dart:typed_data';

import 'package:publicos_core/src/core/core.dart';
import 'package:publicos_core/src/utils/eip712_consent.dart' as eip712;
import 'package:publicos_core/src/utils/log.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart' show EthPrivateKey, Transaction;
/// Recovery management extension for PublicOS.
/// Handles account recovery, recovery contacts, and recovery voting.
extension PublicOSRecovery on PublicOS {
  static const _tag = 'Recovery';

  /// Explicit gas limit for the two RecoveryModule writes that can execute a
  /// reseed inline.
  ///
  /// `eth_estimateGas` CANNOT estimate these two calls: at threshold 1 (and on
  /// the passing vote at any threshold) they run `_tryExecuteReseed` inside a
  /// `try/catch`, so an inner frame can OOG under the 63/64 rule while the
  /// outer call still succeeds. Nethermind refuses to resolve that and answers
  /// `"Gas estimation failed due to out of gas"` at every gas cap,
  /// while `eth_call` on the same
  /// payload succeeds and plain writes on the same contracts estimate fine
  /// (`addRecoveryContact` 95,735 / `setRecoveryThreshold` 63,155).
  ///
  /// web3dart does `maxGas ?? await client.estimateGas(...)`
  /// (`transaction_signer.dart:58`), so leaving this null makes the send throw
  /// BEFORE anything is signed — surfacing to the user as a bogus gas error on
  /// a recovery that the chain would have accepted. Passing an explicit limit
  /// skips estimation entirely.
  ///
  /// Sizing: chain 4489 is free-gas (`gasPrice 0`) with a 200,000,000 block
  /// limit, and unused gas is refunded, so headroom is free. Measured need is
  /// well under 1M; 8M is ~4% of a block.
  static const int _reseedGasLimit = 8000000;

  ///*********************************************
  /// RECOVERY MANAGEMENT METHODS
  ///*********************************************

  /// Add a recovery contact to the current account
  static Future<bool> addRecoveryContact(EthereumAddress recoveryContactAccountAddress) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      throw Exception('Authentication and blockchain key required');
    }

    try {
      Log.d(_tag, 'Adding recovery contact: ${recoveryContactAccountAddress.eip55With0x}');

      // Get initial block number
      final startTime = DateTime.now();
      final maxWaitTime = const Duration(seconds: 10);
      int initialBlockNumber = 0;

      try {
        initialBlockNumber = await PublicOSBsp.getBlockNumber();
        Log.d(_tag, 'Initial block number: $initialBlockNumber');
      } catch (e) {
        Log.w(_tag, 'Could not get initial block number: $e');
      }

      // Send transaction
      await PublicOSBsp.accountManagerContract.addRecoveryContact(
        (recoveryContactAccountAddress: recoveryContactAccountAddress),
        credentials: PublicOS.currentBlockchainPrivateKey!,
      );

      Log.d(_tag, 'Transaction sent, waiting for block confirmation...');

      // Wait for at least one new block to be mined
      while (DateTime.now().difference(startTime) < maxWaitTime) {
        try {
          final currentBlockNumber = await PublicOSBsp.getBlockNumber();
          if (currentBlockNumber > initialBlockNumber) {
            Log.i(_tag, 'New block detected ($currentBlockNumber > $initialBlockNumber), recovery contact should be confirmed');
            return true;
          }
        } catch (e) {
          Log.w(_tag, 'Could not check block number: $e');
        }

        // Wait 1 second before retrying
        await Future.delayed(const Duration(seconds: 1));
      }

      Log.w(_tag, 'Timeout waiting for block confirmation');
      PublicOS.lastError = 'Timeout waiting for blockchain confirmation';
      return false;

    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error adding recovery contact: $e');
      return false;
    }
  }

  /// Remove a recovery contact from the current account
  static Future<bool> removeRecoveryContact(EthereumAddress recoveryContactAccountAddress) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      throw Exception('Authentication and blockchain key required');
    }

    try {
      Log.d(_tag, 'Removing recovery contact: ${recoveryContactAccountAddress.eip55With0x}');

      // Get initial block number
      final startTime = DateTime.now();
      final maxWaitTime = const Duration(seconds: 10);
      int initialBlockNumber = 0;

      try {
        initialBlockNumber = await PublicOSBsp.getBlockNumber();
        Log.d(_tag, 'Initial block number: $initialBlockNumber');
      } catch (e) {
        Log.w(_tag, 'Could not get initial block number: $e');
      }

      // Send transaction
      await PublicOSBsp.accountManagerContract.removeRecoveryContact(
        (recoveryContactAccountAddress: recoveryContactAccountAddress),
        credentials: PublicOS.currentBlockchainPrivateKey!,
      );

      Log.d(_tag, 'Transaction sent, waiting for block confirmation...');

      // Wait for at least one new block to be mined
      while (DateTime.now().difference(startTime) < maxWaitTime) {
        try {
          final currentBlockNumber = await PublicOSBsp.getBlockNumber();
          if (currentBlockNumber > initialBlockNumber) {
            Log.i(_tag, 'New block detected ($currentBlockNumber > $initialBlockNumber), recovery contact should be removed');
            return true;
          }
        } catch (e) {
          Log.w(_tag, 'Could not check block number: $e');
        }

        // Wait 1 second before retrying
        await Future.delayed(const Duration(seconds: 1));
      }

      Log.w(_tag, 'Timeout waiting for block confirmation');
      PublicOS.lastError = 'Timeout waiting for blockchain confirmation';
      return false;

    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error removing recovery contact: $e');
      return false;
    }
  }

  /// Set the recovery threshold for the current account
  static Future<bool> setRecoveryThreshold(int threshold) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      throw Exception('Authentication and blockchain key required');
    }

    try {
      Log.d(_tag, 'Setting recovery threshold to: $threshold');

      await PublicOSBsp.accountManagerContract.setRecoveryThreshold(
        (threshold: BigInt.from(threshold)),
        credentials: PublicOS.currentBlockchainPrivateKey!,
      );

      Log.i(_tag, 'Recovery threshold set successfully');
      return true;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error setting recovery threshold: $e');
      return false;
    }
  }

  /// Get recovery contacts and threshold for an account
  static Future<({List<EthereumAddress> contacts, int threshold})> getAccountRecoveryContacts(EthereumAddress accountAddress) async {
    try {
      final result = await PublicOSBsp.accountManagerContract.getAccountRecoveryContacts(
        (accountAddress: accountAddress),
      );

      // Check if threshold is within int range
      int thresholdInt = 0;
      if (result.threshold.bitLength <= 63) {
        thresholdInt = result.threshold.toInt();
      } else {
        Log.w(_tag, 'Threshold value too large for int conversion: ${result.threshold}');
      }

      return (contacts: result.contacts, threshold: thresholdInt);
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting recovery contacts for ${accountAddress.eip55With0x}: $e');
      return (contacts: <EthereumAddress>[], threshold: 0);
    }
  }

  /// Get recovery contacts and threshold for the current account
  static Future<({List<EthereumAddress> contacts, int threshold})?> getMyRecoveryContacts() async {
    if (PublicOS.myPublicosAddress == null) {
      Log.w(_tag, 'No current account selected');
      return null;
    }

    return await getAccountRecoveryContacts(EthereumAddress.fromHex(PublicOS.myPublicosAddress!));
  }

  ///*********************************************
  /// RECOVERY VOTING METHODS
  ///*********************************************

  /// Start a recovery vote to atomically replace `targetAccountAddress`'s
  /// full session list with the proposed sole session. The consent sig is from
  /// the proposed sole session's key — proves they agreed to be installed.
  /// On a successful vote the RecoveryModule calls
  /// `accountManager.reseedSessionViaRecovery(...)` with the cached deadline +
  /// sig, so both must remain valid until the vote completes (set a longer
  /// `validFor` than the default UX deadline when building the sig).
  ///
  /// Low-level: caller supplies `(deadline, sig)`. For same-device use see
  /// [startRecoveryVoteWithLocalKey].
  static Future<bool> startRecoveryVote({
    required EthereumAddress targetAccountAddress,
    required EthereumAddress proposedSessionAddress,
    required BigInt deadline,
    required Uint8List sig,
  }) async {
    if (!PublicOS.isAuthenticated ||
        PublicOS.currentBlockchainPrivateKey == null) {
      throw Exception('Authentication and blockchain key required');
    }

    try {
      Log.d(
        _tag,
        'Starting recovery vote for target: ${targetAccountAddress.eip55With0x}, proposed sole session: ${proposedSessionAddress.eip55With0x}',
      );

      await PublicOSBsp.recoveryModuleContract.startReseedVote(
        (
          targetAccountAddress: targetAccountAddress,
          proposedSoleSession: proposedSessionAddress,
          deadline: deadline,
          sig: sig,
        ),
        credentials: PublicOS.currentBlockchainPrivateKey!,
        // Explicit limit — this call is not estimatable. See [_reseedGasLimit].
        transaction: Transaction(maxGas: _reseedGasLimit),
      );

      Log.i(_tag, 'Recovery vote started successfully');
      return true;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error starting recovery vote: $e');
      return false;
    }
  }

  /// Same-device convenience: signs the shared `SessionConsent` locally with
  /// `proposedSessionKey`, then starts the recovery vote. `validFor` defaults to
  /// 1 hour: recovery is a synchronous, coordinated
  /// event — the vote must reach threshold and execute within the hour, since
  /// the consent deadline is re-checked at execution.
  static Future<bool> startRecoveryVoteWithLocalKey({
    required EthereumAddress targetAccountAddress,
    required EthPrivateKey proposedSessionKey,
    Duration validFor = const Duration(hours: 1),
  }) async {
    final proposed = proposedSessionKey.address;
    final signed = signReseedConsent(
      account: targetAccountAddress,
      newSoleSession: proposed,
      newSoleSessionKey: proposedSessionKey,
      validFor: validFor,
    );
    return startRecoveryVote(
      targetAccountAddress: targetAccountAddress,
      proposedSessionAddress: proposed,
      deadline: signed.deadline,
      sig: signed.sig,
    );
  }

  /// Build + sign the shared `SessionConsent` for the recovery-reseed path.
  /// Same struct as add/full-reset; the path decides
  /// the blast radius, not the sig. `validFor` defaults to 1 hour to match the
  /// synchronous recovery model.
  static ({BigInt deadline, Uint8List sig}) signReseedConsent({
    required EthereumAddress account,
    required EthereumAddress newSoleSession,
    required EthPrivateKey newSoleSessionKey,
    Duration validFor = const Duration(hours: 1),
  }) {
    final deadline = BigInt.from(
      DateTime.now().add(validFor).add(PublicOS.chainClockSkew).millisecondsSinceEpoch ~/ 1000,
    );
    final structHash = eip712.sessionConsentStructHash(
      account: account,
      newSession: newSoleSession,
      ttl: BigInt.zero, // recovery always ends with a permanent key (RecoveryModule signs ttl 0)
      deadline: deadline,
    );
    final domainSep = eip712.domainSeparator(
      chainId: PublicOS.CHAIN_ID,
      verifyingContract: PublicOSBsp.accountManagerAddress,
    );
    final digest = eip712.finalDigest(
      domainSep: domainSep,
      structHash: structHash,
    );
    return (
      deadline: deadline,
      sig: eip712.signDigest(digest, newSoleSessionKey),
    );
  }

  /// Cast a vote in an active recovery session
  static Future<bool> castRecoveryVote({
    required EthereumAddress targetAccountAddress,
    required bool voteToAdd,
  }) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      throw Exception('Authentication and blockchain key required');
    }

    try {
      Log.d(_tag, 'Casting recovery vote for target: ${targetAccountAddress.eip55With0x}, vote: ${voteToAdd ? "ADD" : "CANCEL"}');

      await PublicOSBsp.recoveryModuleContract.castVote(
        (
          targetAccountAddress: targetAccountAddress,
          voteToAdd: voteToAdd,
        ),
        credentials: PublicOS.currentBlockchainPrivateKey!,
        // The vote that reaches threshold executes the reseed inline, same
        // unestimatable shape as startReseedVote. See [_reseedGasLimit].
        transaction: Transaction(maxGas: _reseedGasLimit),
      );

      Log.i(_tag, 'Recovery vote cast successfully');
      return true;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error casting recovery vote: $e');
      return false;
    }
  }

  ///*********************************************
  /// RECOVERY SESSION MONITORING METHODS
  ///*********************************************

  /// Get the active voting session for a target account
  static Future<Map<String, dynamic>?> getActiveRecoverySession(EthereumAddress targetAccountAddress) async {
    try {
      final sessionData = await PublicOSBsp.recoveryModuleContract.getRecoveryVote(
        (targetAccountAddress: targetAccountAddress),
      );

      // The contract returns a dynamic object, need to extract fields
      if (sessionData != null) {
        // Based on the RecoveryVoteView struct, extract the fields
        final session = sessionData as List<dynamic>;

        if (session.length >= 9) {
          final isActive = session[8] as bool;

          if (!isActive) {
            return null; // No active session
          }

          return {
            'targetAccountAddress': (session[0] as EthereumAddress).eip55With0x,
            'proposedSessionAddress': (session[1] as EthereumAddress).eip55With0x,
            'initiatorSessionAddress': (session[2] as EthereumAddress).eip55With0x,
            'initiatorAccountAddress': (session[3] as EthereumAddress).eip55With0x,
            'requiredThreshold': (session[4] as BigInt).toInt(),
            'expirationTimestamp': (session[5] as BigInt).toInt(),
            'addVotesCount': (session[6] as BigInt).toInt(),
            'cancelVotesCount': (session[7] as BigInt).toInt(),
            'isActive': isActive,
          };
        }
      }

      return null; // No session or invalid data
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting recovery session for ${targetAccountAddress.eip55With0x}: $e');
      return null;
    }
  }

  /// Check if there's an active recovery session for the current account
  static Future<Map<String, dynamic>?> getMyActiveRecoverySession() async {
    if (PublicOS.myPublicosAddress == null) {
      Log.w(_tag, 'No current account selected');
      return null;
    }

    return await getActiveRecoverySession(EthereumAddress.fromHex(PublicOS.myPublicosAddress!));
  }

  /// Get recovery sessions where the current account is a recovery contact
  static Future<List<Map<String, dynamic>>> getRecoverySessionsAsContact() async {
    if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
      return [];
    }

    try {
      // Note: This would require indexing events or maintaining a list of accounts
      // For now, return empty list - this would need backend support or event indexing
      Log.d(_tag, 'Getting recovery sessions where current account is a recovery contact');

      // TODO: Implement event indexing or backend API to track sessions
      // where current account is listed as a recovery contact

      return [];
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting recovery sessions as contact: $e');
      return [];
    }
  }

  /// Check if current account can vote in a recovery session
  static Future<bool> canVoteInRecoverySession(EthereumAddress targetAccountAddress) async {
    if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
      return false;
    }

    try {
      // Get recovery contacts for target account
      final recoveryInfo = await getAccountRecoveryContacts(targetAccountAddress);
      final myAccountAddress = EthereumAddress.fromHex(PublicOS.myPublicosAddress!);

      // Check if current account is a recovery contact
      final isRecoveryContact = recoveryInfo.contacts.contains(myAccountAddress);

      if (!isRecoveryContact) {
        return false;
      }

      // Check if there's an active session
      final session = await getActiveRecoverySession(targetAccountAddress);
      return session != null;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error checking if can vote in recovery session: $e');
      return false;
    }
  }

  /// Check if current account has already voted in a session
  static Future<bool> hasVotedInRecoverySession(EthereumAddress targetAccountAddress) async {
    // Note: This would require checking the voters mapping in the contract
    // The current contract doesn't expose this information directly
    // Would need to listen to VoteCast events or add a getter to the contract

    Log.d(_tag, 'Checking if already voted - requires event monitoring or contract update');
    return false; // TODO: Implement when contract exposes voter status
  }
}