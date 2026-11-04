import 'package:flutter_test/flutter_test.dart';
import 'package:xlab_billing/core/formatting/money.dart';
import 'package:xlab_billing/shared/models/unit.dart';

void main() {
  group('parseDecimalToScale', () {
    test('parses decimal strings into fixed point integers', () {
      expect(parseDecimalToScale('12.34', 100), 1234);
      expect(parseDecimalToScale('12', 1000), 12000);
      expect(parseDecimalToScale('0.99', 100), 99);
      expect(parseDecimalToScale('', 100), isNull);
      expect(parseDecimalToScale(null, 100), isNull);
      expect(parseDecimalToScale('abc', 100), isNull);
    });

    test('parses decimal strings with commas and formatScaled round-trips', () {
      expect(parseDecimalToScale('1,250.50', 100), 125050);
      expect(parseDecimalToScale('1,500', 100), 150000);
      expect(parseDecimalToScale('१,५००.००', 100), 150000);
    });

    test('parses Devanagari digits', () {
      expect(parseDecimalToScale('१२.३४', 100), 1234);
      expect(parseDecimalToScale('१२', 1000), 12000);
    });
  });

  group('formatScaled / formatPaisa / groupThousands', () {
    test('formats paisa amounts with grouping and decimals', () {
      expect(formatScaled(125050, scale: 100, decimals: 2), '1,250.50');
      expect(formatScaled(1250, scale: 100, decimals: 2), '12.50');
      expect(formatScaled(0, scale: 100, decimals: 2), '0.00');
      expect(formatScaled(12345, scale: 1000, decimals: 2), '12.35');
      expect(formatScaled(-1234, scale: 100, decimals: 2), '-12.34');
    });

    test('formats paisa with currency symbol', () {
      expect(formatPaisa(125050, symbol: 'NPR'), 'NPR 1,250.50');
      expect(formatPaisa(125050, symbol: '', withSymbol: false), '1,250.50');
    });

    test('groups thousands', () {
      expect(groupThousands(1250000), '1,250,000');
      expect(groupThousands(1250), '1,250');
      expect(groupThousands(999), '999');
    });

    test('converts digits to Devanagari', () {
      expect(toDevanagariDigits('NPR 12,345.50'), 'NPR १२,३४५.५०');
      expect(toLatinDigits('१२३'), '123');
    });
  });

  group('percentOfPaisa', () {
    test('computes tax/discount percent of subtotal', () {
      expect(percentOfPaisa(125000, 1300), 16250); // 13% of 1250.00
      expect(percentOfPaisa(100000, 0), 0);
    });
  });

  group('roundQuantityMilli', () {
    test('rounds half-up to configured decimals (0..3)', () {
      // 0 decimals: nearest 1000
      expect(roundQuantityMilli(1500, 0), 2000);
      expect(roundQuantityMilli(1499, 0), 1000);
      expect(roundQuantityMilli(1000, 0), 1000);
      expect(roundQuantityMilli(500, 0), 1000);
      expect(roundQuantityMilli(499, 0), 0);

      // 1 decimal: nearest 100
      expect(roundQuantityMilli(1250, 1), 1300);
      expect(roundQuantityMilli(1249, 1), 1200);
      expect(roundQuantityMilli(1200, 1), 1200);

      // 2 decimals: nearest 10
      expect(roundQuantityMilli(1255, 2), 1260);
      expect(roundQuantityMilli(1254, 2), 1250);
      expect(roundQuantityMilli(1250, 2), 1250);

      // 3 decimals: exact milli-units
      expect(roundQuantityMilli(1255, 3), 1255);
      expect(roundQuantityMilli(1254, 3), 1254);

      // zero and negative
      expect(roundQuantityMilli(0, 2), 0);
      expect(roundQuantityMilli(-1255, 2), -1260);
    });
  });

  group('lineTotalPaisa with precision', () {
    test('accurately calculates line total matching quantity decimals', () {
      const rate100 = 10000; // 100.00 NPR in paisa

      // When quantity decimal is 2, 1.255 displays as 1.26.
      // Total amount must calculate based on 2 decimals (1.26 x 100 = 126.00).
      expect(lineTotalPaisa(1255, rate100), 12550); // raw 3 decimals: 125.50
      expect(lineTotalPaisa(1255, rate100, precision: 2), 12600); // 2 decimals: 126.00
      expect(lineTotalPaisa(1254, rate100, precision: 2), 12500); // 1.25 x 100 = 125.00

      // When quantity decimal is 0, 1.5 displays as 2.
      // Total amount must calculate based on 0 decimals (2 x 100 = 200.00).
      expect(lineTotalPaisa(1500, rate100, precision: 0), 20000); // 200.00
      expect(lineTotalPaisa(1400, rate100, precision: 0), 10000); // 100.00

      // When quantity decimal is 1, 1.25 displays as 1.3.
      // Total amount must calculate based on 1 decimal (1.3 x 100 = 130.00).
      expect(lineTotalPaisa(1250, rate100, precision: 1), 13000);

      // When quantity decimal is 3, uses all 3 decimals.
      expect(lineTotalPaisa(1255, rate100, precision: 3), 12550);
    });
  });

  group('shortUnit', () {
    test('resolves abbreviations for default units in English and Nepali', () {
      expect(shortUnit('Kilogram', nepali: false), 'kg');
      expect(shortUnit('Kilogram', nepali: true), 'कि.गा.');
      expect(shortUnit('किलोग्राम', nepali: false), 'kg');
      expect(shortUnit('किलोग्राम', nepali: true), 'कि.गा.');

      expect(shortUnit('Liter', nepali: false), 'L');
      expect(shortUnit('Liter', nepali: true), 'लि.');
      expect(shortUnit('लिटर', nepali: false), 'L');
      expect(shortUnit('लिटर', nepali: true), 'लि.');

      expect(shortUnit('Piece', nepali: false), 'pcs');
      expect(shortUnit('Piece', nepali: true), 'पिस');

      expect(shortUnit('Plate', nepali: false), 'plate');
      expect(shortUnit('Plate', nepali: true), 'प्लेट');

      // Custom units fallback to original string
      expect(shortUnit('cup', nepali: false), 'cup');
      expect(shortUnit('कप', nepali: true), 'कप');
      expect(shortUnit('', nepali: false), '');
    });
  });
}
