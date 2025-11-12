// Model untuk data sensor suhu
class TemperatureData {
  final String device;
  final String sensor;
  final double temperature;
  final DateTime timestamp;

  TemperatureData({
    required this.device,
    required this.sensor,
    required this.temperature,
    required this.timestamp,
  });

  factory TemperatureData.fromJson(Map<String, dynamic> json) {
    return TemperatureData(
      device: json['device'] ?? 'Unknown',
      sensor: json['sensor'] ?? 'DHT22',
      temperature: (json['temperature'] ?? 0).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        ((json['timestamp'] ?? 0) * 1000).toInt(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device': device,
      'sensor': sensor,
      'temperature': temperature,
      'timestamp': timestamp.millisecondsSinceEpoch ~/ 1000,
    };
  }
}

// Model untuk data sensor kelembaban
class HumidityData {
  final String device;
  final String sensor;
  final double humidity;
  final DateTime timestamp;

  HumidityData({
    required this.device,
    required this.sensor,
    required this.humidity,
    required this.timestamp,
  });

  factory HumidityData.fromJson(Map<String, dynamic> json) {
    return HumidityData(
      device: json['device'] ?? 'Unknown',
      sensor: json['sensor'] ?? 'DHT22',
      humidity: (json['humidity'] ?? 0).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        ((json['timestamp'] ?? 0) * 1000).toInt(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device': device,
      'sensor': sensor,
      'humidity': humidity,
      'timestamp': timestamp.millisecondsSinceEpoch ~/ 1000,
    };
  }
}

// Model untuk data sensor gas
class GasData {
  final String device;
  final String sensor;
  final int gasPpm;
  final String status; // NORMAL, WARNING, DANGER
  final DateTime timestamp;

  GasData({
    required this.device,
    required this.sensor,
    required this.gasPpm,
    required this.status,
    required this.timestamp,
  });

  factory GasData.fromJson(Map<String, dynamic> json) {
    return GasData(
      device: json['device'] ?? 'Unknown',
      sensor: json['sensor'] ?? 'MQ-2',
      gasPpm: json['gas_ppm'] ?? 0,
      status: json['status'] ?? 'NORMAL',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        ((json['timestamp'] ?? 0) * 1000).toInt(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device': device,
      'sensor': sensor,
      'gas_ppm': gasPpm,
      'status': status,
      'timestamp': timestamp.millisecondsSinceEpoch ~/ 1000,
    };
  }

  // Helper untuk warna status
  int getStatusColor() {
    switch (status) {
      case 'DANGER':
        return 0xFFD32F2F; // Red
      case 'WARNING':
        return 0xFFFFA000; // Amber
      default:
        return 0xFF388E3C; // Green
    }
  }
}

// Model untuk data sensor cahaya
class LightData {
  final String device;
  final String sensor;
  final int lightLux;
  final DateTime timestamp;

  LightData({
    required this.device,
    required this.sensor,
    required this.lightLux,
    required this.timestamp,
  });

  factory LightData.fromJson(Map<String, dynamic> json) {
    return LightData(
      device: json['device'] ?? 'Unknown',
      sensor: json['sensor'] ?? 'LDR',
      lightLux: json['light_lux'] ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        ((json['timestamp'] ?? 0) * 1000).toInt(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device': device,
      'sensor': sensor,
      'light_lux': lightLux,
      'timestamp': timestamp.millisecondsSinceEpoch ~/ 1000,
    };
  }

  // Helper untuk status terang/gelap
  bool get isDark => lightLux < 300;
}

// Model untuk status pintu
class DoorStatus {
  final String device;
  final String status; // locked, unlocked
  final DateTime timestamp;

  DoorStatus({
    required this.device,
    required this.status,
    required this.timestamp,
  });

  factory DoorStatus.fromJson(Map<String, dynamic> json) {
    return DoorStatus(
      device: json['device'] ?? 'Unknown',
      status: json['status'] ?? 'locked',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        ((json['timestamp'] ?? 0) * 1000).toInt(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device': device,
      'status': status,
      'timestamp': timestamp.millisecondsSinceEpoch ~/ 1000,
    };
  }

  bool get isLocked => status == 'locked';
}
