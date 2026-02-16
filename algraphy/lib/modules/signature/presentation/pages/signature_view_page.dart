import 'dart:convert';
import 'dart:typed_data';
import 'package:algraphy/core/utils/constants.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:permission_handler/permission_handler.dart';

class SignatureViewPage extends StatefulWidget {
  final String token; 
  const SignatureViewPage({super.key, required this.token});

  @override
  State<SignatureViewPage> createState() => _SignatureViewPageState();
}

class _SignatureViewPageState extends State<SignatureViewPage> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 2.5, // Slightly thinner pen for better detail in smaller field
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  bool _isSubmitting = false;
  Uint8List? _uploadedSignature;

  Future<void> _pickSignatureImage() async {
    // 1. Check Photos Permission (Mobile Only)
    if (!kIsWeb) {
      var status = await Permission.photos.status;
      if (status.isDenied) {
        status = await Permission.photos.request();
        if (status.isDenied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Photo library access is required to upload a signature.")),
            );
          }
          return;
        }
      }

      if (status.isPermanentlyDenied) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Photos Permission Required"),
              content: const Text("Please enable photo library access in settings to upload your signature."),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                TextButton(onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                }, child: const Text("Settings")),
              ],
            ),
          );
        }
        return;
      }
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _uploadedSignature = result.files.single.bytes;
        _controller.clear(); // Clear drawing if image is uploaded
      });
    }
  }

  Future<void> _submitSignature() async {
    if (_controller.isEmpty && _uploadedSignature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide a signature first")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      Uint8List? signatureBytes;
      if (_uploadedSignature != null) {
        signatureBytes = _uploadedSignature;
      } else {
        signatureBytes = await _controller.toPngBytes();
      }

      if (signatureBytes == null) return;

      final String base64Signature = base64Encode(signatureBytes);

      final response = await Dio().post(
        "${AppConstants.apiBaseUrl}?action=submit_signature",
        data: {
          "token": widget.token,
          "signature_data": base64Signature,
        },
      );

      if (response.data['status'] == 'success') {
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Submission failed: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text(
          "Document Signed Successfully!",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Done", style: TextStyle(color: Color(0xFFDC2726))),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String pdfUrl = "${AppConstants.apiBaseUrl}?action=get_pdf_by_token&token=${widget.token}";

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Sign Document", style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SfPdfViewer.network(
        pdfUrl,
        onDocumentLoadFailed: (details) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to load PDF: ${details.description}")),
          );
        },
      ),
      // Compact Bottom Navigation for Signature
      bottomNavigationBar: Container(
        height: 230, // Increased to accommodate upload button
        color: const Color(0xFF1C1C1C),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _uploadedSignature != null ? "Uploaded Signature" : "Draw Signature", 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _pickSignatureImage,
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      child: const Text("Upload Image", style: TextStyle(color: Color(0xFFDC2726), fontSize: 13)),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _uploadedSignature = null);
                        _controller.clear();
                      },
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      child: const Text("Clear", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _uploadedSignature != null
                  ? Image.memory(_uploadedSignature!, fit: BoxFit.contain)
                  : Signature(
                      controller: _controller,
                      backgroundColor: Colors.white,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitSignature,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2726),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Confirm & Sign", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}