import '../../../../core/api/api_client.dart';
import '../../../../core/services/session_service.dart';

class AdminRepository {
  final ApiClient _api = ApiClient();

  // ==========================================
  // DEPARTMENTS
  // ==========================================
  Future<List<Map<String, dynamic>>> getDepartments() async {
    final token = await SessionService.getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await _api.get('get_departments_admin', token: token);
    if (response['status'] == 'success') {
      return List<Map<String, dynamic>>.from(response['data']);
    } else {
      throw Exception(response['message']);
    }
  }

  Future<void> saveDepartment(Map<String, dynamic> data) async {
    final token = await SessionService.getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await _api.post('save_department', data, token: token);
    if (response['status'] != 'success') throw Exception(response['message']);
  }

  Future<void> deleteDepartment(int id) async {
    final token = await SessionService.getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await _api.post('delete_department', {'id': id}, token: token);
    if (response['status'] != 'success') throw Exception(response['message']);
  }

  // ==========================================
  // DESIGNATIONS
  // ==========================================
  Future<List<Map<String, dynamic>>> getDesignations() async {
    final token = await SessionService.getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await _api.get('get_designations', token: token);
    if (response['status'] == 'success') {
      return List<Map<String, dynamic>>.from(response['data']);
    } else {
      throw Exception(response['message']);
    }
  }

  Future<void> saveDesignation(Map<String, dynamic> data) async {
    final token = await SessionService.getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await _api.post('save_designation', data, token: token);
    if (response['status'] != 'success') throw Exception(response['message']);
  }

  Future<void> deleteDesignation(int id) async {
    final token = await SessionService.getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await _api.post('delete_designation', {'id': id}, token: token);
    if (response['status'] != 'success') throw Exception(response['message']);
  }

  // ==========================================
  // SHIFTS
  // ==========================================
  Future<List<Map<String, dynamic>>> getShifts() async {
    final token = await SessionService.getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await _api.get('get_shifts', token: token);
    if (response['status'] == 'success') {
      return List<Map<String, dynamic>>.from(response['data']);
    } else {
      throw Exception(response['message']);
    }
  }

  Future<void> saveShift(Map<String, dynamic> data) async {
    final token = await SessionService.getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await _api.post('save_shift', data, token: token);
    if (response['status'] != 'success') throw Exception(response['message']);
  }

  Future<void> deleteShift(int id) async {
    final token = await SessionService.getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await _api.post('delete_shift', {'id': id}, token: token);
    if (response['status'] != 'success') throw Exception(response['message']);
  }
}
