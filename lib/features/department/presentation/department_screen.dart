import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/department_provider.dart';
// Removed unused import
import '../../../core/services/department_service.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/theme/app_theme.dart';

class DepartmentScreen extends ConsumerStatefulWidget {
  const DepartmentScreen({super.key});

  @override
  ConsumerState<DepartmentScreen> createState() => _DepartmentScreenState();
}

class _DepartmentScreenState extends ConsumerState<DepartmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  bool _saving = false;

  late DepartmentService _service;

  @override
  void initState() {
    super.initState();
    _service = DepartmentService(ref.read(apiClientProvider));
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _showForm([Map<String, dynamic>? dept]) {
    if (dept != null) {
      _name.text = dept['name'] ?? '';
      _description.text = dept['description'] ?? '';
    } else {
      _name.clear();
      _description.clear();
    }

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(dept == null ? 'Add Department' : 'Edit Department'),
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
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
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
              setState(() => _saving = true);
              try {
                final payload = {'name': _name.text.trim(), 'description': _description.text.trim()};
                if (dept == null) {
                  await _service.createDepartment(payload);
                } else {
                  await _service.updateDepartment(dept['_id'], payload);
                }
                ref.invalidate(departmentListProvider);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Department ${dept == null ? 'added' : 'updated'}')));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
              } finally {
                if (mounted) setState(() => _saving = false);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Department?'),
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
      await _service.deleteDepartment(id);
      ref.invalidate(departmentListProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Department deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(departmentListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Departments')),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          async.when(
            data: (list) => list.isEmpty
                ? const EmptyView(message: 'No departments found', icon: Icons.business_rounded)
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final dept = list[i];
                      return AppCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(dept['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          subtitle: Text(dept['description'] ?? '', style: TextStyle(color: AppTheme.onSurface.withValues(alpha: 0.6))),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.edit_rounded, color: AppTheme.secondary), onPressed: () => _showForm(dept)),
                              IconButton(icon: const Icon(Icons.delete_rounded, color: AppTheme.error), onPressed: () => _delete(dept['_id'])),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(departmentListProvider)),
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
        label: const Text('Add Department'),
      ),
    );
  }
}
