import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  // Getters
  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  /// Initialize auth state from storage
  Future<void> initAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final savedToken = await _apiService.getToken();
      final savedUser = await _apiService.getSavedUser();

      if (savedToken != null && savedUser != null) {
        _token = savedToken;
        _currentUser = savedUser;
        _isAuthenticated = true;
      }
    } catch (e) {
      print('[AuthProvider] Error initializing auth: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Register new user with face recognition
  Future<bool> registerWithFace({
    required String name,
    required String email,
    required String password,
    required String faceImage,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = RegisterRequest(
        name: name,
        email: email,
        password: password,
        faceImage: faceImage,
      );

      final response = await _apiService.register(request);

      if (response.success) {
        _currentUser = response.user;
        // Note: Registration doesn't return token, user needs approval
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.error ?? response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Registration failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? faceImage,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = RegisterRequest(
        name: name,
        email: email,
        password: password,
        faceImage: faceImage,
      );

      final response = await _apiService.register(request);

      if (response.success) {
        _currentUser = response.user;
        // Note: Registration doesn't return token, user needs approval
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.error ?? response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Registration failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = LoginRequest(
        email: email,
        password: password,
      );

      final response = await _apiService.login(request);

      if (response.success && response.user != null) {
        _currentUser = response.user;
        _token = response.token;
        _isAuthenticated = true;
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.error ?? response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Login failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.logout();
      _currentUser = null;
      _token = null;
      _isAuthenticated = false;
      _errorMessage = null;
    } catch (e) {
      print('[AuthProvider] Error during logout: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Check if user is admin
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  /// Check if user account is active
  bool get isActive => _currentUser?.isActive ?? false;

  /// Check if user account is pending
  bool get isPending => _currentUser?.isPending ?? false;

  /// Update current user data
  Future<void> updateUserData(User user) async {
    _currentUser = user;
    notifyListeners();
  }
}
