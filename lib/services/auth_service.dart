import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/driver_model.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _driverKey = 'driver_data';

  // Login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      debugPrint('🔐 Login attempt for: $email');
      debugPrint('📡 API URL: ${ApiConfig.loginUrl}');
      
      final response = await ApiService.post(
        ApiConfig.loginUrl,
        body: {
          'email': email,
          'password': password,
        },
      );

      debugPrint('✅ Login response received');

      if (response['success']) {
        // Save token
        final token = response['data']['token'];
        debugPrint('💾 Saving token...');
        await _saveToken(token);

        // Save driver data
        final driverData = response['data']['driver'];
        debugPrint('💾 Saving driver data...');
        await _saveDriverData(driverData);

        debugPrint('✅ Login successful');
        return response;
      } else {
        throw Exception(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      rethrow;
    }
  }

  // Get Profile
  static Future<DriverModel> getProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final response = await ApiService.get(
        ApiConfig.profileUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response['success']) {
        return DriverModel.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to get profile');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  static Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await ApiService.post(
          ApiConfig.logoutUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (e) {
      // Silent fail - still clear local data
    } finally {
      await clearAuthData();
    }
  }

  // Save token
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Get token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Save driver data
  static Future<void> _saveDriverData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final driver = DriverModel.fromJson(data);
    await prefs.setString(_driverKey, driver.toJson().toString());
  }

  // Clear auth data
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_driverKey);
  }

  // Check if logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}