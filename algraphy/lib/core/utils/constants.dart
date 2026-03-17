class AppConstants {
  // 1. Base URL for API
  // Use 'http://10.0.2.2/algraphy_api/routes/api.php' for Android Emulator
  // Use 'http://localhost/algraphy_api/routes/api.php' for iOS Simulator / Web
  // Use 'http://192.168.100.149/algraphy_api/routes/api.php' for Real Device
  //static const String apiBaseUrl = "http://localhost/algraphy_api/routes/api.php";
  
  static String get rootUrl => apiBaseUrl.replaceAll('routes/api.php', '');
  static const String apiBaseUrl = "http://192.168.100.149/algraphy_api/routes/api.php";
  //"https://al-graphy.site/algraphy_api/routes/api.php";
  static const String privacyPolicyUrl = "https://al-graphy.site/algraphy_api/privacy-policy";

  // 2. Storage Keys
  static const String tokenKey = "auth_token";
  static const String userKey = "user_data";
}