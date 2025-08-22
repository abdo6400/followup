import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/sheikh_model.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final String _adminEmail = 'admin@followup.com';
  final String _adminPassword = 'admin123456';

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Stream of user changes
  Stream<UserModel?> get userChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  // Initialize admin account
  Future<void> initializeAdmin() async {
    try {
      // Check if admin exists
      final adminQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (adminQuery.docs.isEmpty) {
        // Create admin account
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _adminEmail,
          password: _adminPassword,
        );

        final adminModel = UserModel(
          id: userCredential.user!.uid,
          name: 'Admin',
          email: _adminEmail,
          role: UserRole.admin,
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(adminModel.toMap());
      }
    } catch (e) {
      print('Admin initialization error: $e');
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) return null;
        if (doc.exists) {
          return UserModel.fromFirestore(doc);
        }
      } catch (e) {
        print('Error getting current user: $e');
      }
    }
    return null;
  }

  Future<void> updatePassword(String oldPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw 'No user signed in';
    }

    try {
      // Re-authenticate user before updating password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
            throw 'Current password is incorrect';
          default:
            throw 'Error updating password: ${e.message}';
        }
      }
      throw 'Error updating password: $e';
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  Future<UserModel> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      if (!doc.exists) {
        throw Exception('User data not found');
      }
      
      return UserModel.fromFirestore(doc);
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  Future<UserModel?> registerParent(
    String email,
    String password,
    String name,
  ) async {
    try {
      // Check if email is already registered
      final existingUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw 'A user with this email already exists.';
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userModel = UserModel(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        role: UserRole.parent,
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userModel.toMap());

      return userModel;
    } catch (e) {
      print('Registration error: $e');
      throw 'An error occurred during registration.';
    }
  }

  Future<UserModel?> createSheikhAccount(
    String email,
    String password,
    String name,
    List<String> assignedCategories,
    List<String> workingDays,
  ) async {
    try {
      // Only admin can create sheikh accounts
      final currentUser = await getCurrentUser();
      if (currentUser?.role != UserRole.admin) {
        throw 'Only admin can create sheikh accounts.';
      }

      // Create user account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userModel = UserModel(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        role: UserRole.sheikh,
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userModel.toMap());

      // Create sheikh profile
      final Map<String, int> nameToWeekday = {
        'Monday': 1,
        'Tuesday': 2,
        'Wednesday': 3,
        'Thursday': 4,
        'Friday': 5,
        'Saturday': 6,
        'Sunday': 7,
      };
      final normalizedWorkingDays = workingDays
          .map((d) => nameToWeekday[d] ?? 0)
          .where((v) => v > 0)
          .toList();

      final sheikhModel = SheikhModel(
        id: '', // Will be set by Firestore
        userId: userCredential.user!.uid,
        assignedCategories: assignedCategories,
        workingDays: normalizedWorkingDays,
        name: name,
      );

      await _firestore.collection('sheikhs').add(sheikhModel.toMap());

      return userModel;
    } catch (e) {
      print('Error creating sheikh account: $e');
      throw 'An error occurred while creating the sheikh account.';
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('Password reset error: ${e.message}');
      rethrow;
    }
  }

  // User management
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> deleteUser(String userId) async {
    try {
      // Delete from Firestore first
      await _firestore.collection('users').doc(userId).delete();
      
      // Get current user
      final user = _auth.currentUser;
      
      // If the user to delete is the current user, delete from Firebase Auth
      if (user != null && user.uid == userId) {
        await user.delete();
      }
    } catch (e) {
      print('Error deleting user: $e');
      throw 'An error occurred while deleting the user account.';
    }
  }
}
