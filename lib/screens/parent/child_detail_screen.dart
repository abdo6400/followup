import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/student_model.dart';
import '../../models/task_result_model.dart';
import '../../models/attendance_model.dart';
import '../../models/sheikh_model.dart';
import '../../services/database_service.dart';

class ChildDetailScreen extends StatefulWidget {
  final StudentModel student;

  const ChildDetailScreen({
    Key? key,
    required this.student,
  }) : super(key: key);

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen>
    with SingleTickerProviderStateMixin {
  final _dbService = DatabaseService();
  bool _isLoading = true;
  late TabController _tabController;
  List<TaskResultModel> _taskResults = [];
  List<AttendanceModel> _attendance = [];
  Map<String, SheikhModel> _sheikhs = {};
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load task results
      final taskResults = await _dbService.getStudentTaskResults(
        widget.student.id,
        startDate: _startDate,
        endDate: _endDate,
      );

      // Load attendance
      final attendance = await _dbService.getStudentAttendance(
        widget.student.id,
        startDate: _startDate,
        endDate: _endDate,
      );

      // Load sheikh details for each task result and attendance
      final sheikhIds = {
        ...taskResults.map((r) => r.sheikhId),
        ...attendance.map((a) => a.sheikhId),
      };

      final sheikhs = await Future.wait(
        sheikhIds.map((id) => _dbService.getSheikhById(id)),
      );

      if (mounted) {
        setState(() {
          _taskResults = taskResults;
          _attendance = attendance;
          _sheikhs = {
            for (var sheikh in sheikhs.whereType<SheikhModel>())
              sheikh.id: sheikh,
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

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  Widget _buildTaskResults() {
    if (_taskResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.assessment_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No task results in selected period',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _taskResults.length,
      itemBuilder: (context, index) {
        final result = _taskResults[index];
        final sheikh = _sheikhs[result.sheikhId];

        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: ListTile(
            title: Row(
              children: [
                Expanded(child: Text(result.taskId)), // TODO: Get task title
                Text(
                  '${result.points} points',
                  style: TextStyle(
                    color: _getColorForPoints(result.points),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Sheikh: ${sheikh?.name ?? 'Unknown'}'),
                Text('Date: ${DateFormat('MMM d, y').format(result.date)}'),
                if (result.notes != null && result.notes!.isNotEmpty)
                  Text('Note: ${result.notes}'),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildAttendance() {
    if (_attendance.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No attendance records in selected period',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _attendance.length,
      itemBuilder: (context, index) {
        final record = _attendance[index];
        final sheikh = _sheikhs[record.sheikhId];

        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: record.status == AttendanceStatus.present
                  ? Colors.green
                  : Colors.red,
              child: Icon(
                record.status == AttendanceStatus.present
                    ? Icons.check
                    : Icons.close,
                color: Colors.white,
              ),
            ),
            title: Text(DateFormat('EEEE, MMM d').format(record.date)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sheikh: ${sheikh?.name ?? 'Unknown'}'),
                if (record.notes.isNotEmpty) Text('Note: ${record.notes}'),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Color _getColorForPoints(double points) {
    // TODO: Get max points from task type
    const maxPoints = 10.0;
    final percentage = points / maxPoints;
    
    if (percentage >= 0.8) {
      return Colors.green;
    } else if (percentage >= 0.6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Task Results'),
            Tab(text: 'Attendance'),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.date_range),
            label: Text(
              '${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d').format(_endDate)}',
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTaskResults(),
                _buildAttendance(),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
