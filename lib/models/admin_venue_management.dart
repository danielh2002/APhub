import 'package:cloud_firestore/cloud_firestore.dart';

class VenuesManagementModel {
  final CollectionReference venuesRef =
      FirebaseFirestore.instance.collection("venues");

  // Get all venues stream
  Stream<QuerySnapshot> getVenuesStream() {
    return venuesRef.snapshots();
  }

  // Filter venues based on search query and venue type
  List<QueryDocumentSnapshot> filterVenues(List<QueryDocumentSnapshot> venues,
      String searchQuery, String selectedVenueType) {
    return venues.where((venue) {
      Map<String, dynamic> venueData = venue.data() as Map<String, dynamic>;
      String name = (venueData['name'] ?? '').toLowerCase();
      String venueType = (venueData['venuetype'] ?? 'N/A');
      bool matchesSearch = searchQuery.isEmpty || name.contains(searchQuery);
      bool matchesFilter =
          selectedVenueType == "All" || venueType == selectedVenueType;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  // Delete a venue
  Future<void> deleteVenue(String venueId) {
    return venuesRef.doc(venueId).delete();
  }
}
