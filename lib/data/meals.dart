import 'dart:math';

import '../models/user_profile.dart';

enum MealSlot { breakfast, lunch, dinner, snack }

extension MealSlotInfo on MealSlot {
  String get label => switch (this) {
        MealSlot.breakfast => 'Breakfast',
        MealSlot.lunch => 'Lunch',
        MealSlot.dinner => 'Dinner',
        MealSlot.snack => 'Snack',
      };

  String get pluralLabel => switch (this) {
        MealSlot.breakfast => 'Breakfast',
        MealSlot.lunch => 'Lunch',
        MealSlot.dinner => 'Dinner',
        MealSlot.snack => 'Snacks',
      };
}

/// A simple, affordable Kenyan meal. Costs and calories are rough estimates.
class Meal {
  const Meal({
    required this.id,
    required this.name,
    required this.slot,
    required this.description,
    required this.portion,
    required this.costKsh,
    required this.kcal,
    this.hasMeat = false,
    this.hasEggOrDairy = false,
  });

  final String id;
  final String name;
  final MealSlot slot;
  final String description;
  final String portion;

  /// Approximate cost for one person in KSh. Varies by town, season and market.
  final int costKsh;

  /// Approximate energy in kcal.
  final int kcal;

  /// Contains meat, chicken or fish.
  final bool hasMeat;
  final bool hasEggOrDairy;

  bool fits(Diet diet) => switch (diet) {
        Diet.everything => true,
        Diet.vegetarian => !hasMeat,
        Diet.vegan => !hasMeat && !hasEggOrDairy,
      };
}

const List<Meal> kMeals = <Meal>[
  // Breakfast
  Meal(
    id: 'uji_egg',
    name: 'Uji wa wimbi + boiled egg',
    slot: MealSlot.breakfast,
    description: 'Millet porridge with a little sugar and one boiled egg.',
    portion: 'One mug (about 250 ml) of uji and 1 egg.',
    costKsh: 45,
    kcal: 260,
    hasEggOrDairy: true,
  ),
  Meal(
    id: 'uji_groundnut',
    name: 'Uji wa wimbi + groundnut paste',
    slot: MealSlot.breakfast,
    description: 'Millet porridge stirred with a spoon of ground peanuts for staying power.',
    portion: 'One mug of uji and 1 teaspoon of peanut paste.',
    costKsh: 40,
    kcal: 240,
  ),
  Meal(
    id: 'arrowroot_tea',
    name: 'Boiled arrowroot (nduma) + tea',
    slot: MealSlot.breakfast,
    description: 'Boiled arrowroot with black or lightly sweetened tea.',
    portion: 'One fist-sized piece of arrowroot.',
    costKsh: 50,
    kcal: 230,
  ),
  Meal(
    id: 'sweet_potato_tea',
    name: 'Boiled sweet potato + tea',
    slot: MealSlot.breakfast,
    description: 'Viazi vitamu is filling and gentle on the budget.',
    portion: 'One medium sweet potato (about a fist) and a cup of tea.',
    costKsh: 40,
    kcal: 250,
  ),
  Meal(
    id: 'eggs_sukuma',
    name: 'Scrambled eggs with sukuma wiki',
    slot: MealSlot.breakfast,
    description: 'Two eggs scrambled with finely cut sukuma wiki and tomato.',
    portion: '2 eggs and one cupped handful of greens, with a cup of tea.',
    costKsh: 55,
    kcal: 260,
    hasEggOrDairy: true,
  ),
  Meal(
    id: 'oats_banana',
    name: 'Oat porridge with banana',
    slot: MealSlot.breakfast,
    description: 'Oats cooked in water with banana slices; go easy on sugar.',
    portion: 'About 1/2 cup dry oats and half a banana.',
    costKsh: 55,
    kcal: 270,
  ),
  Meal(
    id: 'githeri_morning',
    name: 'Warmed githeri with tomato and onion',
    slot: MealSlot.breakfast,
    description: 'Leftover githeri pan-warmed with a little onion and tomato.',
    portion: 'About one cupped handful of githeri.',
    costKsh: 40,
    kcal: 320,
  ),

  // Lunch
  Meal(
    id: 'ugali_sukuma_beans',
    name: 'Ugali, sukuma wiki and beans',
    slot: MealSlot.lunch,
    description: 'The classic: beans for protein, greens for fibre, ugali for energy.',
    portion: 'Ugali the size of your fist, a cupped hand of beans, two fists of sukuma wiki.',
    costKsh: 90,
    kcal: 520,
  ),
  Meal(
    id: 'githeri_cabbage',
    name: 'Githeri with cabbage',
    slot: MealSlot.lunch,
    description: 'Maize and beans together, with steamed cabbage or kachumbari.',
    portion: 'About one and a half cupped hands of githeri plus a fist of cabbage.',
    costKsh: 80,
    kcal: 480,
  ),
  Meal(
    id: 'rice_ndengu',
    name: 'Rice, ndengu and kachumbari',
    slot: MealSlot.lunch,
    description: 'Green grams stew with a modest serving of rice and fresh kachumbari.',
    portion: 'Three-quarters of a cup of cooked rice, a cupped hand of ndengu.',
    costKsh: 100,
    kcal: 500,
  ),
  Meal(
    id: 'ugali_omena',
    name: 'Ugali, omena and sukuma wiki',
    slot: MealSlot.lunch,
    description: 'Dried silver fish is cheap, protein-rich and full of calcium.',
    portion: 'A fist of ugali, one palm of omena, two fists of greens.',
    costKsh: 85,
    kcal: 470,
    hasMeat: true,
  ),
  Meal(
    id: 'mukimo_cabbage',
    name: 'Mukimo with cabbage',
    slot: MealSlot.lunch,
    description: 'Mashed potato, peas, maize and greens served with steamed cabbage.',
    portion: 'About one fist of mukimo and a fist of cabbage.',
    costKsh: 95,
    kcal: 500,
  ),
  Meal(
    id: 'chapati_ndengu',
    name: 'One chapati, ndengu and cabbage',
    slot: MealSlot.lunch,
    description: 'A single chapati keeps it satisfying without overdoing the oil.',
    portion: '1 small chapati, a cupped hand of ndengu, a fist of cabbage.',
    costKsh: 80,
    kcal: 520,
  ),
  Meal(
    id: 'ugali_tilapia',
    name: 'Tilapia, ugali and kachumbari',
    slot: MealSlot.lunch,
    description: 'Steamed or lightly fried tilapia with greens or kachumbari.',
    portion: 'One palm-sized piece of fish, a fist of ugali, two fists of vegetables.',
    costKsh: 250,
    kcal: 620,
    hasMeat: true,
  ),
  Meal(
    id: 'chicken_ugali',
    name: 'Skinless chicken stew, small ugali, greens',
    slot: MealSlot.lunch,
    description: 'A lighter chicken stew: remove the skin and go easy on oil.',
    portion: 'One palm of chicken, a fist of ugali, two fists of greens.',
    costKsh: 280,
    kcal: 600,
    hasMeat: true,
  ),

  // Dinner (lighter)
  Meal(
    id: 'sukuma_eggs',
    name: 'Sukuma wiki with eggs and a little ugali',
    slot: MealSlot.dinner,
    description: 'A quick, light dinner that keeps you full without a heavy plate.',
    portion: '2 eggs, two fists of sukuma wiki, half a fist of ugali.',
    costKsh: 70,
    kcal: 380,
    hasEggOrDairy: true,
  ),
  Meal(
    id: 'beans_cabbage',
    name: 'Beans stew with steamed cabbage',
    slot: MealSlot.dinner,
    description: 'High in fibre and protein. Add a small starch if you are very hungry.',
    portion: 'A cupped hand of beans and two fists of cabbage.',
    costKsh: 60,
    kcal: 300,
  ),
  Meal(
    id: 'ndengu_soup',
    name: 'Ndengu soup with spinach',
    slot: MealSlot.dinner,
    description: 'Warm, comforting and low cost, with half a chapati if needed.',
    portion: 'One bowl of soup and half a small chapati.',
    costKsh: 60,
    kcal: 320,
  ),
  Meal(
    id: 'omena_cabbage',
    name: 'Omena with cabbage and tomato',
    slot: MealSlot.dinner,
    description: 'Light, protein-rich dinner with only a spoon or two of ugali.',
    portion: 'One palm of omena, two fists of cabbage, 3 tablespoons of ugali.',
    costKsh: 70,
    kcal: 300,
    hasMeat: true,
  ),
  Meal(
    id: 'chicken_veg',
    name: 'Grilled chicken with steamed vegetables',
    slot: MealSlot.dinner,
    description: 'Skinless chicken with carrots, cabbage and spinach.',
    portion: 'One palm of chicken and a plate half full of vegetables.',
    costKsh: 220,
    kcal: 330,
    hasMeat: true,
  ),
  Meal(
    id: 'fish_sweet_potato',
    name: 'Steamed tilapia, sukuma and sweet potato',
    slot: MealSlot.dinner,
    description: 'A balanced plate with lean protein, greens and a gentle starch.',
    portion: 'One palm of fish, a fist of sweet potato, two fists of greens.',
    costKsh: 230,
    kcal: 380,
    hasMeat: true,
  ),
  Meal(
    id: 'veg_stir_egg',
    name: 'Cabbage, carrot and peas stir-fry with an egg',
    slot: MealSlot.dinner,
    description: 'Cook with about a teaspoon of oil and add a boiled egg on the side.',
    portion: 'Two fists of vegetables and 1 egg.',
    costKsh: 60,
    kcal: 220,
    hasEggOrDairy: true,
  ),

  // Snacks
  Meal(
    id: 'maize_cob',
    name: 'Roasted or boiled maize',
    slot: MealSlot.snack,
    description: 'A fibre-rich street-side snack.',
    portion: 'One cob.',
    costKsh: 25,
    kcal: 130,
  ),
  Meal(
    id: 'groundnuts',
    name: 'Handful of groundnuts',
    slot: MealSlot.snack,
    description: 'Healthy fats and protein. Portion matters: nuts are energy dense.',
    portion: 'One small handful (about 25 g).',
    costKsh: 20,
    kcal: 170,
  ),
  Meal(
    id: 'banana_orange',
    name: 'Banana or orange',
    slot: MealSlot.snack,
    description: 'Seasonal fruit is the cheapest sweet snack.',
    portion: 'One piece of fruit.',
    costKsh: 15,
    kcal: 90,
  ),
  Meal(
    id: 'avocado',
    name: 'Half an avocado with a pinch of salt',
    slot: MealSlot.snack,
    description: 'Creamy and filling when avocados are in season.',
    portion: 'Half a medium avocado.',
    costKsh: 25,
    kcal: 160,
  ),
  Meal(
    id: 'boiled_egg',
    name: 'One boiled egg',
    slot: MealSlot.snack,
    description: 'Cheap protein that travels well.',
    portion: '1 egg.',
    costKsh: 15,
    kcal: 75,
    hasEggOrDairy: true,
  ),
  Meal(
    id: 'maziwa_lala',
    name: 'Small cup of plain yoghurt or maziwa lala',
    slot: MealSlot.snack,
    description: 'Protein and calcium. Pick unsweetened where you can.',
    portion: 'One small cup (about 150 ml).',
    costKsh: 50,
    kcal: 120,
    hasEggOrDairy: true,
  ),
  Meal(
    id: 'cassava',
    name: 'Boiled cassava',
    slot: MealSlot.snack,
    description: 'Filling and inexpensive when you need something more than fruit.',
    portion: 'One small piece, about the size of your palm.',
    costKsh: 20,
    kcal: 110,
  ),
];

/// A day of meals. [snack] may be null when the budget is very tight.
class DayPlan {
  const DayPlan({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    this.snack,
  });

  final Meal breakfast;
  final Meal lunch;
  final Meal dinner;
  final Meal? snack;

  List<Meal> get meals => <Meal>[breakfast, lunch, dinner, if (snack != null) snack!];

  int get totalCost => meals.fold<int>(0, (sum, m) => sum + m.costKsh);

  int get totalKcal => meals.fold<int>(0, (sum, m) => sum + m.kcal);

  /// Short text version, used when asking the AI coach to adapt the plan.
  String toSummary() => meals.map((m) => '${m.slot.label}: ${m.name}').join('; ');
}

class MealPlanner {
  const MealPlanner._();

  static List<Meal> mealsFor(MealSlot slot, Diet diet) =>
      kMeals.where((m) => m.slot == slot && m.fits(diet)).toList();

  static Meal _cheapest(List<Meal> meals) {
    final sorted = List<Meal>.of(meals)..sort((a, b) => a.costKsh.compareTo(b.costKsh));
    return sorted.first;
  }

  /// Picks breakfast, lunch, dinner (and a snack when affordable) that fit [budget].
  /// The same [seed] always gives the same plan; a different seed shuffles it.
  /// When nothing fits, the cheapest combination is returned.
  static DayPlan plan({required int budget, required Diet diet, required int seed}) {
    final breakfasts = mealsFor(MealSlot.breakfast, diet);
    final lunches = mealsFor(MealSlot.lunch, diet);
    final dinners = mealsFor(MealSlot.dinner, diet);
    final snacks = mealsFor(MealSlot.snack, diet);

    for (var attempt = 0; attempt < 300; attempt++) {
      final random = Random(seed * 1009 + attempt);
      final candidate = DayPlan(
        breakfast: breakfasts[random.nextInt(breakfasts.length)],
        lunch: lunches[random.nextInt(lunches.length)],
        dinner: dinners[random.nextInt(dinners.length)],
        snack: snacks[random.nextInt(snacks.length)],
      );
      if (candidate.totalCost <= budget) return candidate;
    }

    for (var attempt = 0; attempt < 300; attempt++) {
      final random = Random(seed * 1013 + attempt);
      final candidate = DayPlan(
        breakfast: breakfasts[random.nextInt(breakfasts.length)],
        lunch: lunches[random.nextInt(lunches.length)],
        dinner: dinners[random.nextInt(dinners.length)],
      );
      if (candidate.totalCost <= budget) return candidate;
    }

    return DayPlan(
      breakfast: _cheapest(breakfasts),
      lunch: _cheapest(lunches),
      dinner: _cheapest(dinners),
    );
  }
}

class GuideTip {
  const GuideTip(this.title, this.body);

  final String title;
  final String body;
}

const List<GuideTip> kPlateGuide = <GuideTip>[
  GuideTip('Half the plate: vegetables', 'Sukuma wiki, cabbage, spinach or kachumbari - about two fists.'),
  GuideTip('A palm of protein', 'Beans, ndengu, eggs, omena, fish or chicken - one palm, or a cupped hand of beans.'),
  GuideTip('A fist of starch', 'Ugali, rice, potato or githeri. Add a little more on very active days.'),
  GuideTip('A thumb of oil', 'About one teaspoon per person. Boil, steam or stew when you can.'),
  GuideTip('Drink water first', 'Keep sodas and sweet juices for treats, and cut sugar in tea one spoon at a time.'),
];

const List<GuideTip> kSwaps = <GuideTip>[
  GuideTip('Fry less', 'Steam or stew fish and arrowroot. If you fry, drain the food on paper.'),
  GuideTip('Mandazi and chapati', 'Keep them for treats. Ugali, rice and sweet potato fill you for less money.'),
  GuideTip('Soda to water', 'Try water with a squeeze of lemon. It saves money and calories.'),
  GuideTip('Sugar in tea', 'Reduce slowly, half a spoon at a time. Small changes stick.'),
  GuideTip('Add one vegetable', 'Put extra sukuma wiki, cabbage or spinach on every plate.'),
  GuideTip('Eat slowly', 'Pause halfway through. Fullness takes about 20 minutes to show up.'),
];
