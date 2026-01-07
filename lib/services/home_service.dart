import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/home_data_model.dart';
import '../models/checkpoint_model.dart';
import '../models/log_activity_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class HomeService {
  // Get home data (driver + truck + saldo)
  static Future<HomeDataModel> getHomeData() async {
    try {
      debugPrint('🔄 Fetching home data...');
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      debugPrint('📡 API URL: ${ApiConfig.baseUrl}/driver/home');
      final response = await ApiService.get(
        '${ApiConfig.baseUrl}/driver/home',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📦 Response: ${response.toString()}');

      if (response['success']) {
        return HomeDataModel.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to get home data');
      }
    } catch (e) {
      debugPrint('❌ Error in getHomeData: $e');
      rethrow;
    }
  }

  // Get today's activity history
  static Future<List<LogActivityModel>> getTodayHistory() async {
    try {
      debugPrint('📜 Fetching today\'s history...');
      
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final response = await ApiService.get(
        '${ApiConfig.baseUrl}/driver/home/history',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📜 History response: $response');

      if (response['success']) {
        final List<dynamic> data = response['data'];
        debugPrint('📜 Found ${data.length} history records');
        return data.map((json) => LogActivityModel.fromJson(json)).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to get history');
      }
    } catch (e) {
      debugPrint('❌ Error in getTodayHistory: $e');
      rethrow;
    }
  }

  // Get nearby checkpoints
  static Future<List<CheckPointModel>> getNearbyCheckpoints({
    required double latitude,
    required double longitude,
    double radius = 10,
  }) async {
    try {
      debugPrint('📍 Fetching nearby checkpoints...');
      debugPrint('   Lat: $latitude, Lng: $longitude, Radius: $radius km');
      
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final response = await ApiService.post(
        '${ApiConfig.baseUrl}/driver/home/nearby-checkpoints',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {
          'latitude': latitude,
          'longitude': longitude,
          'radius': radius,
        },
      );

      debugPrint('📍 Nearby checkpoints response: $response');

      if (response['success']) {
        final List<dynamic> data = response['data'];
        debugPrint('📍 Found ${data.length} nearby checkpoints');
        return data.map((json) => CheckPointModel.fromJson(json)).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to get nearby checkpoints');
      }
    } catch (e) {
      debugPrint('❌ Error in getNearbyCheckpoints: $e');
      rethrow;
    }
  }

  // Turn on driver status
  static Future<void> turnOnStatus() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final response = await ApiService.post(
        '${ApiConfig.baseUrl}/driver/home/status/on',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!response['success']) {
        throw Exception(response['message'] ?? 'Failed to turn on status');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Turn off driver status
  static Future<void> turnOffStatus() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final response = await ApiService.post(
        '${ApiConfig.baseUrl}/driver/home/status/off',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!response['success']) {
        throw Exception(response['message'] ?? 'Failed to turn off status');
      }
    } catch (e) {
      rethrow;
    }
  }
}
