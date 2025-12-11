import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:algraphy/modules/auth/data/models/user_model.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/utils/constants.dart';

class AuthRepository {
  final ApiClient _api = ApiClient();

  // --- LOGIN ---
  Future<UserModel> login(String email, String password) async {
    print("AUTH: Attempting login for $email"); // DEBUG
    final response = await _api.post('login', {
      'email': email,
      'password': password,
    });

    if (response['status'] == 'success') {
      final userData = response['user'];
      final token = response['token'];

      if (userData == null) {
        throw Exception("Server Error: Login successful but no user data returned.");
      }

      final userMap = Map<String, dynamic>.from(userData);
      final user = UserModel.fromMap(userMap);

      // CRITICAL: Save session before returning
      await _saveSession(user, token);
      
      print("AUTH: Login successful and session saved."); // DEBUG
      return user;
    } else {
      throw Exception(response['message'] ?? 'Login failed');
    }
  }

  // --- SESSION MANAGEMENT ---
  
  Future<void> _saveSession(UserModel user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Save Token
    await prefs.setString(AppConstants.tokenKey, token);
    
    // 2. Save User Data
    // We explicitly call persistUser here to ensure data is written to disk
    await persistUser(user);
  }

  Future<void> persistUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toMap());
      
      await prefs.setString(AppConstants.userKey, userJson);
      print("AUTH: User persisted to storage: $userJson"); // DEBUG
    } catch (e) {
      print("AUTH: Failed to persist user: $e"); // DEBUG
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(AppConstants.userKey);

    print("AUTH: Checking storage... Found: ${jsonString != null}"); // DEBUG

    if (jsonString != null) {
      try {
        final Map<String, dynamic> userMap = jsonDecode(jsonString);
        final user = UserModel.fromMap(userMap);
        print("AUTH: User loaded successfully: ${user.fullName}"); // DEBUG
        return user;
      } catch (e, stackTrace) {
        // Capture specific error causing the failure
        print("AUTH ERROR: Corrupted user data in storage."); 
        print("Error: $e"); 
        print("Stack: $stackTrace");
        
        // If data is corrupted, clear it so we don't get stuck
        await prefs.remove(AppConstants.userKey);
        return null;
      }
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
    print("AUTH: Session cleared."); // DEBUG
  }
  
  // --- OTHER ACTIONS ---

  Future<void> changePassword(String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    
    if (token == null) throw Exception("Not authenticated");

    final response = await _api.post(
      'change_password', 
      {'new_password': newPassword, 'token': token}, 
      token: token 
    );

    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? 'Failed to change password');
    }
  }

  Future<void> deleteUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userKey);
  }
}