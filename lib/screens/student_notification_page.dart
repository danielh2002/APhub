import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aphub/screens/student_booking_page.dart';
import 'package:aphub/utils/app_colors.dart';
import 'package:aphub/roles/students.dart';
import 'package:aphub/screens/student_history_page.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:aphub/login_page.dart'; 
import 'package:aphub/models/student_notification_model.dart';

class StudentNotificationPage extends StatefulWidget {
  final String tpNumber;

  const StudentNotificationPage({super.key, required this.tpNumber});

  @override
  StudentNotificationPageState createState() => StudentNotificationPageState();
}

class StudentNotificationPageState extends State<StudentNotificationPage> {
  String selectedBookingStatus = 'All'; // Filter by booking status (bstatus)
  String selectedNotificationStatus = 'All'; // Filter by notification status (nstatus)

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut(); // Sign out the user

      // Navigate to the login page and remove all previous routes
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      debugPrint("Error during logout: $e");
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to log out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Image(
          image: AssetImage('assets/icons/MAE_APHUB_MENU_ICON.png'),
          width: 90,
        ),
        backgroundColor: AppColors.darkdarkgrey,
        actions: [
          IconButton(
            padding: const EdgeInsets.only(right: 15),
            onPressed: () {},
            icon: const Image(
              image: AssetImage('assets/icons/MAE_notification_icon.png'),
              width: 35,
            ),
          )
        ],
      ),
      backgroundColor: AppColors.black,
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildFilters(), // Add filter dropdowns and "Read All" button
          Expanded(child: _buildNotificationList()),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  /// 🔹 Mark All Notifications as Read
  Future<void> _markAllNotificationsAsRead() async {
    try {
      // Fetch all notifications for the current user
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: widget.tpNumber)
          .get();

      // Update each notification's status to "read"
      for (var doc in snapshot.docs) {
        await doc.reference.update({'nstatus': 'read'});
      }

      // Show a success message
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );

      // Refresh the UI
      setState(() {});
    } catch (e) {
      debugPrint("Error marking all notifications as read: $e");
      // Show an error message
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to mark notifications as read')),
      );
    }
  }

  /// 🔹 Filters for Notification List with "Read All" Button
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dropdown for Booking Status
          DropdownButton<String>(
            dropdownColor: AppColors.darkgrey,
            value: selectedBookingStatus,
            items: ['All', 'Scheduled', 'Completed', 'Pending', 'Cancelled']
                .map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(status, style: const TextStyle(color: AppColors.white)),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedBookingStatus = value!;
              });
            },
          ),

          // Dropdown for Notification Status
          DropdownButton<String>(
            dropdownColor: AppColors.darkgrey,
            value: selectedNotificationStatus,
            items: ['All', 'New', 'Read']
                .map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(status, style: const TextStyle(color: AppColors.white)),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedNotificationStatus = value!;
              });
            },
          ),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10), // Match the button's border radius
              boxShadow: [
                BoxShadow(
                  color: AppColors.lightgrey.withOpacity(0.3), // Glow color with opacity
                  blurRadius: 3, // Increase blur for a softer glow
                  spreadRadius: -0.1, // Increase spread for a wider glow
                  offset: const Offset(0, 0), // No offset for a centered glow
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _markAllNotificationsAsRead,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkdarkgrey, // Button color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Rounded corners
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 0, // Remove default elevation to avoid double shadow
              ),
              child: const Text(
                'Read All',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _markNotificationAsRead(DocumentReference docRef) async {
    try {
      debugPrint("Updating notification with ID: ${docRef.id}");
      await docRef.update({'nstatus': 'read'});
      debugPrint("Notification marked as read");
    } catch (e) {
      debugPrint("Error updating notification: $e");
    }
  }

Widget _buildNotificationList() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: widget.tpNumber)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        debugPrint("Error fetching notifications: ${snapshot.error}");
        return Center(
          child: Text(
            'Error: ${snapshot.error}',
            style: const TextStyle(color: AppColors.white),
          ),
        );
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        debugPrint("No notifications found for TP: ${widget.tpNumber}");
        return const Center(
          child: Text(
            'No notifications available',
            style: TextStyle(color: AppColors.white),
          ),
        );
      }

      // Convert Firestore documents to list of StudentNotificationModel
      var notifications = snapshot.data!.docs
          .map((doc) => StudentNotificationModel.fromFirestore(doc))
          .toList();

      // Apply filters
      var filteredNotifications = notifications.where((notification) {
        bool matchesBookingStatus = selectedBookingStatus == 'All' ||
            notification.bstatus.toLowerCase() == selectedBookingStatus.toLowerCase();
        bool matchesNotificationStatus = selectedNotificationStatus == 'All' ||
            notification.nstatus.toLowerCase() == selectedNotificationStatus.toLowerCase();
        return matchesBookingStatus && matchesNotificationStatus;
      }).toList();

      // Sort notifications: "new" notifications first, then "read" notifications
      filteredNotifications.sort((a, b) {
        if (a.nstatus == 'new' && b.nstatus != 'new') {
          return -1;
        } else if (a.nstatus != 'new' && b.nstatus == 'new') {
          return 1;
        } else {
          return 0;
        }
      });

      return ListView.builder(
        itemCount: filteredNotifications.length,
        itemBuilder: (context, index) {
          var notification = filteredNotifications[index];

          // Set opacity based on notification status
          double opacity = notification.nstatus == 'new' ? 0.8 : 0.4;

          // Determine color for booking status
          Color bookingStatusColor;
          switch (notification.bstatus.toLowerCase()) {
            case 'completed':
              bookingStatusColor = Colors.green;
              break;
            case 'scheduled':
              bookingStatusColor = Colors.orange;
              break;
            case 'pending':
              bookingStatusColor = Colors.yellow;
              break;
            case 'cancelled':
              bookingStatusColor = Colors.red;
              break;
            case 'ongoing':
              bookingStatusColor = Colors.green;
              break;
            default:
              bookingStatusColor = AppColors.white; // Default color
          }

          // Determine color for notification status
          Color notificationStatusColor =
              notification.nstatus == 'new' ? Colors.blue : AppColors.white;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkgrey.withOpacity(opacity),
                  blurRadius: 6,
                  spreadRadius: 0.5,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Card(
              color: AppColors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListTile(
                title: Text(
                  notification.venueName,
                  style: const TextStyle(
                      color: AppColors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${notification.date} | ${notification.startTime} - ${notification.endTime}',
                      style: const TextStyle(color: AppColors.white),
                    ),
                    Text(
                      'Booked Time: ${notification.bookedTime}',
                      style: const TextStyle(color: AppColors.white),
                    ),
                    Text(
                      'Booking Status: ${notification.bstatus}',
                      style: TextStyle(
                        color: bookingStatusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Notification Status: ${notification.nstatus}',
                      style: TextStyle(
                        color: notificationStatusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios,
                    color: AppColors.white, size: 18),
                onTap: () {
                  // Get the document reference using the document ID
                  DocumentReference docRef = FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(notification.id);

                  // Mark the notification as read
                  _markNotificationAsRead(docRef);

                  // Show the notification details
                  _showNotificationDetails(notification);
                },
              ),
            ),
          );
        },
      );
    },
  );
}

void _showNotificationDetails(StudentNotificationModel notification) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.darkdarkgrey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Rounded corners
        ),
        title: const Text(
          'Notification Details',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailCard('Venue', notification.venueName),
              const SizedBox(height: 10),
              _buildDetailCard('Date', notification.date),
              const SizedBox(height: 10),
              _buildDetailCard('Time', '${notification.startTime} - ${notification.endTime}'),
              const SizedBox(height: 10),
              _buildDetailCard('Booked Time', notification.bookedTime),
              const SizedBox(height: 10),
              _buildDetailCard('Message', notification.message), 
              const SizedBox(height: 10),
              _buildDetailCard('Notification Status', notification.nstatus),
              const SizedBox(height: 10),
              _buildDetailCard('Booking Status', notification.bstatus),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      );
    },
  );
}

  /// Helper to build a detail card
  Widget _buildDetailCard(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Bottom Navigation Bar
  Widget _buildBottomNavBar() {
    return BottomAppBar(
      color: AppColors.darkdarkgrey,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem('assets/icons/MAE_Calender_icon.png', 'Booking', () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => StudentBookingPage(tpNumber: widget.tpNumber)),
              );
            }),
            _buildNavItem('assets/icons/MAE_History_icon.png', 'History', () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => StudentHistoryPage(tpNumber: widget.tpNumber)),
              );
            }),
            _buildNavItem('assets/icons/MAE_Home_Icon.png', 'Home', () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => StudentPage(tpNumber: widget.tpNumber)),
              );
            }),
            _buildNavItem('assets/icons/MAE_logout_icon.png', 'Logout', () {_logout();}),
          ],
        ),
      ),
    );
  }

  /// 🔹 Helper for Bottom Navigation
  Widget _buildNavItem(String iconPath, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconPath, width: 24, height: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.white)),
        ],
      ),
    );
  }
}