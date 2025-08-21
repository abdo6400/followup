import 'package:flutter/material.dart';
import '../../models/attendance_model.dart';
import '../../models/task_result_model.dart';
import '../../models/sheikh_model.dart';
import '../../services/database_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _dbService = DatabaseService();
  bool _isLoading = false;
  String _selectedReportType = 'Daily';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String? _selectedSheikhId;
  List<SheikhModel> _sheikhs = [];
  Map<String, dynamic> _reportData = {};

  @override
  void initState() {
    super.initState();
    _loadSheikhs();
  }

  Future<void> _loadSheikhs() async {
    try {
      final sheikhs = await _dbService.getSheikhs();
      if (mounted) {
        setState(() {
          _sheikhs = sheikhs;
        });
      }
    } catch (e) {
      print('Error loading sheikhs: $e');
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _generateReport() async {
    if (_selectedReportType == 'Sheikh' && _selectedSheikhId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a sheikh')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _reportData = {};
    });

    try {
      switch (_selectedReportType) {
        case 'Daily':
          // Generate daily report for all sheikhs
          final reports = await Future.wait(
            _sheikhs.map((sheikh) => _dbService.generateSheikhReport(
                  sheikh.id,
                  _startDate,
                  _endDate,
                )),
          );

          _reportData = {
            'reports': reports,
            'sheikhs': _sheikhs,
          };
          break;

        case 'Sheikh':
          if (_selectedSheikhId != null) {
            final report = await _dbService.generateSheikhReport(
              _selectedSheikhId!,
              _startDate,
              _endDate,
            );
            _reportData = {
              'sheikh': _sheikhs.firstWhere((s) => s.id == _selectedSheikhId),
              'report': report,
            };
          }
          break;
      }
    } catch (e) {
      print('Error generating report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Filters',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedReportType,
                    decoration: const InputDecoration(
                      labelText: 'Report Type',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Daily', 'Sheikh'].map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedReportType = value;
                          if (value != 'Sheikh') {
                            _selectedSheikhId = null;
                          }
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _selectDateRange,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      '${_startDate.toString().split(' ')[0]} - ${_endDate.toString().split(' ')[0]}',
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedReportType == 'Sheikh') ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSheikhId,
                decoration: const InputDecoration(
                  labelText: 'Select Sheikh',
                  border: OutlineInputBorder(),
                ),
                items: _sheikhs.map((sheikh) {
                  return DropdownMenuItem(
                    value: sheikh.id,
                    child: Text(sheikh.userId), // TODO: Get sheikh name
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSheikhId = value;
                  });
                },
              ),
            ],
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: _generateReport,
                icon: const Icon(Icons.assessment),
                label: const Text('Generate Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reportData.isEmpty) {
      return const Center(child: Text('No report generated yet'));
    }

    if (_selectedReportType == 'Daily') {
      return _buildDailyReport();
    } else {
      return _buildSheikhReport();
    }
  }

  Widget _buildDailyReport() {
    final reports = _reportData['reports'] as List;
    final sheikhs = _reportData['sheikhs'] as List<SheikhModel>;

    return ListView.builder(
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index] as Map<String, dynamic>;
        final sheikh = sheikhs[index];
        final attendance = report['attendance'] as List<AttendanceModel>;
        final taskResults = report['taskResults'] as List<TaskResultModel>;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            title: Text('Sheikh: ${sheikh.userId}'), // TODO: Get sheikh name
            subtitle: Text(
              'Students: ${report['totalStudents']}, Attendance: ${attendance.length}, Tasks: ${taskResults.length}',
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attendance Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Add attendance summary widgets here

                    const SizedBox(height: 16),
                    const Text(
                      'Task Results Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Add task results summary widgets here
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheikhReport() {
    final sheikh = _reportData['sheikh'] as SheikhModel;
    final report = _reportData['report'] as Map<String, dynamic>;
    final attendance = report['attendance'] as List<AttendanceModel>;
    final taskResults = report['taskResults'] as List<TaskResultModel>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sheikh: ${sheikh.userId}', // TODO: Get sheikh name
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Total Students: ${report['totalStudents']}'),
                  Text('Total Attendance Records: ${attendance.length}'),
                  Text('Total Task Results: ${taskResults.length}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Add detailed attendance and task results widgets here
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildReportContent()),
        ],
      ),
    );
  }
}
