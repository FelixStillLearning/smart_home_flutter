import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/automation_model.dart';

class AutomationProvider with ChangeNotifier {
  List<AutomationRule> _rules = [];
  bool _isLoading = false;

  List<AutomationRule> get rules => _rules;
  bool get isLoading => _isLoading;

  static const String _rulesKey = 'automation_rules';

  // Load automation rules from SharedPreferences
  Future<void> loadRules() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final rulesJson = prefs.getString(_rulesKey);

      if (rulesJson != null) {
        final List<dynamic> decoded = jsonDecode(rulesJson);
        _rules = decoded.map((e) => AutomationRule.fromJson(e)).toList();
      }
    } catch (e) {
      print('[AutomationProvider] Error loading rules: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Save rules to SharedPreferences
  Future<void> _saveRules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rulesJson = jsonEncode(_rules.map((e) => e.toJson()).toList());
      await prefs.setString(_rulesKey, rulesJson);
    } catch (e) {
      print('[AutomationProvider] Error saving rules: $e');
    }
  }

  // Add a new automation rule
  Future<void> addRule(AutomationRule rule) async {
    // Generate ID
    final newId = _rules.isEmpty
        ? 1
        : _rules.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;

    final ruleWithId = AutomationRule(
      id: newId,
      deviceType: rule.deviceType,
      enabled: rule.enabled,
      condition: rule.condition,
      settings: rule.settings,
    );

    _rules.add(ruleWithId);
    notifyListeners();
    await _saveRules();
  }

  // Update an existing automation rule
  Future<void> updateRule(int id, AutomationRule updatedRule) async {
    final index = _rules.indexWhere((r) => r.id == id);
    if (index != -1) {
      _rules[index] = updatedRule;
      notifyListeners();
      await _saveRules();
    }
  }

  // Delete an automation rule
  Future<void> deleteRule(int id) async {
    _rules.removeWhere((r) => r.id == id);
    notifyListeners();
    await _saveRules();
  }

  // Toggle rule enabled status
  Future<void> toggleRule(int id) async {
    final index = _rules.indexWhere((r) => r.id == id);
    if (index != -1) {
      final rule = _rules[index];
      _rules[index] = AutomationRule(
        id: rule.id,
        deviceType: rule.deviceType,
        enabled: !rule.enabled,
        condition: rule.condition,
        settings: rule.settings,
      );
      notifyListeners();
      await _saveRules();
    }
  }

  // Get active rules for a specific device type
  List<AutomationRule> getActiveRulesForDevice(String deviceType) {
    return _rules
        .where((r) => r.enabled && r.deviceType == deviceType)
        .toList();
  }

  // Check if automation should trigger based on current conditions
  bool shouldTriggerAutomation(
    String deviceType,
    double? lightLevel,
    String? currentTime,
  ) {
    final activeRules = getActiveRulesForDevice(deviceType);

    for (var rule in activeRules) {
      if (rule.condition == 'light_threshold' && lightLevel != null) {
        final settings = LightBasedSettings.fromMap(rule.settings);
        if (lightLevel < settings.threshold && settings.action == 'turn_on') {
          return true;
        }
        if (lightLevel >= settings.threshold && settings.action == 'turn_off') {
          return true;
        }
      } else if (rule.condition == 'time_based' && currentTime != null) {
        final settings = TimeBasedSettings.fromMap(rule.settings);
        // Simple time comparison (HH:mm format)
        if (currentTime.compareTo(settings.startTime) >= 0 &&
            currentTime.compareTo(settings.endTime) <= 0) {
          return true;
        }
      }
    }

    return false;
  }
}
