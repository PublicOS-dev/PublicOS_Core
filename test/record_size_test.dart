// The chain's per-record limit (RecordManager): the stored JSON
// envelope at most 2048 bytes. Record.chainSizeProblem must catch what a user can
// type, in bytes, before a write is sent.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/src/models/record_model.dart';

Record _text(String value) => Record.asProfile(
      key: 'card.test',
      value: value,
      expiration: DateTime.utc(2027, 1, 1),
    );

void main() {
  test('a normal card fits', () {
    final r = _text('Hello, this is my card.');
    expect(r.chainSizeProblem, isNull);
    expect(r.chainValueBytes, lessThan(Record.maxChainValueBytes));
  });

  test('2000 ASCII characters plus the envelope is over', () {
    final r = _text('a' * 2000);
    expect(r.chainValueBytes, greaterThan(Record.maxChainValueBytes));
    expect(r.chainSizeProblem, isNotNull);
  });

  test('bytes, not characters: 500 emoji are 2000 bytes and do not fit', () {
    final r = _text('\u{1F600}' * 500); // 4 bytes each in UTF-8
    expect(r.value.runes.length, 500);
    expect(r.chainSizeProblem, isNotNull);
  });

  test('what is measured is what is sent', () {
    final r = _text('café \u{1F600}');
    expect(r.chainValueBytes, utf8.encode(r.toChainJson()).length);
    expect(r.toChainJson(), jsonEncode(r.toChainValue()));
  });

  // fetchContact stamps the resolver's cache onto an NFT card's metadata. None of
  // it may ride back to the chain: an on-chain-art token carries its image as a
  // data: URI inside `nftVerified`, which took a card move past the limit
  // (one such card is 366 bytes on chain and 7848 with the stamp).
  test('a fetched NFT card moves without its view-time stamps', () {
    final art = 'data:image/svg+xml;base64,${'A' * 7000}';
    final stamped = _text('{"v":2,"chain":1,"standard":"erc721","contract":"0x00","tokenId":"1"}').copyWith(
      metadata: {
        'cardKind': 'nft',
        'width': 2,
        'height': 2,
        'nftImage': art,
        'nftOwned': true,
        'nftCheckedAt': 1,
        'nftVerified': jsonEncode({'metadata': {'image': art}}),
      },
    );
    final moved = stamped.copyWith(rank: 'zzt');
    final meta = moved.toChainValue()['metadata'] as Map<String, dynamic>;
    expect(meta.keys.where((k) => k.startsWith('nft')), isEmpty);
    expect(meta['cardKind'], 'nft');
    expect(meta['rank'], 'zzt');
    expect(moved.chainSizeProblem, isNull);
  });
}
