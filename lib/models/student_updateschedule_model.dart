import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';


class StudentUpdateScheduleModel {
  final String tpNumber;
  Timer? _timer;

  StudentUpdateScheduleModel({required this.tpNumber});

  /// Starts the periodic checking of booking statuses
  void startCheckingBookingStatus() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _checkAndUpdateBookingStatus();
    });
  }

  /// Stops the periodic checking to prevent memory leaks
  void stopCheckingBookingStatus() {
    _timer?.cancel();
  }

  /// Checks and updates booking statuses
  Future<void> _checkAndUpdateBookingStatus() async {
    final now = DateTime.now();
    final bookings = await FirebaseFirestore.instance
        .collection('TPbooking')
        .where('userId', isEqualTo: tpNumber)
        .get();

    for (final booking in bookings.docs) {
      final String startTime = booking['startTime'];
      final String endTime = booking['endTime'];
      final String date = booking['date'];
      final String status = booking['status'];
      final String venueName = booking['venueName'];
      final String venueType = booking['venueType'];

      final DateTime bookingDateTime = DateTime.parse('$date $startTime');
      final DateTime endDateTime = DateTime.parse('$date $endTime');

      if (status == 'scheduled' && now.isAfter(bookingDateTime)) {
        if (now.isBefore(endDateTime)) {
          // If booking is in the active window, mark it as ongoing
          await _updateBookingStatus(booking.id, 'ongoing', venueName, venueType, date, startTime, endTime);
        } else {
          // If booking has ended, mark it as completed
          await _updateBookingStatus(booking.id, 'completed', venueName, venueType, date, startTime, endTime);
        }
      } else if (status == 'ongoing' && now.isAfter(endDateTime)) {
        // If it was ongoing but has now ended, mark it as completed
        await _updateBookingStatus(booking.id, 'completed', venueName, venueType, date, startTime, endTime);
      }
    }
  }

  /// Updates booking status and sends a notification
  Future<void> _updateBookingStatus(
    String bookingId,
    String newStatus,
    String venueName,
    String venueType,
    String date,
    String startTime,
    String endTime,
  ) async {
    await FirebaseFirestore.instance.collection('TPbooking').doc(bookingId).update({'status': newStatus});

    await FirebaseFirestore.instance.collection('notifications').add({
      'date': date,
      'bstatus': newStatus,
      'venueName': venueName,
      'venueType': venueType,
      'userId': tpNumber,
      'bookedtime': DateTime.now(),
      'message': 'Your booking for "$venueName" on $date from $startTime to $endTime is now $newStatus.',
      'nstatus': 'new',
      'startTime': startTime,
      'endTime': endTime,
    });
  }
}
