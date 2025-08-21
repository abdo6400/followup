import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/student_model.dart';
import '../../models/attendance_model.dart';
import '../../services/database_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _dbService = DatabaseService();
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  List<StudentModel> _students = [];
  Map<String, AttendanceModel> _attendanceRecords = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load students for the current sheikh
      final students = await _dbService.getStudentsBySheikh('currentSheikhId'); // TODO: Get actual sheikh ID

      // Load attendance records for selected date
      final attendanceRecords = await _dbService.getAttendanceByDate(
        sheikhId: 'currentSheikhId', // TODO: Get actual sheikh ID
        date: _selectedDate,
      );

      if (mounted) {
        setState(() {
          _students = students;
          _attendanceRecords = {
            for (var record in attendanceRecords)
              record.studentId: record,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadData();
    }
  }

  Future<void> _toggleAttendance(StudentModel student) async {
    try {
      final currentAttendance = _attendanceRecords[student.id];
      final newStatus = currentAttendance == null ||
              currentAttendance.status == AttendanceStatus.absent
          ? AttendanceStatus.present
          : AttendanceStatus.absent;

      final attendance = AttendanceModel(
        id: currentAttendance?.id ?? '',
        studentId: student.id,
        sheikhId: 'currentSheikhId', // TODO: Get actual sheikh ID
        categoryId: student.assignedCategories.first, // Using first category for now
        date: _selectedDate,
        status: newStatus,
        notes: currentAttendance?.notes ?? '',
      );

      if (currentAttendance == null) {
        await _dbService.addAttendance(attendance);
      } else {
        await _dbService.updateAttendance(attendance);
      }

      setState(() {
        _attendanceRecords[student.id] = attendance;
      });
    } catch (e) {
      print('Error updating attendance: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating attendance: $e')),
      );
    }
  }

  Future<void> _addNote(StudentModel student) async {
    final currentAttendance = _attendanceRecords[student.id];
    final controller = TextEditingController(text: currentAttendance?.notes);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Note for ${student.name}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Note',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final attendance = AttendanceModel(
                  id: currentAttendance?.id ?? '',
                  studentId: student.id,
                  sheikhId: 'currentSheikhId', // TODO: Get actual sheikh ID
                  categoryId: student.assignedCategories.first, // Using first category for now
                  date: _selectedDate,
                  status: currentAttendance?.status ?? AttendanceStatus.absent,
                  notes: controller.text,
                );

                if (currentAttendance == null) {
                  await _dbService.addAttendance(attendance);
                } else {
                  await _dbService.updateAttendance(attendance);
                }

                setState(() {
                  _attendanceRecords[student.id] = attendance;
                });

                if (mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                print('Error updating note: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating note: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          TextButton.icon(
            onPressed: _selectDate,
            icon: const Icon(Icons.calendar_today),
            label: Text(DateFormat('MMM d, y').format(_selectedDate)),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.group_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No students assigned',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    final attendance = _attendanceRecords[student.id];
                    final isPresent = attendance?.status == AttendanceStatus.present;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPresent ? Colors.green : Colors.red,
                          child: Icon(
                            isPresent ? Icons.check : Icons.close,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(student.name),
                        subtitle: attendance?.notes != null &&
                                attendance!.notes.isNotEmpty
                            ? Text(
                                attendance.notes,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.note_add),
                              onPressed: () => _addNote(student),
                            ),
                            Switch(
                              value: isPresent,
                              onChanged: (_) => _toggleAttendance(student),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
