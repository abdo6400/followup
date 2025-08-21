import 'package:flutter/material.dart';
import '../../models/sheikh_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

class SheikhManagementScreen extends StatefulWidget {
  const SheikhManagementScreen({Key? key}) : super(key: key);

  @override
  State<SheikhManagementScreen> createState() => _SheikhManagementScreenState();
}

class _SheikhManagementScreenState extends State<SheikhManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _dbService = DatabaseService();
  bool _isLoading = true;
  List<SheikhModel> _sheikhs = [];
  List<String> _categories = [];
  List<String> _selectedCategories = [];
  final _workingDays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  final _selectedWorkingDays = <String>{};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final sheikhs = await _dbService.getSheikhs();
      final categories = await _dbService.getCategories();

      if (mounted) {
        setState(() {
          _sheikhs = sheikhs;
          _categories = categories.map((c) => c.name).toList();
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

  void _showAddSheikhDialog() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _selectedCategories.clear();
    _selectedWorkingDays.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Sheikh'),
        content: SingleChildScrollView(
          child: Form(
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
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
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
                      label: Text(category),
                      selected: _selectedCategories.contains(category),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategories.add(category);
                          } else {
                            _selectedCategories.remove(category);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Working Days:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _workingDays.map((day) {
                    return FilterChip(
                      label: Text(day),
                      selected: _selectedWorkingDays.contains(day),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedWorkingDays.add(day);
                          } else {
                            _selectedWorkingDays.remove(day);
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
                if (_selectedWorkingDays.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select working days'),
                    ),
                  );
                  return;
                }
                await _addSheikh();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addSheikh() async {
    try {
      final userModel = await _authService.createSheikhAccount(
        _emailController.text,
        _passwordController.text,
        _nameController.text,
        _selectedCategories,
        _selectedWorkingDays.toList(),
      );

      if (userModel != null && mounted) {
        Navigator.pop(context);
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sheikh added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding sheikh: $e')),
        );
      }
    }
  }

  Future<void> _deleteSheikh(SheikhModel sheikh) async {
    try {
      await _dbService.deleteSheikh(sheikh.id);
      if (mounted) {
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sheikh deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting sheikh: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sheikh Management'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sheikhs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No sheikhs found'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showAddSheikhDialog,
                        child: const Text('Add Sheikh'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _sheikhs.length,
                  itemBuilder: (context, index) {
                    final sheikh = _sheikhs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ExpansionTile(
                        title: Text(sheikh.name),
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
                                  children: sheikh.assignedCategories
                                      .map((c) => Chip(label: Text(c)))
                                      .toList(),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Working Days:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: sheikh.workingDays
                                      .map((d) => Chip(label: Text(d.toString())))
                                      .toList(),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Sheikh'),
                                          content: Text(
                                            'Are you sure you want to delete this sheikh?',
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
                                                _deleteSheikh(sheikh);
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
        onPressed: _showAddSheikhDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
