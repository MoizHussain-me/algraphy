import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiClient {
  final String baseUrl;

  ApiClient({this.baseUrl = AppConstants.apiBaseUrl});

  // --- 1. GET Request (Fixes your error) ---
  Future<Map<String, dynamic>> get(String action, {String? token}) async {
    final uri = Uri.parse('$baseUrl?action=$action');
    
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };

    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }

    try {
      final response = await http.get(uri, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception("Network Error: $e");
    }
  }

  // --- 2. POST Request (JSON) ---
 Future<Map<String, dynamic>> post(String action, Map<String, dynamic> body, {String? token}) async {
    final uri = Uri.parse('$baseUrl?action=$action');
    
    final headers = {
      "Content-Type": "application/json", 
      "Accept": "application/json"
    };

    // Add Token if provided
    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }

    try {
      print("DEBUG: POST $uri");
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      print("DEBUG: Status ${response.statusCode}");
      print("DEBUG: Body ${response.body}");
      return _handleResponse(response);
    } catch (e) {
      print("DEBUG: Error $e");
      throw Exception("Network Error: $e");
    }
  }

  // --- 2b. POST Request (Raw URL) ---
  Future<Map<String, dynamic>> postRaw(String url, Map<String, dynamic> body) async {
    final uri = Uri.parse(url);
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json"
    };

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception("Network Error: $e");
    }
  }

  // --- 3. POST Multipart Request (File Uploads) ---
  Future<Map<String, dynamic>> postMultipart(
    String action, 
    Map<String, String> fields, 
    {
      Map<String, String?>? filePaths, // For Mobile/Desktop (Path)
      Map<String, List<int>?>? fileBytes, // For Web (Bytes)
      Map<String, String>? fileNames, // New: Custom filenames for bytes
      String? token,
    }
  ) async {
    final uri = Uri.parse('$baseUrl?action=$action');
    var request = http.MultipartRequest('POST', uri);

    // 1. Headers
    request.headers.addAll({
      if (token != null) "Authorization": "Bearer $token",
      "Accept": "application/json",
    });

    // 2. Add Text Fields
    request.fields.addAll(fields);

    // 3. Add Files (Mobile/Desktop - Path)
    if (filePaths != null && (!kIsWeb || (kIsWeb && false))) { // kIsWeb check is standard
       for (var entry in filePaths.entries) {
        if (entry.value != null && entry.value!.isNotEmpty) {
          request.files.add(await http.MultipartFile.fromPath(
            entry.key,
            entry.value!,
          ));
        }
      }
    }

    // 4. Add Files (Web/Bytes - Bytes)
    if (fileBytes != null) {
      for (var entry in fileBytes.entries) {
        if (entry.value != null && entry.value!.isNotEmpty) {
          final fileName = fileNames?[entry.key] ?? "${entry.key}.bin";
          request.files.add(http.MultipartFile.fromBytes(
            entry.key,
            entry.value!,
            filename: fileName,
          ));
        }
      }
    }

    // 5. Send
    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      debugPrint("DEBUG: postMultipart Error: $e");
      throw Exception("Upload Error: $e");
    }
  }

  // --- Helper: Response Handler ---
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'status': 'success', 'message': 'Action successful'};
      }
    } else {
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Unknown Server Error');
      } catch (_) {
        throw Exception("Server Error: ${response.statusCode}");
      }
    }
  }
}