import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentFormModel {
  final GlobalKey<FormState> formKey;
  final TextEditingController eventNameController;
  final TextEditingController eventTypeController;
  final TextEditingController estPersonController;
  final String tpNumber;
  final String timeslotId;
  final Map<String, dynamic>? timeslotData;
  final BuildContext context;

  StudentFormModel({
    required this.formKey,
    required this.eventNameController,
    required this.eventTypeController,
    required this.estPersonController,
    required this.tpNumber,
    required this.timeslotId,
    required this.timeslotData,
    required this.context,
  });

  Future<void> submitBooking() async {
    if (!formKey.currentState!.validate()) return;

    try {
      if (timeslotData == null) {
        throw Exception("Timeslot data is null.");
      }

      // Fetch the student name from the `users` collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(tpNumber)
          .get();

      if (!userDoc.exists) {
        throw Exception("User not found in the users collection.");
      }

      final studentName = userDoc['name'] ?? 'Unknown';

      // Validate estPerson input
      final estPerson = int.tryParse(estPersonController.text);
      if (estPerson == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid number for estimated persons.")),
        );
        return;
      }

      // Update timeslot status
      DocumentReference timeslotRef =
          FirebaseFirestore.instance.collection('timeslots').doc(timeslotId);
      await timeslotRef.update({'status': 'pending'});

      // Store booking information
      DocumentReference tpBookingRef =
          await FirebaseFirestore.instance.collection('TPbooking').add({
        'userId': tpNumber,
        'name': studentName,
        'date': timeslotData?['date'],
        'startTime': timeslotData?['startTime'],
        'endTime': timeslotData?['endTime'],
        'status': 'pending',
        'venueName': timeslotData?['venueName'],
        'venueType': timeslotData?['venueType'],
        'bookedtime': DateTime.now(),
      });

      String tpBookingId = tpBookingRef.id;

      await FirebaseFirestore.instance.collection('TPform').add({
        'userId': tpNumber,
        'name': studentName,
        'eventname': eventNameController.text,
        'eventtype': eventTypeController.text,
        'estperson': estPerson,
        'capacity': timeslotData?['capacity'],
        'date': timeslotData?['date'],
        'startTime': timeslotData?['startTime'],
        'endTime': timeslotData?['endTime'],
        'status': 'pending',
        'venueName': timeslotData?['venueName'],
        'venueType': timeslotData?['venueType'],
        'bookedtime': DateTime.now(),
        'TPbookingId': tpBookingId,
      });

      // Send notification
      await FirebaseFirestore.instance.collection('notifications').add({
        'date': timeslotData?['date'],
        'bstatus': 'pending',
        'venueName': timeslotData?['venueName'],
        'venueType': timeslotData?['venueType'],
        'userId': tpNumber,
        'bookedtime': DateTime.now(),
        'message':
            'Your booking for "${timeslotData?['venueName']}" is pending approval. Your booking is on ${timeslotData?['date']} from ${timeslotData?['startTime']} to ${timeslotData?['endTime']}.',
        'nstatus': 'new',
        'startTime': timeslotData?['startTime'],
        'endTime': timeslotData?['endTime'],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Booking Submitted Successfully!")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}