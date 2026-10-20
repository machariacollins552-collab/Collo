/// App-wide constants and build-time settings.
class AppConfig {
  const AppConfig._();

  static const String appName = 'Collins Fit AI';
  static const String coachName = 'FitCoach AI';
  static const String version = '1.0.0';

  /// Address of your FitCoach backend. Set at build time with
  /// `--dart-define=BACKEND_URL=https://...` (the GitHub workflow does this from the
  /// BACKEND_URL repository variable) or later inside the app: Profile -> AI connection.
  /// This is only an address. It is NOT a secret.
  static const String defaultBackendUrl =
      String.fromEnvironment('BACKEND_URL', defaultValue: '');

  /// Optional shared token. Anything inside an APK can be extracted, so this only
  /// deters casual misuse. It is NOT a replacement for the server-side API key.
  static const String appToken = String.fromEnvironment('APP_TOKEN', defaultValue: '');

  // Chat limits.
  static const int maxMessageChars = 500;
  static const int historyForRequest = 8;
  static const int maxStoredMessages = 60;
  static const int maxSendsPerMinute = 8;
  static const int maxSavedPlans = 30;

  // Network behaviour.
  static const Duration requestTimeout = Duration(seconds: 25);
  static const Duration healthTimeout = Duration(seconds: 10);
  static const int maxRetries = 2;

  // Daily habit goals.
  static const int waterGoal = 8;
  static const int movementGoalMinutes = 30;
  static const double sleepGoalHours = 7;
  static const int mealsGoal = 3;

  // Sanity ranges for typed-in weights (kg).
  static const double minWeightKg = 20;
  static const double maxWeightKg = 400;
}
