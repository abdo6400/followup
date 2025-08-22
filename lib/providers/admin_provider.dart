import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:followup/services/database_service.dart';

final adminDashboardProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final dbService = DatabaseService();
  
  final counts = await Future.wait([
    dbService.getCategories().then((list) => list.length),
    dbService.getSheikhs().then((list) => list.length),
    dbService.getAllStudents().then((list) => list.length),
    dbService.getTasks().then((list) => list.length),
  ]);

  return {
    'categories': counts[0],
    'sheikhs': counts[1],
    'students': counts[2],
    'tasks': counts[3],
  };
});

enum AdminTab { dashboard, categories, sheikhs, students, tasks, reports }

final adminTabProvider = StateProvider<AdminTab>((ref) => AdminTab.dashboard);
