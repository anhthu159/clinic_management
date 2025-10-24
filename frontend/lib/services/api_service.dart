import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final StorageService _storage = StorageService();

  Future<Map<String, String>> _getHeaders({bool needsAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (needsAuth) {
      final token = await _storage.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(String endpoint, {bool needsAuth = true}) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
      final headers = await _getHeaders(needsAuth: needsAuth);

      final response = await http.get(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data, {bool needsAuth = true}) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
      final headers = await _getHeaders(needsAuth: needsAuth);

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data, {bool needsAuth = true}) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
      final headers = await _getHeaders(needsAuth: needsAuth);

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> data, {bool needsAuth = true}) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
      final headers = await _getHeaders(needsAuth: needsAuth);

      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  Future<dynamic> delete(String endpoint, {bool needsAuth = true}) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
      final headers = await _getHeaders(needsAuth: needsAuth);

      final response = await http.delete(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    final body = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      final message = body['message'] ?? 'Có lỗi xảy ra';
      throw Exception(message);
    }
  }
}

// API Response Model
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final dynamic error;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromJsonT) {
    return ApiResponse(
      success: json['success'] ?? false,
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : null,
      message: json['message'],
      error: json['error'],
    );
  }
}