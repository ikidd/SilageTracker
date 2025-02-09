import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A service that stores and retrieves user settings.
class SettingsService {
  static const String _themeModeKey = 'themeMode';
  static const String _showDeleteConfirmKey = 'showDeleteConfirm';
  static const String _supabaseUrlKey = 'supabaseUrl';
  static const String _supabaseKeyKey = 'supabaseKey';
  static const String _defaultSupabaseUrl = 'https://sxbetuloniiplaafjeaf.supabase.co';
  static const String _defaultSupabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN4YmV0dWxvbmlpcGxhYWZqZWFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg1MzcxNjgsImV4cCI6MjA1NDExMzE2OH0.GD3M_4BEm80dKCvjJxgm_D_dKialG0NiVO2FjS1Vka4';
  
  late final SharedPreferences _prefs;

  /// Initialize the settings service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get the Supabase URL
  Future<String> supabaseUrl() async {
    return _prefs.getString(_supabaseUrlKey) ?? _defaultSupabaseUrl;
  }

  /// Update the Supabase URL
  Future<void> updateSupabaseUrl(String url) async {
    await _prefs.setString(_supabaseUrlKey, url);
  }

  /// Get the Supabase API key
  Future<String> supabaseKey() async {
    return _prefs.getString(_supabaseKeyKey) ?? _defaultSupabaseKey;
  }

  /// Update the Supabase API key
  Future<void> updateSupabaseKey(String key) async {
    await _prefs.setString(_supabaseKeyKey, key);
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
