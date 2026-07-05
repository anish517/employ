import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';
import '../services/leave_service.dart';

final leaveListProvider = FutureProvider.family<List<dynamic>, String?>((ref, status) async {
  final api = ref.read(apiClientProvider);
  String path = '/leave';
  if (status != null && status.isNotEmpty) {
    path = '$path?status=${Uri.encodeComponent(status)}';
  }
  final res = await api.get(path);
  return (res is Map && res['data'] is List) ? List<dynamic>.from(res['data']) : [];
});

final leaveServiceProvider = Provider((ref) => LeaveService(ref.read(apiClientProvider)));
