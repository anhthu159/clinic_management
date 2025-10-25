import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../config/app_config.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  bool _isLoading = true;  // Start with loading state
  bool _isAuthenticated = false;
  Map<String, dynamic>? _currentUser;
  String? _errorMessage;
  bool _initialized = false;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get initialized => _initialized;

  // Check authentication status on app start
  Future<void> checkAuthStatus() async {
    if (_initialized) return; // Skip if already initialized

    try {
      final isLoggedIn = await _storage.isLoggedIn();
      if (isLoggedIn) {
        _currentUser = await _storage.getUser();
        _isAuthenticated = true;
        // Lấy thông tin user mới nhất từ server
        await getCurrentUser();
      } else {
        _isAuthenticated = false;
        _currentUser = null;
      }
    } catch (e) {
      _isAuthenticated = false;
      _currentUser = null;
    } finally {
      _isLoading = false;
      _initialized = true;
      notifyListeners();
    }
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

  // Update profile
  Future<bool> updateProfile({
    required String fullName,
    String? email,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.put(
        '/auth/profile',
        {
          'fullName': fullName,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
        },
      );

      _isLoading = false;
      if (response['success']) {
        // Cập nhật thông tin user trong state và storage
        _currentUser = response['data'];
        await _storage.saveUser(_currentUser!);
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Cập nhật thông tin thất bại';
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

  String? get userRole => _currentUser?['role'] ?? 'User';
  // Prefer showing the actual account username first (keeps display stable if fullName is a generic label)
  String get userName => _currentUser?['username'] ?? _currentUser?['fullName'] ?? 'Người dùng';

  // Kiểm tra role
  bool get isAdmin => userRole == 'admin';
  bool get isDoctor => userRole == 'doctor';
  bool get isReceptionist => userRole == 'receptionist';
  bool get isAccountant => userRole == 'accountant';

  // Quyền Bệnh nhân
  bool get canCreatePatient => isAdmin || isReceptionist;
  bool get canDeletePatient => isAdmin;

  // Quyền Hồ sơ khám
  bool get canCreateMedicalRecord => isAdmin || isDoctor;

  // Quyền Thanh toán
  bool get canManageBilling => isAdmin || isAccountant;

  // Quyền Dịch vụ & Thuốc
  bool get canManageServices => isAdmin;
  bool get canManageMedicines => isAdmin;

  // Quyền Báo cáo
  bool get canViewReports => isAdmin || isDoctor || isAccountant;

  // Tên role hiển thị
  String get roleDisplayName {
    switch (userRole) {
      case 'admin':
        return 'Quản trị viên';
      case 'doctor':
        return 'Bác sĩ';
      case 'receptionist':
        return 'Lễ tân';
      case 'accountant':
        return 'Kế toán';
      default:
        return 'Người dùng';
    }
  }
}