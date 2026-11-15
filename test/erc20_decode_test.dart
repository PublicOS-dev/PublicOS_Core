import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';

void main() {
  group('decodeErc20Transfer', () {
    // Verbatim calldata from the real Base USDC payment invoices.
    const usdc = '0x833589fcd6edb6e08f4c7c32d4f71b54bda02913';

    test('decodes the 1 USDC transfer sample', () {
      const data =
          '0xa9059cbb00000000000000000000000083546713bd755e46757109353564a7419d23c3fe00000000000000000000000000000000000000000000000000000000000f4240';
      final t = PublicOSWallets.decodeErc20Transfer(usdc, data);
      expect(t, isNotNull);
      expect(t!.recipient, '0x83546713bd755e46757109353564a7419d23c3fe');
      expect(t.rawAmount, BigInt.from(1000000));
      expect(t.token, usdc);
    });

    test('decodes the 300 USDC transfer sample', () {
      const data =
          '0xa9059cbb0000000000000000000000009403469e7940012472238932b0416d1206cde1600000000000000000000000000000000000000000000000000000000011e1a300';
      final t = PublicOSWallets.decodeErc20Transfer(usdc, data);
      expect(t!.rawAmount, BigInt.from(300000000));
      expect(t.recipient, '0x9403469e7940012472238932b0416d1206cde160');
    });

    test('returns null for non-transfer calldata / empty data', () {
      expect(PublicOSWallets.decodeErc20Transfer(usdc, '0x'), isNull);
      expect(PublicOSWallets.decodeErc20Transfer(usdc, null), isNull);
      // approve() selector — not a transfer
      expect(
          PublicOSWallets.decodeErc20Transfer(usdc, '0x095ea7b3' + '0' * 128),
          isNull);
    });

    test('decodes transferFrom', () {
      final data = '0x23b872dd'
          '${'0' * 24}1111111111111111111111111111111111111111' // from
          '${'0' * 24}2222222222222222222222222222222222222222' // to
          '${BigInt.from(5000000).toRadixString(16).padLeft(64, '0')}';
      final t = PublicOSWallets.decodeErc20Transfer(usdc, data);
      expect(t!.recipient, '0x2222222222222222222222222222222222222222');
      expect(t.rawAmount, BigInt.from(5000000));
    });
  });

  group('formatTokenAmount (BigInt-safe)', () {
    test('whole USDC', () {
      expect(PublicOSWallets.formatTokenAmount(BigInt.from(1000000), 6,
          symbol: 'USDC'),
          '1 USDC');
      expect(PublicOSWallets.formatTokenAmount(BigInt.from(300000000), 6,
          symbol: 'USDC'),
          '300 USDC');
    });

    test('fractional, trailing zeros trimmed', () {
      expect(PublicOSWallets.formatTokenAmount(BigInt.from(1500000), 6),
          '1.5');
      expect(PublicOSWallets.formatTokenAmount(BigInt.from(1230000), 6),
          '1.23');
    });

    test('no decimals / zero', () {
      expect(PublicOSWallets.formatTokenAmount(BigInt.from(42), 0), '42');
      expect(PublicOSWallets.formatTokenAmount(BigInt.zero, 6, symbol: 'USDC'),
          '0 USDC');
    });

    test('huge 18-decimal value stays exact (no float drift)', () {
      // 1234.5 ether
      final raw = BigInt.parse('1234500000000000000000');
      expect(PublicOSWallets.formatTokenAmount(raw, 18), '1234.5');
    });
  });

  group('resolveTokenMeta (registry, no network)', () {
    test('USDC on Base resolves instantly from the registry', () async {
      final meta = await PublicOSWallets.resolveTokenMeta(
          8453, '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913');
      expect(meta, isNotNull);
      expect(meta!.symbol, 'USDC');
      expect(meta.decimals, 6);
    });

    test('case-insensitive address match', () async {
      final meta = await PublicOSWallets.resolveTokenMeta(
          1, '0xA0B86991C6218B36C1D19D4A2E9EB0CE3606EB48'); // USDC mainnet
      expect(meta!.symbol, 'USDC');
    });
  });
}
