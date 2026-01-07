import 'package:flutter/foundation.dart';

class CheckPointModel {
  final int id;
  final String name;
  final String kategori;
  final double latitude;
  final double longitude;
  final double distance;
  final String distanceText;

  CheckPointModel({
    required this.id,
    required this.name,
    required this.kategori,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.distanceText,
  });

  factory CheckPointModel.fromJson(Map<String, dynamic> json) {
    debugPrint('📍 Parsing CheckPointModel: ${json['name']}');
    return CheckPointModel(
      id: json['id'],
      name: json['name'],
      kategori: json['kategori'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      distance: double.parse(json['distance'].toString()),
      distanceText: json['distance_text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'kategori': kategori,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'distance_text': distanceText,
    };
  }
}
