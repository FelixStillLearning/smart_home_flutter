import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/sensor_models.dart';
import '../services/api_service.dart';

class SmartHomeProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  Timer? _pollingTimer;

  // ========== STATE VARIABLES ==========
  
  // Sensor data
  TemperatureData? _temperatureData;
  HumidityData? _humidityData;
  GasData? _gasData;
  LightData? _lightData;
  DoorStatus? _doorStatus;

  // Historical data untuk grafik (maks 20 data points)
  final List<TemperatureData> _temperatureHistory = [];
  final List<HumidityData> _humidityHistory = [];
  final List<GasData> _gasHistory = [];

  // Connection status
  bool _isConnected = false;
  String _connectionStatus = 'Disconnected';

  // Device controls state
  bool _isLightOn = false;
  int _curtainPosition = 0; // 0-100%

  // ========== GETTERS ==========

  TemperatureData? get temperatureData => _temperatureData;
  HumidityData? get humidityData => _humidityData;
  GasData? get gasData => _gasData;
  LightData? get lightData => _lightData;
  DoorStatus? get doorStatus => _doorStatus;

  List<TemperatureData> get temperatureHistory => _temperatureHistory;
  List<HumidityData> get humidityHistory => _humidityHistory;
  List<GasData> get gasHistory => _gasHistory;

  bool get isConnected => _isConnected;
  String get connectionStatus => _connectionStatus;

  bool get isLightOn => _isLightOn;
  int get curtainPosition => _curtainPosition;

  // ========== BACKEND CONNECTION ==========

  Future<bool> connectToBackend() async {
    // Menggunakan HTTP API polling untuk mendapatkan data real-time
    print('[API] Starting connection to Go backend...');
    
    // Check health backend
    final isHealthy = await _apiService.checkHealth();
    if (!isHealthy) {
      print('[API] ❌ Backend not responding');
      _isConnected = false;
      _connectionStatus = 'Backend Offline';
      notifyListeners();
      return false;
    }

    print('[API] ✅ Backend is healthy');
    
    // Fetch initial data
    await fetchAllSensorData();
    
    // Start polling untuk update real-time (setiap 3 detik)
    _startPolling();
    
    _isConnected = true;
    _connectionStatus = 'Connected';
    notifyListeners();
    return true;
  }

  void disconnectFromBackend() {
    _stopPolling();
    _isConnected = false;
    _connectionStatus = 'Disconnected';
    notifyListeners();
  }

  // ========== POLLING METHODS ==========

  void _startPolling() {
    _stopPolling();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      fetchAllSensorData();
    });
    print('[API] 📡 Started polling every 3 seconds');
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    print('[API] ⏹️ Stopped polling');
  }

  /// Fetch all sensor data dari Go API
  Future<void> fetchAllSensorData() async {
    try {
      final data = await _apiService.getAllSensorData();

      if (data['temperature'] != null) {
        _handleTemperatureData(data['temperature']);
      }
      if (data['humidity'] != null) {
        _handleHumidityData(data['humidity']);
      }
      if (data['gas'] != null) {
        _handleGasData(data['gas']);
      }
      if (data['light'] != null) {
        _handleLightData(data['light']);
      }
      if (data['door'] != null) {
        _handleDoorStatusData(data['door']);
      }
    } catch (e) {
      print('[API] ❌ Error fetching sensor data: $e');
    }
  }

  /// Fetch data sensor suhu
  Future<void> fetchTemperature() async {
    final data = await _apiService.getTemperature();
    if (data != null) {
      _handleTemperatureData(data);
    }
  }

  /// Fetch data sensor kelembaban
  Future<void> fetchHumidity() async {
    final data = await _apiService.getHumidity();
    if (data != null) {
      _handleHumidityData(data);
    }
  }

  /// Fetch data sensor gas
  Future<void> fetchGas() async {
    final data = await _apiService.getGas();
    if (data != null) {
      _handleGasData(data);
    }
  }

  /// Fetch data sensor cahaya
  Future<void> fetchLight() async {
    final data = await _apiService.getLight();
    if (data != null) {
      _handleLightData(data);
    }
  }

  /// Fetch status pintu
  Future<void> fetchDoorStatus() async {
    final data = await _apiService.getDoorStatus();
    if (data != null) {
      _handleDoorStatusData(data);
    }
  }

  /// Load historical data untuk grafik
  Future<void> loadHistoricalData() async {
    final tempHistory = await _apiService.getTemperatureHistory(limit: 20);
    final humHistory = await _apiService.getHumidityHistory(limit: 20);
    final gasHistory = await _apiService.getGasHistory(limit: 20);
    
    if (tempHistory.isNotEmpty) {
      _temperatureHistory.clear();
      _temperatureHistory.addAll(tempHistory);
    }
    
    if (humHistory.isNotEmpty) {
      _humidityHistory.clear();
      _humidityHistory.addAll(humHistory);
    }
    
    if (gasHistory.isNotEmpty) {
      _gasHistory.clear();
      _gasHistory.addAll(gasHistory);
    }
    
    notifyListeners();
  }

  // ========== DATA HANDLERS ==========

  void _handleTemperatureData(TemperatureData data) {
    _temperatureData = data;
    
    // Add to history (keep last 20)
    _temperatureHistory.add(_temperatureData!);
    if (_temperatureHistory.length > 20) {
      _temperatureHistory.removeAt(0);
    }
    
    notifyListeners();
  }

  void _handleHumidityData(HumidityData data) {
    _humidityData = data;
    
    // Add to history
    _humidityHistory.add(_humidityData!);
    if (_humidityHistory.length > 20) {
      _humidityHistory.removeAt(0);
    }
    
    notifyListeners();
  }

  void _handleGasData(GasData data) {
    _gasData = data;
    
    // Add to history
    _gasHistory.add(_gasData!);
    if (_gasHistory.length > 20) {
      _gasHistory.removeAt(0);
    }
    
    // Show alert jika DANGER
    if (_gasData!.status == 'DANGER') {
      debugPrint('⚠️ GAS DANGER DETECTED! ${_gasData!.gasPpm} PPM');
    }
    
    notifyListeners();
  }

  void _handleLightData(LightData data) {
    _lightData = data;
    notifyListeners();
  }

  void _handleDoorStatusData(DoorStatus data) {
    _doorStatus = data;
    notifyListeners();
  }

  // ========== CONTROL METHODS ==========

  void toggleDoor() async {
    if (!_isConnected) return;
    
    final command = _doorStatus?.isLocked ?? true ? 'UNLOCK' : 'LOCK';
    final success = await _apiService.controlDoor(command);
    
    if (success) {
      // Refresh door status setelah kontrol
      await Future.delayed(const Duration(milliseconds: 500));
      await fetchDoorStatus();
    }
  }

  void lockDoor() async {
    if (!_isConnected) return;
    
    final success = await _apiService.controlDoor('LOCK');
    
    if (success) {
      await Future.delayed(const Duration(milliseconds: 500));
      await fetchDoorStatus();
    }
  }

  void unlockDoor() async {
    if (!_isConnected) return;
    
    final success = await _apiService.controlDoor('UNLOCK');
    
    if (success) {
      await Future.delayed(const Duration(milliseconds: 500));
      await fetchDoorStatus();
    }
  }

  void toggleLight() async {
    if (!_isConnected) return;
    
    _isLightOn = !_isLightOn;
    final command = _isLightOn ? 'ON' : 'OFF';
    final success = await _apiService.controlLight(command);
    
    if (!success) {
      // Rollback jika gagal
      _isLightOn = !_isLightOn;
    }
    
    notifyListeners();
  }

  void setLightState(bool isOn) async {
    if (!_isConnected) return;
    
    _isLightOn = isOn;
    final command = isOn ? 'ON' : 'OFF';
    final success = await _apiService.controlLight(command);
    
    if (!success) {
      // Rollback jika gagal
      _isLightOn = !isOn;
    }
    
    notifyListeners();
  }

  void setCurtainPosition(int position) async {
    if (!_isConnected) return;
    
    final previousPosition = _curtainPosition;
    _curtainPosition = position.clamp(0, 100);
    notifyListeners();
    
    final success = await _apiService.controlCurtain(_curtainPosition);
    
    if (!success) {
      // Rollback jika gagal
      _curtainPosition = previousPosition;
      notifyListeners();
    }
  }

  // ========== UTILITY METHODS ==========

  String get temperatureString => _temperatureData != null
      ? '${_temperatureData!.temperature.toStringAsFixed(1)}°C'
      : '--°C';

  String get humidityString => _humidityData != null
      ? '${_humidityData!.humidity.toStringAsFixed(1)}%'
      : '--%';

  String get gasString => _gasData != null
      ? '${_gasData!.gasPpm} PPM'
      : '-- PPM';

  String get lightString => _lightData != null
      ? '${_lightData!.lightLux} LUX'
      : '-- LUX';

  String get doorStatusString => _doorStatus != null
      ? (_doorStatus!.isLocked ? 'TERKUNCI' : 'TERBUKA')
      : 'UNKNOWN';

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
