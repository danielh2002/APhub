import 'package:flutter/material.dart';

class StudentModel with ChangeNotifier {
  String _name = "Loading...";
  String _tpNumber = "";

  String get name => _name;
  String get tpNumber => _tpNumber;

  void setName(String name) {
    _name = name;
    notifyListeners();
  }

  void setTpNumber(String tpNumber) {
    _tpNumber = tpNumber;
    notifyListeners();
  }

  Future<void> fetchUserData(String tpNumber) async {
    try {
      // Fetch user data from Firestore
      // Example:
      // DocumentSnapshot userDoc = await FirebaseFirestore.instance
      //     .collection('users')
      //     .doc(tpNumber)
      //     .get();
      // setName(userDoc['name']);
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }
}