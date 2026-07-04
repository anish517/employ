import '../services/api_client.dart';

class HolidayService {
  final ApiClient api;
  HolidayService(this.api);

  Future<List<dynamic>> getHolidays([Map<String, String>? params]) async {
    String path = '/holidays';
    if (params != null && params.isNotEmpty) {
      final qs = params.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
      path = '$path?$qs';
    }
    final res = await api.get(path);
    final data = res['data'] ?? res;
    return (data is List) ? List<dynamic>.from(data) : [];
  }

  Future<Map<String, dynamic>> createHoliday(Map<String, dynamic> payload) async {
    return await api.post('/holidays', payload);
  }

  Future<Map<String, dynamic>> updateHoliday(String id, Map<String, dynamic> payload) async {
    return await api.put('/holidays/$id', payload);
  }

  Future<void> deleteHoliday(String id) async {
    await api.delete('/holidays/$id');
  }
}
