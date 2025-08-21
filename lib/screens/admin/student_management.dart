import 'package:flutter/material.dart';
import '../../models/student_model.dart';
import '../../models/category_model.dart';
import '../../models/sheikh_model.dart';
import '../../services/database_service.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({Key? key}) : super(key: key);

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dbService = DatabaseService();
  bool _isLoading = true;
  List<StudentModel> _students = [];
  List<CategoryModel> _categories = [];
  List<SheikhModel> _sheikhs = [];
  List<String> _selectedCategories = [];
  List<String> _selectedSheikhs = [];
  String? _selectedParentId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final categories = await _dbService.getCategories();
      final sheikhs = await _dbService.getSheikhs();
      // TODO: Replace with current user's ID if this screen is used by parents
      final students = await _dbService.getStudentsByParent('parent_id');

      if (mounted) {
        setState(() {
          _categories = categories;
          _sheikhs = sheikhs;
          _students = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
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

  void _showAddEditDialog([StudentModel? student]) {
    if (student != null) {
      _nameController.text = student.name;
      _selectedCategories = [...student.assignedCategories];
      _selectedSheikhs = [...student.assignedSheikhs];
    } else {
      _nameController.clear();
      _selectedCategories.clear();
      _selectedSheikhs.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student == null ? 'Add Student' : 'Edit Student'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text('Categories:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _categories.map((category) {
                    return FilterChip(
                      label: Text(category.name),
                      selected: _selectedCategories.contains(category.id),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategories.add(category.id);
                          } else {
                            _selectedCategories.remove(category.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Sheikhs:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _sheikhs.map((sheikh) {
                    return FilterChip(
                      label: Text(sheikh.userId), // TODO: Get sheikh name from users collection
                      selected: _selectedSheikhs.contains(sheikh.id),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSheikhs.add(sheikh.id);
                          } else {
                            _selectedSheikhs.remove(sheikh.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                if (_selectedCategories.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select at least one category'),
                    ),
                  );
                  return;
                }
                if (_selectedSheikhs.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select at least one sheikh'),
                    ),
                  );
                  return;
                }
                if (student == null) {
                  await _addStudent();
                } else {
                  await _updateStudent(student);
                }
              }
            },
            child: Text(student == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _addStudent() async {
    try {
      final student = StudentModel(
        id: '',  // Will be set by Firestore
        name: _nameController.text,
        parentId: _selectedParentId ?? 'parent_id', // TODO: Replace with actual parent ID
        assignedCategories: _selectedCategories,
        assignedSheikhs: _selectedSheikhs,
      );

      await _dbService.addStudent(student);
      if (mounted) {
        Navigator.pop(context);
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding student: $e')),
        );
      }
    }
  }

  Future<void> _updateStudent(StudentModel student) async {
    try {
      final updatedStudent = StudentModel(
        id: student.id,
        name: _nameController.text,
        parentId: student.parentId,
        assignedCategories: _selectedCategories,
        assignedSheikhs: _selectedSheikhs,
      );

      await _dbService.updateStudent(updatedStudent);
      if (mounted) {
        Navigator.pop(context);
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating student: $e')),
        );
      }
    }
  }

  Future<void> _deleteStudent(StudentModel student) async {
    try {
      await _dbService.deleteStudent(student.id);
      if (mounted) {
        await _loadData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No students found'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showAddEditDialog(),
                        child: const Text('Add Student'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ExpansionTile(
                        title: Text(student.name),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Categories:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: student.assignedCategories
                                      .map((c) => Chip(
                                            label: Text(
                                              _categories
                                                  .firstWhere(
                                                    (cat) => cat.id == c,
                                                    orElse: () => CategoryModel(
                                                      id: '',
                                                      name: 'Unknown',
                                                      description: '',
                                                    ),
                                                  )
                                                  .name,
                                            ),
                                          ))
                                      .toList(),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Sheikhs:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: student.assignedSheikhs
                                      .map((s) => Chip(
                                            label: Text(
                                              _sheikhs
                                                  .firstWhere(
                                                    (sheikh) => sheikh.id == s,
                                                    orElse: () => SheikhModel(
                                                      id: '',
                                                      userId: 'Unknown',
                                                      assignedCategories: [],
                                                      workingDays: [],
                                                      name: 'Unknown',
                                                    ),
                                                  )
                                                  .userId,
                                            ),
                                          ))
                                      .toList(),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _showAddEditDialog(student),
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Edit'),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Student'),
                                          content: Text(
                                            'Are you sure you want to delete ${student.name}?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _deleteStudent(student);
                                              },
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      ),
                                      icon: const Icon(Icons.delete),
                                      label: const Text('Delete'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
