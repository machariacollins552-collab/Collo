import 'dart:convert';

import 'package:collins_fit_ai/core/config.dart';
import 'package:collins_fit_ai/data/local_store.dart';
import 'package:collins_fit_ai/models/user_profile.dart';
import 'package:collins_fit_ai/models/chat_message.dart';
import 'package:collins_fit_ai/services/coach_service.dart';
import 'package:collins_fit_ai/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kUrl = 'https://coach.example.workers.dev';

final DateTime kNow = DateTime(2026, 10, 20, 8, 30);

http.Response replyOf(String text) => http.Response(
      jsonEncode(<String, dynamic>{'reply': text}),
      200,
      headers: <String, String>{'content-type': 'application/json; charset=utf-8'},
    );

Future<LocalStore> freshStore([Map<String, Object> initial = const <String, Object>{}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return LocalStore(await SharedPreferences.getInstance());
}

Future<AppState> makeState({
  MockClient? client,
  LocalStore? store,
  bool connected = true,
}) async {
  final s = store ?? await freshStore();
  final coach = CoachService(
    client: client ?? MockClient((http.Request request) async => replyOf('Hello from FitCoach.')),
    retryDelay: Duration.zero,
    timeout: const Duration(seconds: 2),
  );
  final state = AppState(store: s, coach: coach, clock: () => kNow);
  await state.load();
  if (connected) {
    await state.updateProfile(state.profile.copyWith(backendUrl: kUrl));
  }
  return state;
}

void main() {
  group('onboarding and profile', () {
    test('completing onboarding saves the profile and the first weight', () async {
      final store = await freshStore();
      final state = await makeState(store: store, connected: false);
      expect(state.profile.onboarded, isFalse);

      await state.completeOnboarding(const UserProfile(name: 'Collins', startWeightKg: 82, targetWeightKg: 75));

      expect(state.profile.onboarded, isTrue);
      expect(state.weights.length, 1);
      expect(state.weights.single.kg, 82);
      expect(state.weights.single.dateKey, '2026-10-20');

      // A new AppState on the same storage sees the same data (it was saved to the phone).
      final again = AppState(store: store, clock: () => kNow);
      await again.load();
      expect(again.profile.onboarded, isTrue);
      expect(again.profile.name, 'Collins');
      expect(again.weights.length, 1);
    });
  });

  group('weight', () {
    test('rejects impossible numbers', () async {
      final state = await makeState();
      expect(await state.logWeight(5), isFalse);
      expect(await state.logWeight(900), isFalse);
      expect(await state.logWeight(double.nan), isFalse);
      expect(state.weights, isEmpty);
    });

    test('logging twice on one day replaces the reading, and history stays sorted', () async {
      final state = await makeState();
      expect(await state.logWeight(80), isTrue);
      expect(await state.logWeight(79.64), isTrue);
      expect(state.weights.length, 1);
      expect(state.weights.single.kg, 79.6);

      expect(await state.logWeight(81, date: DateTime(2026, 10, 10)), isTrue);
      expect(state.weights.map((w) => w.dateKey).toList(), <String>['2026-10-10', '2026-10-20']);
      expect(state.currentWeight, 79.6);
    });

    test('goal progress runs from start to target and stays between 0 and 1', () async {
      final state = await makeState();
      await state.updateProfile(state.profile.copyWith(startWeightKg: 80, targetWeightKg: 70));
      await state.logWeight(75);
      expect(state.goalProgress, closeTo(0.5, 0.001));
      await state.logWeight(65);
      expect(state.goalProgress, 1.0);
      await state.logWeight(85);
      expect(state.goalProgress, 0.0);
    });

    test('a reading can be deleted', () async {
      final state = await makeState();
      await state.logWeight(80);
      await state.deleteWeight('2026-10-20');
      expect(state.weights, isEmpty);
    });
  });

  group('habits', () {
    test('counters never go below zero or above their limits', () async {
      final state = await makeState();
      await state.adjustWater(-1);
      expect(state.today.water, 0);
      await state.adjustWater(3);
      expect(state.today.water, 3);
      for (var i = 0; i < 30; i++) {
        await state.adjustWater(1);
      }
      expect(state.today.water, 20);
      await state.adjustSleep(0.5);
      expect(state.today.sleepHours, 0.5);
      await state.adjustMeals(2);
      expect(state.today.mealsOnTrack, 2);
    });

    test('a finished workout adds minutes and counts as a workout day', () async {
      final state = await makeState();
      await state.recordWorkout(15);
      expect(state.today.workouts, 1);
      expect(state.today.movementMinutes, 15);
      expect(state.workoutDaysThisWeek, 1);
    });

    test('habits are saved to the phone', () async {
      final store = await freshStore();
      final state = await makeState(store: store);
      await state.adjustWater(2);
      final again = AppState(store: store, clock: () => kNow);
      await again.load();
      expect(again.today.water, 2);
    });
  });

  group('AI coach chat', () {
    test('a successful reply is added after the question and saved', () async {
      final store = await freshStore();
      final state = await makeState(store: store);
      await state.sendChat('  Plan my meals today.  ');

      expect(state.sending, isFalse);
      expect(state.lastError, isNull);
      expect(state.chat.length, 2);
      expect(state.chat.first.isUser, isTrue);
      expect(state.chat.first.text, 'Plan my meals today.');
      expect(state.chat.last.isUser, isFalse);
      expect(state.chat.last.text, 'Hello from FitCoach.');
      expect(store.loadChat().length, 2);
    });

    test('without a server address the user is told, and no reply is invented', () async {
      final state = await makeState(connected: false);
      await state.sendChat('Hello');

      expect(state.lastError?.code, 'not_configured');
      expect(state.chat.length, 1);
      expect(state.chat.single.isUser, isTrue);
      expect(state.canRetry, isTrue);
    });

    test('when the server is down the error is shown and retry does not duplicate the question', () async {
      var healthy = false;
      final state = await makeState(
        client: MockClient((http.Request request) async {
          if (!healthy) {
            return http.Response(
              jsonEncode(<String, dynamic>{
                'error': <String, dynamic>{'code': 'provider_auth', 'message': 'The AI service rejected the key.'},
              }),
              502,
              headers: <String, String>{'content-type': 'application/json'},
            );
          }
          return replyOf('Back online.');
        }),
      );

      await state.sendChat('Create a home workout.');
      expect(state.lastError?.code, 'provider_auth');
      expect(state.chat.length, 1);
      expect(state.canRetry, isTrue);

      healthy = true;
      await state.retryLast();
      expect(state.lastError, isNull);
      expect(state.chat.length, 2);
      expect(state.chat.last.text, 'Back online.');
      expect(state.canRetry, isFalse);
    });

    test('over-long messages are rejected before sending', () async {
      var calls = 0;
      final state = await makeState(
        client: MockClient((http.Request request) async {
          calls++;
          return replyOf('x');
        }),
      );
      await state.sendChat('a' * (AppConfig.maxMessageChars + 1));
      expect(state.lastError?.code, 'too_long');
      expect(state.chat, isEmpty);
      expect(calls, 0);
    });

    test('sending too fast is limited on the phone', () async {
      final state = await makeState();
      for (var i = 0; i < AppConfig.maxSendsPerMinute; i++) {
        await state.sendChat('Question $i');
        expect(state.lastError, isNull);
      }
      await state.sendChat('One more');
      expect(state.lastError?.code, 'slow_down');
      expect(state.chat.length, AppConfig.maxSendsPerMinute * 2);
    });

    test('only the last few messages are sent, with the profile when sharing is on', () async {
      Map<String, dynamic>? lastBody;
      final state = await makeState(
        client: MockClient((http.Request request) async {
          lastBody = jsonDecode(request.body) as Map<String, dynamic>;
          return replyOf('ok');
        }),
      );
      await state.updateProfile(state.profile.copyWith(startWeightKg: 80, targetWeightKg: 72, dailyBudgetKsh: 350));
      await state.logWeight(79);

      for (var i = 0; i < 6; i++) {
        await state.sendChat('Message $i');
      }
      final messages = lastBody!['messages'] as List<dynamic>;
      expect(messages.length, AppConfig.historyForRequest);
      expect((messages.last as Map<String, dynamic>)['content'], 'Message 5');

      final profile = lastBody!['profile'] as Map<String, dynamic>;
      expect(profile['currentKg'], 79);
      expect(profile['dailyBudgetKsh'], 350);
      expect(profile.containsKey('name'), isFalse);
    });

    test('with sharing off, no personal data is sent', () async {
      Map<String, dynamic>? lastBody;
      final state = await makeState(
        client: MockClient((http.Request request) async {
          lastBody = jsonDecode(request.body) as Map<String, dynamic>;
          return replyOf('ok');
        }),
      );
      await state.updateProfile(state.profile.copyWith(shareContextWithCoach: false));
      await state.sendChat('Hello');
      expect(lastBody!.containsKey('profile'), isFalse);
    });

    test('clearing the chat removes it from the phone', () async {
      final store = await freshStore();
      final state = await makeState(store: store);
      await state.sendChat('Hello');
      expect(store.loadChat(), isNotEmpty);
      await state.clearChat();
      expect(state.chat, isEmpty);
      expect(store.loadChat(), isEmpty);
    });
  });

  group('saved plans', () {
    test('save, detect duplicates, delete', () async {
      final state = await makeState();
      final message = ChatMessage.assistant('## Dinner\n- Beans and cabbage', kNow);
      expect(state.isSaved(message), isFalse);
      await state.savePlan(message);
      expect(state.isSaved(message), isTrue);
      await state.savePlan(message);
      expect(state.plans.length, 1);
      expect(state.plans.single.title, 'Dinner');
      await state.deletePlan(state.plans.single.id);
      expect(state.plans, isEmpty);
    });

    test('planTitle cleans markdown and shortens long lines', () {
      expect(AppState.planTitle('**Bold** start'), 'Bold start');
      expect(AppState.planTitle('\n\n'), 'Saved plan');
      final long = AppState.planTitle('a' * 100);
      expect(long.length, 48);
      expect(long.endsWith('...'), isTrue);
    });
  });

  group('privacy', () {
    test('erasing all data empties memory and storage and restarts onboarding', () async {
      final store = await freshStore();
      final state = await makeState(store: store);
      await state.completeOnboarding(state.profile.copyWith(name: 'Collins'));
      await state.adjustWater(2);
      await state.sendChat('Hello');
      await state.savePlan(state.chat.last);

      await state.resetAll();

      expect(state.profile.onboarded, isFalse);
      expect(state.profile.name, '');
      expect(state.weights, isEmpty);
      expect(state.habits, isEmpty);
      expect(state.chat, isEmpty);
      expect(state.plans, isEmpty);
      expect(store.loadProfile(), isNull);
      expect(store.loadWeights(), isEmpty);
      expect(store.loadHabits(), isEmpty);
      expect(store.loadChat(), isEmpty);
      expect(store.loadPlans(), isEmpty);
    });

    test('corrupt stored data is treated as empty instead of crashing', () async {
      final store = await freshStore(<String, Object>{
        'cfa.profile.v1': 'not json',
        'cfa.weights.v1': '{"oops": true}',
        'cfa.habits.v1': '[1,2,3]',
        'cfa.chat.v1': '"text"',
        'cfa.plans.v1': '[null, 5]',
      });
      final state = AppState(store: store, clock: () => kNow);
      await state.load();
      expect(state.profile.onboarded, isFalse);
      expect(state.weights, isEmpty);
      expect(state.habits, isEmpty);
      expect(state.chat, isEmpty);
      expect(state.plans, isEmpty);
    });
  });
}
