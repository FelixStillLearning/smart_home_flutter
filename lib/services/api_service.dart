// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api';
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  String? _token;
  
  // Get token dari SharedPreferences
  Future<String?> getToken() async {
    if (_token != null) return _token;
    
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }
  
  // Set token ke SharedPreferences
  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  // Clear token
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }
  
  // Get headers dengan auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    
    return _handleResponse(response);
  }
  
  // Register
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? faceImage,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        if (faceImage != null) 'face_image': faceImage,
      }),
    );
    
    return _handleResponse(response);
  }
  
  // Get pending users (admin only)
  Future<Map<String, dynamic>> getPendingUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users/pending'),
      headers: await _getHeaders(),
    );
    
    return _handleResponse(response);
  }
  
  // Approve user (admin only)
  Future<Map<String, dynamic>> approveUser(int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/$userId/approve'),
      headers: await _getHeaders(),
    );
    
    return _handleResponse(response);
  }
  
  // Reject user (admin only)
  Future<Map<String, dynamic>> rejectUser(int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/$userId/reject'),
      headers: await _getHeaders(),
    );
    
    return _handleResponse(response);
  }
  
  // Get universal PIN (admin only)
  Future<Map<String, dynamic>> getUniversalPin() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/pin'),
      headers: await _getHeaders(),
    );
    
    return _handleResponse(response);
  }
  
  // Set universal PIN (admin only)
  Future<Map<String, dynamic>> setUniversalPin(String pin) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/pin'),
      headers: await _getHeaders(),
      body: jsonEncode({'pin': pin}),
    );
    
    return _handleResponse(response);
  }
  
  // Get door status
  Future<Map<String, dynamic>> getDoorStatus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/door/status'),
      headers: await _getHeaders(),
    );
    
    return _handleResponse(response);
  }
  
  // Control door
  Future<Map<String, dynamic>> controlDoor(String action) async {
    final response = await http.post(
      Uri.parse('$baseUrl/door/control'),
      headers: await _getHeaders(),
      body: jsonEncode({'action': action}),
    );
    
    return _handleResponse(response);
  }
  
  // Get lamp status
  Future<Map<String, dynamic>> getLampStatus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/lamp/status'),
      headers: await _getHeaders(),
    );
    
    return _handleResponse(response);
  }
  
  // Control lamp
  Future<Map<String, dynamic>> controlLamp(String action) async {
    final response = await http.post(
      Uri.parse('$baseUrl/lamp/control'),
      headers: await _getHeaders(),
      body: jsonEncode({'action': action}),
    );
    
    return _handleResponse(response);
  }
  
  // Get curtain status
  Future<Map<String, dynamic>> getCurtainStatus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/curtain/status'),
      headers: await _getHeaders(),
    );
    
    return _handleResponse(response);
  }
  
  // Control curtain
  Future<Map<String, dynamic>> controlCurtain(String action) async {
    final response = await http.post(
      Uri.parse('$baseUrl/curtain/control'),
      headers: await _getHeaders(),
      body: jsonEncode({'action': action}),
    );
    
    return _handleResponse(response);
  }
  
  // Get sensor data
  Future<Map<String, dynamic>> getSensorData(String sensorType) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$sensorType'),
      headers: await _getHeaders(),
    );
    
    return _handleResponse(response);
  }
  
  // Get access logs
  Future<Map<String, dynamic>> getAccessLogs({int limit = 20}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/access-logs?limit=$limit'),
      headers: await _getHeaders(),
    );
    
    return _handleResponse(response);
  }
  
  // Handle response
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Request failed');
    }
  }
}
