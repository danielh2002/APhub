import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aphub/utils/app_colors.dart';
import 'package:aphub/screens/admin_create_module.dart';
import 'package:aphub/screens/admin_update_module.dart';
import 'package:aphub/models/admin_module_management.dart';

class ModuleManagement extends StatefulWidget {
  const ModuleManagement({super.key});

  @override
  ModuleManagementState createState() => ModuleManagementState();
}

class ModuleManagementState extends State<ModuleManagement> {
  final AdminModuleManagementModel _model = AdminModuleManagementModel();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text(
          'Module Management',
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
                hintText: "Search modules...",
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
          const SizedBox(height: 10),

          // Module List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _model.getModulesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.white));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No Modules Available",
                          style: TextStyle(color: AppColors.white)));
                }

                List<QueryDocumentSnapshot> modules = snapshot.data!.docs;

                // Apply search filter
                modules = modules.where((module) {
                  String moduleName =
                      (module.data() as Map<String, dynamic>?)?["moduleName"]
                              ?.toString()
                              .toLowerCase() ??
                          "";
                  return _searchQuery.isEmpty ||
                      moduleName.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: modules.length,
                  itemBuilder: (context, index) {
                    var module = modules[index];
                    String moduleId = module.id;
                    Map<String, dynamic> moduleData =
                        module.data() as Map<String, dynamic>;

                    return Card(
                      color: AppColors.darkdarkgrey, // Dark card background
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 10),
                      child: ListTile(
                        title: Text(
                          moduleData['moduleName'] ?? 'Unnamed Module',
                          style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Duration: ${moduleData['duration'] ?? 'N/A'}",
                                style: const TextStyle(
                                    color: AppColors.lightgrey)),
                            Text(
                                "Lecturer: ${moduleData['lecturerName'] ?? 'Unassigned'}",
                                style: const TextStyle(
                                    color: AppColors.lightgrey)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                _editModule(module);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _deleteModule(moduleId);
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

      // Floating Action Button for adding modules
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: _createModule,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _createModule() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateModuleScreen()),
    );
  }

  void _editModule(DocumentSnapshot module) async {
    Map<String, dynamic>? data = module.data() as Map<String, dynamic>?;

    String lecturerId = data?["lecturerId"] ?? "";
    String lecturerName = await _model.getLecturerName(lecturerId);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UpdateModuleScreen(
            moduleId: module.id,
            moduleName: data?["moduleName"] ?? "Unknown",
            duration: data?["duration"]?.toString() ?? "N/A",
            lecturerId: lecturerId,
            lecturerName: lecturerName,
          ),
        ),
      );
    }
  }

  void _deleteModule(String moduleId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.darkdarkgrey,
          title: const Text("Confirm Deletion",
              style: TextStyle(color: AppColors.white)),
          content: const Text("Are you sure you want to delete this module?",
              style: TextStyle(color: AppColors.white)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel",
                  style: TextStyle(color: AppColors.white)),
            ),
            TextButton(
              onPressed: () {
                _model.deleteModule(moduleId);
                Navigator.of(context).pop();
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
