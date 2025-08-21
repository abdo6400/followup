import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService();
  final _dbService = DatabaseService();
  bool _isLoading = true;
  bool _isEditingPassword = false;
  late UserModel _currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) throw 'User not found';

      if (mounted) {
        setState(() {
          _currentUser = user;
          _nameController.text = user.name;
          _emailController.text = user.email;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Update user profile
      final updatedUser = UserModel(
        id: _currentUser.id,
        name: _nameController.text,
        email: _emailController.text,
        role: _currentUser.role,
      );

      await _dbService.updateUser(updatedUser);

      // Update password if requested
      if (_isEditingPassword && 
          _newPasswordController.text.isNotEmpty &&
          _oldPasswordController.text.isNotEmpty) {
        await _authService.updatePassword(
          _oldPasswordController.text,
          _newPasswordController.text,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        setState(() {
          _currentUser = updatedUser;
          _isEditingPassword = false;
          _oldPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
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
        title: const Text('Profile'),
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
                    // Profile Image
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            child: Text(
                              _currentUser.name[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 36,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getRoleIcon(_currentUser.role),
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Role Badge
                    Center(
                      child: Chip(
                        label: Text(
                          _getRoleLabel(_currentUser.role),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: _getRoleColor(_currentUser.role),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      enabled: false, // Email cannot be changed
                    ),
                    const SizedBox(height: 24),

                    // Password Change Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Change Password',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Switch(
                                  value: _isEditingPassword,
                                  onChanged: (value) {
                                    setState(() {
                                      _isEditingPassword = value;
                                      if (!value) {
                                        _oldPasswordController.clear();
                                        _newPasswordController.clear();
                                        _confirmPasswordController.clear();
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                            if (_isEditingPassword) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _oldPasswordController,
                                decoration: const InputDecoration(
                                  labelText: 'Current Password',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.lock),
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (_isEditingPassword &&
                                      (value == null || value.isEmpty)) {
                                    return 'Please enter your current password';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _newPasswordController,
                                decoration: const InputDecoration(
                                  labelText: 'New Password',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (_isEditingPassword) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a new password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                decoration: const InputDecoration(
                                  labelText: 'Confirm New Password',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (_isEditingPassword) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please confirm your new password';
                                    }
                                    if (value != _newPasswordController.text) {
                                      return 'Passwords do not match';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Update Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Update Profile'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.sheikh:
        return Icons.mosque;
      case UserRole.parent:
        return Icons.family_restroom;
    }
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.sheikh:
        return 'Sheikh';
      case UserRole.parent:
        return 'Parent';
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.purple;
      case UserRole.sheikh:
        return Colors.green;
      case UserRole.parent:
        return Colors.blue;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
