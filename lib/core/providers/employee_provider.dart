import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';
import '../services/employee_service.dart';

final employeeListProvider = FutureProvider.family<List<dynamic>, String?>((ref, query) async {
  final api = ref.read(apiClientProvider);
  String path = '/employees';
  if (query != null && query.isNotEmpty) {
    path = '$path?$query';
  }
  final res = await api.get(path);
  return (res is Map && res['data'] is List) ? List<dynamic>.from(res['data']) : [];
});

final employeeServiceProvider = Provider((ref) => EmployeeService(ref.read(apiClientProvider)));
