import 'package:aphub/models/lecturer_history_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';

class LecturerHistoryPage extends StatelessWidget {
  final String tpNumber;
  const LecturerHistoryPage({super.key, required this.tpNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Booking History",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.blue),
        backgroundColor: AppColors.darkdarkgrey,
      ),
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('TPbooking')
            .where('userId', isEqualTo: tpNumber)
            .where('status', isEqualTo: 'history')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No past bookings found.",
                style: TextStyle(color: AppColors.white),
              ),
            );
          }

          final bookings = snapshot.data!.docs
              .map((doc) => BookingHistory.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return _BookingHistoryCard(booking: booking);
            },
          );
        },
      ),
    );
  }
}

class _BookingHistoryCard extends StatelessWidget {
  final BookingHistory booking;
  const _BookingHistoryCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.darkgrey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(
          "Venue: ${booking.venueName}",
          style: const TextStyle(color: AppColors.white),
        ),
        subtitle: Text(
          "Date: ${booking.date}\nTime: ${booking.startTime} - ${booking.endTime}",
          style: const TextStyle(color: Colors.white70),
        ),
        leading: const Icon(Icons.history, color: Colors.white),
      ),
    );
  }
}
