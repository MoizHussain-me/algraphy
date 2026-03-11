import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// A shared service for reading session data (token, etc.) from local storage.
/// Eliminates the repeated _getToken() pattern across all repositories.
class SessionService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }
}
