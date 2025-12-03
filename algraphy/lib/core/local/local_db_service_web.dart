import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:web/web.dart' as web;
import 'local_db_service.dart';

class LocalDbServiceWeb implements LocalDbService {
  @override
  Future<String?> read(String key) async {
    final storage = web.window.localStorage;
    return storage.getItem(key);
  }

  @override
  Future<void> write(String key, String content) async {
    final storage = web.window.localStorage;
    storage.setItem(key, content);
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

LocalDbService createLocalDbService() => LocalDbServiceWeb();
