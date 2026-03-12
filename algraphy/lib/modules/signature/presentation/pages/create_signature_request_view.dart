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
  
  PlatformFile? _selectedFile;
  double _xPos = 150.0;
  double _yPos = 240.0;
  int _pageNum = 1;
  DateTime? _expiryDate;
  
  String? _selectedEmployeeId;
  bool _isUploading = false;

  Future<void> _pickExpiryDate() async {
    final theme = Theme.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: const Color(0xFFDC2726),
              onPrimary: Colors.white,
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
      setState(() {
        _selectedFile = result.files.single;
      });

      final designerData = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignatureDesignerPage(
            pdfBytes: _selectedFile?.bytes,
            pdfFile: kIsWeb ? null : File(_selectedFile!.path!),
            onPositionSelected: (x, y, page) {
              _xPos = x;
              _yPos = y;
              _pageNum = page;
            },
          ),
        ),
      );

      if (designerData != null) {
        setState(() {
          _xPos = designerData['x']?.toDouble() ?? 150.0;
          _yPos = designerData['y']?.toDouble() ?? 240.0;
          _pageNum = designerData['page'] ?? 1;
        });
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

    if (_selectedEmployeeId == null || _selectedEmployeeId!.isEmpty) {
       _showSnackbar("Invalid Employee selected", Colors.orange);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);

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

      final response = await Dio().post(
        "${AppConstants.apiBaseUrl}?action=create_signature_request",
        data: FormData.fromMap(dataMap),
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.data['status'] == 'success') {
        if (mounted) Navigator.pop(context, true);
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      _showSnackbar("Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Request Document Signature", 
              style: TextStyle(
                color: theme.textTheme.titleLarge?.color, 
                fontSize: 18, 
                fontWeight: FontWeight.bold
              )
            ),
            const SizedBox(height: 20),

            // Employee Dropdown
            DropdownButtonFormField<String>(
              dropdownColor: isDark ? const Color(0xFF2C2C2C) : theme.cardColor,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: _inputDecoration(context, "Select Employee", Icons.person),
              items: widget.employees.map((emp) => DropdownMenuItem(
                value: emp.employeeId.toString(), 
                child: Text("${emp.fullName} ${emp.employeeCode}"),
              )).toList(),
              onChanged: (val) => setState(() => _selectedEmployeeId = val),
              validator: (v) => v == null ? "Required" : null,
            ),
            const SizedBox(height: 16),

            // Title Field
            TextFormField(
              controller: _titleCtrl,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: _inputDecoration(context, "Document Title", Icons.title),
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 16),

            // Expiry Date Picker
            InkWell(
              onTap: _pickExpiryDate,
              child: InputDecorator(
                decoration: _inputDecoration(context, "Expiry Date (Optional)", Icons.event),
                child: Text(
                  _expiryDate == null ? "No Expiry" : DateFormat('MMM dd, yyyy').format(_expiryDate!),
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
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
                  color: isDark ? const Color(0xFF2C2C2C) : theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedFile != null 
                        ? Colors.green 
                        : theme.dividerColor.withOpacity(0.1)
                  ),
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
                        style: TextStyle(
                          color: _selectedFile != null 
                              ? theme.textTheme.bodyLarge?.color 
                              : Colors.grey
                        ),
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
                  elevation: 0,
                ),
                onPressed: _isUploading ? null : _handleUpload,
                child: _isUploading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Create Request", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String label, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: isDark ? const Color(0xFF2C2C2C) : theme.scaffoldBackgroundColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), 
        borderSide: const BorderSide(color: Color(0xFFDC2726), width: 1.5)
      ),
    );
  }
}