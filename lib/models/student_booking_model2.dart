import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:aphub/screens/student_form_page.dart';
import 'package:aphub/utils/app_colors.dart';

class StudentBookingModel2 {
  Future<void> confirmBooking(
    BuildContext context,
    DocumentReference timeslotRef,
    String timeRange,
    String tpNumber,
  ) async {
    // Check if the student already has 5 or more active bookings
    final bookingQuery = await FirebaseFirestore.instance
        .collection('TPbooking')
        .where('userId', isEqualTo: tpNumber)
        .where('status', whereIn: ['ongoing', 'scheduled', 'pending'])
        .get();

    if (bookingQuery.docs.length >= 5) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have exceeded your booking limit: 5')),
        );
      }
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Confirm Booking',
            style: TextStyle(color: AppColors.white),
          ),
          backgroundColor: AppColors.darkdarkgrey,
          content: Text(
            'Are you sure you want to book the timeslot $timeRange?',
            style: const TextStyle(color: AppColors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirm', style: TextStyle(color: AppColors.white)),
            ),
          ],
        );
      },
    );

    // If user confirmed, proceed with booking
    if (confirmed == true) {
      try {
        // Get timeslot data
        final timeslotSnapshot = await timeslotRef.get();
        final timeslotData = timeslotSnapshot.data() as Map<String, dynamic>;

        // Fetch student name from `users` collection
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(tpNumber).get();
        if (!userDoc.exists) throw Exception('User not found');

        final studentName = userDoc['name'] ?? 'Unknown';

        if (timeslotData['venueType'] == "Auditorium") {
          // Navigate to StudentFormPage
          Navigator.push(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(
              builder: (context) => StudentFormPage(
                tpNumber: tpNumber,
                timeslotId: timeslotRef.id,
              ),
            ),
          );
        } else {
          // Normal booking process
          await timeslotRef.update({'status': 'scheduled'});

          await FirebaseFirestore.instance.collection('TPbooking').add({
            'date': timeslotData['date'],
            'endTime': timeslotData['endTime'],
            'startTime': timeslotData['startTime'],
            'status': 'scheduled',
            'venueName': timeslotData['venueName'],
            'venueType': timeslotData['venueType'],
            'userId': tpNumber,
            'name': studentName,
            'bookedtime': DateTime.now(),
          });

          await FirebaseFirestore.instance.collection('notifications').add({
            'date': timeslotData['date'],
            'bstatus': 'scheduled',
            'venueName': timeslotData['venueName'],
            'venueType': timeslotData['venueType'],
            'userId': tpNumber,
            'bookedtime': DateTime.now(),
            'message':
                'Your booking for "${timeslotData['venueName']}" has been scheduled for ${timeslotData['date']} from ${timeslotData['startTime']} to ${timeslotData['endTime']}.',
            'nstatus': 'new',
            'startTime': timeslotData['startTime'],
            'endTime': timeslotData['endTime'],
          });

          // Show success message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Booking successful!')),
            );
          }
        }
      } catch (e) {
        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}