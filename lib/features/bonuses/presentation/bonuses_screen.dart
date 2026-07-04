import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/financial_provider.dart';
import '../../../core/providers/employee_provider.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/theme/app_theme.dart';

class BonusesScreen extends ConsumerStatefulWidget {
  const BonusesScreen({super.key});

  @override
  ConsumerState<BonusesScreen> createState() => _BonusesScreenState();
}

class _BonusesScreenState extends ConsumerState<BonusesScreen> {
  DateTime _selectedMonth = DateTime.now();
  String get _monthString => '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';
  bool _saving = false;

  void _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Bonus?'),
        content: const Text('Are you sure you want to delete this bonus?'),
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
      await ref.read(bonusServiceProvider).deleteBonus(id);
      ref.invalidate(bonusListProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bonus deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeeListProvider(null));
    final async = ref.watch(bonusListProvider(_monthString));

    return Scaffold(
      appBar: AppBar(title: const Text('Bonuses')),
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
                    if (list.isEmpty) return const EmptyView(message: 'No bonuses this month', icon: Icons.card_giftcard_rounded);
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final bonus = list[i];
                        String empName = 'Employee';
                        if (employees.hasValue) {
                          final matched = employees.value!.where((e) => e['_id'] == bonus['employeeId']).toList();
                          if (matched.isNotEmpty) empName = matched.first['fullName'] ?? 'Employee';
                        }
                        return AppCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(empName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Text('${bonus['type']} • ${bonus['reason'] ?? ''}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('NPR ${bonus['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success)),
                                const SizedBox(width: 8),
                                IconButton(icon: const Icon(Icons.delete_rounded, color: AppTheme.error), onPressed: () => _delete(bonus['_id'])),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const LoadingView(),
                  error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(bonusListProvider)),
                ),
                if (_saving) const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/bonuses/add'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Bonus'),
      ),
    );
  }
}
