import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/session_service.dart';
import '../../../auth/data/models/user_model.dart';

class AdminRepository {
  final ApiClient _api = ApiClient();

  // 1. Fetch All Employees
  Future<List<UserModel>> getAllEmployees() async {
    try {
      final token = await SessionService.getToken();
      if (token == null) throw Exception("Unauthorized");

      final response = await _api.get('all_employees', token: token);

      if (response['status'] == 'success') {
        final dynamic rawData = response['data'];
        
        if (rawData == null || rawData is! List) {
          return [];
        }

        return rawData.map((json) {
          try {
            return UserModel.fromMap(json as Map<String, dynamic>);
          } catch (e) {
            debugPrint("Error mapping individual user: $e | Data: $json");
            return null; 
          }
        })
        .whereType<UserModel>() 
        .toList();
      } else {
        throw Exception(response['message'] ?? "Failed to fetch employees");
      }
    } catch (e) {
      debugPrint("AdminRepository.getAllEmployees Error: $e");
      rethrow;
    }
  }

  // 2. Fetch Admin Dashboard Stats
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final token = await SessionService.getToken();
      if (token == null) throw Exception("Unauthorized");

      final response = await _api.get('admin_dashboard_stats', token: token);
      if (response['status'] == 'success') {
        return response['data'] ?? {};
      } else {
        throw Exception(response['message'] ?? "Failed to fetch stats");
      }
    } catch (e) {
      debugPrint("AdminRepository.getAdminStats Error: $e");
      return {};
    }
  }

  // 3. Fetch Departments
  Future<List<String>> getDepartments() async {
    try {
      final token = await SessionService.getToken();
      if (token == null) throw Exception("Unauthorized");

      final response = await _api.get('get_departments', token: token);
      if (response['status'] == 'success') {
        return List<String>.from(response['data'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching departments: $e");
      return [];
    }
  }

// 4. Create Employee (Handles File Upload)
  Future<void> createEmployee(
    UserModel user, {
    String? profilePicPath,
    Uint8List? profilePicBytes,
  }) async {
    try {
      final token = await SessionService.getToken();
      if (token == null) throw Exception("Unauthorized");

      final Map<String, dynamic> rawData = user.toMap();
      
      // Convert to Map<String, String> for http.MultipartRequest
      final Map<String, String> fields = {};
      rawData.forEach((key, value) {
        if (value != null) {
            fields[key] = value.toString();
          }
      });
      
      debugPrint("📢 createEmployee Payload: $fields");

      Map<String, String?>? filePaths;
      Map<String, List<int>?>? fileBytes;

      if (kIsWeb && profilePicBytes != null) {
        fileBytes = {'profile_picture': profilePicBytes};
      } else if (!kIsWeb && profilePicPath != null) {
        filePaths = {'profile_picture': profilePicPath};
      }

      final response = await _api.postMultipart(
        'create_employee',
        fields,
        filePaths: filePaths,
        fileBytes: fileBytes,
        token: token,
      );

      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? "Onboarding failed");
      }
    } catch (e) {
      rethrow;
    }
  }

  // 5. Update Employee
  Future<void> updateEmployee(
    UserModel user, {
    String? profilePicPath,
    Uint8List? profilePicBytes,
  }) async {
    try {
      final token = await SessionService.getToken();
      if (token == null) throw Exception("Unauthorized");

      final Map<String, dynamic> rawData = user.toMap();
      rawData['id'] = user.id; 

      // Convert to Map<String, String> for http.MultipartRequest
      final Map<String, String> fields = {};
      rawData.forEach((key, value) {
        if (value != null) {
            fields[key] = value.toString();
          }
      });
      
      debugPrint("📢 createEmployee Payload: $fields");

      Map<String, String?>? filePaths;
      Map<String, List<int>?>? fileBytes;

      if (kIsWeb && profilePicBytes != null) {
        fileBytes = {'profile_picture': profilePicBytes};
      } else if (!kIsWeb && profilePicPath != null) {
        filePaths = {'profile_picture': profilePicPath};
      }

      final response = await _api.postMultipart(
        'update_employee',
        fields,
        filePaths: filePaths,
        fileBytes: fileBytes,
        token: token,
      );

      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? "Update failed");
      }
    } catch (e) {
      rethrow;
    }
  }

  // 6. Organization Attendance Logs
  Future<List<Map<String, dynamic>>> getOrganizationAttendance({String? employeeId}) async {
    try {
      final token = await SessionService.getToken();
      if (token == null) throw Exception("Unauthorized");

      final url = employeeId != null 
          ? 'org_attendance_logs&employee_id=$employeeId' 
          : 'org_attendance_logs';

      final response = await _api.get(url, token: token);
      if (response['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response['data'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching org attendance: $e");
      return [];
    }
  }

  // 7. Mark Attendance for Employee
  Future<void> markEmployeeAttendance(String userId, String type) async {
    try {
      final token = await SessionService.getToken();
      if (token == null) throw Exception("Unauthorized");

      final response = await _api.post('mark_attendance', {
        'employee_id': userId,
        'type': type,
      }, token: token);

      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? "Failed to mark attendance");
      }
    } catch (e) {
      rethrow;
    }
  }

  // 8. Leave Management (Admin Override)
  Future<List<dynamic>> getAllLeaves() async {
    try {
      final token = await SessionService.getToken();
      if (token == null) throw Exception("Unauthorized");

      final response = await _api.get('all_leaves', token: token);
      if (response['status'] == 'success') {
        return response['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> updateLeaveStatus(String requestId, String status, String comment) async {
    try {
      final token = await SessionService.getToken();
      if (token == null) throw Exception("Unauthorized");

      final response = await _api.post('process_leave', {
        'request_id': requestId,
        'status': status,
        'comment': comment,
      }, token: token);
      
      if (response['status'] != 'success') {
        throw Exception(response['message']);
      }
    } catch (e) {
      rethrow;
    }
  }

  // 9. Soft Delete Account (Admin removing an employee)
  Future<void> softDeleteAccount(String userId) async {
    try {
      final token = await SessionService.getToken();
      if (token == null) throw Exception("Unauthorized");

      final response = await _api.post('soft_delete_account', {
        'user_id': userId,
      }, token: token);

      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'Failed to delete account');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 10. Update Account Status (Enable / Disable an employee)
  Future<void> updateAccountStatus(String userId, bool isActive) async {
    try {
      final token = await SessionService.getToken();
      if (token == null) throw Exception("Unauthorized");

      final response = await _api.post('update_account_status', {
        'user_id': userId,
        'is_active': isActive ? 1 : 0,
      }, token: token);

      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'Failed to update account status');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // MODULE 11: GEOFENCING / OFFICE CRUD
  // ==========================================

  Future<List<Map<String, dynamic>>> getOffices() async {
    try {
      final token = await SessionService.getToken();
      if (token == null) throw Exception("Unauthorized");
      final response = await _api.get('get_offices', token: token);
      if (response['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response['data'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> saveOffice(Map<String, dynamic> data) async {
    final token = await SessionService.getToken();
    if (token == null) throw Exception("Unauthorized");
    final response = await _api.post('save_office', data, token: token);
    if (response['status'] != 'success') throw Exception(response['message'] ?? "Failed to save office");
  }

  Future<void> deleteOffice(String id) async {
    final token = await SessionService.getToken();
    if (token == null) throw Exception("Unauthorized");
    final response = await _api.post('delete_office', {'id': id}, token: token);
    if (response['status'] != 'success') throw Exception(response['message'] ?? "Failed to delete office");
  }

  Future<void> bulkAssignOffice(String officeId, List<String> employeeIds) async {
    try {
      final token = await SessionService.getToken();
      if (token == null) throw Exception("Unauthorized");
      
      final response = await _api.post('bulk_assign_office', {
        'office_id': officeId,
        'employee_ids': employeeIds,
      }, token: token);

      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? "Bulk assignment failed");
      }
    } catch (e) {
      rethrow;
    }
  }
}