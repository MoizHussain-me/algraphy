import 'package:algraphy/core/utils/image_helper.dart';
import 'package:algraphy/modules/admin/data/repositories/admin_data_repository.dart';
import 'package:algraphy/modules/auth/data/models/user_model.dart';
import 'package:algraphy/modules/profile/presentation/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../views/registration_stepper_view.dart';

class AllEmployeesPage extends StatefulWidget {
  final UserModel currentUser;
  const AllEmployeesPage({super.key, required this.currentUser});

  @override
  State<AllEmployeesPage> createState() => _AllEmployeesPageState();
}

class _AllEmployeesPageState extends State<AllEmployeesPage> {
  final AdminRepository _repo = GetIt.I<AdminRepository>();
  List<UserModel> _allEmployees = [];
  List<UserModel> _filtered = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEmployees() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final employees = await _repo.getAllEmployees();
      if (mounted) {
        setState(() {
          _allEmployees = employees;
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filtered = List.from(_allEmployees);
      } else {
        _filtered = _allEmployees.where((u) {
          return u.fullName.toLowerCase().contains(query) ||
              (u.designation?.toLowerCase().contains(query) ?? false) ||
              (u.department?.toLowerCase().contains(query) ?? false) ||
              u.email.toLowerCase().contains(query) ||
              (u.employeeCode?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  // ---------- ACTIONS ----------

  Future<void> _toggleStatus(UserModel user, bool currentlyActive) async {
    final action = currentlyActive ? 'Disable' : 'Enable';
    final confirmed = await _showConfirmDialog(
      title: '$action Account',
      message: 'Are you sure you want to $action ${user.fullName}\'s account?',
      confirmLabel: action,
      confirmColor: currentlyActive ? Colors.orange : Colors.green,
    );
    if (!confirmed) return;

    try {
      await _repo.updateAccountStatus(user.id, !currentlyActive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${user.fullName} has been ${action.toLowerCase()}d.'),
          backgroundColor: currentlyActive ? Colors.orange : Colors.green,
        ));
        _fetchEmployees();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _deleteEmployee(UserModel user) async {
    final confirmed = await _showConfirmDialog(
      title: 'Delete Account',
      message:
          'This will permanently deactivate ${user.fullName}\'s account. '
          'They will no longer be able to log in. This action cannot be easily undone.',
      confirmLabel: 'Delete',
      confirmColor: const Color(0xFFDC2726),
    );
    if (!confirmed) return;

    try {
      await _repo.softDeleteAccount(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${user.fullName}\'s account has been deleted.'),
          backgroundColor: const Color(0xFFDC2726),
        ));
        _fetchEmployees();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  // ---------- BUILD ----------

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFDC2726)));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text("Error: $_error", style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchEmployees,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2726)),
          ),
        ]),
      );
    }

    final bool isAdmin = widget.currentUser.role == 'admin';

    return Column(
      children: [
        // --- Search Bar ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by name, role, department…',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilter();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF1C1C1C),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.grey),
                tooltip: 'Refresh',
                onPressed: _fetchEmployees,
              ),
            ],
          ),
        ),

        // --- Count badge ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '${_filtered.length} employee${_filtered.length == 1 ? '' : 's'}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),

        // --- List ---
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey[800]),
                    const SizedBox(height: 12),
                    const Text('No employees found', style: TextStyle(color: Colors.grey)),
                  ]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) => _buildEmployeeCard(_filtered[index], isAdmin),
                ),
        ),
      ],
    );
  }

  Widget _buildEmployeeCard(UserModel user, bool isAdmin) {
    final bool isActive = user.isActive;

    return Card(
      color: const Color(0xFF1C1C1C),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isActive
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfilePage(
                user: user,
                loggedInUser: widget.currentUser,
                showScaffold: true,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // --- Avatar ---
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFFDC2726).withValues(alpha: 0.15),
                    backgroundImage: _getProfileImage(user.profilePicture),
                    child: user.profilePicture == null || user.profilePicture!.isEmpty
                        ? Text(
                            user.firstName?.isNotEmpty == true
                                ? user.firstName![0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Color(0xFFDC2726),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  if (!isActive)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1C1C1C), width: 2),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 14),

              // --- Details ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.fullName.trim().isEmpty ? 'Unknown' : user.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                            ),
                            child: const Text(
                              'Disabled',
                              style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [user.designation, user.department].where((s) => s != null && s.isNotEmpty).join(' • '),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.employeeCode != null && user.employeeCode!.isNotEmpty)
                      Text(
                        user.employeeCode!,
                        style: TextStyle(color: Colors.grey[700], fontSize: 10),
                      ),
                  ],
                ),
              ),

              // --- Admin Action Menu ---
              if (isAdmin)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  color: const Color(0xFF2A2A2A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              appBar: AppBar(
                                title: const Text('Edit Employee'),
                                backgroundColor: const Color(0xFF080808),
                              ),
                              backgroundColor: const Color(0xFF080808),
                              body: RegistrationStepperView(userToEdit: user),
                            ),
                          ),
                        ).then((_) => _fetchEmployees());
                        break;
                      case 'toggle':
                        _toggleStatus(user, isActive);
                        break;
                      case 'delete':
                        _deleteEmployee(user);
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    if (kIsWeb)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit_outlined, color: Color(0xFFDC2726), size: 18),
                          SizedBox(width: 10),
                          Text('Edit Profile', style: TextStyle(color: Colors.white)),
                        ]),
                      ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(children: [
                        Icon(
                          isActive ? Icons.block : Icons.check_circle_outline,
                          color: isActive ? Colors.orange : Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isActive ? 'Disable Account' : 'Enable Account',
                          style: TextStyle(color: isActive ? Colors.orange : Colors.green),
                        ),
                      ]),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline, color: Color(0xFFDC2726), size: 18),
                        SizedBox(width: 10),
                        Text('Delete Account', style: TextStyle(color: Color(0xFFDC2726))),
                      ]),
                    ),
                  ],
                )
              else
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider? _getProfileImage(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return NetworkImage(path);
    if (!kIsWeb) return FileImage(File(path));
    final fullUrl = ImageHelper.getFullUrl(path);
    return NetworkImage(fullUrl);
  }
}