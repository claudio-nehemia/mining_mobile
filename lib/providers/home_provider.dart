import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../models/home_data_model.dart';
import '../models/checkpoint_model.dart';
import '../models/log_activity_model.dart';
import '../services/home_service.dart';
import '../services/location_service.dart';
import '../services/checkin_service.dart';
import '../services/checkout_service.dart';
import '../services/location_tracking_service.dart';
import '../main.dart' as main_app;

class HomeProvider extends ChangeNotifier {
  HomeDataModel? _homeData;
  List<CheckPointModel> _nearbyCheckpoints = [];
  List<LogActivityModel> _todayHistory = [];
  bool _isLoading = false;
  String? _errorMessage;
  Position? _currentPosition;
  bool _isCheckedIn = false;
  String? _currentCheckpoint;
  String? _checkInTime;
  
  String? _checkoutRequestStatus;
  int? _checkoutRequestId;
  double? _checkoutBiaya;
  
  Timer? _autoRefreshTimer;
  bool _isAutoRefreshEnabled = true;
  static const Duration _refreshInterval = Duration(seconds: 10);

  // Getters
  HomeDataModel? get homeData => _homeData;
  List<CheckPointModel> get nearbyCheckpoints => _nearbyCheckpoints;
  List<LogActivityModel> get todayHistory => _todayHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Position? get currentPosition => _currentPosition;
  bool get isCheckedIn => _isCheckedIn;
  String? get currentCheckpoint => _currentCheckpoint;
  String? get checkInTime => _checkInTime;
  String? get checkoutRequestStatus => _checkoutRequestStatus;
  int? get checkoutRequestId => _checkoutRequestId;
  double? get checkoutBiaya => _checkoutBiaya;
  bool get isAutoRefreshEnabled => _isAutoRefreshEnabled;

  Future<void> loadHomeData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🏠 Loading home data...');
      
      debugPrint('📍 Getting GPS location first...');
      try {
        _currentPosition = await LocationService.getCurrentLocation();
        debugPrint('✅ Real GPS obtained: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      } catch (e) {
        debugPrint('⚠️ Could not get GPS location, trying last known: $e');
        try {
          _currentPosition = await LocationService.getLastKnownLocation();
          debugPrint('✅ Last known GPS obtained: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
        } catch (e2) {
          debugPrint('⚠️ No GPS available, will use Jakarta default: $e2');
          _currentPosition = null;
        }
      }
      
      _homeData = await HomeService.getHomeData();
      debugPrint('✅ Home data loaded: ${_homeData?.driver.name}');
      notifyListeners();
      
      final lat = _currentPosition?.latitude ?? -6.2088;
      final lng = _currentPosition?.longitude ?? 106.8456;
      
      await Future.wait([
        loadTodayHistory(),
        loadNearbyCheckpoints(lat, lng),
        loadCheckInStatus(),
        loadCheckoutStatus(),
      ]);
    } catch (e) {
      debugPrint('❌ Failed to load home data: $e');
      final errorMsg = e.toString();
      
      // Check if it's a session expired error
      if (errorMsg.contains('Session telah berakhir') || 
          errorMsg.contains('Unauthenticated') ||
          errorMsg.contains('401')) {
        debugPrint('🚪 Session expired, triggering logout...');
        main_app.handleSessionExpired();
        return;
      }
      
      _errorMessage = errorMsg.replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTodayHistory() async {
    try {
      debugPrint('📜 Loading today\'s history...');
      _todayHistory = await HomeService.getTodayHistory();
      debugPrint('✅ Loaded ${_todayHistory.length} history records');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to load today history: $e');
      _handleServiceError(e);
    }
  }

  Future<void> loadNearbyCheckpoints(double lat, double lng) async {
    try {
      debugPrint('📍 Loading nearby checkpoints...');
      _nearbyCheckpoints = await HomeService.getNearbyCheckpoints(
        latitude: lat,
        longitude: lng,
        radius: 10,
      );
      debugPrint('✅ Loaded ${_nearbyCheckpoints.length} nearby checkpoints');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to load nearby checkpoints: $e');
      _handleServiceError(e);
    }
  }

  Future<bool> turnOnStatus() async {
    try {
      debugPrint('🔄 Turning on status...');
      await HomeService.turnOnStatus();
      
      await LocationTrackingService.startTracking();
      
      if (_homeData != null) {
        _homeData = HomeDataModel(
          driver: _homeData!.driver.copyWith(status: 'active'),
          truck: _homeData!.truck?.copyWith(status: 'active'),
          saldo: _homeData!.saldo,
        );
        debugPrint('✅ Status updated to active');
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Failed to turn on status: $e');
      _handleServiceError(e);
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> turnOffStatus({
    required String reasonType,
    String? reasonDetail,
  }) async {
    try {
      debugPrint('🔄 Turning off status...');
      await HomeService.turnOffStatus(
        reasonType: reasonType,
        reasonDetail: reasonDetail,
      );
      
      LocationTrackingService.stopTracking();
      
      if (_homeData != null) {
        _homeData = HomeDataModel(
          driver: _homeData!.driver.copyWith(status: 'inactive'),
          truck: _homeData!.truck?.copyWith(status: 'maintenance'),
          saldo: _homeData!.saldo,
        );
        debugPrint('✅ Status updated to inactive');
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Failed to turn off status: $e');
      _handleServiceError(e);
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> checkInWithCheckpoint(int checkpointId) async {
    try {
      debugPrint('🔄 Performing check-in with checkpoint ID: $checkpointId');
      
      Position position;
      if (_currentPosition != null) {
        position = _currentPosition!;
      } else {
        try {
          final newPosition = await LocationService.getCurrentLocation();
          if (newPosition == null) {
            throw Exception('Tidak dapat mengambil lokasi GPS. Pastikan GPS aktif.');
          }
          position = newPosition;
          _currentPosition = position;
        } catch (e) {
          throw Exception('Tidak dapat mengambil lokasi GPS. Pastikan GPS aktif.');
        }
      }
      
      final result = await CheckInService.checkIn(
        checkpointId: checkpointId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      
      _isCheckedIn = true;
      _currentCheckpoint = result['checkpoint_name'];
      if (result['check_in_time'] != null) {
        final utcTime = DateTime.parse(result['check_in_time']);
        final localTime = utcTime.toLocal();
        _checkInTime = DateFormat('HH:mm:ss').format(localTime);
      } else {
        _checkInTime = result['check_in_time'];
      }
      
      debugPrint('✅ Check-in successful at: $_currentCheckpoint');
      
      notifyListeners();
      await loadTodayHistory();
      
      return result;
    } catch (e) {
      debugPrint('❌ Failed to check-in: $e');
      _handleServiceError(e);
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<List<CheckPointModel>> loadAllCheckpoints() async {
    try {
      debugPrint('📍 Loading all checkpoints...');
      
      Position position;
      if (_currentPosition != null) {
        position = _currentPosition!;
      } else {
        try {
          final newPosition = await LocationService.getCurrentLocation();
          if (newPosition != null) {
            position = newPosition;
            _currentPosition = position;
          } else {
            position = Position(
              latitude: -6.2088,
              longitude: 106.8456,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              altitudeAccuracy: 0,
              headingAccuracy: 0,
            );
          }
        } catch (e) {
          position = Position(
            latitude: -6.2088,
            longitude: 106.8456,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        }
      }
      
      final checkpoints = await CheckInService.getAllCheckpoints(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      
      debugPrint('✅ Loaded ${checkpoints.length} checkpoints');
      return checkpoints;
    } catch (e) {
      debugPrint('❌ Failed to load checkpoints: $e');
      _handleServiceError(e);
      rethrow;
    }
  }

  Future<void> loadCheckInStatus() async {
    try {
      debugPrint('🔄 Loading check-in status...');
      final status = await CheckInService.getCurrentStatus();
      final isCheckedIn = status['is_checked_in'] ?? false;
      
      if (isCheckedIn && status['checkpoint'] != null) {
        _isCheckedIn = true;
        _currentCheckpoint = status['checkpoint']['name'];
        if (status['check_in_time'] != null) {
          final utcTime = DateTime.parse(status['check_in_time']);
          final localTime = utcTime.toLocal();
          _checkInTime = DateFormat('HH:mm:ss').format(localTime);
        } else {
          _checkInTime = status['check_in_time'];
        }
        debugPrint('✅ Check-in active at: $_currentCheckpoint');
      } else {
        _isCheckedIn = false;
        _currentCheckpoint = null;
        _checkInTime = null;
        debugPrint('✅ No active check-in');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to load check-in status: $e');
      _handleServiceError(e);
      _isCheckedIn = false;
      _currentCheckpoint = null;
      _checkInTime = null;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> requestCheckout({
    required int checkpointId,
    required String namaMaterial,
    required double jumlahKubikasi,
    String? namaKernet,
  }) async {
    try {
      debugPrint('📤 Requesting checkout...');
      final result = await CheckoutService.requestCheckout(
        checkoutCheckpointId: checkpointId,
        namaMaterial: namaMaterial,
        jumlahKubikasi: jumlahKubikasi,
        namaKernet: namaKernet,
      );
      
      _checkoutRequestStatus = 'pending';
      _checkoutRequestId = result['request_id'];
      _checkoutBiaya = result['biaya_pemotongan']?.toDouble();
      
      debugPrint('✅ Checkout request created: ID $_checkoutRequestId');
      notifyListeners();
      
      return result;
    } catch (e) {
      debugPrint('❌ Failed to request checkout: $e');
      _handleServiceError(e);
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadCheckoutStatus() async {
    try {
      debugPrint('🔄 Loading checkout status...');
      final status = await CheckoutService.getCheckoutStatus();
      
      final hasActiveCheckIn = status['has_active_checkin'] ?? false;
      final checkoutStatus = status['checkout_request_status'];
      
      if (hasActiveCheckIn && checkoutStatus != null) {
        _checkoutRequestStatus = checkoutStatus;
        _checkoutRequestId = status['request_id'];
        _checkoutBiaya = status['biaya_pemotongan']?.toDouble();
        
        debugPrint('✅ Checkout status: $checkoutStatus');
        
        if (checkoutStatus == 'approved') {
          await loadCheckInStatus();
          await loadTodayHistory();
          _checkoutRequestStatus = null;
          _checkoutRequestId = null;
          _checkoutBiaya = null;
        }
      } else {
        _checkoutRequestStatus = null;
        _checkoutRequestId = null;
        _checkoutBiaya = null;
        debugPrint('✅ No checkout request');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to load checkout status: $e');
      _handleServiceError(e);
    }
  }
  
  void startAutoRefresh() {
    if (!_isAutoRefreshEnabled) return;
    
    _autoRefreshTimer?.cancel();
    debugPrint('🔄 Starting auto-refresh (every ${_refreshInterval.inSeconds}s)');
    
    _autoRefreshTimer = Timer.periodic(_refreshInterval, (timer) async {
      if (_isAutoRefreshEnabled && !_isLoading) {
        debugPrint('🔄 Auto-refreshing data...');
        await refreshData();
      }
    });
  }
  
  void stopAutoRefresh() {
    debugPrint('⏹️ Stopping auto-refresh');
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }
  
  void toggleAutoRefresh(bool enabled) {
    _isAutoRefreshEnabled = enabled;
    if (enabled) {
      startAutoRefresh();
    } else {
      stopAutoRefresh();
    }
    notifyListeners();
  }
  
  Future<void> refreshData() async {
    try {
      final oldSaldo = _homeData?.saldo?.amount;
      
      _homeData = await HomeService.getHomeData();
      
      final newSaldo = _homeData?.saldo?.amount;
      if (oldSaldo != null && newSaldo != null && oldSaldo != newSaldo) {
        debugPrint('💰 Saldo berubah: Rp $oldSaldo -> Rp $newSaldo');
      }
      
      await Future.wait([
        loadCheckInStatus(),
        loadCheckoutStatus(),
        loadTodayHistory(),
      ]);
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to refresh data: $e');
      _handleServiceError(e, silent: true);
    }
  }
  
  // Helper untuk handle service errors termasuk session expired
  void _handleServiceError(dynamic error, {bool silent = false}) {
    final errorMsg = error.toString();
    
    if (errorMsg.contains('Session telah berakhir') || 
        errorMsg.contains('Unauthenticated') ||
        errorMsg.contains('401')) {
      debugPrint('🚪 Session expired detected in service call');
      if (!silent) {
        main_app.handleSessionExpired();
      }
    }
  }
  
  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}