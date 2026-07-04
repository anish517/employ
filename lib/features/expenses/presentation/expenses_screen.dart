import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/expense_provider.dart';
import '../../../core/providers/employee_provider.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/theme/app_theme.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  DateTime _selectedMonth = DateTime.now();
  String get _monthString => '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';
  bool _saving = false;

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _category = TextEditingController();
  final _date = TextEditingController();
  String? _employeeId;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _category.dispose();
    _date.dispose();
    super.dispose();
  }

  void _showForm([Map<String, dynamic>? expense]) {
    if (expense != null) {
      _title.text = expense['title'] ?? '';
      _amount.text = (expense['amount'] ?? 0).toString();
      _category.text = expense['category'] ?? '';
      _date.text = expense['date'] != null ? DateTime.parse(expense['date']).toString().split(' ')[0] : DateTime.now().toString().split(' ')[0];
      _employeeId = expense['employeeId'];
    } else {
      _title.clear();
      _amount.clear();
      _category.clear();
      _date.text = DateTime.now().toString().split(' ')[0];
      _employeeId = null;
    }

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (ctx, setState) {
          final employees = ref.watch(employeeListProvider({'status': 'Active'}));
          return AlertDialog(
            title: Text(expense == null ? 'Add Expense' : 'Edit Expense'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _title,
                      decoration: const InputDecoration(labelText: 'Title *'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amount,
                      decoration: const InputDecoration(labelText: 'Amount *'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _category,
                      decoration: const InputDecoration(labelText: 'Category *'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    employees.when(
                      data: (list) => DropdownButtonFormField<String>(
                        initialValue: _employeeId,
                        decoration: const InputDecoration(labelText: 'Claimed By'),
                        items: list.map((e) => DropdownMenuItem<String>(
                          value: e['_id'],
                          child: Text('${e['fullName']}'),
                        )).toList(),
                        onChanged: (v) => setState(() => _employeeId = v),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('Error: $e'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _date,
                      decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD) *'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  Navigator.pop(c);
                  this.setState(() => _saving = true);
                  try {
                    final payload = {
                      'title': _title.text.trim(),
                      'amount': double.tryParse(_amount.text) ?? 0,
                      'category': _category.text.trim(),
                      'date': _date.text.trim(),
                      'employeeId': _employeeId,
                    };
                    
                    if (expense == null) {
                      await ref.read(expenseServiceProvider).createExpense(payload);
                    } else {
                      await ref.read(expenseServiceProvider).updateExpense(expense['_id'], payload);
                    }
                    ref.invalidate(expenseListProvider);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Expense ${expense == null ? 'added' : 'updated'}')));
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
                  } finally {
                    if (mounted) this.setState(() => _saving = false);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text('Are you sure you want to delete this expense?'),
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
      await ref.read(expenseServiceProvider).deleteExpense(id);
      ref.invalidate(expenseListProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  
  void _updateStatus(String id, String status) async {
    setState(() => _saving = true);
    try {
      await ref.read(expenseServiceProvider).updateExpense(id, {'status': status});
      ref.invalidate(expenseListProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Expense marked as $status')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeeListProvider(null));
    final async = ref.watch(expenseListProvider({'month': _monthString}));

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
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
                  data: (data) {
                    final list = (data['data'] as List?) ?? [];
                    final summary = data['summary'] as Map? ?? {};
                    
                    if (list.isEmpty) return const EmptyView(message: 'No expenses this month', icon: Icons.receipt_long_rounded);
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Expenses: NPR ${summary['totalExpenses'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Pending: NPR ${summary['totalPending'] ?? 0}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: list.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final expense = list[i];
                              String empName = 'Company';
                              if (expense['employeeId'] != null && employees.hasValue) {
                                final matched = employees.value!.where((e) => e['_id'] == expense['employeeId']).toList();
                                if (matched.isNotEmpty) empName = matched.first['fullName'] ?? 'Employee';
                              }
                              
                              final status = expense['status'] ?? 'Pending';
                              final date = expense['date'] != null ? DateTime.parse(expense['date']).toString().split(' ')[0] : '';
                              
                              return AppCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(expense['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      subtitle: Text('$empName • $date\nCategory: ${expense['category']}'),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('NPR ${expense['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          const SizedBox(height: 4),
                                          StatusChip(status: status),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (status == 'Pending') ...[
                                          TextButton(onPressed: () => _updateStatus(expense['_id'], 'Rejected'), child: const Text('Reject', style: TextStyle(color: AppTheme.error))),
                                          TextButton(onPressed: () => _updateStatus(expense['_id'], 'Approved'), child: const Text('Approve', style: TextStyle(color: AppTheme.success))),
                                        ],
                                        IconButton(icon: const Icon(Icons.edit_rounded, size: 20, color: AppTheme.secondary), onPressed: () => _showForm(expense)),
                                        IconButton(icon: const Icon(Icons.delete_rounded, size: 20, color: AppTheme.error), onPressed: () => _delete(expense['_id'])),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const LoadingView(),
                  error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(expenseListProvider)),
                ),
                if (_saving) const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
      ),
    );
  }
}
