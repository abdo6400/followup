import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/sheikh_model.dart';
import '../../../providers/sheikh_provider.dart';


// Simple validation helper
class Validators {
  static String? required(String? value, String message) {
    if (value == null || value.isEmpty) {
      return message;
    }
    return null;
  }

  static String? minLength(String? value, int length, String message) {
    if (value != null && value.length < length) {
      return message;
    }
    return null;
  }

  static String? email(String? value, String message) {
    if (value == null || value.isEmpty) return message;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return message;
    }
    return null;
  }
}

// Working days list
final List<String> workingDays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

class SheikhManagementScreen extends ConsumerWidget {
  const SheikhManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: const _SheikhList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SheikhList extends ConsumerWidget {
  const _SheikhList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sheikhsAsync = ref.watch(sheikhProvider);

    return sheikhsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text('Error: ${error.toString()}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(sheikhProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (sheikhs) => sheikhs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No sheikhs found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showAddEditDialog(context, ref),
                    child: const Text('Add Sheikh'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: sheikhs.length,
              itemBuilder: (context, index) {
                final sheikh = sheikhs[index];
                return _SheikhItem(sheikh: sheikh);
              },
            ),
    );
  }
}

class _SheikhItem extends ConsumerWidget {
  final SheikhModel sheikh;

  const _SheikhItem({required this.sheikh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(sheikh.name),
        subtitle: Text('Categories: ${sheikh.assignedCategories.join(", ")}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Working Days:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(sheikh.workingDays.map((day) => workingDays[day - 1]).join(', ')),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      onPressed: () => _showAddEditDialog(context, ref, sheikh),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () => _confirmDelete(context, ref, sheikh),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, SheikhModel sheikh) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sheikh'),
        content: Text('Are you sure you want to delete ${sheikh.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(sheikhProvider.notifier).deleteSheikh(sheikh);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Sheikh deleted successfully')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting sheikh: $e')));
        }
      }
    }
  }
}

Future<void> _showAddEditDialog(BuildContext context, WidgetRef ref, [SheikhModel? sheikh]) async {
  final nameController = TextEditingController(text: sheikh?.name ?? '');
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // Initialize selected values
  final selectedCategories = <String>[...sheikh?.assignedCategories ?? []];
  final selectedWorkingDays = <String>{
    for (final day in sheikh?.workingDays ?? []) workingDays[day - 1],
  };

  // Form validation
  String? validateName(String? value) {
    return Validators.required(value, 'Name is required') ??
        Validators.minLength(value, 3, 'Name must be at least 3 characters');
  }

  String? validatePassword(String? value) {
    if (sheikh != null && (value == null || value.isEmpty)) {
      return null; // Password is optional for editing
    }
    return Validators.required(value, 'Password is required') ??
        Validators.minLength(value, 6, 'Password must be at least 6 characters');
  }

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(sheikh == null ? 'Add Sheikh' : 'Edit Sheikh'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: validateName,
                ),
                const SizedBox(height: 16),

                if (sheikh == null) ...[
                  // Only show password for new sheikhs
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: validatePassword,
                  ),
                  const SizedBox(height: 16),
                ],

                const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                // TODO: Add category selection
                const Text('Working Days', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: workingDays
                      .map(
                        (day) => FilterChip(
                          label: Text(day),
                          selected: selectedWorkingDays.contains(day),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedWorkingDays.add(day);
                              } else {
                                selectedWorkingDays.remove(day);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                if (selectedWorkingDays.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select at least one working day')),
                  );
                  return;
                }
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );

  if (result == true) {
    try {
      // Convert working days from names to numbers (1-7)
      final workingDayNumbers = selectedWorkingDays
          .map((day) => workingDays.indexOf(day) + 1)
          .toSet();

      try {
        if (sheikh == null) {
          // Add new sheikh
          await ref
              .read(sheikhProvider.notifier)
              .addSheikh(
                name: nameController.text.trim(),
                email:
                    '${nameController.text.trim().toLowerCase().replaceAll(' ', '.')}@example.com',
                password: passwordController.text,
                categories: selectedCategories,
                workingDays: selectedWorkingDays,
              );
        } else {
          // Update existing sheikh - create a new instance with updated values
          final updatedSheikh = SheikhModel(
            id: sheikh.id,
            userId: sheikh.userId,
            name: nameController.text.trim(),
            assignedCategories: selectedCategories,
            workingDays: workingDayNumbers.toList(),
          );
          await ref.read(sheikhProvider.notifier).updateSheikh(updatedSheikh);
        }
      } on FirebaseException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Firebase Error: ${e.message}')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('An unexpected error occurred')));
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sheikh ${sheikh == null ? 'added' : 'updated'} successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }
}
