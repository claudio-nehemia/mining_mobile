import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import 'auth_service.dart';

class SaldoService {
  /// Request top up saldo
  static Future<void> requestTopUp(double amount) async {
    try {
      debugPrint('💰 Requesting top up: Rp $amount');
      
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final response = await ApiService.post(
        '${ApiConfig.baseUrl}/driver/request-saldo/top-up',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {
          'amount': amount,
        },
      );

      if (!response['success']) {
        throw Exception(response['message'] ?? 'Failed to request top up');
      }
      
      debugPrint('✅ Top up request created successfully');
    } catch (e) {
      debugPrint('❌ Error requesting top up: $e');
      rethrow;
    }
  }

  /// Get my pending requests
  static Future<List<Map<String, dynamic>>> getMyRequests() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final response = await ApiService.get(
        '${ApiConfig.baseUrl}/driver/request-saldo/my-requests',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response['success']) {
        return List<Map<String, dynamic>>.from(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to get requests');
      }
    } catch (e) {
      debugPrint('❌ Error getting requests: $e');
      rethrow;
    }
  }
}
