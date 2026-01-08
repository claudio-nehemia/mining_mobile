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
  
  // Checkout state
  String? _checkoutRequestStatus; // 'pending', 'rejected', or null
  int? _checkoutRequestId;
  double? _checkoutBiaya;
  
  // Auto-refresh timer
  Timer? _autoRefreshTimer;
  bool _isAutoRefreshEnabled = true;
  static const Duration _refreshInterval = Duration(seconds: 10);

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

  // Load home data
  Future<void> loadHomeData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🏠 Loading home data...');
      
      // Get GPS location FIRST before loading any data
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
      
      // Now load home data
      _homeData = await HomeService.getHomeData();
      debugPrint('✅ Home data loaded: ${_homeData?.driver.name}');
      debugPrint('🚛 Truck: ${_homeData?.truck?.noUnit ?? "No truck"}');
      debugPrint('💰 Saldo: ${_homeData?.saldo?.amount ?? 0}');
      notifyListeners();
      
      // After loading home data, load history and nearby checkpoints with GPS
      final lat = _currentPosition?.latitude ?? -6.2088; // Default Jakarta if GPS fails
      final lng = _currentPosition?.longitude ?? 106.8456;
      
      if (_currentPosition != null) {
        debugPrint('📍 Using real GPS for nearby checkpoints: $lat, $lng');
      } else {
        debugPrint('⚠️ Using default Jakarta coordinates: $lat, $lng');
      }
      
      await Future.wait([
        loadTodayHistory(),
        loadNearbyCheckpoints(lat, lng),
        loadCheckInStatus(),
        loadCheckoutStatus(),
      ]);
    } catch (e) {
      debugPrint('❌ Failed to load home data: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load today's history
  Future<void> loadTodayHistory() async {
    try {
      debugPrint('📜 Loading today\'s history...');
      _todayHistory = await HomeService.getTodayHistory();
      debugPrint('✅ Loaded ${_todayHistory.length} history records');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to load today history: $e');
    }
  }

  // Load nearby checkpoints
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
    }
  }

  // Turn on status
  Future<bool> turnOnStatus() async {
    try {
      debugPrint('🔄 Turning on status...');
      await HomeService.turnOnStatus();
      
      // Start location tracking when status becomes active
      await LocationTrackingService.startTracking();
      
      // Update status using copyWith
      if (_homeData != null) {
        _homeData = HomeDataModel(
          driver: _homeData!.driver.copyWith(status: 'active'),
          truck: _homeData!.truck,
          saldo: _homeData!.saldo,
        );
        debugPrint('✅ Status updated to active');
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Failed to turn on status: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Turn off status
  Future<bool> turnOffStatus() async {
    try {
      debugPrint('🔄 Turning off status...');
      await HomeService.turnOffStatus();
      
      // Stop location tracking
      LocationTrackingService.stopTracking();
      
      // Update status using copyWith
      if (_homeData != null) {
        _homeData = HomeDataModel(
          driver: _homeData!.driver.copyWith(status: 'inactive'),
          truck: _homeData!.truck,
          saldo: _homeData!.saldo,
        );
        debugPrint('✅ Status updated to inactive');
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Failed to turn off status: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Check-in
  Future<Map<String, dynamic>?> checkIn() async {
    try {
      debugPrint('🔄 Performing check-in...');
      
      // Get current GPS location
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
        position.latitude,
        position.longitude,
      );
      
      // Update state
      _isCheckedIn = true;
      _currentCheckpoint = result['checkpoint_name'];
      // Parse ISO timestamp and convert to local timezone
      if (result['check_in_time'] != null) {
        final utcTime = DateTime.parse(result['check_in_time']);
        final localTime = utcTime.toLocal();
        _checkInTime = DateFormat('HH:mm:ss').format(localTime);
      } else {
        _checkInTime = result['check_in_time'];
      }
      
      debugPrint('✅ Check-in successful at: $_currentCheckpoint');
      
      notifyListeners();
      
      // Reload history to show new check-in
      await loadTodayHistory();
      
      return result;
    } catch (e) {
      debugPrint('❌ Failed to check-in: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  // Load check-in status
  Future<void> loadCheckInStatus() async {
    try {
      debugPrint('🔄 Loading check-in status...');
      final status = await CheckInService.getCurrentStatus();
      final isCheckedIn = status['is_checked_in'] ?? false;
      
      if (isCheckedIn && status['checkpoint'] != null) {
        _isCheckedIn = true;
        _currentCheckpoint = status['checkpoint']['name'];
        // Parse ISO timestamp and convert to local timezone
        if (status['check_in_time'] != null) {
          final utcTime = DateTime.parse(status['check_in_time']);
          final localTime = utcTime.toLocal();
          _checkInTime = DateFormat('HH:mm:ss').format(localTime);
        } else {
          _checkInTime = status['check_in_time'];
        }
        debugPrint('✅ Check-in active at: $_currentCheckpoint');
      } else {
        // Clear check-in state ketika tidak ada check-in aktif
        _isCheckedIn = false;
        _currentCheckpoint = null;
        _checkInTime = null;
        debugPrint('✅ No active check-in');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to load check-in status: $e');
      // Clear state on error
      _isCheckedIn = false;
      _currentCheckpoint = null;
      _checkInTime = null;
      notifyListeners();
    }
  }

  // Request checkout dengan material data
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
      
      // Update checkout state
      _checkoutRequestStatus = 'pending';
      _checkoutRequestId = result['request_id'];
      _checkoutBiaya = result['biaya_pemotongan']?.toDouble();
      
      debugPrint('✅ Checkout request created: ID $_checkoutRequestId');
      notifyListeners();
      
      return result;
    } catch (e) {
      debugPrint('❌ Failed to request checkout: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  // Load checkout status
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
        
        // Jika approved, clear check-in dan reload
        if (checkoutStatus == 'approved') {
          await loadCheckInStatus();
          await loadTodayHistory();
          // Clear checkout state karena sudah selesai
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
    }
  }
  
  // Start auto-refresh
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
  
  // Stop auto-refresh
  void stopAutoRefresh() {
    debugPrint('⏹️ Stopping auto-refresh');
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }
  
  // Toggle auto-refresh
  void toggleAutoRefresh(bool enabled) {
    _isAutoRefreshEnabled = enabled;
    if (enabled) {
      startAutoRefresh();
    } else {
      stopAutoRefresh();
    }
    notifyListeners();
  }
  
  // Refresh data (lebih ringan dari loadHomeData)
  Future<void> refreshData() async {
    try {
      // Refresh data penting tanpa loading indicator untuk seamless UX
      final oldSaldo = _homeData?.saldo?.amount;
      
      // Refresh home data (termasuk saldo)
      _homeData = await HomeService.getHomeData();
      
      // Check jika ada perubahan saldo
      final newSaldo = _homeData?.saldo?.amount;
      if (oldSaldo != null && newSaldo != null && oldSaldo != newSaldo) {
        debugPrint('💰 Saldo berubah: Rp $oldSaldo -> Rp $newSaldo');
      }
      
      // Refresh status check-in dan checkout
      await Future.wait([
        loadCheckInStatus(),
        loadCheckoutStatus(),
        loadTodayHistory(),
      ]);
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to refresh data: $e');
      // Tidak set error message agar tidak mengganggu UX
    }
  }
  
  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
