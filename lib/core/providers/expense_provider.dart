import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';
import '../services/expense_service.dart';

final expenseListProvider = FutureProvider.family<Map<String, dynamic>, Map<String, String>?>((ref, params) async {
  final api = ref.read(apiClientProvider);
  String path = '/expenses';
  if (params != null && params.isNotEmpty) {
    final qs = params.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
    path = '$path?$qs';
  }
  final res = await api.get(path);
  return res as Map<String, dynamic>; // Contains 'data' and 'summary'
});

final expenseServiceProvider = Provider((ref) => ExpenseService(ref.read(apiClientProvider)));
