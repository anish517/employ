import '../services/api_client.dart';

class SettingsService {
  final ApiClient api;
  SettingsService(this.api);

  Future<Map<String, dynamic>> getSettings() async {
    return await api.get('/settings');
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> payload) async {
    return await api.put('/settings', payload);
  }
}
