/// What the user told us in onboarding / settings. Stored only on this device.
library;

enum Goal { loseWeight, maintain, buildHabits }

enum Diet { everything, vegetarian, vegan }

enum Equipment { none, household, bands }

extension GoalInfo on Goal {
  String get label => switch (this) {
        Goal.loseWeight => 'Lose weight gradually',
        Goal.maintain => 'Maintain and feel stronger',
        Goal.buildHabits => 'Build healthy habits',
      };

  String get blurb => switch (this) {
        Goal.loseWeight => 'Slow, steady progress you can keep.',
        Goal.maintain => 'Keep your weight steady while gaining energy.',
        Goal.buildHabits => 'Focus on routines first, numbers second.',
      };

  /// Wording used when describing the goal to the AI coach.
  String get promptText => switch (this) {
        Goal.loseWeight => 'lose weight gradually',
        Goal.maintain => 'maintain weight and feel stronger',
        Goal.buildHabits => 'build healthy habits',
      };
}

extension DietInfo on Diet {
  String get label => switch (this) {
        Diet.everything => 'Eats everything',
        Diet.vegetarian => 'Vegetarian (eggs, dairy ok)',
        Diet.vegan => 'Vegan',
      };

  String get promptText => switch (this) {
        Diet.everything => 'eats meat, fish, eggs and dairy',
        Diet.vegetarian => 'vegetarian (eggs and dairy ok)',
        Diet.vegan => 'vegan',
      };
}

extension EquipmentInfo on Equipment {
  String get label => switch (this) {
        Equipment.none => 'No equipment',
        Equipment.household => 'Household items',
        Equipment.bands => 'Bands or dumbbells',
      };

  String get promptText => switch (this) {
        Equipment.none => 'no equipment',
        Equipment.household => 'household items only (water bottles, a chair)',
        Equipment.bands => 'resistance bands or dumbbells',
      };
}

T enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

class UserProfile {
  const UserProfile({
    this.name = '',
    this.goal = Goal.loseWeight,
    this.startWeightKg = 70,
    this.targetWeightKg = 65,
    this.dailyBudgetKsh = 300,
    this.diet = Diet.everything,
    this.equipment = Equipment.none,
    this.workoutDaysPerWeek = 3,
    this.shareContextWithCoach = true,
    this.onboarded = false,
    this.backendUrl = '',
  });

  final String name;
  final Goal goal;
  final double startWeightKg;
  final double targetWeightKg;
  final int dailyBudgetKsh;
  final Diet diet;
  final Equipment equipment;
  final int workoutDaysPerWeek;

  /// When false, the coach only receives the chat messages - no weights or preferences.
  final bool shareContextWithCoach;
  final bool onboarded;

  /// Optional override for the AI server address (otherwise the build-time default is used).
  final String backendUrl;

  String get displayName => name.trim().isEmpty ? 'friend' : name.trim();

  UserProfile copyWith({
    String? name,
    Goal? goal,
    double? startWeightKg,
    double? targetWeightKg,
    int? dailyBudgetKsh,
    Diet? diet,
    Equipment? equipment,
    int? workoutDaysPerWeek,
    bool? shareContextWithCoach,
    bool? onboarded,
    String? backendUrl,
  }) {
    return UserProfile(
      name: name ?? this.name,
      goal: goal ?? this.goal,
      startWeightKg: startWeightKg ?? this.startWeightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      dailyBudgetKsh: dailyBudgetKsh ?? this.dailyBudgetKsh,
      diet: diet ?? this.diet,
      equipment: equipment ?? this.equipment,
      workoutDaysPerWeek: workoutDaysPerWeek ?? this.workoutDaysPerWeek,
      shareContextWithCoach: shareContextWithCoach ?? this.shareContextWithCoach,
      onboarded: onboarded ?? this.onboarded,
      backendUrl: backendUrl ?? this.backendUrl,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'goal': goal.name,
        'startWeightKg': startWeightKg,
        'targetWeightKg': targetWeightKg,
        'dailyBudgetKsh': dailyBudgetKsh,
        'diet': diet.name,
        'equipment': equipment.name,
        'workoutDaysPerWeek': workoutDaysPerWeek,
        'shareContextWithCoach': shareContextWithCoach,
        'onboarded': onboarded,
        'backendUrl': backendUrl,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] is String ? json['name'] as String : '',
      goal: enumByName(Goal.values, json['goal'], Goal.loseWeight),
      startWeightKg: (json['startWeightKg'] as num?)?.toDouble() ?? 70,
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble() ?? 65,
      dailyBudgetKsh: (json['dailyBudgetKsh'] as num?)?.toInt() ?? 300,
      diet: enumByName(Diet.values, json['diet'], Diet.everything),
      equipment: enumByName(Equipment.values, json['equipment'], Equipment.none),
      workoutDaysPerWeek: (json['workoutDaysPerWeek'] as num?)?.toInt() ?? 3,
      shareContextWithCoach: json['shareContextWithCoach'] is bool
          ? json['shareContextWithCoach'] as bool
          : true,
      onboarded: json['onboarded'] is bool ? json['onboarded'] as bool : false,
      backendUrl: json['backendUrl'] is String ? json['backendUrl'] as String : '',
    );
  }
}
