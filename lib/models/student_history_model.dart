import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aphub/utils/app_colors.dart';

class StudentHistoryModel {
  static Widget buildPastBookingList(List<QueryDocumentSnapshot> pastBookings) {
    return SingleChildScrollView(
      child: Column(
        children: List.generate(pastBookings.length, (index) {
          final booking = pastBookings[index];
          final status = booking['status'] ?? 'unknown';
          final startTime = booking['startTime'] ?? 'N/A';
          final endTime = booking['endTime'] ?? 'N/A';
          final timeRange = '$startTime - $endTime';
          final venueName = booking['venueName'] ?? 'Unknown';
          final venueType = booking['venueType'] ?? 'Unknown';
          final date = booking['date'] ?? 'Unknown';

          // Determine status color
          Color statusColor;
          switch (status.toLowerCase()) {
            case 'completed':
              statusColor = Colors.green;
              break;
            case 'cancelled':
              statusColor = Colors.red;
              break;
            default:
              statusColor = AppColors.white;
          }

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkgrey.withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 0.5,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date: $date',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeRange,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Venue: $venueName',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Type: $venueType',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
