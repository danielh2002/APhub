import 'package:aphub/models/lecturer_booking_model.dart';
import 'package:aphub/models/lecturer_timeslot_model.dart';
import 'package:aphub/models/lecturer_user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Timeslot methods
  Stream<List<Timeslot>> getAvailableTimeslots() {
    return _firestore
        .collection("timeslots")
        .where("status", isEqualTo: "available")
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Timeslot.fromFirestore(doc)).toList());
  }

  Future<void> updateTimeslotStatus(String timeslotId, String status) async {
    await _firestore.collection("timeslots").doc(timeslotId).update({
      "status": status,
    });
  }

  // User methods
  Future<User> getUser(String tpNumber) async {
    final doc = await _firestore.collection("users").doc(tpNumber).get();
    if (!doc.exists) {
      throw Exception("User not found");
    }
    return User.fromFirestore(doc);
  }

  // Booking methods
  Future<void> createBooking(Booking booking) async {
    await _firestore.collection("TPbooking").add(booking.toMap());
  }

  Future<void> createNotification({
    required String userId,
    required String venueName,
    required String venueType,
    required String date,
    required String startTime,
    required String endTime,
    required String message,
  }) async {
    await _firestore.collection("notifications").add({
      'userId': userId,
      'venueName': venueName,
      'venueType': venueType,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'bookedtime': Timestamp.now(),
      'bstatus': 'scheduled',
      'message': message,
      'nstatus': 'new',
    });
  }
}