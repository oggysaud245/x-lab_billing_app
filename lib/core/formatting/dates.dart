/// Date/time formatting for receipts and the UI.
///
/// - Canonical timestamps are always stored as milliseconds since epoch (AD).
/// - Display converts to Gregorian (AD) or Bikram Sambat (BS) using the
///   tested `bikram_sambat` package (real calendar table, no approximation).
/// - Bilingual month names come from the package's own tables.
library;

import 'package:bikram_sambat/bikram_sambat.dart';
import 'package:intl/intl.dart';

import 'money.dart';

enum DateSystem { ad, bs }

enum DateStyle { numeric, longMonth }

/// Formats [timestampMillis] for a receipt.
String formatReceiptDateMillis(
  int timestampMillis, {
  required DateSystem system,
  required DateStyle style,
  bool withTime = false,
  bool nepaliNames = false,
  bool devanagariNumerals = false,
}) {
  final ts = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
  return formatReceiptDate(
    ts,
    system: system,
    style: style,
    withTime: withTime,
    nepaliNames: nepaliNames,
    devanagariNumerals: devanagariNumerals,
  );
}

String formatReceiptDate(
  DateTime ts, {
  required DateSystem system,
  required DateStyle style,
  bool withTime = false,
  bool nepaliNames = false,
  bool devanagariNumerals = false,
}) {
  var out = '';
  if (system == DateSystem.bs) {
    final bs = ts.toBikramSambat();
    final lang = nepaliNames ? BSLanguage.nepali : BSLanguage.english;
    if (style == DateStyle.numeric) {
      out = BSDateFormat.yMd(lang).format(bs);
    } else {
      out = BSDateFormat.yMMMMd(lang).format(bs);
    }
  } else {
    if (style == DateStyle.numeric) {
      out = DateFormat('yyyy-MM-dd').format(ts);
    } else {
      out = DateFormat('d MMMM yyyy').format(ts);
    }
  }
  if (withTime) {
    if (system == DateSystem.bs) {
      final bs = ts.toBikramSambat();
      out += ' ${BSDateFormat.jm(BSLanguage.english).format(bs)}';
    } else {
      out += ' ${DateFormat('HH:mm').format(ts)}';
    }
  }
  return devanagariNumerals ? toDevanagariDigits(out) : out;
}

/// Short HH:mm format used in lists (never localized digits).
String formatListTime(int timestampMillis) =>
    DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(timestampMillis));

/// Short day label for lists.
String formatListDate(int timestampMillis) =>
    DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(timestampMillis));

/// Nepali fiscal year (Shrawan 1 – Ashad end) label, e.g. "2082-83".
/// Falls back to null if conversion is out of range.
String? fiscalYearPrefixFor(DateTime now) {
  try {
    final bs = now.toBikramSambat();
    final startYear = bs.month >= 4 ? bs.year : bs.year - 1;
    return '$startYear-${startYear + 1}';
  } catch (_) {
    return null;
  }
}

/// Start/end timestamps of "today" in local time.
(int, int) todayRange(DateTime now) {
  final start = DateTime(now.year, now.month, now.day);
  return (start.millisecondsSinceEpoch, start.add(const Duration(days: 1)).millisecondsSinceEpoch - 1);
}

(int, int) lastNDaysRange(DateTime now, int n) {
  final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: n - 1));
  return (start.millisecondsSinceEpoch, start.add(Duration(days: n)).millisecondsSinceEpoch - 1);
}

(int, int) thisMonthRange(DateTime now) {
  final start = DateTime(now.year, now.month, 1);
  return (start.millisecondsSinceEpoch, DateTime(now.year, now.month + 1, 1).millisecondsSinceEpoch - 1);
}

(int, int) thisYearRange(DateTime now) {
  final start = DateTime(now.year, 1, 1);
  return (start.millisecondsSinceEpoch, start.add(const Duration(days: 365)).millisecondsSinceEpoch - 1);
}

/// Subtracts [months] from [dt], safely clamping the day to the last valid
/// day of the target month.
DateTime subtractMonths(DateTime dt, int months) {
  var year = dt.year;
  var month = dt.month - months;
  while (month < 1) {
    month += 12;
    year -= 1;
  }
  final maxDay = DateTime(year, month + 1, 0).day;
  final day = dt.day > maxDay ? maxDay : dt.day;
  return DateTime(year, month, day);
}

/// Start/end timestamps covering the last [months] months up to end of today.
(int, int) lastMonthsRange(DateTime now, int months) {
  final start = subtractMonths(DateTime(now.year, now.month, now.day), months);
  final end = DateTime(now.year, now.month, now.day).add(const Duration(days: 1)).millisecondsSinceEpoch - 1;
  return (start.millisecondsSinceEpoch, end);
}
