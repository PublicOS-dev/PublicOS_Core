import 'package:publicos_core/src/core/publicos_core.dart';
import 'package:publicos_core/src/core/extensions/publicos_bsp.dart';
import 'package:publicos_core/src/utils/log.dart';
import 'package:publicos_core/src/utils/tx_utils.dart';
import 'package:wallet/wallet.dart';

/// Agreements: root
/// publishes versioned texts per KIND; an account's acceptance is recorded on
/// chain. The PROTOCOL agreement is accepted inside `createAccount` (the
/// consent binds the version), the CITIZEN one inside the citizenship claim
/// ([PublicOSAccounts.claimCitizenship]); the OPERATOR one is accepted here
/// before registering a BSP / SSP. A newer version means "not agreed" again.
extension PublicOSAgreements on PublicOS {
  static const _tag = 'Agreements';

  /// AgreementManager kinds (Solidity constants).
  static const int kindProtocol = 1;
  static const int kindOperator = 2;
  static const int kindCitizen = 3;

  /// The current version of [kind] (0 = nothing published yet).
  static Future<BigInt> currentVersion(int kind) =>
      PublicOSBsp.agreementManagerContract.currentVersion((kind: BigInt.from(kind)));

  /// The CURRENT text of [kind], read off chain storage (`AgreementMemory.getVersion`):
  /// the version `currentVersion` names and its full text. `null` when nothing
  /// is published for that kind. Read by the citizen claim sheet.
  static Future<({BigInt version, String text})?> currentText(int kind) async {
    final version = await currentVersion(kind);
    if (version == BigInt.zero) return null;
    final raw = await PublicOSBsp.agreementMemoryContract
        .getVersion((kind: BigInt.from(kind), version: version));
    // Struct Version { string text; bytes32 textHash; uint64 publishedAt; uint64 validFrom }
    // comes back as a positional list.
    final fields = raw as List<dynamic>;
    return (version: version, text: fields[0] as String);
  }

  /// True when [account] has accepted the CURRENT version of [kind] — or when
  /// nothing is published for that kind (the contract answers yes then).
  static Future<bool> hasAgreed(int kind, EthereumAddress account) async {
    final sel = await PublicOSBsp.agreementManagerContract
        .checkAgreed((kind: BigInt.from(kind), account: account));
    return sel.any((b) => b != 0);
  }

  /// Accept the current version of [kind] as the active session's account.
  /// Reads the version first so the call always names the one on chain.
  static Future<bool> agree(int kind) async {
    if (!PublicOS.isAuthenticated || PublicOS.currentBlockchainPrivateKey == null) {
      Log.w(_tag, 'Authentication required');
      return false;
    }
    try {
      final version = await currentVersion(kind);
      if (version == BigInt.zero) {
        PublicOS.lastError = 'agree: nothing published for kind $kind';
        return false;
      }
      final txHash = await PublicOSBsp.agreementManagerContract.agree(
        (kind: BigInt.from(kind), version: version),
        credentials: PublicOS.currentBlockchainPrivateKey!,
      );
      return await TxUtils.waitForReceipt(txHash, label: 'agree(kind $kind, v$version)');
    } catch (e) {
      PublicOS.lastError = TxUtils.decodeRevertReason(e) ?? e.toString();
      Log.e(_tag, 'agree(kind $kind) failed: $e');
      return false;
    }
  }
}
