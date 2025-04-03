import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String tpNumber;
  final String name;
  final List<String> modules;

  User({
    required this.tpNumber,
    required this.name,
    required this.modules,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return User(
      tpNumber: doc.id,
      name: data['name'] ?? 'Unknown Lecturer',
      modules: List<String>.from(data['modules'] ?? []),
    );
  }
}