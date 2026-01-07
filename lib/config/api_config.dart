import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // Base URL dari .env file
  static String get baseUrl {
    final url = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api';
    debugPrint('🌐 API Base URL: $url');
    return url;
  }
  
  // Endpoints
  static const String loginEndpoint = '/driver/login';
  static const String logoutEndpoint = '/driver/logout';
  static const String profileEndpoint = '/driver/profile';
  
  // Full URLs
  static String get loginUrl => baseUrl + loginEndpoint;
  static String get logoutUrl => baseUrl + logoutEndpoint;
  static String get profileUrl => baseUrl + profileEndpoint;
}
