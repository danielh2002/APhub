import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:aphub/screens/admin_create_account.dart';
import 'package:aphub/screens/admin_update_account.dart';
import 'package:aphub/utils/app_colors.dart';
import 'package:aphub/models/admin_account_management.dart';

class AccountManagement extends StatefulWidget {
  const AccountManagement({super.key});

  @override
  AccountManagementState createState() => AccountManagementState();
}

class AccountManagementState extends State<AccountManagement> {
  final AdminAccountManagement _accountManagement = AdminAccountManagement();
  String _searchQuery = "";
  String _selectedRole = "All";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text(
          'Account Management',
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
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: AppColors.white),
                hintText: "Search accounts...",
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
          // Role Filter Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: DropdownButtonFormField<String>(
              value: _selectedRole,
              dropdownColor: AppColors.darkgrey,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.darkgrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: AppColors.white),
              items: ["All", "Student", "Lecturer", "Admin"]
                  .map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(role,
                            style: const TextStyle(color: AppColors.white)),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
            ),
          ),

          const SizedBox(height: 10),

          // Account List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _accountManagement.getUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No Accounts Available",
                          style: TextStyle(color: AppColors.white)));
                }

                List<QueryDocumentSnapshot> users = snapshot.data!.docs;

                // Apply search filter and role filter
                users = _accountManagement.filterUsers(
                    users, _searchQuery, _selectedRole);

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var user = users[index];
                    String userId = user.id;
                    Map<String, dynamic> userData =
                        user.data() as Map<String, dynamic>;

                    return Card(
                      color: AppColors.darkdarkgrey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 10),
                      child: ListTile(
                        title: Text(
                          userData['name'] ?? 'Unknown User',
                          style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("TP Number: $userId",
                                style: const TextStyle(color: AppColors.white)),
                            Text(
                                "Role: ${userData['role'] ?? userData['modules']?['role'] ?? 'No role'}",
                                style: const TextStyle(color: AppColors.white)),
                            Text("Email: ${userData['email'] ?? 'No email'}",
                                style: const TextStyle(color: AppColors.white)),
                            if (userData['role'] == 'Lecturer')
                              Text(
                                  "Modules: ${userData['modules'] ?? 'Not assigned'}",
                                  style:
                                      const TextStyle(color: AppColors.white)),
                            Text(
                                "Password: ${userData['password'] ?? 'Not available'}",
                                style: const TextStyle(color: AppColors.white)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                _editAccount(userId, userData);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _deleteAccount(userId);
                              },
                            ),
                          ],
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

      // Floating Action Button for adding accounts
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: _createAccount,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  void _editAccount(String userId, Map<String, dynamic> userData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateAccount(
          userId: userId,
          name: userData['name'] ?? '',
          role: userData['role'] ?? '',
          password: userData['password'] ?? '',
          modules: userData['modules'] ?? '',
        ),
      ),
    );
  }

  void _deleteAccount(String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.darkgrey,
          title: const Text("Confirm Deletion",
              style: TextStyle(color: AppColors.white)),
          content: const Text("Are you sure you want to delete this account?",
              style: TextStyle(color: AppColors.white)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel",
                  style: TextStyle(color: AppColors.white)),
            ),
            TextButton(
              onPressed: () {
                _accountManagement.deleteAccount(userId);
                Navigator.of(context).pop(); // Close the dialog after deletion
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _createAccount() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const CreateAccount()));
  }
}
