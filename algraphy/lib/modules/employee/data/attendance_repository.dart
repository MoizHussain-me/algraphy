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
  Future<void> checkIn() async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await _api.post('check_in', {}, token: token);

    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? "Check-in failed");
    }
  }

  // --- 2. Check Out ---
  Future<void> checkOut() async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await _api.post('check_out', {}, token: token);

    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? "Check-out failed");
    }
  }

  // --- 3. Get Today's Status (For Button State & Timer) ---
  Future<Map<String, dynamic>> getTodayStatus() async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await _api.get('attendance_status', token: token);

    if (response['status'] == 'success') {
      return response['data']; 
      // Returns: { 'isCheckedIn': true/false, 'checkInTime': '2023-10-27 09:00:00', ... }
    } else {
      throw Exception(response['message']);
    }
  }

  // --- 4. Get History (For Timeline) ---
  Future<List<Map<String, dynamic>>> getHistory() async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await _api.get('my_attendance_history', token: token);

    if (response['status'] == 'success') {
      return List<Map<String, dynamic>>.from(response['data']);
    } else {
      throw Exception(response['message']);
    }
  }
  
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