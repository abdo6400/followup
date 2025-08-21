import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import './category_management.dart';
import './sheikh_management.dart';
import './student_management.dart';
import './task_management.dart';
import './report_screen.dart';
import './admin_notification_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _authService = AuthService();
  final _dbService = DatabaseService();
  bool _isLoading = true;
  int _categoryCount = 0;
  int _sheikhCount = 0;
  int _studentCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final categories = await _dbService.getCategories();
      final sheikhs = await _dbService.getSheikhs();
      final students = await _dbService.getTasks();

      if (mounted) {
        setState(() {
          _categoryCount = categories.length;
          _sheikhCount = sheikhs.length;
          _studentCount = students.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  Widget _buildDashboardItem({
    required String title,
    required IconData icon,
    required int count,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: color ?? Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildDashboardItem(
                        title: 'Categories',
                        icon: Icons.category,
                        count: _categoryCount,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CategoryManagementScreen(),
                          ),
                        ),
                      ),
                      _buildDashboardItem(
                        title: 'Sheikhs',
                        icon: Icons.people,
                        count: _sheikhCount,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SheikhManagementScreen(),
                          ),
                        ),
                      ),
                      _buildDashboardItem(
                        title: 'Students',
                        icon: Icons.school,
                        count: _studentCount,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StudentManagementScreen(),
                          ),
                        ),
                      ),
                      _buildDashboardItem(
                        title: 'Tasks',
                        icon: Icons.task,
                        count: 0,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TaskManagementScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReportScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.assessment),
                          label: const Text('View Reports'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminNotificationScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.announcement),
                          label: const Text('Announcements'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
