import 'package:flutter/material.dart';

/// The Collins Fit AI palette: old-money forest and ivory with antique gold accents.
class AppColors {
  const AppColors._();

  static const Color forest = Color(0xFF183D30);
  static const Color forestSoft = Color(0xFF2B5646);
  static const Color ivory = Color(0xFFF7F4EC);
  static const Color card = Color(0xFFFFFDF8);
  static const Color sage = Color(0xFFA8B5A0);
  static const Color sageLight = Color(0xFFE4E9DF);
  static const Color gold = Color(0xFFC6A76A);

  /// A darker gold that stays readable as text on ivory.
  static const Color goldText = Color(0xFF7D6228);
  static const Color ink = Color(0xFF20251F);
  static const Color muted = Color(0xFF59625A);
  static const Color border = Color(0xFFE2DCCB);
  static const Color danger = Color(0xFF9B2C2C);
  static const Color dangerSoft = Color(0xFFF6E6E3);
}

/// Text styles. Headings use the system serif; body text uses the system sans-serif,
/// so no font files are bundled and the app stays small.
class AppText {
  const AppText._();

  static const String serif = 'serif';
  static const List<String> serifFallback = <String>['Noto Serif', 'Georgia', 'Times New Roman'];

  static const TextStyle display = TextStyle(
    fontFamily: serif,
    fontFamilyFallback: serifFallback,
    fontSize: 44,
    height: 1.05,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    letterSpacing: -0.5,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: serif,
    fontFamilyFallback: serifFallback,
    fontSize: 30,
    height: 1.15,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    letterSpacing: -0.3,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: serif,
    fontFamilyFallback: serifFallback,
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: serif,
    fontFamilyFallback: serifFallback,
    fontSize: 18,
    height: 1.25,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  static const TextStyle body = TextStyle(fontSize: 15, height: 1.45, color: AppColors.ink);

  static const TextStyle bodyMuted = TextStyle(fontSize: 14, height: 1.45, color: AppColors.muted);

  static const TextStyle small = TextStyle(fontSize: 13, height: 1.4, color: AppColors.muted);

  static const TextStyle label = TextStyle(
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.3,
    color: AppColors.muted,
  );

  static const TextStyle button = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.light(
    primary: AppColors.forest,
    onPrimary: AppColors.ivory,
    primaryContainer: AppColors.sageLight,
    onPrimaryContainer: AppColors.forest,
    secondary: AppColors.gold,
    onSecondary: AppColors.ink,
    secondaryContainer: AppColors.sageLight,
    onSecondaryContainer: AppColors.forest,
    surface: AppColors.ivory,
    onSurface: AppColors.ink,
    error: AppColors.danger,
    onError: Colors.white,
    outline: AppColors.border,
    outlineVariant: AppColors.border,
  );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme);

  final roundedShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.ivory,
    textTheme: base.textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.sageLight,
      elevation: 0,
      height: 70,
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((Set<WidgetState> states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.forest : AppColors.muted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((Set<WidgetState> states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? AppColors.forest : AppColors.muted, size: 24);
      }),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.forest,
      inactiveTrackColor: AppColors.sageLight,
      thumbColor: AppColors.forest,
      overlayColor: Color(0x1F183D30),
      valueIndicatorColor: AppColors.forest,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.forest,
      linearTrackColor: AppColors.sageLight,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.forest,
      contentTextStyle: const TextStyle(color: AppColors.ivory, fontSize: 14),
      shape: roundedShape,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.ivory,
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        shape: roundedShape,
        textStyle: AppText.button,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.forest,
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        side: const BorderSide(color: AppColors.forest, width: 1),
        shape: roundedShape,
        textStyle: AppText.button,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.forest,
        minimumSize: const Size(48, 44),
        textStyle: AppText.button,
      ),
    ),
  );
}

/// Shared decoration for text fields so every input looks the same.
InputDecoration fieldDecoration(
  String label, {
  String? hint,
  String? errorText,
  String? suffixText,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    errorText: errorText,
    suffixText: suffixText,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.card,
    labelStyle: const TextStyle(color: AppColors.muted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: border(AppColors.border),
    focusedBorder: border(AppColors.forest, 1.6),
    errorBorder: border(AppColors.danger),
    focusedErrorBorder: border(AppColors.danger, 1.6),
  );
}
