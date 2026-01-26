import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/checkpoint_model.dart';
import 'auth_service.dart';

class CheckInService {
  static const String _getAllCheckpointsEndpoint = '/driver/check-in/checkpoints';
  static const String _checkInEndpoint = '/driver/check-in';
  static const String _statusEndpoint = '/driver/check-in/status';

  /// Get all available checkpoints with distance calculation
  static Future<List<CheckPointModel>> getAllCheckpoints({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final url = Uri.parse(ApiConfig.baseUrl + _getAllCheckpointsEndpoint);
      debugPrint('📡 GET All Checkpoints: $url');
      debugPrint('📍 Location: $latitude, $longitude');

      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response length: ${response.body.length} bytes');
      
      // Log first 500 chars untuk debugging
      if (response.body.length > 500) {
        debugPrint('📥 Response body (first 500 chars): ${response.body.substring(0, 500)}...');
      } else {
        debugPrint('📥 Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        Map<String, dynamic> data;
        
        try {
          // Decode JSON with error handling
          data = jsonDecode(response.body);
          debugPrint('✅ JSON decoded successfully');
        } catch (e) {
          debugPrint('❌ JSON Decode Error: $e');
          debugPrint('📄 Full response body: ${response.body}');
          throw Exception('Format response tidak valid: $e');
        }
        
        if (data['success'] == true) {
          final checkpointsData = data['data']['checkpoints'] as List;
          debugPrint('📊 Total checkpoints in response: ${checkpointsData.length}');
          
          // Parse each checkpoint dengan error handling individual
          final List<CheckPointModel> checkpoints = [];
          int successCount = 0;
          int errorCount = 0;
          
          for (int i = 0; i < checkpointsData.length; i++) {
            try {
              final checkpoint = CheckPointModel.fromJson(checkpointsData[i]);
              checkpoints.add(checkpoint);
              successCount++;
              
              // Log setiap 5 checkpoint yang berhasil
              if (successCount % 5 == 0) {
                debugPrint('✅ Parsed $successCount checkpoints...');
              }
            } catch (e) {
              errorCount++;
              debugPrint('❌ Error parsing checkpoint $i: $e');
              debugPrint('📦 Problematic data: ${jsonEncode(checkpointsData[i])}');
              // Continue parsing the rest
              continue;
            }
          }
          
          debugPrint('✅ Successfully parsed $successCount checkpoints');
          if (errorCount > 0) {
            debugPrint('⚠️ Failed to parse $errorCount checkpoints');
          }
          
          if (checkpoints.isEmpty) {
            throw Exception('Tidak ada checkpoint yang valid');
          }
          
          return checkpoints;
        } else {
          throw Exception(data['message'] ?? 'Gagal mengambil data checkpoint');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session telah berakhir. Silakan login kembali.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal mengambil data checkpoint');
      }
    } catch (e) {
      debugPrint('❌ Error getting all checkpoints: $e');
      rethrow;
    }
  }

  /// Check-in to selected checkpoint
  static Future<Map<String, dynamic>> checkIn({
    required int checkpointId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final url = Uri.parse(ApiConfig.baseUrl + _checkInEndpoint);
      debugPrint('📡 POST Check-in: $url');
      debugPrint('📍 Checkpoint ID: $checkpointId, Location: $latitude, $longitude');

      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'checkpoint_id': checkpointId,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          return {
            'checkpoint_name': data['data']['checkpoint_name'],
            'check_in_time': data['data']['check_in_time'],
            'distance': data['data']['distance_km'],
            'status': data['data']['status'],
          };
        } else {
          throw Exception(data['message'] ?? 'Check-in gagal');
        }
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Check-in gagal');
      } else if (response.statusCode == 401) {
        throw Exception('Session telah berakhir. Silakan login kembali.');
      } else if (response.statusCode == 403) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Akun tidak aktif');
      } else if (response.statusCode == 404) {
        throw Exception('Checkpoint tidak ditemukan atau tidak aktif');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Check-in gagal');
      }
    } catch (e) {
      debugPrint('❌ Error checking in: $e');
      rethrow;
    }
  }

  /// Get current check-in status
  static Future<Map<String, dynamic>> getCurrentStatus() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final url = Uri.parse(ApiConfig.baseUrl + _statusEndpoint);
      debugPrint('📡 GET Check-in Status: $url');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else if (response.statusCode == 401) {
        throw Exception('Session telah berakhir. Silakan login kembali.');
      } else {
        throw Exception('Gagal mengambil status check-in');
      }
    } catch (e) {
      debugPrint('❌ Error getting check-in status: $e');
      rethrow;
    }
  }
}