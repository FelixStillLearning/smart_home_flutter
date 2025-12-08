// lib/providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  
  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isAdmin => _user?.isAdmin ?? false;
  
  final ApiService _apiService = ApiService();
  
  // Initialize - cek token saat app start
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final token = await _apiService.getToken();
      
      if (token != null && !JwtDecoder.isExpired(token)) {
        // Load user data dari SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString('user_data');
        
        if (userJson != null) {
          _user = User.fromJson(jsonDecode(userJson));
          _isAuthenticated = true;
        }
      } else {
        // Token expired atau tidak ada
        await logout();
      }
    } catch (e) {
      await logout();
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Login
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _apiService.login(email, password);
      
      if (response['success'] && response['data'] != null) {
        final data = response['data'];
        final token = data['token'];
        final userData = data['user'];
        
        // Simpan token
        await _apiService.setToken(token);
        
        // Simpan user data
        _user = User.fromJson(userData);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(userData));
        
        _isAuthenticated = true;
      } else {
        throw Exception(response['message'] ?? 'Login gagal');
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Register
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? faceImage,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _apiService.register(
        name: name,
        email: email,
        password: password,
        faceImage: faceImage,
      );
      
      if (!response['success']) {
        throw Exception(response['message'] ?? 'Registrasi gagal');
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Logout
  Future<void> logout() async {
    await _apiService.clearToken();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
