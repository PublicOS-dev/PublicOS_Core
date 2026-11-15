// EIP-712 typed-data digest builder for the client consent
// typehashes (2 account consents + the wallet link). Domain mirrors Solidity: EIP712("PublicOS","1") in
// AccountManager. Drift between these type strings and the Solidity
// constants is the silent-failure mode (sig verifies on this side,
// reverts on chain). The test test/eip712_typehashes_test.dart reads the
// Solidity source and asserts byte-equal match.

import 'dart:convert';
import 'dart:typed_data';

import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

// =========================================================================
// Type strings — MUST match Solidity AccountManager.sol byte-for-byte.
// =========================================================================

// Agreements: the consent also binds the PROTOCOL agreement version
// the new account accepts (AccountManager reads it from AgreementManager at
// submit time, so sign with the live `currentVersion(1)`).
const String createAccountConsentTypeString =
    'CreateAccountConsent(string displayName,address newSession,uint256 deadline,uint256 protocolVersion)';

// add / recovery-reseed / DAO-full-reset
// share ONE on-chain typehash. The submitter's authority is the gate, not
// the sig; AccountMemory.consentConsumed keeps each key single-use across all
// three paths. MUST match AccountManager.sol SESSION_CONSENT_TYPEHASH.
// `ttl` (seconds, 0 = permanent) is signed by the
// new key. A key is a *session*.
const String sessionConsentTypeString =
    'SessionConsent(address account,address newSession,uint256 ttl,uint256 deadline)';

/// WalletDirectory v2 — proves ownership of a wallet being linked to `account`.
/// MUST match WalletDirectoryManager.LINK_WALLET_TYPEHASH byte-for-byte. Note
/// the domain's `verifyingContract` is the WalletDirectoryManager (not
/// AccountManager), so build the separator with that address.
const String linkWalletConsentTypeString =
    'LinkWallet(address account,bytes32 protocol,bytes walletAddress,uint64 walletChainId,uint256 deadline)';

const String eip712DomainTypeString =
    'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)';

const String eip712DomainName = 'PublicOS';
const String eip712DomainVersion = '1';

// =========================================================================
// Low-level primitives
// =========================================================================

Uint8List _keccakUtf8(String s) =>
    keccak256(Uint8List.fromList(utf8.encode(s)));

Uint8List _uint256BE(BigInt v) {
  final b = Uint8List(32);
  var n = v;
  for (var i = 31; i >= 0; i--) {
    b[i] = (n & BigInt.from(0xff)).toInt();
    n >>= 8;
  }
  return b;
}

Uint8List _addressLeftPad(EthereumAddress addr) {
  final b = Uint8List(32);
  b.setRange(12, 32, addr.value);
  return b;
}

// =========================================================================
// Typehash constants — exposed for the drift fixture
// =========================================================================

Uint8List get createAccountTypehash => _keccakUtf8(createAccountConsentTypeString);
Uint8List get sessionConsentTypehash => _keccakUtf8(sessionConsentTypeString);
Uint8List get linkWalletTypehash => _keccakUtf8(linkWalletConsentTypeString);

// =========================================================================
// Domain separator + final digest
// =========================================================================

/// EIP-712 domain separator. Solidity equivalent (OpenZeppelin):
///   keccak256(abi.encode(EIP712_DOMAIN_TYPEHASH,
///                        keccak256("PublicOS"),
///                        keccak256("1"),
///                        chainId,
///                        verifyingContract))
Uint8List domainSeparator({
  required int chainId,
  required EthereumAddress verifyingContract,
}) {
  final builder = BytesBuilder()
    ..add(_keccakUtf8(eip712DomainTypeString))
    ..add(_keccakUtf8(eip712DomainName))
    ..add(_keccakUtf8(eip712DomainVersion))
    ..add(_uint256BE(BigInt.from(chainId)))
    ..add(_addressLeftPad(verifyingContract));
  return keccak256(builder.toBytes());
}

/// Final EIP-712 digest. Solidity: keccak256(0x1901 || domainSep || structHash).
Uint8List finalDigest({
  required Uint8List domainSep,
  required Uint8List structHash,
}) {
  final builder = BytesBuilder()
    ..addByte(0x19)
    ..addByte(0x01)
    ..add(domainSep)
    ..add(structHash);
  return keccak256(builder.toBytes());
}

// =========================================================================
// Per-typehash struct hashers
// =========================================================================

Uint8List createAccountStructHash({
  required String displayName,
  required EthereumAddress newSession,
  required BigInt deadline,
  required BigInt protocolVersion,
}) {
  final builder = BytesBuilder()
    ..add(createAccountTypehash)
    ..add(_keccakUtf8(displayName))
    ..add(_addressLeftPad(newSession))
    ..add(_uint256BE(deadline))
    ..add(_uint256BE(protocolVersion));
  return keccak256(builder.toBytes());
}

/// Struct hash for the shared `SessionConsent` message — used by addSession,
/// recovery reseed, and DAO full-reset. The field is
/// named `newSession` everywhere; a caller signing a "sole session" just passes
/// that address as `newSession`. `ttl` is 0 (permanent) on the reseed and
/// full-reset paths; addSession signs the ttl the caller chose.
Uint8List sessionConsentStructHash({
  required EthereumAddress account,
  required EthereumAddress newSession,
  required BigInt ttl,
  required BigInt deadline,
}) {
  final builder = BytesBuilder()
    ..add(sessionConsentTypehash)
    ..add(_addressLeftPad(account))
    ..add(_addressLeftPad(newSession))
    ..add(_uint256BE(ttl))
    ..add(_uint256BE(deadline));
  return keccak256(builder.toBytes());
}

/// Struct hash for the WalletDirectory v2 `LinkWallet` message.
/// `protocol` is the 32-byte `bytes32` protocol id (e.g. from `encodeProtocol`);
/// it is encoded directly. `walletAddress` is the raw address bytes (`bytes`),
/// so it is hashed (`keccak256`) per the EIP-712 dynamic-type rule. `walletChainId`
/// is a `uint64` but ABI-encodes to a full 32-byte word.
Uint8List linkWalletStructHash({
  required EthereumAddress account,
  required Uint8List protocol,
  required Uint8List walletAddress,
  required int walletChainId,
  required BigInt deadline,
}) {
  assert(protocol.length == 32, 'protocol must be bytes32 (32 bytes)');
  final builder = BytesBuilder()
    ..add(linkWalletTypehash)
    ..add(_addressLeftPad(account))
    ..add(protocol)
    ..add(keccak256(walletAddress))
    ..add(_uint256BE(BigInt.from(walletChainId)))
    ..add(_uint256BE(deadline));
  return keccak256(builder.toBytes());
}

// =========================================================================
// Sign a digest with an EthPrivateKey, return 65-byte (r || s || v).
// v normalized to 27/28 (matches what _verifyConsent →
// SignatureChecker.isValidSignatureNow → ECDSA.recover expects).
// =========================================================================

Uint8List signDigest(Uint8List digest, EthPrivateKey key) {
  final privBytes = _privateKeyBytes(key);
  final MsgSignature s = sign(digest, privBytes);
  final out = Uint8List(65);
  _writeBigInt32(out, 0, s.r);
  _writeBigInt32(out, 32, s.s);
  out[64] = s.v < 27 ? s.v + 27 : s.v;
  return out;
}

Uint8List _privateKeyBytes(EthPrivateKey key) {
  final hex = key.privateKeyInt.toRadixString(16).padLeft(64, '0');
  final out = Uint8List(32);
  for (var i = 0; i < 32; i++) {
    out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}

void _writeBigInt32(Uint8List buf, int offset, BigInt v) {
  var n = v;
  for (var i = 31; i >= 0; i--) {
    buf[offset + i] = (n & BigInt.from(0xff)).toInt();
    n >>= 8;
  }
}
