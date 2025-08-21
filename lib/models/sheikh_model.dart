import 'package:cloud_firestore/cloud_firestore.dart';

class SheikhModel {
  final String id;
  final String userId;
  final String name;
  final List<String> assignedCategories;
  final List<String> workingDays;

  SheikhModel({
    required this.id,
    required this.userId,
    required this.assignedCategories,
    required this.workingDays,
    required this.name,
  });

  factory SheikhModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SheikhModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      assignedCategories: List<String>.from(data['assignedCategories'] ?? []),
      workingDays: List<String>.from(data['workingDays'] ?? []),
      name: data['name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'assignedCategories': assignedCategories,
      'workingDays': workingDays,
      'name': name,
    };
  }
}
