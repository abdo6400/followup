import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:followup/models/student_model.dart';
import 'package:followup/services/database_service.dart';

final studentProvider = StateNotifierProvider<StudentNotifier, AsyncValue<List<StudentModel>>>((ref) {
  return StudentNotifier();
});

class StudentNotifier extends StateNotifier<AsyncValue<List<StudentModel>>> {
  final DatabaseService _dbService = DatabaseService();
  List<StudentModel> _allStudents = [];
  String _searchQuery = '';
  String? _selectedCategory;

  StudentNotifier() : super(const AsyncValue.loading()) {
    loadStudents();
  }

  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;

  Future<void> loadStudents() async {
    try {
      state = const AsyncValue.loading();
      _allStudents = await _dbService.getAllStudents();
      _filterStudents();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _filterStudents();
  }

  void setSelectedCategory(String? categoryId) {
    _selectedCategory = categoryId;
    _filterStudents();
  }

  void _filterStudents() {
    if (_allStudents.isEmpty) return;
    
    var filtered = _allStudents;
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((student) => 
        student.name.toLowerCase().contains(_searchQuery)
      ).toList();
    }
    
    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((student) => 
        student.assignedCategories.contains(_selectedCategory)
      ).toList();
    }
    
    state = AsyncValue.data(filtered);
  }

  Future<void> addStudent(StudentModel student) async {
    try {
      await _dbService.addStudent(student);
      await loadStudents();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateStudent(StudentModel student) async {
    try {
      await _dbService.updateStudent(student);
      await loadStudents();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteStudent(String studentId) async {
    try {
      await _dbService.deleteStudent(studentId);
      await loadStudents();
    } catch (e) {
      rethrow;
    }
  }
}
