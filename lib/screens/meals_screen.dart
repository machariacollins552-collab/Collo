import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../data/meals.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/formatted_text.dart';
import '../widgets/inputs.dart';

/// Meals: a budget-aware day plan from familiar Kenyan foods, portion guidance,
/// swaps, and plans the user has saved (these work offline).
class MealsBody extends StatefulWidget {
  const MealsBody({super.key});

  @override
  State<MealsBody> createState() => _MealsBodyState();
}

class _MealsBodyState extends State<MealsBody> {
  int? _seed;
  int? _dragBudget;

  static String _clip(String text, int max) => text.length <= max ? text : text.substring(0, max);

  static String _planText(DayPlan plan, int budget) {
    final b = StringBuffer('Meal plan for KSh $budget a day\n');
    for (final meal in plan.meals) {
      b.writeln('- ${meal.slot.label}: ${meal.name} (${meal.portion}) - about KSh ${meal.costKsh}');
    }
    b.write('Total: about KSh ${plan.totalCost}, around ${plan.totalKcal} kcal (estimates)');
    return b.toString();
  }

  Future<void> _savePlan(AppState state, DayPlan plan, int budget) async {
    final message = ChatMessage.assistant(_planText(plan, budget), state.clock());
    if (state.isSaved(message)) {
      showSnack(context, 'This plan is already saved.');
      return;
    }
    await state.savePlan(message);
    if (mounted) showSnack(context, 'Plan saved. You can read it offline below.');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final profile = state.profile;
    final budget = _dragBudget ?? profile.dailyBudgetKsh;
    final seed = _seed ?? dayOfYear(state.clock());
    final plan = MealPlanner.plan(budget: budget, diet: profile.diet, seed: seed);
    final overBudget = plan.totalCost > budget;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: <Widget>[
        AppCard(
          child: LabeledSlider(
            label: 'Daily food budget',
            valueLabel: 'KSh $budget',
            value: budget.toDouble(),
            min: 100,
            max: 1000,
            divisions: 18,
            onChanged: (double v) => setState(() => _dragBudget = v.round()),
            onChangeEnd: (double v) async {
              final value = v.round();
              await state.updateProfile(state.profile.copyWith(dailyBudgetKsh: value));
              if (mounted) setState(() => _dragBudget = null);
            },
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Expanded(child: Text("Today's plan", style: AppText.h2)),
                  TextButton.icon(
                    onPressed: () => setState(() => _seed = seed + 1),
                    icon: const Icon(Icons.shuffle, size: 18),
                    label: const Text('Shuffle'),
                  ),
                ],
              ),
              Text(profile.diet.label, style: AppText.small),
              const SizedBox(height: 8),
              for (final meal in plan.meals) _MealTile(meal: meal),
              const Divider(height: 24),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'About KSh ${plan.totalCost}  ·  ~${plan.totalKcal} kcal',
                      style: AppText.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Prices and calories are rough estimates. Markets and portions vary.',
                style: AppText.small,
              ),
              if (overBudget) ...<Widget>[
                const SizedBox(height: 10),
                const InfoBanner(
                  icon: Icons.info_outline,
                  text: 'This is the cheapest combination we have, a little above your budget today. '
                      'Ask FitCoach for swaps that stretch your shillings.',
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _savePlan(state, plan, budget),
                      icon: const Icon(Icons.bookmark_border, size: 18),
                      label: const Text('Save'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () => state.askCoach(
                        _clip(
                          'Please adapt this meal plan to my budget of KSh $budget a day and suggest cheaper '
                          'or healthier swaps. ${plan.toSummary()}',
                          480,
                        ),
                      ),
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('Adapt with FitCoach'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SectionLabel('Build your plate'),
        _TipsCard(tips: kPlateGuide),
        const SectionLabel('Simple swaps'),
        _TipsCard(tips: kSwaps),
        const SectionLabel('Saved plans'),
        if (state.plans.isEmpty)
          const AppCard(
            child: EmptyState(
              icon: Icons.bookmark_border,
              title: 'Nothing saved yet',
              message: 'Save a meal plan above, or save a FitCoach answer. Saved plans open without internet.',
            ),
          )
        else
          for (final saved in state.plans) _SavedPlanTile(plan: saved, state: state),
      ],
    );
  }
}

class _MealTile extends StatelessWidget {
  const _MealTile({required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 4,
            height: 58,
            margin: const EdgeInsets.only(right: 12, top: 2),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(meal.slot.label.toUpperCase(), style: AppText.label),
                const SizedBox(height: 4),
                Text(meal.name, style: AppText.h3),
                const SizedBox(height: 2),
                Text(meal.portion, style: AppText.small),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text('KSh ${meal.costKsh}', style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
              Text('${meal.kcal} kcal', style: AppText.small),
            ],
          ),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.tips});

  final List<GuideTip> tips;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (var i = 0; i < tips.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 22),
            Text(tips[i].title, style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(tips[i].body, style: AppText.bodyMuted),
          ],
        ],
      ),
    );
  }
}

class _SavedPlanTile extends StatelessWidget {
  const _SavedPlanTile({required this.plan, required this.state});

  final SavedPlan plan;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(plan.title, style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
          subtitle: Text('Saved ${shortDate(plan.savedAt)}', style: AppText.small),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            FormattedText(plan.body),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  final ok = await confirmDialog(
                    context,
                    title: 'Delete saved plan?',
                    message: 'This removes it from this phone.',
                    confirmLabel: 'Delete',
                    destructive: true,
                  );
                  if (ok) await state.deletePlan(plan.id);
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
