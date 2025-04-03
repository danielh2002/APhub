import 'package:cloud_firestore/cloud_firestore.dart';

class AdminModuleManagementModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get modulesRef => _firestore.collection("modules");
  CollectionReference get usersRef => _firestore.collection("users");

  // Fetch all modules
  Stream<QuerySnapshot> getModulesStream() {
    return modulesRef.snapshots();
  }

  // Delete a module
  Future<void> deleteModule(String moduleId) async {
    await modulesRef.doc(moduleId).delete();
  }

  // Fetch lecturer name by ID
  Future<String> getLecturerName(String lecturerId) async {
    if (lecturerId.isEmpty) return "Unassigned";

    DocumentSnapshot lecturerSnapshot = await usersRef.doc(lecturerId).get();
    Map<String, dynamic>? lecturerData =
        lecturerSnapshot.data() as Map<String, dynamic>?;

    return lecturerData?["name"] ?? "Unassigned";
  }
}