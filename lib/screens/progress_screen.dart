import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../data/insights.dart';
import '../models/weight_entry.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/log_weight_sheet.dart';
import '../widgets/weight_chart.dart';

enum _Range { month, quarter, all }

/// Progress: log weight, see the trend chart and the full history. Stored on this phone only.
class ProgressBody extends StatefulWidget {
  const ProgressBody({super.key});

  @override
  State<ProgressBody> createState() => _ProgressBodyState();
}

class _ProgressBodyState extends State<ProgressBody> {
  _Range _range = _Range.all;
  bool _showAll = false;

  static const int _collapsedRows = 10;

  List<WeightEntry> _visible(AppState state) {
    final entries = state.weights;
    final days = switch (_range) {
      _Range.month => 30,
      _Range.quarter => 90,
      _Range.all => null,
    };
    if (days == null) return entries;
    final today = dateOnly(state.clock());
    final filtered = entries.where((e) => daysBetween(e.date, today) <= days).toList();
    // A chart needs at least two points; otherwise show everything.
    return filtered.length >= 2 ? filtered : entries;
  }

  Future<void> _delete(AppState state, WeightEntry entry) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete this reading?',
      message: '${formatKg(entry.kg)} kg on ${shortDateYear(entry.date)} will be removed from this phone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok) await state.deleteWeight(entry.dateKey);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final profile = state.profile;
    final entries = state.weights;

    if (entries.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: <Widget>[
          AppCard(
            child: EmptyState(
              icon: Icons.monitor_weight_outlined,
              title: 'No weight logged yet',
              message: 'Add your first reading to start your chart. Once or twice a week is plenty.',
              action: FilledButton(
                onPressed: () => showLogWeightSheet(context),
                child: const Text('Log weight'),
              ),
            ),
          ),
        ],
      );
    }

    final visible = _visible(state);
    final history = entries.reversed.toList();
    final rows = _showAll ? history : history.take(_collapsedRows).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: <Widget>[
        AppCard(
          child: Row(
            children: <Widget>[
              Expanded(child: _Stat(label: 'Start', value: '${formatKg(profile.startWeightKg)} kg')),
              Expanded(child: _Stat(label: 'Now', value: '${formatKg(state.currentWeight)} kg')),
              Expanded(child: _Stat(label: 'Target', value: '${formatKg(profile.targetWeightKg)} kg')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Expanded(child: Text('Weight trend', style: AppText.h3)),
                  Text(signedKg(state.changeSinceStart), style: AppText.small),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  for (final r in _Range.values)
                    ChoiceChip(
                      label: Text(switch (r) {
                        _Range.month => '30 days',
                        _Range.quarter => '90 days',
                        _Range.all => 'All',
                      }),
                      selected: _range == r,
                      showCheckmark: false,
                      onSelected: (bool value) => setState(() => _range = r),
                      selectedColor: AppColors.forest,
                      backgroundColor: AppColors.card,
                      side: BorderSide(color: _range == r ? AppColors.forest : AppColors.border),
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _range == r ? AppColors.ivory : AppColors.ink,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              WeightChart(entries: visible, target: profile.targetWeightKg),
              if (entries.length < 2) ...<Widget>[
                const SizedBox(height: 8),
                const Text('Log a second reading to draw your trend line.', style: AppText.small),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => showLogWeightSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Log weight'),
          ),
        ),
        const SizedBox(height: 16),
        InfoBanner(
          icon: Icons.lightbulb_outline,
          text: progressInsight(profile: profile, weights: entries),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => state.askCoach('Review my progress.'),
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Ask FitCoach to review my progress'),
          ),
        ),
        const SectionLabel('History'),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: <Widget>[
              for (var i = 0; i < rows.length; i++) ...<Widget>[
                if (i > 0) const Divider(),
                _HistoryRow(
                  entry: rows[i],
                  // The reading before this one (history is newest first).
                  previous: i + 1 < history.length ? history[i + 1] : null,
                  onDelete: () => _delete(state, rows[i]),
                ),
              ],
            ],
          ),
        ),
        if (history.length > _collapsedRows)
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () => setState(() => _showAll = !_showAll),
              child: Text(_showAll ? 'Show fewer' : 'Show all ${history.length} readings'),
            ),
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(label.toUpperCase(), style: AppText.label),
        const SizedBox(height: 6),
        Text(value, style: AppText.h3, textAlign: TextAlign.center),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry, required this.previous, required this.onDelete});

  final WeightEntry entry;
  final WeightEntry? previous;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final prev = previous;
    final delta = prev == null ? null : entry.kg - prev.kg;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('${formatKg(entry.kg)} kg', style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
                Text(longDate(entry.date), style: AppText.small),
              ],
            ),
          ),
          if (delta != null)
            Text(
              signedKg(delta),
              style: AppText.small.copyWith(
                color: delta.abs() < 0.05 ? AppColors.muted : AppColors.forest,
                fontWeight: FontWeight.w600,
              ),
            ),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Delete reading from ${shortDateYear(entry.date)}',
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
