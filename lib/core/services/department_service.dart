import '../services/api_client.dart';

class DepartmentService {
  final ApiClient api;
  DepartmentService(this.api);

  Future<Map<String, dynamic>> createDepartment(Map<String, dynamic> payload) async {
    return await api.post('/departments', payload);
  }

  Future<Map<String, dynamic>> updateDepartment(String id, Map<String, dynamic> payload) async {
    return await api.put('/departments/$id', payload);
  }

  Future<void> deleteDepartment(String id) async {
    await api.delete('/departments/$id');
  }
}
