import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/designation_provider.dart';
import '../../../core/providers/department_provider.dart';
// Removed unused import
import '../../../core/services/designation_service.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/theme/app_theme.dart';

class DesignationScreen extends ConsumerStatefulWidget {
  const DesignationScreen({super.key});

  @override
  ConsumerState<DesignationScreen> createState() => _DesignationScreenState();
}

class _DesignationScreenState extends ConsumerState<DesignationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  String? _departmentId;
  bool _saving = false;

  late DesignationService _service;

  @override
  void initState() {
    super.initState();
    _service = DesignationService(ref.read(apiClientProvider));
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _showForm([Map<String, dynamic>? desig]) {
    if (desig != null) {
      _title.text = desig['title'] ?? '';
      _departmentId = desig['departmentId'];
    } else {
      _title.clear();
      _departmentId = null;
    }

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (ctx, setState) {
          final depts = ref.watch(departmentListProvider);
          return AlertDialog(
            title: Text(desig == null ? 'Add Designation' : 'Edit Designation'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'Title *'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  depts.when(
                    data: (list) => DropdownButtonFormField<String>(
                      initialValue: _departmentId,
                      decoration: const InputDecoration(labelText: 'Department (Optional)'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None')),
                        ...list.map((d) => DropdownMenuItem<String>(value: d['_id'], child: Text(d['name'] ?? ''))),
                      ],
                      onChanged: (v) => setState(() => _departmentId = v),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, _) => const Text('Error loading departments'),
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
                    final payload = {'title': _title.text.trim()};
                    if (_departmentId != null) payload['departmentId'] = _departmentId!;
                    
                    if (desig == null) {
                      await _service.createDesignation(payload);
                    } else {
                      await _service.updateDesignation(desig['_id'], payload);
                    }
                    ref.invalidate(designationListProvider);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Designation ${desig == null ? 'added' : 'updated'}')));
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
        title: const Text('Delete Designation?'),
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
      await _service.deleteDesignation(id);
      ref.invalidate(designationListProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Designation deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(designationListProvider);
    final depts = ref.watch(departmentListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Designations')),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          async.when(
            data: (list) => list.isEmpty
                ? const EmptyView(message: 'No designations found', icon: Icons.work_outline_rounded)
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final desig = list[i];
                      
                      String deptName = 'No Department';
                      if (desig['departmentId'] != null && depts.hasValue) {
                        final deptList = depts.value!;
                        final matched = deptList.where((d) => d['_id'] == desig['departmentId']).toList();
                        if (matched.isNotEmpty) deptName = matched.first['name'] ?? 'Unknown';
                      }

                      return AppCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(desig['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          subtitle: Text(deptName, style: TextStyle(color: AppTheme.onSurface.withValues(alpha: 0.6))),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.edit_rounded, color: AppTheme.secondary), onPressed: () => _showForm(desig)),
                              IconButton(icon: const Icon(Icons.delete_rounded, color: AppTheme.error), onPressed: () => _delete(desig['_id'])),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(designationListProvider)),
          ),
          if (_saving)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Designation'),
      ),
    );
  }
}
