import '../services/api_client.dart';

class LeaveService {
  final ApiClient api;
  LeaveService(this.api);

  Future<List<dynamic>> getLeaveRequests([Map<String, String>? params]) async {
    String path = '/leave';
    if (params != null && params.isNotEmpty) {
      final qs = params.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
      path = '$path?$qs';
    }
    final res = await api.get(path);
    final data = res['data'] ?? res;
    return (data is List) ? List<dynamic>.from(data) : [];
  }

  Future<Map<String, dynamic>> submitLeave(Map<String, dynamic> payload) async {
    return await api.post('/leave', payload);
  }

  Future<Map<String, dynamic>> updateLeaveStatus(String id, String status) async {
    return await api.put('/leave/$id/status', {'status': status});
  }

  // Leave Types
  Future<Map<String, dynamic>> createLeaveType(Map<String, dynamic> payload) async {
    return await api.post('/leave-types', payload);
  }

  Future<Map<String, dynamic>> updateLeaveType(String id, Map<String, dynamic> payload) async {
    return await api.put('/leave-types/$id', payload);
  }

  Future<void> deleteLeaveType(String id) async {
    await api.delete('/leave-types/$id');
  }
}
