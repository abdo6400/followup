import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sheikh_model.dart';
import '../models/category_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

final sheikhProvider = StateNotifierProvider<SheikhNotifier, AsyncValue<List<SheikhModel>>>((ref) {
  return SheikhNotifier();
});

class SheikhNotifier extends StateNotifier<AsyncValue<List<SheikhModel>>> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  SheikhNotifier() : super(const AsyncValue.loading()) {
    loadSheikhs();
  }

  Future<void> loadSheikhs() async {
    try {
      state = const AsyncValue.loading();
      final sheikhs = await _dbService.getSheikhs();
      state = AsyncValue.data(sheikhs);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> addSheikh({
    required String name,
    required String email,
    required String password,
    required List<String> categories,
    required Set<String> workingDays,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      // Convert working day names to numbers (1-7)
      final workingDayNumbers = workingDays.map((day) {
        final Map<String, int> nameToWeekday = {
          'Monday': 1,
          'Tuesday': 2,
          'Wednesday': 3,
          'Thursday': 4,
          'Friday': 5,
          'Saturday': 6,
          'Sunday': 7,
        };
        return nameToWeekday[day]!;
      }).toList();

      // Create user account first
      final userCredential = await _authService.createUserWithEmailAndPassword(email, password);
      
      // Create sheikh profile
      final sheikh = SheikhModel(
        id: '', // Will be set by Firestore
        userId: userCredential.user!.uid,
        name: name,
        assignedCategories: categories,
        workingDays: workingDayNumbers,
      );

      await _dbService.addSheikh(sheikh);
      await loadSheikhs(); // Refresh the list
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateSheikh(SheikhModel sheikh) async {
    try {
      state = const AsyncValue.loading();
      await _dbService.updateSheikh(sheikh);
      await loadSheikhs(); // Refresh the list
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> deleteSheikh(SheikhModel sheikh) async {
    try {
      state = const AsyncValue.loading();
      await _dbService.deleteSheikh(sheikh.id);
      await _authService.deleteUser(sheikh.userId);
      await loadSheikhs(); // Refresh the list
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

// Provider for categories
final categoriesProvider = FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final dbService = DatabaseService();
  return await dbService.getCategories();
});

// Provider for working days
final workingDaysProvider = Provider<List<String>>((ref) {
  return const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
});
