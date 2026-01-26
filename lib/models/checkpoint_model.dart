import 'package:flutter/foundation.dart';

class CheckPointModel {
  final int id;
  final String name;
  final String kategori;
  final double latitude;
  final double longitude;
  final int radius;
  final double distance;
  final String distanceText;

  CheckPointModel({
    required this.id,
    required this.name,
    required this.kategori,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.distance,
    required this.distanceText,
  });

  factory CheckPointModel.fromJson(Map<String, dynamic> json) {
    try {
      // Helper function to safely parse double from various types
      double parseDouble(dynamic value, String fieldName) {
        if (value == null) {
          print('⚠️ Field $fieldName is null, returning 0.0');
          return 0.0;
        }
        
        if (value is double) return value;
        if (value is int) return value.toDouble();
        
        if (value is String) {
          final cleaned = value.trim();
          if (cleaned.isEmpty) {
            print('⚠️ Field $fieldName is empty string, returning 0.0');
            return 0.0;
          }
          
          final parsed = double.tryParse(cleaned);
          if (parsed == null) {
            print('❌ Cannot parse $fieldName: "$cleaned" to double');
            return 0.0;
          }
          return parsed;
        }
        
        print('⚠️ Field $fieldName has unknown type: ${value.runtimeType}');
        return 0.0;
      }

      // Helper function to safely parse int
      int parseInt(dynamic value, String fieldName) {
        if (value == null) {
          print('⚠️ Field $fieldName is null, returning 0');
          return 0;
        }
        
        if (value is int) return value;
        if (value is double) return value.toInt();
        
        if (value is String) {
          final cleaned = value.trim();
          if (cleaned.isEmpty) {
            print('⚠️ Field $fieldName is empty string, returning 0');
            return 0;
          }
          
          final parsed = int.tryParse(cleaned);
          if (parsed == null) {
            print('❌ Cannot parse $fieldName: "$cleaned" to int');
            return 0;
          }
          return parsed;
        }
        
        print('⚠️ Field $fieldName has unknown type: ${value.runtimeType}');
        return 0;
      }

      final checkpoint = CheckPointModel(
        id: parseInt(json['id'], 'id'),
        name: json['name']?.toString().trim() ?? 'Unknown',
        kategori: json['kategori']?.toString().trim() ?? 'unknown',
        latitude: parseDouble(json['latitude'], 'latitude'),
        longitude: parseDouble(json['longitude'], 'longitude'),
        radius: parseInt(json['radius'], 'radius'),
        distance: parseDouble(json['distance_km'], 'distance_km'),
        distanceText: json['distance_text']?.toString().trim() ?? '0 km',
      );
      
      // Validation
      if (checkpoint.id == 0) {
        print('⚠️ Checkpoint has ID 0: ${json['name']}');
      }
      
      return checkpoint;
    } catch (e, stackTrace) {
      print('❌ Critical error parsing CheckPointModel: $e');
      print('📦 JSON data: $json');
      print('🔍 Stack trace: $stackTrace');
      
      // Return a dummy checkpoint instead of crashing
      return CheckPointModel(
        id: 0,
        name: 'Error Checkpoint',
        kategori: 'unknown',
        latitude: 0.0,
        longitude: 0.0,
        radius: 0,
        distance: 0.0,
        distanceText: '0 km',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'kategori': kategori,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'distance_km': distance,
      'distance_text': distanceText,
    };
  }

  @override
  String toString() {
    return 'CheckPointModel(id: $id, name: $name, kategori: $kategori, '
        'lat: $latitude, lng: $longitude, distance: $distanceText)';
  }
}