import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/attendance_provider.dart';
import '../../../core/providers/employee_provider.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/theme/app_theme.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _selectedMonth = DateTime.now();
  String get _monthString => '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeeListProvider('status=Active'));
    final async = ref.watch(monthlyAttendanceProvider(_monthString));

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: AppTheme.secondary, size: 20),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedMonth,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) setState(() => _selectedMonth = date);
                          },
                          child: Text('${_selectedMonth.year} - ${_selectedMonth.month.toString().padLeft(2, '0')}'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: async.when(
              data: (list) {
                if (list.isEmpty) return const EmptyView(message: 'No attendance records for this month', icon: Icons.event_busy_rounded);
                
                // Group by date
                final Map<String, List<dynamic>> byDate = {};
                for (final record in list) {
                  final date = record['date'] != null ? DateTime.parse(record['date']).toIso8601String().split('T')[0] : 'Unknown';
                  if (!byDate.containsKey(date)) byDate[date] = [];
                  byDate[date]!.add(record);
                }
                
                final sortedDates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: sortedDates.length,
                  itemBuilder: (context, i) {
                    final date = sortedDates[i];
                    final records = byDate[date]!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        padding: EdgeInsets.zero,
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded: i == 0,
                            title: Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${records.length} records'),
                            children: records.map((r) {
                              String empName = 'Employee';
                              if (employees.hasValue) {
                                final matched = employees.value!.where((e) => e['_id'] == r['employeeId']).toList();
                                if (matched.isNotEmpty) empName = matched.first['fullName'] ?? 'Employee';
                              }
                              return ListTile(
                                title: Text(empName),
                                subtitle: Text('In: ${r['checkIn'] != null ? DateTime.parse(r['checkIn']).toLocal().toString().split(' ')[1].substring(0,5) : '-'} | Out: ${r['checkOut'] != null ? DateTime.parse(r['checkOut']).toLocal().toString().split(' ')[1].substring(0,5) : '-'}'),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    StatusChip(status: r['status'] ?? ''),
                                    if (r['isLate'] == true) const SizedBox(height: 4),
                                    if (r['isLate'] == true) Text('Late', style: TextStyle(color: AppTheme.warning, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(monthlyAttendanceProvider)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/attendance/mark'),
        icon: const Icon(Icons.check_circle_rounded),
        label: const Text('Mark Attendance'),
      ),
    );
  }
}
