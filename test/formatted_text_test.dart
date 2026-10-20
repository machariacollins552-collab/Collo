import 'package:collins_fit_ai/widgets/formatted_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('spansFor turns **bold** into bold spans and strips stray markdown', () {
    final span = FormattedText.spansFor('Eat **beans** and `ugali`*', const TextStyle(fontSize: 14));
    expect(span.toPlainText(), 'Eat beans and ugali');
    final bold = span.children!.whereType<TextSpan>().where((s) => s.style?.fontWeight == FontWeight.w700);
    expect(bold.map((s) => s.text), <String?>['beans']);
  });

  test('spansFor copes with an unclosed ** marker', () {
    final span = FormattedText.spansFor('Hello **world', const TextStyle(fontSize: 14));
    expect(span.toPlainText(), 'Hello world');
  });

  testWidgets('renders bullets, headings and paragraphs without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FormattedText('# Plan\n- eggs\n* **beans**\n\nDrink water.'),
          ),
        ),
      ),
    );
    expect(find.byType(FormattedText), findsOneWidget);
    expect(find.textContaining('Drink water.', findRichText: true), findsOneWidget);
    expect(find.text('•  '), findsNWidgets(2));
  });
}
