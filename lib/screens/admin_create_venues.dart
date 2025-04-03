import 'package:aphub/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateVenuePage extends StatefulWidget {
  const CreateVenuePage({super.key});

  @override
  CreateVenuePageState createState() => CreateVenuePageState();
}

class CreateVenuePageState extends State<CreateVenuePage> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final List<String> _selectedEquipment = [];

  final List<String> _availableEquipment = ['Mic', 'Speaker', 'Projector'];
  final List<String> _venueTypes = [
    'Classroom',
    'Meeting room',
    'Auditorium',
    'Lab'
  ];
  final List<String> _blocks = ['A', 'B', 'D', 'E', 'S', 'Library', 'Tech Lab'];
  final List<String> _levels = ['3', '4', '5', '6', '7', '8', '9'];
  final List<String> _statusOptions = ['available', 'unavailable'];

  String _selectedVenueType = 'Classroom';
  String _selectedBlock = 'A';
  String _selectedLevel = '3';
  String _selectedStatus = 'available';

  Future<void> _saveVenue() async {
    if (!mounted) return;

    String location = _locationController.text.trim();
    String capacityText = _capacityController.text.trim();

    if (location.isEmpty || capacityText.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill in all fields")),
        );
      }
      return;
    }

    int? capacity = int.tryParse(capacityText);
    if (capacity == null || capacity <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter a valid capacity")),
        );
      }
      return;
    }

    CollectionReference venues =
        FirebaseFirestore.instance.collection('venues');

    try {
      DocumentSnapshot venueDoc = await venues.doc(location).get();

      // Check again if the widget is still mounted
      if (!mounted) return;

      if (venueDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Venue already exists!")),
          );
        }
        return;
      }

      await venues.doc(location).set({
        "name": location,
        "block": _selectedBlock,
        "level": _selectedLevel,
        "capacity": capacity,
        "equipment": _selectedEquipment,
        "venuetype": _selectedVenueType,
        "status": _selectedStatus,
      });

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving venue: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Venue'),
        backgroundColor: AppColors.darkdarkgrey,
        foregroundColor: AppColors.white,
      ),
      backgroundColor: AppColors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Venue Type Dropdown
            _buildDropdown(
              value: _selectedVenueType,
              label: "Venue Type",
              items: _venueTypes,
              onChanged: (value) {
                setState(() {
                  _selectedVenueType = value!;
                });
              },
            ),
            const SizedBox(height: 20),

            // Venue Location TextField
            _buildTextField(
              controller: _locationController,
              label: "Venue Location (e.g., A-07-01)",
            ),
            const SizedBox(height: 20),

            // Block Dropdown
            _buildDropdown(
              value: _selectedBlock,
              label: "Block",
              items: _blocks,
              onChanged: (value) {
                setState(() {
                  _selectedBlock = value!;
                });
              },
            ),
            const SizedBox(height: 20),

            // Level Dropdown
            _buildDropdown(
              value: _selectedLevel,
              label: "Level",
              items: _levels,
              onChanged: (value) {
                setState(() {
                  _selectedLevel = value!;
                });
              },
            ),
            const SizedBox(height: 20),

            // Capacity TextField
            _buildTextField(
              controller: _capacityController,
              label: "Capacity",
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            // Equipment Selection
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Select Equipment:",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: _availableEquipment.map((equipment) {
                      return FilterChip(
                        label: Text(equipment),
                        selected: _selectedEquipment.contains(equipment),
                        selectedColor: Colors.green,
                        labelStyle: TextStyle(
                          color: _selectedEquipment.contains(equipment)
                              ? AppColors.darkdarkgrey
                              : AppColors.darkgrey,
                        ),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _selectedEquipment.add(equipment);
                            } else {
                              _selectedEquipment.remove(equipment);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Status Dropdown
            _buildDropdown(
              value: _selectedStatus,
              label: "Status",
              items: _statusOptions,
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
            const SizedBox(height: 30),

            // Save Venue Button
            Center(
              child: ElevatedButton(
                onPressed: _saveVenue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkgrey,
                  foregroundColor: AppColors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Save Venue",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build a dropdown
  Widget _buildDropdown({
    required String value,
    required String label,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.lightgrey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.lightgrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.lightgrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.lightgrey),
        ),
        filled: true,
        fillColor: AppColors.darkdarkgrey,
      ),
      dropdownColor: AppColors.darkdarkgrey,
      style: const TextStyle(color: AppColors.white),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: const TextStyle(color: AppColors.white),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  // Helper method to build a text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppColors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.lightgrey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.lightgrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.lightgrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.lightgrey),
        ),
        filled: true,
        fillColor: AppColors.darkdarkgrey,
      ),
      keyboardType: keyboardType,
    );
  }
}
