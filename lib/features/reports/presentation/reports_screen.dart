import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/report_provider.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/theme/app_theme.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime _selectedMonth = DateTime.now();
  String get _monthString => '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';
  String _reportType = 'attendance'; // attendance, salary, leave
  bool _exporting = false;

  void _export(String format) async {
    setState(() => _exporting = true);
    try {
      final url = await ref.read(reportServiceProvider).exportReport(_reportType, format, _monthString);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report exported: $url')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Map<String, dynamic> _parseSummary(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      try {
        final decoded = json.decode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return {};
  }

  Widget _buildSummary(Map<String, dynamic> data) {
    final inner = data['data'];
    if (inner is! Map) return const SizedBox();
    if (_reportType == 'attendance') {
      final summary = _parseSummary(inner['summary']);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Working Days: ${summary['totalWorkingDays'] ?? 0}'),
          Text('Average Attendance: ${summary['averageAttendance'] ?? 0}%'),
        ],
      );
    } else if (_reportType == 'salary') {
      final summary = _parseSummary(inner['summary']);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Payout: NPR ${summary['totalPayout'] ?? 0}'),
          Text('Processed: ${summary['processedCount'] ?? 0} / ${summary['totalEmployees'] ?? 0}'),
        ],
      );
    } else if (_reportType == 'leave') {
      final summary = _parseSummary(inner['summary']);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Leaves Taken: ${summary['totalLeavesTaken'] ?? 0}'),
          Text('Approved Requests: ${summary['approvedRequests'] ?? 0}'),
        ],
      );
    }
    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    AsyncValue<Map<String, dynamic>> async;
    if (_reportType == 'attendance') {
      async = ref.watch(attendanceReportProvider(_monthString));
    } else if (_reportType == 'salary') {
      async = ref.watch(salaryReportProvider(_monthString));
    } else {
      async = ref.watch(leaveReportProvider(_monthString));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: AppTheme.secondary, size: 20),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(context: context, initialDate: _selectedMonth, firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 31)));
                          if (date != null) setState(() => _selectedMonth = date);
                        },
                        child: Text('${_selectedMonth.year} - ${_selectedMonth.month.toString().padLeft(2, '0')}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _reportType,
                    decoration: const InputDecoration(labelText: 'Report Type'),
                    items: const [
                      DropdownMenuItem(value: 'attendance', child: Text('Attendance Report')),
                      DropdownMenuItem(value: 'salary', child: Text('Salary Report')),
                      DropdownMenuItem(value: 'leave', child: Text('Leave Report')),
                    ],
                    onChanged: (v) => setState(() => _reportType = v!),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                async.when(
                  data: (data) {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${_reportType.toUpperCase()} SUMMARY', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const Divider(),
                              const SizedBox(height: 8),
                              _buildSummary(data),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _exporting ? null : () => _export('pdf'),
                              icon: const Icon(Icons.picture_as_pdf_rounded),
                              label: const Text('Export PDF'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                            ),
                            ElevatedButton.icon(
                              onPressed: _exporting ? null : () => _export('csv'),
                              icon: const Icon(Icons.table_chart_rounded),
                              label: const Text('Export CSV'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => const LoadingView(),
                  error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(attendanceReportProvider)),
                ),
                if (_exporting) const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
