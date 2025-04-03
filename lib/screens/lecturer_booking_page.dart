import 'package:aphub/models/lecturer_booking_model.dart';
import 'package:aphub/models/lecturer_repository_model.dart';
import 'package:aphub/models/lecturer_timeslot_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class LecturerBookingPage extends StatefulWidget {
  final String tpNumber;

  const LecturerBookingPage({super.key, required this.tpNumber});

  @override
  LecturerBookingPageState createState() => LecturerBookingPageState();
}

class LecturerBookingPageState extends State<LecturerBookingPage> {
  final BookingRepository _repository = BookingRepository();
  String _searchQuery = "";
  String _selectedVenueType = "All";
  String? _selectedDate;

  Future<List<String>> _getLecturerModules() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('modules')
        .where('lecturerId', isEqualTo: widget.tpNumber)
        .get();

    List<String> moduleNames =
        querySnapshot.docs.map((doc) => doc['moduleName'] as String).toList();
    return moduleNames;
  }

  Future<String?> _showPurposeDialog(List<String> modules) async {
    String? selectedPurpose;
    TextEditingController eventController = TextEditingController();
    bool showEventField = false;

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Purpose"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedPurpose,
                    isExpanded: true,
                    hint: const Text("Choose a purpose"),
                    items: [
                      ...modules.map((module) => DropdownMenuItem(
                            value: module,
                            child: Text(module),
                          )),
                      const DropdownMenuItem(
                        value: "Event",
                        child: Text("Event"),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedPurpose = value;
                        showEventField = (value == "Event");
                      });
                    },
                  ),
                  if (showEventField)
                    TextField(
                      controller: eventController,
                      decoration: const InputDecoration(
                          hintText: "Enter event details"),
                    ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (selectedPurpose == "Event" &&
                    eventController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter event details")),
                  );
                  return;
                }
                Navigator.pop(
                    context,
                    selectedPurpose == "Event"
                        ? eventController.text
                        : selectedPurpose);
              },
              child: const Text("Continue"),
            ),
          ],
        );
      },
    );
  }

  Future<String> _showEventDetailDialog() async {
    TextEditingController eventController = TextEditingController();

    String? result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter Event Details"),
          content: TextField(
            controller: eventController,
            decoration: const InputDecoration(hintText: "Event details"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, eventController.text),
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );

    return result ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text(
          'Book a Venue',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppColors.darkdarkgrey,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                hintText: "Search venues...",
                hintStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    dropdownColor: Colors.grey[800],
                    value: _selectedVenueType,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      'All',
                      'Labs',
                      'Meeting Room',
                      'Classroom',
                      'Auditorium'
                    ]
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type,
                                  style: const TextStyle(color: Colors.white)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedVenueType = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Filter by date (YYYY-MM-DD)",
                      hintStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedDate = value.isEmpty ? null : value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<List<Timeslot>>(
              stream: _repository.getAvailableTimeslots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text("No Available Venues",
                          style: TextStyle(color: Colors.white)));
                }

                List<Timeslot> filteredTimeslots = snapshot.data!.where((slot) {
                  bool matchesSearch = _searchQuery.isEmpty ||
                      slot.venueName.toLowerCase().contains(_searchQuery);
                  bool matchesFilter = _selectedVenueType == "All" ||
                      slot.venueType == _selectedVenueType;
                  bool matchesDate =
                      _selectedDate == null || slot.date == _selectedDate;
                  return matchesSearch && matchesFilter && matchesDate;
                }).toList();

                return ListView.builder(
                  itemCount: filteredTimeslots.length,
                  itemBuilder: (context, index) {
                    Timeslot timeslot = filteredTimeslots[index];
                    return Card(
                      color: Colors.grey[850],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 10),
                      child: ListTile(
                        title: Text(
                          timeslot.venueName,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Date: ${timeslot.date}",
                                style: const TextStyle(color: Colors.white70)),
                            Text(
                                "Time: ${timeslot.startTime} - ${timeslot.endTime}",
                                style: const TextStyle(color: Colors.white70)),
                            Text("Capacity: ${timeslot.capacity}",
                                style: const TextStyle(color: Colors.white70)),
                            Text("Equipment: ${timeslot.equipment.join(', ')}",
                                style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            try {
                              final user =
                                  await _repository.getUser(widget.tpNumber);
                              final moduleNames = await _getLecturerModules();

                              String? selectedPurpose =
                                  await _showPurposeDialog(moduleNames);
                              if (selectedPurpose == null) return;

                              String detail = selectedPurpose == "Event"
                                  ? await _showEventDetailDialog()
                                  : selectedPurpose;
                              if (detail.isEmpty) return;

                              await _repository.createBooking(Booking(
                                userId: widget.tpNumber,
                                name: user.name,
                                venueName: timeslot.venueName,
                                venueType: timeslot.venueType,
                                date: timeslot.date,
                                startTime: timeslot.startTime,
                                endTime: timeslot.endTime,
                                status: "scheduled",
                                bookedTime: Timestamp.now(),
                                detail: detail,
                                moduleName:
                                    selectedPurpose, // Store module name in booking
                              ));

                              await _repository.createNotification(
                                userId: widget.tpNumber,
                                venueName: timeslot.venueName,
                                venueType: timeslot.venueType,
                                date: timeslot.date,
                                startTime: timeslot.startTime,
                                endTime: timeslot.endTime,
                                message:
                                    "Your booking for ${timeslot.venueName} on ${timeslot.date} has been successfully scheduled.",
                              );

                              await _repository.updateTimeslotStatus(
                                  timeslot.id, "scheduled");

                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Booking Successful!")),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e")),
                              );
                            }
                          },
                          child: const Text("Book"),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
