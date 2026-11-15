import 'dart:typed_data';

/// Base58 (Bitcoin / Solana alphabet). Hand-rolled big-integer base conversion —
/// no crypto, small enough to own. Used for Solana public keys / signatures in
/// the wallet directory (CAIP / Phantom proofs).
const String _alphabet =
    '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

String base58Encode(Uint8List input) {
  if (input.isEmpty) return '';
  int zeros = 0;
  while (zeros < input.length && input[zeros] == 0) {
    zeros++;
  }
  var n = BigInt.zero;
  for (final b in input) {
    n = (n << 8) | BigInt.from(b);
  }
  final out = StringBuffer();
  final fifty8 = BigInt.from(58);
  while (n > BigInt.zero) {
    out.write(_alphabet[(n % fifty8).toInt()]);
    n = n ~/ fifty8;
  }
  for (int i = 0; i < zeros; i++) {
    out.write('1');
  }
  return out.toString().split('').reversed.join();
}

Uint8List base58Decode(String input) {
  if (input.isEmpty) return Uint8List(0);
  int zeros = 0;
  while (zeros < input.length && input[zeros] == '1') {
    zeros++;
  }
  var n = BigInt.zero;
  final fifty8 = BigInt.from(58);
  for (final ch in input.split('')) {
    final idx = _alphabet.indexOf(ch);
    if (idx < 0) {
      throw FormatException('Invalid base58 character: $ch');
    }
    n = n * fifty8 + BigInt.from(idx);
  }
  final body = <int>[];
  while (n > BigInt.zero) {
    body.add((n & BigInt.from(0xff)).toInt());
    n = n >> 8;
  }
  return Uint8List.fromList([...List.filled(zeros, 0), ...body.reversed]);
}
