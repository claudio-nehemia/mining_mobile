import 'package:flutter/foundation.dart';

class DriverMoneyModel {
  final int id;
  final int driverId;
  final double amount;

  DriverMoneyModel({
    required this.id,
    required this.driverId,
    required this.amount,
  });

  factory DriverMoneyModel.fromJson(Map<String, dynamic> json) {
    debugPrint('💰 Parsing DriverMoneyModel from JSON: $json');
    return DriverMoneyModel(
      id: json['id'],
      driverId: json['driver_id'],
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'amount': amount,
    };
  }
}
