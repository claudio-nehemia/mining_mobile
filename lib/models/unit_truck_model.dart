import 'package:flutter/foundation.dart';

class UnitTruckModel {
  final int id;
  final String noUnit;
  final String plateNumber;
  final String status;

  UnitTruckModel({
    required this.id,
    required this.noUnit,
    required this.plateNumber,
    required this.status,
  });

  factory UnitTruckModel.fromJson(Map<String, dynamic> json) {
    debugPrint('🚛 Parsing UnitTruckModel from JSON: $json');
    return UnitTruckModel(
      id: json['id'],
      noUnit: json['no_unit'] ?? '',
      plateNumber: json['plate_number'] ?? '',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'no_unit': noUnit,
      'plate_number': plateNumber,
      'status': status,
    };
  }

  UnitTruckModel copyWith({
    int? id,
    String? noUnit,
    String? plateNumber,
    String? status,
  }) {
    return UnitTruckModel(
      id: id ?? this.id,
      noUnit: noUnit ?? this.noUnit,
      plateNumber: plateNumber ?? this.plateNumber,
      status: status ?? this.status,
    );
  }
}
