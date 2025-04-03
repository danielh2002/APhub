import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:aphub/utils/app_colors.dart';
import 'package:aphub/models/admin_timetable_management.dart';

class TimeSlotManagement extends StatefulWidget {
  const TimeSlotManagement({super.key});

  @override
  TimeSlotManagementState createState() => TimeSlotManagementState();
}

class TimeSlotManagementState extends State<TimeSlotManagement> {
  final TimeSlotManagementModel model = TimeSlotManagementModel();
  DateTime? selectedWeek;

  String? selectedVenueType;
  String? selectedDate;
  String? selectedTime;

  List<Map<String, dynamic>> venues = [];
  bool isGenerating = false;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchVenues();
  }

  Future<void> fetchVenues() async {
    List<Map<String, dynamic>> fetchedVenues = await model.fetchVenues();
    setState(() {
      venues = fetchedVenues;
    });
  }

  DateTime _getStartOfWeek(DateTime date) {
    int difference = date.weekday - DateTime.monday;
    return date.subtract(Duration(days: difference));
  }

  Future<void> _selectWeek(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedWeek ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      if (!mounted) return;
      setState(() {
        selectedWeek = _getStartOfWeek(picked);
      });
      _generateTimeslotsForAllVenues();
    }
  }

  Future<void> _generateTimeslotsForAllVenues() async {
    if (selectedWeek == null) return;

    setState(() {
      isGenerating = true;
    });

    await model.generateTimeslotsForAllVenues(selectedWeek!, venues);

    if (!mounted) return;

    setState(() {
      isGenerating = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("New Time Slots Generated!"),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text("Time Slot Management",
            style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.darkdarkgrey,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.white),
            onPressed: () {
              _showSearchDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.white),
            onPressed: () {
              _showFilterDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isGenerating
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.blue,
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: model.timeslotsRef.orderBy("date").snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text("No time slots available",
                              style: TextStyle(color: AppColors.white)),
                        );
                      }

                      List<Map<String, dynamic>> filteredSlots = snapshot
                          .data!.docs
                          .map((doc) => doc.data() as Map<String, dynamic>)
                          .where((slot) =>
                              (selectedVenueType == null ||
                                  selectedVenueType == "All" ||
                                  slot["venueType"] == selectedVenueType) &&
                              (selectedDate == null ||
                                  selectedDate == "All" ||
                                  slot["date"] == selectedDate) &&
                              (selectedTime == null ||
                                  selectedTime == "All" ||
                                  slot["startTime"] == selectedTime) &&
                              (searchQuery.isEmpty ||
                                  slot["venueName"]
                                      .toLowerCase()
                                      .contains(searchQuery.toLowerCase())))
                          .toList();

                      if (filteredSlots.isEmpty) {
                        return const Center(
                          child: Text("No matching time slots",
                              style: TextStyle(color: AppColors.white)),
                        );
                      }

                      Map<String, Map<String, List<Map<String, dynamic>>>>
                          groupedSlots = {};
                      for (var slot in filteredSlots) {
                        String date = slot["date"];
                        String venueName = slot["venueName"];

                        if (!groupedSlots.containsKey(date)) {
                          groupedSlots[date] = {};
                        }
                        if (!groupedSlots[date]!.containsKey(venueName)) {
                          groupedSlots[date]![venueName] = [];
                        }
                        groupedSlots[date]![venueName]!.add(slot);
                      }

                      return ListView(
                        children: groupedSlots.entries.map((dateEntry) {
                          String date = dateEntry.key;
                          Map<String, List<Map<String, dynamic>>> venuesMap =
                              dateEntry.value;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "Date: $date",
                                  style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              ...venuesMap.entries.map((venueEntry) {
                                String venueName = venueEntry.key;
                                List<Map<String, dynamic>> slots =
                                    venueEntry.value;

                                slots.sort((a, b) =>
                                    a["startTime"].compareTo(b["startTime"]));

                                return Card(
                                  color: AppColors.darkdarkgrey,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  child: ExpansionTile(
                                    title: Text(
                                      venueName,
                                      style: const TextStyle(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    children: slots.map((slot) {
                                      return ListTile(
                                        title: Text(
                                          "${slot["startTime"]} - ${slot["endTime"]}",
                                          style: TextStyle(
                                              color:
                                                  slot["status"] == "available"
                                                      ? Colors.green
                                                      : Colors.red),
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.info_outline,
                                              color: AppColors.white),
                                          onPressed: () {
                                            _showVenueInfoDialog(context, slot);
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              })
                            ],
                          );
                        }).toList(),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.calendar_today, color: AppColors.white),
        label: const Text("Generate Weekly Time Slots",
            style: TextStyle(color: AppColors.white)),
        onPressed: () => _selectWeek(context),
      ),
    );
  }

  void _showVenueInfoDialog(BuildContext context, Map<String, dynamic> slot) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.darkdarkgrey,
          title: Text(
            slot["venueName"],
            style: const TextStyle(color: AppColors.white),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Block: ${slot["block"]}",
                  style: const TextStyle(color: AppColors.white)),
              Text("Level: ${slot["level"]}",
                  style: const TextStyle(color: AppColors.white)),
              Text("Venue Type: ${slot["venueType"]}",
                  style: const TextStyle(color: AppColors.white)),
              Text("Capacity: ${slot["capacity"]}",
                  style: const TextStyle(color: AppColors.white)),
              Text("Equipment: ${slot["equipment"].join(", ")}",
                  style: const TextStyle(color: AppColors.white)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child:
                  const Text("Close", style: TextStyle(color: AppColors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.darkdarkgrey,
          title: const Text("Search Venues",
              style: TextStyle(color: AppColors.white)),
          content: TextField(
            style: const TextStyle(color: AppColors.white),
            decoration: const InputDecoration(
              hintText: "Enter venue name...",
              hintStyle: TextStyle(color: AppColors.darkgrey),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child:
                  const Text("Close", style: TextStyle(color: AppColors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.darkdarkgrey,
          title:
              const Text("Filters", style: TextStyle(color: AppColors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDropdown("Type", TimeSlotManagementModel.venueTypeOptions,
                  selectedVenueType, (value) {
                setState(() {
                  selectedVenueType = value;
                });
              }),
              const SizedBox(height: 10),
              _buildDateDropdown(),
              const SizedBox(height: 10),
              _buildDropdown(
                  "Time", TimeSlotManagementModel.timeSlots, selectedTime,
                  (value) {
                setState(() {
                  selectedTime = value;
                });
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child:
                  const Text("Close", style: TextStyle(color: AppColors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? selectedValue,
      Function(String?) onChanged) {
    return DropdownButton<String>(
      dropdownColor: AppColors.darkdarkgrey,
      value: selectedValue,
      hint: Text(label, style: const TextStyle(color: AppColors.white)),
      icon: const Icon(Icons.arrow_drop_down, color: AppColors.white),
      onChanged: onChanged,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item, style: const TextStyle(color: AppColors.white)),
        );
      }).toList(),
    );
  }

  Widget _buildDateDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: model.timeslotsRef.orderBy("date").snapshots(),
      builder: (context, snapshot) {
        List<String> dates = snapshot.hasData
            ? snapshot.data!.docs
                .map((doc) =>
                    (doc.data() as Map<String, dynamic>)["date"].toString())
                .toSet()
                .toList()
            : [];
        dates.insert(0, "All");

        return _buildDropdown("Date", dates, selectedDate, (value) {
          setState(() {
            selectedDate = value;
          });
        });
      },
    );
  }
}
