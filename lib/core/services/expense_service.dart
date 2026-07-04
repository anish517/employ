import '../services/api_client.dart';

class ExpenseService {
  final ApiClient api;
  ExpenseService(this.api);

  Future<Map<String, dynamic>> getExpenses([Map<String, String>? params]) async {
    String path = '/expenses';
    if (params != null && params.isNotEmpty) {
      final qs = params.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
      path = '$path?$qs';
    }
    return await api.get(path); // Returns { data: [...], summary: {...} }
  }

  Future<Map<String, dynamic>> createExpense(Map<String, dynamic> payload) async {
    return await api.post('/expenses', payload);
  }

  Future<Map<String, dynamic>> updateExpense(String id, Map<String, dynamic> payload) async {
    return await api.put('/expenses/$id', payload);
  }

  Future<void> deleteExpense(String id) async {
    await api.delete('/expenses/$id');
  }
}
