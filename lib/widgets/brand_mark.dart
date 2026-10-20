import 'package:flutter/material.dart';

import '../core/theme.dart';

/// The Collins Fit AI monogram: a double gold ring around "CF".
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 96, this.onDark = true});

  final double size;

  /// True on the forest-green background, false on ivory.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final line = onDark ? AppColors.gold : AppColors.forest;
    final textColor = onDark ? AppColors.ivory : AppColors.forest;
    return Semantics(
      label: 'Collins Fit AI logo',
      image: true,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: line, width: 1.6),
        ),
        child: Center(
          child: Container(
            width: size - 12,
            height: size - 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: line.withValues(alpha: 0.45)),
            ),
            child: Center(
              child: Text(
                'CF',
                style: TextStyle(
                  fontFamily: AppText.serif,
                  fontFamilyFallback: AppText.serifFallback,
                  fontSize: size * 0.34,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
