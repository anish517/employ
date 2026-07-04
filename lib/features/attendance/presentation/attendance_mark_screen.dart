import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/attendance_provider.dart';
import '../../../core/providers/employee_provider.dart';
import '../../../core/theme/app_theme.dart';
// Removed unused import

class AttendanceMarkScreen extends ConsumerStatefulWidget {
  const AttendanceMarkScreen({super.key});

  @override
  ConsumerState<AttendanceMarkScreen> createState() => _AttendanceMarkScreenState();
}

class _AttendanceMarkScreenState extends ConsumerState<AttendanceMarkScreen> {
  DateTime _date = DateTime.now();
  TimeOfDay? _checkIn;
  TimeOfDay? _checkOut;
  String _status = 'Present';
  String? _employeeId;
  bool _saving = false;

  Future<void> _submit() async {
    if (_employeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an employee')));
      return;
    }
    setState(() => _saving = true);
    try {
      final payload = {
        'employeeId': _employeeId,
        'date': _date.toIso8601String().split('T')[0],
        'status': _status,
      };

      if (_checkIn != null) {
        payload['checkIn'] = DateTime(_date.year, _date.month, _date.day, _checkIn!.hour, _checkIn!.minute).toIso8601String();
      }
      if (_checkOut != null) {
        payload['checkOut'] = DateTime(_date.year, _date.month, _date.day, _checkOut!.hour, _checkOut!.minute).toIso8601String();
      }

      await ref.read(attendanceServiceProvider).mark(payload);
      ref.invalidate(monthlyAttendanceProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance marked successfully')));
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

    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Employee', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
              error: (e, _) => Text('Error loading employees: $e'),
            ),
            const SizedBox(height: 24),

            const Text('Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.divider)),
              title: Text('${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
              trailing: const Icon(Icons.calendar_today_rounded),
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime.now());
                if (d != null) setState(() => _date = d);
              },
            ),
            const SizedBox(height: 24),

            const Text('Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(),
              items: ['Present', 'Absent', 'Half Day'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 24),

            if (_status != 'Absent') ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Check In', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.divider)),
                          title: Text(_checkIn?.format(context) ?? 'Select Time'),
                          trailing: const Icon(Icons.access_time_rounded),
                          onTap: () async {
                            final t = await showTimePicker(context: context, initialTime: _checkIn ?? const TimeOfDay(hour: 9, minute: 0));
                            if (t != null) setState(() => _checkIn = t);
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
                        const Text('Check Out', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.divider)),
                          title: Text(_checkOut?.format(context) ?? 'Select Time'),
                          trailing: const Icon(Icons.access_time_rounded),
                          onTap: () async {
                            final t = await showTimePicker(context: context, initialTime: _checkOut ?? const TimeOfDay(hour: 17, minute: 0));
                            if (t != null) setState(() => _checkOut = t);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Attendance'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
