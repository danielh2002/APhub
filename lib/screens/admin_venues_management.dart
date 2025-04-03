import 'package:flutter/material.dart';
import 'package:aphub/models/admin_venue_management.dart';
import 'package:aphub/screens/admin_create_venues.dart';
import 'package:aphub/screens/admin_update_venues.dart';
import 'package:aphub/utils/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VenuesManagement extends StatefulWidget {
  const VenuesManagement({super.key});

  @override
  VenuesManagementState createState() => VenuesManagementState();
}

class VenuesManagementState extends State<VenuesManagement> {
  final VenuesManagementModel _model = VenuesManagementModel();
  String _searchQuery = "";
  String _selectedVenueType = "All";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text(
          'Venues Management',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppColors.darkdarkgrey,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: AppColors.white),
                hintText: "Search venues...",
                hintStyle: const TextStyle(color: AppColors.white),
                filled: true,
                fillColor: AppColors.darkgrey,
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
          const SizedBox(height: 1),
          // Dropdown Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButtonFormField<String>(
              dropdownColor: AppColors.darkgrey,
              value: _selectedVenueType,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.darkgrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              items: ['All', 'Labs', 'Meeting room', 'Classroom', 'Auditorium']
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
          const SizedBox(height: 1),
          // Venue List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _model.getVenuesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No Venues Available",
                          style: TextStyle(color: Colors.white)));
                }

                List<QueryDocumentSnapshot> venues = _model.filterVenues(
                    snapshot.data!.docs, _searchQuery, _selectedVenueType);

                return ListView.builder(
                  itemCount: venues.length,
                  itemBuilder: (context, index) {
                    var venue = venues[index];
                    String venueId = venue.id;
                    Map<String, dynamic> venueData =
                        venue.data() as Map<String, dynamic>;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 10),
                      child: Card(
                        color: AppColors.darkdarkgrey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          title: Text(
                            venueData['name'] ?? 'Unnamed Venue',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Capacity: ${venueData['capacity']}",
                                  style: const TextStyle(
                                      color: AppColors.lightgrey)),
                              Text(
                                  "Equipment: ${(venueData['equipment'] as List<dynamic>?)?.join(', ') ?? 'No Equipment'}",
                                  style: const TextStyle(
                                      color: AppColors.lightgrey)),
                              Text(
                                  "Venue Type: ${venueData['venuetype'] ?? 'N/A'}",
                                  style: const TextStyle(
                                      color: AppColors.lightgrey)),
                              Text(
                                "Status: ${venueData['status'] ?? 'N/A'}",
                                style: TextStyle(
                                  color: venueData['status'] == 'available'
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  _editVenue(venueId, venueData);
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _deleteVenue(venueId);
                                },
                              ),
                            ],
                          ),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: _createVenue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _editVenue(String venueId, Map<String, dynamic> venueData) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EditVenuePage(
                venueId: venueId,
                venueData: venueData,
              )),
    );
  }

  void _deleteVenue(String venueId) {
    _model.deleteVenue(venueId);
  }

  void _createVenue() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateVenuePage()),
    );
  }
}
