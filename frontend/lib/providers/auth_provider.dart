import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../config/app_config.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _currentUser;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  // Check authentication status on app start
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isLoggedIn = await _storage.isLoggedIn();
      if (isLoggedIn) {
        _currentUser = await _storage.getUser();
        _isAuthenticated = true;
      }
    } catch (e) {
      _isAuthenticated = false;
      _currentUser = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Login
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.post(
        AppConfig.loginEndpoint,
        {
          'username': username,
          'password': password,
        },
        needsAuth: false,
      );

      if (response['success']) {
        await _storage.saveToken(response['token']);
        await _storage.saveUser(response['user']);
        
        _currentUser = response['user'];
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Đăng nhập thất bại';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String username,
    required String password,
    required String fullName,
    String? email,
    String role = 'receptionist',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.post(
        AppConfig.registerEndpoint,
        {
          'username': username,
          'password': password,
          'fullName': fullName,
          'email': email,
          'role': role,
        },
        needsAuth: false,
      );

      if (response['success']) {
        await _storage.saveToken(response['token']);
        await _storage.saveUser(response['user']);
        
        _currentUser = response['user'];
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Đăng ký thất bại';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _storage.clearAll();
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }

  // Get current user info
  Future<void> getCurrentUser() async {
    try {
      final response = await _api.get(AppConfig.meEndpoint);
      if (response['success']) {
        _currentUser = response['data'];
        await _storage.saveUser(_currentUser!);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error getting current user: $e');
    }
  }

  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.put(
        '/auth/change-password',
        {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      _isLoading = false;
      if (response['success']) {
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Đổi mật khẩu thất bại';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String? get userRole => _currentUser?['role'];
  String? get userName => _currentUser?['fullName'];
}