import 'package:flutter/foundation.dart';

/// Central configuration for the application.
///
/// This is the single place to control how the app talks to the back-end
/// (the Spring Boot REST API built in Part 2 of the project).
class AppConfig {
  const AppConfig._();

  /// When `true`, the app runs entirely on local mock data and does NOT need
  /// the Spring Boot back-end to be running. This lets the project be opened
  /// and demonstrated in VS Code out-of-the-box.
  ///
  /// Set to `false` once the Spring Boot API is up to consume real data —
  /// without editing code: `flutter run --dart-define=SMARTHAS_USE_MOCK=false`.
  static const bool useMockData =
      bool.fromEnvironment('SMARTHAS_USE_MOCK', defaultValue: true);

  /// When `true`, if a real API call fails because the back-end is
  /// unreachable, the repositories transparently fall back to mock data
  /// instead of throwing. Keeps the demo resilient during a live presentation.
  static const bool fallbackToMockOnError = true;

  /// Base URL used by the Android emulator. `10.0.2.2` is the special alias
  /// the emulator uses to reach `localhost` on the host machine.
  static const String _androidBaseUrl = 'http://10.0.2.2:8080/api';

  /// Base URL used by web, desktop and iOS simulator (they share the host's
  /// `localhost`).
  static const String _defaultBaseUrl = 'http://localhost:8080/api';

  /// Resolves the correct base URL for the current platform.
  static String get apiBaseUrl {
    if (kIsWeb) return _defaultBaseUrl;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidBaseUrl;
    }
    return _defaultBaseUrl;
  }

  /// Maximum time to wait for a single HTTP request before giving up.
  static const Duration requestTimeout = Duration(seconds: 15);

  /// Simulated latency for mock calls, so loading states are visible in the UI.
  static const Duration mockLatency = Duration(milliseconds: 700);

  /// Key used to persist the auth token in [SharedPreferences].
  static const String tokenStorageKey = 'smarthas.auth.token';

  /// Key used to persist the selected theme mode.
  static const String themeStorageKey = 'smarthas.settings.themeMode';
}
