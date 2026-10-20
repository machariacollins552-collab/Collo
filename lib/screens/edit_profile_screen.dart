import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/user_profile.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/inputs.dart';

/// Edit the answers given during onboarding. Changes are saved only when "Save" is tapped.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _start;
  late final TextEditingController _target;
  late Goal _goal;
  late int _budget;
  late Diet _diet;
  late Equipment _equipment;
  late int _days;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = AppScope.read(context).profile;
    _name = TextEditingController(text: p.name);
    _start = TextEditingController(text: formatKg(p.startWeightKg));
    _target = TextEditingController(text: formatKg(p.targetWeightKg));
    _goal = p.goal;
    _budget = p.dailyBudgetKsh;
    _diet = p.diet;
    _equipment = p.equipment;
    _days = p.workoutDaysPerWeek;
  }

  @override
  void dispose() {
    _name.dispose();
    _start.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final start = parseNumber(_start.text);
    final target = parseNumber(_target.text);
    String? error;
    if (start == null || start < AppConfig.minWeightKg || start > AppConfig.maxWeightKg) {
      error = 'Enter a starting weight in kg, for example 72.5.';
    } else if (target == null || target < AppConfig.minWeightKg || target > AppConfig.maxWeightKg) {
      error = 'Enter a target weight in kg, for example 68.';
    } else if (_goal == Goal.loseWeight && target >= start) {
      error = 'For gradual weight loss, your target should be below your starting weight.';
    } else if (_goal == Goal.loseWeight && (start - target) / start > 0.25) {
      error = 'That is a big change. Pick a nearer first target (you can change it any time).';
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final state = AppScope.read(context);
    await state.updateProfile(
      state.profile.copyWith(
        name: _name.text.trim(),
        goal: _goal,
        startWeightKg: round1(start!),
        targetWeightKg: round1(target!),
        dailyBudgetKsh: _budget,
        diet: _diet,
        equipment: _equipment,
        workoutDaysPerWeek: _days,
      ),
    );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(const SnackBar(content: Text('Preferences saved.')));
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
        if (_error != null) setState(() => _error = null);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit preferences'),
        backgroundColor: AppColors.ivory,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: <Widget>[
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 24,
                    decoration: fieldDecoration('Your name (optional)').copyWith(counterText: ''),
                  ),
                  const SectionLabel('Main goal'),
                  ChoiceCards<Goal>(
                    options: Goal.values,
                    selected: _goal,
                    onChanged: (Goal g) => setState(() => _goal = g),
                    labelOf: (Goal g) => g.label,
                    subtitleOf: (Goal g) => g.blurb,
                  ),
                  const SectionLabel('Weights'),
                  _weightField(_start, 'Starting weight'),
                  const SizedBox(height: 12),
                  _weightField(_target, 'Target weight'),
                  if (_error != null) ...<Widget>[
                    const SizedBox(height: 12),
                    InfoBanner(
                      icon: Icons.info_outline,
                      text: _error!,
                      color: AppColors.dangerSoft,
                      iconColor: AppColors.danger,
                    ),
                  ],
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _save, child: const Text('Save changes')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
