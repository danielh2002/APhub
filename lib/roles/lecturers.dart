import 'dart:async';
import 'package:aphub/login_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aphub/utils/app_colors.dart';
import 'package:aphub/screens/lecturer_booking_page.dart';
import 'package:aphub/screens/lecturer_faq_page.dart';
import 'package:aphub/screens/lecturer_history_page.dart';
import 'package:aphub/screens/lecturer_notification_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LecturerPage extends StatefulWidget {
  final String tpNumber;
  const LecturerPage({super.key, required this.tpNumber});

  @override
  LecturerPageState createState() => LecturerPageState();
}

class LecturerPageState extends State<LecturerPage> {
  late String name;
  late String tpNumber;
  Timer? _autoUpdateTimer;
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  Timer? _userInteractionTimer;
  bool _isUserScrolling = false;

  @override
  void initState() {
    super.initState();
    tpNumber = widget.tpNumber;
    name = "Loading...";
    _fetchLecturerData();
    _updateBookingStates();
    _autoUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _updateBookingStates();
      } else {
        timer.cancel(); // Stop timer when widget is removed
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    const scrollDuration = Duration(seconds: 15);
    const pauseDuration = Duration(seconds: 2);

    Future<void> scroll(bool toRight) async {
      if (!_scrollController.hasClients || !mounted || _isUserScrolling) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final double target = toRight ? maxScroll : 0.0;

      await _scrollController.animateTo(
        target,
        duration: scrollDuration,
        curve: Curves.linear,
      );

      await Future.delayed(pauseDuration);

      if (mounted) scroll(!toRight);
    }

    _autoScrollTimer?.cancel();
    scroll(true);
  }

  void _handleUserInteraction() {
    if (!_isUserScrolling) {
      setState(() {
        _isUserScrolling = true;
      });
    }

    _userInteractionTimer?.cancel();
    _userInteractionTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isUserScrolling = false;
        });
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _autoUpdateTimer?.cancel(); // Prevent memory leaks
    _autoScrollTimer?.cancel();
    _userInteractionTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchLecturerData() async {
    try {
      DocumentSnapshot lecturerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(tpNumber)
          .get();

      if (lecturerDoc.exists) {
        Map<String, dynamic> lecturerData =
            lecturerDoc.data() as Map<String, dynamic>;

        if (mounted) {
          setState(() {
            name = lecturerData['name'] ?? "Unknown";
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching lecturer data: $e");
    }
  }

  void _updateBookingStates() async {
    QuerySnapshot bookingsSnapshot = await FirebaseFirestore.instance
        .collection('TPbooking')
        .where('status', whereIn: ['scheduled', 'ongoing'])
        .where('userId', isEqualTo: tpNumber)
        .get();

    for (var bookingDoc in bookingsSnapshot.docs) {
      var bookingData = bookingDoc.data() as Map<String, dynamic>;

      // Use the actual booking date
      String bookingDate = bookingData['date'];
      DateTime startTime =
          DateTime.parse("$bookingDate ${bookingData['startTime']}:00");
      DateTime endTime =
          DateTime.parse("$bookingDate ${bookingData['endTime']}:00");

      // Get current local time
      DateTime now = DateTime.now().toLocal();

      print("Now: $now, Start: $startTime, End: $endTime");

      // Update status only if it needs to change
      if (bookingData['status'] != 'history' && now.isAfter(endTime)) {
        await FirebaseFirestore.instance
            .collection('TPbooking')
            .doc(bookingDoc.id)
            .update({'status': 'history'});

        print("Updated ${bookingData['venueName']} to completed.");
      } else if (bookingData['status'] == 'scheduled' &&
          now.isAfter(startTime) &&
          now.isBefore(endTime)) {
        await FirebaseFirestore.instance
            .collection('TPbooking')
            .doc(bookingDoc.id)
            .update({'status': 'ongoing'});

        print("Updated ${bookingData['venueName']} to ongoing.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Image(
          image: AssetImage('assets/icons/MAE_APHUB_MENU_ICON.png'),
          width: 90,
        ),
        backgroundColor: AppColors.darkdarkgrey,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: tpNumber)
                .where('nstatus', isEqualTo: 'new')
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                unreadCount = snapshot.data!.docs.length;
              }

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: AppColors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LecturerNotificationPage(tpNumber: tpNumber),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: -3,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            _buildProfileSection(),
            const SizedBox(height: 20),
            // Add the new facility slideshow section
            _buildFacilityInfo(),
            const SizedBox(height: 20),
            _buildUpcomingBooking(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // Add this new method for the facility slideshow
  Widget _buildFacilityInfo() {
    final facilities = [
      {
        'name': 'Auditorium',
        'image': 'assets/icons/MAE_FACILITY_AUDI.png',
        'capacity': 'Capacity: 250',
        'equipment': ['Projector', 'Speaker', 'Mic'],
      },
      {
        'name': 'Classroom',
        'image': 'assets/icons/MAE_FACILITY_CLASSROOM.jpg',
        'capacity': 'Capacity: 35',
        'equipment': ['Projector', 'Whiteboard'],
      },
      {
        'name': 'Meeting Room',
        'image': 'assets/icons/MAE_FACILITY_MEETING.jpg',
        'capacity': 'Capacity: 6',
        'equipment': ['Projector', 'Whiteboard'],
      },
      {
        'name': 'Tech Lab',
        'image': 'assets/icons/MAE_FACILITY_TECHLAB.png',
        'capacity': 'Capacity: 25',
        'equipment': ['Computers', 'Projector', 'Whiteboard'],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Text(
            'Facilities Information',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 300,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification || 
                  notification is ScrollUpdateNotification) {
                _handleUserInteraction();
              }
              return false;
            },
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: facilities.length,
              itemBuilder: (context, index) {
                final facility = facilities[index];
                return Container(
                  width: 240,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: AppColors.darkdarkgrey,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: Image.asset(
                          facility['image'] as String,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              facility['name'] as String,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              facility['capacity'] as String,
                              style: const TextStyle(
                                color: AppColors.lightgrey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...(facility['equipment'] as List<String>)
                                .map((item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '• $item',
                                        style: const TextStyle(
                                          color: AppColors.lightgrey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.darkdarkgrey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/icons/lecturer_default.png',
            width: 100,
            height: 100,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.person, size: 35, color: Colors.white);
            },
          ),
          const SizedBox(height: 16),
          Text(name,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white)),
          Text(tpNumber,
              style: const TextStyle(fontSize: 16, color: AppColors.lightgrey)),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      color: AppColors.darkdarkgrey,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
                Icons.calendar_today,
                'Bookings',
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            LecturerBookingPage(tpNumber: tpNumber)))),
            _buildNavItem(
                Icons.history,
                'History',
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            LecturerHistoryPage(tpNumber: tpNumber)))),
            _buildNavItem(
                Icons.question_answer,
                'FAQ',
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            LecturerFaqPage(tpNumber: tpNumber)))),
            _buildNavItem(Icons.logout, 'Logout', () async {
              try {
                await FirebaseAuth.instance.signOut(); // Firebase sign out
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              } catch (e) {
                debugPrint("Sign-out error: $e");
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingBooking() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.darkdarkgrey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Bookings',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.white),
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('TPbooking')
                .where('userId', isEqualTo: tpNumber)
                .where('status', whereIn: ['scheduled', 'ongoing']).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text(
                  'No upcoming bookings available.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.white),
                );
              }
              List<QueryDocumentSnapshot> bookings = snapshot.data!.docs;
              return Column(
                children: bookings.map((booking) {
                  Map<String, dynamic> data =
                      booking.data() as Map<String, dynamic>;

                  // Define status color
                  Color statusColor = Colors.white;
                  if (data['status'] == 'scheduled')
                    statusColor = Colors.green;
                  else if (data['status'] == 'ongoing')
                    statusColor = Colors.orange;

                  return Card(
                    color: AppColors.darkgrey.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      title: Text(
                        data['venueName'] ?? 'Unknown Venue',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Date: ${data['date']}",
                              style: const TextStyle(color: AppColors.white)),
                          Text(
                              "Time: ${data['startTime']} - ${data['endTime']}",
                              style: const TextStyle(color: AppColors.white)),
                          Text(
                            "Status: ${data['status']}",
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      trailing: data['status'] == 'ongoing'
                          ? null // Hide cancel button for ongoing bookings
                          : TextButton(
                              onPressed: () => _showCancelConfirmation(
                                context,
                                booking.id,
                                data['venueName'],
                                data['startTime'],
                                data['date'],
                                data['endTime'],
                              ),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context, String bookingId,
      String venueName, String startTime, String date, String endTime) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Booking"),
        content: const Text("Are you sure you want to cancel this booking?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close dialog
            child: const Text("No", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _cancelBooking(
                  bookingId, venueName, startTime, date, endTime);
            },
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking(String bookingId, String venueName,
      String startTime, String date, String endTime) async {
    try {
      debugPrint(
          "Attempting to cancel booking ID: $bookingId for venue: $venueName on $date at $startTime");

      // Fetch the specific timeslot matching venueName, date, and startTime
      QuerySnapshot timeslotQuery = await FirebaseFirestore.instance
          .collection('timeslots')
          .where('venueName', isEqualTo: venueName)
          .where('date', isEqualTo: date) // Ensures correct date
          .where('startTime', isEqualTo: startTime)
          .where('endTime', isEqualTo: endTime)
          .limit(1) // Ensures only one matching document is retrieved
          .get();

      if (timeslotQuery.docs.isEmpty) {
        debugPrint(
            "Error: No matching timeslot found for venue $venueName on $date at $startTime.");
        return;
      }

      // Get the correct timeslot document ID
      String timeslotId = timeslotQuery.docs.first.id;

      // Update the timeslot status back to 'available'
      await FirebaseFirestore.instance
          .collection('timeslots')
          .doc(timeslotId)
          .update({
        'status': 'available',
      });

      debugPrint("Timeslot status updated to available for ID: $timeslotId");

      // Delete the booking from 'bookings' collection
      await FirebaseFirestore.instance
          .collection('TPbooking')
          .doc(bookingId)
          .delete();

      debugPrint("Booking deleted successfully.");

      // Add a notification for the canceled booking
      await FirebaseFirestore.instance.collection("notifications").add({
        "userId": tpNumber, // Lecturer's ID
        "venueName": venueName,
        "date": date,
        "startTime": startTime,
        "endTime": endTime,
        "bookedtime": Timestamp.now(),
        "bstatus": "canceled",
        "message":
            "Your booking for $venueName on $date at $startTime has been canceled.",
        "nstatus": "new",
      });
    } catch (e) {
      debugPrint("Error cancelling booking: $e");
    }
  }

  // Bottom nav
  Widget _buildNavItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
