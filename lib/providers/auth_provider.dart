import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/driver_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  DriverModel? _driver;
  bool _isLoading = false;
  String? _errorMessage;

  DriverModel? get driver => _driver;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _driver != null;

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🚀 Starting login process...');
      final response = await AuthService.login(email, password);
      _driver = DriverModel.fromJson(response['data']['driver']);
      _isLoading = false;
      notifyListeners();
      debugPrint('✅ Login completed successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Login failed in provider: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load profile
  Future<void> loadProfile() async {
    try {
      _driver = await AuthService.getProfile();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    await AuthService.logout();
    _driver = null;
    notifyListeners();
  }

  // Check if logged in
  Future<bool> checkAuth() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    if (isLoggedIn) {
      await loadProfile();
    }
    return isLoggedIn;
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}