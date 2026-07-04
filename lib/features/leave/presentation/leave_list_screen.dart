import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/leave_provider.dart';
import '../../../core/providers/employee_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/theme/app_theme.dart';

class LeaveListScreen extends ConsumerStatefulWidget {
  const LeaveListScreen({super.key});

  @override
  ConsumerState<LeaveListScreen> createState() => _LeaveListScreenState();
}

class _LeaveListScreenState extends ConsumerState<LeaveListScreen> {
  String _statusFilter = 'Pending';
  bool _saving = false;

  Future<void> _updateStatus(String id, String newStatus) async {
    setState(() => _saving = true);
    try {
      await ref.read(leaveServiceProvider).updateLeaveStatus(id, newStatus);
      ref.invalidate(leaveListProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Leave marked as $newStatus')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeeListProvider(null));
    final leaveTypes = ref.watch(leaveTypeListProvider);
    final async = ref.watch(leaveListProvider({'status': _statusFilter}));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management'),
        actions: [
          IconButton(icon: const Icon(Icons.settings_rounded), onPressed: () => Navigator.pushNamed(context, '/leave/types')),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Pending', 'Approved', 'Rejected'].map((s) {
                  final selected = _statusFilter == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(s),
                      selected: selected,
                      onSelected: (b) {
                        if (b) setState(() => _statusFilter = s);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                async.when(
                  data: (list) {
                    if (list.isEmpty) return const EmptyView(message: 'No leave requests found', icon: Icons.inbox_rounded);
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final leave = list[i];
                        
                        String empName = 'Employee';
                        if (employees.hasValue) {
                          final matched = employees.value!.where((e) => e['_id'] == leave['employeeId']).toList();
                          if (matched.isNotEmpty) empName = matched.first['fullName'] ?? 'Employee';
                        }
                        
                        String typeName = 'Leave';
                        if (leaveTypes.hasValue) {
                          final matched = leaveTypes.value!.where((t) => t['_id'] == leave['leaveTypeId']).toList();
                          if (matched.isNotEmpty) typeName = matched.first['name'] ?? 'Leave';
                        }

                        final startDate = leave['startDate'] != null ? DateTime.parse(leave['startDate']).toString().split(' ')[0] : '';
                        final endDate = leave['endDate'] != null ? DateTime.parse(leave['endDate']).toString().split(' ')[0] : '';

                        return AppCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                title: Text(empName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('$typeName • $startDate to $endDate (${leave['totalDays']} days)'),
                                trailing: StatusChip(status: leave['status'] ?? 'Pending'),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('Reason: ${leave['reason'] ?? ''}', style: TextStyle(color: AppTheme.onSurface.withValues(alpha: 0.7), fontSize: 13)),
                              ),
                              if (leave['status'] == 'Pending') ...[
                                const Divider(height: 24),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () => _updateStatus(leave['_id'], 'Rejected'),
                                        style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error, side: const BorderSide(color: AppTheme.error)),
                                        child: const Text('Reject'),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton(
                                        onPressed: () => _updateStatus(leave['_id'], 'Approved'),
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                                        child: const Text('Approve'),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 16),
                              ]
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const LoadingView(),
                  error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(leaveListProvider)),
                ),
                if (_saving) const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/leave/request'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Request'),
      ),
    );
  }
}
