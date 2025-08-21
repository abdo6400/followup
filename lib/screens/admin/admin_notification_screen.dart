import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import 'announcement_screen.dart';
import 'package:intl/intl.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({Key? key}) : super(key: key);

  @override
  State<AdminNotificationScreen> createState() => _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final _notificationService = NotificationService();
  final _authService = AuthService();
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) throw 'User not authenticated';

      final snapshot = await _notificationService.getUserNotifications(currentUser.id);
      if (mounted) {
        setState(() {
          _notifications = snapshot;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notifications: $e')),
        );
      }
    }
  }

  String _getTargetText(NotificationTarget target, String? targetId) {
    switch (target) {
      case NotificationTarget.all:
        return 'All Users';
      case NotificationTarget.parent:
        return 'All Parents';
      case NotificationTarget.category:
        return 'Category: $targetId';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.notifications_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No announcements yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              notification.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(notification.message),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      notification.target == NotificationTarget.all
                                          ? Icons.people
                                          : notification.target ==
                                                  NotificationTarget.parent
                                              ? Icons.family_restroom
                                              : Icons.category,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getTargetText(
                                          notification.target, notification.targetId),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      DateFormat('MMM d, y - h:mm a')
                                          .format(notification.createdAt),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AnnouncementScreen(),
            ),
          ).then((_) => _loadNotifications());
        },
        icon: const Icon(Icons.add),
        label: const Text('New Announcement'),
      ),
    );
  }
}
