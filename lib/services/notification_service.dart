import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Request permission for iOS and macOS
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(initializationSettings);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background/terminated messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      await _showLocalNotification(
        title: message.notification!.title ?? '',
        body: message.notification!.body ?? '',
      );
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'followup_channel',
      'Followup Notifications',
      channelDescription: 'Notifications from Followup app',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iOSDetails = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> _handleNotificationTap(RemoteMessage message) async {
    // Handle notification tap
    print('Notification tapped!');
    print('Message data: ${message.data}');
  }

  Future<String?> getDeviceToken() async {
    return await _messaging.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  Future<void> sendNotification({
    required String title,
    required String message,
    required NotificationTarget target,
    String? targetId,
    required String senderId,
  }) async {
    final notification = NotificationModel(
      id: '',  // Will be set by Firestore
      title: title,
      message: message,
      target: target,
      targetId: targetId,
      createdAt: DateTime.now(),
      senderId: senderId,
    );

    await _db.collection('notifications').add(notification.toMap());
  }

  Future<void> sendTaskResultNotification({
    required String studentId,
    required String taskTitle,
    required double points,
    required String parentId,
  }) async {
    await sendNotification(
      title: 'Task Result',
      message: 'Your child received $points points in $taskTitle',
      target: NotificationTarget.parent,
      targetId: parentId,
      senderId: 'system',
    );
  }

  Future<void> sendCategoryAnnouncement({
    required String categoryId,
    required String title,
    required String message,
    required String senderId,
  }) async {
    await sendNotification(
      title: title,
      message: message,
      target: NotificationTarget.category,
      targetId: categoryId,
      senderId: senderId,
    );
  }

  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    final snapshot = await _db
        .collection('notifications')
        .where('targetId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    return snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
  }
}

// Top-level function for background message handling
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}
