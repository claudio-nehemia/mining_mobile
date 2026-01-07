import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import 'auth_service.dart';

class LocationTrackingService {
  static Timer? _locationTimer;
  static bool _isTracking = false;

  /// Start tracking location (send every 30 seconds)
  static Future<void> startTracking() async {
    if (_isTracking) {
      debugPrint('📍 Location tracking already started');
      return;
    }

    debugPrint('📍 Starting location tracking...');
    
    // Check permission first
    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) {
      debugPrint('❌ Location permission denied');
      return;
    }

    _isTracking = true;

    // Send location immediately
    await _sendCurrentLocation();

    // Then send every 30 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _sendCurrentLocation();
    });

    debugPrint('✅ Location tracking started (every 30 seconds)');
  }

  /// Stop tracking location
  static void stopTracking() {
    if (_locationTimer != null) {
      _locationTimer!.cancel();
      _locationTimer = null;
      _isTracking = false;
      debugPrint('🛑 Location tracking stopped');
    }
  }

  /// Check if currently tracking
  static bool get isTracking => _isTracking;

  /// Send current location to backend
  static Future<void> _sendCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      debugPrint('📍 Got location: ${position.latitude}, ${position.longitude}');

      final token = await AuthService.getToken();
      if (token == null) {
        debugPrint('❌ No token found');
        return;
      }

      final response = await ApiService.post(
        '${ApiConfig.baseUrl}/driver/location/update',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
      );

      if (response['success'] == true) {
        debugPrint('✅ Location sent to server');
      } else {
        debugPrint('⚠️ Failed to send location: ${response['message']}');
      }
    } catch (e) {
      debugPrint('❌ Error sending location: $e');
    }
  }

  /// Check and request location permission
  static Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('❌ Location services are disabled');
      return false;
    }

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('❌ Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('❌ Location permissions are permanently denied');
      return false;
    }

    return true;
  }

  /// Get current position once (for check-in)
  static Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      debugPrint('❌ Error getting current position: $e');
      return null;
    }
  }
}
