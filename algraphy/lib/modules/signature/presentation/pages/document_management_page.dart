import 'dart:convert';
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
import 'package:intl/intl.dart';

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
      final userJson = prefs.getString(AppConstants.userKey);

      String url = "${AppConstants.apiBaseUrl}?action=get_all_signature_requests";

      if (!widget.isAdmin) {
        if (userJson == null) {
          if (mounted) setState(() => isLoading = false);
          return;
        }

        final Map<String, dynamic> userMap = jsonDecode(userJson);
        final user = UserModel.fromMap(userMap);
        final String? filterId = user.employeeId ?? user.id;

        if (filterId != null && filterId.isNotEmpty) {
          url += "&employee_id=$filterId";
        } else {
          if (mounted) setState(() => isLoading = false);
          return;
        }
      }

      final response = await Dio().get(
        url,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.data['status'] == 'success') {
        if (mounted) {
          setState(() {
            docs = (response.data['data'] as List)
                .map((e) => SignatureRequestModel.fromJson(e))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _openCreateSheet() async {
    try {
      final employees = await GetIt.I<AdminRepository>().getAllEmployees();
      if (!mounted) return;

      final Set<String> seenIds = {};
      final List<UserModel> uniqueEmployees = employees.where((emp) {
        if (emp.id.isEmpty) return false;
        return seenIds.add(emp.id);
      }).toList();

      if (uniqueEmployees.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No employees found.")),
        );
        return;
      }

      final result = await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: CreateSignatureRequestView(employees: uniqueEmployees),
        ),
      );

      if (result == true) _fetchDocuments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: theme.primaryColor));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: widget.isAdmin 
        ? FloatingActionButton(
            backgroundColor: theme.primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: _openCreateSheet,
          )
        : null,
      body: RefreshIndicator(
        onRefresh: _fetchDocuments,
        color: theme.primaryColor,
        child: docs.isEmpty 
          ? const Center(child: Text("No documents found", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final bool isSigned = doc.status == 'Signed';
                final bool isExpired = doc.expiryDate != null && 
                    DateTime.parse(doc.expiryDate!).isBefore(DateTime.now()) &&
                    !isSigned;

                return Card(
                  color: theme.cardColor,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: isDark ? 0 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isExpired 
                        ? const BorderSide(color: Colors.red, width: 1) 
                        : BorderSide(color: theme.dividerColor.withOpacity(isDark ? 0.05 : 0.1)),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.picture_as_pdf, 
                      color: isSigned ? Colors.green : (isExpired ? Colors.grey : Colors.red),
                      size: 32,
                    ),
                    title: Text(
                      doc.documentTitle, 
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color, 
                        fontWeight: FontWeight.bold
                      )
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          "Status: ${isExpired ? 'Expired' : doc.status}", 
                          style: TextStyle(
                            color: isSigned ? Colors.green : (isExpired ? Colors.red : Colors.orange), 
                            fontSize: 12,
                            fontWeight: FontWeight.w600
                          )
                        ),
                        if (doc.expiryDate != null)
                          Text(
                            "Expires: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(doc.expiryDate!))}",
                            style: TextStyle(
                              color: isExpired ? Colors.red.withOpacity(0.7) : Colors.grey, 
                              fontSize: 11
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.blue),
                          onPressed: () => _viewPDF(
                            isSigned ? (doc.signedPath ?? '') : doc.originalPath, 
                            isSigned ? "Signed PDF" : "Original PDF"
                          ),
                        ),
                        if (doc.status == 'Pending' && !widget.isAdmin && !isExpired)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onPressed: () => Navigator.pushNamed(
                              context, '/signature', arguments: doc.token
                            ).then((_) => _fetchDocuments()),
                            child: const Text("Sign", style: TextStyle(color: Colors.white, fontSize: 12)),
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