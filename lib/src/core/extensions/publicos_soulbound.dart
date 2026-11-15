import 'dart:async';

import 'package:publicos_core/src/contracts/SoulboundKit.g.dart';
import 'package:publicos_core/src/core/core.dart';
import 'package:publicos_core/src/utils/log.dart';
import 'package:publicos_core/src/utils/tx_utils.dart';
import 'package:wallet/wallet.dart';

/// The PublicOS **soulbound starter kit** — the five-piece art collection every
/// account is entitled to exactly once.
///
/// A kit is `PIECES = 5` consecutive ERC-721 ids, minted together and held by
/// the account's **MainSafe**, never by the account contract:
///
/// | offset | piece |
/// |--------|-------|
/// | `+0`   | profile picture |
/// | `+1`   | banner |
/// | `+2`   | horizontal card (4×1) |
/// | `+3`   | vertical card (1×4) |
/// | `+4`   | square card (1×1) |
///
/// **Only three of the five are cards.** Any UI promising a card *grid* from
/// this tier is promising something the contract does not mint.
///
/// The art is a pure function of the holder's address with no stored seed,
/// which is why the token is soulbound: `ownerOf` never changing is what keeps
/// the render stable.
extension PublicOSSoulbound on PublicOS {
  static const _tag = 'Soulbound';

  /// ⚠ **A hardcoded address, by necessity.** `SoulboundKit` is deliberately
  /// **not** a `ModuleRegistry` module — no key resolves it, it appears in no
  /// address artifact, and a chain redeploy kills it silently. Dead deploys
  /// still answer with plausible art keyed on the
  /// wrong holder, so a stale pin **succeeds and lies**.
  ///
  /// The tell for a stale pin is the **`mint` selector**, not `ownerOf`: the
  /// live contract has `mint()` (`1249c58b`) and no `mint(address)`. Every
  /// superseded deploy has the reverse.
  static const String kitContractAddress =
      '0xa4066ac324787e0D5d4a75db8cAf1343D789C661';

  /// Number of tokens in one kit. Mirrors the contract's `PIECES`.
  static const int piecesPerKit = 5;

  static SoulboundKit get kitContract => SoulboundKit(
        address: EthereumAddress.fromHex(kitContractAddress),
        client: PublicOS.web3Client,
        chainId: PublicOS.CHAIN_ID,
      );

  /// The wallet that holds (or is due to hold) this account's kit.
  ///
  /// `hasMinted` and `firstTokenOf` are keyed by the **MainSafe**, so every
  /// read here has to resolve it first. An account with no MainSafe can never
  /// hold a kit — the contract itself rejects the mint.
  static Future<EthereumAddress?> kitHolder(EthereumAddress account) async {
    final safe = await PublicOSSafe.getMainSafeAddress(account);
    if (safe == null) return null;
    return EthereumAddress.fromHex(safe);
  }

  /// Whether [account] already holds its kit.
  ///
  /// Returns `null` when the answer could not be established — a failed chain
  /// read, or an account with no MainSafe. **`null` is not `false`:** callers
  /// must never treat an unknown as "go ahead and mint", or a dead RPC turns
  /// into a transaction nobody asked for.
  static Future<bool?> isKitMinted(EthereumAddress account) async {
    try {
      final holder = await kitHolder(account);
      if (holder == null) {
        Log.w(_tag, 'No MainSafe for $account — an account with no Safe cannot hold a kit');
        return null;
      }
      return await kitContract.hasMinted((arg0: holder));
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'hasMinted read failed: $e');
      return null;
    }
  }

  /// The five token ids of [account]'s kit, in piece order, or `null` if the
  /// account has no kit (or the read failed).
  ///
  /// One call: `firstTokenOfAccount` resolves account → MainSafe → first id
  /// contract-side, and the kinds are pure offsets from there. No `tokenURI`
  /// decoding and no enumeration.
  static Future<List<BigInt>?> kitTokenIds(EthereumAddress account) async {
    try {
      final first = await kitContract.firstTokenOfAccount((account: account));
      if (first == BigInt.zero) return null;
      return List<BigInt>.generate(piecesPerKit, (i) => first + BigInt.from(i));
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'firstTokenOfAccount read failed: $e');
      return null;
    }
  }

  /// Mint this client's kit. One per **account**, ever.
  ///
  /// Takes no recipient: the contract derives caller → account → MainSafe
  /// itself, which is what makes the kit un-mintable on anyone else's behalf
  /// and what lets this be fired without a confirmation step.
  ///
  /// Returns the transaction hash, or `null` if the send failed.
  static Future<String?> mintKit() async {
    final key = PublicOS.currentBlockchainPrivateKey;
    if (key == null) {
      Log.w(_tag, 'Cannot mint — no blockchain key loaded');
      return null;
    }
    try {
      final txHash = await kitContract.mint( credentials: key);

      // **Wait for the receipt.** `mint` returns as soon as the node ACCEPTS
      // the transaction, not when it is mined — so a caller that read the
      // kit's state on the next line was querying a chain that had not applied
      // it yet, and got a truthful `false` for a mint that was about to
      // succeed. That is exactly what produced *"Mint sent but isMinted is
      // false"*, and it is why every other write in Core goes through
      // `TxUtils.waitForReceipt` before reporting anything.
      //
      // Returning null on a lost receipt is deliberate: the caller's contract
      // is "a hash means it landed", and half-truths here become latched flags
      // upstream.
      Log.i(_tag, 'mint tx sent: $txHash — waiting for receipt...');
      final confirmed =
          await TxUtils.waitForReceipt(txHash, label: 'SoulboundKit.mint');
      if (!confirmed) {
        Log.w(_tag, 'mint receipt never arrived for $txHash');
        return null;
      }
      return txHash;
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'mint() failed: $e');
      return null;
    }
  }

  /// Make sure [account] has its kit, minting it if it does not.
  ///
  /// **Fire-and-forget by design.** Onboarding calls this the moment the
  /// account is known to be domain-compliant, so that by the time the profile
  /// step renders the kit either exists or the account was never eligible for
  /// one. Nothing downstream waits on it and nothing gates on its result: a
  /// revert, a dead RPC or a missing MainSafe is logged and swallowed, and the
  /// profile step simply finds no kit and writes nothing.
  ///
  /// Returns `true` only when the account demonstrably holds a kit at the end
  /// — whether it already did or this call minted it.
  static Future<bool> ensureKitMinted(EthereumAddress account) async {
    final minted = await isKitMinted(account);

    if (minted == true) {
      Log.d(_tag, 'Soulbound minted already');
      return true;
    }

    // Unknown — a failed read or no MainSafe. Never mint on a maybe.
    if (minted == null) {
      Log.d(_tag, 'Soulbound mint state unknown — not minting');
      return false;
    }

    Log.d(_tag, 'Soulbound not minted');
    Log.d(_tag, 'Minting soulbound');

    final txHash = await mintKit();
    if (txHash == null) {
      Log.d(_tag, 'Soulbound mint failed');
      return false;
    }

    Log.d(_tag, 'Correctly minted soulbound (tx $txHash)');
    return true;
  }
}
