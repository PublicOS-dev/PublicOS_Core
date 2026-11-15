/// Verify-only Ed25519 (RFC 8032), pure `BigInt`.
///
/// We only ever VERIFY public data (public key, message, signature) — there is
/// no secret material on our side — so constant-time execution is not required
/// and a plain BigInt implementation is safe. (The "never roll your own crypto"
/// rule is about signing / secret-key side-channels, which do not apply here.)
/// Correctness is anchored to the official RFC 8032 §7.1 test vectors and to a
/// real Phantom signature; see `test/ed25519_test.dart`.
///
/// Used by `PublicOSWallets.verifySolSignature` for Solana linked-wallet proofs
/// that the chain stores CLAIMED (it cannot verify a foreign curve). No signing,
/// no key generation — verification only.
library;

import 'dart:typed_data';

import 'package:pointycastle/digests/sha512.dart';

Uint8List _sha512(Uint8List data) => SHA512Digest().process(data);

// ---- Curve constants (Ed25519) -------------------------------------------
final BigInt _p = (BigInt.one << 255) - BigInt.from(19);
final BigInt _l =
    (BigInt.one << 252) + BigInt.parse('27742317777372353535851937790883648493');
final BigInt _d = BigInt.parse(
    '37095705934669439343138083508754565189542113879843219016388785533085940283555');
final BigInt _bx = BigInt.parse(
    '15112221349535400772501151409588531511454012693041857206046113283949847762202');
final BigInt _by = BigInt.parse(
    '46316835694926478169428394003475163141307993866256225615783033603165251855960');
final BigInt _sqrtm1 = BigInt.two.modPow((_p - BigInt.one) ~/ BigInt.from(4), _p);
final BigInt _two = BigInt.two;

// ---- Field helpers (results in [0, p)) -----------------------------------
BigInt _fadd(BigInt a, BigInt b) => (a + b) % _p;
BigInt _fsub(BigInt a, BigInt b) => (a - b) % _p;
BigInt _fmul(BigInt a, BigInt b) => (a * b) % _p;

// ---- Extended twisted-Edwards point (X, Y, Z, T) -------------------------
class _Pt {
  final BigInt x, y, z, t;
  _Pt(this.x, this.y, this.z, this.t);
}

_Pt get _identity => _Pt(BigInt.zero, BigInt.one, BigInt.one, BigInt.zero);
_Pt _affineToExt(BigInt x, BigInt y) => _Pt(x, y, BigInt.one, _fmul(x, y));
_Pt get _base => _affineToExt(_bx, _by);

/// Unified (complete) addition for a=-1 twisted Edwards. Works for doubling too.
_Pt _add(_Pt p, _Pt q) {
  final a = _fmul(_fsub(p.y, p.x), _fsub(q.y, q.x));
  final b = _fmul(_fadd(p.y, p.x), _fadd(q.y, q.x));
  final c = _fmul(_fmul(_fmul(p.t, _two), _d), q.t);
  final dd = _fmul(_fmul(p.z, _two), q.z);
  final e = _fsub(b, a);
  final f = _fsub(dd, c);
  final g = _fadd(dd, c);
  final h = _fadd(b, a);
  return _Pt(_fmul(e, f), _fmul(g, h), _fmul(f, g), _fmul(e, h));
}

_Pt _scalarMul(BigInt k, _Pt p) {
  var r = _identity;
  for (int i = k.bitLength - 1; i >= 0; i--) {
    r = _add(r, r);
    if ((k >> i) & BigInt.one == BigInt.one) r = _add(r, p);
  }
  return r;
}

bool _ptEquals(_Pt p, _Pt q) =>
    _fsub(_fmul(p.x, q.z), _fmul(q.x, p.z)) == BigInt.zero &&
    _fsub(_fmul(p.y, q.z), _fmul(q.y, p.z)) == BigInt.zero;

BigInt _leToBig(List<int> b) {
  var r = BigInt.zero;
  for (int i = b.length - 1; i >= 0; i--) {
    r = (r << 8) | BigInt.from(b[i]);
  }
  return r;
}

/// Decode a 32-byte compressed point (RFC 8032 §5.1.3). Null on any
/// non-canonical / off-curve / invalid encoding.
_Pt? _decompress(Uint8List s) {
  if (s.length != 32) return null;
  final yBytes = Uint8List.fromList(s);
  final sign = (yBytes[31] >> 7) & 1;
  yBytes[31] &= 0x7f;
  final y = _leToBig(yBytes);
  if (y >= _p) return null;

  final y2 = _fmul(y, y);
  final u = _fsub(y2, BigInt.one);
  final v = _fadd(_fmul(_d, y2), BigInt.one);
  final v3 = _fmul(_fmul(v, v), v);
  final v7 = _fmul(_fmul(v3, v3), v);
  final exp = (_p - BigInt.from(5)) ~/ BigInt.from(8);
  var x = _fmul(_fmul(u, v3), _fmul(u, v7).modPow(exp, _p));

  final vx2 = _fmul(v, _fmul(x, x));
  if (vx2 == u) {
    // ok
  } else if (vx2 == _fsub(BigInt.zero, u)) {
    x = _fmul(x, _sqrtm1);
  } else {
    return null;
  }
  if (x == BigInt.zero && sign == 1) return null;
  if ((x & BigInt.one).toInt() != sign) x = _fsub(BigInt.zero, x);
  return _affineToExt(x, y);
}

/// Whether a 32-byte value is a valid point on the ed25519 curve. Used by
/// Solana PDA derivation (a program-derived address is, by definition, OFF
/// the curve).
bool ed25519IsOnCurve(Uint8List point) =>
    point.length == 32 && _decompress(point) != null;

/// Verify an Ed25519 signature (RFC 8032 §5.1.7). [pub] = 32 bytes, [sig] = 64.
/// Non-cofactored check [S]B = R + [k]A (RFC-permitted; standard wallet
/// signatures satisfy it). Rejects an unreduced S (malleability guard).
bool ed25519Verify(Uint8List pub, Uint8List msg, Uint8List sig) {
  if (pub.length != 32 || sig.length != 64) return false;
  final rBytes = Uint8List.sublistView(sig, 0, 32);
  final sBytes = Uint8List.sublistView(sig, 32, 64);

  final s = _leToBig(sBytes);
  if (s >= _l) return false;

  final aPt = _decompress(pub);
  if (aPt == null) return false;
  final rPt = _decompress(rBytes);
  if (rPt == null) return false;

  final h = _sha512(Uint8List.fromList([...rBytes, ...pub, ...msg]));
  final k = _leToBig(h) % _l;

  final lhs = _scalarMul(s, _base);
  final rhs = _add(rPt, _scalarMul(k, aPt));
  return _ptEquals(lhs, rhs);
}
