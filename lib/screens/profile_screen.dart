import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/user_profile.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'ai_connection_screen.dart';
import 'edit_profile_screen.dart';
import 'onboarding_screen.dart';

/// Profile and settings: preferences, AI connection, privacy, and erasing local data.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _clearChat(BuildContext context, AppState state) async {
    final ok = await confirmDialog(
      context,
      title: 'Clear chat history?',
      message: 'Your conversation with FitCoach is removed from this phone. Saved plans are kept.',
      confirmLabel: 'Clear chat',
      destructive: true,
    );
    if (!ok) return;
    await state.clearChat();
    if (context.mounted) showSnack(context, 'Chat history cleared.');
  }

  Future<void> _resetAll(BuildContext context, AppState state) async {
    final ok = await confirmDialog(
      context,
      title: 'Erase all data?',
      message: 'This permanently deletes your profile, weight history, habits, chat and saved plans '
          'from this phone, then restarts setup. It cannot be undone.',
      confirmLabel: 'Erase everything',
      destructive: true,
    );
    if (!ok) return;
    await state.resetAll();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      fadeRoute<void>(const OnboardingScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final profile = state.profile;
    final name = profile.displayName;
    final connected = state.backendUrl.trim().isNotEmpty;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: <Widget>[
          const ScreenHeader(eyebrow: 'Profile', title: 'Your settings'),
          AppCard(
            child: Row(
              children: <Widget>[
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.forest,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initialOf(name),
                    style: AppText.h2.copyWith(color: AppColors.ivory),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(name, style: AppText.h2),
                      Text(profile.goal.label, style: AppText.bodyMuted),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SectionLabel('Preferences'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _Line('Starting weight', '${formatKg(profile.startWeightKg)} kg'),
                _Line('Target weight', '${formatKg(profile.targetWeightKg)} kg'),
                _Line('Daily food budget', 'KSh ${profile.dailyBudgetKsh}'),
                _Line('Eating style', profile.diet.label),
                _Line('Equipment', profile.equipment.label),
                _Line('Workout days', '${profile.workoutDaysPerWeek} a week'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => const EditProfileScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit preferences'),
                  ),
                ),
              ],
            ),
          ),
          const SectionLabel('FitCoach AI'),
          AppCard(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const AiConnectionScreen(),
                ),
              );
            },
            child: Row(
              children: <Widget>[
                Icon(
                  connected ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                  color: connected ? AppColors.forest : AppColors.danger,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('AI connection', style: AppText.h3),
                      const SizedBox(height: 2),
                      Text(
                        connected ? 'Server address set. Tap to test it.' : 'Not connected. Tap to set up.',
                        style: AppText.small,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
          const SectionLabel('Privacy'),
          AppCard(
            padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'Share goal, weight and preferences with FitCoach',
                        style: AppText.body,
                      ),
                    ),
                    Switch(
                      value: profile.shareContextWithCoach,
                      onChanged: (bool value) =>
                          state.updateProfile(profile.copyWith(shareContextWithCoach: value)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    'Everything you log stays on this phone. There is no account and no analytics. '
                    'When you chat, your message (and, if this is on, your goal, weight, budget and '
                    'preferences) is sent over HTTPS to your FitCoach server and Google Gemini to '
                    'write a reply. Your server does not store chat messages. On Google\'s free tier, '
                    'Google may use chat content to improve its products and people may review it, so '
                    'do not type private details such as phone numbers or medical records.',
                    style: AppText.small,
                  ),
                ),
              ],
            ),
          ),
          const SectionLabel('Your data'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Column(
              children: <Widget>[
                _ActionRow(
                  icon: Icons.clear_all,
                  title: 'Clear chat history',
                  subtitle: '${state.chat.length} messages on this phone',
                  onTap: () => _clearChat(context, state),
                ),
                const Divider(),
                _ActionRow(
                  icon: Icons.restart_alt,
                  title: 'Erase all data',
                  subtitle: 'Profile, weights, habits, chat and saved plans',
                  destructive: true,
                  onTap: () => _resetAll(context, state),
                ),
              ],
            ),
          ),
          const SectionLabel('About'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('${AppConfig.appName}  ·  version ${AppConfig.version}', style: AppText.body),
                const SizedBox(height: 8),
                const Text(
                  'FitCoach AI offers general wellbeing information, not medical advice. It cannot '
                  'diagnose conditions and does not replace a doctor, nurse or dietitian. If you feel '
                  'unwell, have a health condition, are pregnant or take medication, speak to a qualified '
                  'health professional before changing your diet or exercise. In an emergency, contact '
                  'your local emergency services.',
                  style: AppText.small,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: Text(label, style: AppText.bodyMuted)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppText.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.danger : AppColors.forest;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: <Widget>[
            Icon(icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: color)),
                  Text(subtitle, style: AppText.small),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
