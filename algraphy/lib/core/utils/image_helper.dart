import 'package:flutter/material.dart';
import 'constants.dart';

class ImageHelper {
  static String getFullUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    
    // 1. If it's already a full web URL, return it as is
    if (path.startsWith("http")) return path;

    // 2. Clean the Base URL
    // Your API URL is: http://192.168.1.15/algraphy_api/routes/api.php
    // We need root:    http://192.168.1.15/algraphy_api/
    
    String rootUrl = AppConstants.apiBaseUrl;
    
    // Remove the 'routes/api.php' part to get the project root
    if (rootUrl.contains("routes/api.php")) {
      rootUrl = rootUrl.replaceAll("routes/api.php", "");
    }
    
    // Ensure root ends with /
    if (!rootUrl.endsWith("/")) {
      rootUrl = "$rootUrl/";
    }

    // 3. Combine
    // Result: http://192.168.1.15/algraphy_api/uploads/emp_123.jpg
    return "$rootUrl$path";
  }

  static ImageProvider? getProvider(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith("http")) return NetworkImage(path);
    return NetworkImage(getFullUrl(path));
  }
}