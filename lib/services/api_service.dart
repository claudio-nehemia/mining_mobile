import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Timeout duration
  static const Duration timeoutDuration = Duration(seconds: 30);

  // Generic GET request
  static Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: headers ?? {'Content-Type': 'application/json'},
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
    } on TimeoutException {
      throw Exception('Koneksi timeout. Server tidak merespon.');
    } on FormatException {
      throw Exception('Response format tidak valid.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Generic POST request
  static Future<Map<String, dynamic>> post(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: headers ?? {'Content-Type': 'application/json'},
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
    } on TimeoutException {
      throw Exception('Koneksi timeout. Server tidak merespon.');
    } on FormatException catch (e) {
      throw Exception('Response format tidak valid: $e');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Handle response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      print('🔍 Response status: ${response.statusCode}');
      print('🔍 Response body: ${response.body}');
      
      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Request failed');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to parse response: $e');
    }
  }
}