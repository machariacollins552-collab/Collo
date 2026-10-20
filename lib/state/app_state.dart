import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/config.dart';
import '../core/format.dart';
import '../data/insights.dart';
import '../data/local_store.dart';
import '../models/chat_message.dart';
import '../models/habit_day.dart';
import '../models/saved_plan.dart';
import '../models/user_profile.dart';
import '../models/weight_entry.dart';
import '../services/coach_service.dart';

/// Positions of the bottom navigation tabs.
class AppTab {
  const AppTab._();

  static const int home = 0;
  static const int coach = 1;
  static const int plan = 2;
  static const int track = 3;
  static const int profile = 4;
}

/// The single source of truth for the app. Screens read from it and call its methods;
/// every change is saved to the phone straight away and listeners are notified.
class AppState extends ChangeNotifier {
  AppState({required this.store, CoachService? coach, DateTime Function()? clock})
      : coach = coach ?? CoachService(),
        clock = clock ?? DateTime.now;

  final LocalStore store;
  final CoachService coach;

  /// Replaceable clock so tests can control "today".
  final DateTime Function() clock;

  bool loaded = false;
  UserProfile profile = const UserProfile();
  List<WeightEntry> weights = <WeightEntry>[];
  Map<String, HabitDay> habits = <String, HabitDay>{};
  List<ChatMessage> chat = <ChatMessage>[];
  List<SavedPlan> plans = <SavedPlan>[];

  int selectedTab = AppTab.home;

  /// Which part of the Plan tab is showing: 0 = meals, 1 = workouts.
  int planSegment = 0;

  /// Which part of the Track tab is showing: 0 = weight, 1 = habits.
  int trackSegment = 0;
  String? pendingPrompt;
  bool sending = false;
  CoachException? lastError;

  final List<DateTime> _sendTimes = <DateTime>[];
  int _chatGeneration = 0;

  // ---------------------------------------------------------------- loading

  Future<void> load() async {
    if (loaded) return;
    profile = store.loadProfile() ?? const UserProfile();
    weights = store.loadWeights();
    habits = store.loadHabits();
    chat = store.loadChat();
    plans = store.loadPlans();
    loaded = true;
    notifyListeners();
  }

  // -------------------------------------------------------------- navigation

  void goToTab(int index) {
    if (selectedTab == index) return;
    selectedTab = index;
    notifyListeners();
  }

  /// Opens the Plan tab on meals (0) or workouts (1).
  void openPlan(int segment) {
    planSegment = segment;
    selectedTab = AppTab.plan;
    notifyListeners();
  }

  /// Opens the Track tab on weight (0) or habits (1).
  void openTrack(int segment) {
    trackSegment = segment;
    selectedTab = AppTab.track;
    notifyListeners();
  }

  void setPlanSegment(int segment) {
    if (planSegment == segment) return;
    planSegment = segment;
    notifyListeners();
  }

  void setTrackSegment(int segment) {
    if (trackSegment == segment) return;
    trackSegment = segment;
    notifyListeners();
  }

  /// Opens the coach tab and queues [prompt] to be sent.
  void askCoach(String prompt) {
    pendingPrompt = prompt;
    selectedTab = AppTab.coach;
    notifyListeners();
  }

  String? takePendingPrompt() {
    final p = pendingPrompt;
    pendingPrompt = null;
    return p;
  }

  // ----------------------------------------------------------------- profile

  Future<void> completeOnboarding(UserProfile p) async {
    profile = p.copyWith(onboarded: true);
    final today = dateKey(clock());
    if (weights.isEmpty) {
      weights = <WeightEntry>[WeightEntry(dateKey: today, kg: p.startWeightKg)];
      await store.saveWeights(weights);
    }
    await store.saveProfile(profile);
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile p) async {
    profile = p;
    await store.saveProfile(profile);
    notifyListeners();
  }

  /// The AI server address in use: the user's own setting, else the build-time default.
  String get backendUrl =>
      profile.backendUrl.trim().isNotEmpty ? profile.backendUrl.trim() : AppConfig.defaultBackendUrl;

  // ------------------------------------------------------------------ weight

  double get currentWeight => weights.isNotEmpty ? weights.last.kg : profile.startWeightKg;

  double get changeSinceStart => currentWeight - profile.startWeightKg;

  /// 0.0 - 1.0 progress from the starting weight toward the target weight.
  double get goalProgress {
    final start = profile.startWeightKg;
    final target = profile.targetWeightKg;
    final span = start - target;
    if (span.abs() < 0.1) return 0;
    return clamp01((start - currentWeight) / span);
  }

  double? get weeklyRate => weeklyRateKg(weights);

  /// Saves a reading for [date] (today by default), replacing any reading for that day.
  /// Returns false when the number is outside a sensible range.
  Future<bool> logWeight(double kg, {DateTime? date}) async {
    if (kg.isNaN || kg < AppConfig.minWeightKg || kg > AppConfig.maxWeightKg) return false;
    final key = dateKey(date ?? clock());
    final updated = weights.where((w) => w.dateKey != key).toList()
      ..add(WeightEntry(dateKey: key, kg: round1(kg)));
    updated.sort((a, b) => a.dateKey.compareTo(b.dateKey));
    weights = updated;
    await store.saveWeights(weights);
    notifyListeners();
    return true;
  }

  Future<void> deleteWeight(String key) async {
    weights = weights.where((w) => w.dateKey != key).toList();
    await store.saveWeights(weights);
    notifyListeners();
  }

  // ------------------------------------------------------------------ habits

  String get todayKey => dateKey(clock());

  HabitDay habitOn(String key) => habits[key] ?? const HabitDay();

  HabitDay get today => habitOn(todayKey);

  Future<void> _updateToday(HabitDay Function(HabitDay current) change) async {
    final updated = Map<String, HabitDay>.of(habits);
    updated[todayKey] = change(today);
    // Keep roughly the last 120 days so storage stays small.
    if (updated.length > 120) {
      final keys = updated.keys.toList()..sort();
      for (final k in keys.take(updated.length - 120)) {
        updated.remove(k);
      }
    }
    habits = updated;
    await store.saveHabits(habits);
    notifyListeners();
  }

  Future<void> adjustWater(int delta) =>
      _updateToday((h) => h.copyWith(water: clampInt(h.water + delta, 0, 20)));

  Future<void> adjustMovement(int deltaMinutes) =>
      _updateToday((h) => h.copyWith(movementMinutes: clampInt(h.movementMinutes + deltaMinutes, 0, 600)));

  Future<void> adjustSleep(double deltaHours) =>
      _updateToday((h) => h.copyWith(sleepHours: clampDouble(h.sleepHours + deltaHours, 0, 16)));

  Future<void> adjustMeals(int delta) =>
      _updateToday((h) => h.copyWith(mealsOnTrack: clampInt(h.mealsOnTrack + delta, 0, 6)));

  /// Called when a guided workout is finished.
  Future<void> recordWorkout(int minutes) => _updateToday(
        (h) => h.copyWith(
          workouts: h.workouts + 1,
          movementMinutes: clampInt(h.movementMinutes + minutes, 0, 600),
        ),
      );

  /// Completion (0.0 - 1.0) of the four daily habits for each of the last [days] days, oldest first.
  List<HabitDay> lastDays(int days) {
    final now = dateOnly(clock());
    return <HabitDay>[
      for (var i = days - 1; i >= 0; i--) habitOn(dateKey(now.subtract(Duration(days: i)))),
    ];
  }

  /// Days in the last 7 (including today) with at least one finished workout.
  int get workoutDaysThisWeek => lastDays(7).where((d) => d.workouts > 0).length;

  // -------------------------------------------------------------------- chat

  Map<String, dynamic>? _coachContext() {
    if (!profile.shareContextWithCoach) return null;
    final rate = weeklyRate;
    return <String, dynamic>{
      'goal': profile.goal.promptText,
      'startKg': round1(profile.startWeightKg),
      'currentKg': round1(currentWeight),
      'targetKg': round1(profile.targetWeightKg),
      'dailyBudgetKsh': profile.dailyBudgetKsh,
      'diet': profile.diet.promptText,
      'equipment': profile.equipment.promptText,
      'workoutDaysPerWeek': profile.workoutDaysPerWeek,
      if (rate != null) 'recentWeeklyChangeKg': round1(rate),
    };
  }

  /// True when the last message is the user's and no answer has arrived (so Retry makes sense).
  bool get canRetry => !sending && chat.isNotEmpty && chat.last.isUser;

  Future<void> sendChat(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || sending) return;

    if (text.length > AppConfig.maxMessageChars) {
      lastError = const CoachException(
        code: 'too_long',
        message: 'That message is a bit long. Please keep it under ${AppConfig.maxMessageChars} characters.',
      );
      notifyListeners();
      return;
    }

    final now = clock();
    _sendTimes.removeWhere((t) => now.difference(t) > const Duration(minutes: 1));
    if (_sendTimes.length >= AppConfig.maxSendsPerMinute) {
      lastError = const CoachException(
        code: 'slow_down',
        message: "You're sending messages quickly. Give it a moment, then try again.",
      );
      notifyListeners();
      return;
    }
    _sendTimes.add(now);

    chat = <ChatMessage>[...chat, ChatMessage.user(text, now)];
    await _requestReply();
  }

  /// Sends the conversation again after a failure, without duplicating the user's message.
  Future<void> retryLast() async {
    if (!canRetry) return;
    await _requestReply();
  }

  Future<void> _requestReply() async {
    final generation = _chatGeneration;
    sending = true;
    lastError = null;
    notifyListeners();

    final history = chat.length > AppConfig.historyForRequest
        ? chat.sublist(chat.length - AppConfig.historyForRequest)
        : List<ChatMessage>.of(chat);

    ChatMessage? answer;
    CoachException? failure;
    try {
      final reply = await coach.chat(baseUrl: backendUrl, history: history, context: _coachContext());
      answer = ChatMessage.assistant(reply, clock());
    } on CoachException catch (e) {
      failure = e;
    } catch (_) {
      failure = const CoachException(
        code: 'unknown',
        message: 'Something unexpected went wrong. Please try again.',
      );
    }

    // The chat was cleared or the app was reset while we waited: drop the late answer.
    if (generation != _chatGeneration) return;

    if (answer != null) chat = <ChatMessage>[...chat, answer];
    lastError = failure;
    sending = false;
    await _persistChat();
    notifyListeners();
  }

  Future<void> _persistChat() async {
    if (chat.length > AppConfig.maxStoredMessages) {
      chat = chat.sublist(chat.length - AppConfig.maxStoredMessages);
    }
    await store.saveChat(chat);
  }

  void dismissError() {
    if (lastError == null) return;
    lastError = null;
    notifyListeners();
  }

  Future<void> clearChat() async {
    _chatGeneration++;
    chat = <ChatMessage>[];
    lastError = null;
    sending = false;
    await store.clearChat();
    notifyListeners();
  }

  // ------------------------------------------------------------- saved plans

  bool isSaved(ChatMessage message) => plans.any((p) => p.body == message.text);

  Future<void> savePlan(ChatMessage message) async {
    if (isSaved(message)) return;
    final plan = SavedPlan(
      id: 'p${clock().microsecondsSinceEpoch}',
      title: planTitle(message.text),
      body: message.text,
      savedAt: clock(),
    );
    final updated = <SavedPlan>[plan, ...plans];
    plans = updated.length > AppConfig.maxSavedPlans ? updated.sublist(0, AppConfig.maxSavedPlans) : updated;
    await store.savePlans(plans);
    notifyListeners();
  }

  Future<void> deletePlan(String id) async {
    plans = plans.where((p) => p.id != id).toList();
    await store.savePlans(plans);
    notifyListeners();
  }

  /// First readable line of a reply, with markdown symbols removed, as a short title.
  static String planTitle(String text) {
    for (final line in text.split('\n')) {
      final cleaned = line.replaceAll(RegExp(r'[*#`>_-]'), '').trim();
      if (cleaned.isNotEmpty) {
        return cleaned.length > 48 ? '${cleaned.substring(0, 45)}...' : cleaned;
      }
    }
    return 'Saved plan';
  }

  // ------------------------------------------------------------------- reset

  /// Deletes everything stored on this device and returns the app to its first-run state.
  Future<void> resetAll() async {
    _chatGeneration++;
    await store.clearAll();
    profile = const UserProfile();
    weights = <WeightEntry>[];
    habits = <String, HabitDay>{};
    chat = <ChatMessage>[];
    plans = <SavedPlan>[];
    selectedTab = AppTab.home;
    planSegment = 0;
    trackSegment = 0;
    pendingPrompt = null;
    sending = false;
    lastError = null;
    _sendTimes.clear();
    notifyListeners();
  }
}

/// Makes [AppState] available to every screen: `AppScope.of(context)`.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  /// Use inside `build` so the widget rebuilds when the state changes.
  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found. Wrap the app in AppScope.');
    return scope!.notifier!;
  }

  /// Use inside button handlers and callbacks where no rebuild is needed.
  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found. Wrap the app in AppScope.');
    return scope!.notifier!;
  }
}
