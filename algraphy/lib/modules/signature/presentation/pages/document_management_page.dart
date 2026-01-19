import 'package:algraphy/core/utils/constants.dart';
import 'package:algraphy/modules/admin/data/repositories/admin_data_repository.dart';
import 'package:algraphy/modules/auth/data/models/user_model.dart';
import 'package:algraphy/modules/signature/data/models/signature_request_model.dart';
import 'package:algraphy/modules/signature/presentation/pages/PDF_Preview_Page.dart';
import 'package:algraphy/modules/signature/presentation/pages/create_signature_request_view.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';

class DocumentManagementPage extends StatefulWidget {
  final bool isAdmin;
  const DocumentManagementPage({super.key, required this.isAdmin});

  @override
  State<DocumentManagementPage> createState() => _DocumentManagementPageState();
}

class _DocumentManagementPageState extends State<DocumentManagementPage> {
  List<SignatureRequestModel> docs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);

      final response = await Dio().get(
        "${AppConstants.apiBaseUrl}?action=get_all_signature_requests",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.data['status'] == 'success') {
        setState(() {
          docs = (response.data['data'] as List)
              .map((e) => SignatureRequestModel.fromJson(e))
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Logic to show the creation sheet (For Admins)
  void _openCreateSheet() async {
    try {
      // 1. Fetch employees first (required for the dropdown in the sheet)
      final employees = await GetIt.I<AdminRepository>().getAllEmployees();
      
      if (!mounted) return;

      // 2. Filter for unique IDs to prevent Dropdown assertion errors
      final Set<String> seenIds = {};
      final List<UserModel> uniqueEmployees = employees.where((emp) {
        if (emp.id.isEmpty) return false;
        return seenIds.add(emp.id);
      }).toList();

      if (uniqueEmployees.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No employees found to request signatures from.")),
        );
        return;
      }

      // 3. Show the upload form
      final result = await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: CreateSignatureRequestView(employees: uniqueEmployees),
        ),
      );

      if (result == true) {
        _fetchDocuments(); // Refresh list if a new doc was created
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Navigation to preview
  void _viewPDF(String relativePath, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFPreviewPage(pdfUrl: relativePath, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFFDC2726)));

    return Scaffold(
      backgroundColor: Colors.transparent,
      // Only show the Plus button if the user is an Admin
      floatingActionButton: widget.isAdmin 
        ? FloatingActionButton(
            backgroundColor: const Color(0xFFDC2726),
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: _openCreateSheet,
          )
        : null,
      body: RefreshIndicator(
        onRefresh: _fetchDocuments,
        color: const Color(0xFFDC2726),
        child: docs.isEmpty 
          ? const Center(child: Text("No documents found", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final bool isSigned = doc.status == 'Signed';

                return Card(
                  color: const Color(0xFF1C1C1C),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(
                      Icons.picture_as_pdf, 
                      color: isSigned ? Colors.green : Colors.red,
                      size: 32,
                    ),
                    title: Text(
                      doc.documentTitle, 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                    ),
                    subtitle: Text(
                      "Status: ${doc.status}", 
                      style: TextStyle(color: isSigned ? Colors.green : Colors.orange)
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // VIEW BUTTON
                        IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.blue),
                          onPressed: () => _viewPDF(
                            isSigned ? (doc.signedPath ?? '') : doc.originalPath, 
                            isSigned ? "Signed PDF" : "Original PDF"
                          ),
                        ),
                        
                        // SIGN BUTTON (Only for employees on pending docs)
                        if (doc.status == 'Pending' && !widget.isAdmin)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2726),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => Navigator.pushNamed(
                              context, '/signature', arguments: doc.token
                            ).then((_) => _fetchDocuments()),
                            child: const Text("Sign", style: TextStyle(color: Colors.white)),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }
}