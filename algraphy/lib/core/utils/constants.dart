class AppConstants {
  // 1. Base URL for API
  // Use 'http://10.0.2.2/algraphy_api/routes/api.php' for Android Emulator 
  static const String apiBaseUrl = "http://192.168.100.149/algraphy_api/routes/api.php"; // Real Device
  //static const String apiBaseUrl = "https://al-graphy.site/algraphy_api/routes/api.php"; // Production URL
  //static const String apiBaseUrl = "http://localhost/algraphy_api/routes/api.php"; // Local URL 

  static const String privacyPolicyUrl = "https://al-graphy.site/algraphy_api/privacy-policy";
  static String get rootUrl => apiBaseUrl.replaceAll('routes/api.php', '');
  // 2. Storage Keys
  static const String tokenKey = "auth_token";
  static const String userKey = "user_data";
  static const String currencySymbol = "SAR";
}