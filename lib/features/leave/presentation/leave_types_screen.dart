import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/leave_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';

class LeaveTypesScreen extends ConsumerStatefulWidget {
  const LeaveTypesScreen({super.key});

  @override
  ConsumerState<LeaveTypesScreen> createState() => _LeaveTypesScreenState();
}

class _LeaveTypesScreenState extends ConsumerState<LeaveTypesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _maxDays = TextEditingController();
  bool _isPaid = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _maxDays.dispose();
    super.dispose();
  }

  void _showForm([Map<String, dynamic>? type]) {
    if (type != null) {
      _name.text = type['name'] ?? '';
      _maxDays.text = (type['maxDaysPerYear'] ?? 0).toString();
      _isPaid = type['isPaid'] == true;
    } else {
      _name.clear();
      _maxDays.clear();
      _isPaid = false;
    }

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(type == null ? 'Add Leave Type' : 'Edit Leave Type'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name *'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _maxDays,
                  decoration: const InputDecoration(labelText: 'Max Days per Year *'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Is Paid Leave?'),
                  value: _isPaid,
                  onChanged: (v) => setState(() => _isPaid = v),
                ),
              ],
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
                    'name': _name.text.trim(),
                    'maxDaysPerYear': int.tryParse(_maxDays.text) ?? 0,
                    'isPaid': _isPaid,
                  };
                  
                  if (type == null) {
                    await ref.read(leaveServiceProvider).createLeaveType(payload);
                  } else {
                    await ref.read(leaveServiceProvider).updateLeaveType(type['_id'], payload);
                  }
                  ref.invalidate(leaveTypeListProvider);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Leave type ${type == null ? 'added' : 'updated'}')));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
                } finally {
                  if (mounted) this.setState(() => _saving = false);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Leave Type?'),
        content: const Text('Are you sure? This action cannot be undone.'),
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
      await ref.read(leaveServiceProvider).deleteLeaveType(id);
      ref.invalidate(leaveTypeListProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave type deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(leaveTypeListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Leave Types')),
      body: Stack(
        children: [
          async.when(
            data: (list) => list.isEmpty
                ? const EmptyView(message: 'No leave types found')
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final type = list[i];
                      return AppCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(type['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          subtitle: Text('Max: ${type['maxDaysPerYear']} days/year'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StatusChip(status: type['isPaid'] == true ? 'Paid' : 'Unpaid'),
                              IconButton(icon: const Icon(Icons.edit_rounded, color: AppTheme.secondary), onPressed: () => _showForm(type)),
                              IconButton(icon: const Icon(Icons.delete_rounded, color: AppTheme.error), onPressed: () => _delete(type['_id'])),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(leaveTypeListProvider)),
          ),
          if (_saving)
            Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator())),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Type'),
      ),
    );
  }
}
