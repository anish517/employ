import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/leave_provider.dart';
import '../../../core/providers/employee_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_theme.dart';

class LeaveRequestScreen extends ConsumerStatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  ConsumerState<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends ConsumerState<LeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  String? _employeeId;
  String? _leaveTypeId;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  bool _saving = false;

  int get _totalDays {
    final diff = _endDate.difference(_startDate).inDays;
    return diff >= 0 ? diff + 1 : 0;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_employeeId == null || _leaveTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select employee and leave type')));
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End date must be after start date')));
      return;
    }

    setState(() => _saving = true);
    try {
      final payload = {
        'employeeId': _employeeId,
        'leaveTypeId': _leaveTypeId,
        'startDate': _startDate.toIso8601String().split('T')[0],
        'endDate': _endDate.toIso8601String().split('T')[0],
        'reason': _reason.text.trim(),
      };
      
      await ref.read(leaveServiceProvider).submitLeave(payload);
      ref.invalidate(leaveListProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave request submitted')));
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
    final employees = ref.watch(employeeListProvider({'status': 'Active'}));
    final leaveTypes = ref.watch(leaveTypeListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Leave Request')),
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

              const Text('Leave Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              leaveTypes.when(
                data: (list) => DropdownButtonFormField<String>(
                  initialValue: _leaveTypeId,
                  decoration: const InputDecoration(hintText: 'Select Leave Type'),
                  items: list.map((t) => DropdownMenuItem<String>(
                    value: t['_id'],
                    child: Text('${t['name']} (${t['isPaid'] ? 'Paid' : 'Unpaid'})'),
                  )).toList(),
                  onChanged: (v) => setState(() => _leaveTypeId = v),
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
                        const Text('Start Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.divider)),
                          title: Text('${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}'),
                          trailing: const Icon(Icons.calendar_today_rounded),
                          onTap: () async {
                            final d = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 365)));
                            if (d != null) setState(() { _startDate = d; if (_endDate.isBefore(d)) _endDate = d; });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('End Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.divider)),
                          title: Text('${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}'),
                          trailing: const Icon(Icons.calendar_today_rounded),
                          onTap: () async {
                            final d = await showDatePicker(context: context, initialDate: _endDate, firstDate: _startDate, lastDate: DateTime.now().add(const Duration(days: 365)));
                            if (d != null) setState(() => _endDate = d);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Total Days: $_totalDays', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary)),
              const SizedBox(height: 24),

              const Text('Reason', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reason,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Enter reason for leave...'),
                validator: (v) => v!.isEmpty ? 'Reason is required' : null,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
