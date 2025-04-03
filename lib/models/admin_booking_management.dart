import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminBookingManagementModel {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get tpBookingsRef => firestore.collection("TPbooking");
  CollectionReference get tpFormRef => firestore.collection("TPform");

  // Fetch all bookings with optional status filter
  Query getAllBookingsQuery({String? statusFilter}) {
    Query query = tpBookingsRef;

    if (statusFilter != null && statusFilter != "All") {
      query = query.where("status", isEqualTo: statusFilter);
    }

    if (statusFilter == "All") {
      query = query.orderBy("date", descending: true);
    }

    return query;
  }

  // Fetch pending auditorium requests
  Query getPendingAuditoriumRequestsQuery() {
    return tpFormRef
        .where("venueType", isEqualTo: "Auditorium")
        .where("status", isEqualTo: "pending");
  }

  // Approve a request
  Future<void> approveRequest(String docId) async {
    try {
      DocumentSnapshot tpFormDoc = await tpFormRef.doc(docId).get();
      if (!tpFormDoc.exists) return;

      String tpBookingId = tpFormDoc["TPbookingId"];
      await tpFormRef.doc(docId).update({"status": "scheduled"});
      await tpBookingsRef.doc(tpBookingId).update({"status": "scheduled"});
    } catch (e) {
      rethrow;
    }
  }

  // Reject a request
  Future<void> rejectRequest(String docId, String reason) async {
    try {
      DocumentSnapshot tpFormDoc = await tpFormRef.doc(docId).get();
      if (!tpFormDoc.exists) return;

      String tpBookingId = tpFormDoc["TPbookingId"];
      await tpFormRef.doc(docId).update({
        "status": "cancelled",
        "rejectionReason": reason,
      });
      await tpBookingsRef.doc(tpBookingId).update({"status": "cancelled"});

      await _sendNotification(
        userId: tpFormDoc["userId"],
        venueName: tpFormDoc["venueName"],
        date: tpFormDoc["date"],
        startTime: tpFormDoc["startTime"],
        endTime: tpFormDoc["endTime"],
        reason: reason,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Send notification to user
  Future<void> _sendNotification({
    required String userId,
    required String venueName,
    required String date,
    required String startTime,
    required String endTime,
    required String reason,
  }) async {
    try {
      await firestore.collection("notifications").add({
        "userId": userId,
        "venueName": venueName,
        "date": date,
        "startTime": startTime,
        "endTime": endTime,
        "message":
            "Your booking for \"$venueName\" on $date from $startTime to $endTime has been cancelled. Reason: $reason",
        "nstatus": "unread",
        "bookedtime": DateTime.now(),
        "bstatus": "cancelled",
        "venueType": "Auditorium",
      });
    } catch (e) {
      rethrow;
    }
  }

  // Helper function to get status color
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "scheduled":
        return Colors.green;
      case "pending":
        return Colors.yellow;
      case "cancelled":
        return Colors.red;
      case "history":
        return Colors.orange;
      case "completed":
        return Colors.orange;
      case "ongoing":
        return Colors.green;
      default:
        return Colors.white;
    }
  }
}
