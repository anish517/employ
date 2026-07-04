import '../services/api_client.dart';

class BonusService {
  final ApiClient api;

  BonusService(this.api);

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    return await api.post('/bonuses', payload);
  }

  Future<List<dynamic>> list([Map<String, String>? params]) async {
    final res = await api.get('/bonuses');
    final data = res['data'] ?? res;
    return (data is List) ? List<dynamic>.from(data) : [];
  }
}
