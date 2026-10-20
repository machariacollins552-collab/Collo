import 'package:collins_fit_ai/models/chat_message.dart';
import 'package:collins_fit_ai/models/habit_day.dart';
import 'package:collins_fit_ai/models/saved_plan.dart';
import 'package:collins_fit_ai/models/user_profile.dart';
import 'package:collins_fit_ai/models/weight_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile', () {
    test('survives a JSON round trip', () {
      const original = UserProfile(
        name: 'Collins',
        goal: Goal.buildHabits,
        startWeightKg: 82.5,
        targetWeightKg: 75,
        dailyBudgetKsh: 400,
        diet: Diet.vegetarian,
        equipment: Equipment.household,
        workoutDaysPerWeek: 4,
        shareContextWithCoach: false,
        onboarded: true,
        backendUrl: 'https://example.workers.dev',
      );
      final copy = UserProfile.fromJson(original.toJson());
      expect(copy.name, 'Collins');
      expect(copy.goal, Goal.buildHabits);
      expect(copy.startWeightKg, 82.5);
      expect(copy.targetWeightKg, 75);
      expect(copy.dailyBudgetKsh, 400);
      expect(copy.diet, Diet.vegetarian);
      expect(copy.equipment, Equipment.household);
      expect(copy.workoutDaysPerWeek, 4);
      expect(copy.shareContextWithCoach, isFalse);
      expect(copy.onboarded, isTrue);
      expect(copy.backendUrl, 'https://example.workers.dev');
    });

    test('unknown or missing values fall back to safe defaults', () {
      final p = UserProfile.fromJson(<String, dynamic>{'goal': 'nonsense', 'diet': 5});
      expect(p.goal, Goal.loseWeight);
      expect(p.diet, Diet.everything);
      expect(p.shareContextWithCoach, isTrue);
      expect(p.onboarded, isFalse);
      expect(p.displayName, 'friend');
    });

    test('displayName trims the name', () {
      expect(const UserProfile(name: '  Collins ').displayName, 'Collins');
    });
  });

  group('WeightEntry', () {
    test('rejects malformed data', () {
      expect(WeightEntry.tryFromJson('x'), isNull);
      expect(WeightEntry.tryFromJson(<String, dynamic>{'d': '2026-99-99', 'kg': 70}), isNull);
      expect(WeightEntry.tryFromJson(<String, dynamic>{'d': '2026-10-01', 'kg': 'heavy'}), isNull);
    });

    test('accepts a valid reading', () {
      final e = WeightEntry.tryFromJson(<String, dynamic>{'d': '2026-10-01', 'kg': 70});
      expect(e, isNotNull);
      expect(e!.kg, 70.0);
      expect(e.date, DateTime(2026, 10, 1));
    });
  });

  group('ChatMessage', () {
    test('round trip keeps role and text', () {
      final m = ChatMessage.assistant('Drink water.', DateTime(2026, 10, 20, 8));
      final copy = ChatMessage.tryFromJson(m.toJson());
      expect(copy, isNotNull);
      expect(copy!.isUser, isFalse);
      expect(copy.text, 'Drink water.');
    });

    test('rejects bad data', () {
      expect(ChatMessage.tryFromJson(null), isNull);
      expect(ChatMessage.tryFromJson(<String, dynamic>{'id': 1}), isNull);
    });
  });

  group('SavedPlan', () {
    test('round trip and rejection', () {
      final plan = SavedPlan(id: 'p1', title: 'T', body: 'B', savedAt: DateTime(2026, 10, 20));
      final copy = SavedPlan.tryFromJson(plan.toJson());
      expect(copy?.id, 'p1');
      expect(copy?.body, 'B');
      expect(SavedPlan.tryFromJson(<String, dynamic>{'id': 'x'}), isNull);
    });
  });

  group('HabitDay', () {
    test('completion averages the four habits and caps each at 1', () {
      const full = HabitDay(water: 12, movementMinutes: 90, sleepHours: 9, mealsOnTrack: 5);
      expect(full.completion, 1.0);
      expect(full.habitsDone, 4);

      const half = HabitDay(water: 4, movementMinutes: 15, sleepHours: 3.5, mealsOnTrack: 0);
      expect(half.waterRatio, 0.5);
      expect(half.habitsDone, 0);
      expect(half.completion, closeTo((0.5 + 0.5 + 0.5 + 0) / 4, 0.001));
    });

    test('JSON round trip', () {
      const day = HabitDay(water: 3, movementMinutes: 20, sleepHours: 7.5, mealsOnTrack: 2, workouts: 1);
      final copy = HabitDay.fromJson(day.toJson());
      expect(copy.water, 3);
      expect(copy.movementMinutes, 20);
      expect(copy.sleepHours, 7.5);
      expect(copy.mealsOnTrack, 2);
      expect(copy.workouts, 1);
    });
  });
}
