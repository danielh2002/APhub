import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lecturer_notifications_model.dart';

class LecturerNotificationPage extends StatelessWidget {
  final String tpNumber;
  const LecturerNotificationPage({super.key, required this.tpNumber});

  Future<void> _markAllAsRead() async {
    final notifications = await FirebaseFirestore.instance
        .collection("notifications")
        .where("userId", isEqualTo: tpNumber)
        .where("nstatus", isEqualTo: "new")
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in notifications.docs) {
      batch.update(doc.reference, {"nstatus": "read"});
    }
    await batch.commit();
  }

  Future<void> _markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection("notifications")
        .doc(notificationId)
        .update({"nstatus": "read"});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Lecturer Notifications', style: TextStyle(fontSize: 18),),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text(
              "Mark All as Read",
              style: TextStyle(color: Colors.pink),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("notifications")
            .where("userId", isEqualTo: tpNumber)
            .orderBy("bookedtime", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.pink),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No notifications",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final notifications = snapshot.data!.docs
              .map((doc) => LecturerNotification.fromFirestore(doc))
              .toList();

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationCard(
                notification: notification,
                onTap: () => _markAsRead(notification.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final LecturerNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(
          notification.message,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          "${notification.date} | ${notification.startTime} - ${notification.endTime}",
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: notification.nstatus == "new"
            ? const Icon(Icons.notifications_active, color: Colors.pink)
            : null,
        onTap: onTap,
      ),
    );
  }
}
