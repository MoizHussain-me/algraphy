import 'constants.dart';

class ImageHelper {
  static String getFullUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    
    // If it's already a full URL (e.g. from internet), return it
    if (path.startsWith("http")) return path;

    // Remove 'routes/api.php' from the base URL to get the root
    // Example: [http://192.168.1.15/algraphy_api/routes/api.php](http://192.168.1.15/algraphy_api/routes/api.php) 
    // Becomes: [http://192.168.1.15/algraphy_api/](http://192.168.1.15/algraphy_api/)
    final String rootUrl = AppConstants.apiBaseUrl.replaceAll("routes/api.php", "");
    
    // Result: [http://192.168.1.15/algraphy_api/uploads/emp_123.jpg](http://192.168.1.15/algraphy_api/uploads/emp_123.jpg)
    return "$rootUrl$path";
  }
}