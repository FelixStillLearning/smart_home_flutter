import 'package:flutter/foundation.dart';
import '../models/sensor_models.dart';
import '../services/mqtt_service.dart';

class SmartHomeProvider with ChangeNotifier {
  final MqttService _mqttService = MqttService();

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

  // ========== MQTT CONNECTION ==========

  Future<bool> connectToMqtt() async {
    // Setup callbacks
    _mqttService.onTemperatureReceived = _handleTemperatureData;
    _mqttService.onHumidityReceived = _handleHumidityData;
    _mqttService.onGasReceived = _handleGasData;
    _mqttService.onLightReceived = _handleLightData;
    _mqttService.onDoorStatusReceived = _handleDoorStatusData;
    _mqttService.onConnectionStatusChanged = _handleConnectionStatusChanged;

    // Connect
    final success = await _mqttService.connect();
    if (success) {
      _isConnected = true;
      _connectionStatus = 'Connected';
      notifyListeners();
    }
    return success;
  }

  void disconnectFromMqtt() {
    _mqttService.disconnect();
    _isConnected = false;
    _connectionStatus = 'Disconnected';
    notifyListeners();
  }

  // ========== DATA HANDLERS ==========

  void _handleTemperatureData(Map<String, dynamic> data) {
    _temperatureData = TemperatureData.fromJson(data);
    
    // Add to history (keep last 20)
    _temperatureHistory.add(_temperatureData!);
    if (_temperatureHistory.length > 20) {
      _temperatureHistory.removeAt(0);
    }
    
    notifyListeners();
  }

  void _handleHumidityData(Map<String, dynamic> data) {
    _humidityData = HumidityData.fromJson(data);
    
    // Add to history
    _humidityHistory.add(_humidityData!);
    if (_humidityHistory.length > 20) {
      _humidityHistory.removeAt(0);
    }
    
    notifyListeners();
  }

  void _handleGasData(Map<String, dynamic> data) {
    _gasData = GasData.fromJson(data);
    
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

  void _handleLightData(Map<String, dynamic> data) {
    _lightData = LightData.fromJson(data);
    notifyListeners();
  }

  void _handleDoorStatusData(Map<String, dynamic> data) {
    _doorStatus = DoorStatus.fromJson(data);
    notifyListeners();
  }

  void _handleConnectionStatusChanged(String status) {
    _connectionStatus = status;
    _isConnected = status == 'Connected';
    notifyListeners();
  }

  // ========== CONTROL METHODS ==========

  void toggleDoor() {
    if (!_isConnected) return;
    
    final command = _doorStatus?.isLocked ?? true ? 'UNLOCK' : 'LOCK';
    _mqttService.publishDoorControl(command);
  }

  void lockDoor() {
    if (!_isConnected) return;
    _mqttService.publishDoorControl('LOCK');
  }

  void unlockDoor() {
    if (!_isConnected) return;
    _mqttService.publishDoorControl('UNLOCK');
  }

  void toggleLight() {
    if (!_isConnected) return;
    
    _isLightOn = !_isLightOn;
    final command = _isLightOn ? 'ON' : 'OFF';
    _mqttService.publishLightControl(command);
    notifyListeners();
  }

  void setLightState(bool isOn) {
    if (!_isConnected) return;
    
    _isLightOn = isOn;
    final command = isOn ? 'ON' : 'OFF';
    _mqttService.publishLightControl(command);
    notifyListeners();
  }

  void setCurtainPosition(int position) {
    if (!_isConnected) return;
    
    _curtainPosition = position.clamp(0, 100);
    _mqttService.publishCurtainControl(_curtainPosition);
    notifyListeners();
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
    _mqttService.disconnect();
    super.dispose();
  }
}
