import '../services/api_client.dart';

class AttendanceService {
  final ApiClient api;
  AttendanceService(this.api);

  Future<Map<String, dynamic>> mark(Map<String, dynamic> payload) async {
    return await api.post('/attendance/mark', payload);
  }

  Future<Map<String, dynamic>> bulkMark(Map<String, dynamic> payload) async {
    return await api.post('/attendance/bulk-mark', payload);
  }

  Future<List<dynamic>> monthly(String month, {String? employeeId}) async {
    String url = '/attendance/monthly?month=${Uri.encodeComponent(month)}';
    if (employeeId != null) {
      url += '&employeeId=${Uri.encodeComponent(employeeId)}';
    }
    final res = await api.get(url);
    final data = res['data'] ?? res;
    return (data is List) ? List<dynamic>.from(data) : [];
  }
}
