import 'package:flutter/material.dart';

import '../core/theme.dart';

/// A rounded ivory card with a subtle border and a restrained shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.onTap,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: radius,
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x0D183D30), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Large serif title with an optional small caps eyebrow, subtitle and trailing widget.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (eyebrow != null) ...<Widget>[
                  Text(eyebrow!.toUpperCase(), style: AppText.label),
                  const SizedBox(height: 6),
                ],
                Text(title, style: AppText.h1),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(subtitle!, style: AppText.bodyMuted),
                ],
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

/// Small uppercase label that introduces a group of content.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(text.toUpperCase(), style: AppText.label)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Friendly placeholder for screens or lists with nothing to show yet.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: AppColors.sageLight, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.forest, size: 30),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppText.h3, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(message, style: AppText.bodyMuted, textAlign: TextAlign.center),
          if (action != null) ...<Widget>[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

/// A short thin gold rule used as a quiet decorative accent.
class GoldRule extends StatelessWidget {
  const GoldRule({super.key, this.width = 40});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(width: width, height: 2, color: AppColors.gold);
  }
}

/// A one-line notice with an icon, used for offline and safety messages.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.icon,
    required this.text,
    this.color = AppColors.sageLight,
    this.iconColor = AppColors.forest,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppText.small.copyWith(color: AppColors.ink))),
        ],
      ),
    );
  }
}

/// Fade transition used when moving between the splash, onboarding and main screens.
Route<T> fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondary) => page,
    transitionsBuilder:
        (BuildContext context, Animation<double> animation, Animation<double> secondary, Widget child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

void showSnack(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(message)));
}

/// Yes/no confirmation dialog. Returns true only when the user confirms.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(title, style: AppText.h3),
      content: Text(message, style: AppText.body),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: destructive ? TextButton.styleFrom(foregroundColor: AppColors.danger) : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
