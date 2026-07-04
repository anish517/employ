import '../services/api_client.dart';

class LoanService{
  final ApiClient api;
  LoanService(this.api);

  Future<Map<String,dynamic>> create(Map<String,dynamic> payload) async{
    return await api.post('/loans', payload);
  }

  Future<List<dynamic>> list() async{
    final res = await api.get('/loans');
    final data = res['data'] ?? res;
    return (data is List)? List<dynamic>.from(data) : [];
  }
}
