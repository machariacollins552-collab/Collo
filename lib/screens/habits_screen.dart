import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/habit_day.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/progress_ring.dart';

/// Habits: water, movement, sleep and meal consistency for today, plus the last 7 days.
class HabitsBody extends StatelessWidget {
  const HabitsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final today = state.today;
    final week = state.lastDays(7);
    final now = dateOnly(state.clock());
    final strongDays = week.where((d) => d.habitsDone >= 3).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: <Widget>[
        AppCard(
          child: Row(
            children: <Widget>[
              ProgressRing(
                value: today.completion,
                size: 72,
                strokeWidth: 7,
                child: Text('${(today.completion * 100).round()}%', style: AppText.body),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(longDate(now), style: AppText.h3),
                    const SizedBox(height: 4),
                    Text('${today.habitsDone} of 4 daily goals reached', style: AppText.bodyMuted),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _HabitCard(
          icon: Icons.water_drop_outlined,
          title: 'Water',
          valueText: '${today.water} of ${AppConfig.waterGoal} glasses',
          ratio: today.waterRatio,
          decreaseLabel: 'Remove a glass of water',
          increaseLabel: 'Add a glass of water',
          onDecrease: () => state.adjustWater(-1),
          onIncrease: () => state.adjustWater(1),
        ),
        const SizedBox(height: 12),
        _HabitCard(
          icon: Icons.directions_walk,
          title: 'Movement',
          valueText: '${today.movementMinutes} of ${AppConfig.movementGoalMinutes} minutes',
          ratio: today.movementRatio,
          decreaseLabel: 'Remove 10 minutes of movement',
          increaseLabel: 'Add 10 minutes of movement',
          onDecrease: () => state.adjustMovement(-10),
          onIncrease: () => state.adjustMovement(10),
          stepHint: '10 min',
        ),
        const SizedBox(height: 12),
        _HabitCard(
          icon: Icons.bedtime_outlined,
          title: 'Sleep (last night)',
          valueText: '${formatKg(today.sleepHours)} of ${formatKg(AppConfig.sleepGoalHours)} hours',
          ratio: today.sleepRatio,
          decreaseLabel: 'Remove half an hour of sleep',
          increaseLabel: 'Add half an hour of sleep',
          onDecrease: () => state.adjustSleep(-0.5),
          onIncrease: () => state.adjustSleep(0.5),
          stepHint: '30 min',
        ),
        const SizedBox(height: 12),
        _HabitCard(
          icon: Icons.restaurant_outlined,
          title: 'Meals on track',
          valueText: '${today.mealsOnTrack} of ${AppConfig.mealsGoal} meals',
          ratio: today.mealsRatio,
          decreaseLabel: 'Remove a meal on track',
          increaseLabel: 'Add a meal on track',
          onDecrease: () => state.adjustMeals(-1),
          onIncrease: () => state.adjustMeals(1),
        ),
        const SectionLabel('Last 7 days'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  for (var i = 0; i < week.length; i++)
                    _DayDot(
                      day: week[i],
                      date: now.subtract(Duration(days: week.length - 1 - i)),
                      isToday: i == week.length - 1,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '$strongDays of 7 days with three or more habits done. '
                'Missing a day is normal. Simply begin again.',
                style: AppText.small,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.icon,
    required this.title,
    required this.valueText,
    required this.ratio,
    required this.decreaseLabel,
    required this.increaseLabel,
    required this.onDecrease,
    required this.onIncrease,
    this.stepHint,
  });

  final IconData icon;
  final String title;
  final String valueText;
  final double ratio;
  final String decreaseLabel;
  final String increaseLabel;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final String? stepHint;

  @override
  Widget build(BuildContext context) {
    final reached = ratio >= 1;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: reached ? AppColors.gold.withValues(alpha: 0.25) : AppColors.sageLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(reached ? Icons.check : icon, color: AppColors.forest, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: AppText.h3),
                    Text(
                      stepHint == null ? valueText : '$valueText  ·  steps of $stepHint',
                      style: AppText.small,
                    ),
                  ],
                ),
              ),
              IconButton.outlined(
                onPressed: onDecrease,
                tooltip: decreaseLabel,
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                onPressed: onIncrease,
                tooltip: increaseLabel,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                color: reached ? AppColors.gold : AppColors.forest,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({required this.day, required this.date, required this.isToday});

  final HabitDay day;
  final DateTime date;
  final bool isToday;

  static const List<String> _initials = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final percent = (day.completion * 100).round();
    return Semantics(
      label: '${longDate(date)}, $percent percent of habits',
      child: Column(
        children: <Widget>[
          ProgressRing(
            value: day.completion,
            size: 34,
            strokeWidth: 4,
            color: day.habitsDone >= 3 ? AppColors.gold : AppColors.forest,
          ),
          const SizedBox(height: 6),
          Text(
            _initials[date.weekday - 1],
            style: AppText.small.copyWith(
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
              color: isToday ? AppColors.forest : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
