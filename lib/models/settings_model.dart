class AppSettings {
  final String theme; // 'light', 'dark', 'system'
  final bool notifications;
  final bool autoRefresh;
  final int refreshInterval; // in seconds
  final String language; // 'en', 'id'

  AppSettings({
    this.theme = 'system',
    this.notifications = true,
    this.autoRefresh = true,
    this.refreshInterval = 5,
    this.language = 'id',
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      theme: json['theme'] ?? 'system',
      notifications: json['notifications'] ?? true,
      autoRefresh: json['auto_refresh'] ?? true,
      refreshInterval: json['refresh_interval'] ?? 5,
      language: json['language'] ?? 'id',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'notifications': notifications,
      'auto_refresh': autoRefresh,
      'refresh_interval': refreshInterval,
      'language': language,
    };
  }

  AppSettings copyWith({
    String? theme,
    bool? notifications,
    bool? autoRefresh,
    int? refreshInterval,
    String? language,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      notifications: notifications ?? this.notifications,
      autoRefresh: autoRefresh ?? this.autoRefresh,
      refreshInterval: refreshInterval ?? this.refreshInterval,
      language: language ?? this.language,
    );
  }
}
