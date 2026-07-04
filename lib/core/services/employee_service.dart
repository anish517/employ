import '../services/api_client.dart';

class EmployeeService{
  final ApiClient api;
  EmployeeService(this.api);

  Future<Map<String,dynamic>> createEmployee(Map<String,dynamic> payload) async{
    return await api.post('/employees', payload);
  }

  Future<Map<String,dynamic>> updateEmployee(String id, Map<String,dynamic> payload) async{
    return await api.put('/employees/$id', payload);
  }

  Future<void> deleteEmployee(String id) async{
    await api.delete('/employees/$id');
  }

  Future<Map<String,dynamic>> getEmployee(String id) async{
    final res = await api.get('/employees/$id');
    final data = res['data'] ?? res;
    return (data is Map) ? Map<String,dynamic>.from(data) : {};
  }

  Future<List<dynamic>> list([Map<String,String>? params]) async{
    String path = '/employees';
    if(params != null && params.isNotEmpty){
      final qs = params.entries.map((e)=> '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
      path = '$path?$qs';
    }
    final res = await api.get(path);
    final data = res['data'] ?? res;
    return (data is List) ? List<dynamic>.from(data) : [];
  }
}
