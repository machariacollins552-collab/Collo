import '../core/format.dart';
import '../models/user_profile.dart';
import '../models/weight_entry.dart';

/// Rate of weight change in kg per week over roughly the last four weeks.
/// Returns null when there is not enough data (fewer than two readings or less than a week apart).
double? weeklyRateKg(List<WeightEntry> weights, {int windowDays = 28}) {
  if (weights.length < 2) return null;
  final last = weights.last;
  final lastDate = last.date;
  final window = weights
      .where((w) => daysBetween(w.date, lastDate) <= windowDays)
      .toList();
  if (window.length < 2) return null;
  final first = window.first;
  final days = daysBetween(first.date, lastDate);
  if (days < 7) return null;
  return (last.kg - first.kg) / days * 7;
}

/// A supportive, non-judgmental message about recent progress.
String progressInsight({
  required UserProfile profile,
  required List<WeightEntry> weights,
}) {
  if (weights.length < 2) {
    return 'Log your weight once or twice a week, at a similar time of day, to see your trend. '
        'Small, steady steps beat quick fixes.';
  }
  final rate = weeklyRateKg(weights);
  if (rate == null) {
    return 'Early days. A week or two of readings will show a clearer trend, so there is no need to judge a single number.';
  }
  if (rate < -1.0) {
    return 'Your recent change is faster than the commonly suggested pace of about 0.25 to 0.75 kg a week. '
        'Make sure you are eating enough and sleeping well, and speak to a doctor or dietitian if you feel weak or dizzy.';
  }
  if (rate <= -0.15) {
    return 'You are trending down by about ${formatKg(rate.abs())} kg a week. That is steady and sustainable. '
        'Keep your routines simple and keep going.';
  }
  if (rate < 0.15) {
    return 'Your weight has been steady lately. Plateaus are normal. Regular meals, walking and good sleep still count, '
        'even when the scale pauses.';
  }
  return 'Weight moves with water, salt and timing, so one reading is never the whole story. '
      'Look at the trend over several weeks. Want help adjusting your plan? Ask FitCoach.';
}
