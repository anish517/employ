import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyName = TextEditingController();
  final _currency = TextEditingController();
  final _timezone = TextEditingController();
  final _adminEmail = TextEditingController();
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _companyName.dispose();
    _currency.dispose();
    _timezone.dispose();
    _adminEmail.dispose();
    super.dispose();
  }

  void _init(Map<String, dynamic>? data) {
    if (_initialized || data == null) return;
    _companyName.text = data['companyName'] ?? '';
    _currency.text = data['currency'] ?? 'NPR';
    _timezone.text = data['timezone'] ?? 'Asia/Kathmandu';
    _adminEmail.text = data['adminEmail'] ?? '';
    _initialized = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final payload = {
        'companyName': _companyName.text.trim(),
        'currency': _currency.text.trim(),
        'timezone': _timezone.text.trim(),
        'adminEmail': _adminEmail.text.trim(),
      };
      
      await ref.read(settingsServiceProvider).updateSettings(payload);
      ref.invalidate(settingsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved successfully')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncSettings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Company Settings')),
      drawer: const AppDrawer(),
      body: asyncSettings.when(
        data: (settings) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _init(settings));
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('General Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                        const SizedBox(height: 24),
                        
                        const Text('Company Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _companyName,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 24),
                        
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Currency', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _currency,
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
                                  const Text('Timezone', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _timezone,
                                    validator: (v) => v!.isEmpty ? 'Required' : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        const Text('Admin Email', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _adminEmail,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 48),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Settings'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_saving) const Center(child: CircularProgressIndicator()),
            ],
          );
        },
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(settingsProvider)),
      ),
    );
  }
}
