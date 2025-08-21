import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/category_model.dart';
import '../../models/student_model.dart';
import '../../models/task_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

class SheikhDashboard extends StatefulWidget {
  const SheikhDashboard({Key? key}) : super(key: key);

  @override
  State<SheikhDashboard> createState() => _SheikhDashboardState();
}

class _SheikhDashboardState extends State<SheikhDashboard> {
  final _authService = AuthService();
  final _dbService = DatabaseService();
  bool _isLoading = true;
  late UserModel _currentSheikh;
  List<CategoryModel> _assignedCategories = [];
  List<StudentModel> _assignedStudents = [];
  List<TaskModel> _availableTasks = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final sheikh = await _authService.getCurrentUser();
      if (sheikh == null || sheikh.role != UserRole.sheikh) {
        throw 'Invalid user or role';
      }
      _currentSheikh = sheikh;

      // Load assigned categories
      final sheikhData = await _dbService.getSheikhByUserId(sheikh.id);
      if (sheikhData == null) throw 'Sheikh data not found';
      
      final categories = await _dbService.getCategories();
      final assignedCategories = categories.where(
        (c) => sheikhData.assignedCategories.contains(c.id)
      ).toList();
      
      // Load assigned students
      final students = await _dbService.getStudentsBySheikh(sheikhData.id);

      // Load available tasks
      final tasks = await _dbService.getTasks();

      if (mounted) {
        setState(() {
          _assignedCategories = assignedCategories;
          _assignedStudents = students;
          _availableTasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
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
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48),
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

  Future<bool> _isWorkingDay() async {
    try {
      final sheikh = await _authService.getCurrentUser();
      if (sheikh == null) return false;
      
      final sheikhData = await _dbService.getSheikhByUserId(sheikh.id);
      if (sheikhData == null) return false;

      final today = DateTime.now();
      final weekday = today.weekday; // 1 = Monday, 7 = Sunday
      
      return sheikhData.workingDays.contains(weekday);
    } catch (e) {
      print('Error checking working day: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sheikh Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Welcome, ${_currentSheikh.name}',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            FutureBuilder<bool>(
                              future: _isWorkingDay(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final isWorkingDay = snapshot.data!;
                                  return Text(
                                    isWorkingDay
                                        ? 'Today is your working day'
                                        : 'Today is not your working day',
                                    style: TextStyle(
                                      color: isWorkingDay ? Colors.green : Colors.red,
                                    ),
                                  );
                                }
                                return const CircularProgressIndicator();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                          count: _assignedCategories.length,
                          onTap: () {
                            // TODO: Navigate to categories screen
                          },
                        ),
                        _buildDashboardItem(
                          title: 'Students',
                          icon: Icons.people,
                          count: _assignedStudents.length,
                          onTap: () {
                            // TODO: Navigate to students screen
                          },
                        ),
                        _buildDashboardItem(
                          title: 'Tasks',
                          icon: Icons.assignment,
                          count: _availableTasks.length,
                          onTap: () {
                            // TODO: Navigate to tasks screen
                          },
                        ),
                        _buildDashboardItem(
                          title: 'Today\'s Attendance',
                          icon: Icons.how_to_reg,
                          count: 0, // TODO: Get today's attendance count
                          onTap: () {
                            // TODO: Navigate to attendance screen
                          },
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
                            onPressed: () {
                              // TODO: Navigate to take attendance screen
                            },
                            icon: const Icon(Icons.how_to_reg),
                            label: const Text('Take Attendance'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Navigate to mark tasks screen
                            },
                            icon: const Icon(Icons.assignment_turned_in),
                            label: const Text('Mark Tasks'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
