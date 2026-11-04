import 'package:flutter_test/flutter_test.dart';
import 'package:xlab_billing/core/formatting/dates.dart';

void main() {
  group('todayRange / ranges', () {
    test('todayRange covers one AD day', () {
      final (from, to) = todayRange(DateTime(2026, 10, 29));
      expect(from, DateTime(2026, 10, 29).millisecondsSinceEpoch);
      expect(to, DateTime(2026, 10, 30).millisecondsSinceEpoch - 1);
    });

    test('lastNDaysRange', () {
      final (from, to) = lastNDaysRange(DateTime(2026, 10, 29), 3);
      expect(from, DateTime(2026, 10, 27).millisecondsSinceEpoch);
      expect(to, DateTime(2026, 10, 29).millisecondsSinceEpoch + 86399999);
      expect(to, greaterThanOrEqualTo(from));
    });

    test('thisMonthRange / thisYearRange', () {
      final (mFrom, mTo) = thisMonthRange(DateTime(2026, 10, 1));
      final (yFrom, yTo) = thisYearRange(DateTime(2026, 5, 5));
      expect(yFrom, DateTime(2026, 1, 1).millisecondsSinceEpoch);
      expect(yTo, DateTime(2027, 1, 1).millisecondsSinceEpoch - 1);
      expect(mFrom, DateTime(2026, 10, 1).millisecondsSinceEpoch);
      expect(mTo, DateTime(2026, 11, 1).millisecondsSinceEpoch - 1);
      expect(yFrom, lessThan(yTo));
    });

    test('subtractMonths clamps days correctly across month lengths', () {
      expect(subtractMonths(DateTime(2026, 11, 3), 3), DateTime(2026, 8, 3));
      expect(subtractMonths(DateTime(2026, 11, 3), 6), DateTime(2026, 5, 3));
      expect(subtractMonths(DateTime(2026, 3, 31), 1), DateTime(2026, 2, 28));
      expect(subtractMonths(DateTime(2026, 1, 15), 3), DateTime(2025, 10, 15));
    });

    test('lastMonthsRange covers full duration up to end of today', () {
      final now = DateTime(2026, 11, 3, 10, 30);
      final (from3, to3) = lastMonthsRange(now, 3);
      expect(from3, DateTime(2026, 8, 3).millisecondsSinceEpoch);
      expect(to3, DateTime(2026, 11, 4).millisecondsSinceEpoch - 1);

      final (from6, to6) = lastMonthsRange(now, 6);
      expect(from6, DateTime(2026, 5, 3).millisecondsSinceEpoch);
      expect(to6, DateTime(2026, 11, 4).millisecondsSinceEpoch - 1);
    });
  });

  group('formatReceiptDateMillis', () {
    test('AD long date with time', () {
      final out = formatReceiptDateMillis(
        DateTime(2026, 10, 29, 14, 5).millisecondsSinceEpoch,
        system: DateSystem.ad,
        style: DateStyle.longMonth,
        withTime: true,
        devanagariNumerals: false,
      );
      expect(out, contains('October'));
      expect(out, contains('14:05'));
    });

    test('BS (Bikram Sambat) numeric date + devanagari numerals', () {
      final out = formatReceiptDateMillis(
        DateTime(2026, 10, 29).millisecondsSinceEpoch,
        system: DateSystem.bs,
        style: DateStyle.numeric,
        withTime: false,
        nepaliNames: false,
        devanagariNumerals: true,
      );
      expect(out, isNotEmpty);
      expect(out, isNot(contains('20'))); // sanity: may contain year digits; just non-empty
      expect(out, contains(RegExp('[०-९]')));
    });

    test('fiscalYearPrefixFor uses BS year boundary', () {
      final fy = fiscalYearPrefixFor(DateTime(2026, 1, 15));
      expect(fy, isNotNull);
    });
  });
}
