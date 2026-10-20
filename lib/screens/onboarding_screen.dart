import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/user_profile.dart';
import '../state/app_state.dart';
import '../widgets/brand_mark.dart';
import '../widgets/common.dart';
import '../widgets/inputs.dart';
import 'shell_screen.dart';

/// First-run setup: four short steps that collect goals and preferences.
/// Everything is stored on this phone only.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _lastStep = 3;

  int _step = 0;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _startController = TextEditingController(text: '70');
  final TextEditingController _targetController = TextEditingController(text: '65');

  Goal _goal = Goal.loseWeight;
  int _budget = 300;
  Diet _diet = Diet.everything;
  Equipment _equipment = Equipment.none;
  int _days = 3;
  bool _share = true;
  String? _weightError;
  bool _finishing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _startController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  /// Checks the two weights. Returns true when they are usable.
  bool _validateWeights() {
    final start = parseNumber(_startController.text);
    final target = parseNumber(_targetController.text);
    String? error;
    if (start == null || start < AppConfig.minWeightKg || start > AppConfig.maxWeightKg) {
      error = 'Enter your current weight in kg, for example 72.5.';
    } else if (target == null || target < AppConfig.minWeightKg || target > AppConfig.maxWeightKg) {
      error = 'Enter a target weight in kg, for example 68.';
    } else if (_goal == Goal.loseWeight && target >= start) {
      error = 'For gradual weight loss, your target should be below your current weight.';
    } else if (_goal == Goal.loseWeight && (start - target) / start > 0.25) {
      error = 'That is a big change. Pick a nearer first target (you can change it any time).';
    }
    setState(() => _weightError = error);
    return error == null;
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_step == 2 && !_validateWeights()) return;
    if (_step < _lastStep) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _finish() async {
    if (_finishing) return;
    if (!_validateWeights()) {
      setState(() => _step = 2);
      return;
    }
    setState(() => _finishing = true);
    final state = AppScope.read(context);
    final profile = UserProfile(
      name: _nameController.text.trim(),
      goal: _goal,
      startWeightKg: round1(parseNumber(_startController.text) ?? 70),
      targetWeightKg: round1(parseNumber(_targetController.text) ?? 65),
      dailyBudgetKsh: _budget,
      diet: _diet,
      equipment: _equipment,
      workoutDaysPerWeek: _days,
      shareContextWithCoach: _share,
      onboarded: true,
    );
    await state.completeOnboarding(profile);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(fadeRoute<void>(const ShellScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _buildTopBar(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: SingleChildScrollView(
                  key: ValueKey<int>(_step),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: _buildStep(),
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 48,
            height: 48,
            child: _step > 0
                ? IconButton(
                    onPressed: _back,
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back),
                  )
                : null,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (var i = 0; i <= _lastStep; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _step ? 26 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i <= _step ? AppColors.forest : AppColors.sage.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
          Text('${_step + 1} / ${_lastStep + 1}', style: AppText.small),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLast = _step == _lastStep;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _finishing ? null : _next,
          child: Text(isLast ? 'Start my journey' : 'Continue'),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _welcomeStep();
      case 1:
        return _goalStep();
      case 2:
        return _weightStep();
      default:
        return _routineStep();
    }
  }

  Widget _welcomeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 12),
        const BrandMark(size: 72, onDark: false),
        const SizedBox(height: 24),
        const Text('Welcome to\nCollins Fit AI', style: AppText.h1),
        const SizedBox(height: 10),
        const GoldRule(),
        const SizedBox(height: 14),
        const Text(
          'A calm place to build healthy habits with affordable Kenyan meals, simple home '
          'workouts, honest progress tracking and a friendly AI coach.',
          style: AppText.bodyMuted,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          maxLength: 24,
          decoration: fieldDecoration('What should we call you? (optional)').copyWith(counterText: ''),
        ),
        const SizedBox(height: 16),
        const InfoBanner(
          icon: Icons.lock_outline,
          text: 'Takes about a minute. Your details stay on this phone and you can erase them any time.',
        ),
      ],
    );
  }

  Widget _goalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 12),
        const Text('What is your main goal?', style: AppText.h1),
        const SizedBox(height: 8),
        const Text('Pick the one that feels right today. You can change it later.', style: AppText.bodyMuted),
        const SizedBox(height: 22),
        ChoiceCards<Goal>(
          options: Goal.values,
          selected: _goal,
          onChanged: (Goal g) => setState(() => _goal = g),
          labelOf: (Goal g) => g.label,
          subtitleOf: (Goal g) => g.blurb,
        ),
      ],
    );
  }

  Widget _weightStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 12),
        const Text('Your starting point', style: AppText.h1),
        const SizedBox(height: 8),
        const Text(
          'We use these two numbers to draw your progress chart. They are saved only on this phone.',
          style: AppText.bodyMuted,
        ),
        const SizedBox(height: 22),
        _weightField(_startController, 'Current weight'),
        const SizedBox(height: 14),
        _weightField(_targetController, 'Target weight'),
        if (_weightError != null) ...<Widget>[
          const SizedBox(height: 12),
          InfoBanner(
            icon: Icons.info_outline,
            text: _weightError!,
            color: AppColors.dangerSoft,
            iconColor: AppColors.danger,
          ),
        ],
        const SizedBox(height: 16),
        const Text(
          'Healthy, sustainable change is usually about 0.25 to 0.75 kg a week.',
          style: AppText.small,
        ),
      ],
    );
  }

  Widget _weightField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        LengthLimitingTextInputFormatter(6),
      ],
      decoration: fieldDecoration(label, suffixText: 'kg'),
      onChanged: (_) {
        if (_weightError != null) setState(() => _weightError = null);
      },
    );
  }

  Widget _routineStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 12),
        const Text('Your everyday routine', style: AppText.h1),
        const SizedBox(height: 8),
        const Text('So meal and workout ideas fit your life and your pocket.', style: AppText.bodyMuted),
        const SizedBox(height: 18),
        LabeledSlider(
          label: 'Daily food budget',
          valueLabel: 'KSh $_budget',
          value: _budget.toDouble(),
          min: 100,
          max: 1000,
          divisions: 18,
          onChanged: (double v) => setState(() => _budget = v.round()),
        ),
        const SectionLabel('Eating style'),
        ChipChoice<Diet>(
          options: Diet.values,
          selected: _diet,
          onChanged: (Diet d) => setState(() => _diet = d),
          labelOf: (Diet d) => d.label,
        ),
        const SectionLabel('Equipment at home'),
        ChipChoice<Equipment>(
          options: Equipment.values,
          selected: _equipment,
          onChanged: (Equipment e) => setState(() => _equipment = e),
          labelOf: (Equipment e) => e.label,
        ),
        const SizedBox(height: 18),
        LabeledSlider(
          label: 'Workout days a week',
          valueLabel: '$_days',
          value: _days.toDouble(),
          min: 1,
          max: 6,
          divisions: 5,
          onChanged: (double v) => setState(() => _days = v.round()),
        ),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Let FitCoach AI see my goal, weight and preferences so its advice is personal.',
                  style: AppText.small,
                ),
              ),
              Switch(value: _share, onChanged: (bool v) => setState(() => _share = v)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Collins Fit AI offers general wellbeing guidance. It does not replace a doctor or dietitian.',
          style: AppText.small,
        ),
      ],
    );
  }
}
