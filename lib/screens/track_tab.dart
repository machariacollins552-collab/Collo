import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/inputs.dart';
import 'habits_screen.dart';
import 'progress_screen.dart';

/// The Track tab: weight progress and daily habits, switched with a pill.
class TrackTab extends StatelessWidget {
  const TrackTab({super.key});

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
                  eyebrow: 'Track',
                  title: 'Small steps, steady trend',
                ),
                SegmentSwitch(
                  labels: const <String>['Weight', 'Habits'],
                  icons: const <IconData>[Icons.monitor_weight_outlined, Icons.check_circle_outline],
                  selected: state.trackSegment,
                  onChanged: state.setTrackSegment,
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: state.trackSegment,
              children: const <Widget>[
                ProgressBody(),
                HabitsBody(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
