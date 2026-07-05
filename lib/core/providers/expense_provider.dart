import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';
import '../services/expense_service.dart';

final expenseListProvider = FutureProvider.family<Map<String, dynamic>, String?>((ref, month) async {
  final api = ref.read(apiClientProvider);
  String path = '/expenses';
  if (month != null && month.isNotEmpty) {
    path = '$path?month=${Uri.encodeComponent(month)}';
  }
  final res = await api.get(path);
  return res as Map<String, dynamic>;
});

final expenseServiceProvider = Provider((ref) => ExpenseService(ref.read(apiClientProvider)));
