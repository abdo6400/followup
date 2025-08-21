import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({Key? key}) : super(key: key);

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _notificationService = NotificationService();
  final _dbService = DatabaseService();
  final _authService = AuthService();
  bool _isLoading = true;
  NotificationTarget _selectedTarget = NotificationTarget.all;
  List<CategoryModel> _categories = [];
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _dbService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: $e')),
        );
      }
    }
  }

  Future<void> _sendAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTarget == NotificationTarget.category &&
        _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) throw 'User not authenticated';

      await _notificationService.sendNotification(
        title: _titleController.text,
        message: _messageController.text,
        target: _selectedTarget,
        targetId: _selectedTarget == NotificationTarget.category
            ? _selectedCategoryId
            : null,
        senderId: currentUser.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement sent successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error sending announcement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending announcement: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Announcement'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Target Audience',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('All'),
                                  selected:
                                      _selectedTarget == NotificationTarget.all,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedTarget = NotificationTarget.all;
                                        _selectedCategoryId = null;
                                      });
                                    }
                                  },
                                ),
                                ChoiceChip(
                                  label: const Text('Parents'),
                                  selected:
                                      _selectedTarget == NotificationTarget.parent,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedTarget = NotificationTarget.parent;
                                        _selectedCategoryId = null;
                                      });
                                    }
                                  },
                                ),
                                ChoiceChip(
                                  label: const Text('Categories'),
                                  selected: _selectedTarget ==
                                      NotificationTarget.category,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedTarget =
                                            NotificationTarget.category;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            if (_selectedTarget == NotificationTarget.category) ...[
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedCategoryId,
                                decoration: const InputDecoration(
                                  labelText: 'Select Category',
                                  border: OutlineInputBorder(),
                                ),
                                items: _categories.map((category) {
                                  return DropdownMenuItem(
                                    value: category.id,
                                    child: Text(category.name),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategoryId = value;
                                  });
                                },
                                validator: (value) {
                                  if (_selectedTarget ==
                                          NotificationTarget.category &&
                                      value == null) {
                                    return 'Please select a category';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Announcement Content',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Title',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a title';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                labelText: 'Message',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                              ),
                              maxLines: 5,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a message';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _sendAnnouncement,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Send Announcement'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
