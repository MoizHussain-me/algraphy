import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'local_db_service_mobile.dart'
    if (dart.library.js_interop) 'local_db_service_web.dart';

abstract class LocalDbService {
  Future<String?> read(String key);
  Future<void> write(String key, String content);

  // JSON helpers
  Future<dynamic> readJson(String key) async {
    final raw = await read(key);
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  Future<void> writeJson(String key, dynamic value) async {
    final raw = jsonEncode(value);
    await write(key, raw);
  }

  String generateId() => const Uuid().v4();

  factory LocalDbService() => createLocalDbService();
}
