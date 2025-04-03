import 'dart:async';
import 'package:aphub/models/student_history_model.dart'; 
import 'package:aphub/screens/student_booking_page.dart';
import 'package:flutter/material.dart';
import 'package:aphub/utils/app_colors.dart';
import 'package:aphub/roles/students.dart';
import 'package:aphub/screens/student_notification_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:aphub/login_page.dart'; 
import 'package:aphub/models/student_booking_model.dart'; 
import 'package:aphub/models/student_updateschedule_model.dart';


class StudentHistoryPage extends StatefulWidget {
  final String tpNumber;

  const StudentHistoryPage({super.key, required this.tpNumber});

  @override
  StudentHistoryPageState createState() => StudentHistoryPageState();
}

class StudentHistoryPageState extends State<StudentHistoryPage> {
  String selectedFacility = 'All'; // Move to state
  String selectedStatus = 'All'; // Move to state
  late StudentUpdateScheduleModel _scheduleModel;

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

  void initState() {
    super.initState();
    _scheduleModel = StudentUpdateScheduleModel(tpNumber: widget.tpNumber); // ✅ Correct placement
    _scheduleModel.startCheckingBookingStatus(); // ✅ No error now
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
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StudentNotificationPage(tpNumber: widget.tpNumber),
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
      backgroundColor: AppColors.black,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildCurrentBooking(),
            const SizedBox(height: 20),
            _buildPastBooking(),
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
                    builder: (context) =>
                        StudentBookingPage(tpNumber: widget.tpNumber),
                  ),
                );
              }),
              _buildNavItem(
                'assets/icons/MAE_History_icon.png',
                'History',
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('You are already on the History page!')),
                  );
                },
              ),
              _buildNavItem('assets/icons/MAE_Home_Icon.png', 'Home', () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentPage(tpNumber: widget.tpNumber),
                  ),
                );
              }),
              _buildNavItem('assets/icons/MAE_logout_icon.png', 'Logout', () {_logout();}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentBooking() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.darkdarkgrey,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkdarkgrey.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Booking',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<String>(
                dropdownColor: AppColors.darkdarkgrey.withOpacity(0.7),
                value: selectedFacility,
                items: ['All', 'Lab', 'Meeting room', 'Classroom', 'Auditorium']
                    .map((facility) => DropdownMenuItem(
                          value: facility,
                          child: Text(
                            facility,
                            style: const TextStyle(color: AppColors.white),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedFacility = value!;
                  });
                },
              ),
              DropdownButton<String>(
                dropdownColor: AppColors.darkdarkgrey.withOpacity(0.7),
                value: selectedStatus,
                items: ['All', 'Pending', 'Scheduled', 'Ongoing']
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(
                            status,
                            style: const TextStyle(color: AppColors.white),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value!;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<StudentBookingModel>>(
            stream: StudentBookingModel.getFilteredBookings(
              widget.tpNumber,
              selectedFacility,
              selectedStatus,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildNoDataMessage('No bookings available');
              }

              final filteredList = snapshot.data!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Bookings: ${filteredList.length}',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final booking = filteredList[index];

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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: statusColor, width: 1),
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
                                if (booking.status.toLowerCase() == 'scheduled' ||
                                    booking.status.toLowerCase() == 'pending')
                                  IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.red),
                                    onPressed: () => _cancelBooking(booking),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

    Future<void> _cancelBooking(StudentBookingModel booking) async {
    try {
      await StudentBookingModel.cancelBooking(
        bookingId: booking.bookingId,
        venueName: booking.venueName,
        startTime: booking.startTime,
        endTime: booking.endTime,
        date: booking.date,
        venueType: booking.venueType,
        userId: widget.tpNumber,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel booking: $e')),
      );
    }
  }

Widget _buildPastBooking() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    margin: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      color: AppColors.darkdarkgrey,
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: AppColors.darkdarkgrey.withOpacity(0.3),
          blurRadius: 10,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Past Booking',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('TPbooking')
              .where('userId', isEqualTo: widget.tpNumber)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildNoDataMessage('No past bookings available');
            }

            final bookings = snapshot.data!.docs;

            // Apply filters locally
            final filteredBookings = bookings.where((booking) {
              final status = booking['status']?.toString().toLowerCase() ?? 'unknown';
              final venueType = booking['venueType']?.toString() ?? 'Unknown';

              bool matchesStatus = selectedStatus.toLowerCase() == 'all' ||
                  status == selectedStatus.toLowerCase();

              bool matchesFacility = selectedFacility == 'All' ||
                  venueType == selectedFacility;

              return matchesStatus && matchesFacility;
            }).toList();

            if (filteredBookings.isEmpty) {
              return _buildNoDataMessage('No past bookings match the selected filters');
            }

            // Filter past bookings with "Cancelled" or "Completed" status
            final pastBookings = filteredBookings.where((booking) {
              final status = booking['status']?.toString().toLowerCase() ?? 'unknown';
              return status == 'cancelled' || status == 'completed';
            }).toList();

            if (pastBookings.isEmpty) {
              return _buildNoDataMessage('No past bookings available');
            }

            // Use the helper function from StudentHistoryModel
            return StudentHistoryModel.buildPastBookingList(pastBookings);
          },
        ),
      ],
    ),
  );
}


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

  Widget _buildNoDataMessage(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 14,
        ),
      ),
    );
  }
}