import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class ApiClient {
  final String baseUrl;
  final FlutterSecureStorage storage;
  ApiClient({this.baseUrl = apiBaseUrl, FlutterSecureStorage? storage}) : storage = storage ?? const FlutterSecureStorage();

  Future<dynamic> post(String path, Map<String, dynamic> body, {Map<String,String>? headers}) async {
    return _send('POST', path, body: json.encode(body), headers: {'Content-Type':'application/json', ...?headers});
  }

  Future<dynamic> get(String path, {Map<String,String>? headers}) async {
    return _send('GET', path, headers: {...?headers});
  }

  Future<dynamic> put(String path, Map<String, dynamic> body, {Map<String,String>? headers}) async {
    return _send('PUT', path, body: json.encode(body), headers: {'Content-Type':'application/json', ...?headers});
  }

  Future<dynamic> delete(String path, {Map<String,String>? headers}) async {
    return _send('DELETE', path, headers: {...?headers});
  }

  Future<Uint8List> downloadBytes(String path, {Map<String,String>? headers}) async {
    headers = {...?headers};
    final token = await storage.read(key: 'accessToken');
    if(token != null){
      headers = {...headers, 'Authorization': 'Bearer $token'};
    }
    var res = await http.get(Uri.parse('$baseUrl$path'), headers: headers).timeout(const Duration(seconds: 10));
    if(res.statusCode == 401){
      final refreshed = await _tryRefresh();
      if(refreshed){
        final newToken = await storage.read(key: 'accessToken');
        if(newToken != null) headers = {...headers, 'Authorization': 'Bearer $newToken'};
        res = await http.get(Uri.parse('$baseUrl$path'), headers: headers).timeout(const Duration(seconds: 10));
      }
    }
    if(res.statusCode >=200 && res.statusCode < 300){
      return res.bodyBytes;
    }
    throw Exception('Download failed ${res.statusCode}');
  }

  Future<dynamic> _send(String method, String path, {String? body, Map<String,String>? headers}) async {
    headers = {...?headers};
    final token = await storage.read(key: 'accessToken');
    if(token != null){
      headers = {...headers, 'Authorization': 'Bearer $token'};
    }

    http.Response res;
    if(method == 'GET'){
      res = await http.get(Uri.parse('$baseUrl$path'), headers: headers).timeout(const Duration(seconds: 10));
    } else if(method == 'POST'){
      res = await http.post(Uri.parse('$baseUrl$path'), headers: headers, body: body).timeout(const Duration(seconds: 10));
    } else if(method == 'PUT'){
      res = await http.put(Uri.parse('$baseUrl$path'), headers: headers, body: body).timeout(const Duration(seconds: 10));
    } else if(method == 'DELETE'){
      res = await http.delete(Uri.parse('$baseUrl$path'), headers: headers).timeout(const Duration(seconds: 10));
    } else {
      throw Exception('Unsupported method $method');
    }

    if(res.statusCode == 401){
      final refreshed = await _tryRefresh();
      if(refreshed){
        final newToken = await storage.read(key: 'accessToken');
        if(newToken != null) headers = {...headers, 'Authorization': 'Bearer $newToken'};
        if(method == 'GET'){
          res = await http.get(Uri.parse('$baseUrl$path'), headers: headers).timeout(const Duration(seconds: 10));
        } else if(method == 'POST'){
          res = await http.post(Uri.parse('$baseUrl$path'), headers: headers, body: body).timeout(const Duration(seconds: 10));
        } else if(method == 'PUT'){
          res = await http.put(Uri.parse('$baseUrl$path'), headers: headers, body: body).timeout(const Duration(seconds: 10));
        } else if(method == 'DELETE'){
          res = await http.delete(Uri.parse('$baseUrl$path'), headers: headers).timeout(const Duration(seconds: 10));
        }
      }
    }

    if(res.statusCode >= 200 && res.statusCode < 300){
      try{ return json.decode(res.body); }catch(e){ return res.body; }
    }

    try{
      final err = json.decode(res.body);
      throw Exception('API error ${res.statusCode}: $err');
    }catch(_){
      throw Exception('API error ${res.statusCode}: ${res.body}');
    }
  }

  Future<bool> _tryRefresh() async {
    final refresh = await storage.read(key: 'refreshToken');
    if(refresh == null) return false;
    try{
      final res = await http.post(Uri.parse('$baseUrl/auth/refresh'), headers: {'Content-Type':'application/json'}, body: json.encode({ 'refreshToken': refresh })).timeout(const Duration(seconds: 10));
      if(res.statusCode >=200 && res.statusCode < 300){
        final body = json.decode(res.body);
        final data = body['data'] ?? body;
        if(data != null && data['accessToken'] != null){
          await storage.write(key: 'accessToken', value: data['accessToken']);
          if(data['refreshToken'] != null) await storage.write(key: 'refreshToken', value: data['refreshToken']);
          return true;
        }
      }
    }catch(e){ /* ignore */ }
    return false;
  }
}
