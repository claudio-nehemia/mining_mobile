import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class CheckoutService {
  /// Get active check-in record
  static Future<Map<String, dynamic>> getActiveCheckIn() async {
    try {
      debugPrint('🔍 Getting active check-in...');
      
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/driver/checkout/active-checkin'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Active check-in response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else if (response.statusCode == 404) {
        throw Exception('Tidak ada check-in aktif');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Gagal mengambil data check-in');
      }
    } catch (e) {
      debugPrint('❌ Error getting active check-in: $e');
      rethrow;
    }
  }

  /// Get checkout checkpoints (dalam radius)
  static Future<List<Map<String, dynamic>>> getCheckoutCheckpoints(
    double latitude,
    double longitude,
  ) async {
    try {
      debugPrint('🔍 Getting checkout checkpoints...');
      
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/driver/checkout/checkpoints'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      debugPrint('Checkout checkpoints response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Gagal mengambil checkpoint');
      }
    } catch (e) {
      debugPrint('❌ Error getting checkout checkpoints: $e');
      rethrow;
    }
  }

  /// Request checkout
  static Future<Map<String, dynamic>> requestCheckout({
    required int checkoutCheckpointId,
    required String namaMaterial,
    required double jumlahKubikasi,
    String? namaKernet,
  }) async {
    try {
      debugPrint('📤 Requesting checkout...');
      
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/driver/checkout/request'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'checkout_checkpoint_id': checkoutCheckpointId,
          'nama_material': namaMaterial,
          'jumlah_kubikasi': jumlahKubikasi,
          'nama_kernet': namaKernet,
        }),
      );

      debugPrint('Checkout request response: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        final error = json.decode(response.body);
        final message = error['message'] ?? 'Gagal membuat request checkout';
        
        // Tambahkan detail error jika ada
        String detailMessage = message;
        if (error['errors'] != null) {
          final errors = error['errors'] as Map<String, dynamic>;
          final errorDetails = errors.values.map((e) => e.toString()).join(', ');
          detailMessage = '$message: $errorDetails';
        }
        
        debugPrint('❌ Checkout error: $detailMessage');
        throw Exception(detailMessage);
      }
    } catch (e) {
      debugPrint('❌ Error requesting checkout: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Gagal mengirim request checkout: ${e.toString()}');
    }
  }

  /// Get checkout status
  static Future<Map<String, dynamic>> getCheckoutStatus() async {
    try {
      debugPrint('🔍 Getting checkout status...');
      
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/driver/checkout/status'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Checkout status response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Gagal mengambil status checkout');
      }
    } catch (e) {
      debugPrint('❌ Error getting checkout status: $e');
      rethrow;
    }
  }
}
