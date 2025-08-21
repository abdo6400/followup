import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/sheikh_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _adminEmail = 'admin@followup.com'; // You can change this
  final String _adminPassword = 'admin123456'; // You can change this

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
      // Clear any cached user data here if needed
    } catch (e) {
      print('Error signing out: $e');
      throw 'An error occurred while signing out.';
    }
  }

  Future<UserModel?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final doc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        return UserModel.fromFirestore(doc);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        throw 'Wrong password provided.';
      }
    } catch (e) {
      print('Sign in error: $e');
      throw 'An error occurred while signing in.';
    }
    return null;
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
    } catch (e) {
      print('Password reset error: $e');
      throw 'An error occurred while sending the password reset email.';
    }
  }
}
