import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/inputs.dart';
import 'meals_screen.dart';
import 'workouts_screen.dart';

/// The Plan tab: affordable Kenyan meals and home workouts, switched with a pill.
class PlanTab extends StatelessWidget {
  const PlanTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const ScreenHeader(
                  eyebrow: 'Plan',
                  title: 'Eat well, move gently',
                ),
                SegmentSwitch(
                  labels: const <String>['Meals', 'Workouts'],
                  icons: const <IconData>[Icons.restaurant_outlined, Icons.fitness_center],
                  selected: state.planSegment,
                  onChanged: state.setPlanSegment,
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: state.planSegment,
              children: const <Widget>[
                MealsBody(),
                WorkoutsBody(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
