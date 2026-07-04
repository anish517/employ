import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/employee_provider.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/theme/app_theme.dart';

class EmployeeListScreen extends ConsumerStatefulWidget {
  const EmployeeListScreen({super.key});
  @override
  ConsumerState<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends ConsumerState<EmployeeListScreen> {
  final _search = TextEditingController();
  String? _statusFilter;
  Map<String, String>? _params;

  void _applyFilters() {
    final params = <String, String>{};
    if (_search.text.isNotEmpty) params['search'] = _search.text;
    if (_statusFilter != null) params['status'] = _statusFilter!;
    setState(() => _params = params.isEmpty ? null : params);
    ref.invalidate(employeeListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(employeeListProvider(_params));
    return Scaffold(
      appBar: AppBar(title: const Text('Employees')),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Search & filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onSubmitted: (_) => _applyFilters(),
                  decoration: const InputDecoration(
                    hintText: 'Search by name, email, phone...',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String?>(
                icon: const Icon(Icons.filter_list_rounded),
                onSelected: (v) { setState(() => _statusFilter = v); _applyFilters(); },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: null, child: Text('All')),
                  const PopupMenuItem(value: 'Active', child: Text('Active')),
                  const PopupMenuItem(value: 'Inactive', child: Text('Inactive')),
                ],
              ),
            ]),
          ),
          if (_statusFilter != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: Row(children: [
                Chip(label: Text('Status: $_statusFilter'), onDeleted: () { setState(() => _statusFilter = null); _applyFilters(); }),
              ]),
            ),
          Expanded(
            child: async.when(
              data: (list) => list.isEmpty
                  ? const EmptyView(message: 'No employees found', icon: Icons.people_alt_outlined)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (c, i) {
                        final e = list[i];
                        final name = e['fullName'] ?? 'Unnamed';
                        final id = e['employeeId'] ?? '';
                        final status = e['status'] ?? 'Active';
                        return AppCard(
                          onTap: () => Navigator.pushNamed(context, '/employees/detail', arguments: e['_id']),
                          child: Row(children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                              child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'E',
                                  style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(id, style: TextStyle(color: AppTheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                              Text('Hourly: NPR ${e['hourlyRate'] ?? 0}',
                                  style: TextStyle(color: AppTheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                            ])),
                            StatusChip(status: status),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded, size: 18),
                          ]),
                        );
                      },
                    ),
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(employeeListProvider)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/employees/add'),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Employee'),
      ),
    );
  }
}
