import 'package:cloud_firestore/cloud_firestore.dart';

class SheikhModel {
  final String id;
  final String userId;
  final String name;
  final List<String> assignedCategories;
  final List<int> workingDays;

  SheikhModel({
    required this.id,
    required this.userId,
    required this.assignedCategories,
    required this.workingDays,
    required this.name,
  });

  factory SheikhModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    List<int> _parseWorkingDays(dynamic raw) {
      if (raw is List) {
        if (raw.isEmpty) return <int>[];
        if (raw.first is int) {
          return List<int>.from(raw);
        }
        if (raw.first is String) {
          final Map<String, int> nameToWeekday = {
            'Monday': 1,
            'Tuesday': 2,
            'Wednesday': 3,
            'Thursday': 4,
            'Friday': 5,
            'Saturday': 6,
            'Sunday': 7,
          };
          return List<String>.from(raw)
              .map((s) => nameToWeekday[s] ?? 0)
              .where((v) => v > 0)
              .toList();
        }
      }
      return <int>[];
    }

    return SheikhModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      assignedCategories: List<String>.from(data['assignedCategories'] ?? []),
      workingDays: _parseWorkingDays(data['workingDays']),
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
