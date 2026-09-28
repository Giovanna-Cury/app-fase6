import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';

/// Holds user-facing app settings. Currently the theme mode (light/dark/system),
/// persisted across restarts with [SharedPreferences].
class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(AppConfig.themeStorageKey);
    _themeMode = _fromString(stored);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.themeStorageKey, _themeMode.name);
  }

  ThemeMode _fromString(String? value) => switch (value) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      };
}
