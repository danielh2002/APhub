import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aphub/utils/app_colors.dart';
import 'package:aphub/models/admin_booking_management.dart';

class AdminBookingManagement extends StatefulWidget {
  const AdminBookingManagement({super.key});

  @override
  State<AdminBookingManagement> createState() => _AdminBookingManagementState();
}

class _AdminBookingManagementState extends State<AdminBookingManagement> {
  final AdminBookingManagementModel _model = AdminBookingManagementModel();
  String _selectedStatusFilter = "All";

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(
          title: const Text("Booking Management",
              style: TextStyle(color: AppColors.white)),
          backgroundColor: AppColors.darkdarkgrey,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            DropdownButton<String>(
              value: _selectedStatusFilter,
              dropdownColor: AppColors.darkdarkgrey,
              icon: const Icon(Icons.filter_list, color: AppColors.white),
              underline: Container(),
              items: <String>[
                "All",
                "scheduled",
                "pending",
                "cancelled",
                "history",
                "completed"
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(color: AppColors.white),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedStatusFilter = newValue!;
                });
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "All Bookings"),
              Tab(text: "Auditorium Requests"),
            ],
            indicatorColor: Colors.blue,
            labelColor: Colors.blue,
            unselectedLabelColor: AppColors.white,
          ),
        ),
        body: TabBarView(
          children: [
            _buildAllBookingsTab(),
            _buildAuditoriumRequestsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAllBookingsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _model
          .getAllBookingsQuery(statusFilter: _selectedStatusFilter)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("No bookings found",
                style: TextStyle(color: AppColors.white)),
          );
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            Map<String, dynamic> booking = doc.data() as Map<String, dynamic>;
            String status = booking["status"] ?? "pending";
            Color statusColor = _model.getStatusColor(status);

            return Card(
              color: AppColors.darkdarkgrey,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: ListTile(
                title: Text(
                  booking["venueName"] ?? "Unknown Venue",
                  style: const TextStyle(
                      color: AppColors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Date: ${booking["date"]}",
                        style: const TextStyle(color: AppColors.white)),
                    Text(
                        "Time: ${booking["startTime"]} - ${booking["endTime"]}",
                        style: const TextStyle(color: AppColors.white)),
                    Text("Booked By: ${booking["name"]} | ${booking["userId"]}",
                        style: TextStyle(color: AppColors.white)),
                    Text(
                      "Status: $status",
                      style: TextStyle(
                          color: statusColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAuditoriumRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _model.getPendingAuditoriumRequestsQuery().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading requests: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("No pending auditorium requests found",
                style: TextStyle(color: AppColors.white)),
          );
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            Map<String, dynamic> request = doc.data() as Map<String, dynamic>;
            String status = request["status"] ?? "pending";
            Color statusColor = _model.getStatusColor(status);

            return Card(
              color: AppColors.darkdarkgrey,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: ListTile(
                title: Text(
                  request["venueName"] ?? "Unknown Venue",
                  style: const TextStyle(
                      color: AppColors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Event: ${request["eventname"] ?? "N/A"}",
                      style: const TextStyle(color: AppColors.white),
                    ),
                    Text(
                      "Date: ${request["date"] ?? "N/A"}",
                      style: const TextStyle(color: AppColors.white),
                    ),
                    Text(
                      "Time: ${request["startTime"] ?? "N/A"} - ${request["endTime"] ?? "N/A"}",
                      style: const TextStyle(color: AppColors.white),
                    ),
                    Text(
                      "Estimated People: ${request["estperson"] ?? "N/A"}",
                      style: const TextStyle(color: AppColors.white),
                    ),
                    Text(
                      "Booked By : ${request["name"] ?? "Unknown"} | ${request["userId"] ?? "N/A"}",
                      style: const TextStyle(color: AppColors.white),
                    ),
                    Text(
                      "Status: $status",
                      style: TextStyle(
                          color: statusColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                trailing: status == "pending"
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _model.approveRequest(doc.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _showRejectDialog(doc.id),
                          ),
                        ],
                      )
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showRejectDialog(String docId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.darkdarkgrey,
          title: const Text("Reject Request",
              style: TextStyle(color: AppColors.white)),
          content: TextField(
            controller: reasonController,
            style: const TextStyle(color: AppColors.white),
            decoration: const InputDecoration(
              hintText: "Enter reason for rejection...",
              hintStyle: TextStyle(color: AppColors.darkdarkgrey),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel",
                  style: TextStyle(color: AppColors.white)),
            ),
            TextButton(
              onPressed: () async {
                if (reasonController.text.isNotEmpty) {
                  await _model.rejectRequest(docId, reasonController.text);
                  if (!mounted) return;
                  Navigator.pop(context);
                }
              },
              child: const Text("Reject", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
