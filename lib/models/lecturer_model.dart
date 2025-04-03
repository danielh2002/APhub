import 'package:cloud_firestore/cloud_firestore.dart';

class Lecturer {
  final String id;
  final String name;
  final String tpNumber;

  Lecturer({
    required this.id,
    required this.name,
    required this.tpNumber,
  });

  factory Lecturer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Lecturer(
      id: doc.id,
      name: data['name'] ?? 'Unknown',
      tpNumber: data['tpNumber'] ?? '',
    );
  }
}