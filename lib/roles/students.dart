import 'dart:async';
import 'package:flutter/material.dart';
import 'package:aphub/screens/student_notification_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aphub/screens/student_history_page.dart';
import 'package:aphub/utils/app_colors.dart';
import 'package:aphub/screens/student_booking_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aphub/login_page.dart';
import 'package:aphub/models/student_updateschedule_model.dart';
import 'package:aphub/models/student_schedulehome_model.dart';

class StudentPage extends StatefulWidget {
  final String tpNumber;
  const StudentPage({super.key, required this.tpNumber});
  
  @override
  StudentPageState createState() => StudentPageState();
}

class StudentPageState extends State<StudentPage> {
  late String name;
  late String tpNumber;
  late StudentUpdateScheduleModel _scheduleModel;
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  Timer? _userInteractionTimer;
  bool _isUserScrolling = false;

  @override
  void initState() {
    super.initState();
    tpNumber = widget.tpNumber;
    name = "Loading...";
    _fetchUserData();
    _scheduleModel = StudentUpdateScheduleModel(tpNumber: widget.tpNumber);
    _scheduleModel.startCheckingBookingStatus();
    
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
    _autoScrollTimer?.cancel();
    _userInteractionTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(tpNumber)
          .get();

      if (userDoc.exists) {
        String fetchedName = userDoc['name'] ?? "Unknown";

        if (mounted) {
          setState(() {
            name = fetchedName;
          });
        }
      } else {
        debugPrint("User document does not exist.");
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      debugPrint("Error during logout: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to log out. Please try again.')),
      );
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
          IconButton(
            padding: const EdgeInsets.only(right: 15),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StudentNotificationPage(tpNumber: tpNumber),
                ),
              );
            },
            icon: const Image(
              image: AssetImage('assets/icons/MAE_notification_icon.png'),
              width: 35,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Profile Section (your existing code)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.darkdarkgrey,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkgrey.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.white,
                          AppColors.lightgrey,
                          AppColors.darkgrey,
                          AppColors.black,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.black,
                      ),
                      child: const CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            AssetImage('assets/icons/MAE_PROFILEOG_ICON.png'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    tpNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.lightgrey,
                    ),
                  ),
                ],
              ),
            ),
            
            // Facilities Section with Auto-scroll
            _buildFacilityInfo(),
            
            const SizedBox(height: 20),
            
            // Schedule Section (your existing code)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'TODAY'),
                        Tab(text: 'UPCOMING'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildScheduleTab(isToday: true),
                          _buildScheduleTab(isToday: false),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: AppColors.darkdarkgrey,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem('assets/icons/MAE_Calender_icon.png', 'Booking', () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentBookingPage(tpNumber: tpNumber),
                  ),
                );
              }),
              _buildNavItem(
                'assets/icons/MAE_History_icon.png',
                'History',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          StudentHistoryPage(tpNumber: tpNumber),
                    ),
                  );
                },
              ),
              _buildNavItem('assets/icons/MAE_Home_Icon.png', 'Home', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('You are already on the Home page!')),
                );
              }),
              _buildNavItem('assets/icons/MAE_logout_icon.png', 'Logout', _logout),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildFacilityInfo() {
  final facilities = [
    {
      'name': 'Auditorium',
      'type': 'Auditorium',  
      'image': 'assets/icons/MAE_FACILITY_AUDI.png',
      'capacity': 'Capacity: 250',
      'equipment': ['Projector', 'Speaker', 'Mic'],
    },
    {
      'name': 'Classroom',
      'type': 'Classroom',
      'image': 'assets/icons/MAE_FACILITY_CLASSROOM.jpg',
      'capacity': 'Capacity: 35',
      'equipment': ['Projector', 'Whiteboard'],
    },
    {
      'name': 'Meeting Room',
      'type': 'Meeting room',  
      'image': 'assets/icons/MAE_FACILITY_MEETING.jpg',
      'capacity': 'Capacity: 6',
      'equipment': ['Projector', 'Whiteboard'],
    },
    {
      'name': 'Tech Lab',
      'type': 'Lab',
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
          'Facilities information',
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
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentBookingPage(
                        tpNumber: widget.tpNumber,
                        initialFacilityFilter: facility['type'] as String,
                      ),
                    ),
                  );
                },
                child: Container(
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
                ),
              );
            },
          ),
        ),
      ),
    ],
  );
}

  Widget _buildScheduleTab({required bool isToday}) {
    final today = DateTime.now().toLocal();
    final todayFormatted =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('TPbooking')
          .where('userId', isEqualTo: tpNumber)
          .where('status', whereIn: ['scheduled', 'ongoing', 'pending'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No ${isToday ? 'today\'s' : 'upcoming'} bookings available.',
              style: const TextStyle(color: AppColors.white),
            ),
          );
        }

        final bookings = snapshot.data!.docs
            .map((doc) => StudentScheduleHomeModel.fromFirestore(doc))
            .toList();

        final filteredBookings = bookings.where((booking) {
          return isToday ? booking.date == todayFormatted : booking.date != todayFormatted;
        }).toList();

        if (filteredBookings.isEmpty) {
          return Center(
            child: Text(
              'No ${isToday ? 'today\'s' : 'upcoming'} bookings available.',
              style: const TextStyle(color: AppColors.white),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredBookings.length,
          itemBuilder: (context, index) {
            final booking = filteredBookings[index];
            Color statusColor;
            switch (booking.status.toLowerCase()) {
              case 'scheduled':
                statusColor = Colors.orange;
                break;
              case 'ongoing':
                statusColor = Colors.green;
                break;
              case 'pending':
                statusColor = Colors.yellow;
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date: ${booking.date}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${booking.startTime} - ${booking.endTime}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Venue: ${booking.venueName}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Type: ${booking.venueType}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      booking.status,
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
          },
        );
      },
    );
  }

  Widget _buildNavItem(String iconPath, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconPath, width: 30, height: 30),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}