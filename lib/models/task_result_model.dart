import 'package:cloud_firestore/cloud_firestore.dart';

class TaskResultModel {
  final String id;
  final String studentId;
  final String taskId;
  final DateTime date;
  final double points;
  final String sheikhId;
  final String categoryId;
  final String? notes;

  TaskResultModel({
    required this.id,
    required this.studentId,
    required this.taskId,
    required this.date,
    required this.points,
    required this.sheikhId,
    required this.categoryId,
    this.notes,
  });

  factory TaskResultModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskResultModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      taskId: data['taskId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      points: (data['points'] ?? 0).toDouble(),
      sheikhId: data['sheikhId'] ?? '',
      categoryId: data['categoryId'] ?? '',
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'taskId': taskId,
      'date': Timestamp.fromDate(date),
      'points': points,
      'sheikhId': sheikhId,
      'categoryId': categoryId,
      'notes': notes,
    };
  }
}
