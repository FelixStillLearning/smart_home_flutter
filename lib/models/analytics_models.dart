class SensorStats {
  final TemperatureStats? temperature;
  final HumidityStats? humidity;
  final LightStats? light;
  final GasStats? gas;

  SensorStats({
    this.temperature,
    this.humidity,
    this.light,
    this.gas,
  });

  factory SensorStats.fromJson(Map<String, dynamic> json) {
    return SensorStats(
      temperature: json['temperature'] != null
          ? TemperatureStats.fromJson(json['temperature'])
          : null,
      humidity: json['humidity'] != null
          ? HumidityStats.fromJson(json['humidity'])
          : null,
      light: json['light'] != null ? LightStats.fromJson(json['light']) : null,
      gas: json['gas'] != null ? GasStats.fromJson(json['gas']) : null,
    );
  }
}

class TemperatureStats {
  final double avg;
  final double min;
  final double max;
  final int count;

  TemperatureStats({
    required this.avg,
    required this.min,
    required this.max,
    required this.count,
  });

  factory TemperatureStats.fromJson(Map<String, dynamic> json) {
    return TemperatureStats(
      avg: (json['avg'] ?? 0.0).toDouble(),
      min: (json['min'] ?? 0.0).toDouble(),
      max: (json['max'] ?? 0.0).toDouble(),
      count: json['count'] ?? 0,
    );
  }
}

class HumidityStats {
  final double avg;
  final double min;
  final double max;
  final int count;

  HumidityStats({
    required this.avg,
    required this.min,
    required this.max,
    required this.count,
  });

  factory HumidityStats.fromJson(Map<String, dynamic> json) {
    return HumidityStats(
      avg: (json['avg'] ?? 0.0).toDouble(),
      min: (json['min'] ?? 0.0).toDouble(),
      max: (json['max'] ?? 0.0).toDouble(),
      count: json['count'] ?? 0,
    );
  }
}

class LightStats {
  final double avg;
  final double min;
  final double max;
  final int count;

  LightStats({
    required this.avg,
    required this.min,
    required this.max,
    required this.count,
  });

  factory LightStats.fromJson(Map<String, dynamic> json) {
    return LightStats(
      avg: (json['avg'] ?? 0.0).toDouble(),
      min: (json['min'] ?? 0.0).toDouble(),
      max: (json['max'] ?? 0.0).toDouble(),
      count: json['count'] ?? 0,
    );
  }
}

class GasStats {
  final double avg;
  final double min;
  final double max;
  final int count;

  GasStats({
    required this.avg,
    required this.min,
    required this.max,
    required this.count,
  });

  factory GasStats.fromJson(Map<String, dynamic> json) {
    return GasStats(
      avg: (json['avg'] ?? 0.0).toDouble(),
      min: (json['min'] ?? 0.0).toDouble(),
      max: (json['max'] ?? 0.0).toDouble(),
      count: json['count'] ?? 0,
    );
  }
}

class HourlyData {
  final String hour;
  final double? temperature;
  final double? humidity;
  final double? light;
  final double? gas;

  HourlyData({
    required this.hour,
    this.temperature,
    this.humidity,
    this.light,
    this.gas,
  });

  factory HourlyData.fromJson(Map<String, dynamic> json) {
    return HourlyData(
      hour: json['hour'] ?? '',
      temperature: json['temperature']?.toDouble(),
      humidity: json['humidity']?.toDouble(),
      light: json['light']?.toDouble(),
      gas: json['gas']?.toDouble(),
    );
  }
}

class CombinedSensorData {
  final int id;
  final double? temperature;
  final double? humidity;
  final double? light;
  final double? gas;
  final String timestamp;

  CombinedSensorData({
    required this.id,
    this.temperature,
    this.humidity,
    this.light,
    this.gas,
    required this.timestamp,
  });

  factory CombinedSensorData.fromJson(Map<String, dynamic> json) {
    return CombinedSensorData(
      id: json['id'] ?? 0,
      temperature: json['temperature']?.toDouble(),
      humidity: json['humidity']?.toDouble(),
      light: json['light']?.toDouble(),
      gas: json['gas']?.toDouble(),
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class SensorDataResponse {
  final List<CombinedSensorData> data;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  SensorDataResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory SensorDataResponse.fromJson(Map<String, dynamic> json) {
    return SensorDataResponse(
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => CombinedSensorData.fromJson(e))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 50,
      totalPages: json['total_pages'] ?? 0,
    );
  }
}
