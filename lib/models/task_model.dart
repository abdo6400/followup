import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskType { points, yesNo, custom }

class TaskModel {
  final String id;
  final String title;
  final TaskType type;
  final String? categoryId;
  final int maxPoints;

  TaskModel({
    required this.id,
    required this.title,
    required this.type,
    this.categoryId,
    required this.maxPoints,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      type: TaskType.values.firstWhere(
        (e) => e.toString() == 'TaskType.${data['type']}',
        orElse: () => TaskType.points,
      ),
      categoryId: data['categoryId'],
      maxPoints: data['maxPoints'] ?? 10,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type.toString().split('.').last,
      'categoryId': categoryId,
      'maxPoints': maxPoints,
    };
  }
}
