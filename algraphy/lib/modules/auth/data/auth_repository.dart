import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:algraphy/modules/auth/data/models/user_model.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/services/notification_service.dart';

class AuthRepository {
  final ApiClient _api;

  AuthRepository({ApiClient? api}) : _api = api ?? ApiClient();

  // --- LOGIN ---
  Future<UserModel> login(String email, String password) async {
    logger.i("AUTH: Attempting login for $email");

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

      final user = UserModel.fromMap(Map<String, dynamic>.from(userData));

      // CRITICAL: Save session before returning
      await _saveSession(user, token);
      
      logger.i("AUTH: Login successful for ${user.email}");
      return user;
    } else {
      final msg = response['message'] ?? 'Login failed';
      logger.w("AUTH: Login failed with message: $msg");
      throw Exception(msg);
    }
  }

  // --- CLIENT SIGNUP ---
  Future<UserModel> signupClient({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String companyName,
    required String industry,
    required String servicesNeeded,
  }) async {
    logger.i("AUTH: Attempting Client Signup for $email");

    final response = await _api.post('client_signup', {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'company_name': companyName,
      'industry': industry,
      'services_needed': servicesNeeded,
    });

    if (response['status'] == 'success') {
      final userData = response['user'];
      final token = response['token'];

      if (userData == null) {
        throw Exception("Server Error: Signup successful but no user data returned.");
      }

      final userMap = Map<String, dynamic>.from(userData);
      final user = UserModel.fromMap(userMap);

      // We DON'T save session here anymore because 
      // the user wants them redirected to login screen
      
      logger.i("AUTH: Client Signup successful.");
      return user;
    } else {
      throw Exception(response['message'] ?? 'Signup failed');
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

    // 3. Send FCM Token to Backend
    try {
      final fcmToken = await NotificationService().getFCMToken();
      if (fcmToken != null) {
        await _api.post('update_fcm_token', {
          'fcm_token': fcmToken,
          'token': token,
        }, token: token);
        logger.i("AUTH: FCM Token synced with backend.");
      }
    } catch (e) {
      logger.w("AUTH: Failed to sync FCM token: $e");
      // For deeper debugging if needed
      if (kDebugMode) {
        print("Detailed FCM Sync Error: $e");
      }
    }
  }

  Future<void> persistUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toMap());
      
      await prefs.setString(AppConstants.userKey, userJson);
      logger.d("AUTH: User persisted to storage: $userJson");
    } catch (e) {
      logger.e("AUTH: Failed to persist user: $e");
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(AppConstants.userKey);

    logger.d("AUTH: Checking storage... Found: ${jsonString != null}");

    if (jsonString != null) {
      try {
        final Map<String, dynamic> userMap = jsonDecode(jsonString);
        final user = UserModel.fromMap(userMap);
        logger.i("AUTH: User loaded successfully: ${user.fullName}");
        return user;
      } catch (e, stackTrace) {
        // Capture specific error causing the failure
        logger.e("AUTH ERROR: Corrupted user data in storage.", error: e, stackTrace: stackTrace);
        
        // If data is corrupted, clear it so we don't get stuck
        await prefs.remove(AppConstants.userKey);
        return null;
      }
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    
    if (token != null) {
      try {
        await _api.post('logout', {}, token: token);
      } catch (e) {
        logger.e("AUTH: Logout API failed: $e");
      }
    }

    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
    logger.i("AUTH: Session cleared.");
  }
  
  // --- OTHER ACTIONS ---

  Future<UserModel> validateSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    
    if (token == null) throw Exception("No token available");

    final response = await _api.get('verify_session', token: token);

    if (response['status'] == 'success') {
      final userData = response['user'];
      if (userData == null) throw Exception("No user data from server");

      final user = UserModel.fromMap(Map<String, dynamic>.from(userData));
      
      // Update local storage with fresh data
      await persistUser(user);
      
      return user;
    } else {
      throw Exception(response['message'] ?? 'Session verification failed');
    }
  }

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
    final token = prefs.getString(AppConstants.tokenKey);
    
    if (token == null) throw Exception("Not authenticated");

    final response = await _api.post(
      'delete_account', 
      {'token': token}, 
      token: token 
    );

    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? 'Failed to delete account');
    }

    await logout();
  }

  // --- EMAIL VERIFICATION & INITIAL SETUP ---

  Future<Map<String, dynamic>> verifyEmail(String token) async {
    logger.i("AUTH: Verifying email with token: $token");
    final response = await _api.post('verify_email', {'token': token});
    if (response['status'] == 'success') {
      logger.i("AUTH: Email verified successfully.");
      return response;
    } else {
      throw Exception(response['message'] ?? 'Verification failed');
    }
  }

  Future<void> setupInitialPassword(String token, String password) async {
    logger.i("AUTH: Setting initial password for token: $token");
    final response = await _api.post('setup_password', {
      'token': token,
      'password': password,
    });

    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? 'Failed to set password');
    }
    logger.i("AUTH: Initial password set successfully.");
  }
}