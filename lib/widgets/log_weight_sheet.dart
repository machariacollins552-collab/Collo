import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../state/app_state.dart';

/// Opens the "Log weight" bottom sheet. Used from Home and from the Progress screen.
Future<void> showLogWeightSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.ivory,
    builder: (BuildContext sheetContext) => const _LogWeightSheet(),
  );
}

class _LogWeightSheet extends StatefulWidget {
  const _LogWeightSheet();

  @override
  State<_LogWeightSheet> createState() => _LogWeightSheetState();
}

class _LogWeightSheetState extends State<_LogWeightSheet> {
  late final TextEditingController _controller;
  late DateTime _date;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final state = AppScope.read(context);
    _date = dateOnly(state.clock());
    _controller = TextEditingController(text: formatKg(state.currentWeight));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final state = AppScope.read(context);
    final today = dateOnly(state.clock());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(today.year - 3, 1, 1),
      lastDate: today,
    );
    if (picked != null && mounted) {
      setState(() => _date = dateOnly(picked));
    }
  }

  Future<void> _save() async {
    final state = AppScope.read(context);
    final value = parseNumber(_controller.text);
    if (value == null || value < AppConfig.minWeightKg || value > AppConfig.maxWeightKg) {
      setState(() => _error =
          'Enter a weight between ${formatKg(AppConfig.minWeightKg)} and ${formatKg(AppConfig.maxWeightKg)} kg.');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    final ok = await state.logWeight(value, date: _date);
    if (!mounted) return;
    if (ok) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('Logged ${formatKg(value)} kg. Nice work.')));
    } else {
      setState(() {
        _saving = false;
        _error = 'That number looks off. Please check it.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final state = AppScope.read(context);
    final isToday = _date == dateOnly(state.clock());
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Log your weight', style: AppText.h2),
            const SizedBox(height: 6),
            const Text(
              'One reading per day. Logging again on the same day replaces it.',
              style: AppText.bodyMuted,
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: fieldDecoration('Weight', suffixText: 'kg', errorText: _error),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(isToday ? 'Today, ${shortDate(_date)}' : longDate(_date)),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: const Text('Save weight'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
