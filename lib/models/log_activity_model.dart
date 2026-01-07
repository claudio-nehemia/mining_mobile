import 'package:flutter/foundation.dart';

class LogActivityModel {
  final int id;
  final String checkpointName;
  final String status;
  final String? lastActivity;
  final String checkIn;
  final String? checkOut;
  final String? duration;
  final String time;

  LogActivityModel({
    required this.id,
    required this.checkpointName,
    required this.status,
    this.lastActivity,
    required this.checkIn,
    this.checkOut,
    this.duration,
    required this.time,
  });

  factory LogActivityModel.fromJson(Map<String, dynamic> json) {
    debugPrint('📜 Parsing LogActivityModel: ${json['checkpoint_name']}');
    
    // Parse ISO timestamp and convert to local timezone
    String displayTime = json['time'];
    try {
      final utcTime = DateTime.parse(json['time']);
      final localTime = utcTime.toLocal();
      displayTime = '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      debugPrint('⚠️ Failed to parse time: $e');
    }
    
    // Parse check_out timestamp to local timezone
    String? displayCheckOut;
    if (json['check_out'] != null) {
      try {
        final utcCheckOut = DateTime.parse(json['check_out']);
        final localCheckOut = utcCheckOut.toLocal();
        displayCheckOut = '${localCheckOut.hour.toString().padLeft(2, '0')}:${localCheckOut.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        debugPrint('⚠️ Failed to parse check_out: $e');
        displayCheckOut = json['check_out'];
      }
    }
    
    return LogActivityModel(
      id: json['id'],
      checkpointName: json['checkpoint_name'],
      status: json['status'],
      lastActivity: json['last_activity'],
      checkIn: json['check_in'],
      checkOut: displayCheckOut,
      duration: json['duration'],
      time: displayTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'checkpoint_name': checkpointName,
      'status': status,
      'last_activity': lastActivity,
      'check_in': checkIn,
      'check_out': checkOut,
      'duration': duration,
      'time': time,
    };
  }
}
