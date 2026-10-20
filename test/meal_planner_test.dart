import 'package:collins_fit_ai/data/meals.dart';
import 'package:collins_fit_ai/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

String ids(DayPlan p) => p.meals.map((m) => m.id).join(',');

void main() {
  test('every diet has meals for every slot', () {
    for (final diet in Diet.values) {
      for (final slot in MealSlot.values) {
        expect(MealPlanner.mealsFor(slot, diet), isNotEmpty, reason: '$diet / $slot');
      }
    }
  });

  test('plans stay within a realistic budget for every diet', () {
    for (final diet in Diet.values) {
      for (final budget in <int>[200, 300, 500, 1000]) {
        for (var seed = 0; seed < 30; seed++) {
          final plan = MealPlanner.plan(budget: budget, diet: diet, seed: seed);
          expect(plan.totalCost, lessThanOrEqualTo(budget), reason: '$diet budget $budget seed $seed');
        }
      }
    }
  });

  test('a very small budget returns the cheapest plan instead of failing', () {
    final plan = MealPlanner.plan(budget: 100, diet: Diet.everything, seed: 3);
    expect(plan.meals.length, greaterThanOrEqualTo(3));
    expect(plan.snack, isNull);
    expect(plan.totalCost, greaterThan(100));
  });

  test('vegetarian plans contain no meat or fish', () {
    for (var seed = 0; seed < 40; seed++) {
      final plan = MealPlanner.plan(budget: 600, diet: Diet.vegetarian, seed: seed);
      expect(plan.meals.any((m) => m.hasMeat), isFalse);
    }
  });

  test('vegan plans contain no meat, fish, eggs or dairy', () {
    for (var seed = 0; seed < 40; seed++) {
      final plan = MealPlanner.plan(budget: 600, diet: Diet.vegan, seed: seed);
      expect(plan.meals.any((m) => m.hasMeat || m.hasEggOrDairy), isFalse);
    }
  });

  test('the same seed gives the same plan and other seeds vary it', () {
    final a = MealPlanner.plan(budget: 500, diet: Diet.everything, seed: 7);
    final b = MealPlanner.plan(budget: 500, diet: Diet.everything, seed: 7);
    expect(ids(a), ids(b));

    final variety = <String>{
      for (var seed = 0; seed < 20; seed++)
        ids(MealPlanner.plan(budget: 500, diet: Diet.everything, seed: seed)),
    };
    expect(variety.length, greaterThan(1));
  });

  test('totals add up and the summary names every meal', () {
    final plan = MealPlanner.plan(budget: 400, diet: Diet.everything, seed: 1);
    expect(plan.totalCost, plan.meals.fold<int>(0, (s, m) => s + m.costKsh));
    expect(plan.totalKcal, plan.meals.fold<int>(0, (s, m) => s + m.kcal));
    for (final meal in plan.meals) {
      expect(plan.toSummary(), contains(meal.name));
    }
  });
}
