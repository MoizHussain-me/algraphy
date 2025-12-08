import 'package:algraphy/core/utils/image_helper.dart';
import 'package:algraphy/modules/admin/data/repositories/admin_data_repository.dart';
import 'package:algraphy/modules/auth/data/models/user_model.dart';
import 'package:algraphy/modules/profile/presentation/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../views/registration_stepper_view.dart'; // Uncommented!

class AllEmployeesPage extends StatefulWidget {
  const AllEmployeesPage({super.key});

  @override
  State<AllEmployeesPage> createState() => _AllEmployeesPageState();
}

class _AllEmployeesPageState extends State<AllEmployeesPage> {
  List<UserModel> _employees = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    try {
      final employees = await GetIt.I<AdminRepository>().getAllEmployees();
      if (mounted) {
        setState(() {
          _employees = employees;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text("Error: $_error", style: const TextStyle(color: Colors.red)));
    }
    if (_employees.isEmpty) {
      return const Center(child: Text("No employees found", style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _employees.length,
      itemBuilder: (context, index) {
        final user = _employees[index];
        return Card(
          color: const Color(0xFF1C1C1C),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[800],
              backgroundImage: _getProfileImage(user.profilePicture),
              child: user.profilePicture == null
                  ? Text(
                      user.firstName?.isNotEmpty == true ? user.firstName![0] : "U",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            title: Text(
              user.fullName.isNotEmpty ? user.fullName : "Unknown Name",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  "${user.designation ?? 'No Designation'} • ${user.department ?? 'No Dept'}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  user.email,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit Button (Now Connected)
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFFDC2726)),
                  tooltip: "Edit Employee",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(
                            title: const Text("Edit Employee"),
                            backgroundColor: const Color(0xFF080808),
                          ),
                          backgroundColor: const Color(0xFF080808),
                          body: RegistrationStepperView(userToEdit: user),
                        ),
                      ),
                    ).then((_) => _fetchEmployees()); // Refresh on return
                  },
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            onTap: () {
              // Open Profile View
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfilePage(user: user)),
              );
            },
          ),
        );
      },
    );
  }

  ImageProvider? _getProfileImage(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return NetworkImage(path);
    if (!kIsWeb) return FileImage(File(path));
    final fullUrl = ImageHelper.getFullUrl(path);
    return NetworkImage(fullUrl); // Fallback
  }
}