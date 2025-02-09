import 'package:flutter/material.dart';

import 'settings_service.dart';

/// A class that many Widgets can interact with to read user settings, update
/// user settings, or listen to user settings changes.
///
/// Controllers glue Data Services to Flutter Widgets. The SettingsController
/// uses the SettingsService to store and retrieve user settings.
class SettingsController with ChangeNotifier {
  SettingsController(this._settingsService);

  // Make SettingsService a private variable so it is not used directly.
  final SettingsService _settingsService;

  late ThemeMode _themeMode;
  late bool _showDeleteConfirmation;
  late String _supabaseUrl;
  late String _supabaseKey;

  ThemeMode get themeMode => _themeMode;
  bool get showDeleteConfirmation => _showDeleteConfirmation;
  String get supabaseUrl => _supabaseUrl;
  String get supabaseKey => _supabaseKey;
  String get version => '0.0.5';

  // Function to validate Supabase URL
  bool isValidSupabaseUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isScheme('https') && uri.host.contains('supabase');
    } catch (_) {
      return false;
    }
  }

  // Function to validate Supabase key
  bool isValidSupabaseKey(String key) {
    // Basic JWT format validation
    final parts = key.split('.');
    return parts.length == 3 && key.length > 50;
  }

  /// Load the user's settings from the SettingsService. It may load from a
  /// local database or the internet. The controller only knows it can load the
  /// settings from the service.
  Future<void> loadSettings() async {
    await _settingsService.init();
    _themeMode = await _settingsService.themeMode();
    _showDeleteConfirmation = await _settingsService.showDeleteConfirmation();
    _supabaseUrl = await _settingsService.supabaseUrl();
    _supabaseKey = await _settingsService.supabaseKey();

    // Important! Inform listeners a change has occurred.
    notifyListeners();
  }

  /// Update and persist the Supabase URL
  Future<void> updateSupabaseUrl(String url) async {
    if (!isValidSupabaseUrl(url)) {
      throw FormatException('Invalid Supabase URL format');
    }

    if (url == _supabaseUrl) return;

    _supabaseUrl = url;
    notifyListeners();
    await _settingsService.updateSupabaseUrl(url);
  }

  /// Update and persist the Supabase key
  Future<void> updateSupabaseKey(String key) async {
    if (!isValidSupabaseKey(key)) {
      throw FormatException('Invalid Supabase key format');
    }

    if (key == _supabaseKey) return;

    _supabaseKey = key;
    notifyListeners();
    await _settingsService.updateSupabaseKey(key);
  }

  /// Update and persist the ThemeMode based on the user's selection.
  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) return;

    // Do not perform any work if new and old ThemeMode are identical
    if (newThemeMode == _themeMode) return;

    // Otherwise, store the new ThemeMode in memory
    _themeMode = newThemeMode;

    // Important! Inform listeners a change has occurred.
    notifyListeners();

    // Persist the changes to a local database or the internet using the
    // SettingService.
    await _settingsService.updateThemeMode(newThemeMode);
  }

  /// Update and persist the delete confirmation setting
  Future<void> updateShowDeleteConfirmation(bool show) async {
    // Do not perform any work if new and old values are identical
    if (show == _showDeleteConfirmation) return;

    // Otherwise, store the new value in memory
    _showDeleteConfirmation = show;

    // Important! Inform listeners a change has occurred.
    notifyListeners();

    // Persist the changes using the SettingService.
    await _settingsService.updateShowDeleteConfirmation(show);
  }
}
