import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/digests/sha256.dart';

import 'base58.dart';
import 'ed25519.dart';

/// Reads Solana NFT metadata from the **Metaplex Token-Metadata on-chain
/// program** — the de-facto standard account where ~every Solana NFT stores its
/// name/symbol/uri. This is NOT a Metaplex SDK/API/service: we derive the
/// program-derived account address and Borsh-decode its raw bytes ourselves
/// (the only Metaplex footprint is the program-id constant below). Ownership is
/// pure SPL Token and lives in `PublicOSWallets`; this file is metadata only.

/// Metaplex Token-Metadata program id (mainnet) — an on-chain program address,
/// like a contract address. No code/key/service is pulled from it.
const String tokenMetadataProgram =
    'metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s';

Uint8List _sha256(Uint8List d) => SHA256Digest().process(d);

/// Metaplex metadata PDA for [mintBase58]:
/// `findProgramAddress(["metadata", PROGRAM, mint], PROGRAM)` — sha256 over
/// (seeds ‖ bump ‖ programId ‖ "ProgramDerivedAddress"), bump 255→0, first
/// result OFF the ed25519 curve. Returns the PDA as base58.
String metadataPda(String mintBase58) {
  final program = base58Decode(tokenMetadataProgram);
  final mint = base58Decode(mintBase58);
  final prefix = Uint8List.fromList('metadata'.codeUnits);
  final tag = Uint8List.fromList('ProgramDerivedAddress'.codeUnits);
  for (int bump = 255; bump >= 0; bump--) {
    final buf = Uint8List.fromList([
      ...prefix, ...program, ...mint, // seeds
      bump, // bump seed
      ...program, // programId
      ...tag, // PDA marker
    ]);
    if (!ed25519IsOnCurve(_sha256(buf))) {
      return base58Encode(_sha256(buf));
    }
  }
  throw StateError('no off-curve PDA found');
}

/// Parse name/symbol/uri from a Metaplex Metadata account (Borsh): skip
/// key(1) + updateAuthority(32) + mint(32), then read the name/symbol/uri
/// strings (`u32 len (LE) + bytes`, null-padded).
({String name, String symbol, String uri}) parseSolanaMetadata(Uint8List data) {
  int o = 1 + 32 + 32;
  String readStr() {
    final len = data[o] |
        (data[o + 1] << 8) |
        (data[o + 2] << 16) |
        (data[o + 3] << 24);
    o += 4;
    final bytes = data.sublist(o, o + len).where((b) => b != 0).toList();
    o += len;
    return utf8.decode(bytes, allowMalformed: true).trim();
  }

  final name = readStr();
  final symbol = readStr();
  final uri = readStr();
  return (name: name, symbol: symbol, uri: uri);
}
