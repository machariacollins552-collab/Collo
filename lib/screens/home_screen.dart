import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../data/insights.dart';
import '../data/quick_prompts.dart';
import '../data/workouts.dart';
import '../models/habit_day.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/log_weight_sheet.dart';
import '../widgets/progress_ring.dart';
import 'workout_player_screen.dart';

/// The dashboard: greeting, weight and goal progress, today's habits, coach shortcut.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final now = state.clock();
    final tip = kDailyTips[dayOfYear(now) % kDailyTips.length];

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: <Widget>[
          _Greeting(state: state, now: now),
          _WeightCard(state: state),
          const SizedBox(height: 16),
          _HabitsCard(state: state),
          const SizedBox(height: 16),
          _CoachCard(state: state),
          const SizedBox(height: 16),
          _WorkoutCard(now: now),
          const SizedBox(height: 16),
          AppCard(
            color: AppColors.sageLight,
            borderColor: AppColors.sageLight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.spa_outlined, color: AppColors.forest),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('TIP OF THE DAY', style: AppText.label),
                      const SizedBox(height: 6),
                      Text(tip, style: AppText.body),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              progressInsight(profile: state.profile, weights: state.weights),
              style: AppText.small,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Collins Fit AI gives general wellbeing guidance and does not replace a doctor or dietitian.',
              style: AppText.small,
            ),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.state, required this.now});

  final AppState state;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final name = state.profile.displayName;
    final initial = initialOf(name);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(longDate(now).toUpperCase(), style: AppText.label),
                const SizedBox(height: 6),
                Text('${greetingFor(now)}, $name', style: AppText.h1),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            button: true,
            label: 'Open profile and settings',
            excludeSemantics: true,
            onTap: () => state.goToTab(AppTab.profile),
            child: InkWell(
              onTap: () => state.goToTab(AppTab.profile),
              customBorder: const CircleBorder(),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.forest,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: AppText.h3.copyWith(color: AppColors.ivory),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightCard extends StatelessWidget {
  const _WeightCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final profile = state.profile;
    final change = state.changeSinceStart;
    final hasGoalSpan = (profile.startWeightKg - profile.targetWeightKg).abs() >= 0.1;
    final percent = (state.goalProgress * 100).round();

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('CURRENT WEIGHT', style: AppText.label),
                    const SizedBox(height: 8),
                    Text(
                      '${formatKg(state.currentWeight)} kg',
                      style: AppText.display.copyWith(fontSize: 40),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      state.weights.length < 2
                          ? 'Log again to see your change.'
                          : '${signedKg(change)} since you started',
                      style: AppText.bodyMuted,
                    ),
                  ],
                ),
              ),
              if (hasGoalSpan)
                Semantics(
                  label: 'Goal progress $percent percent',
                  child: ProgressRing(
                    value: state.goalProgress,
                    size: 86,
                    strokeWidth: 8,
                    color: AppColors.forest,
                    child: Text('$percent%', style: AppText.h3),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            hasGoalSpan
                ? 'Target ${formatKg(profile.targetWeightKg)} kg'
                : 'Goal: ${profile.goal.label.toLowerCase()}',
            style: AppText.bodyMuted,
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => showLogWeightSheet(context),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Log weight'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => state.openTrack(0),
                child: const Text('Progress'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HabitsCard extends StatelessWidget {
  const _HabitsCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final HabitDay today = state.today;
    final items = <_HabitRing>[
      _HabitRing('Water', Icons.water_drop_outlined, today.waterRatio),
      _HabitRing('Move', Icons.directions_walk, today.movementRatio),
      _HabitRing('Sleep', Icons.bedtime_outlined, today.sleepRatio),
      _HabitRing('Meals', Icons.restaurant_outlined, today.mealsRatio),
    ];
    return AppCard(
      onTap: () => state.openTrack(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text("Today's habits", style: AppText.h3)),
              Text('${today.habitsDone} of 4 done', style: AppText.small),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              for (final item in items)
                Column(
                  children: <Widget>[
                    ProgressRing(
                      value: item.value,
                      size: 58,
                      strokeWidth: 5,
                      color: item.value >= 1 ? AppColors.gold : AppColors.forest,
                      child: Icon(item.icon, size: 22, color: AppColors.forest),
                    ),
                    const SizedBox(height: 6),
                    Text(item.label, style: AppText.small),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HabitRing {
  const _HabitRing(this.label, this.icon, this.value);

  final String label;
  final IconData icon;
  final double value;
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.forest,
      borderColor: AppColors.forest,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.auto_awesome, color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              Text(
                AppConfig.coachName.toUpperCase(),
                style: AppText.label.copyWith(color: AppColors.gold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Ask anything about meals, workouts or habits.',
            style: AppText.h2.copyWith(color: AppColors.ivory),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final prompt in kQuickPrompts.take(3))
                ActionChip(
                  label: Text(prompt),
                  onPressed: () => state.askCoach(prompt),
                  backgroundColor: AppColors.forestSoft,
                  side: const BorderSide(color: AppColors.forestSoft),
                  labelStyle: const TextStyle(color: AppColors.ivory, fontSize: 13),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => state.goToTab(AppTab.coach),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.ink,
              ),
              child: const Text('Open FitCoach AI'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final workout = suggestedWorkoutFor(now);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text("TODAY'S SUGGESTED WORKOUT", style: AppText.label),
          const SizedBox(height: 10),
          Text(workout.title, style: AppText.h2),
          const SizedBox(height: 4),
          Text('${workout.minutes} min  ·  ${workout.level}  ·  no equipment', style: AppText.bodyMuted),
          const SizedBox(height: 4),
          Text(workout.subtitle, style: AppText.small),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) => WorkoutPlayerScreen(workout: workout),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => AppScope.read(context).openPlan(1),
                child: const Text('All workouts'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
