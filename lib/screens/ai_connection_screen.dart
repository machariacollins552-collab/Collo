import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../services/coach_service.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// Where the user pastes the address of their FitCoach backend and tests it.
/// The address is not a secret. The AI key itself lives only on the server.
class AiConnectionScreen extends StatefulWidget {
  const AiConnectionScreen({super.key});

  @override
  State<AiConnectionScreen> createState() => _AiConnectionScreenState();
}

class _AiConnectionScreenState extends State<AiConnectionScreen> {
  late final TextEditingController _controller;
  String? _fieldError;
  bool _testing = false;
  HealthResult? _result;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: AppScope.read(context).profile.backendUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Returns the cleaned address ('' means "use the built-in default"), or null if invalid.
  String? _cleanAddress() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return '';
    return CoachService.normalizeBaseUrl(raw);
  }

  Future<void> _save() async {
    final state = AppScope.read(context);
    final cleaned = _cleanAddress();
    if (cleaned == null) {
      setState(() => _fieldError = 'The address must look like https://your-name.workers.dev');
      return;
    }
    setState(() => _fieldError = null);
    await state.updateProfile(state.profile.copyWith(backendUrl: cleaned));
    if (!mounted) return;
    _controller.text = cleaned;
    showSnack(context, cleaned.isEmpty ? 'Using the built-in address.' : 'Address saved.');
  }

  Future<void> _test() async {
    final state = AppScope.read(context);
    final cleaned = _cleanAddress();
    if (cleaned == null) {
      setState(() => _fieldError = 'The address must look like https://your-name.workers.dev');
      return;
    }
    final target = cleaned.isEmpty ? AppConfig.defaultBackendUrl : cleaned;
    setState(() {
      _fieldError = null;
      _testing = true;
      _result = null;
    });
    final result = await state.coach.checkHealth(target);
    if (!mounted) return;
    setState(() {
      _testing = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasDefault = AppConfig.defaultBackendUrl.isNotEmpty;
    final result = _result;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI connection'),
        backgroundColor: AppColors.ivory,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: <Widget>[
            const Text(
              'FitCoach AI answers through a small server that you own. It keeps the AI key safe, '
              'so the key is never stored in this app.',
              style: AppText.bodyMuted,
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableSuggestions: false,
              decoration: fieldDecoration(
                'Server address',
                hint: 'https://collins-fit-ai-coach.your-name.workers.dev',
                errorText: _fieldError,
              ),
              onChanged: (_) {
                if (_fieldError != null || _result != null) {
                  setState(() {
                    _fieldError = null;
                    _result = null;
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              hasDefault
                  ? 'Leave this empty to use the address built into this app.'
                  : 'No address is built into this app, so paste yours here.',
              style: AppText.small,
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _testing ? null : _test,
                    child: _testing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Test connection'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(onPressed: _save, child: const Text('Save')),
                ),
              ],
            ),
            if (result != null) ...<Widget>[
              const SizedBox(height: 16),
              InfoBanner(
                icon: result.ok ? Icons.check_circle_outline : Icons.error_outline,
                text: result.message,
                color: result.ok ? AppColors.sageLight : AppColors.dangerSoft,
                iconColor: result.ok ? AppColors.forest : AppColors.danger,
              ),
            ],
            const SizedBox(height: 24),
            const InfoBanner(
              icon: Icons.shield_outlined,
              text: 'Your chat messages travel over HTTPS to your server and on to Google Gemini. '
                  'On Google\'s free tier, Google may use them to improve its products, so keep private '
                  'details out of the chat. Nothing is sent to advertising or analytics services.',
            ),
          ],
        ),
      ),
    );
  }
}
