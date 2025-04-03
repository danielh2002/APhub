import 'package:cloud_firestore/cloud_firestore.dart';

class StudentScheduleHomeModel {
  final String id;
  final String date;
  final String startTime;
  final String endTime;
  final String venueName;
  final String venueType;
  final String status;

  StudentScheduleHomeModel({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.venueName,
    required this.venueType,
    required this.status,
  });

  // Factory method to create an instance from Firestore document
  factory StudentScheduleHomeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudentScheduleHomeModel(
      id: doc.id,
      date: data['date'] ?? 'Unknown Date',
      startTime: data['startTime'] ?? 'N/A',
      endTime: data['endTime'] ?? 'N/A',
      venueName: data['venueName'] ?? 'Unknown Venue',
      venueType: data['venueType'] ?? 'Unknown',
      status: data['status'] ?? 'unknown',
    );
  }
}
