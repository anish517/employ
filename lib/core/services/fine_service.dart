import '../services/api_client.dart';

class FineService{
  final ApiClient api;
  FineService(this.api);

  Future<Map<String,dynamic>> create(Map<String,dynamic> payload) async{
    return await api.post('/fines', payload);
  }

  Future<List<dynamic>> list() async{
    final res = await api.get('/fines');
    final data = res['data'] ?? res;
    return (data is List)? List<dynamic>.from(data) : [];
  }
}
