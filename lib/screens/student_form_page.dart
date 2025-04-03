import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aphub/utils/app_colors.dart';
import 'package:aphub/models/student_form_model.dart'; 

class StudentFormPage extends StatefulWidget {
  final String tpNumber;
  final String timeslotId;
  
  

  const StudentFormPage({super.key, required this.tpNumber, required this.timeslotId});

  @override
  StudentFormPageState createState() => StudentFormPageState();
}

class StudentFormPageState extends State<StudentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController eventNameController = TextEditingController();
  final TextEditingController eventTypeController = TextEditingController();
  final TextEditingController estPersonController = TextEditingController();
  

  Map<String, dynamic>? timeslotData;

  @override
  void initState() {
    super.initState();
    fetchTimeslotData();
  }

  Future<void> fetchTimeslotData() async {
    try {
      DocumentSnapshot timeslotSnapshot = await FirebaseFirestore.instance
          .collection('timeslots')
          .doc(widget.timeslotId)
          .get();
      if (timeslotSnapshot.exists) {
        setState(() {
          timeslotData = timeslotSnapshot.data() as Map<String, dynamic>?;
        });
      }
    } catch (e) {
      //
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Auditorium", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
      ),
      body: Container(
        color: Colors.black,
        child: timeslotData == null
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Hall Information Card
                      Card(
                        color: Colors.grey[900],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                "Hall Information",
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 16),
                              _buildReadOnlyTextField("Venue Name", timeslotData?['venueName'] ?? 'N/A'),
                              const SizedBox(height: 8),
                              _buildReadOnlyTextField("Venue Type", timeslotData?['venueType'] ?? 'N/A'),
                              const SizedBox(height: 8),
                              _buildReadOnlyTextField("Capacity", timeslotData?['capacity']?.toString() ?? 'N/A'),
                              const SizedBox(height: 8),
                              _buildReadOnlyTextField("Date", timeslotData?['date'] ?? 'N/A'),
                              const SizedBox(height: 8),
                              _buildReadOnlyTextField("Time",
                                  "${timeslotData?['startTime'] ?? 'N/A'} - ${timeslotData?['endTime'] ?? 'N/A'}"),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Equipment Information Card
                      if (timeslotData?['equipment'] != null)
                        Card(
                          color: Colors.grey[900],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  "Equipment",
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 16),
                                ...(timeslotData?['equipment'] as List<dynamic>).map((equipment) {
                                  return _buildReadOnlyTextField("Equipment", equipment);
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Booking Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildTextField(eventNameController, "Event Name"),
                            const SizedBox(height: 10),
                            _buildTextField(eventTypeController, "Event Type"),
                            const SizedBox(height: 10),
                            _buildTextField(estPersonController, "Estimated Persons", isNumber: true),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () async {
                                _submitBooking();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[400],
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text("Submit Booking", style: TextStyle(color: Colors.black)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

void _submitBooking() async {
  final studentFormModel = StudentFormModel(
    formKey: _formKey,
    eventNameController: eventNameController,
    eventTypeController: eventTypeController,
    estPersonController: estPersonController,
    tpNumber: widget.tpNumber,
    timeslotId: widget.timeslotId,
    timeslotData: timeslotData,
    context: context,
  ); // Create an instance
  await studentFormModel.submitBooking(); // Call the method
}


  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return Card(
      color: AppColors.darkdarkgrey, // Set the background color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Rounded corners
      ),
      elevation: 0, 
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Add padding
        child: TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white),
            enabledBorder: InputBorder.none, // Remove the default border
            focusedBorder: InputBorder.none, // Remove the default border
            border: InputBorder.none, // Remove the default border
          ),
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Please enter $label"; // Ensure the field is not empty
            }
            if (isNumber && int.tryParse(value) == null) {
              return "Please enter a valid number for $label"; // Ensure the input is a valid number
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildReadOnlyTextField(String label, String value) {
    return Card(
      color: AppColors.darkdarkgrey, // Set the background color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Rounded corners
      ),
      elevation: 0, // Remove shadow to match the Equipment/Hall Information tabs
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Add padding
        child: TextFormField(
          initialValue: value,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white),
            enabledBorder: InputBorder.none, // Remove the default border
            focusedBorder: InputBorder.none, // Remove the default border
            border: InputBorder.none, // Remove the default border
          ),
          enabled: false, // Make the text field non-editable
        ),
      ),
    );
  }
}