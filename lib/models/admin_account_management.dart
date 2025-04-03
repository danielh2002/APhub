import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAccountManagement {
  final CollectionReference _usersRef =
      FirebaseFirestore.instance.collection("users");

  // Fetch all users
  Stream<QuerySnapshot> getUsers() {
    return _usersRef.snapshots();
  }

  // Delete a user account
  Future<void> deleteAccount(String userId) async {
    await _usersRef.doc(userId).delete();
  }

  // Filter users based on search query and role
  List<QueryDocumentSnapshot> filterUsers(
      List<QueryDocumentSnapshot> users, String searchQuery, String selectedRole) {
    return users.where((user) {
      Map<String, dynamic> userData = user.data() as Map<String, dynamic>;

      String name = (userData['name'] ?? '').toLowerCase();
      String role = (userData['role'] ?? '').toLowerCase();

      if (role.isEmpty && userData.containsKey('modules')) {
        role = (userData['modules']['role'] ?? '').toLowerCase();
      }

      bool matchesSearch = searchQuery.isEmpty || name.contains(searchQuery);
      bool matchesRole = selectedRole == "All" || role == selectedRole.toLowerCase();

      return matchesSearch && matchesRole;
    }).toList();
  }
}