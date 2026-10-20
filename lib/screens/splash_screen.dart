import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/brand_mark.dart';
import '../widgets/common.dart';
import 'onboarding_screen.dart';
import 'shell_screen.dart';

/// Branded opening screen. After a moment it moves on to onboarding (first run) or the app.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.duration = const Duration(milliseconds: 1600)});

  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, _continue);
  }

  void _continue() {
    if (!mounted) return;
    final state = AppScope.read(context);
    final Widget next = state.profile.onboarded ? const ShellScreen() : const OnboardingScreen();
    Navigator.of(context).pushReplacement(fadeRoute<void>(next));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.forest,
        body: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (BuildContext context, double value, Widget? child) {
              return Opacity(opacity: value, child: child);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const BrandMark(size: 104),
                  const SizedBox(height: 32),
                  Text(
                    AppConfig.appName,
                    textAlign: TextAlign.center,
                    style: AppText.h1.copyWith(color: AppColors.ivory, fontSize: 34),
                  ),
                  const SizedBox(height: 14),
                  const GoldRule(width: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Calm, practical fitness for everyday life',
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(color: AppColors.sage),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
