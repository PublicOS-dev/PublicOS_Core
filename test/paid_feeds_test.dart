import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';

/// Client-side paid-feeds surface.
///
/// Everything here is pure — no chain, no server. The chain-touching half of
/// `PublicOSPaidFeeds` is covered by the contract's own suite in
/// ContactOS_Contracts; what these tests protect is the part that is easy to
/// get wrong silently: which entry may be SOLD into, and what a 403 body means.
void main() {
  group('PaidFeedChains', () {
    test('knows the six designed chains and reaches all of them', () {
      expect(PaidFeedChains.all.keys.toSet(), {4489, 8453, 42161, 137, 1, 56});
      for (final chain in PaidFeedChains.all.values) {
        expect(chain.isReachable, isTrue,
            reason: '${chain.name} has no RPC endpoint — it could be shown but '
                'never quoted or paid on');
      }
    });

    test('carries no master addresses — the server supplies them', () {
      // Guards the design's promise: "adding Base is a deploy plus one config line,
      // no client change". A master map here would need an app release per
      // chain, and could disagree with the server about what it just checked.
      // The type has no field for one; this asserts nobody adds a lookalike.
      final chain = PaidFeedChains.forId(8453)!;
      expect(chain.toString(), isNot(contains('0x')));
    });

    test('names an unknown chain from the server, then from its id', () {
      expect(PaidFeedChains.nameFor(8453), 'Base');
      expect(PaidFeedChains.nameFor(8453, serverName: 'Base Mainnet'), 'Base',
          reason: 'a chain this build knows uses its own label');
      expect(PaidFeedChains.nameFor(31337, serverName: 'Hardhat'), 'Hardhat');
      expect(PaidFeedChains.nameFor(31337), 'Chain 31337');
      expect(PaidFeedChains.nameFor(31337, serverName: '   '), 'Chain 31337',
          reason: 'a blank label on a pay sheet is worse than a numeric one');
    });

    test('orders PublicOS first, then ascending — the server walk order', () {
      final ids = [8453, 1, 4489, 137]..sort(PaidFeedChains.compareChainIds);
      expect(ids, [4489, 1, 137, 8453]);
    });

    test('explorer links are null rather than wrong for PublicOS', () {
      // publicos.dev hosts a CONTRACT explorer, not a transaction one. A link
      // that 404s right after a payment is worse than no link.
      expect(PaidFeedChains.forId(4489)!.txUrl('0xabc'), isNull);
      expect(PaidFeedChains.forId(8453)!.txUrl('0xabc'),
          'https://basescan.org/tx/0xabc');
    });
  });

  group('ChannelAccessEntry', () {
    test('write shape carries chain, contract and id — and nothing else', () {
      const entry = ChannelAccessEntry(
        chainId: 8453,
        feedId: 9,
        contract: '0xdeadbeef',
        chainName: 'Base',
        payable: true,
      );
      // The contract IS sent — the server allowlists it at save time rather
      // than the client withholding it, which is what keeps the owner flow
      // identical when v2 widens that list. `chain_name` and `payable` are
      // server-derived and must not travel back; an RPC URL never appears at
      // all, since naming the endpoint would be an SSRF primitive.
      expect(entry.toJson(),
          {'chain_id': 8453, 'feed_id': 9, 'contract': '0xdeadbeef'});
    });

    test('an empty contract is OMITTED, meaning "this server\'s default"', () {
      const entry = ChannelAccessEntry(chainId: 8453, feedId: 9);
      expect(entry.toJson(), {'chain_id': 8453, 'feed_id': 9});
      expect(entry.toJson().containsKey('contract'), isFalse,
          reason: 'sending an empty string would fail address validation; '
              'absence is what means "use the default"');
    });

    test('a 403 body has no `payable` key and every entry in it is payable',
        () {
      final fromPaywall = ChannelAccessEntry.fromJson(
          {'chain_id': 4489, 'feed_id': 3, 'contract': '0xaa'},
          defaultPayable: true);
      expect(fromPaywall.payable, isTrue);

      // The channel listing states it, and the default must not override.
      final fromListing = ChannelAccessEntry.fromJson({
        'chain_id': 4489,
        'feed_id': 3,
        'contract': '0xaa',
        'payable': false,
      });
      expect(fromListing.payable, isFalse);
    });

    test('identity is (chain, contract, feed) — the triple the server indexes',
        () {
      // Feed ids are PER CONTRACT: id 2 on the master and id 2 on a payout
      // splitter are unrelated plans. Collapsing them would silently drop one
      // from any list or set.
      const master = ChannelAccessEntry(chainId: 1, feedId: 2, contract: '0xaa');
      const splitter =
          ChannelAccessEntry(chainId: 1, feedId: 2, contract: '0xbb');
      expect(master, isNot(equals(splitter)));
      expect({master, splitter}.length, 2);

      // …but one address in two spellings is still one plan.
      const shouty = ChannelAccessEntry(chainId: 1, feedId: 2, contract: '0xAA');
      expect(master, equals(shouty));
      expect({master, shouty}.length, 1);
    });
  });

  group('Channel paywall fields', () {
    Map<String, dynamic> channelJson({
      bool isPaid = true,
      List<Map<String, dynamic>>? entries,
    }) =>
        {
          'id': 1,
          'account_id': 1,
          'name': 'Paid',
          'description': '',
          'slug': 'paid',
          'is_paid': isPaid,
          if (entries != null) 'access_entries': entries,
          'created_at': '',
          'updated_at': '',
        };

    test('parses is_paid and the entry list', () {
      final ch = Channel.fromJson(channelJson(entries: [
        {'chain_id': 4489, 'feed_id': 7, 'contract': '0xaa', 'payable': false},
        {'chain_id': 4489, 'feed_id': 12, 'contract': '0xaa', 'payable': true},
      ]));
      expect(ch.isPaid, isTrue);
      expect(ch.accessEntries.length, 2);
    });

    test('a RETIRED id is listed but never offered for payment', () {
      // The lost-registrant-key recovery path: the old id stays so existing
      // subscribers keep reading, and the new one is what gets sold. Selling
      // into the retired id sends money to a feed nobody can manage.
      final ch = Channel.fromJson(channelJson(entries: [
        {'chain_id': 4489, 'feed_id': 7, 'contract': '0xaa', 'payable': false},
        {'chain_id': 4489, 'feed_id': 12, 'contract': '0xaa', 'payable': true},
      ]));
      expect(ch.accessEntries.map((e) => e.feedId), [7, 12]);
      expect(ch.payableEntries.map((e) => e.feedId), [12]);
    });

    test('payable entries are ordered PublicOS-first so the sheet preselects '
        'the chain the server would have answered from', () {
      final ch = Channel.fromJson(channelJson(entries: [
        {'chain_id': 8453, 'feed_id': 1, 'contract': '0xbb', 'payable': true},
        {'chain_id': 4489, 'feed_id': 2, 'contract': '0xaa', 'payable': true},
      ]));
      expect(ch.payableEntries.map((e) => e.chainId), [4489, 8453]);
    });

    test('paid with NO entries is locked, not free', () {
      // Older servers omit the key entirely. A client that read "no entries" as
      // "not gated" would render a free feed it cannot fetch.
      final ch = Channel.fromJson(channelJson());
      expect(ch.isPaid, isTrue);
      expect(ch.accessEntries, isEmpty);
      expect(ch.payableEntries, isEmpty);
    });

    test('an entry on an unreachable chain is not usable even when payable',
        () {
      const unreachable =
          ChannelAccessEntry(chainId: 31337, feedId: 1, contract: '0xaa', payable: true);
      const noAddress =
          ChannelAccessEntry(chainId: 8453, feedId: 1, payable: true);
      const good =
          ChannelAccessEntry(chainId: 8453, feedId: 1, contract: '0xaa', payable: true);
      expect(unreachable.isUsable, isFalse);
      expect(noAddress.isUsable, isFalse);
      expect(good.isUsable, isTrue);
    });
  });

  group('PaidFeedServerChain', () {
    // The server's answer is the authority on WHICH chains exist and WHERE the
    // master is. This build's registry only ever improves the label.
    PaidFeedServerChain parse(Map<String, dynamic> json) =>
        PaidFeedServerChain.fromJson(json);

    test('parses the /api/paid_feeds/chains row', () {
      final c = parse({
        'chain_id': 4489,
        'name': 'PublicOS',
        'contract': '0x9daf5732781827eD628AE774B66088F1Ea360029',
        'native_symbol': 'OX',
      });
      expect(c.chainId, 4489);
      expect(c.contract, '0x9daf5732781827eD628AE774B66088F1Ea360029');
      expect(c.symbol, 'OX');
      expect(c.isUsable, isTrue);
    });

    test('a chain this build does not know is listed, not usable', () {
      // A different SSP may serve a chain we have no RPC for. Showing it is
      // honest; offering a Confirm button for it is not.
      final c = parse({'chain_id': 31337, 'name': 'Hardhat', 'contract': '0xaa'});
      expect(c.displayName, 'Hardhat', reason: 'falls back to the server label');
      expect(c.isUsable, isFalse);
    });

    test('a row with no contract is never usable', () {
      final c = parse({'chain_id': 8453, 'name': 'Base'});
      expect(c.isUsable, isFalse);
    });

    test('entryFor builds the channel entry an owner just registered', () {
      final c = parse({'chain_id': 8453, 'name': 'Base', 'contract': '0xbb'});
      final entry = c.entryFor(7);
      expect(entry.chainId, 8453);
      expect(entry.feedId, 7);
      expect(entry.contract, '0xbb');
      expect(entry.payable, isTrue);
      // The contract rides along to the save, where the server re-checks it
      // against its allowlist rather than taking the client's word for it.
      expect(entry.toJson(),
          {'chain_id': 8453, 'feed_id': 7, 'contract': '0xbb'});
    });
  });

  group('PaywallException', () {
    Map<String, dynamic> denial({
      List<Map<String, dynamic>>? entries,
      int? lapsedAt,
    }) =>
        {
          'code': 'PAYWALL_DENIED',
          'message': 'this feed requires a subscription',
          if (entries != null) 'entries': entries,
          if (lapsedAt != null) 'lapsed_at': lapsedAt,
        };

    test('parses a denial with its payable entries', () {
      final ex = PaywallException.tryFromErrorMap(403, denial(entries: [
        {
          'chain_id': 4489,
          'feed_id': 12,
          'contract': '0xaa',
          'chain_name': 'PublicOS'
        },
      ]))!;
      expect(ex.code, 'PAYWALL_DENIED');
      expect(ex.isDenied, isTrue);
      expect(ex.isPayable, isTrue);
      expect(ex.entries.single.contract, '0xaa');
      // A 403 body contains only payable entries and omits the flag.
      expect(ex.entries.single.payable, isTrue);
      expect(ex.hasLapsed, isFalse);
    });

    test('lapsed_at turns "subscribe" into "renew"', () {
      final ex = PaywallException.tryFromErrorMap(403,
          denial(lapsedAt: DateTime.utc(2026, 3, 14).millisecondsSinceEpoch ~/ 1000))!;
      expect(ex.hasLapsed, isTrue);
      expect(ex.lapsedAt, DateTime.utc(2026, 3, 14));
    });

    test('a denial with NO entries is a real state and must not look payable',
        () {
      // Every chain this channel names was dropped by its SSP. The screen is
      // "not currently for sale", not a Confirm button.
      final ex = PaywallException.tryFromErrorMap(403, denial())!;
      expect(ex.isDenied, isTrue);
      expect(ex.isPayable, isFalse);
    });

    test('PAYWALL_CHECK_FAILED is a server fault, not a paywall', () {
      final ex = PaywallException.tryFromErrorMap(500, {
        'code': 'PAYWALL_CHECK_FAILED',
        'message': 'could not verify subscription state',
      })!;
      expect(ex.isServerFault, isTrue);
      expect(ex.isDenied, isFalse);
      expect(ex.isPayable, isFalse,
          reason: 'a retry belongs here, never a price');
    });

    test('leaves every other refusal to the existing error path', () {
      expect(
          PaywallException.tryFromErrorMap(
              403, {'code': 'PRIVATE_FEED_NOT_APPROVED'}),
          isNull);
      expect(PaywallException.tryFromErrorMap(403, null), isNull);
      expect(PaywallException.tryFromErrorMap(403, {'code': 42}), isNull);
    });

    test('stringifies to the FEED_ERROR protocol callers already match on', () {
      // The typed exception is additive: a caller still doing
      // `e.toString().contains('FEED_ERROR:')` keeps working.
      final ex = PaywallException.tryFromErrorMap(403, denial())!;
      expect(ex.toString(), 'FEED_ERROR:PAYWALL_DENIED');
    });
  });
}
