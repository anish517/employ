import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/employee_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';

class EmployeeDetailScreen extends ConsumerStatefulWidget {
  const EmployeeDetailScreen({super.key});

  @override
  ConsumerState<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends ConsumerState<EmployeeDetailScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _hourlyRate = TextEditingController();
  bool _saving = false;
  Map<String, dynamic>? _empData;

  @override
  void dispose() {
    _phone.dispose();
    _address.dispose();
    _hourlyRate.dispose();
    super.dispose();
  }

  void _initControllers(Map<String, dynamic> data) {
    if (_empData == null) {
      _empData = data;
      _phone.text = data['phone'] ?? '';
      _address.text = data['address'] ?? '';
      _hourlyRate.text = (data['hourlyRate'] ?? 0).toString();
    }
  }

  Future<void> _save(String id) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updates = {
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
        'hourlyRate': double.tryParse(_hourlyRate.text) ?? 0,
      };
      await ref.read(employeeServiceProvider).updateEmployee(id, updates);
      ref.invalidate(employeeListProvider);
      setState(() {
        _isEditing = false;
        _empData = null; // force reload
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employee updated successfully')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Employee?'),
        content: const Text('Are you sure you want to delete this employee? This action cannot be undone.'),
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

    try {
      await ref.read(employeeServiceProvider).deleteEmployee(id);
      ref.invalidate(employeeListProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employee deleted')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = ModalRoute.of(context)?.settings.arguments as String?;
    if (id == null) return const Scaffold(body: Center(child: Text('No ID provided')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Details'),
        actions: [
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () => setState(() => _isEditing = true)),
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.delete_rounded, color: AppTheme.error), onPressed: () => _delete(id)),
          if (_isEditing)
            IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(() { _isEditing = false; _empData = null; })),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: ref.read(employeeServiceProvider).getEmployee(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _empData == null) return const LoadingView();
          if (snapshot.hasError) return ErrorView(message: snapshot.error.toString());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const EmptyView(message: 'Employee not found');

          final emp = snapshot.data!;
          _initControllers(emp);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                          child: Text(
                            (emp['fullName'] ?? 'E')[0].toUpperCase(),
                            style: const TextStyle(fontSize: 32, color: AppTheme.secondary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(emp['fullName'] ?? 'Unnamed', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(emp['employeeId'] ?? '', style: TextStyle(color: AppTheme.onSurface.withValues(alpha: 0.5))),
                        const SizedBox(height: 8),
                        StatusChip(status: emp['status'] ?? 'Active'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  _SectionTitle('Employment Information'),
                  AppCard(
                    child: Column(
                      children: [
                        _InfoRow('Department ID', emp['departmentId'] ?? 'N/A'),
                        const Divider(height: 24),
                        _InfoRow('Designation ID', emp['designationId'] ?? 'N/A'),
                        const Divider(height: 24),
                        _InfoRow('Employment Type', emp['employmentType'] ?? 'N/A'),
                        const Divider(height: 24),
                        _InfoRow('Joining Date', emp['joiningDate'] != null ? DateTime.parse(emp['joiningDate']).toString().split(' ')[0] : 'N/A'),
                        if (_isEditing) const Divider(height: 24),
                        if (_isEditing)
                          TextFormField(
                            controller: _hourlyRate,
                            decoration: const InputDecoration(labelText: 'Hourly Rate (NPR)'),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          )
                        else ...[
                          const Divider(height: 24),
                          _InfoRow('Hourly Rate', 'NPR ${emp['hourlyRate']}'),
                        ]
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _SectionTitle('Contact Information'),
                  AppCard(
                    child: Column(
                      children: [
                        _InfoRow('Email', emp['email'] ?? 'N/A'),
                        const Divider(height: 24),
                        if (_isEditing)
                          TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone'), validator: (v) => v!.isEmpty ? 'Required' : null)
                        else
                          _InfoRow('Phone', emp['phone'] ?? 'N/A'),
                        const Divider(height: 24),
                        if (_isEditing)
                          TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'Address'), maxLines: 2)
                        else
                          _InfoRow('Address', emp['address'] ?? 'N/A'),
                      ],
                    ),
                  ),

                  if (emp['emergencyContact'] != null) ...[
                    const SizedBox(height: 24),
                    _SectionTitle('Emergency Contact'),
                    AppCard(
                      child: Column(
                        children: [
                          _InfoRow('Name', emp['emergencyContact']['name'] ?? 'N/A'),
                          const Divider(height: 24),
                          _InfoRow('Phone', emp['emergencyContact']['phone'] ?? 'N/A'),
                          const Divider(height: 24),
                          _InfoRow('Relation', emp['emergencyContact']['relation'] ?? 'N/A'),
                        ],
                      ),
                    ),
                  ],

                  if (_isEditing) ...[
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saving ? null : () => _save(id),
                        child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes'),
                      ),
                    )
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: TextStyle(color: AppTheme.onSurface.withValues(alpha: 0.5), fontSize: 14)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
