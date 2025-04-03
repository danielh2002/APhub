import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String userId;
  final String name;
  final String venueName;
  final String venueType;
  final String date;
  final String startTime;
  final String endTime;
  final String status;
  final Timestamp bookedTime;
  final String detail;
  final String moduleName;  // New field

  Booking({
    required this.userId,
    required this.name,
    required this.venueName,
    required this.venueType,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.bookedTime,
    required this.detail,
    required this.moduleName,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'venueName': venueName,
      'venueType': venueType,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      'bookedtime': bookedTime,
      'detail': detail,
      'moduleName': moduleName,  // Store in Firestore
    };
  }
}
