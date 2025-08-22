import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:followup/providers/admin_provider.dart';
import 'package:followup/providers/auth_provider.dart';
import 'package:followup/providers/category_provider.dart' as category_provider;
import 'package:followup/providers/sheikh_provider.dart';
import 'package:followup/providers/student_provider.dart';
import 'package:followup/screens/admin/category_management_screen.dart';
import 'package:followup/screens/admin/student_management_screen.dart';
import 'package:followup/widgets/error_widget.dart' as error_widget;
import 'package:followup/widgets/loading_indicator.dart';

import 'sheikh_management.dart';
import 'task_management.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(adminTabProvider);
    final dashboardData = ref.watch(adminDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(currentTab)),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout)],
      ),
      body: _buildBody(currentTab, dashboardData),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentTab.index,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => _onTabTapped(index, ref),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Sheikhs'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Students'),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
        ],
      ),
    );
  }

  String _getTitle(AdminTab tab) {
    switch (tab) {
      case AdminTab.dashboard:
        return 'Dashboard';
      case AdminTab.categories:
        return 'Categories';
      case AdminTab.sheikhs:
        return 'Sheikhs';
      case AdminTab.students:
        return 'Students';
      case AdminTab.tasks:
        return 'Tasks';
      case AdminTab.reports:
        return 'Reports';
    }
  }

  Widget _buildBody(AdminTab tab, AsyncValue<Map<String, int>> dashboardData) {
    // Preload data for all tabs
    ref.read(category_provider.categoryProvider);
    ref.read(sheikhProvider);
    ref.read(studentProvider);

    if (tab != AdminTab.dashboard) {
      return _buildTabContent(tab);
    }

    return dashboardData.when(
      data: (data) => _buildDashboard(data),
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, stack) => error_widget.AppErrorWidget(message: error.toString()),
    );
  }

  Widget _buildDashboard(Map<String, int> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard('Categories', data['categories'] ?? 0, Icons.category, Colors.blue),
              _buildStatCard('Sheikhs', data['sheikhs'] ?? 0, Icons.people, Colors.green),
              _buildStatCard('Students', data['students'] ?? 0, Icons.school, Colors.orange),
              _buildStatCard('Tasks', data['tasks'] ?? 0, Icons.task, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 35, color: color),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(AdminTab tab) {
    switch (tab) {
      case AdminTab.categories:
        return const CategoryManagementScreen();
      case AdminTab.sheikhs:
        return const SheikhManagementScreen();
      case AdminTab.students:
        return const StudentManagementScreen();
      case AdminTab.tasks:
        return const TaskManagementScreen();
      default:
        return const Center(child: Text('Coming soon...'));
    }
  }

  void _onTabTapped(int index, WidgetRef ref) {
    ref.read(adminTabProvider.notifier).state = AdminTab.values[index];
  }

  Future<void> _handleLogout() async {
    try {
      await ref.read(authControllerProvider.notifier).signOut();
      // Navigate to login screen and remove all previous routes
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
