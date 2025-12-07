
import 'package:algraphy/core/api/api_client.dart';
import 'package:algraphy/core/utils/constants.dart';
import 'package:algraphy/modules/auth/data/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final ApiClient _api = ApiClient();

  // Login
  Future<UserModel> login(String email, String password) async {
    final response = await _api.post('login', {
      'email': email,
      'password': password,
    });

    if (response['status'] == 'success') {
      final userData = response['user'];
      final token = response['token'];

      // Convert JSON to User Model
      final user = UserModel.fromMap(userData);

      // Save Session Locally
      await _saveSession(user, token);

      return user;
    } else {
      throw Exception(response['message'] ?? 'Login failed');
    }
  }

  // Save Token & User
  Future<void> _saveSession(UserModel user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    // You might want to save user ID or Role too
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}