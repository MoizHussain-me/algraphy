import 'package:flutter/foundation.dart';

import '../../../../core/api/api_client.dart';
import '../../../../modules/auth/data/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/constants.dart';

class AdminRepository {
  final ApiClient _api = ApiClient();

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<void> createEmployee(UserModel user, {String? profilePicPath, List<int>? profilePicBytes}) async {
    final token = await getToken();
    if (token == null) throw Exception("Admin not authenticated");

    final Map<String, String> fields = {};
    user.toMap().forEach((key, value) {
      if (value != null && key != 'id' && key != 'profile_picture') {
        fields[key] = value.toString();
      }
    });

    // Prepare Arguments based on Platform
    Map<String, String?>? filePaths;
    Map<String, List<int>?>? fileBytes;

    if (kIsWeb) {
      // WEB: Send Bytes
      if (profilePicBytes != null) {
        fileBytes = {'profile_picture': profilePicBytes};
      }
    } else {
      // MOBILE: Send Path
      if (profilePicPath != null) {
        filePaths = {'profile_picture': profilePicPath};
      }
    }

    final response = await _api.postMultipart(
      'create_employee', 
      fields, 
      filePaths: filePaths,
      fileBytes: fileBytes,
      token: token
    );

    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? "Failed to create employee");
    }
  }

  Future<List<UserModel>> getAllEmployees() async {
    final token = await getToken();
    final response = await _api.get('all_employees', token: token);

    if (response['status'] == 'success') {
      final List<dynamic> data = response['data'];
      // Ensure we map the 'actual_user_id' from PHP (users.user_id) to the ID field
      // This is crucial for the Hierarchy dropdown to work
      return data.map((json) {
        // If your PHP join returns 'actual_user_id', use it. Otherwise fallback.
        if (json['actual_user_id'] != null) {
          json['user_id'] = json['actual_user_id']; 
        }
        return UserModel.fromMap(json);
      }).toList();
    } else {
      throw Exception(response['message']);
    }
  }

  Future<List<String>> getDepartments() async {
    final token = await getToken();
    final response = await _api.get('get_departments', token: token);

    if (response['status'] == 'success') {
      return List<String>.from(response['data']);
    } else {
      return [];
    }
  }


 Future<void> updateEmployee(UserModel user, {String? profilePicPath, List<int>? profilePicBytes}) async {
    final token = await getToken();
    if (token == null) throw Exception("Admin not authenticated");

    final Map<String, String> fields = {};
    user.toMap().forEach((key, value) {
      // Send ID so backend knows who to update
      if (value != null && key != 'profile_picture') {
        fields[key] = value.toString();
      }
    });

    // Handle Files for Web vs Mobile
    Map<String, String?>? filePaths;
    Map<String, List<int>?>? fileBytes;

    if (kIsWeb) {
      // WEB: Send Bytes
      if (profilePicBytes != null) {
        fileBytes = {'profile_picture': profilePicBytes};
      }
    } else {
      // MOBILE: Send Path
      if (profilePicPath != null) {
        filePaths = {'profile_picture': profilePicPath};
      }
    }

    final response = await _api.postMultipart(
      'update_employee', 
      fields, 
      filePaths: filePaths,
      fileBytes: fileBytes,
      token: token
    );

    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? "Failed to update employee");
    }
  }


}