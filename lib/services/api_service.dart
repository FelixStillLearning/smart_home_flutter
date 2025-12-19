import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_models.dart';
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ========== KONFIGURASI API ==========
  // Untuk Android Emulator gunakan 10.0.2.2 (bukan localhost)
  // Untuk iOS Simulator atau Physical Device, gunakan IP komputer Anda
  static const String baseUrl = 'http://10.124.88.57:8080';

  // API Endpoints - Disesuaikan dengan backend Go
  static const String endpointTemperature = '/api/sensor/temperature';
  static const String endpointHumidity = '/api/sensor/humidity';
  static const String endpointGas = '/api/sensor/gas';
  static const String endpointLight = '/api/sensor/light';
  static const String endpointDoor = '/api/device/door/latest';
  static const String endpointDoorControl = '/api/control/door';
  static const String endpointLampControl = '/api/control/lamp';
  static const String endpointCurtainControl = '/api/control/curtain';

  // Auth Endpoints
  static const String endpointRegister = '/api/auth/register';
  static const String endpointLogin = '/api/auth/login';

  // Timeout duration
  static const Duration timeoutDuration = Duration(seconds: 10);
  static const Duration authTimeoutDuration =
      Duration(seconds: 60); // Longer for face validation + enrollment

  // Token storage key
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // ========== AUTH METHODS ==========

  /// Save token to local storage
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Get saved token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Save user data to local storage
  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  /// Get saved user data
  Future<User?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  /// Clear token and user data (logout)
  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// Register new user
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      print('[API] Starting registration...');
      print('[API] URL: $baseUrl$endpointRegister');
      print('[API] Name: ${request.name}');
      print('[API] Email: ${request.email}');
      print(
          '[API] Has face image: ${request.faceImage != null && request.faceImage!.isNotEmpty}');
      if (request.faceImage != null) {
        print(
            '[API] Face image length: ${request.faceImage!.length} characters');
      }

      final requestBody = jsonEncode(request.toJson());
      print('[API] Request body size: ${requestBody.length} bytes');

      final response = await http
          .post(
            Uri.parse('$baseUrl$endpointRegister'),
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          )
          .timeout(authTimeoutDuration);

      print('[API] Response status: ${response.statusCode}');
      print('[API] Response body: ${response.body}');

      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Registration successful
        final authResponse = AuthResponse.fromJson(jsonData);

        // Save user data if available
        if (authResponse.user != null) {
          await _saveUser(authResponse.user!);
        }

        return authResponse;
      } else {
        // Registration failed
        return AuthResponse(
          success: false,
          message: jsonData['error'] ?? 'Registration failed',
          error: jsonData['error'],
        );
      }
    } catch (e) {
      print('[API] Exception during registration: $e');
      return AuthResponse(
        success: false,
        message: 'Connection error',
        error: e.toString(),
      );
    }
  }

  /// Login user
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpointLogin'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(timeoutDuration);

      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Login successful
        final authResponse = AuthResponse.fromJson(jsonData);

        // Save token and user data
        if (authResponse.token != null) {
          await _saveToken(authResponse.token!);
        }
        if (authResponse.user != null) {
          await _saveUser(authResponse.user!);
        }

        return authResponse;
      } else {
        // Login failed
        return AuthResponse(
          success: false,
          message: jsonData['error'] ?? 'Login failed',
          error: jsonData['error'],
        );
      }
    } catch (e) {
      print('[API] Exception during login: $e');
      return AuthResponse(
        success: false,
        message: 'Connection error',
        error: e.toString(),
      );
    }
  }

  /// Logout user
  Future<void> logout() async {
    await clearAuth();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ========== SENSOR DATA METHODS (GET) ==========

  /// Get data sensor suhu
  Future<TemperatureData?> getTemperature() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpointTemperature?limit=1'))
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        // Backend returns: {"data": [{"temp_id": 1, "temperature": 28.5, "timestamp": "..."}]}
        if (jsonData['data'] != null && (jsonData['data'] as List).isNotEmpty) {
          final latestData = (jsonData['data'] as List).first;
          return TemperatureData(
            device: 'ESP32-01',
            sensor: 'DHT22',
            temperature: (latestData['temperature'] ?? 0).toDouble(),
            timestamp: DateTime.parse(latestData['timestamp']),
          );
        }
        return null;
      } else {
        print('[API] Error getting temperature: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[API] Exception getting temperature: $e');
      return null;
    }
  }

  /// Get data sensor kelembaban
  Future<HumidityData?> getHumidity() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpointHumidity?limit=1'))
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        // Backend returns: {"data": [{"humid_id": 1, "humidity": 65.3, "timestamp": "..."}]}
        if (jsonData['data'] != null && (jsonData['data'] as List).isNotEmpty) {
          final latestData = (jsonData['data'] as List).first;
          return HumidityData(
            device: 'ESP32-01',
            sensor: 'DHT22',
            humidity: (latestData['humidity'] ?? 0).toDouble(),
            timestamp: DateTime.parse(latestData['timestamp']),
          );
        }
        return null;
      } else {
        print('[API] Error getting humidity: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[API] Exception getting humidity: $e');
      return null;
    }
  }

  /// Get data sensor gas
  Future<GasData?> getGas() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpointGas?limit=1'))
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        // Backend returns: {"data": [{"gas_id": 1, "ppm_value": 150, "status": "normal", "timestamp": "..."}]}
        if (jsonData['data'] != null && (jsonData['data'] as List).isNotEmpty) {
          final latestData = (jsonData['data'] as List).first;
          return GasData(
            device: 'ESP32-02',
            sensor: 'MQ-2',
            gasPpm: latestData['ppm_value'] ?? 0,
            status: (latestData['status'] ?? 'normal').toUpperCase(),
            timestamp: DateTime.parse(latestData['timestamp']),
          );
        }
        return null;
      } else {
        print('[API] Error getting gas: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[API] Exception getting gas: $e');
      return null;
    }
  }

  /// Get data sensor cahaya
  Future<LightData?> getLight() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpointLight?limit=1'))
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        // Backend returns: {"data": [{"light_id": 1, "lux_value": 450, "timestamp": "..."}]}
        if (jsonData['data'] != null && (jsonData['data'] as List).isNotEmpty) {
          final latestData = (jsonData['data'] as List).first;
          return LightData(
            device: 'ESP32-03',
            sensor: 'LDR',
            lightLux: latestData['lux_value'] ?? 0,
            timestamp: DateTime.parse(latestData['timestamp']),
          );
        }
        return null;
      } else {
        print('[API] Error getting light: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[API] Exception getting light: $e');
      return null;
    }
  }

  /// Get status pintu
  Future<DoorStatus?> getDoorStatus() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpointDoor'))
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        // Backend returns: {"success": true, "data": {"door_id": 1, "status": "locked", "method": "remote", "timestamp": "..."}}
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final data = jsonData['data'];
          return DoorStatus(
            device: 'SmartLock-01',
            status: data['status'] ?? 'locked',
            timestamp: DateTime.parse(data['timestamp']),
          );
        }
        return null;
      } else {
        print('[API] Error getting door status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[API] Exception getting door status: $e');
      return null;
    }
  }

  /// Get semua data sensor sekaligus
  Future<Map<String, dynamic>> getAllSensorData() async {
    final results = await Future.wait([
      getTemperature(),
      getHumidity(),
      getGas(),
      getLight(),
      getDoorStatus(),
    ]);

    return {
      'temperature': results[0],
      'humidity': results[1],
      'gas': results[2],
      'light': results[3],
      'door': results[4],
    };
  }

  // ========== CONTROL METHODS (POST) ==========

  /// Kontrol pintu (LOCK/UNLOCK)
  Future<bool> controlDoor(String command) async {
    try {
      // Backend expects: {"action": "lock/unlock", "method": "remote"}
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpointDoorControl'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'action': command.toLowerCase(),
              'method': 'remote',
            }),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('[API] Door control success: $command - ${jsonData['message']}');
        return jsonData['success'] == true;
      } else {
        print('[API] Door control failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('[API] Exception controlling door: $e');
      return false;
    }
  }

  /// Kontrol lampu (ON/OFF)
  Future<bool> controlLight(String command) async {
    try {
      // Backend expects: {"action": "on/off", "mode": "manual"}
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpointLampControl'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'action': command.toLowerCase(),
              'mode': 'manual',
            }),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('[API] Light control success: $command - ${jsonData['message']}');
        return jsonData['success'] == true;
      } else {
        print('[API] Light control failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('[API] Exception controlling light: $e');
      return false;
    }
  }

  /// Kontrol tirai (SET_POSITION)
  Future<bool> controlCurtain(int position) async {
    try {
      // Backend expects: {"position": 1-100, "mode": "manual", "action": "open/close"}
      // Validasi backend: min=1, max=100
      final curtainPosition = position.clamp(1, 100);

      // Tentukan action berdasarkan position
      String action = '';
      if (position >= 100) {
        action = 'open';
      } else if (position <= 0) {
        action = 'close';
      }

      final requestBody = {
        'position': curtainPosition,
        'mode': 'manual',
        if (action.isNotEmpty) 'action': action,
      };

      print(
          '[API] Sending curtain control: position=$curtainPosition%, action=$action');

      final response = await http
          .post(
            Uri.parse('$baseUrl$endpointCurtainControl'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(timeoutDuration);

      print('[API] Curtain control response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('[API] Curtain control success: ${jsonData['message']}');
        return jsonData['success'] == true;
      } else {
        print(
            '[API] Curtain control failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('[API] Exception controlling curtain: $e');
      return false;
    }
  }

  // ========== HISTORICAL DATA METHODS ==========

  /// Get historical data untuk grafik (opsional)
  Future<List<TemperatureData>> getTemperatureHistory({int limit = 20}) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpointTemperature?limit=$limit'))
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['data'] != null) {
          final List<dynamic> dataList = jsonData['data'];
          return dataList
              .map((item) => TemperatureData(
                    device: 'ESP32-01',
                    sensor: 'DHT22',
                    temperature: (item['temperature'] ?? 0).toDouble(),
                    timestamp: DateTime.parse(item['timestamp']),
                  ))
              .toList();
        }
        return [];
      } else {
        print(
            '[API] Error getting temperature history: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[API] Exception getting temperature history: $e');
      return [];
    }
  }

  Future<List<HumidityData>> getHumidityHistory({int limit = 20}) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpointHumidity?limit=$limit'))
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['data'] != null) {
          final List<dynamic> dataList = jsonData['data'];
          return dataList
              .map((item) => HumidityData(
                    device: 'ESP32-01',
                    sensor: 'DHT22',
                    humidity: (item['humidity'] ?? 0).toDouble(),
                    timestamp: DateTime.parse(item['timestamp']),
                  ))
              .toList();
        }
        return [];
      } else {
        print('[API] Error getting humidity history: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[API] Exception getting humidity history: $e');
      return [];
    }
  }

  Future<List<GasData>> getGasHistory({int limit = 20}) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpointGas?limit=$limit'))
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['data'] != null) {
          final List<dynamic> dataList = jsonData['data'];
          return dataList
              .map((item) => GasData(
                    device: 'ESP32-02',
                    sensor: 'MQ-2',
                    gasPpm: item['ppm_value'] ?? 0,
                    status: (item['status'] ?? 'normal').toUpperCase(),
                    timestamp: DateTime.parse(item['timestamp']),
                  ))
              .toList();
        }
        return [];
      } else {
        print('[API] Error getting gas history: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[API] Exception getting gas history: $e');
      return [];
    }
  }

  // ========== HEALTH CHECK ==========

  /// Check apakah backend API online
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return jsonData['status'] == 'healthy';
      }
      return false;
    } catch (e) {
      print('[API] Health check failed: $e');
      return false;
    }
  }
}
