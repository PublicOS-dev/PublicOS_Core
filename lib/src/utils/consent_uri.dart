// Consent URI codec — encodes a signed EIP-712 consent payload into a
// `publicos-claim:<base64url-cbor>` URI for QR transfer between the new
// device (signer) and the sponsor (submitter).
//
// Payload (5-field CBOR map, single-char keys to keep the QR small):
//   k (uint8)        — kind: 0 = new-account, 1 = add-session
//   n (bytes20)      — newSession address (the consenting key)
//   d (uint40)       — deadline (Unix seconds; uint40 lasts to 2104)
//   s (bytes64)      — EIP-2098 compact sig (r || (s|v-bit))
//   a (string|bytes20) — when k=0: chosen displayName (UTF-8 string)
//                        when k=1: sponsor account address (bytes20)
//   e (uint)         — OPTIONAL, k=1 only (key expiry): the ttl in seconds the
//                      consent was signed over; absent / 0 = permanent key. The
//                      sponsor must submit addSession with this same ttl.
//
// Why CBOR not JSON: 30%+ smaller for this shape and lets us add optional
// fields later (recoveryContacts[], preferences) without versioning the URI
// scheme — readers tolerate unknown keys. Hand-rolled (no cbor dep) because
// the payload shape is tiny and well-defined.
//
// Why EIP-2098 compact sig: 64 bytes instead of 65 — saves 1 byte and
// matches the spec's QR size budget table. OZ SignatureChecker (used by
// AccountManager._verifyConsent) accepts both 64 and 65 byte sigs natively.

import 'dart:convert';
import 'dart:typed_data';

import 'package:wallet/wallet.dart' show EthereumAddress;

const String consentUriScheme = 'publicos-claim';

enum ConsentKind {
  newAccount, // k=0; `a` is a displayName string
  addSession,  // k=1; `a` is an account address (bytes20)
}

/// Decoded payload — the result of [decodeConsentUri].
class ConsentPayload {
  final ConsentKind kind;
  final EthereumAddress newSession;
  final BigInt deadline;
  /// EIP-2098 compact (64 bytes): r || (s with v-bit packed into high bit).
  /// AccountManager's SignatureChecker accepts this directly; clients that
  /// need the 65-byte (r||s||v) form can expand via [expandedSig].
  final Uint8List compactSig;
  final String? displayName;
  final EthereumAddress? account;
  /// k=1 only: the ttl (seconds) signed into the SessionConsent; 0 = permanent.
  BigInt get ttl => _ttl ?? BigInt.zero;
  final BigInt? _ttl;

  const ConsentPayload._({
    required this.kind,
    required this.newSession,
    required this.deadline,
    required this.compactSig,
    this.displayName,
    this.account,
    BigInt? ttl,
  }) : _ttl = ttl;

  /// Expand the 64-byte compact sig into the 65-byte (r||s||v) form. v is
  /// 27 or 28. Useful for clients that prefer the legacy form.
  Uint8List expandedSig() {
    final out = Uint8List(65);
    out.setRange(0, 32, compactSig.sublist(0, 32));        // r
    final sBytes = Uint8List.fromList(compactSig.sublist(32, 64));
    final vBit = (sBytes[0] & 0x80) >> 7;
    sBytes[0] &= 0x7f;                                     // clear high bit
    out.setRange(32, 64, sBytes);
    out[64] = vBit == 0 ? 27 : 28;
    return out;
  }
}

/// Pack a 65-byte (r||s||v) sig into 64-byte EIP-2098 compact form. v must
/// be 27 or 28 (the form [signDigest] in eip712_consent.dart emits).
Uint8List toCompactSig(Uint8List rsv) {
  if (rsv.length != 65) {
    throw ArgumentError('expected 65-byte sig, got ${rsv.length}');
  }
  final v = rsv[64];
  if (v != 27 && v != 28) {
    throw ArgumentError('expected v in {27,28}, got $v');
  }
  final out = Uint8List(64);
  out.setRange(0, 32, rsv.sublist(0, 32));    // r
  out.setRange(32, 64, rsv.sublist(32, 64));  // s (top bit guaranteed 0 for secp256k1 normalized)
  if (v == 28) {
    out[32] |= 0x80;
  }
  return out;
}

/// Encode a `publicos-claim:` URI for the new-account variant.
String encodeNewAccountUri({
  required EthereumAddress newSession,
  required BigInt deadline,
  required Uint8List compactSig,
  required String displayName,
}) {
  final cbor = _encodeMap([
    _kv('k', _uint(0)),
    _kv('n', _bytes(Uint8List.fromList(newSession.value))),
    _kv('d', _uint(deadline.toInt())),
    _kv('s', _bytes(compactSig)),
    _kv('a', _textString(displayName)),
  ]);
  return '$consentUriScheme:${base64Url.encode(cbor).replaceAll('=', '')}';
}

/// Encode a `publicos-claim:` URI for the add-session variant.
String encodeAddSessionUri({
  required EthereumAddress newSession,
  required BigInt deadline,
  required Uint8List compactSig,
  required EthereumAddress account,
  BigInt? ttl, // key expiry: omitted when 0 / null (permanent) to keep the QR small
}) {
  final cbor = _encodeMap([
    _kv('k', _uint(1)),
    _kv('n', _bytes(Uint8List.fromList(newSession.value))),
    _kv('d', _uint(deadline.toInt())),
    _kv('s', _bytes(compactSig)),
    _kv('a', _bytes(Uint8List.fromList(account.value))),
    if (ttl != null && ttl > BigInt.zero) _kv('e', _uint(ttl.toInt())),
  ]);
  return '$consentUriScheme:${base64Url.encode(cbor).replaceAll('=', '')}';
}

/// Decode a `publicos-claim:<base64url-cbor>` URI. Throws [FormatException]
/// on any malformed input — caller should catch and show an error sheet.
ConsentPayload decodeConsentUri(String uri) {
  final prefix = '$consentUriScheme:';
  if (!uri.startsWith(prefix)) {
    throw const FormatException('Not a publicos-claim URI');
  }
  var b64 = uri.substring(prefix.length);
  // Pad up to a multiple of 4 (we strip '=' on encode).
  while (b64.length % 4 != 0) {
    b64 += '=';
  }
  final cbor = base64Url.decode(b64);
  final map = _decodeMap(cbor);

  final k = map['k'];
  final n = map['n'];
  final d = map['d'];
  final s = map['s'];
  final a = map['a'];
  if (k is! int || n is! Uint8List || n.length != 20 ||
      d is! int || s is! Uint8List || s.length != 64) {
    throw const FormatException('Malformed consent payload');
  }
  final kind = k == 0 ? ConsentKind.newAccount : ConsentKind.addSession;
  final newSession = EthereumAddress(n);
  final deadline = BigInt.from(d);

  if (kind == ConsentKind.newAccount) {
    if (a is! String || a.isEmpty) {
      throw const FormatException('new-account payload missing displayName');
    }
    return ConsentPayload._(
      kind: kind,
      newSession: newSession,
      deadline: deadline,
      compactSig: s,
      displayName: a,
    );
  } else {
    if (a is! Uint8List || a.length != 20) {
      throw const FormatException('add-session payload missing account address');
    }
    final e = map['e'];
    if (e != null && e is! int) {
      throw const FormatException('add-session payload has a malformed ttl');
    }
    return ConsentPayload._(
      kind: kind,
      newSession: newSession,
      deadline: deadline,
      compactSig: s,
      account: EthereumAddress(a),
      ttl: e == null ? null : BigInt.from(e as int),
    );
  }
}

// =========================================================================
// Minimal CBOR encoder/decoder — single-key string maps with primitive
// value types (uint, bytes, text). NOT a general-purpose codec.
// =========================================================================

/// Build a CBOR major-type | argument prefix. `mt` is 0-7 (3 bits).
Uint8List _typeArg(int mt, int n) {
  final tag = mt << 5;
  if (n < 24) return Uint8List.fromList([tag | n]);
  if (n < 0x100) return Uint8List.fromList([tag | 24, n]);
  if (n < 0x10000) return Uint8List.fromList([tag | 25, n >> 8, n & 0xff]);
  if (n < 0x100000000) {
    return Uint8List.fromList([
      tag | 26,
      (n >> 24) & 0xff,
      (n >> 16) & 0xff,
      (n >> 8) & 0xff,
      n & 0xff,
    ]);
  }
  // uint64 path — used only for deadlines past 2106 (i.e. never in practice).
  final hi = (n >> 32) & 0xffffffff;
  final lo = n & 0xffffffff;
  return Uint8List.fromList([
    tag | 27,
    (hi >> 24) & 0xff, (hi >> 16) & 0xff, (hi >> 8) & 0xff, hi & 0xff,
    (lo >> 24) & 0xff, (lo >> 16) & 0xff, (lo >> 8) & 0xff, lo & 0xff,
  ]);
}

Uint8List _uint(int n) => _typeArg(0, n);
Uint8List _bytes(Uint8List b) {
  final h = _typeArg(2, b.length);
  return Uint8List.fromList([...h, ...b]);
}
Uint8List _textString(String s) {
  final utf = utf8.encode(s);
  final h = _typeArg(3, utf.length);
  return Uint8List.fromList([...h, ...utf]);
}

Uint8List _kv(String key, Uint8List value) {
  final k = _textString(key);
  return Uint8List.fromList([...k, ...value]);
}

Uint8List _encodeMap(List<Uint8List> kvs) {
  final h = _typeArg(5, kvs.length);
  final body = BytesBuilder();
  for (final kv in kvs) {
    body.add(kv);
  }
  return Uint8List.fromList([...h, ...body.toBytes()]);
}

Map<String, Object?> _decodeMap(Uint8List buf) {
  final r = _Reader(buf);
  final (mt, n) = r.readHeader();
  if (mt != 5) {
    throw const FormatException('CBOR root must be a map');
  }
  final out = <String, Object?>{};
  for (var i = 0; i < n; i++) {
    final key = r.readValue();
    final val = r.readValue();
    if (key is! String) throw const FormatException('CBOR map key must be string');
    out[key] = val;
  }
  return out;
}

class _Reader {
  final Uint8List buf;
  int pos = 0;
  _Reader(this.buf);

  (int mt, int n) readHeader() {
    final b = buf[pos++];
    final mt = b >> 5;
    final info = b & 0x1f;
    if (info < 24) return (mt, info);
    if (info == 24) return (mt, buf[pos++]);
    if (info == 25) {
      final v = (buf[pos] << 8) | buf[pos + 1];
      pos += 2;
      return (mt, v);
    }
    if (info == 26) {
      final v = (buf[pos] << 24) |
          (buf[pos + 1] << 16) |
          (buf[pos + 2] << 8) |
          buf[pos + 3];
      pos += 4;
      return (mt, v);
    }
    if (info == 27) {
      // Treat as int; in practice we never write 64-bit values for these
      // payloads. If this fires, caller is decoding a corrupt or
      // unexpected payload.
      var v = 0;
      for (var i = 0; i < 8; i++) {
        v = (v << 8) | buf[pos + i];
      }
      pos += 8;
      return (mt, v);
    }
    throw const FormatException('Unsupported CBOR length encoding');
  }

  Object? readValue() {
    final (mt, n) = readHeader();
    switch (mt) {
      case 0:
        return n;
      case 2:
        final b = buf.sublist(pos, pos + n);
        pos += n;
        return Uint8List.fromList(b);
      case 3:
        final s = utf8.decode(buf.sublist(pos, pos + n));
        pos += n;
        return s;
      default:
        throw FormatException('Unsupported CBOR major type $mt');
    }
  }
}
