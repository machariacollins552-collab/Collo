import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/workouts.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'workout_player_screen.dart';

/// Workouts: beginner-friendly home routines. No gym or equipment needed.
class WorkoutsBody extends StatelessWidget {
  const WorkoutsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final goal = state.profile.workoutDaysPerWeek;
    final done = state.workoutDaysThisWeek;
    final ratio = goal <= 0 ? 0.0 : (done / goal).clamp(0.0, 1.0).toDouble();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: <Widget>[
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Expanded(child: Text('This week', style: AppText.h3)),
                  Text('$done of $goal workout days', style: AppText.small),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: ratio, minHeight: 8),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const InfoBanner(icon: Icons.health_and_safety_outlined, text: kWorkoutSafety),
        const SectionLabel('Routines'),
        for (final workout in kWorkouts) _WorkoutCard(workout: workout),
      ],
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.workout});

  final Workout workout;

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => WorkoutPlayerScreen(workout: workout),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercises = workout.steps.where((s) => !s.isRest).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () => _open(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: AppColors.sageLight, shape: BoxShape.circle),
              child: const Icon(Icons.fitness_center, color: AppColors.forest),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(workout.title, style: AppText.h3),
                  const SizedBox(height: 3),
                  Text(workout.subtitle, style: AppText.bodyMuted),
                  const SizedBox(height: 8),
                  Text(
                    '${workout.minutes} min  ·  $exercises exercises  ·  ${workout.level}'
                    '${workout.lowImpact ? '  ·  low impact' : ''}',
                    style: AppText.small,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Icon(Icons.chevron_right, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
