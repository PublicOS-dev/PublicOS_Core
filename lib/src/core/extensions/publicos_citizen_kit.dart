import 'dart:async';
import 'dart:convert';

import 'package:publicos_core/src/contracts/CitizenKit.g.dart';
import 'package:publicos_core/src/core/core.dart';
import 'package:publicos_core/src/utils/log.dart';
import 'package:publicos_core/src/utils/tx_utils.dart';
import 'package:wallet/wallet.dart';

/// The PublicOS **citizen kit** — the thirteen-piece art collection a citizen may
/// mint once, and the tier-2 counterpart to [PublicOSSoulbound].
///
/// | tile | piece | shape |
/// |------|-------|-------|
/// | `0`  | banner | `3000x1000` |
/// | `1`  | avatar | `1000x1000` |
/// | `2`  | rule   | `4000x1000`, stretches |
/// | `3`  | spine  | `1000x4000`, stretches |
/// | `4..12` | nine cards | `1000x1000` each, **all different** |
///
/// **The roles line up piece for piece with the soulbound kit**, which is what
/// lets one profile layout serve both tiers. The single difference is the square
/// pool: tier 1 has *one* card reused, tier 2 has *nine* distinct ones.
///
/// Three things separate it from its sibling, all of them consequences of one
/// decision — **the account rides inside the token id**, `(uint160(account) << 8) | tile`:
///
///   * **ids are `pure`.** [tokenIdsFor] is arithmetic, not a chain read.
///   * **the art cannot repaint for a buyer**, so unlike tier 1 this token is
///     transferable without a stored seed.
///   * **once-per-citizen enforces itself** — a second mint collides on ids
///     already in existence and reverts inside `_safeMint`.
extension PublicOSCitizenKit on PublicOS {
  static const _tag = 'CitizenKit';

  /// ⚠ **A hardcoded address, by necessity** — the same non-module class as
  /// [PublicOSSoulbound.kitContractAddress]. No `ModuleRegistry` key resolves it,
  /// it appears in no address artifact, and a chain redeploy kills it silently.
  ///
  /// **A dead deploy still answers and still renders plausible art — a stale
  /// pin SUCCEEDS AND LIES.** Superseded builds render byte-identically to this
  /// one on purpose (the art is a pure function of the account), so *looking at
  /// the picture proves nothing*.
  ///
  /// **The tell is the `isMinted` selector.** Every earlier deploy reverts on it;
  /// only this one answers. Probe the selector, not the art.
  ///
  /// The machine-readable record is
  /// `ContactOS_Contracts/scripts/nft/citizen-deployed.json`.
  static const String kitContractAddress =
      '0xbec5dab26D1F7873E922CE14Ed39F382213C0F46';

  /// Number of pieces in one kit. Mirrors the contract's `TILE_COUNT`.
  static const int tilesPerKit = 13;

  /// Tile offsets, by role. The contract's own ordering, not a convention this
  /// file invents — `CitizenKit._tileName` names them in exactly this order.
  static const int bannerTile = 0;
  static const int avatarTile = 1;
  static const int ruleTile = 2; // the horizontal, 4x1
  static const int spineTile = 3; // the vertical, 1x4
  static const int firstCardTile = 4; // nine squares, 4..12

  /// The nine square tiles, in order. Tier 1's single square has nine of these
  /// as its counterpart, which is the only place the two tiers differ in shape.
  static List<int> get cardTiles =>
      List<int>.generate(tilesPerKit - firstCardTile, (i) => firstCardTile + i);

  static CitizenKit get kitContract => CitizenKit(
        address: EthereumAddress.fromHex(kitContractAddress),
        client: PublicOS.web3Client,
        chainId: PublicOS.CHAIN_ID,
      );

  /// The thirteen token ids of [account]'s kit, in tile order.
  ///
  /// **Pure arithmetic — no chain read, no round-trip, and it works for an
  /// account that has never minted.** The contract exposes `tokenIdsFor` for the
  /// same reason, but calling it would be a network hop to recompute a shift and
  /// an or. Mirrors `CitizenKit.tokenIdFor` exactly: `(uint160(account) << 8) | tile`.
  static List<BigInt> tokenIdsFor(EthereumAddress account) {
    final base = _base(account);
    return List<BigInt>.generate(tilesPerKit, (tile) => base | BigInt.from(tile));
  }

  /// The token id of one piece.
  static BigInt tokenIdOf(EthereumAddress account, int tile) {
    assert(tile >= 0 && tile < tilesPerKit, 'tile out of range: $tile');
    return _base(account) | BigInt.from(tile);
  }

  /// `uint160(account) << 8` — the kit's id base, with the low byte left free for
  /// the tile. `without0x` is the unchecksummed form, which is what `radix: 16`
  /// needs; the EIP-55 variants would parse the same but say the wrong thing here,
  /// since this is arithmetic on the address and not a display of it.
  static BigInt _base(EthereumAddress account) =>
      BigInt.parse(account.without0x, radix: 16) << 8;

  /// Whether [account] already holds its citizen kit.
  ///
  /// Returns `null` when the answer could not be established. **`null` is not
  /// `false`:** a caller must never treat an unknown as "go ahead and mint", or a
  /// dead RPC turns into a transaction nobody asked for — and must never treat it
  /// as "already minted" either, or a citizen silently loses their gift.
  ///
  /// This reads the contract's own `isMinted` view rather than catching a revert
  /// from `ownerOf`, which is the entire reason that view was added: a revert
  /// cannot be told apart from a failed call.
  static Future<bool?> isKitMinted(EthereumAddress account) async {
    try {
      return await kitContract.isMinted((account: account));
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'isMinted read failed: $e');
      return null;
    }
  }

  /// Mint [account]'s kit — all thirteen pieces, one transaction, to the MainSafe.
  ///
  /// **Permissionless in who calls it**, deliberately: the recipient is derived
  /// contract-side from the account, so paying someone else's gas is harmless and
  /// the kit cannot be misdirected. The gate is citizenship, checked on chain.
  ///
  /// Returns the transaction hash, or `null` if the send failed. **Reverts when
  /// [account] is not a citizen** (`CitizenshipManager.isCitizen`) — which is a
  /// *different question* from holding a lifetime domain, and the two must never
  /// be substituted for each other. See `PublicOSAccounts.isCitizen`.
  static Future<String?> mintKit(EthereumAddress account) async {
    final key = PublicOS.currentBlockchainPrivateKey;
    if (key == null) {
      Log.w(_tag, 'Cannot mint — no blockchain key loaded');
      return null;
    }
    try {
      final txHash = await kitContract.mint((account: account), credentials: key);

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
          await TxUtils.waitForReceipt(txHash, label: 'CitizenKit.mint');
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

  /// The art for one tile, as a `data:` URI ready to hand to an image widget.
  ///
  /// **Renders for an account that has NOT minted.** That is the whole point of
  /// the contract's `previewSVG`, and it is what lets a screen show a citizen
  /// their exact kit — or hold its shape behind a shimmer — before they commit.
  ///
  /// ⚠ **`tokenURI` is the opposite and cannot stand in here**: it `_requireOwned`s,
  /// so it reverts for an unminted piece. Once the kit exists the normal fetched
  /// path (`PublicOSContacts.resolveNftAvatarData`) serves the same bytes.
  ///
  /// The contract returns a bare `<svg …>` string, unlike `tokenURI`'s wrapped
  /// base64 JSON, so the data URI is assembled here.
  static Future<String?> previewArt(EthereumAddress account, int tile) async {
    if (tile < 0 || tile >= tilesPerKit) {
      Log.w(_tag, 'previewArt: tile $tile out of range');
      return null;
    }
    try {
      final svg = await kitContract.previewSVG(
        (account: account, tile: BigInt.from(tile)),
      );
      if (svg.isEmpty) return null;
      return 'data:image/svg+xml;base64,${base64Encode(utf8.encode(svg))}';
    } catch (e) {
      PublicOS.lastError = e.toString();
      Log.e(_tag, 'previewSVG($tile) read failed: $e');
      return null;
    }
  }

  /// Every piece's art at once, keyed by tile.
  ///
  /// **Issued in parallel**, because thirteen sequential reads is a visible pause
  /// (~2.2 s measured live) and thirteen concurrent ones is not. A tile that fails
  /// is simply absent from the map rather than failing the batch — a partial kit
  /// still draws, and the caller can retry the gaps.
  static Future<Map<int, String>> previewAllArt(EthereumAddress account) async {
    final tiles = List<int>.generate(tilesPerKit, (i) => i);
    final results = await Future.wait(
      tiles.map((t) async => MapEntry(t, await previewArt(account, t))),
    );
    return {
      for (final e in results)
        if (e.value != null) e.key: e.value!,
    };
  }
}
