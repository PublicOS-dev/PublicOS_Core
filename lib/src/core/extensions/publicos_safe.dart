import 'dart:async';
import 'dart:typed_data';
import 'package:publicos_core/src/core/core.dart';
import 'package:publicos_core/src/utils/log.dart';
import 'package:web3dart/web3dart.dart';
import 'package:wallet/wallet.dart';

/// Safe wallet management extension for PublicOS.
///
/// Routes through `SafeManager` (the per-account main Safe) and `SafeAuth`
/// (transaction execution). For multi-protocol additional wallets, see
/// `PublicOSWallets` in `publicos_wallets.dart`.
extension PublicOSSafe on PublicOS {
  static const _tag = 'Safe';

  /// Get the main Safe address for an account.
  /// Returns null if the account has no main Safe yet.
  static Future<String?> getMainSafeAddress(EthereumAddress accountAddress) async {
    if (!PublicOS.isAuthenticated || PublicOS.myPublicosAddress == null) {
      throw Exception('Authentication and account required');
    }

    try {
      final safeAddress = await Future.any([
        PublicOSBsp.safeManagerContract.getMainSafeAddress(
          (accountAddress: accountAddress),
        ),
        Future.delayed(const Duration(seconds: 5)).then((_) => throw TimeoutException('Request timed out')),
      ]);

      if (safeAddress == EthereumAddress.fromHex('0x0000000000000000000000000000000000000000')) {
        return null;
      }

      return safeAddress.eip55With0x;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting main Safe address: $e');
      return null;
    }
  }

  /// Resolve the account that owns a given Safe address (reverse lookup).
  /// Returns the zero address if the Safe is not registered to any account.
  static Future<EthereumAddress?> getSafeOwnerAccount(EthereumAddress safeAddress) async {
    try {
      return await PublicOSBsp.safeManagerContract.getSafeOwnerAccount(
        (safeAddress: safeAddress),
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting Safe owner account: $e');
      return null;
    }
  }

  /// Check whether a Safe is the main Safe of a given account.
  static Future<bool> isAccountMainSafe({
    required EthereumAddress accountAddress,
    required EthereumAddress safeAddress,
  }) async {
    try {
      return await PublicOSBsp.safeManagerContract.isAccountMainSafe(
        (accountAddress: accountAddress, safeAddress: safeAddress),
      );
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error checking main Safe: $e');
      return false;
    }
  }

  /// Get the ETH balance of a Safe.
  static Future<double?> getSafeBalance(EthereumAddress safeAddress) async {
    try {
      final balance = await PublicOSBsp.getEthBalance(safeAddress.eip55With0x);
      return balance.getValueInUnit(EtherUnit.ether);
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error getting Safe balance: $e');
      return null;
    }
  }

  /// Execute a transaction from a Safe.
  /// For individual accounts: directly through SafeAuth.
  /// For org accounts: through OrgManager voting mechanism.
  static Future<String?> sendTransactionFromSafe({
    required EthereumAddress accountAddress,
    required EthereumAddress safeAddress,
    required String to,
    required BigInt valueWei,
    String data = '0x',
  }) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      throw Exception('Authentication required');
    }

    try {
      Log.d(_tag, 'Sending transaction from Safe: ${safeAddress.eip55With0x}');

      final isOrg = await PublicOSGovernance.isOrgAccount(accountAddress);

      if (isOrg) {
        Log.d(_tag, 'Org account detected, using voting mechanism');

        final result = await PublicOSGovernance.sendStartVote(
          (
            orgAddress: accountAddress,
            tag: Uint8List(32), // no topic: only the default delegations count
            actionType: VoteActionType.executeSafeTx.chainIndex,
            params: [
              EthereumAddress.fromHex(to),      // targetAddress
              valueWei,                         // valueParam
              "",                               // keyParam
              "",                               // valueStringParam
              BigInt.zero,                      // recordTypeValueParam
              "",                               // customTypeParam
              hexToBytes(data),                 // dataParam
              BigInt.zero,                      // operationParam (0 = Call)
            ]
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        );

        Log.i(_tag, 'Org transaction vote started: $result');
        return result;
      } else {
        Log.d(_tag, 'Individual account detected, using direct SafeAuth execution');

        final result = await PublicOSBsp.safeAuthContract.executeCall(
          (
            safe: safeAddress,
            to: EthereumAddress.fromHex(to),
            value: valueWei,
            data: hexToBytes(data),
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        );

        Log.i(_tag, 'Individual account transaction executed: $result');
        return result;
      }
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'Error sending transaction from Safe: $e');
      return null;
    }
  }

  /// Send ERC20 tokens from a Safe.
  /// Encodes transfer(address,uint256) calldata and routes through sendTransactionFromSafe.
  static Future<String?> sendTokenFromSafe({
    required EthereumAddress accountAddress,
    required EthereumAddress safeAddress,
    required EthereumAddress to,
    required BigInt amount,
  }) async {
    final toHex = to.without0x.padLeft(64, '0');
    final amountHex = amount.toRadixString(16).padLeft(64, '0');
    final data = '0xa9059cbb$toHex$amountHex';

    return sendTransactionFromSafe(
      accountAddress: accountAddress,
      safeAddress: safeAddress,
      to: PublicOSBsp.publicOSTokenAddress!.eip55With0x,
      valueWei: BigInt.zero,
      data: data,
    );
  }

  /// Helper method to convert hex string to bytes
  static Uint8List hexToBytes(String hex) {
    if (hex.startsWith('0x')) {
      hex = hex.substring(2);
    }

    if (hex.length % 2 != 0) {
      hex = '0$hex';
    }

    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return result;
  }
}
