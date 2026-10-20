import '../core/config.dart';
import '../core/format.dart';

/// Habit totals for a single day.
class HabitDay {
  const HabitDay({
    this.water = 0,
    this.movementMinutes = 0,
    this.sleepHours = 0,
    this.mealsOnTrack = 0,
    this.workouts = 0,
  });

  final int water;
  final int movementMinutes;
  final double sleepHours;
  final int mealsOnTrack;
  final int workouts;

  double get waterRatio => clamp01(water / AppConfig.waterGoal);
  double get movementRatio => clamp01(movementMinutes / AppConfig.movementGoalMinutes);
  double get sleepRatio => clamp01(sleepHours / AppConfig.sleepGoalHours);
  double get mealsRatio => clamp01(mealsOnTrack / AppConfig.mealsGoal);

  /// Average of the four daily habits, 0.0 - 1.0.
  double get completion => (waterRatio + movementRatio + sleepRatio + mealsRatio) / 4;

  /// How many of the four habits reached their goal.
  int get habitsDone => <double>[waterRatio, movementRatio, sleepRatio, mealsRatio]
      .where((r) => r >= 1.0)
      .length;

  HabitDay copyWith({
    int? water,
    int? movementMinutes,
    double? sleepHours,
    int? mealsOnTrack,
    int? workouts,
  }) {
    return HabitDay(
      water: water ?? this.water,
      movementMinutes: movementMinutes ?? this.movementMinutes,
      sleepHours: sleepHours ?? this.sleepHours,
      mealsOnTrack: mealsOnTrack ?? this.mealsOnTrack,
      workouts: workouts ?? this.workouts,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'w': water,
        'm': movementMinutes,
        's': sleepHours,
        'e': mealsOnTrack,
        'x': workouts,
      };

  factory HabitDay.fromJson(Map<String, dynamic> json) {
    return HabitDay(
      water: (json['w'] as num?)?.toInt() ?? 0,
      movementMinutes: (json['m'] as num?)?.toInt() ?? 0,
      sleepHours: (json['s'] as num?)?.toDouble() ?? 0,
      mealsOnTrack: (json['e'] as num?)?.toInt() ?? 0,
      workouts: (json['x'] as num?)?.toInt() ?? 0,
    );
  }
}
