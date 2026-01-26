import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  // Callback untuk handle unauthorized
  static Function(BuildContext)? onUnauthorized;
  
  static Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      debugPrint('📤 GET: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers ?? {'Content-Type': 'application/json'},
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      
      // Check for unauthorized
      if (response.statusCode == 401) {
        debugPrint('❌ 401 Unauthorized - Session expired');
        await _handleUnauthorized();
        throw Exception('Session telah berakhir. Silakan login kembali.');
      }

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ GET Error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> post(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    try {
      debugPrint('📤 POST: $url');
      if (body != null) {
        debugPrint('📦 Body: $body');
      }
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers ?? {'Content-Type': 'application/json'},
        body: body != null ? jsonEncode(body) : null,
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      
      // Check for unauthorized
      if (response.statusCode == 401) {
        debugPrint('❌ 401 Unauthorized - Session expired');
        await _handleUnauthorized();
        throw Exception('Session telah berakhir. Silakan login kembali.');
      }

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ POST Error: $e');
      rethrow;
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    debugPrint('📄 Response body: $body');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(body);
    } else {
      final error = jsonDecode(body);
      throw Exception(error['message'] ?? 'Request failed');
    }
  }
  
  static Future<void> _handleUnauthorized() async {
    // Clear auth data
    await AuthService.clearAuthData();
    
    // Trigger callback untuk navigate ke login
    // (Akan di-set dari main.dart atau app-level)
  }
}