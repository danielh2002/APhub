import 'package:aphub/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditVenuePage extends StatefulWidget {
  final String venueId;
  final Map<String, dynamic> venueData;

  const EditVenuePage(
      {super.key, required this.venueId, required this.venueData});

  @override
  EditVenuePageState createState() => EditVenuePageState();
}

class EditVenuePageState extends State<EditVenuePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _locationController;
  late TextEditingController _capacityController;
  final List<String> _venueTypes = [
    'Classroom',
    'Meeting Room',
    'Auditorium',
    'Lab'
  ];
  final List<String> _blocks = ['A', 'B', 'D', 'E', 'S', 'Library', 'Tech Lab'];
  final List<String> _levels = ['3', '4', '5', '6', '7', '8', '9'];
  final List<String> _equipmentOptions = ['Mic', 'Speaker', 'Projector'];
  final List<String> _statusOptions = ['available', 'unavailable'];

  late String _selectedVenueType;
  late String _selectedBlock;
  late String _selectedLevel;
  late String _selectedStatus;
  Set<String> _selectedEquipment = {};

  @override
  void initState() {
    super.initState();
    _locationController =
        TextEditingController(text: widget.venueData['name'] ?? '');
    _capacityController = TextEditingController(
        text: widget.venueData['capacity']?.toString() ?? '');

    // Ensure _selectedVenueType is in the _venueTypes list
    _selectedVenueType = widget.venueData['venuetype'] ?? 'Classroom';
    if (!_venueTypes.contains(_selectedVenueType)) {
      _selectedVenueType = 'Classroom'; // Reset to default if not found
    }

    // Ensure _selectedBlock is in the _blocks list
    _selectedBlock = widget.venueData['block'] ?? 'A';
    if (!_blocks.contains(_selectedBlock)) {
      _selectedBlock = 'A'; // Reset to default if not found
    }

    // Ensure _selectedLevel is in the _levels list
    _selectedLevel = widget.venueData['level']?.toString() ?? '1';
    if (!_levels.contains(_selectedLevel)) {
      _selectedLevel = '1'; // Reset to default if not found
    }

    // Ensure _selectedStatus is in the _statusOptions list
    _selectedStatus = widget.venueData['status'] ?? 'available';
    if (!_statusOptions.contains(_selectedStatus)) {
      _selectedStatus = 'available'; // Reset to default if not found
    }

    _selectedEquipment = Set<String>.from(widget.venueData['equipment'] ?? []);
  }

  @override
  void dispose() {
    _locationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _updateVenue() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance
          .collection("venues")
          .doc(widget.venueId)
          .set({
        "location": _locationController.text.trim(),
        "capacity": int.tryParse(_capacityController.text.trim()) ?? 0,
        "venuetype": _selectedVenueType,
        "block": _selectedBlock,
        "level": _selectedLevel,
        "equipment": _selectedEquipment.toList(),
        "status": _selectedStatus,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Venue updated successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating venue: $e")),
        );
      }
    }
  }

  Widget _buildEquipmentChips() {
    return Wrap(
      spacing: 8.0,
      children: _equipmentOptions.map((equipment) {
        final isSelected = _selectedEquipment.contains(equipment);
        return ChoiceChip(
          label: Text(equipment),
          selected: isSelected,
          selectedColor: Colors.green,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.white : AppColors.lightgrey,
          ),
          onSelected: (selected) {
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Venue"),
        backgroundColor: AppColors.darkdarkgrey,
        foregroundColor: AppColors.white,
      ),
      backgroundColor: AppColors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.center, // Center children horizontally
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

              // Equipment Selection (Centered)
              Center(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.center, // Center children horizontally
                  children: [
                    const Text(
                      "Select Equipment:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white, // White text for dark theme
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildEquipmentChips(),
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

              // Save Venue Button (Centered)
              Center(
                child: ElevatedButton(
                  onPressed: _updateVenue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkgrey,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
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
      style:
          const TextStyle(color: AppColors.white), // White text for dark theme
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
