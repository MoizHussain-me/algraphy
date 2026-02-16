import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/utils/constants.dart';
import '../../../auth/data/models/user_model.dart';

class AdminRepository {
  final ApiClient _api = ApiClient();

  // Helper to fetch the stored JWT token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  // 1. Fetch All Employees
  Future<List<UserModel>> getAllEmployees() async {
    try {
      final token = await _getToken();
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
      final token = await _getToken();
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
      final token = await _getToken();
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
      final token = await _getToken();
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
      final token = await _getToken();
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

  // 6. Leave Management (Admin Override)
  Future<List<dynamic>> getAllLeaves() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Unauthorized");

      final response = await _api.get('admin_all_leaves', token: token);
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
      final token = await _getToken();
      if (token == null) throw Exception("Unauthorized");

      final response = await _api.post('admin_update_leave_status', {
        'request_id': requestId,
        'status': status,
        'admin_comment': comment,
      }, token: token);
      
      if (response['status'] != 'success') {
        throw Exception(response['message']);
      }
    } catch (e) {
      rethrow;
    }
  }
}