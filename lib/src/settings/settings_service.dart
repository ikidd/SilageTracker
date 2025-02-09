import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A service that stores and retrieves user settings.
class SettingsService {
  static const String _themeModeKey = 'themeMode';
  static const String _showDeleteConfirmKey = 'showDeleteConfirm';
  late final SharedPreferences _prefs;

  /// Initialize the settings service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Loads the User's preferred ThemeMode from local storage.
  Future<ThemeMode> themeMode() async {
    final String? themeModeString = _prefs.getString(_themeModeKey);
    switch (themeModeString) {
      case 'ThemeMode.light':
        return ThemeMode.light;
      case 'ThemeMode.dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Persists the user's preferred ThemeMode to local storage.
  Future<void> updateThemeMode(ThemeMode theme) async {
    await _prefs.setString(_themeModeKey, theme.toString());
  }

  /// Loads whether to show delete confirmation dialogs
  Future<bool> showDeleteConfirmation() async {
    return _prefs.getBool(_showDeleteConfirmKey) ?? true;
  }

  /// Updates whether to show delete confirmation dialogs
  Future<void> updateShowDeleteConfirmation(bool show) async {
    await _prefs.setBool(_showDeleteConfirmKey, show);
  }
}
