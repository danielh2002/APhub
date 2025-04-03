import 'dart:async';
import 'package:aphub/models/student_booking_model2.dart';
import 'package:flutter/material.dart';
import 'package:aphub/utils/app_colors.dart';
import 'package:aphub/roles/students.dart';
import 'package:aphub/screens/student_history_page.dart';
import 'package:aphub/screens/student_notification_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:aphub/login_page.dart';
import 'package:aphub/models/student_booking_model.dart'; 
import 'package:aphub/models/student_updateschedule_model.dart';


class StudentBookingPage extends StatefulWidget {
  final String tpNumber;
  final String? initialFacilityFilter;  // Add this parameter

  const StudentBookingPage({
    Key? key,
    required this.tpNumber,
    this.initialFacilityFilter,  // Make it optional
  }) : super(key: key);

  @override
  StudentBookingPageState createState() => StudentBookingPageState();
}

class StudentBookingPageState extends State<StudentBookingPage> {
  late StudentUpdateScheduleModel _scheduleModel;
  String selectedFacility = 'All';  // Will be initialized in initState
  String selectedBlock = 'All';
  String selectedFloor = 'All';
  String selectedStatus = 'All';
  String selectedDate = 'All';

  @override
  void initState() {
    super.initState();
    // Initialize with the passed filter or default to 'All'
    selectedFacility = widget.initialFacilityFilter ?? 'All';
    
    _scheduleModel = StudentUpdateScheduleModel(tpNumber: widget.tpNumber);
    _scheduleModel.startCheckingBookingStatus();
  }

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
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentNotificationPage(tpNumber: widget.tpNumber),
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
            _buildBooking(),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You are already on the Booking page!')),
                );
              }),
              _buildNavItem(
                'assets/icons/MAE_History_icon.png',
                'History',
                () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentHistoryPage(tpNumber: widget.tpNumber),
                    ),
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


Widget _buildBooking() {
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
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Header with Calendar and Reset
          Row(
            children: [
              const Text(
                'Available Facilities',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: Image.asset(
                  'assets/icons/MAE_Calender_icon.png',
                  width: 24,
                  height: 24,
                ),
                onPressed: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                    });
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.white),
                onPressed: () {
                  setState(() {
                    selectedDate = 'All';
                    selectedFacility = 'All';
                    selectedBlock = 'All';
                    selectedFloor = 'All';
                  });
                },
              ),
            ],
          ),
          
          // Selected Date Display
          if (selectedDate != 'All')
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Selected Date: $selectedDate',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                ),
              ),
            ),
          const SizedBox(height: 10),

          // Filter Dropdowns
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
                value: selectedBlock,
                items: ['All', 'A', 'B', 'C','D','E','F','G']
                    .map((block) => DropdownMenuItem(
                          value: block,
                          child: Text(
                            block == 'All' ? block : 'Block $block',
                            style: const TextStyle(color: AppColors.white),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedBlock = value!;
                  });
                },
              ),
              DropdownButton<String>(
                dropdownColor: AppColors.darkdarkgrey.withOpacity(0.7),
                value: selectedFloor,
                items: ['All', '1', '2', '3', '4', '5','6','7','8','9']
                    .map((floor) => DropdownMenuItem(
                          value: floor,
                          child: Text(
                            floor == 'All' ? floor : 'Floor $floor',
                            style: const TextStyle(color: AppColors.white),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedFloor = value!;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Timeslots List
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('timeslots')
                .where('status', isEqualTo: 'available')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildNoDataMessage('No available facilities');
              }

              // Apply filters
              final timeslots = snapshot.data!.docs.where((timeslot) {
                final venueType = timeslot['venueType'] ?? 'Classroom';
                final block = timeslot['block'];
                final level = timeslot['level'];
                final date = timeslot['date'];

                bool matchesVenueType = selectedFacility == 'All' || venueType == selectedFacility;
                bool matchesBlock = selectedBlock == 'All' || block == selectedBlock;
                bool matchesLevel = selectedFloor == 'All' || level == selectedFloor;
                bool matchesDate = selectedDate == 'All' || date == selectedDate;

                return matchesVenueType && matchesBlock && matchesLevel && matchesDate;
              }).toList();

              if (timeslots.isEmpty) {
                return _buildNoDataMessage('No available facilities matching the filters');
              }

              // Group by venueName
              final Map<String, List<QueryDocumentSnapshot>> groupedByVenue = {};
              for (final timeslot in timeslots) {
                final venueName = timeslot['venueName'];
                groupedByVenue.putIfAbsent(venueName, () => []).add(timeslot);
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groupedByVenue.keys.length,
                itemBuilder: (context, index) {
                  final venueName = groupedByVenue.keys.elementAt(index);
                  final venueTimeslots = groupedByVenue[venueName]!;
                  final venueType = venueTimeslots.first['venueType'] ?? 'Classroom';

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('venues').doc(venueName).get(),
                    builder: (context, venueSnapshot) {
                      if (!venueSnapshot.hasData || !venueSnapshot.data!.exists) {
                        return const SizedBox.shrink();
                      }

                      final venueData = venueSnapshot.data!;
                      final capacity = venueData['capacity'];
                      final equipment = venueData['equipment'];
                      final imagePath = _getVenueImagePath(venueType);

                      // Group timeslots by date
                      final Map<String, List<QueryDocumentSnapshot>> groupedByDate = {};
                      for (final timeslot in venueTimeslots) {
                        final date = timeslot['date'];
                        groupedByDate.putIfAbsent(date, () => []).add(timeslot);
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: groupedByDate.entries.map((entry) {
                          final date = entry.key;
                          final timeslotsForDate = entry.value;

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.darkgrey.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Large Image at the top
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: Image.asset(
                                    imagePath,
                                    width: double.infinity,
                                    height: 150,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 150,
                                        color: AppColors.darkgrey,
                                        child: Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                            color: AppColors.white,
                                            size: 40,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                
                                // Venue Info Container
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.black.withOpacity(0.7),
                                    borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(12),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            venueName,
                                            style: const TextStyle(
                                              color: AppColors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.info_outline, color: AppColors.white),
                                            onPressed: () {
                                              _showVenueInfoDialog(context, venueName, capacity, equipment);
                                            },
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 8),
                                      
                                      Text(
                                        'Date: $date',
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 12),
                                      
                                      Text(
                                        'Available Timeslots (${timeslotsForDate.length})',
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 12),
                                      
                                      // Timeslots Grid
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: timeslotsForDate.map((timeslot) {
                                          final startTime = timeslot['startTime'];
                                          final endTime = timeslot['endTime'];
                                          final timeRange = '$startTime - $endTime';

                                          return ElevatedButton(
                                            onPressed: () {
                                              _confirmBooking(context, timeslot.reference, timeRange, widget.tpNumber);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.darkgrey,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              timeRange,
                                              style: const TextStyle(
                                                color: AppColors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    ),
  );
}


// Helper function to get image path
String _getVenueImagePath(String venueType) {
  switch (venueType.toLowerCase()) {
    case 'auditorium':
      return 'assets/icons/MAE_FACILITY_AUDI.png';
    case 'meeting room':
    case 'meetingroom':
      return 'assets/icons/MAE_FACILITY_MEETING.jpg';
    case 'lab':
    case 'laboratory':
      return 'assets/icons/MAE_FACILITY_TECHLAB.png';
    case 'classroom':
    default:
      return 'assets/icons/MAE_FACILITY_CLASSROOM.jpg';
  }
}


  Widget _buildNoDataMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkgrey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.white),
      ),
    );
  }

void _confirmBooking(BuildContext context, DocumentReference timeslotRef, String timeRange, String tpNumber) {
  final bookingModel = StudentBookingModel2();
  bookingModel.confirmBooking(context, timeslotRef, timeRange, tpNumber);
}


  void _showVenueInfoDialog(BuildContext context, String venueName, int capacity, List<dynamic> equipment) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Venue Information: $venueName',
            style: const TextStyle(color: AppColors.white),
          ),
          backgroundColor: AppColors.darkdarkgrey,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Capacity: $capacity',
                style: const TextStyle(color: AppColors.white),
              ),
              const SizedBox(height: 10),
              const Text(
                'Equipment:',
                style: TextStyle(color: AppColors.white),
              ),
              ...equipment.map((item) {
                return Text(
                  '- $item',
                  style: const TextStyle(color: AppColors.white),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Close',
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ],
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
          Image.asset(iconPath, width: 24, height: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.white)),
        ],
      ),
    );
  }
}