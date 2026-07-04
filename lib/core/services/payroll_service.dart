import '../services/api_client.dart';

class PayrollService {
  final ApiClient api;
  PayrollService(this.api);

  Future<List<dynamic>> getSalaryRecords([Map<String, String>? params]) async {
    String path = '/salary';
    if (params != null && params.isNotEmpty) {
      final qs = params.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
      path = '$path?$qs';
    }
    final res = await api.get(path);
    final data = res['data'] ?? res;
    return (data is List) ? List<dynamic>.from(data) : [];
  }

  Future<Map<String, dynamic>> calculateSalary(String month, String employeeId) async {
    return await api.post('/salary/calculate', {
      'month': month,
      'employeeId': employeeId,
    });
  }

  Future<Map<String, dynamic>> processSalary(String month, String employeeId) async {
    return await api.post('/salary/process', {
      'month': month,
      'employeeId': employeeId,
    });
  }

  Future<Map<String, dynamic>> finalizePayroll(String month) async {
    return await api.post('/salary/finalize', {
      'month': month,
    });
  }
}
