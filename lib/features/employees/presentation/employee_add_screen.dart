import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/employee_provider.dart';
import '../../../core/providers/department_provider.dart';
import '../../../core/providers/designation_provider.dart';
// Removed unused import
import '../../../core/theme/app_theme.dart';

class EmployeeAddScreen extends ConsumerStatefulWidget {
  const EmployeeAddScreen({super.key});
  @override
  ConsumerState<EmployeeAddScreen> createState() => _EmployeeAddScreenState();
}

class _EmployeeAddScreenState extends ConsumerState<EmployeeAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _hourlyRate = TextEditingController();
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();
  final _emergencyRelation = TextEditingController();
  String _gender = 'Male';
  String _employmentType = 'Full-time';
  DateTime? _dob;
  DateTime _joiningDate = DateTime.now();
  String? _departmentId;
  String? _designationId;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_fullName, _email, _phone, _address, _hourlyRate, _emergencyName, _emergencyPhone, _emergencyRelation]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final body = {
        'fullName': _fullName.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
        'hourlyRate': double.tryParse(_hourlyRate.text) ?? 0,
        'gender': _gender,
        'employmentType': _employmentType,
        'joiningDate': _joiningDate.toIso8601String(),
        if (_dob != null) 'dateOfBirth': _dob!.toIso8601String(),
        if (_departmentId != null) 'departmentId': _departmentId,
        if (_designationId != null) 'designationId': _designationId,
        'emergencyContact': {
          'name': _emergencyName.text.trim(),
          'phone': _emergencyPhone.text.trim(),
          'relation': _emergencyRelation.text.trim(),
        },
      };
      await ref.read(employeeServiceProvider).createEmployee(body);
      ref.invalidate(employeeListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employee added successfully!')));
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
    final depts = ref.watch(departmentListProvider);
    final desigs = ref.watch(designationListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Add Employee')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader('Personal Information'),
            const SizedBox(height: 12),
            _field('Full Name *', _fullName, validator: (v) => v!.isEmpty ? 'Required' : null),
            _row([
              _dropdownGender(),
              _field('Date of Birth', TextEditingController(text: _dob == null ? '' : '${_dob!.day}/${_dob!.month}/${_dob!.year}'), readOnly: true,
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: DateTime(1990), firstDate: DateTime(1950), lastDate: DateTime.now());
                    if (d != null) setState(() => _dob = d);
                  }),
            ]),
            _field('Phone *', _phone, keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Required' : null),
            _field('Email', _email, keyboardType: TextInputType.emailAddress),
            _field('Address', _address, maxLines: 2),
            const SizedBox(height: 20),
            _SectionHeader('Employment Details'),
            const SizedBox(height: 12),
            depts.when(
              data: (list) => _dropdown('Department', _departmentId, list.map<DropdownMenuItem<String>>((d) => DropdownMenuItem(value: d['_id'], child: Text(d['name'] ?? ''))).toList(), (v) => setState(() => _departmentId = v)),
              loading: () => const SizedBox(height: 56, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (_, _) => const SizedBox(),
            ),
            const SizedBox(height: 12),
            desigs.when(
              data: (list) => _dropdown('Designation', _designationId, list.map<DropdownMenuItem<String>>((d) => DropdownMenuItem(value: d['_id'], child: Text(d['title'] ?? ''))).toList(), (v) => setState(() => _designationId = v)),
              loading: () => const SizedBox(height: 56, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (_, _) => const SizedBox(),
            ),
            const SizedBox(height: 12),
            _dropdown('Employment Type', _employmentType, const [
              DropdownMenuItem(value: 'Full-time', child: Text('Full-time')),
              DropdownMenuItem(value: 'Part-time', child: Text('Part-time')),
              DropdownMenuItem(value: 'Contract', child: Text('Contract')),
            ], (v) => setState(() => _employmentType = v!)),
            const SizedBox(height: 12),
            _field('Hourly Rate (NPR) *', _hourlyRate, keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : (double.tryParse(v) == null ? 'Invalid number' : null)),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Joining Date'),
              subtitle: Text('${_joiningDate.day}/${_joiningDate.month}/${_joiningDate.year}'),
              trailing: TextButton(
                onPressed: () async {
                  final d = await showDatePicker(context: context, initialDate: _joiningDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (d != null) setState(() => _joiningDate = d);
                },
                child: const Text('Change'),
              ),
            ),
            const SizedBox(height: 20),
            _SectionHeader('Emergency Contact'),
            const SizedBox(height: 12),
            _field('Contact Name', _emergencyName),
            _row([
              _field('Phone', _emergencyPhone, keyboardType: TextInputType.phone),
              _field('Relation', _emergencyRelation),
            ]),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white) : const Text('Add Employee'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController? controller, {
    TextInputType? keyboardType, String? Function(String?)? validator, int maxLines = 1,
    bool readOnly = false, VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(color: AppTheme.onSurface),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _row(List<Widget> children) {
    return Row(children: children.map((w) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: w))).toList());
  }

  Widget _dropdownGender() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: _gender,
        decoration: const InputDecoration(labelText: 'Gender'),
        items: const [
          DropdownMenuItem(value: 'Male', child: Text('Male')),
          DropdownMenuItem(value: 'Female', child: Text('Female')),
          DropdownMenuItem(value: 'Other', child: Text('Other')),
        ],
        onChanged: (v) => setState(() => _gender = v!),
      ),
    );
  }

  Widget _dropdown<T>(String label, T? value, List<DropdownMenuItem<T>> items, void Function(T?) onChanged) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: onChanged,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.secondary));
}
