import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StudentNotificationModel {
  final String id;
  final String venueName;
  final String date;
  final String startTime;
  final String endTime;
  final String bookedTime;
  final String nstatus;
  final String bstatus;
  final String message;

  StudentNotificationModel({
    required this.id,
    required this.venueName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.bookedTime,
    required this.nstatus,
    required this.bstatus,
    required this.message,
  });

  /// Factory method to create a `StudentNotificationModel` from Firestore
  factory StudentNotificationModel.fromFirestore(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    return StudentNotificationModel(
      id: doc.id,
      venueName: data['venueName'] as String? ?? 'Unknown Venue',
      date: data['date'] as String? ?? 'Unknown Date',
      startTime: data['startTime'] as String? ?? 'N/A',
      endTime: data['endTime'] as String? ?? 'N/A',
      bookedTime: data['bookedtime'] != null
          ? _formatTimestamp(data['bookedtime'] as Timestamp)
          : 'Unknown Time',
      nstatus: data['nstatus'] as String? ?? 'Unknown',
      bstatus: data['bstatus'] as String? ?? 'Unknown',
      message: data['message'] ?? 'No message',
    );
  }

  /// Converts a Firestore Timestamp to a readable string format
  static String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  /// Converts a raw date string to a readable format (YYYY-MM-DD)
  static String formatDate(String rawDate) {
    try {
      DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(rawDate);
      return DateFormat('EEEE, MMM dd, yyyy').format(parsedDate);
    } catch (e) {
      return 'Invalid Date';
    }
  }
}
