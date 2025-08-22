import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/student_model.dart';
import '../../../models/sheikh_model.dart';
import '../../../models/category_model.dart';
import '../../../providers/student_provider.dart';
import '../../../providers/sheikh_provider.dart' as sheikh_provider;
import '../../../providers/category_provider.dart' as category_provider;
import '../../../widgets/loading_indicator.dart';
import '../../../widgets/error_widget.dart' as error_widget;

class StudentManagementScreen extends ConsumerStatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  ConsumerState<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends ConsumerState<StudentManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentState = ref.watch(studentProvider);
    final categories = ref.watch(category_provider.categoryProvider);

    return Scaffold(
      body: Column(
        children: [
          _buildSearchAndFilter(categories),
          const SizedBox(height: 8),
          Expanded(
            child: studentState.when(
              data: (students) => _buildStudentList(students),
              loading: () => const Center(child: LoadingIndicator()),
              error: (error, stack) => error_widget.AppErrorWidget(message: error.toString()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditStudentDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchAndFilter(AsyncValue<List<CategoryModel>> categories) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search students...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  ref.read(studentProvider.notifier).setSearchQuery('');
                },
              ),
            ),
            onChanged: (value) => ref.read(studentProvider.notifier).setSearchQuery(value),
          ),
          const SizedBox(height: 8),
          categories.when(
            data: (categories) => DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Filter by Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Categories')),
                ...categories.map((category) => DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    )),
              ],
              onChanged: (value) {
                setState(() => _selectedCategory = value);
                ref.read(studentProvider.notifier).setSelectedCategory(value);
              },
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Error loading categories'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(List<StudentModel> students) {
    if (students.isEmpty) {
      return const Center(child: Text('No students found'));
    }

    return ListView.builder(
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return _buildStudentCard(student);
      },
    );
  }

  Widget _buildStudentCard(StudentModel student) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        title: Text(
          student.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('ID: ${student.id.substring(0, 8)}...'),
        children: [
          _buildStudentDetails(student),
          _buildActionButtons(student),
        ],
      ),
    );
  }

 Widget _buildStudentDetails(StudentModel student) {
  final sheikhs = ref.watch(sheikh_provider.sheikhProvider);
  final categories = ref.watch(category_provider.categoryProvider);

  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        categories.when(
          data: (categoryList) => _buildDetailSection('Categories', student.assignedCategories, AsyncValue.data(categoryList)),
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => Text('Error: $error'),
        ),
        const SizedBox(height: 16),
        sheikhs.when(
          data: (sheikhList) => _buildSheikhsSection('Assigned Sheikhs', student.assignedSheikhs, AsyncValue.data(sheikhList)),
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => Text('Error: $error'),
        ),
      ],
    ),
  );
}

Widget _buildDetailSection(String title, List<String> items, AsyncValue<List<dynamic>> data) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$title:',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      const SizedBox(height: 8),
      data.when(
        data: (allItems) {
          final itemNames = items.map((id) {
            try {
              final item = allItems.firstWhere(
                (item) => item.id == id,
                orElse: () => null,
              );
              return item?.name ?? 'Unknown';
            } catch (e) {
              return 'Unknown';
            }
          }).toList();

          return Wrap(
            spacing: 8,
            runSpacing: 4,
            children: itemNames
                .map((name) => Chip(
                      label: Text(name),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    ))
                .toList(),
          );
        },
        loading: () => const CircularProgressIndicator(),
        error: (_, __) => const Text('Error loading data'),
      ),
    ],
  );
}

Widget _buildSheikhsSection(String title, List<String> sheikhIds, AsyncValue<List<dynamic>> sheikhs) {
  return sheikhs.when(
    data: (allSheikhs) {
      final assignedSheikhs = allSheikhs
          .where((sheikh) => sheikhIds.contains(sheikh.id))
          .map((e) => e.name)
          .toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: assignedSheikhs
                .map((name) => Chip(
                      label: Text(name),
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    ))
                .toList(),
          ),
        ],
      );
    },
    loading: () => const CircularProgressIndicator(),
    error: (_, __) => const Text('Error loading sheikhs'),
  );
}

  Widget _buildActionButtons(StudentModel student) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
            onPressed: () => _showAddEditStudentDialog(student: student),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () => _confirmDelete(student),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEditStudentDialog({StudentModel? student}) async {
    // Implementation of add/edit dialog
    // This would include a form with fields for student details,
    // category selection, and sheikh assignment
    // Similar to the previous implementation but with better state management
  }

  Future<void> _confirmDelete(StudentModel student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(studentProvider.notifier).deleteStudent(student.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting student: $e')),
          );
        }
      }
    }
  }
}
