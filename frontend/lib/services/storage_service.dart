import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token Management
  Future<void> saveToken(String token) async {
    await _prefs?.setString(AppConfig.tokenKey, token);
  }

  Future<String?> getToken() async {
    return _prefs?.getString(AppConfig.tokenKey);
  }

  Future<void> removeToken() async {
    await _prefs?.remove(AppConfig.tokenKey);
  }

  // User Data Management
  Future<void> saveUser(Map<String, dynamic> userData) async {
    await _prefs?.setString(AppConfig.userKey, jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final userStr = _prefs?.getString(AppConfig.userKey);
    if (userStr != null) {
      return jsonDecode(userStr);
    }
    return null;
  }

  Future<void> removeUser() async {
    await _prefs?.remove(AppConfig.userKey);
  }

  // Clear All Data
  Future<void> clearAll() async {
    await _prefs?.clear();
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}