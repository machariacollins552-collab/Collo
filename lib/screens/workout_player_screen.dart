import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../data/workouts.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/progress_ring.dart';

enum _Phase { preview, running, done }

/// A guided workout: shows the steps, counts down timed exercises, and records the
/// finished session in today's habits.
class WorkoutPlayerScreen extends StatefulWidget {
  const WorkoutPlayerScreen({super.key, required this.workout});

  final Workout workout;

  @override
  State<WorkoutPlayerScreen> createState() => _WorkoutPlayerScreenState();
}

class _WorkoutPlayerScreenState extends State<WorkoutPlayerScreen> {
  _Phase _phase = _Phase.preview;
  int _index = 0;
  int _remaining = 0;
  bool _paused = false;
  Timer? _timer;

  Workout get _workout => widget.workout;
  WorkoutStep get _step => _workout.steps[_index];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() => _phase = _Phase.running);
    _goTo(0);
  }

  /// Moves to the step at [index] and starts its countdown when it is timed.
  void _goTo(int index) {
    _timer?.cancel();
    final step = _workout.steps[index];
    setState(() {
      _index = index;
      _remaining = step.seconds ?? 0;
      _paused = false;
    });
    HapticFeedback.lightImpact();
    if (step.isTimed) {
      _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) => _tick());
    }
  }

  void _tick() {
    if (!mounted || _paused) return;
    if (_remaining <= 1) {
      _next();
    } else {
      setState(() => _remaining -= 1);
    }
  }

  void _next() {
    if (_index >= _workout.steps.length - 1) {
      _finish();
    } else {
      _goTo(_index + 1);
    }
  }

  void _previous() {
    if (_index > 0) _goTo(_index - 1);
  }

  void _togglePause() => setState(() => _paused = !_paused);

  Future<void> _finish() async {
    _timer?.cancel();
    final state = AppScope.read(context);
    await state.recordWorkout(_workout.minutes);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _phase = _Phase.done);
  }

  Future<void> _confirmExit() async {
    final leave = await confirmDialog(
      context,
      title: 'End this workout?',
      message: 'Your progress in this session will not be saved.',
      confirmLabel: 'End workout',
      destructive: true,
    );
    if (leave && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _phase != _Phase.running,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_workout.title),
          backgroundColor: AppColors.ivory,
          surfaceTintColor: Colors.transparent,
        ),
        body: SafeArea(
          child: switch (_phase) {
            _Phase.preview => _buildPreview(),
            _Phase.running => _buildRunning(),
            _Phase.done => _buildDone(),
          },
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: <Widget>[
              Text(_workout.subtitle, style: AppText.bodyMuted),
              const SizedBox(height: 6),
              Text(
                '${_workout.minutes} min  ·  ${_workout.level}  ·  no equipment',
                style: AppText.small,
              ),
              const SizedBox(height: 14),
              const InfoBanner(icon: Icons.health_and_safety_outlined, text: kWorkoutSafety),
              const SectionLabel('What you will do'),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (var i = 0; i < _workout.steps.length; i++) ...<Widget>[
                      if (i > 0) const Divider(height: 20),
                      _PreviewRow(step: _workout.steps[i]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _start,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start workout'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRunning() {
    final step = _step;
    final total = _workout.steps.length;
    final isLast = _index == total - 1;
    final next = isLast ? null : _workout.steps[_index + 1];
    final ratio = step.isTimed && (step.seconds ?? 0) > 0 ? _remaining / step.seconds! : 1.0;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: _index / total, minHeight: 6),
                ),
              ),
              const SizedBox(width: 12),
              Text('${_index + 1} / $total', style: AppText.small),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            children: <Widget>[
              Center(
                child: Semantics(
                  liveRegion: true,
                  label: step.isTimed ? '$_remaining seconds left' : step.reps,
                  child: ProgressRing(
                    value: ratio,
                    size: 180,
                    strokeWidth: 10,
                    color: step.isRest ? AppColors.sage : AppColors.forest,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: step.isTimed
                          ? Text('$_remaining', style: AppText.display.copyWith(fontSize: 56))
                          : Text(
                              step.reps ?? '',
                              textAlign: TextAlign.center,
                              style: AppText.h1,
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                step.isRest ? 'REST' : 'EXERCISE',
                textAlign: TextAlign.center,
                style: AppText.label.copyWith(color: AppColors.goldText),
              ),
              const SizedBox(height: 8),
              Text(step.name, textAlign: TextAlign.center, style: AppText.h1),
              const SizedBox(height: 10),
              Text(step.howTo, textAlign: TextAlign.center, style: AppText.bodyMuted),
              if (next != null) ...<Widget>[
                const SizedBox(height: 22),
                Text(
                  'Next: ${next.name}',
                  textAlign: TextAlign.center,
                  style: AppText.small,
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            children: <Widget>[
              IconButton.outlined(
                onPressed: _index > 0 ? _previous : null,
                tooltip: 'Previous step',
                icon: const Icon(Icons.skip_previous_rounded),
              ),
              const SizedBox(width: 10),
              if (step.isTimed) ...<Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _togglePause,
                    icon: Icon(_paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                    label: Text(_paused ? 'Resume' : 'Pause'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: _next,
                  child: Text(isLast ? 'Finish' : (step.isTimed ? 'Skip' : 'Done')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDone() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.sageLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 1.6),
            ),
            child: const Icon(Icons.check, size: 42, color: AppColors.forest),
          ),
          const SizedBox(height: 24),
          const Text('Well done', style: AppText.h1),
          const SizedBox(height: 10),
          Text(
            '${_workout.minutes} minutes added to today\'s movement. Every session counts, '
            'so rest well and drink some water.',
            textAlign: TextAlign.center,
            style: AppText.bodyMuted,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.step});

  final WorkoutStep step;

  @override
  Widget build(BuildContext context) {
    final amount = step.isTimed ? '${step.seconds}s' : (step.reps ?? '');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                step.name,
                style: AppText.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: step.isRest ? AppColors.muted : AppColors.ink,
                ),
              ),
              if (!step.isRest) ...<Widget>[
                const SizedBox(height: 2),
                Text(step.howTo, style: AppText.small),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(amount, style: AppText.body.copyWith(color: AppColors.goldText, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
