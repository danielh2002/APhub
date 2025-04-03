import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TimeSlotManagementModel {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late CollectionReference timeslotsRef;

  TimeSlotManagementModel() {
    timeslotsRef = firestore.collection("timeslots");
  }

  Future<List<Map<String, dynamic>>> fetchVenues() async {
    QuerySnapshot querySnapshot = await firestore.collection("venues").get();
    return querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  Future<void> generateTimeslotsForAllVenues(
      DateTime selectedWeek, List<Map<String, dynamic>> venues) async {
    for (int i = 0; i < 5; i++) {
      DateTime currentDate = selectedWeek.add(Duration(days: i));
      String formattedDate = DateFormat('yyyy-MM-dd').format(currentDate);

      for (var venue in venues) {
        String venueName = venue["name"];
        String venueType = venue["venuetype"];
        String block = venue["block"];
        int capacity = venue["capacity"];
        List<dynamic> equipment = venue["equipment"];
        String level = venue["level"];
        String status = venue["status"];

        for (int j = 0; j < timeSlots.length - 1; j++) {
          String startTime = timeSlots[j];
          String endTime = timeSlots[j + 1];

          await timeslotsRef.add({
            "venueName": venueName,
            "venueType": venueType,
            "block": block,
            "capacity": capacity,
            "equipment": equipment,
            "level": level,
            "status": status,
            "date": formattedDate,
            "startTime": startTime,
            "endTime": endTime,
          });
        }
      }
    }
  }

  static List<String> timeSlots = [
    "08:30",
    "09:00",
    "09:30",
    "10:00",
    "10:30",
    "11:00",
    "11:30",
    "12:00",
    "12:30",
    "13:00",
    "13:30",
    "14:00",
    "14:30",
    "15:00",
    "15:30",
    "16:00",
    "16:30",
    "17:00"
  ];

  static List<String> venueTypeOptions = [
    "All",
    "Auditorium",
    "Classroom",
    "Lab",
    "Meeting Room"
  ];
}


