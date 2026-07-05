import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/holiday_provider.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/theme/app_theme.dart';

class HolidaysScreen extends ConsumerStatefulWidget {
  const HolidaysScreen({super.key});

  @override
  ConsumerState<HolidaysScreen> createState() => _HolidaysScreenState();
}

class _HolidaysScreenState extends ConsumerState<HolidaysScreen> {
  int _selectedYear = DateTime.now().year;
  bool _saving = false;

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  final _description = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _showForm([Map<String, dynamic>? holiday]) {
    if (holiday != null) {
      _name.text = holiday['name'] ?? '';
      _startDate = holiday['startDate'] != null ? DateTime.parse(holiday['startDate']) : DateTime.now();
      _endDate = holiday['endDate'] != null ? DateTime.parse(holiday['endDate']) : DateTime.now();
      _description.text = holiday['description'] ?? '';
    } else {
      _name.clear();
      _startDate = DateTime.now();
      _endDate = DateTime.now();
      _description.clear();
    }

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(holiday == null ? 'Add Holiday' : 'Edit Holiday'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Name *'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text('${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final d = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (d != null) setState(() { _startDate = d; if (_endDate.isBefore(d)) _endDate = d; });
                    },
                  ),
                  ListTile(
                    title: const Text('End Date'),
                    subtitle: Text('${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final d = await showDatePicker(context: context, initialDate: _endDate, firstDate: _startDate, lastDate: DateTime(2100));
                      if (d != null) setState(() => _endDate = d);
                    },
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
                    'startDate': _startDate.toIso8601String().split('T')[0],
                    'endDate': _endDate.toIso8601String().split('T')[0],
                    'description': _description.text.trim(),
                  };
                  
                  if (holiday == null) {
                    await ref.read(holidayServiceProvider).createHoliday(payload);
                  } else {
                    await ref.read(holidayServiceProvider).updateHoliday(holiday['_id'], payload);
                  }
                  ref.invalidate(holidayListProvider);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Holiday ${holiday == null ? 'added' : 'updated'}')));
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
        title: const Text('Delete Holiday?'),
        content: const Text('Are you sure you want to delete this holiday?'),
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
      await ref.read(holidayServiceProvider).deleteHoliday(id);
      ref.invalidate(holidayListProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Holiday deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(holidayListProvider(_selectedYear.toString()));

    return Scaffold(
      appBar: AppBar(title: const Text('Holidays')),
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
                  DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      items: List.generate(5, (index) {
                        final y = DateTime.now().year - 2 + index;
                        return DropdownMenuItem(value: y, child: Text(y.toString()));
                      }),
                      onChanged: (v) => setState(() => _selectedYear = v!),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                async.when(
                  data: (list) {
                    if (list.isEmpty) return EmptyView(message: 'No holidays found for $_selectedYear', icon: Icons.celebration_rounded);
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final holiday = list[i];
                        final start = holiday['startDate'] != null ? DateTime.parse(holiday['startDate']).toString().split(' ')[0] : '';
                        final end = holiday['endDate'] != null ? DateTime.parse(holiday['endDate']).toString().split(' ')[0] : '';
                        
                        return AppCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(holiday['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Text('$start to $end\n${holiday['description'] ?? ''}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit_rounded, color: AppTheme.secondary), onPressed: () => _showForm(holiday)),
                                IconButton(icon: const Icon(Icons.delete_rounded, color: AppTheme.error), onPressed: () => _delete(holiday['_id'])),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const LoadingView(),
                  error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(holidayListProvider)),
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
        label: const Text('Add Holiday'),
      ),
    );
  }
}
