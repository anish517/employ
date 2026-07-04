import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/financial_provider.dart';
import '../../../core/providers/employee_provider.dart';
import '../../../core/theme/app_theme.dart';

class LoanAddScreen extends ConsumerStatefulWidget {
  const LoanAddScreen({super.key});

  @override
  ConsumerState<LoanAddScreen> createState() => _LoanAddScreenState();
}

class _LoanAddScreenState extends ConsumerState<LoanAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _installments = TextEditingController(text: '1');
  final _reason = TextEditingController();
  String? _employeeId;
  DateTime _selectedMonth = DateTime.now();
  bool _saving = false;

  String get _monthString => '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _amount.dispose();
    _installments.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_employeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an employee')));
      return;
    }

    setState(() => _saving = true);
    try {
      final payload = {
        'employeeId': _employeeId,
        'amount': double.tryParse(_amount.text) ?? 0,
        'installments': int.tryParse(_installments.text) ?? 1,
        'startMonth': _monthString,
        'reason': _reason.text.trim(),
      };
      
      await ref.read(loanServiceProvider).createLoan(payload);
      ref.invalidate(loanListProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loan added successfully')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeeListProvider(const {'status': 'Active'}));

    return Scaffold(
      appBar: AppBar(title: const Text('Add Loan/Advance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Employee', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              employees.when(
                data: (list) => DropdownButtonFormField<String>(
                  initialValue: _employeeId,
                  decoration: const InputDecoration(hintText: 'Select Employee'),
                  items: list.map((e) => DropdownMenuItem<String>(
                    value: e['_id'],
                    child: Text('${e['fullName']} (${e['employeeId']})'),
                  )).toList(),
                  onChanged: (v) => setState(() => _employeeId = v),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Amount (NPR)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _amount,
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Installments', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _installments,
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text('Start Month', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.divider)),
                title: Text(_monthString),
                trailing: const Icon(Icons.calendar_month_rounded),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: _selectedMonth, firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (d != null) setState(() => _selectedMonth = d);
                },
              ),
              const SizedBox(height: 24),

              const Text('Reason', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reason,
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Add Loan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
