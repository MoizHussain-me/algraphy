import 'package:algraphy/core/utils/constants.dart';
import 'package:algraphy/modules/signature/data/models/signature_request_model.dart';
import 'package:dio/dio.dart';

class SignatureRepository {
  final Dio _dio = Dio();
  final String baseUrl = AppConstants.apiBaseUrl;

  // ADMIN: Send the PDF to server and trigger email
  Future<Response> sendSignatureRequest({
    required String employeeEmail,
    required dynamic pdfFile, // Can be XFile or platform file
  }) async {
    FormData formData = FormData.fromMap({
      "action": "create_signature_request",
      "email": employeeEmail,
      "pdf_file": await MultipartFile.fromFile(pdfFile.path, filename: "contract.pdf"),
    });

    return await _dio.post(baseUrl, data: formData);
  }

  // EMPLOYEE: Submit the PNG signature
  Future<Response> submitSignature({
    required String token,
    required String base64Image,
  }) async {
    return await _dio.post(
      "$baseUrl?action=submit_signature",
      data: {
        "token": token,
        "signature_base64": base64Image,
      },
    );
  }

    Future<List<SignatureRequestModel>> getMyDocuments() async {
    final response = await _dio.get("$baseUrl?action=my_signature_requests");
    return (response.data['data'] as List)
        .map((x) => SignatureRequestModel.fromJson(x))
        .toList();
  }

  Future<bool> uploadSignature(String token, String base64Image) async {
    final response = await _dio.post(baseUrl, data: {
      "action": "submit_signature",
      "token": token,
      "signature_base64": base64Image,
    });
    return response.data['status'] == 'success';
  }

}





