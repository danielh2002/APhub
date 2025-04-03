import 'package:cloud_firestore/cloud_firestore.dart';

class BookingHistory {
  final String id;
  final String userId;
  final String venueName;
  final String venueType;
  final String date;
  final String startTime;
  final String endTime;
  final String status; // "history", "cancelled", etc.
  final DateTime bookedTime;
  final String detail; // Purpose (module/event)

  BookingHistory({
    required this.id,
    required this.userId,
    required this.venueName,
    required this.venueType,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.bookedTime,
    required this.detail,
  });

  factory BookingHistory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingHistory(
      id: doc.id,
      userId: data['userId'] ?? '',
      venueName: data['venueName'] ?? '',
      venueType: data['venueType'] ?? '',
      date: data['date'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      status: data['status'] ?? 'history',
      bookedTime: (data['bookedtime'] as Timestamp).toDate(),
      detail: data['detail'] ?? '',
    );
  }
}