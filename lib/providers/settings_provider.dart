import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/settings_model.dart';

class SettingsProvider with ChangeNotifier {
  AppSettings _settings = AppSettings();

  AppSettings get settings => _settings;

  static const String _settingsKey = 'app_settings';

  // Load settings from SharedPreferences
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        _settings = AppSettings.fromJson(jsonDecode(settingsJson));
        notifyListeners();
      }
    } catch (e) {
      print('[SettingsProvider] Error loading settings: $e');
    }
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, jsonEncode(_settings.toJson()));
    } catch (e) {
      print('[SettingsProvider] Error saving settings: $e');
    }
  }

  // Update theme
  Future<void> updateTheme(String theme) async {
    _settings = _settings.copyWith(theme: theme);
    notifyListeners();
    await _saveSettings();
  }

  // Update notifications
  Future<void> updateNotifications(bool enabled) async {
    _settings = _settings.copyWith(notifications: enabled);
    notifyListeners();
    await _saveSettings();
  }

  // Update auto refresh
  Future<void> updateAutoRefresh(bool enabled) async {
    _settings = _settings.copyWith(autoRefresh: enabled);
    notifyListeners();
    await _saveSettings();
  }

  // Update refresh interval
  Future<void> updateRefreshInterval(int seconds) async {
    _settings = _settings.copyWith(refreshInterval: seconds);
    notifyListeners();
    await _saveSettings();
  }

  // Update language
  Future<void> updateLanguage(String language) async {
    _settings = _settings.copyWith(language: language);
    notifyListeners();
    await _saveSettings();
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    _settings = AppSettings();
    notifyListeners();
    await _saveSettings();
  }
}
