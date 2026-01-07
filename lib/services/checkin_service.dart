import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import 'auth_service.dart';

class CheckInService {
  /// Check-in ke checkpoint terdekat
  static Future<Map<String, dynamic>> checkIn(double latitude, double longitude) async {
    try {
      debugPrint('📍 Check-in request at: $latitude, $longitude');
      
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final response = await ApiService.post(
        '${ApiConfig.baseUrl}/driver/check-in',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      if (response['success']) {
        debugPrint('✅ Check-in successful: ${response['data']}');
        return response['data'];
      } else {
        throw Exception(response['message'] ?? 'Failed to check-in');
      }
    } catch (e) {
      debugPrint('❌ Error check-in: $e');
      rethrow;
    }
  }

  /// Get current check-in status
  static Future<Map<String, dynamic>> getCurrentStatus() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final response = await ApiService.get(
        '${ApiConfig.baseUrl}/driver/check-in/status',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response['success']) {
        return response['data'];
      } else {
        throw Exception(response['message'] ?? 'Failed to get status');
      }
    } catch (e) {
      debugPrint('❌ Error getting check-in status: $e');
      rethrow;
    }
  }
}
