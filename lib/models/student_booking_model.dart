import 'package:cloud_firestore/cloud_firestore.dart';

class StudentBookingModel {
  final String userId;
  final String bookingId;
  final String status;
  final String startTime;
  final String endTime;
  final String venueName;
  final String venueType;
  final String date;

  StudentBookingModel({
    required this.userId,
    required this.bookingId,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.venueName,
    required this.venueType,
    required this.date,
  });

  // Factory method to create a StudentBookingModel from a Firestore document
  factory StudentBookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudentBookingModel(
      userId: data['userId'] ?? '',
      bookingId: doc.id,
      status: data['status'] ?? 'unknown',
      startTime: data['startTime'] ?? 'N/A',
      endTime: data['endTime'] ?? 'N/A',
      venueName: data['venueName'] ?? 'Unknown',
      venueType: data['venueType'] ?? 'Unknown',
      date: data['date'] ?? 'Unknown',
    );
  }

  // Convert the model to a Map (useful for Firestore operations)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'status': status,
      'startTime': startTime,
      'endTime': endTime,
      'venueName': venueName,
      'venueType': venueType,
      'date': date,
    };
  }

static Stream<List<StudentBookingModel>> getFilteredBookings(
    String userId, String selectedFacility, String selectedStatus) {
  return FirebaseFirestore.instance
      .collection('TPbooking')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => StudentBookingModel.fromFirestore(doc))
        .where((booking) {
          final isCancelled = booking.status.toLowerCase() == 'cancelled';
          if (isCancelled) return false; 

          final isCompleted = booking.status.toLowerCase() == 'completed';
          if (isCompleted) return false; 

          final matchesStatus = selectedStatus == 'All' ||
              booking.status.toLowerCase() == selectedStatus.toLowerCase();
          final matchesFacility = selectedFacility == 'All' ||
              booking.venueType == selectedFacility;

          return matchesStatus && matchesFacility;
        })
        .toList();
  });
}

  // Method to cancel a booking
  static Future<void> cancelBooking({
    required String bookingId,
    required String venueName,
    required String startTime,
    required String endTime,
    required String date,
    required String venueType,
    required String userId,
  }) async {
    try {
      // Step 1: Update the status in the TPbooking collection
      await FirebaseFirestore.instance
          .collection('TPbooking')
          .doc(bookingId)
          .update({'status': 'cancelled'});

      // Step 2: Update the status in the TPform collection where TPbookingId matches
      final tpFormQuery = await FirebaseFirestore.instance
          .collection('TPform')
          .where('TPbookingId', isEqualTo: bookingId)
          .get();

      for (final doc in tpFormQuery.docs) {
        await FirebaseFirestore.instance
            .collection('TPform')
            .doc(doc.id)
            .update({'status': 'cancelled'});
      }

      // Step 3: Update the timeslots collection from "scheduled" to "available"
      final timeslotQuery = await FirebaseFirestore.instance
          .collection('timeslots')
          .where('venueName', isEqualTo: venueName)
          .where('startTime', isEqualTo: startTime)
          .where('endTime', isEqualTo: endTime)
          .where('date', isEqualTo: date)
          .get();

      if (timeslotQuery.docs.isNotEmpty) {
        await timeslotQuery.docs.first.reference.update({'status': 'available'});
      }

      // Step 4: Add a notification to the 'notifications' collection
      await FirebaseFirestore.instance.collection('notifications').add({
        'date': date,
        'bstatus': 'cancelled',
        'venueName': venueName,
        'venueType': venueType,
        'userId': userId,
        'bookedtime': DateTime.now(),
        'message':
            'Your booking for "$venueName" on $date from $startTime to $endTime has been cancelled successfully.',
        'nstatus': 'new',
        'startTime': startTime,
        'endTime': endTime,
      });
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }
}