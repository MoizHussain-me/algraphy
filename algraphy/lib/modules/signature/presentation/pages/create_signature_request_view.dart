import 'dart:io';
import 'package:algraphy/core/utils/constants.dart';
import 'package:algraphy/modules/auth/data/models/user_model.dart';
import 'package:algraphy/core/services/logger_service.dart';
import 'package:algraphy/modules/signature/presentation/pages/signature_designer_page.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CreateSignatureRequestView extends StatefulWidget {
  final List<UserModel> employees;

  const CreateSignatureRequestView({super.key, required this.employees});

  @override
  State<CreateSignatureRequestView> createState() => _CreateSignatureRequestViewState();
}

class _CreateSignatureRequestViewState extends State<CreateSignatureRequestView> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  
  // State variables for coordinates and file
  PlatformFile? _selectedFile;
  double _xPos = 150.0;
  double _yPos = 240.0;
  int _pageNum = 1;
  DateTime? _expiryDate;
  
  String? _selectedEmployeeId;
  bool _isUploading = false;

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFDC2726),
              onPrimary: Colors.white,
              surface: Color(0xFF1C1C1C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  void _pickAndDesignPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null) {
      // Set the file in state BEFORE opening the designer
      setState(() {
        _selectedFile = result.files.single;
      });

      // OPEN THE DESIGNER AND WAIT
      final designerData = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignatureDesignerPage(
            pdfBytes: _selectedFile?.bytes,
            pdfFile: kIsWeb ? null : File(_selectedFile!.path!),
            onPositionSelected: (x, y, page) {
               // Internal update
               _xPos = x;
               _yPos = y;
               _pageNum = page;
            },
          ),
        ),
      );

      // CATCH THE RETURNED COORDINATES HERE
      if (designerData != null) {
        setState(() {
          _xPos = designerData['x']?.toDouble() ?? 150.0;
          _yPos = designerData['y']?.toDouble() ?? 240.0;
          _pageNum = designerData['page'] ?? 1;
        });
        logger.d("Coordinates Captured: X=$_xPos, Y=$_yPos, Page=$_pageNum");
      }
    }
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and select a PDF")),
      );
      return;
    }

    // Safety check for the Foreign Key
    if (_selectedEmployeeId == null || _selectedEmployeeId!.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid Employee selected. Please try again.")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);

      // DEBUG: Print exactly what is being sent to catch the 1452 source
      logger.i("--- UPLOADING SIGNATURE REQUEST ---");
      logger.d("Target Employee ID: $_selectedEmployeeId");
      logger.d("Document Title: ${_titleCtrl.text}");

      // Prepare multi-part form data
      // FormData formData = FormData.fromMap({
      //   "employee_id": _selectedEmployeeId, // This MUST be a valid integer ID in the DB
      //   "document_title": _titleCtrl.text.trim(),
      //   "x_pos": _xPos.toInt().toString(),
      //   "y_pos": _yPos.toInt().toString(),
      //   "page_num": _pageNum.toString(),
      //   "pdf_file": kIsWeb
      //       ? MultipartFile.fromBytes(_selectedFile!.bytes!, filename: _selectedFile!.name)
      //       : await MultipartFile.fromFile(_selectedFile!.path!, filename: _selectedFile!.name),
      // });


      final Map<String, dynamic> dataMap = {
        "employee_id": _selectedEmployeeId,
        "document_title": _titleCtrl.text.trim(),
        "x_pos": _xPos.toString(), 
        "y_pos": _yPos.toString(),
        "page_num": _pageNum.toString(),
        "pdf_file": kIsWeb
            ? MultipartFile.fromBytes(_selectedFile!.bytes!, filename: _selectedFile!.name)
            : await MultipartFile.fromFile(_selectedFile!.path!, filename: _selectedFile!.name),
      };

      if (_expiryDate != null) {
        dataMap["expiry_date"] = DateFormat('yyyy-MM-dd').format(_expiryDate!);
      }

      final formData = FormData.fromMap(dataMap);

      final response = await Dio().post(
        "${AppConstants.apiBaseUrl}?action=create_signature_request",
        data: formData,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.data['status'] == 'success') {
        if (mounted) Navigator.pop(context, true);
      } else {
        // This will now catch and show the custom error message from your PHP try-catch
        throw Exception(response.data['message']);
      }
    } catch (e) {
      logger.e("Upload Error Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"), 
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Request Document Signature", 
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Employee Dropdown
            DropdownButtonFormField<String>(
              dropdownColor: const Color(0xFF2C2C2C),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Select Employee", Icons.person),
              items: widget.employees.map((emp) => DropdownMenuItem(
                value: emp.employeeId.toString(), 
                child: Text("${emp.fullName} ${emp.employeeCode}"),
              )).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedEmployeeId = val;
                });
                logger.d("Selected Database Primary Key (employee_id): $_selectedEmployeeId");
              },
              validator: (v) => v == null ? "Required" : null,
            ),
            const SizedBox(height: 16),

            // Title Field
            TextFormField(
              controller: _titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Document Title", Icons.title),
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 16),

            // Expiry Date Picker
            InkWell(
              onTap: _pickExpiryDate,
              child: InputDecorator(
                decoration: _inputDecoration("Expiry Date (Optional)", Icons.event),
                child: Text(
                  _expiryDate == null ? "No Expiry" : DateFormat('MMM dd, yyyy').format(_expiryDate!),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // File Picker Field
            InkWell(
              onTap: _pickAndDesignPDF,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _selectedFile != null ? Colors.green : Colors.white10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: _selectedFile != null ? Colors.green : Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedFile != null 
                          ? "${_selectedFile!.name} (Pos Set)" 
                          : "Tap to select PDF & set position",
                        style: TextStyle(color: _selectedFile != null ? Colors.white : Colors.grey),
                      ),
                    ),
                    if (_selectedFile != null) const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2726),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isUploading ? null : _handleUpload,
                child: _isUploading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Create Request", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDC2726))),
    );
  }
}