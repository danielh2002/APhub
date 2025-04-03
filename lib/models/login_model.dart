import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../roles/students.dart';
import '../roles/lecturers.dart';
import '../roles/admins.dart';

class LoginModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> login({
    required BuildContext context,
    required String tpNumber,
    required String password,
  }) async {
    tpNumber = tpNumber.trim().toUpperCase();
    password = password.trim();

    if (tpNumber.isEmpty || password.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter TP Number and Password')),
      );
      return;
    }

    try {
      // Fetch user data from Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection("users").doc(tpNumber).get();

      if (!userDoc.exists) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String storedPassword = userData['password'] ?? '';
      String userRole = userData['role'] ?? '';

      if (password == storedPassword) {
        Widget nextPage;
        if (userRole == 'Student') {
          nextPage = StudentPage(tpNumber: tpNumber);
        } else if (userRole == 'Lecturer') {
          nextPage = LecturerPage(tpNumber: tpNumber);
        } else if (userRole == 'Admin') {
          nextPage = const AdminPage();
        } else {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Role not recognized')),
          );
          return;
        }

        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => nextPage),
        );
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect Password')),
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database Error: $error')),
      );
    }
  }
}
