import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:html' as web if (dart.library.html) 'dart:html'; // web only import
// Note: conditional import for web usage shown later

class AuthRepository {
  final String baseUrl; // e.g. http://localhost/algraphy_api/auth for Android emulator or http://localhost...
  final _secureStorage = const FlutterSecureStorage();

  AuthRepository({required this.baseUrl});

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login.php');
    final resp = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}));
    final body = jsonDecode(resp.body);
    if (resp.statusCode == 200 && body['success'] == true) {
      final token = body['token'];
      final user = body['user'];
      await persistToken(token);
      return {'token': token, 'user': user};
    } else {
      throw Exception(body['message'] ?? 'Login failed');
    }
  }

  Future<void> persistToken(String token) async {
    if (kIsWeb) {
      // web: localStorage
      web.window.localStorage['algraphy_token'] = token;
    } else {
      await _secureStorage.write(key: 'algraphy_token', value: token);
    }
  }

  Future<String?> getToken() async {
    if (kIsWeb) {
      return web.window.localStorage['algraphy_token'];
    } else {
      return await _secureStorage.read(key: 'algraphy_token');
    }
  }

  Future<void> deleteToken() async {
    if (kIsWeb) {
      web.window.localStorage.remove('algraphy_token');
    } else {
      await _secureStorage.delete(key: 'algraphy_token');
    }
  }

  Future<Map<String, dynamic>> fetchMe(String token) async {
    final url = Uri.parse('$baseUrl/me.php');
    final resp = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    throw Exception('Failed to fetch me');
  }
}
