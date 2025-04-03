import 'package:cloud_firestore/cloud_firestore.dart';

class Timeslot {
  final String id;
  final String venueName;
  final String venueType;
  final String date;
  final String startTime;
  final String endTime;
  final int capacity;
  final List<String> equipment;
  final String status;

  Timeslot({
    required this.id,
    required this.venueName,
    required this.venueType,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.equipment,
    required this.status,
  });

  factory Timeslot.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Timeslot(
      id: doc.id,
      venueName: data['venueName'] ?? 'Unnamed Venue',
      venueType: data['venueType'] ?? 'N/A',
      date: data['date'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      capacity: data['capacity'] ?? 0,
      equipment: List<String>.from(data['equipment'] ?? []),
      status: data['status'] ?? 'available',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'venueName': venueName,
      'venueType': venueType,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'capacity': capacity,
      'equipment': equipment,
      'status': status,
    };
  }
}