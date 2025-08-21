import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';
import '../models/sheikh_model.dart';
import '../models/student_model.dart';
import '../models/task_model.dart';
import '../models/attendance_model.dart';
import '../models/task_result_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Categories
  Future<List<CategoryModel>> getCategories() async {
    final snapshot = await _db.collection('categories').get();
    return snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
  }

  Future<void> addCategory(CategoryModel category) async {
    await _db.collection('categories').add(category.toMap());
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _db.collection('categories').doc(category.id).update(category.toMap());
  }

  Future<void> deleteCategory(String categoryId) async {
    await _db.collection('categories').doc(categoryId).delete();
  }

  // Sheikhs
  // User Methods
  Future<void> updateUser(UserModel user) async {
    await _db.collection('users').doc(user.id).update(user.toMap());
  }

  // Sheikh Methods
  Future<List<SheikhModel>> getSheikhs() async {
    final snapshot = await _db.collection('sheikhs').get();
    return snapshot.docs.map((doc) => SheikhModel.fromFirestore(doc)).toList();
  }

  Future<SheikhModel?> getSheikhById(String id) async {
    final doc = await _db.collection('sheikhs').doc(id).get();
    if (!doc.exists) return null;
    return SheikhModel.fromFirestore(doc);
  }

  Future<SheikhModel?> getSheikhByUserId(String userId) async {
    final snapshot = await _db
        .collection('sheikhs')
        .where('userId', isEqualTo: userId)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return SheikhModel.fromFirestore(snapshot.docs.first);
  }

  Future<void> addSheikh(SheikhModel sheikh) async {
    await _db.collection('sheikhs').add(sheikh.toMap());
  }

  Future<void> updateSheikh(SheikhModel sheikh) async {
    await _db.collection('sheikhs').doc(sheikh.id).update(sheikh.toMap());
  }

  Future<void> deleteSheikh(String sheikhId) async {
    await _db.collection('sheikhs').doc(sheikhId).delete();
  }

  // Students
  Future<List<StudentModel>> getAllStudents() async {
    final snapshot = await _db.collection('students').get();
    return snapshot.docs.map((doc) => StudentModel.fromFirestore(doc)).toList();
  }
  Future<List<StudentModel>> getStudentsByParent(String parentId) async {
    final snapshot = await _db
        .collection('students')
        .where('parentId', isEqualTo: parentId)
        .get();
    return snapshot.docs.map((doc) => StudentModel.fromFirestore(doc)).toList();
  }

  Future<List<StudentModel>> getStudentsByCategory(String categoryId) async {
    final snapshot = await _db
        .collection('students')
        .where('assignedCategories', arrayContains: categoryId)
        .get();
    return snapshot.docs.map((doc) => StudentModel.fromFirestore(doc)).toList();
  }

  Future<List<StudentModel>> getStudentsBySheikh(String sheikhId) async {
    final snapshot = await _db
        .collection('students')
        .where('assignedSheikhs', arrayContains: sheikhId)
        .get();
    return snapshot.docs.map((doc) => StudentModel.fromFirestore(doc)).toList();
  }

  Future<void> addStudent(StudentModel student) async {
    await _db.collection('students').add(student.toMap());
  }

  Future<void> updateStudent(StudentModel student) async {
    await _db.collection('students').doc(student.id).update(student.toMap());
  }

  Future<void> deleteStudent(String studentId) async {
    await _db.collection('students').doc(studentId).delete();
  }

  // Tasks
  Future<List<TaskModel>> getTasks() async {
    final snapshot = await _db.collection('tasks').get();
    return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
  }

  Future<List<TaskModel>> getTasksByCategory(String categoryId) async {
    final snapshot = await _db
        .collection('tasks')
        .where('categoryId', isEqualTo: categoryId)
        .get();
    return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
  }

  Future<void> addTask(TaskModel task) async {
    await _db.collection('tasks').add(task.toMap());
  }

  Future<void> updateTask(TaskModel task) async {
    await _db.collection('tasks').doc(task.id).update(task.toMap());
  }

  Future<void> deleteTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).delete();
  }

  // Attendance
  Future<void> addAttendance(AttendanceModel attendance) async {
    await _db.collection('attendance').add(attendance.toMap());
  }

  Future<void> updateAttendance(AttendanceModel attendance) async {
    await _db.collection('attendance').doc(attendance.id).update(attendance.toMap());
  }

  Future<List<AttendanceModel>> getAttendanceByDate({
    required String sheikhId,
    required DateTime date,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _db
        .collection('attendance')
        .where('sheikhId', isEqualTo: sheikhId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThan: endOfDay)
        .get();

    return snapshot.docs.map((doc) => AttendanceModel.fromFirestore(doc)).toList();
  }

  Future<List<AttendanceModel>> getStudentAttendance(
    String studentId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _db
        .collection('attendance')
        .where('studentId', isEqualTo: studentId);
    
    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: endDate);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => AttendanceModel.fromFirestore(doc)).toList();
  }

  // Task Results
  Future<void> addTaskResult(TaskResultModel result) async {
    await _db.collection('taskResults').add(result.toMap());
  }

  Future<void> updateTaskResult(TaskResultModel result) async {
    await _db.collection('taskResults').doc(result.id).update(result.toMap());
  }

  Future<List<TaskResultModel>> getTaskResultsByDate({
    required String sheikhId,
    required DateTime date,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _db
        .collection('taskResults')
        .where('sheikhId', isEqualTo: sheikhId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThan: endOfDay)
        .get();

    return snapshot.docs.map((doc) => TaskResultModel.fromFirestore(doc)).toList();
  }

  Future<List<TaskResultModel>> getStudentTaskResults(
    String studentId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _db
        .collection('taskResults')
        .where('studentId', isEqualTo: studentId);
    
    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: endDate);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => TaskResultModel.fromFirestore(doc)).toList();
  }

  // Reports
  Future<Map<String, dynamic>> generateSheikhReport(
    String sheikhId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final students = await getStudentsBySheikh(sheikhId);
    final attendanceQuery = await _db
        .collection('attendance')
        .where('sheikhId', isEqualTo: sheikhId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .get();
    
    final taskResultsQuery = await _db
        .collection('taskResults')
        .where('sheikhId', isEqualTo: sheikhId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .get();

    return {
      'totalStudents': students.length,
      'attendance': attendanceQuery.docs.map((doc) => AttendanceModel.fromFirestore(doc)).toList(),
      'taskResults': taskResultsQuery.docs.map((doc) => TaskResultModel.fromFirestore(doc)).toList(),
    };
  }

  Future<Map<String, dynamic>> generateStudentReport(
    String studentId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final attendance = await getStudentAttendance(
      studentId,
      startDate: startDate,
      endDate: endDate,
    );
    
    final taskResults = await getStudentTaskResults(
      studentId,
      startDate: startDate,
      endDate: endDate,
    );

    return {
      'attendance': attendance,
      'taskResults': taskResults,
    };
  }
}
