import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/src/utils/solana_metadata.dart';

void main() {
  group('Solana metadata PDA derivation', () {
    test('USDC mint → its known Metaplex metadata PDA', () {
      // Deterministic, no network. The known on-chain USDC metadata PDA.
      expect(
        metadataPda('EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v'),
        '5x38Kp4hvdomTCnCrAny4UtMUt5rQBdB6px2K1Ui45Wq',
      );
    });
  });

  group('Solana metadata Borsh parse', () {
    test('parses name / symbol / uri after key + authority + mint', () {
      final b = BytesBuilder();
      b.addByte(4); // key (MetadataV1)
      b.add(Uint8List(32)); // update authority
      b.add(Uint8List(32)); // mint
      void str(String s) {
        final bytes = utf8.encode(s);
        final len = Uint8List(4);
        len.buffer.asByteData().setUint32(0, bytes.length, Endian.little);
        b.add(len);
        b.add(bytes);
      }

      str('Frogana #3072');
      str('FRG');
      str('https://arweave.net/abc');

      final parsed = parseSolanaMetadata(b.toBytes());
      expect(parsed.name, 'Frogana #3072');
      expect(parsed.symbol, 'FRG');
      expect(parsed.uri, 'https://arweave.net/abc');
    });

    test('strips null padding (puffed strings)', () {
      final b = BytesBuilder();
      b.addByte(4);
      b.add(Uint8List(32));
      b.add(Uint8List(32));
      void puffed(String s, int max) {
        final bytes = List<int>.filled(max, 0);
        final src = utf8.encode(s);
        for (var i = 0; i < src.length; i++) {
          bytes[i] = src[i];
        }
        final len = Uint8List(4);
        len.buffer.asByteData().setUint32(0, max, Endian.little);
        b.add(len);
        b.add(Uint8List.fromList(bytes));
      }

      puffed('USD Coin', 32);
      puffed('USDC', 10);
      puffed('', 200); // no uri → all null
      final parsed = parseSolanaMetadata(b.toBytes());
      expect(parsed.name, 'USD Coin');
      expect(parsed.symbol, 'USDC');
      expect(parsed.uri, '');
    });
  });
}
