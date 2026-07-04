import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/financial_provider.dart';
import '../../../core/providers/employee_provider.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/theme/app_theme.dart';

class FinesScreen extends ConsumerStatefulWidget {
  const FinesScreen({super.key});

  @override
  ConsumerState<FinesScreen> createState() => _FinesScreenState();
}

class _FinesScreenState extends ConsumerState<FinesScreen> {
  DateTime _selectedMonth = DateTime.now();
  String get _monthString => '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';
  bool _saving = false;

  void _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Fine?'),
        content: const Text('Are you sure you want to delete this fine?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _saving = true);
    try {
      await ref.read(fineServiceProvider).deleteFine(id);
      ref.invalidate(fineListProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fine deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeeListProvider(null));
    final async = ref.watch(fineListProvider(_monthString));

    return Scaffold(
      appBar: AppBar(title: const Text('Fines & Deductions')),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
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
          Expanded(
            child: Stack(
              children: [
                async.when(
                  data: (list) {
                    if (list.isEmpty) return const EmptyView(message: 'No fines this month', icon: Icons.remove_circle_outline_rounded);
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final fine = list[i];
                        String empName = 'Employee';
                        if (employees.hasValue) {
                          final matched = employees.value!.where((e) => e['_id'] == fine['employeeId']).toList();
                          if (matched.isNotEmpty) empName = matched.first['fullName'] ?? 'Employee';
                        }
                        return AppCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(empName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Text('${fine['type']} • ${fine['reason'] ?? ''}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('NPR ${fine['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.error)),
                                const SizedBox(width: 8),
                                IconButton(icon: const Icon(Icons.delete_rounded, color: AppTheme.error), onPressed: () => _delete(fine['_id'])),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const LoadingView(),
                  error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(fineListProvider)),
                ),
                if (_saving) const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/fines/add'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Fine'),
      ),
    );
  }
}
