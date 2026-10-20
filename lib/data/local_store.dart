import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_message.dart';
import '../models/habit_day.dart';
import '../models/saved_plan.dart';
import '../models/user_profile.dart';
import '../models/weight_entry.dart';

/// Everything the app remembers lives here, on the phone, in SharedPreferences.
/// Nothing in this class talks to the network.
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStore> open() async => LocalStore(await SharedPreferences.getInstance());

  static const String _kProfile = 'cfa.profile.v1';
  static const String _kWeights = 'cfa.weights.v1';
  static const String _kHabits = 'cfa.habits.v1';
  static const String _kChat = 'cfa.chat.v1';
  static const String _kPlans = 'cfa.plans.v1';

  Object? _readJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null; // corrupt data is treated as empty rather than crashing the app
    }
  }

  Future<void> _write(String key, Object value) async {
    await _prefs.setString(key, jsonEncode(value));
  }

  UserProfile? loadProfile() {
    final json = _readJson(_kProfile);
    if (json is Map<String, dynamic>) return UserProfile.fromJson(json);
    return null;
  }

  Future<void> saveProfile(UserProfile profile) => _write(_kProfile, profile.toJson());

  List<WeightEntry> loadWeights() {
    final json = _readJson(_kWeights);
    if (json is! List) return <WeightEntry>[];
    final entries = <WeightEntry>[];
    for (final item in json) {
      final entry = WeightEntry.tryFromJson(item);
      if (entry != null) entries.add(entry);
    }
    entries.sort((a, b) => a.dateKey.compareTo(b.dateKey));
    return entries;
  }

  Future<void> saveWeights(List<WeightEntry> weights) =>
      _write(_kWeights, weights.map((w) => w.toJson()).toList());

  Map<String, HabitDay> loadHabits() {
    final json = _readJson(_kHabits);
    final result = <String, HabitDay>{};
    if (json is Map) {
      json.forEach((key, value) {
        if (key is String && value is Map<String, dynamic>) {
          result[key] = HabitDay.fromJson(value);
        }
      });
    }
    return result;
  }

  Future<void> saveHabits(Map<String, HabitDay> habits) =>
      _write(_kHabits, habits.map((key, value) => MapEntry<String, dynamic>(key, value.toJson())));

  List<ChatMessage> loadChat() {
    final json = _readJson(_kChat);
    if (json is! List) return <ChatMessage>[];
    final messages = <ChatMessage>[];
    for (final item in json) {
      final message = ChatMessage.tryFromJson(item);
      if (message != null) messages.add(message);
    }
    return messages;
  }

  Future<void> saveChat(List<ChatMessage> chat) =>
      _write(_kChat, chat.map((m) => m.toJson()).toList());

  List<SavedPlan> loadPlans() {
    final json = _readJson(_kPlans);
    if (json is! List) return <SavedPlan>[];
    final plans = <SavedPlan>[];
    for (final item in json) {
      final plan = SavedPlan.tryFromJson(item);
      if (plan != null) plans.add(plan);
    }
    return plans;
  }

  Future<void> savePlans(List<SavedPlan> plans) =>
      _write(_kPlans, plans.map((p) => p.toJson()).toList());

  Future<void> clearChat() async {
    await _prefs.remove(_kChat);
  }

  /// Removes everything this app stored.
  Future<void> clearAll() async {
    for (final key in <String>[_kProfile, _kWeights, _kHabits, _kChat, _kPlans]) {
      await _prefs.remove(key);
    }
  }
}
