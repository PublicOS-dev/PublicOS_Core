import 'dart:convert';
import 'package:publicos_core/src/core/publicos_core.dart';
import 'package:publicos_core/src/utils/log.dart';
import 'package:web3dart/json_rpc.dart' show RPCError;
import 'package:web3dart/web3dart.dart' show TransactionReceipt, Web3Client;

/// Shared transaction utilities for receipt-based confirmation.
class TxUtils {
  static const _tag = 'TxUtils';

  // Solidity built-in error selectors.
  static const _errorStringSelector = '08c379a0'; // Error(string)
  static const _panicSelector = '4e487b71';        // Panic(uint256)

  /// Try to extract a human-readable revert reason from a contract write
  /// failure. Handles three shapes commonly seen across nodes:
  ///
  /// 1. ABI-encoded `Error(string)` in `RPCError.data` (Nethermind, Geth).
  /// 2. Reason embedded in the message after "execution reverted:".
  /// 3. ABI-encoded `Panic(uint256)` (decoded to a known panic code label).
  ///
  /// Returns null when no decodable reason is found — caller should fall
  /// back to a generic message.
  static String? decodeRevertReason(Object error) {
    String? hexData;
    String? message;

    if (error is RPCError) {
      message = error.message;
      final d = error.data;
      if (d is String) {
        hexData = d;
      } else if (d is Map && d['data'] is String) {
        hexData = d['data'] as String;
      }
    } else {
      message = error.toString();
    }

    if (hexData != null) {
      final reason = _decodeAbiError(hexData);
      if (reason != null && reason.isNotEmpty) return reason;
    }

    {
      const marker = 'execution reverted:';
      final idx = message.indexOf(marker);
      if (idx >= 0) {
        final tail = message.substring(idx + marker.length).trim();
        // Strip surrounding quotes some nodes add.
        final stripped = tail.replaceAll(RegExp(r'^"|"$'), '');
        if (stripped.isNotEmpty) return stripped;
      }
    }

    return null;
  }

  static String? _decodeAbiError(String hex) {
    var h = hex.startsWith('0x') ? hex.substring(2) : hex;
    if (h.length < 8) return null;
    final selector = h.substring(0, 8).toLowerCase();

    if (selector == _errorStringSelector) {
      // After selector: 32-byte offset, 32-byte length, then UTF-8 bytes.
      if (h.length < 8 + 64 + 64) return null;
      try {
        final length = int.parse(h.substring(72, 136), radix: 16);
        if (length == 0) return '';
        final bytesEnd = 136 + (length * 2);
        if (h.length < bytesEnd) return null;
        final bytes = <int>[];
        for (int i = 136; i < bytesEnd; i += 2) {
          bytes.add(int.parse(h.substring(i, i + 2), radix: 16));
        }
        return utf8.decode(bytes, allowMalformed: true);
      } catch (e) {
        Log.w(_tag, 'Failed to decode Error(string) data: $e');
        return null;
      }
    }

    if (selector == _panicSelector) {
      if (h.length < 8 + 64) return null;
      try {
        final code = int.parse(h.substring(8, 72), radix: 16);
        return _panicLabel(code);
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  /// Translate a raw revert reason (as returned by [decodeRevertReason] or
  /// found in `PublicOS.lastError`) into user-facing copy. Strips the
  /// `ContractName: ` prefix Solidity convention adds, and maps a small
  /// set of well-known phrases to friendlier sentences. When [raw] is null
  /// or empty, returns [fallback]. Anything that doesn't match a known
  /// phrase falls through with just the prefix stripped — better than
  /// surfacing `RPCError: got code -32000 ...` to the user, which carries
  /// no signal beyond "the chain said no".
  static String humanizeRevertReason(String? raw, {String fallback = 'The chain rejected the transaction.'}) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    var msg = raw.trim();

    // If we got a raw RPCError.toString() (decoder returned null), pull the
    // reason out of the typical `got code -32000 with msg "..."` shape.
    final withMsg = RegExp(r'with msg "([^"]+)"').firstMatch(msg);
    if (withMsg != null) {
      msg = withMsg.group(1)!.trim();
    }
    // Some nodes send `execution reverted: <reason>` inside the message.
    const marker = 'execution reverted:';
    final idx = msg.indexOf(marker);
    if (idx >= 0) {
      msg = msg.substring(idx + marker.length).trim();
    } else if (msg.toLowerCase() == 'execution reverted') {
      // No reason at all — best we can do is generic.
      return fallback;
    }
    msg = msg.replaceAll(RegExp(r'^"|"$'), '');

    // Known AccountManager + AccountMemory + DisplayNameValidator phrases.
    const map = <String, String>{
      'AccountManager: Account creation paused':
          'Account creation is paused right now.',
      'AccountManager: Display name cannot be empty':
          'Username can\'t be empty.',
      'AccountManager: Minter must be citizen':
          'Only citizens can create new accounts. Get vouched in first.',
      'AccountManager: Display name fails charset/tier':
          'That username doesn\'t fit the rules (length, charset, or leading character).',
      'AccountManager: Display name already taken':
          'That username is already taken.',
      'AccountManager: Display name in cooldown or reserved':
          'That username is reserved or in cooldown — try another.',
      'AccountManager: Name cooldown active':
          'That username is in cooldown — try another.',
      'AccountManager: Rename quota exhausted':
          'You\'ve used your free name change for this year and have no bonus left.',
      'AccountManager: NotRegisteredSender':
          'This wallet isn\'t registered as a session of any account.',
      // Org creation (createOrg).
      'AccountManager: Org creation rate-limited':
          'You created an org recently — there\'s a cooldown before you can create another.',
      'AccountManager: Org must have initial members':
          'An org needs at least one member.',
      'AccountManager: Initial threshold must be positive':
          'The voting threshold must be at least 1.',
      'AccountManager: Initial threshold cannot exceed member count':
          'The voting threshold can\'t be higher than the number of members.',
      'AccountManager: Initial member is not a valid individual account':
          'One of the members isn\'t a valid individual account.',
      'AccountManager: Public org creator must be a citizen':
          'Only citizens can create a public org.',
      'AccountManager: Public org members must be citizens':
          'Every member of a public org must be a citizen.',
      // OrgManager — startVote modifiers (preflight gates).
      'OrgManager: Caller is not a registered session':
          'Your wallet isn\'t a registered session of any account.',
      'OrgManager: Caller\'s account is not a member of this org':
          'You\'re not a member of this org — only members can start a vote.',
      'OrgManager: Target address is not an org account':
          'That address isn\'t an org account.',
      'OrgManager: Vote already active for this org':
          'There\'s already an active vote on this org — wait for it to resolve before starting another.',
      // OrgManager — ADD_MEMBER preflight (_validateVoteParams).
      'OrgManager: Invalid member address':
          'The selected member address is invalid.',
      'OrgManager: Address is already a member':
          'That account is already a member.',
      'OrgManager: memberToAdd must be a valid individual account':
          'You can only add an individual account as a member, not an org account.',
      'OrgManager: CitizenshipManager not registered':
          'Citizenship check unavailable right now — try again later.',
      'OrgManager: Public org can only add citizen members':
          'This is a public org — every new member must be a citizen.',
      // OrgManager — REMOVE_MEMBER preflight.
      'OrgManager: Address is not a member':
          'That account isn\'t a member.',
      'OrgManager: Cannot remove the last member':
          'You can\'t remove the last member of an org.',
      'OrgManager: Removal would violate threshold rule':
          'Removing them would leave fewer members than the voting threshold — lower the threshold first.',
      // OrgStorage downstream (safety net — shouldn\'t hit if preflight passes).
      'OrgStorage: Org not initialized':
          'This org isn\'t initialized.',
      'OrgStorage: Address is already a member':
          'That account is already a member.',
      'OrgStorage: Address is not a member':
          'That account isn\'t a member.',
      'OrgStorage: Invalid member address':
          'The selected member address is invalid.',
    };
    final mapped = map[msg];
    if (mapped != null) return mapped;

    // Generic prefix strip ("ContractName: actual reason").
    final prefix = RegExp(r'^[A-Z][A-Za-z0-9_]+:\s*');
    return msg.replaceFirst(prefix, '');
  }

  static String _panicLabel(int code) {
    switch (code) {
      case 0x01: return 'Panic: assertion failed';
      case 0x11: return 'Panic: arithmetic overflow';
      case 0x12: return 'Panic: division by zero';
      case 0x21: return 'Panic: invalid enum conversion';
      case 0x22: return 'Panic: invalid storage byte array';
      case 0x31: return 'Panic: pop on empty array';
      case 0x32: return 'Panic: array out of bounds';
      case 0x41: return 'Panic: out of memory';
      case 0x51: return 'Panic: zero-initialized internal function called';
      default:   return 'Panic: code 0x${code.toRadixString(16)}';
    }
  }

  /// Poll [eth_getTransactionReceipt] until the tx is mined or timeout.
  /// Returns the [TransactionReceipt] when one is found (success OR revert);
  /// returns null on timeout or repeated RPC error.
  ///
  /// Polling is adaptive: every [fastInterval] for the first [fastPhase]
  /// (so a tx that lands in the next block or two is noticed almost
  /// immediately, instead of up to a full second late), then backs off to
  /// [slowInterval] so a genuinely stuck tx doesn't hammer the node for the
  /// whole [timeout] window. The dominant wait is block time, not this poll;
  /// shortening the detection tail is the free half of the fix.
  ///
  /// Use this when the caller needs the receipt itself (logs, block number,
  /// status discrimination). For a simple confirmed/failed bool, use
  /// [waitForReceipt], which delegates here.
  ///
  /// [client] defaults to the live PublicOS client (chain 4489). Pass one
  /// explicitly to wait on a FOREIGN chain — paid-feed subscriptions confirm on
  /// Base or Polygon, and polling 4489 for a Base tx hash would simply time out
  /// after 40 seconds and report a successful payment as failed.
  static Future<TransactionReceipt?> waitForReceiptObject(
    String txHash, {
    String label = '',
    Web3Client? client,
    Duration timeout = const Duration(seconds: 40),
    Duration fastInterval = const Duration(milliseconds: 250),
    Duration slowInterval = const Duration(seconds: 1),
    Duration fastPhase = const Duration(seconds: 6),
  }) async {
    final start = DateTime.now();
    int polls = 0;
    final web3 = client ?? PublicOS.web3Client;

    while (DateTime.now().difference(start) < timeout) {
      try {
        final receipt = await web3.getTransactionReceipt(txHash);
        polls++;

        if (receipt != null) {
          final success = receipt.status ?? false;
          if (success) {
            Log.i(_tag, '$label confirmed in block ${receipt.blockNumber} ($polls polls, ${DateTime.now().difference(start).inMilliseconds}ms)');
          } else {
            Log.e(_tag, '$label REVERTED in block ${receipt.blockNumber} ($polls polls)');
          }
          return receipt;
        }
      } catch (e) {
        Log.w(_tag, '$label receipt poll error: $e');
      }

      final elapsed = DateTime.now().difference(start);
      await Future.delayed(elapsed < fastPhase ? fastInterval : slowInterval);
    }

    Log.e(_tag, '$label receipt timeout after ${timeout.inSeconds}s ($polls polls) — treating as failed');
    return null;
  }

  /// Convenience wrapper around [waitForReceiptObject] for callers that only
  /// need to know "confirmed or not". Returns true iff a receipt arrived with
  /// status == true; false on revert, timeout, or RPC error.
  static Future<bool> waitForReceipt(
    String txHash, {
    String label = '',
    Web3Client? client,
    Duration timeout = const Duration(seconds: 40),
    Duration fastInterval = const Duration(milliseconds: 250),
    Duration slowInterval = const Duration(seconds: 1),
    Duration fastPhase = const Duration(seconds: 6),
  }) async {
    final receipt = await waitForReceiptObject(
      txHash,
      label: label,
      client: client,
      timeout: timeout,
      fastInterval: fastInterval,
      slowInterval: slowInterval,
      fastPhase: fastPhase,
    );
    return receipt?.status ?? false;
  }
}
