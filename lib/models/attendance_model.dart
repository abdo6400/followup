import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus {
  present,
  absent,
  excused,
  late
}

class AttendanceModel {
  final String id;
  final String studentId;
  final DateTime date;
  final AttendanceStatus status;
  final String sheikhId;
  final String categoryId;
  final String notes;

  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.date,
    required this.status,
    required this.sheikhId,
    required this.categoryId,
    this.notes = '',
  });

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      status: AttendanceStatus.values.firstWhere(
        (s) => s.toString() == 'AttendanceStatus.${data['status']}',
        orElse: () => AttendanceStatus.absent,
      ),
      notes: data['notes'] ?? '',
      sheikhId: data['sheikhId'] ?? '',
      categoryId: data['categoryId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'date': Timestamp.fromDate(date),
      'status': status.toString().split('.').last,
      'notes': notes,
      'sheikhId': sheikhId,
      'categoryId': categoryId,
    };
  }
}
