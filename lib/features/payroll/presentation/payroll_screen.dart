import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/payroll_provider.dart';
import '../../../core/providers/employee_provider.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/theme/app_theme.dart';

class PayrollScreen extends ConsumerStatefulWidget {
  const PayrollScreen({super.key});

  @override
  ConsumerState<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends ConsumerState<PayrollScreen> {
  DateTime _selectedMonth = DateTime.now();
  String get _monthString => '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';
  bool _processing = false;

  Future<void> _processAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Process Payroll?'),
        content: Text('This will calculate and finalize salary for all active employees for $_monthString.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Proceed')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _processing = true);
    try {
      await ref.read(payrollServiceProvider).finalizePayroll(_monthString);
      ref.invalidate(salaryListProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payroll processed successfully')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeeListProvider(null));
    final async = ref.watch(salaryListProvider({'month': _monthString}));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
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
                            final date = await showDatePicker(context: context, initialDate: _selectedMonth, firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 31)));
                            if (date != null) setState(() => _selectedMonth = date);
                          },
                          child: Text('${_selectedMonth.year} - ${_selectedMonth.month.toString().padLeft(2, '0')}'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _processing ? null : _processAll,
                  icon: _processing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.play_circle_filled_rounded),
                  label: const Text('Process All'),
                ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              data: (list) {
                if (list.isEmpty) return const EmptyView(message: 'No payroll records for this month', icon: Icons.payments_rounded);
                
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final sal = list[i];
                    String empName = 'Employee';
                    if (employees.hasValue) {
                      final matched = employees.value!.where((e) => e['_id'] == sal['employeeId']).toList();
                      if (matched.isNotEmpty) empName = matched.first['fullName'] ?? 'Employee';
                    }

                    return AppCard(
                      onTap: () => Navigator.pushNamed(context, '/payroll/payslip', arguments: sal),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(empName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Text('Status: ${sal['status']} • Total Hrs: ${sal['regularHours'] + sal['overtimeHours']}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('NPR ${sal['netSalary']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.success)),
                                const SizedBox(height: 4),
                                StatusChip(status: sal['status'] ?? ''),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(salaryListProvider)),
            ),
          ),
        ],
      ),
    );
  }
}
