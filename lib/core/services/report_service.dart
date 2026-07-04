import '../services/api_client.dart';

class ReportService {
  final ApiClient api;
  ReportService(this.api);

  Future<Map<String, dynamic>> getAttendanceReport(String month) async {
    return await api.get('/reports/attendance?month=${Uri.encodeComponent(month)}');
  }

  Future<Map<String, dynamic>> getSalaryReport(String month) async {
    return await api.get('/reports/salary?month=${Uri.encodeComponent(month)}');
  }

  Future<Map<String, dynamic>> getLeaveReport(String month) async {
    return await api.get('/reports/leave?month=${Uri.encodeComponent(month)}');
  }

  Future<String> exportReport(String reportType, String format, String month) async {
    final res = await api.get('/reports/export?type=$reportType&format=$format&month=${Uri.encodeComponent(month)}');
    return res['downloadUrl'] ?? '';
  }
}
