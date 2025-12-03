import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'local_db_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDbServiceMobile implements LocalDbService {
  SharedPreferences? _prefs;

  Future<void> _init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<String?> read(String key) async {
    await _init();
    return _prefs!.getString(key);
  }

  @override
  Future<void> write(String key, String content) async {
    await _init();
    await _prefs!.setString(key, content);
  }
  
  @override
  String generateId() => const Uuid().v4();
  
  @override
  Future<dynamic> readJson(String key)  async{
     final raw = await read(key);
    if (raw == null) return null;
    return jsonDecode(raw);
  }
  
  @override
  Future<void> writeJson(String key, value) async {
    final raw = jsonEncode(value);
    await write(key, raw);
  }
}

LocalDbService createLocalDbService() => LocalDbServiceMobile();
