import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/utils/constants.dart';

class AttendanceRepository {
  final ApiClient _api = ApiClient();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  // --- 1. Check In ---
  Future<void> checkIn(String userId) async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await _api.post('check_in', {}, token: token);

    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? "Check-in failed");
    }
  }

  // --- 2. Toggle Break (FIXED) ---
  Future<void> toggleBreak(String status) async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    // We don't need attendanceId, the backend finds the active session by Token
    final response = await _api.post('toggle_break', {'status': status}, token: token);

    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? "Failed to update break status");
    }
  }

  // --- 3. Check Out ---
  Future<void> checkOut(String attendanceId) async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await _api.post('check_out', {}, token: token);

    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? "Check-out failed");
    }
  }

  // --- 4. Get Today's Status ---
  Future<Map<String, dynamic>?> getTodayAttendance(String userId) async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    try {
      final response = await _api.get('attendance_status', token: token);

      if (response['status'] == 'success') {
        return response['data'];
      } else {
        return null; 
      }
    } catch (e) {
      return null;
    }
  }

  // --- 5. Get History (FIXED NULL CRASH) ---
  Future<List<Map<String, dynamic>>> getHistory() async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await _api.get('my_attendance_history', token: token);

    if (response['status'] == 'success') {
      // The API returns nulls for clock_out/work_hours. 
      // We pass it as-is, but the UI MUST handle nulls.
      return List<Map<String, dynamic>>.from(response['data']);
    } else {
      throw Exception(response['message']);
    }
  }

  // --- 6. Dashboard Stats ---
  Future<Map<String, dynamic>> getDashboardStats() async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await _api.get('dashboard_stats', token: token);

    if (response['status'] == 'success') {
      return response['data'];
    } else {
      throw Exception(response['message']);
    }
  }
}