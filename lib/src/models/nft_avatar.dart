import 'dart:convert';

/// Pointer stored in the `profile.avatar.nft` chain record.
///
/// A non-NFT-aware consumer ignores this entirely and reads `profile.avatar`
/// (the plain fallback URL). NFT-aware code (the contact icon) reads this to
/// resolve the artwork and verify ownership.
///
/// CAIP-19 shape it maps to: `eip155:{chain}/{erc721|erc1155}:{contract}/{tokenId}`.
class NftAvatarRef {
  /// CAIP-2 namespace: `'eip155'` (EVM, default) or `'solana'`. Discriminates
  /// which fields are meaningful and which resolver/ownership path runs.
  final String namespace;

  /// CAIP-2 numeric chain id (4489 = PublicOS; also 1/10/137/8453/42161).
  /// EVM only; `0`/unused for Solana.
  final int chain;

  /// `'erc721'` | `'erc1155'`. EVM only; empty for Solana.
  final String standard;

  /// Contract address (`0x…`). EVM only; empty for Solana.
  final String contract;

  /// Token id as a string — a uint256 overflows Dart's int. EVM only; empty
  /// for Solana.
  final String tokenId;

  /// Solana NFT **mint** (base58). Solana only; null for EVM.
  final String? mint;

  /// Provenance hint only; ownership is always re-derived at render time.
  final String? owner;

  const NftAvatarRef({
    required this.chain,
    required this.standard,
    required this.contract,
    required this.tokenId,
    this.namespace = 'eip155',
    this.mint,
    this.owner,
  });

  /// A Solana NFT pointer, keyed on the [mint] (base58). The EVM fields are
  /// placeholders so existing non-null consumers stay safe; gate on [isSolana].
  factory NftAvatarRef.solana({required String mint, String? owner}) =>
      NftAvatarRef(
        namespace: 'solana',
        chain: 0,
        standard: '',
        contract: '',
        tokenId: '',
        mint: mint,
        owner: owner,
      );

  bool get isSolana => namespace == 'solana';

  /// Parse the JSON held in `profile.avatar.nft`. Returns null for a plain-URL
  /// avatar (anything that isn't a JSON object) or malformed JSON.
  static NftAvatarRef? tryParse(String? raw) {
    if (raw == null || !raw.trimLeft().startsWith('{')) return null;
    try {
      return fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Build from an already-decoded map (e.g. the nested `pointer` of a
  /// [VerifiedNftAvatar]). Null if any required field is missing.
  static NftAvatarRef? fromMap(Map<String, dynamic> j) {
    final namespace = (j['namespace'] as String?) ?? 'eip155';
    if (namespace == 'solana') {
      final mint = j['mint'] as String?;
      if (mint == null) return null;
      return NftAvatarRef.solana(mint: mint, owner: j['owner'] as String?);
    }
    final chain = j['chain'];
    final standard = j['standard'];
    final contract = j['contract'];
    final tokenId = j['tokenId'];
    if (chain == null || standard == null || contract == null || tokenId == null) {
      return null;
    }
    return NftAvatarRef(
      chain: (chain as num).toInt(),
      standard: (standard as String).toLowerCase(),
      contract: contract as String,
      tokenId: tokenId.toString(),
      owner: j['owner'] as String?,
    );
  }

  bool get isErc1155 => standard == 'erc1155';

  Map<String, dynamic> toMap() => isSolana
      ? {
          'namespace': 'solana',
          'mint': mint,
          if (owner != null) 'owner': owner,
        }
      : {
          // EVM keeps its original shape (no namespace key) → backward-compatible
          // with refs encoded before the discriminator existed.
          'chain': chain,
          'standard': standard,
          'contract': contract,
          'tokenId': tokenId,
          if (owner != null) 'owner': owner,
        };

  /// JSON for the `profile.avatar.nft` record.
  String encode() => jsonEncode({'v': 2, ...toMap()});

  /// CAIP-19 form the existing resolver helpers understand (EVM); a `solana:`
  /// id for Solana (resolved by mint, not CAIP).
  String toCaip19() =>
      isSolana ? 'solana:$mint' : 'eip155:$chain/$standard:$contract/$tokenId';

  /// True when two refs name the same NFT.
  bool samePointer(NftAvatarRef o) {
    if (namespace != o.namespace) return false;
    if (isSolana) return mint == o.mint;
    return chain == o.chain &&
        standard == o.standard &&
        contract.toLowerCase() == o.contract.toLowerCase() &&
        tokenId == o.tokenId;
  }
}

/// Icon-managed verdict cache, persisted as JSON in the Contacts
/// `verifiedNftAvatar` column (not a chain record).
///
/// Holds the resolved metadata (the image URL lives inside [metadata]), the
/// ownership verdict (drives sparkles/shimmer), and the TTL anchor. The icon
/// reuses this without any chain call while it still [matches] the contact's
/// current `profile.avatar.nft` and is [isFresh]; otherwise it re-resolves and
/// rewrites the column.
class VerifiedNftAvatar {
  /// Which NFT this verdict is for (invalidates the cache if the pointer changed).
  final NftAvatarRef pointer;

  /// Resolved NFT metadata JSON — `image`/`name`/`attributes`/`animation_url`.
  final Map<String, dynamic> metadata;

  /// owner ∈ sessions ∪ linked ∪ safe → eligible for sparkles + shimmer.
  final bool verifiedOwnership;

  /// TTL anchor — when this verdict was last computed.
  final DateTime checkedAt;

  const VerifiedNftAvatar({
    required this.pointer,
    required this.metadata,
    required this.verifiedOwnership,
    required this.checkedAt,
  });

  String? get imageUrl =>
      metadata['image'] as String? ?? metadata['image_url'] as String?;

  String? get animationUrl => metadata['animation_url'] as String?;

  /// Attribute/trait list from the metadata, if any (for the NFT info dialog).
  List<dynamic> get attributes =>
      (metadata['attributes'] as List?) ?? const <dynamic>[];

  bool isFresh(Duration ttl) => DateTime.now().difference(checkedAt) < ttl;

  /// True when this cached verdict still describes [current].
  bool matches(NftAvatarRef current) => pointer.samePointer(current);

  static VerifiedNftAvatar? tryParse(String? raw) {
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final pointerMap = j['pointer'];
      final p = pointerMap is Map
          ? NftAvatarRef.fromMap(pointerMap.cast<String, dynamic>())
          : null;
      if (p == null) return null;
      final meta = j['metadata'];
      return VerifiedNftAvatar(
        pointer: p,
        metadata:
            meta is Map ? meta.cast<String, dynamic>() : <String, dynamic>{},
        verifiedOwnership: j['verifiedOwnership'] as bool? ?? false,
        checkedAt: DateTime.fromMillisecondsSinceEpoch(
            (j['checkedAt'] as num?)?.toInt() ?? 0),
      );
    } catch (_) {
      return null;
    }
  }

  String encode() => jsonEncode({
        'pointer': pointer.toMap(),
        'metadata': metadata,
        'verifiedOwnership': verifiedOwnership,
        'checkedAt': checkedAt.millisecondsSinceEpoch,
      });
}
