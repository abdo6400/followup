import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:followup/models/category_model.dart';
import 'package:followup/services/database_service.dart';

final categoryProvider = StateNotifierProvider<CategoryNotifier, AsyncValue<List<CategoryModel>>>((ref) {
  return CategoryNotifier();
});

class CategoryNotifier extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  final DatabaseService _dbService = DatabaseService();
  List<CategoryModel> _allCategories = [];
  String _searchQuery = '';

  CategoryNotifier() : super(const AsyncValue.loading()) {
    _loadCategories();
  }

  String get searchQuery => _searchQuery;

  Future<void> _loadCategories() async {
    try {
      state = const AsyncValue.loading();
      _allCategories = await _dbService.getCategories();
      _filterCategories();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void setSearchQuery(String query) {
    final newQuery = query.trim().toLowerCase();
    if (_searchQuery != newQuery) {
      _searchQuery = newQuery;
      _filterCategories();
    }
  }

  void _filterCategories() {
    if (_allCategories.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    var filtered = _allCategories;
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((category) => 
        category.name.toLowerCase().contains(_searchQuery) ||
        (category.description?.toLowerCase().contains(_searchQuery) ?? false)
      ).toList();
    }
    
    state = AsyncValue.data(List.from(filtered));
  }

  Future<void> addCategory(String name, String description) async {
    try {
      state = const AsyncValue.loading();
      final category = CategoryModel(name: name, description: description,id: DateTime.now().toString() );
      final newCategory = await _dbService.addCategory(category);
      _allCategories.add(category);
      _filterCategories();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    try {
      state = const AsyncValue.loading();
      await _dbService.updateCategory(category);
      final index = _allCategories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _allCategories[index] = category;
        _filterCategories();
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      state = const AsyncValue.loading();
      await _dbService.deleteCategory(categoryId);
      _allCategories.removeWhere((category) => category.id == categoryId);
      _filterCategories();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}