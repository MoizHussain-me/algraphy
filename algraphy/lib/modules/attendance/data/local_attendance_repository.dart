import 'package:algraphy/modules/attendance/data/models/attendance_model.dart';
import '../../../core/local/local_db_service.dart';

class LocalAttendanceRepository {
  final LocalDbService _db = LocalDbService();

  // file naming per user: attendance_{userId}.json
  String _fileNameForUser(String userId) => 'attendance_$userId.json';

  Future<Map<String, AttendanceModel>> _readAll(String userId) async {
    final file = _fileNameForUser(userId);
    final raw = await _db.readJson(file);
    if (raw == null) return {};
    final map = Map<String, dynamic>.from(raw as Map);
    final out = <String, AttendanceModel>{};
    map.forEach((date, m) {
      out[date] = AttendanceModel.fromMap(Map<String, dynamic>.from(m));
    });
    return out;
  }

  Future<void> _writeAll(String userId, Map<String, AttendanceModel> data) async {
    final file = _fileNameForUser(userId);
    final encoded = <String, dynamic>{};
    data.forEach((k, v) {
      encoded[k] = v.toMap();
    });
    await _db.writeJson(file, encoded);
  }

  Future<AttendanceModel?> getForDate(String userId, String yyyyMMdd) async {
    final all = await _readAll(userId);
    return all[yyyyMMdd];
  }

  Future<void> checkIn(String userId, String yyyyMMdd, String timestamp) async {
    final all = await _readAll(userId);
    final existing = all[yyyyMMdd];
    if (existing != null && existing.checkIn != null) {
      // already checked in — override allowed? we'll keep existing
      return;
    }
    final model = AttendanceModel(date: yyyyMMdd, checkIn: timestamp, checkOut: existing?.checkOut);
    all[yyyyMMdd] = model;
    await _writeAll(userId, all);
  }

  Future<void> checkOut(String userId, String yyyyMMdd, String timestamp) async {
    final all = await _readAll(userId);
    final existing = all[yyyyMMdd];
    if (existing == null) {
      // can't checkout without checkIn — create a record with null checkIn
      final model = AttendanceModel(date: yyyyMMdd, checkIn: null, checkOut: timestamp);
      all[yyyyMMdd] = model;
    } else {
      final model = existing.copyWith(checkOut: timestamp);
      all[yyyyMMdd] = model;
    }
    await _writeAll(userId, all);
  }

  Future<List<AttendanceModel>> getHistory(String userId) async {
    final all = await _readAll(userId);
    final values = all.values.toList();
    values.sort((a, b) => b.date.compareTo(a.date));
    return values;
  }
}
