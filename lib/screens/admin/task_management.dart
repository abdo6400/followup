import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../models/category_model.dart';
import '../../services/database_service.dart';

class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({Key? key}) : super(key: key);

  @override
  State<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _maxPointsController = TextEditingController();
  final _dbService = DatabaseService();
  bool _isLoading = true;
  List<TaskModel> _tasks = [];
  List<CategoryModel> _categories = [];
  String? _selectedCategoryId;
  TaskType _selectedTaskType = TaskType.points;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final tasks = await _dbService.getTasks();
      final categories = await _dbService.getCategories();

      if (mounted) {
        setState(() {
          _tasks = tasks;
          _categories = categories;
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

  void _showAddEditDialog([TaskModel? task]) {
    if (task != null) {
      _titleController.text = task.title;
      _maxPointsController.text = task.maxPoints.toString();
      _selectedCategoryId = task.categoryId;
      _selectedTaskType = task.type;
    } else {
      _titleController.clear();
      _maxPointsController.text = '10';
      _selectedCategoryId = null;
      _selectedTaskType = TaskType.points;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task == null ? 'Add Task' : 'Edit Task'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                DropdownButtonFormField<TaskType>(
                  value: _selectedTaskType,
                  decoration: const InputDecoration(
                    labelText: 'Task Type',
                    border: OutlineInputBorder(),
                  ),
                  items: TaskType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        type.toString().split('.').last,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedTaskType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (_selectedTaskType == TaskType.points ||
                    _selectedTaskType == TaskType.custom)
                  TextFormField(
                    controller: _maxPointsController,
                    decoration: const InputDecoration(
                      labelText: 'Maximum Points',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter maximum points';
                      }
                      final points = int.tryParse(value);
                      if (points == null || points <= 0) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('None'),
                    ),
                    ..._categories.map((category) {
                      return DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
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
                if (task == null) {
                  await _addTask();
                } else {
                  await _updateTask(task);
                }
              }
            },
            child: Text(task == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _addTask() async {
    try {
      final task = TaskModel(
        id: '',  // Will be set by Firestore
        title: _titleController.text,
        type: _selectedTaskType,
        categoryId: _selectedCategoryId,
        maxPoints: int.parse(_maxPointsController.text),
      );

      await _dbService.addTask(task);
      if (mounted) {
        Navigator.pop(context);
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding task: $e')),
        );
      }
    }
  }

  Future<void> _updateTask(TaskModel task) async {
    try {
      final updatedTask = TaskModel(
        id: task.id,
        title: _titleController.text,
        type: _selectedTaskType,
        categoryId: _selectedCategoryId,
        maxPoints: int.parse(_maxPointsController.text),
      );

      await _dbService.updateTask(updatedTask);
      if (mounted) {
        Navigator.pop(context);
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating task: $e')),
        );
      }
    }
  }

  Future<void> _deleteTask(TaskModel task) async {
    try {
      await _dbService.deleteTask(task.id);
      if (mounted) {
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting task: $e')),
        );
      }
    }
  }

  String _getTaskTypeLabel(TaskType type) {
    switch (type) {
      case TaskType.points:
        return 'Points';
      case TaskType.yesNo:
        return 'Yes/No';
      case TaskType.custom:
        return 'Custom';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Management'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No tasks found'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showAddEditDialog(),
                        child: const Text('Add Task'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(task.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Type: ${_getTaskTypeLabel(task.type)}'),
                            if (task.categoryId != null)
                              Text(
                                'Category: ${_categories.firstWhere((c) => c.id == task.categoryId).name}',
                              ),
                            if (task.type != TaskType.yesNo)
                              Text('Max Points: ${task.maxPoints}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showAddEditDialog(task),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Task'),
                                  content: Text(
                                    'Are you sure you want to delete ${task.title}?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _deleteTask(task);
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
                        isThreeLine: true,
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
    _titleController.dispose();
    _maxPointsController.dispose();
    super.dispose();
  }
}
