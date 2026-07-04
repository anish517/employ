import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/financial_provider.dart';
import '../../../core/providers/employee_provider.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/theme/app_theme.dart';

class LoansScreen extends ConsumerStatefulWidget {
  const LoansScreen({super.key});

  @override
  ConsumerState<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends ConsumerState<LoansScreen> {
  bool _saving = false;

  void _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Loan?'),
        content: const Text('Are you sure you want to delete this loan record?'),
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
      await ref.read(loanServiceProvider).deleteLoan(id);
      ref.invalidate(loanListProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loan deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeeListProvider(null));
    final async = ref.watch(loanListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Loans & Advances')),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          async.when(
            data: (list) {
              if (list.isEmpty) return const EmptyView(message: 'No loan records found', icon: Icons.account_balance_rounded);
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final loan = list[i];
                  String empName = 'Employee';
                  if (employees.hasValue) {
                    final matched = employees.value!.where((e) => e['_id'] == loan['employeeId']).toList();
                    if (matched.isNotEmpty) empName = matched.first['fullName'] ?? 'Employee';
                  }

                  final amount = loan['amount'] ?? 0;
                  final installments = loan['installments'] ?? 1;
                  final remaining = loan['remainingAmount'] ?? 0;
                  final monthly = amount / installments;
                  
                  return AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(empName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text('Start Month: ${loan['startMonth']} • Reason: ${loan['reason']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('NPR $amount', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.warning)),
                              const SizedBox(width: 8),
                              IconButton(icon: const Icon(Icons.delete_rounded, color: AppTheme.error), onPressed: () => _delete(loan['_id'])),
                            ],
                          ),
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Installments: $installments'),
                            Text('Monthly: NPR ${monthly.toStringAsFixed(0)}'),
                            Text('Remaining: NPR $remaining', style: TextStyle(fontWeight: FontWeight.bold, color: remaining == 0 ? AppTheme.success : AppTheme.error)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(loanListProvider)),
          ),
          if (_saving) const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/loans/add'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Loan'),
      ),
    );
  }
}
