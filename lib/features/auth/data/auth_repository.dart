import 'package:employe_management/core/services/api_client.dart';

class AuthRepository {
  final ApiClient api;
  AuthRepository([ApiClient? api]) : api = api ?? ApiClient();

  Future<dynamic> login(String email, String password) =>
      api.post('/auth/login', {'email': email, 'password': password});
}
