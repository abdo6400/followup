import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String id;
  final String name;
  final String parentId;
  final List<String> assignedCategories;
  final List<String> assignedSheikhs;

  StudentModel({
    required this.id,
    required this.name,
    required this.parentId,
    required this.assignedCategories,
    required this.assignedSheikhs,
  });

  factory StudentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudentModel(
      id: doc.id,
      name: data['name'] ?? '',
      parentId: data['parentId'] ?? '',
      assignedCategories: List<String>.from(data['assignedCategories'] ?? []),
      assignedSheikhs: List<String>.from(data['assignedSheikhs'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'parentId': parentId,
      'assignedCategories': assignedCategories,
      'assignedSheikhs': assignedSheikhs,
    };
  }
}
