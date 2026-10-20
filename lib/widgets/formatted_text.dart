import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Renders the light formatting the AI coach uses: `- ` bullets and `**bold**`.
/// Anything else is shown as plain text, so unexpected markup never breaks the screen.
class FormattedText extends StatelessWidget {
  const FormattedText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  static final RegExp _bullet = RegExp(r'^\s*[-*•]\s+(.*)$');
  static final RegExp _heading = RegExp(r'^\s*#{1,6}\s+(.*)$');

  @override
  Widget build(BuildContext context) {
    final base = style ?? AppText.body;
    final lines = text.replaceAll('\r\n', '\n').split('\n');
    final children = <Widget>[];

    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        children.add(const SizedBox(height: 8));
        continue;
      }
      final bullet = _bullet.firstMatch(line);
      final heading = _heading.firstMatch(line);
      if (bullet != null) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('•  ', style: base),
                Expanded(child: Text.rich(spansFor(bullet.group(1) ?? '', base))),
              ],
            ),
          ),
        );
      } else if (heading != null) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text.rich(
              spansFor(heading.group(1) ?? '', base.copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
        );
      } else {
        children.add(Text.rich(spansFor(line, base)));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  /// Turns `**bold**` into bold spans and strips leftover markdown symbols.
  @visibleForTesting
  static TextSpan spansFor(String input, TextStyle base) {
    final parts = input.split('**');
    final spans = <InlineSpan>[];
    for (var i = 0; i < parts.length; i++) {
      final cleaned = parts[i].replaceAll('*', '').replaceAll('`', '');
      if (cleaned.isEmpty) continue;
      spans.add(
        TextSpan(
          text: cleaned,
          style: i.isOdd ? const TextStyle(fontWeight: FontWeight.w700) : null,
        ),
      );
    }
    return TextSpan(style: base, children: spans);
  }
}
