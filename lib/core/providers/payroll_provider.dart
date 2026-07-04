import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';
import '../services/payroll_service.dart';

final salaryListProvider = FutureProvider.family<List<dynamic>, Map<String, String>?>((ref, params) async {
  final api = ref.read(apiClientProvider);
  String path = '/salary';
  if (params != null && params.isNotEmpty) {
    final qs = params.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
    path = '$path?$qs';
  }
  final res = await api.get(path);
  return (res is Map && res['data'] is List) ? List<dynamic>.from(res['data']) : [];
});

final payrollServiceProvider = Provider((ref) => PayrollService(ref.read(apiClientProvider)));
