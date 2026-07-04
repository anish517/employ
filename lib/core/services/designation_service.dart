import '../services/api_client.dart';

class DesignationService {
  final ApiClient api;
  DesignationService(this.api);

  Future<Map<String, dynamic>> createDesignation(Map<String, dynamic> payload) async {
    return await api.post('/designations', payload);
  }

  Future<Map<String, dynamic>> updateDesignation(String id, Map<String, dynamic> payload) async {
    return await api.put('/designations/$id', payload);
  }

  Future<void> deleteDesignation(String id) async {
    await api.delete('/designations/$id');
  }
}
