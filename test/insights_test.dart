import 'package:collins_fit_ai/data/insights.dart';
import 'package:collins_fit_ai/models/user_profile.dart';
import 'package:collins_fit_ai/models/weight_entry.dart';
import 'package:flutter_test/flutter_test.dart';

WeightEntry w(String date, double kg) => WeightEntry(dateKey: date, kg: kg);

void main() {
  group('weeklyRateKg', () {
    test('needs at least two readings', () {
      expect(weeklyRateKg(<WeightEntry>[]), isNull);
      expect(weeklyRateKg(<WeightEntry>[w('2026-10-01', 80)]), isNull);
    });

    test('needs readings at least a week apart', () {
      expect(weeklyRateKg(<WeightEntry>[w('2026-10-10', 80), w('2026-10-14', 79)]), isNull);
    });

    test('computes kilograms per week', () {
      final rate = weeklyRateKg(<WeightEntry>[w('2026-10-01', 80), w('2026-10-15', 79)]);
      expect(rate, isNotNull);
      expect(rate!, closeTo(-0.5, 0.001));
    });
  });

  group('progressInsight', () {
    const profile = UserProfile();

    test('encourages logging when there is no trend yet', () {
      final text = progressInsight(profile: profile, weights: <WeightEntry>[w('2026-10-01', 80)]);
      expect(text, contains('Log your weight'));
    });

    test('warns gently about very fast loss', () {
      final text = progressInsight(
        profile: profile,
        weights: <WeightEntry>[w('2026-10-01', 80), w('2026-10-15', 77)],
      );
      expect(text, contains('faster than'));
      expect(text, contains('doctor'));
    });

    test('praises steady loss', () {
      final text = progressInsight(
        profile: profile,
        weights: <WeightEntry>[w('2026-10-01', 80), w('2026-10-15', 79)],
      );
      expect(text, contains('steady and sustainable'));
    });

    test('normalises plateaus', () {
      final text = progressInsight(
        profile: profile,
        weights: <WeightEntry>[w('2026-10-01', 80), w('2026-10-15', 80)],
      );
      expect(text, contains('Plateaus are normal'));
    });

    test('never shames a rise', () {
      final text = progressInsight(
        profile: profile,
        weights: <WeightEntry>[w('2026-10-01', 80), w('2026-10-15', 81)],
      );
      expect(text, contains('one reading is never the whole story'));
    });
  });
}
