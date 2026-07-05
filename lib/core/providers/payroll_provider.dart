import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';
import '../services/payroll_service.dart';

final salaryListProvider = FutureProvider.family<List<dynamic>, String?>((ref, month) async {
  final api = ref.read(apiClientProvider);
  String path = '/salary';
  if (month != null && month.isNotEmpty) {
    path = '$path?month=${Uri.encodeComponent(month)}';
  }
  final res = await api.get(path);
  return (res is Map && res['data'] is List) ? List<dynamic>.from(res['data']) : [];
});

final payrollServiceProvider = Provider((ref) => PayrollService(ref.read(apiClientProvider)));
