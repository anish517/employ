import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';

class AuthService {
  final ApiClient api;
  final FlutterSecureStorage storage;
  AuthService({ApiClient? api, FlutterSecureStorage? storage})
    : api = api ?? ApiClient(),
      storage = storage ?? const FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await api.post('/auth/login', {
      'email': email,
      'password': password,
    });
    final data = res['data'] ?? res;
    if (data != null && data['accessToken'] != null) {
      await storage.write(key: 'accessToken', value: data['accessToken']);
      await storage.write(key: 'refreshToken', value: data['refreshToken']);
    }
    return data;
  }

  Future<void> logout() async {
    final refresh = await storage.read(key: 'refreshToken');
    if (refresh != null) {
      try {
        await api.post('/auth/logout', {'refreshToken': refresh});
      } catch (e) {
        // ignore logout errors to ensure local tokens are cleared
      }
    }
    await storage.deleteAll();
  }

  Future<String?> getAccessToken() => storage.read(key: 'accessToken');
}
