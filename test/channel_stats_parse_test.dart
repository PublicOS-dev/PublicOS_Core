// Unit tests for ChannelStats.tryFromJson — the null-when-absent contract that
// keeps a feed with no stats from rendering "0 readers" (social-reads KPI).

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';

void main() {
  group('ChannelStats.tryFromJson', () {
    test('parses a full stats block', () {
      final s = ChannelStats.tryFromJson(<String, dynamic>{
        'verified_citizen_views': 412,
        'total_views': 1893,
        'by_type': {
          'citizen': 412,
          'private': 88,
          'signed_no_account': 12,
          'anonymous': 1381,
        },
        'daily': [12, 18, 20, 15, 22, 19, 17],
        'today': 5,
        'week': '2026-W29',
        'verified_through': '2026-W28',
      });

      expect(s, isNotNull);
      expect(s!.verifiedCitizenViews, 412);
      expect(s.totalViews, 1893);
      expect(s.byType.citizen, 412);
      expect(s.byType.anonymous, 1381);
      expect(s.daily, [12, 18, 20, 15, 22, 19, 17]);
      expect(s.today, 5);
      expect(s.week, '2026-W29');
      expect(s.verifiedThrough, '2026-W28');
      // The 4-way split sums to total.
      expect(
        s.byType.citizen +
            s.byType.private +
            s.byType.signedNoAccount +
            s.byType.anonymous,
        s.totalViews,
      );
    });

    test('ABSENT stays null — never a zero object', () {
      // These are the real "no stats" shapes: missing key (null), and an
      // interactions answer whose channel block carried no stats member.
      expect(ChannelStats.tryFromJson(null), isNull);
      expect(ChannelStats.tryFromJson(<String, dynamic>{}['stats']), isNull);
    });

    test('non-map input is null, not a throw', () {
      expect(ChannelStats.tryFromJson('nope'), isNull);
      expect(ChannelStats.tryFromJson(42), isNull);
      expect(ChannelStats.tryFromJson(<int>[1, 2, 3]), isNull);
    });

    test('verified_through omitted (brand-new channel) → null', () {
      final s = ChannelStats.tryFromJson(<String, dynamic>{
        'verified_citizen_views': 1,
        'total_views': 2,
        'by_type': {'citizen': 1, 'anonymous': 1},
        'daily': [0, 0, 0, 0, 0, 0, 1],
        'today': 1,
        'week': '2026-W30',
        // no verified_through — nothing sealed yet
      });
      expect(s, isNotNull);
      expect(s!.verifiedThrough, isNull);
      expect(s.byType.private, 0); // absent sub-key defaults to 0
    });

    test('a measured-but-zero channel is a real zero, still present', () {
      // Distinct from absence: the server DID send a block, everyone read as
      // anonymous. verified_citizen_views is a truthful 0, and the object
      // exists (not null) so the UI can show "0 Readers".
      final s = ChannelStats.tryFromJson(<String, dynamic>{
        'verified_citizen_views': 0,
        'total_views': 30,
        'by_type': {'anonymous': 30},
        'daily': [0, 0, 0, 0, 0, 0, 0],
        'today': 0,
        'week': '2026-W30',
      });
      expect(s, isNotNull);
      expect(s!.verifiedCitizenViews, 0);
      expect(s.totalViews, 30);
    });
  });
}
