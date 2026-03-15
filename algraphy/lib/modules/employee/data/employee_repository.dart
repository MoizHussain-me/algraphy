import '../../../../core/api/api_client.dart';
import '../../../../core/services/session_service.dart';

class EmployeeRepository {
  final ApiClient _api = ApiClient();

  // ==========================================
  // MODULE 1: ATTENDANCE
  // ==========================================

  Future<void> checkIn() async {
    final token = await SessionService.getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await _api.post('check_in', {}, token: token);

    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? "Check-in failed");
    }
  }

  Future<void> toggleBreak(String status) async {
    final token = await SessionService.getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await _api.post('toggle_break', {'status': status}, token: token);

    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? "Failed to update break status");
    }
  }

  Future<void> checkOut() async {
    final token = await SessionService.getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await _api.post('check_out', {}, token: token);

    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? "Check-out failed");
    }
  }

  Future<Map<String, dynamic>?> getTodayStatus() async {
    final token = await SessionService.getToken();
    if (token == null) throw Exception("Not authenticated");

    try {
      final response = await _api.get('attendance_status', token: token);

      if (response['status'] == 'success') {
        return response; // Return full response to get 'data' and 'geofence'
      } else {
        return null; 
      }
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceHistory() async {
    final token = await SessionService.getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await _api.get('my_attendance_history', token: token);

    if (response['status'] == 'success') {
      return List<Map<String, dynamic>>.from(response['data']);
    } else {
      throw Exception(response['message']);
    }
  }

  // ==========================================
  // MODULE 2: DASHBOARD STATS
  // ==========================================

  Future<Map<String, dynamic>> getDashboardStats() async {
    final token = await SessionService.getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await _api.get('dashboard_stats', token: token);

    if (response['status'] == 'success') {
      return response['data'];
    } else {
      throw Exception(response['message']);
    }
  }

  // ==========================================
  // MODULE 3: LEAVES MANAGEMENT
  // ==========================================

  // 1. Get My Leaves (History & Balance)
  Future<Map<String, dynamic>> getMyLeaves() async {
    final token = await SessionService.getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await _api.get('my_leaves', token: token);

    if (response['status'] == 'success') {
      // Returns { "balance": 21, "history": [...] }
      return response['data']; 
    } else {
      throw Exception(response['message']);
    }
  }

  // 2. Apply for Leave
  Future<void> applyLeave(Map<String, dynamic> leaveData) async {
    final token = await SessionService.getToken();
    if (token == null) throw Exception("Not authenticated");

    // Route matches 'apply_leave' in api.php
    final response = await _api.post('apply_leave', leaveData, token: token);

    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? "Failed to apply for leave");
    }
  }

  // 3. Get Employee List (For To/CC Pickers)
  Future<List<Map<String, dynamic>>> getEmployeeList() async {
    final token = await SessionService.getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await _api.get('get_employee_list', token: token);

    if (response['status'] == 'success') {
      return List<Map<String, dynamic>>.from(response['data']);
    } else {
      throw Exception(response['message'] ?? "Failed to fetch employees");
    }
  }

  // 3. Get Team Requests (For Managers)
  Future<List<dynamic>> getTeamLeaveRequests() async {
    final token = await SessionService.getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await _api.get('team_requests', token: token);

    if (response['status'] == 'success') {
      return response['data'] as List<dynamic>;
    } else {
      throw Exception(response['message']);
    }
  }

  // 4. Process Request (Approve/Reject)
  Future<void> processLeaveRequest(String requestId, String status, String comment) async {
    final token = await SessionService.getToken();
    if (token == null) throw Exception("Not authenticated");

    final body = {
      "request_id": requestId,
      "status": status, 
      "comment": comment
    };

    final response = await _api.post('process_leave', body, token: token);

    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? "Failed to process request");
    }
  }
}