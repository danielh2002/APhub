import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key});

  @override
  CreateAccountState createState() => CreateAccountState();
}

class CreateAccountState extends State<CreateAccount> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _userIdController =
      TextEditingController(text: "TP");
  final TextEditingController _modulesController = TextEditingController();
  final TextEditingController _emailController =
      TextEditingController(text: "TP@mail.apu.edu.my");

  String _selectedRole = 'Student';

  String _getPrefix(String role) {
    switch (role) {
      case 'Admin':
        return 'A';
      case 'Lecturer':
        return 'L';
      case 'Student':
        return 'TP';
      default:
        return 'TP';
    }
  }

  void _updateUserIdPrefix() {
    String prefix = _getPrefix(_selectedRole);
    String currentInput =
        _userIdController.text.replaceAll(RegExp(r'[^0-9]'), '');

    setState(() {
      _userIdController.text = "$prefix$currentInput";
      _emailController.text = "${_userIdController.text}@mail.apu.edu.my";
    });
  }

  Future<bool> _isDuplicateAccount(String userId, String name) async {
    var userIdDoc =
        await FirebaseFirestore.instance.collection("users").doc(userId).get();
    if (userIdDoc.exists) {
      _showError('User ID already exists.');
      return true;
    }

    var querySnapshot = await FirebaseFirestore.instance
        .collection("users")
        .where("name", isEqualTo: name)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      _showError('An account with this Name already exists.');
      return true;
    }

    return false;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _createAccount() async {
    if (_formKey.currentState!.validate()) {
      String userId = _userIdController.text.trim();
      String name = _nameController.text.trim();
      String email = _emailController.text.trim(); // Ensure email is included
      String password = _passwordController.text.trim();
      String modules = _modulesController.text.trim();

      if (!RegExp(r'^[A-Z]{1,2}[0-9]{6}$').hasMatch(userId)) {
        _showError(
            'User ID must be in the correct format (Prefix + 6 digits).');
        return;
      }

      if (await _isDuplicateAccount(userId, name)) return;

      try {
        Map<String, dynamic> userData = {
          'name': name,
          'email': email,
          'password': password,
          'role': _selectedRole,
          'modules': _selectedRole == 'Lecturer'
              ? modules.split(",").map((e) => e.trim()).toList()
              : [],
        };

        await FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .set(userData);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Account Created Successfully!'),
              backgroundColor: Colors.green),
        );

        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        _showError('Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title:
            const Text('Create Account', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Role Dropdown
              DropdownButtonFormField<String>(
                value: _selectedRole,
                dropdownColor: Colors.grey[900],
                decoration: _inputDecoration("Role"),
                style: const TextStyle(color: Colors.white),
                items: ['Admin', 'Lecturer', 'Student']
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role,
                              style: const TextStyle(color: Colors.white)),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                    _updateUserIdPrefix(); // Update User ID and Email when role changes
                  });
                },
              ),
              const SizedBox(height: 20),

              // User ID Field
              TextFormField(
                controller: _userIdController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("User ID (Prefix + 6 Digits)"),
                onChanged: (value) {
                  _updateUserIdPrefix();
                },
                validator: (value) {
                  if (value == null ||
                      !RegExp(r'^[A-Z]{1,2}[0-9]{6}$').hasMatch(value)) {
                    return 'Enter a valid ID (e.g., TP123456, A000001)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Name Field
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Name"),
                validator: (value) =>
                    value!.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 20),

              // Email Field
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Email"),
                readOnly: true, // Prevent user from editing
              ),

              const SizedBox(height: 20),

              // Modules Field (Only for Lecturers)
              if (_selectedRole == 'Lecturer') ...[
                TextFormField(
                  controller: _modulesController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Modules (Courses Taught)"),
                  validator: (value) =>
                      value!.isEmpty ? 'Modules are required' : null,
                ),
                const SizedBox(height: 20),
              ],

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: false,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Password"),
                validator: (value) =>
                    value!.isEmpty ? 'Password is required' : null,
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.all(15),
                  ),
                  child: const Text("Create Account",
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// **Custom Input Decoration**
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.grey[800],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}
