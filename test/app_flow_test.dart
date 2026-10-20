import 'package:collins_fit_ai/app.dart';
import 'package:collins_fit_ai/data/local_store.dart';
import 'package:collins_fit_ai/screens/onboarding_screen.dart';
import 'package:collins_fit_ai/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder navLabel(String text) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(text));

void main() {
  testWidgets('first launch: splash, onboarding, then the home dashboard and honest AI state', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = LocalStore(await SharedPreferences.getInstance());
    final state = AppState(store: store, clock: () => DateTime(2026, 10, 20, 8, 30));
    await state.load();

    await tester.pumpWidget(CollinsFitApp(state: state));

    // Splash shows the brand name.
    expect(find.text('Collins Fit AI'), findsOneWidget);

    // After the splash delay a first-time user lands on onboarding.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(OnboardingScreen), findsOneWidget);

    // Welcome -> goal -> weights -> routine.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(find.text('Start my journey'), findsOneWidget);

    await tester.tap(find.text('Start my journey'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    // The profile was saved and the dashboard is showing.
    expect(state.profile.onboarded, isTrue);
    expect(state.weights.length, 1);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Good morning, friend'), findsOneWidget);

    // The Coach tab says plainly that no AI server is connected (no fake answers).
    await tester.tap(navLabel('Coach'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('AI server not connected yet'), findsOneWidget);

    // The Plan tab shows a Kenyan meal plan.
    await tester.tap(navLabel('Plan'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text("Today's plan"), findsOneWidget);
  });
}
