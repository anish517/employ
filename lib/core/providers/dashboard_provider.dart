import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';

final dashboardSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/dashboard/summary');
  if (res is Map && res['data'] is Map) return Map<String, dynamic>.from(res['data']);
  return {};
});
