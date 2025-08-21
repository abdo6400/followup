import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/student_model.dart';
import '../../models/task_model.dart';
import '../../models/task_result_model.dart';
import '../../services/database_service.dart';

class TaskMarkingScreen extends StatefulWidget {
  const TaskMarkingScreen({Key? key}) : super(key: key);

  @override
  State<TaskMarkingScreen> createState() => _TaskMarkingScreenState();
}

class _TaskMarkingScreenState extends State<TaskMarkingScreen> {
  final _dbService = DatabaseService();
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  List<StudentModel> _students = [];
  List<TaskModel> _tasks = [];
  Map<String, Map<String, TaskResultModel>> _taskResults = {}; // studentId -> taskId -> result
  TaskModel? _selectedTask;

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

      // Load available tasks
      final tasks = await _dbService.getTasks();

      // Load task results for selected date
      final taskResults = await _dbService.getTaskResultsByDate(
        sheikhId: 'currentSheikhId', // TODO: Get actual sheikh ID
        date: _selectedDate,
      );

      if (mounted) {
        setState(() {
          _students = students;
          _tasks = tasks;
          _taskResults = {};
          
          // Organize task results by student and task
          for (var result in taskResults) {
            _taskResults[result.studentId] ??= {};
            _taskResults[result.studentId]![result.taskId] = result;
          }
          
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

  Future<void> _markTask(StudentModel student) async {
    if (_selectedTask == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a task')),
      );
      return;
    }

    final currentResult = _taskResults[student.id]?[_selectedTask!.id];
    final controller = TextEditingController(
      text: currentResult?.points.toString() ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark ${_selectedTask!.title} for ${student.name}'),
        content: _selectedTask!.type == TaskType.yesNo
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _saveTaskResult(student, 1),
                    child: const Text('Yes'),
                  ),
                  ElevatedButton(
                    onPressed: () => _saveTaskResult(student, 0),
                    child: const Text('No'),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Points (max: ${_selectedTask!.maxPoints})',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final points = double.tryParse(controller.text);
                          if (points != null &&
                              points >= 0 &&
                              points <= _selectedTask!.maxPoints) {
                            _saveTaskResult(student, points);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please enter a valid number between 0 and ${_selectedTask!.maxPoints}',
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _saveTaskResult(StudentModel student, double points) async {
    try {
      final currentResult = _taskResults[student.id]?[_selectedTask!.id];
      final result = TaskResultModel(
        id: currentResult?.id ?? '',
        studentId: student.id,
        taskId: _selectedTask!.id,
        sheikhId: 'currentSheikhId', // TODO: Get actual sheikh ID
        categoryId: student.assignedCategories.first, // Using first category for now
        points: points,
        date: _selectedDate,
      );

      if (currentResult == null) {
        await _dbService.addTaskResult(result);
      } else {
        await _dbService.updateTaskResult(result);
      }

      setState(() {
        _taskResults[student.id] ??= {};
        _taskResults[student.id]![_selectedTask!.id] = result;
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving task result: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving task result: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Tasks'),
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
          : Column(
              children: [
                // Task Selection
                Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<TaskModel>(
                      value: _selectedTask,
                      decoration: const InputDecoration(
                        labelText: 'Select Task',
                        border: OutlineInputBorder(),
                      ),
                      items: _tasks.map((task) {
                        return DropdownMenuItem(
                          value: task,
                          child: Text(task.title),
                        );
                      }).toList(),
                      onChanged: (task) {
                        setState(() {
                          _selectedTask = task;
                        });
                      },
                    ),
                  ),
                ),
                // Students List
                Expanded(
                  child: _students.isEmpty
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
                            TaskResultModel? result;
                            if (_selectedTask != null) {
                              result = _taskResults[student.id]?[_selectedTask!.id];
                            }

                            return Card(
                              child: ListTile(
                                title: Text(student.name),
                                subtitle: result != null
                                    ? Text(
                                        _selectedTask!.type == TaskType.yesNo
                                            ? result.points > 0
                                                ? 'Yes'
                                                : 'No'
                                            : '${result.points} points',
                                        style: TextStyle(
                                          color: _getColorForPoints(result.points),
                                        ),
                                      )
                                    : const Text('Not marked'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: _selectedTask == null
                                      ? null
                                      : () => _markTask(student),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Color _getColorForPoints(double points) {
    if (_selectedTask?.type == TaskType.yesNo) {
      return points > 0 ? Colors.green : Colors.red;
    }

    final percentage = points / (_selectedTask?.maxPoints ?? 1);
    if (percentage >= 0.8) {
      return Colors.green;
    } else if (percentage >= 0.6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
