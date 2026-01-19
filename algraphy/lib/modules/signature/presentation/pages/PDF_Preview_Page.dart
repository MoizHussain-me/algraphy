import 'package:algraphy/core/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../../../core/services/logger_service.dart';

class PDFPreviewPage extends StatefulWidget {
  final String pdfUrl; // Relative path from DB: e.g., "uploads/contracts/file.pdf"
  final String title;

  const PDFPreviewPage({super.key, required this.pdfUrl, required this.title});

  @override
  State<PDFPreviewPage> createState() => _PDFPreviewPageState();
}

class _PDFPreviewPageState extends State<PDFPreviewPage> {
  String? _fullUrl;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _prepareUrl();
  }

  

  /// Refined URL construction logic.
  /// If the API is located in a subfolder like /routes/api.php, 
  /// we navigate back to the root folder before appending the relative PDF path.
  void _prepareUrl() {
    try {
      String apiBase = AppConstants.apiBaseUrl;
      String rootBase;
      
      // Logic to find the project root from the apiBaseUrl
      if (apiBase.contains('/routes/')) {
        // Strip everything from '/routes/' onwards to get the project root
        // Example: http://localhost/algraphy_api/routes/api.php -> http://localhost/algraphy_api/
        rootBase = apiBase.substring(0, apiBase.indexOf('/routes/')) + "/";
      } else {
        // Standard fallback: strip only the filename (e.g. api.php)
        rootBase = apiBase.substring(0, apiBase.lastIndexOf('/') + 1);
      }

      String cleanPath = widget.pdfUrl;
      if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);

      // Using Uri.parse and resolve to safely combine URLs
      _fullUrl = Uri.parse(rootBase).resolve(cleanPath).toString();
      _fullUrl = Uri.encodeFull(_fullUrl!);
      
      logger.d("Constructed PDF Link: $_fullUrl");
    } catch (e) {
      logger.e("URL Construction Error: $e");
      setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _hasError || _fullUrl == null
          ? _buildErrorWidget()
          : SfPdfViewer.network(
              _fullUrl!,
              onDocumentLoadFailed: (details) {
                if (mounted) setState(() => _hasError = true);
              },
            ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.picture_as_pdf_outlined, color: Colors.redAccent, size: 64),
          const SizedBox(height: 16),
          const Text("Cannot Load PDF", style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 8),
          const Text("The file path might be incorrect or inaccessible.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2726)),
            child: const Text("Go Back"),
          )
        ],
      ),
    );
  }
}