import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';

void main() {
  group('NftAvatarRef namespace discriminator', () {
    test('Solana ref round-trips through encode/tryParse', () {
      final ref = NftAvatarRef.solana(
          mint: '4Cma66uMs7ehC2iS2oLCNnsFsuVtgTw8GFH7a5NwBeaF', owner: 'x');
      final back = NftAvatarRef.tryParse(ref.encode());
      expect(back, isNotNull);
      expect(back!.isSolana, isTrue);
      expect(back.mint, '4Cma66uMs7ehC2iS2oLCNnsFsuVtgTw8GFH7a5NwBeaF');
      expect(ref.samePointer(back), isTrue);
    });

    test('EVM ref still round-trips and stays eip155 (backward compat)', () {
      final ref = NftAvatarRef(
          chain: 1, standard: 'erc721', contract: '0xabc', tokenId: '7');
      final back = NftAvatarRef.tryParse(ref.encode());
      expect(back, isNotNull);
      expect(back!.isSolana, isFalse);
      expect(back.namespace, 'eip155');
      expect(back.chain, 1);
      expect(back.tokenId, '7');
      expect(ref.samePointer(back), isTrue);
    });

    test('legacy EVM JSON without a namespace key parses as eip155', () {
      final back = NftAvatarRef.tryParse(
          '{"v":2,"chain":1,"standard":"erc721","contract":"0xABC","tokenId":"7"}');
      expect(back, isNotNull);
      expect(back!.isSolana, isFalse);
      expect(back.chain, 1);
    });

    test('Solana and EVM refs are never samePointer', () {
      final sol = NftAvatarRef.solana(mint: 'A');
      final evm =
          NftAvatarRef(chain: 1, standard: 'erc721', contract: '0xA', tokenId: '1');
      expect(sol.samePointer(evm), isFalse);
      expect(evm.samePointer(sol), isFalse);
    });
  });
}
