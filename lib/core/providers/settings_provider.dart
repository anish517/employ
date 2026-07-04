import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';
import '../services/settings_service.dart';

final settingsServiceProvider = Provider((ref) => SettingsService(ref.read(apiClientProvider)));

final settingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(settingsServiceProvider);
  final res = await api.getSettings();
  if (res['data'] is Map) return Map<String, dynamic>.from(res['data']);
  return {};
});

final leaveTypeListProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/leave-types');
  return (res is Map && res['data'] is List) ? List<dynamic>.from(res['data']) : [];
});

final salaryHistoryProvider = FutureProvider.family<List<dynamic>, Map<String, String>?>((ref, params) async {
  final api = ref.read(apiClientProvider);
  String path = '/salary-history';
  if (params != null && params.isNotEmpty) {
    final qs = params.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
    path = '$path?$qs';
  }
  final res = await api.get(path);
  return (res is Map && res['data'] is List) ? List<dynamic>.from(res['data']) : [];
});
