/// Integral, decimal-safe money and quantity helpers.
///
/// - All monetary amounts are stored as **integer paisa** (1 NPR = 100 paisa),
///   avoiding floating point rounding errors entirely.
/// - All quantities are stored as **integer thousandths** (x1000) so
///   fractional quantities (weight/volume) of up to 3 decimals are exact.
/// - Percentages are stored as integer hundredths (x100), e.g. 13.50% = 1350.
library;

const int paisaPerNPR = 100;
const int qtyScale = 1000;
const int percentScale = 100;

int _scaleDigits(int scale) {
  var n = scale, digits = 0;
  while (n > 1) {
    n ~/= 10;
    digits++;
  }
  return digits;
}

int pow10(int e) {
  var r = 1;
  for (var i = 0; i < e; i++) {
    r *= 10;
  }
  return r;
}

/// Rounds [num] / [den] half-up for non-negative integers.
int roundHalfUp(int num, int den) {
  assert(den > 0 && num >= 0, 'invalid $num/$den');
  return (num * 2 + den) ~/ (den * 2);
}

/// Rounds a quantity in milli-units (x1000) half-up to [precision] decimals (0..3).
/// Precision 0: nearest 1000 (e.g. 1500 -> 2000, 1400 -> 1000)
/// Precision 1: nearest 100  (e.g. 1250 -> 1300, 1240 -> 1200)
/// Precision 2: nearest 10   (e.g. 1255 -> 1260, 1254 -> 1250)
/// Precision 3: nearest 1    (1255 -> 1255)
int roundQuantityMilli(int quantityMilli, int precision) {
  final p = precision.clamp(0, 3);
  if (p == 3) return quantityMilli;
  if (quantityMilli < 0) return -roundQuantityMilli(-quantityMilli, p);
  final factor = pow10(3 - p);
  return roundHalfUp(quantityMilli, factor) * factor;
}

/// Computes a line total: quantity(x1000) x rate(paisa) -> paisa.
/// If [precision] is given, the quantity is rounded to [precision] decimals
/// first so that the calculation matches the displayed quantity decimals.
int lineTotalPaisa(int quantityMilli, int ratePaisa, {int? precision}) {
  final q = precision != null
      ? roundQuantityMilli(quantityMilli, precision)
      : quantityMilli;
  return roundHalfUp(q * ratePaisa, qtyScale);
}

/// [percentHundredths] percent of [amountPaisa] in paisa (half-up).
int percentOfPaisa(int amountPaisa, int percentHundredths) =>
    roundHalfUp(amountPaisa * percentHundredths, percentScale * paisaPerNPR);

/// Normalizes Devanagari digits in user input to Latin digits.
String normalizeDigits(String input) {
  const dev = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
  var out = input;
  for (var i = 0; i < 10; i++) {
    out = out.replaceAll(dev[i], i.toString());
  }
  return out;
}

/// Parses a user-entered decimal number into an integer [scale] fixed point
/// value (scale=100 -> paisa, scale=1000 -> quantity milli-units).
/// Accepts Western and Devanagari digits. Returns null when invalid or negative.
int? parseDecimalToScale(String? input, int scale) {
  if (input == null) return null;
  final cleaned = normalizeDigits(input.trim()).replaceAll(',', '');
  if (cleaned.isEmpty) return null;
  if (RegExp(r'^\d{1,9}(\.\d{1,4})?$').allMatches(cleaned).isEmpty) return null;
  final parts = cleaned.split('.');
  final intPart = int.parse(parts[0]);
  if (parts.length == 1) return intPart * scale;
  final digits = _scaleDigits(scale);
  final frac = parts[1];
  var fracValue = 0;
  if (frac.length >= digits) {
    fracValue = int.parse(frac.substring(0, digits));
    final extra = frac.substring(digits);
    if (extra.isNotEmpty && int.parse(extra[0]) >= 5) {
      fracValue = (fracValue + 1) % scale;
    }
  } else {
    fracValue = int.parse(frac) * pow10(digits - frac.length);
  }
  return intPart * scale + fracValue;
}

/// Formats an integer fixed point [value] (in [scale] units) with thousands
/// separators and [decimals] decimals, optionally as Devanagari digits.
/// The value is rounded half-up to [decimals] decimals.
String formatScaled(
  int value, {
  required int scale,
  int decimals = 2,
  bool devanagari = false,
  bool group = true,
}) {
  final neg = value < 0;
  final abs = neg ? -value : value;
  final digits = _scaleDigits(scale);
  final p = decimals.clamp(0, digits);
  // `rounded` now equals value x 10^p, as an integer.
  final rounded = roundHalfUp(abs, pow10(digits - p));
  final fracBase = pow10(p);
  final whole = (group ? groupThousands(rounded ~/ fracBase) : (rounded ~/ fracBase).toString());
  var out = whole;
  if (p > 0) {
    final fracStr = (rounded % fracBase).toString().padLeft(p, '0');
    out = '$out.$fracStr';
  }
  if (neg) out = '-$out';
  return devanagari ? toDevanagariDigits(out) : out;
}

/// Formats an integer with thousands grouping (1250000 -> 1,250,000).
String groupThousands(int value) {
  final s = value.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final remaining = s.length - i;
    buf.write(s[i]);
    if (remaining > 1 && (remaining - 1) % 3 == 0) buf.write(',');
  }
  return (value < 0 ? '-' : '') + buf.toString();
}

/// Formats a paisa amount, e.g. `NPR 1,250.50`.
String formatPaisa(
  int paisa, {
  required String symbol,
  bool devanagari = false,
  bool withSymbol = true,
  int decimals = 2,
}) {
  final text = formatScaled(
    paisa,
    scale: paisaPerNPR,
    decimals: decimals,
    devanagari: devanagari,
  );
  if (!withSymbol || symbol.isEmpty) return text;
  return '$symbol $text';
}

const devanagariDigits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];

/// Converts all Latin digits in [input] to Devanagari digits.
String toDevanagariDigits(String input) {
  const latin = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  var out = input;
  for (var i = 0; i < 10; i++) {
    out = out.replaceAll(latin[i], devanagariDigits[i]);
  }
  return out;
}

/// Converts Devanagari digits in [input] back to Latin digits.
String toLatinDigits(String input) {
  const latin = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  var out = input;
  for (var i = 0; i < 10; i++) {
    out = out.replaceAll(devanagariDigits[i], latin[i]);
  }
  return out;
}
