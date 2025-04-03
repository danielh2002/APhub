import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../login_page.dart';
import '../utils/app_colors.dart';
import '../screens/admin_account_management.dart';
import '../screens/admin_booking_management.dart';
import '../screens/admin_module_management.dart';
import '../screens/admin_timetable_management.dart';
import '../screens/admin_venues_management.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final PageController _pageController = PageController();
  Timer? _timer;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _startAutoSwiping();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSwiping() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.page == 2) {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.darkdarkgrey,
        title: const Text('Admin Dashboard',
            style: TextStyle(color: AppColors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.white),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Auto-Swiping Section
              _buildOverviewSection(),
              const SizedBox(height: 20),
              // Venues Utilization Section
              _buildVenueUtilizationSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  // Overview Section
  Widget _buildOverviewSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.darkdarkgrey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Overview'),
          const SizedBox(height: 10),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.35,
            child: PageView(
              controller: _pageController,
              children: [
                _buildUpcomingBookings(),
                _buildVenues(),
                _buildModules(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Venues Utilization Section
  Widget _buildVenueUtilizationSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.darkdarkgrey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Venues Utilization'),
          _buildVenueUtilization(),
        ],
      ),
    );
  }

  // Bottom Navigation Bar
  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomAppBar(
      color: AppColors.darkdarkgrey,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavButton(
                context, Icons.business, 'Venues', const VenuesManagement()),
            _buildNavButton(context, Icons.meeting_room, 'Modules',
                const ModuleManagement()),
            _buildNavButton(context, Icons.calendar_today, 'Timetables',
                const TimeSlotManagement()),
            _buildNavButton(context, Icons.book, 'Bookings',
                const AdminBookingManagement()),
            _buildNavButton(context, Icons.account_circle, 'Accounts',
                const AccountManagement()),
          ],
        ),
      ),
    );
  }

  // Upcoming Bookings Section
  Widget _buildUpcomingBookings() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('TPbooking')
          .orderBy('date', descending: false) // Sort by date
          .limit(3) // Limit to 3 bookings
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var bookings = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upcoming Bookings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                var booking = bookings[index];
                return _buildBookingItem(
                  booking['venueName'],
                  'Date: ${booking['date']}',
                  'Time: ${booking['startTime']} - ${booking['endTime']}',
                  'Name: ${booking['name']}',
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Venues Section
  Widget _buildVenues() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('venues').limit(3).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var venues = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Venues',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white)),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: venues.length,
              itemBuilder: (context, index) {
                var venue = venues[index];
                return _buildVenueItem(
                  venue['name'],
                  'Block: ${venue['block']}',
                  'Capacity: ${venue['capacity']}',
                  'Status: ${venue['status']}',
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Modules Section
  Widget _buildModules() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('modules').limit(3).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var modules = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Modules',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white)),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: modules.length,
              itemBuilder: (context, index) {
                var module = modules[index];
                return _buildModuleItem(
                  module['moduleName'],
                  'Lecturer: ${module['lecturerName']}',
                  'Duration: ${module['duration']}',
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Venue Utilization
  Widget _buildVenueUtilization() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('venues').snapshots(),
      builder: (context, venueSnapshot) {
        if (venueSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (venueSnapshot.hasError) {
          return Center(child: Text('Error: ${venueSnapshot.error}'));
        }

        int totalVenues = venueSnapshot.data!.docs.length;
        int totalSlots = totalVenues * 19; // Assuming 19 slots per venue

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('TPbooking').snapshots(),
          builder: (context, bookingSnapshot) {
            if (bookingSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (bookingSnapshot.hasError) {
              return Center(child: Text('Error: ${bookingSnapshot.error}'));
            }

            int bookedSlots = bookingSnapshot.data!.docs.length;
            int availableSlots = totalSlots - bookedSlots;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Booked Time Slots',
                      bookedSlots.toString(),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildStatCard(
                      'Available Time Slots',
                      availableSlots.toString(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Booking Item
  Widget _buildBookingItem(
      String venue, String date, String time, String user) {
    return ListTile(
      leading: const Icon(Icons.event, color: AppColors.lightgrey),
      title: Text(venue,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          )),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(date, style: const TextStyle(color: AppColors.lightgrey)),
          Text(time, style: const TextStyle(color: AppColors.lightgrey)),
          Text(user, style: const TextStyle(color: AppColors.lightgrey)),
        ],
      ),
    );
  }

  // Venue Item
  Widget _buildVenueItem(
      String name, String block, String capacity, String status) {
    return ListTile(
      leading: const Icon(Icons.business, color: AppColors.lightgrey),
      title: Text(name,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.white)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(block, style: const TextStyle(color: AppColors.lightgrey)),
          Text(capacity, style: const TextStyle(color: AppColors.lightgrey)),
          Text(status, style: const TextStyle(color: AppColors.lightgrey)),
        ],
      ),
    );
  }

  // Module Item
  Widget _buildModuleItem(String name, String lecturer, String durations) {
    return ListTile(
      leading: const Icon(Icons.meeting_room, color: AppColors.lightgrey),
      title: Text(name,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.white)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lecturer, style: const TextStyle(color: AppColors.lightgrey)),
          Text(durations, style: const TextStyle(color: AppColors.lightgrey)),
        ],
      ),
    );
  }

  // Navigation Button
  Widget _buildNavButton(
      BuildContext context, IconData icon, String label, Widget page) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => page));
        },
        child: SizedBox(
          height: 60,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.white, size: 24),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(color: AppColors.white, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  // Section Header
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.white),
    );
  }

  // Stat Card
  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkgrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.white),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: AppColors.white),
          ),
        ],
      ),
    );
  }
}
