import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationTarget { all, parent, category, sheikh, student }

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationTarget target;
  final String? targetId;  // ID of specific category/sheikh/student if not "all"
  final DateTime createdAt;
  final String senderId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.target,
    this.targetId,
    required this.createdAt,
    required this.senderId,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      target: NotificationTarget.values.firstWhere(
        (e) => e.toString() == 'NotificationTarget.${data['target']}',
        orElse: () => NotificationTarget.all,
      ),
      targetId: data['targetId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      senderId: data['senderId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'target': target.toString().split('.').last,
      'targetId': targetId,
      'createdAt': Timestamp.fromDate(createdAt),
      'senderId': senderId,
    };
  }
}
