import 'package:flutter/foundation.dart';
import 'driver_model.dart';
import 'unit_truck_model.dart';
import 'driver_money_model.dart';

class HomeDataModel {
  final DriverModel driver;
  final UnitTruckModel? truck;
  final DriverMoneyModel? saldo;

  HomeDataModel({
    required this.driver,
    this.truck,
    this.saldo,
  });

  factory HomeDataModel.fromJson(Map<String, dynamic> json) {
    debugPrint('🔧 Parsing HomeDataModel from JSON: $json');
    debugPrint('🚛 Truck data: ${json['truck']}');
    debugPrint('💰 Saldo data: ${json['saldo']}');
    
    return HomeDataModel(
      driver: DriverModel.fromJson(json['driver']),
      truck: json['truck'] != null ? UnitTruckModel.fromJson(json['truck']) : null,
      saldo: json['saldo'] != null ? DriverMoneyModel.fromJson(json['saldo']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driver': driver.toJson(),
      'truck': truck?.toJson(),
      'saldo': saldo?.toJson(),
    };
  }
}
