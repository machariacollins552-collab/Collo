/// Small, dependency-free helpers for dates and numbers.
library;

const List<String> _months = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> _weekdays = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// `2026-10-19` style key for a calendar day in local time.
String dateKey(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

DateTime? parseDateKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  return DateTime(y, m, d);
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Whole calendar days from [a] to [b].
int daysBetween(DateTime a, DateTime b) {
  final from = DateTime.utc(a.year, a.month, a.day);
  final to = DateTime.utc(b.year, b.month, b.day);
  return to.difference(from).inDays;
}

String longDate(DateTime d) => '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';

String shortDate(DateTime d) => '${d.day} ${_months[d.month - 1].substring(0, 3)}';

String shortDateYear(DateTime d) => '${shortDate(d)} ${d.year}';

int dayOfYear(DateTime d) => daysBetween(DateTime(d.year, 1, 1), d) + 1;

String greetingFor(DateTime now) {
  if (now.hour < 12) return 'Good morning';
  if (now.hour < 17) return 'Good afternoon';
  return 'Good evening';
}

/// `78.4` or `78` (drops a trailing `.0`).
String formatKg(double v) {
  final s = v.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

/// `+1.2 kg`, `-0.8 kg` or `0 kg`.
String signedKg(double v) {
  if (v.abs() < 0.05) return '0 kg';
  final sign = v > 0 ? '+' : '-';
  return '$sign${formatKg(v.abs())} kg';
}

double round1(double v) => (v * 10).round() / 10;

/// Accepts `78.5` and `78,5`.
double? parseNumber(String input) {
  final cleaned = input.trim().replaceAll(',', '.');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

/// First letter of [name] in capitals; safe for any text, including emoji.
String initialOf(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  return String.fromCharCode(trimmed.runes.first).toUpperCase();
}

int clampInt(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);

double clampDouble(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);

double clamp01(double v) => clampDouble(v, 0.0, 1.0);
