import 'package:collins_fit_ai/core/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dates', () {
    test('dateKey pads month and day', () {
      expect(dateKey(DateTime(2026, 3, 5)), '2026-03-05');
    });

    test('parseDateKey reads valid keys and rejects bad ones', () {
      expect(parseDateKey('2026-10-20'), DateTime(2026, 10, 20));
      expect(parseDateKey('2026-13-01'), isNull);
      expect(parseDateKey('2026-10'), isNull);
      expect(parseDateKey('abcd-ef-gh'), isNull);
    });

    test('daysBetween counts whole calendar days', () {
      expect(daysBetween(DateTime(2026, 3, 28), DateTime(2026, 3, 30)), 2);
      expect(daysBetween(DateTime(2026, 3, 30), DateTime(2026, 3, 28)), -2);
      expect(daysBetween(DateTime(2026, 5, 1, 23, 59), DateTime(2026, 5, 2, 0, 1)), 1);
    });

    test('dayOfYear starts at 1', () {
      expect(dayOfYear(DateTime(2026, 1, 1)), 1);
      expect(dayOfYear(DateTime(2026, 12, 31)), 365);
    });

    test('long and short dates', () {
      expect(longDate(DateTime(2026, 10, 20)), 'Tuesday, 20 October');
      expect(shortDate(DateTime(2026, 10, 20)), '20 Oct');
      expect(shortDateYear(DateTime(2026, 10, 20)), '20 Oct 2026');
    });

    test('greeting follows the time of day', () {
      expect(greetingFor(DateTime(2026, 1, 1, 8)), 'Good morning');
      expect(greetingFor(DateTime(2026, 1, 1, 14)), 'Good afternoon');
      expect(greetingFor(DateTime(2026, 1, 1, 19)), 'Good evening');
    });
  });

  group('numbers', () {
    test('formatKg drops a trailing .0', () {
      expect(formatKg(78), '78');
      expect(formatKg(78.44), '78.4');
    });

    test('signedKg shows direction and hides tiny changes', () {
      expect(signedKg(-0.8), '-0.8 kg');
      expect(signedKg(1.2), '+1.2 kg');
      expect(signedKg(0.02), '0 kg');
    });

    test('round1 rounds to one decimal', () {
      expect(round1(78.46), 78.5);
      expect(round1(70), 70);
    });

    test('parseNumber accepts dots and commas and rejects junk', () {
      expect(parseNumber('78.5'), 78.5);
      expect(parseNumber('78,5'), 78.5);
      expect(parseNumber('  70 '), 70);
      expect(parseNumber(''), isNull);
      expect(parseNumber('abc'), isNull);
    });

    test('clamp helpers', () {
      expect(clampInt(5, 0, 3), 3);
      expect(clampInt(-1, 0, 3), 0);
      expect(clampDouble(0.5, 0, 1), 0.5);
      expect(clamp01(1.7), 1.0);
      expect(clamp01(-2), 0.0);
    });

    test('initialOf handles empty names', () {
      expect(initialOf('collins'), 'C');
      expect(initialOf('   '), '?');
    });
  });
}
