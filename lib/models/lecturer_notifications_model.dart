import 'package:cloud_firestore/cloud_firestore.dart';

class LecturerNotification {
  final String id;
  final String userId;
  final String venueName;
  final String venueType;
  final String date;
  final String startTime;
  final String endTime;
  final String message;
  final String nstatus; // "new" or "read"
  final DateTime bookedTime;
  final String bstatus; // "scheduled", "cancelled", etc.

  LecturerNotification({
    required this.id,
    required this.userId,
    required this.venueName,
    required this.venueType,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.message,
    required this.nstatus,
    required this.bookedTime,
    required this.bstatus,
  });

  factory LecturerNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LecturerNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      venueName: data['venueName'] ?? '',
      venueType: data['venueType'] ?? '',
      date: data['date'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      message: data['message'] ?? '',
      nstatus: data['nstatus'] ?? 'new',
      bookedTime: (data['bookedtime'] as Timestamp).toDate(),
      bstatus: data['bstatus'] ?? 'scheduled',
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'venueName': venueName,
        'venueType': venueType,
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        'message': message,
        'nstatus': nstatus,
        'bookedtime': Timestamp.fromDate(bookedTime),
        'bstatus': bstatus,
      };
}