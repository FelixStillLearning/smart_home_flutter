class AutomationRule {
  final int? id;
  final String deviceType; // 'lamp' or 'curtain'
  final bool enabled;
  final String condition; // 'light_threshold', 'time_based', etc.
  final Map<String, dynamic> settings;

  AutomationRule({
    this.id,
    required this.deviceType,
    required this.enabled,
    required this.condition,
    required this.settings,
  });

  factory AutomationRule.fromJson(Map<String, dynamic> json) {
    return AutomationRule(
      id: json['id'],
      deviceType: json['device_type'] ?? '',
      enabled: json['enabled'] ?? false,
      condition: json['condition'] ?? '',
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'device_type': deviceType,
      'enabled': enabled,
      'condition': condition,
      'settings': settings,
    };
  }
}

// Settings untuk Light-based automation
class LightBasedSettings {
  final double threshold;
  final String action; // 'turn_on' or 'turn_off'

  LightBasedSettings({
    required this.threshold,
    required this.action,
  });

  factory LightBasedSettings.fromMap(Map<String, dynamic> map) {
    return LightBasedSettings(
      threshold: (map['threshold'] ?? 0).toDouble(),
      action: map['action'] ?? 'turn_on',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'threshold': threshold,
      'action': action,
    };
  }
}

// Settings untuk Time-based automation
class TimeBasedSettings {
  final String startTime;
  final String endTime;
  final String action;

  TimeBasedSettings({
    required this.startTime,
    required this.endTime,
    required this.action,
  });

  factory TimeBasedSettings.fromMap(Map<String, dynamic> map) {
    return TimeBasedSettings(
      startTime: map['start_time'] ?? '00:00',
      endTime: map['end_time'] ?? '00:00',
      action: map['action'] ?? 'turn_on',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'start_time': startTime,
      'end_time': endTime,
      'action': action,
    };
  }
}
