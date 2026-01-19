import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class SignatureDesignerPage extends StatefulWidget {
  final File? pdfFile;
  final Uint8List? pdfBytes;
  final Function(double x, double y, int page) onPositionSelected;

  const SignatureDesignerPage({
    super.key, 
    this.pdfFile, 
    this.pdfBytes,
    required this.onPositionSelected
  });

  @override
  State<SignatureDesignerPage> createState() => _SignatureDesignerPageState();
}

class _SignatureDesignerPageState extends State<SignatureDesignerPage> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  
  Offset? _normalizedPosition; 
  Offset? _visualPosition;     
  int _selectedPage = 1;
  bool _isDocumentLoaded = false;

  void _handlePdfTap(details) {
    setState(() {
      _selectedPage = details.pageNumber;

      // details.pagePosition is zoom/scroll independent (in PDF points)
      double xPoints = details.pagePosition.dx;
      double yPoints = details.pagePosition.dy;

      // Normalize to 0.0 - 1.0 (Standard A4 width is 595, height 842)
      double xPct = xPoints / 595.0;
      double yPct = yPoints / 842.0;

      _normalizedPosition = Offset(xPct, yPct);
      _visualPosition = details.position; 
    });
  }

  void _confirmPosition() {
    if (_normalizedPosition == null) return;

    widget.onPositionSelected(
      _normalizedPosition!.dx, 
      _normalizedPosition!.dy, 
      _selectedPage
    );

    Navigator.pop(context, {
      'x': _normalizedPosition!.dx,
      'y': _normalizedPosition!.dy,
      'page': _selectedPage,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Set Signature Spot", style: TextStyle(color: Colors.white, fontSize: 14)),
        backgroundColor: Colors.black,
        actions: [
          if (_isDocumentLoaded && _normalizedPosition != null)
            TextButton(
              onPressed: _confirmPosition,
              child: const Text("Save", style: TextStyle(color: Colors.greenAccent)),
            )
        ],
      ),
      body: Stack(
        children: [
          kIsWeb 
            ? SfPdfViewer.memory(
                widget.pdfBytes!,
                controller: _pdfViewerController,
                onTap: _handlePdfTap,
                enableTextSelection: false,
                onDocumentLoaded: (details) => setState(() => _isDocumentLoaded = true),
              )
            : SfPdfViewer.file(
                widget.pdfFile!,
                controller: _pdfViewerController,
                onTap: _handlePdfTap,
                enableTextSelection: false,
                onDocumentLoaded: (details) => setState(() => _isDocumentLoaded = true),
              ),

          if (_visualPosition != null)
            Positioned(
              left: _visualPosition!.dx - 40,
              top: _visualPosition!.dy - 20,
              child: IgnorePointer(
                child: Container(
                  width: 80, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.3),
                    border: Border.all(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Text("SIGN HERE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 9)),
                  ),
                ),
              ),
            ),
          
          if (!_isDocumentLoaded)
            const Center(child: CircularProgressIndicator(color: Color(0xFFDC2726))),
        ],
      ),
    );
  }
}