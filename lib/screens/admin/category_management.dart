import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../models/sheikh_model.dart';
import '../../models/student_model.dart';
import '../../services/database_service.dart';


class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({Key? key}) : super(key: key);

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dbService = DatabaseService();
  bool _isLoading = true;
  List<CategoryModel> _categories = [];
  List<SheikhModel> _sheikhs = [];
  List<StudentModel> _students = [];
  CategoryModel? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final futures = await Future.wait([
        _dbService.getCategories(),
        _dbService.getSheikhs(),
        _dbService.getAllStudents(),
      ]);
      
      if (mounted) {
        setState(() {
          _categories = futures[0] as List<CategoryModel>;
          _sheikhs = futures[1] as List<SheikhModel>;
          _students = futures[2] as List<StudentModel>;
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

  void _showAddEditDialog([CategoryModel? category]) {
    _selectedCategory = category;
    if (category != null) {
      _nameController.text = category.name;
      _descriptionController.text = category.description;
    } else {
      _nameController.clear();
      _descriptionController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Add Category' : 'Edit Category'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
            ],
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
                if (category == null) {
                  await _addCategory();
                } else {
                  await _updateCategory();
                }
              }
            },
            child: Text(category == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _addCategory() async {
    try {
      final category = CategoryModel(
        id: '',  // Will be set by Firestore
        name: _nameController.text,
        description: _descriptionController.text,
      );

      await _dbService.addCategory(category);
      if (mounted) {
        Navigator.pop(context);
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding category: $e')),
        );
      }
    }
  }

  Future<void> _updateCategory() async {
    if (_selectedCategory == null) return;

    try {
      final category = CategoryModel(
        id: _selectedCategory!.id,
        name: _nameController.text,
        description: _descriptionController.text,
      );

      await _dbService.updateCategory(category);
      if (mounted) {
        Navigator.pop(context);
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating category: $e')),
        );
      }
    }
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    try {
      await _dbService.deleteCategory(category.id);
      if (mounted) {
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting category: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No categories found'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showAddEditDialog(),
                        child: const Text('Add Category'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ExpansionTile(
                        title: Text(category.name),
                        subtitle: Text(category.description),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.people),
                              onPressed: () => _showAssignmentsDialog(category),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showAddEditDialog(category),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Category'),
                                  content: Text(
                                    'Are you sure you want to delete ${category.name}?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _deleteCategory(category);
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
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

  void _showAssignmentsDialog(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage ${category.name} Assignments'),
        content: SizedBox(
          width: double.maxFinite,
          child: DefaultTabController(
            length: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Students'),
                    Tab(text: 'Sheikhs'),
                  ],
                ),
                SizedBox(
                  height: 300,
                  child: TabBarView(
                    children: [
                      _buildStudentsList(category),
                      _buildSheikhsList(category),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList(CategoryModel category) {
    final assignedStudents = _students.where(
      (s) => s.assignedCategories.contains(category.id)
    ).toList();
    final unassignedStudents = _students.where(
      (s) => !s.assignedCategories.contains(category.id)
    ).toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              const ListTile(
                title: Text('Assigned Students', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ...assignedStudents.map((student) => ListTile(
                title: Text(student.name),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => _updateStudentAssignment(
                    student, category.id, false),
                ),
              )),
              const Divider(),
              const ListTile(
                title: Text('Available Students', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ...unassignedStudents.map((student) => ListTile(
                title: Text(student.name),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _updateStudentAssignment(
                    student, category.id, true),
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSheikhsList(CategoryModel category) {
    final assignedSheikhs = _sheikhs.where(
      (s) => s.assignedCategories.contains(category.id)
    ).toList();
    final unassignedSheikhs = _sheikhs.where(
      (s) => !s.assignedCategories.contains(category.id)
    ).toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              const ListTile(
                title: Text('Assigned Sheikhs', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ...assignedSheikhs.map((sheikh) => ListTile(
                title: Text(sheikh.name),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => _updateSheikhAssignment(
                    sheikh, category.id, false),
                ),
              )),
              const Divider(),
              const ListTile(
                title: Text('Available Sheikhs', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ...unassignedSheikhs.map((sheikh) => ListTile(
                title: Text(sheikh.name),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _updateSheikhAssignment(
                    sheikh, category.id, true),
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _updateStudentAssignment(
    StudentModel student, String categoryId, bool assign) async {
    try {
      final updatedStudent = StudentModel(
        id: student.id,
        name: student.name,
        parentId: student.parentId,
        assignedCategories: assign 
          ? [...student.assignedCategories, categoryId]
          : student.assignedCategories.where((id) => id != categoryId).toList(),
        assignedSheikhs: student.assignedSheikhs,
      );
      await _dbService.updateStudent(updatedStudent);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating student assignment: $e')),
        );
      }
    }
  }

  Future<void> _updateSheikhAssignment(
    SheikhModel sheikh, String categoryId, bool assign) async {
    try {
      final updatedSheikh = SheikhModel(
        id: sheikh.id,
        userId: sheikh.userId,
        name: sheikh.name,
        assignedCategories: assign 
          ? [...sheikh.assignedCategories, categoryId]
          : sheikh.assignedCategories.where((id) => id != categoryId).toList(),
        workingDays: sheikh.workingDays,
      );
      await _dbService.updateSheikh(updatedSheikh);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating sheikh assignment: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

