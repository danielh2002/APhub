import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aphub/utils/app_colors.dart';

class UpdateModuleScreen extends StatefulWidget {
  final String moduleId;
  final String moduleName;
  final String duration;
  final String? lecturerId;
  final String? lecturerName;

  const UpdateModuleScreen({
    super.key,
    required this.moduleId,
    required this.moduleName,
    required this.duration,
    this.lecturerId,
    this.lecturerName,
  });

  @override
  UpdateModuleScreenState createState() => UpdateModuleScreenState();
}

class UpdateModuleScreenState extends State<UpdateModuleScreen> {
  final TextEditingController _moduleNameController = TextEditingController();
  String? _selectedDuration;
  String? _selectedLecturerId;
  String? _selectedLecturerName;

  bool _isSaving = false;

  final CollectionReference _modulesRef =
      FirebaseFirestore.instance.collection("modules");
  final CollectionReference _usersRef =
      FirebaseFirestore.instance.collection("users");

  final List<String> _durations = [
    "1 hour",
    "1 hour 30 minutes",
    "1 hour 45 minutes",
    "2 hours"
  ];

  @override
  void initState() {
    super.initState();
    _moduleNameController.text = widget.moduleName;
    _selectedDuration = widget.duration;
    _selectedLecturerId = widget.lecturerId;
    _selectedLecturerName = widget.lecturerName;

    if (!_durations.contains(_selectedDuration)) {
      _selectedDuration = null;
    }
  }

  Future<void> _updateModule() async {
    if (_moduleNameController.text.isEmpty || _selectedDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Module name and duration are required"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _modulesRef.doc(widget.moduleId).update({
        "moduleName": _moduleNameController.text,
        "duration": _selectedDuration,
        "lecturerName": _selectedLecturerName ?? "Unassigned",
        "lecturerId": _selectedLecturerId ?? "",
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Module updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text(
          "Update Module",
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppColors.darkdarkgrey,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _moduleNameController,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                labelText: "Module Name",
                labelStyle: const TextStyle(color: AppColors.white),
                filled: true,
                fillColor: AppColors.darkgrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Duration",
                labelStyle: const TextStyle(color: AppColors.white),
                filled: true,
                fillColor: AppColors.darkgrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              dropdownColor: AppColors.darkgrey,
              value: _selectedDuration,
              items: _durations
                  .map((duration) => DropdownMenuItem(
                        value: duration,
                        child: Text(duration,
                            style: const TextStyle(color: AppColors.white)),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDuration = value;
                });
              },
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream:
                  _usersRef.where("role", isEqualTo: "Lecturer").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.white));
                }

                List<QueryDocumentSnapshot> lecturers = snapshot.data!.docs;
                if (lecturers.isEmpty) {
                  return const Text("No lecturers available",
                      style: TextStyle(color: AppColors.white));
                }

                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Select Lecturer",
                    labelStyle: const TextStyle(color: AppColors.white),
                    filled: true,
                    fillColor: AppColors.darkgrey,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: AppColors.darkgrey,
                  value: _selectedLecturerId,
                  items: lecturers.map((lecturer) {
                    final data = lecturer.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: lecturer.id,
                      child: Text(data["name"] ?? "Unknown",
                          style: const TextStyle(color: AppColors.white)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    final selectedLecturer = lecturers
                        .firstWhere((lecturer) => lecturer.id == value);
                    final lecturerData =
                        selectedLecturer.data() as Map<String, dynamic>;
                    setState(() {
                      _selectedLecturerId = value;
                      _selectedLecturerName = lecturerData["name"];
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _updateModule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(
                        color: AppColors.white, strokeWidth: 2)
                    : const Text("Update Module",
                        style: TextStyle(color: AppColors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
