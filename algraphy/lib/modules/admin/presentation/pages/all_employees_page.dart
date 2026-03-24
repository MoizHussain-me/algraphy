import 'package:algraphy/core/utils/image_helper.dart';
import 'package:algraphy/modules/admin/data/repositories/admin_data_repository.dart';
import 'package:algraphy/modules/auth/data/models/user_model.dart';
import 'package:algraphy/modules/profile/presentation/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../views/registration_form_view.dart';

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
      confirmColor: currentlyActive ? Color(0xFFDC2726) : Colors.green,
    );
    if (!confirmed) return;

    try {
      await _repo.updateAccountStatus(user.id, !currentlyActive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${user.fullName} has been ${action.toLowerCase()}d.'),
          backgroundColor: currentlyActive ? Color(0xFFDC2726) : Colors.green,
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
          'They will no longer be able to log in. This action cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: Theme.of(context).primaryColor,
    );
    if (!confirmed) return;

    try {
      await _repo.softDeleteAccount(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${user.fullName}\'s account has been deleted.'),
          backgroundColor: Theme.of(context).primaryColor,
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
    final theme = Theme.of(context);
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: TextStyle(color: theme.textTheme.titleLarge?.color, fontWeight: FontWeight.bold)),
        content: Text(message, style: TextStyle(color: theme.hintColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: theme.hintColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  // ---------- BUILD ----------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: theme.primaryColor));
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
            style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor),
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
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    hintText: 'Search by name, role, department…',
                    hintStyle: TextStyle(color: theme.hintColor),
                    prefixIcon: Icon(Icons.search, color: theme.hintColor),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: theme.hintColor),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilter();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: isDark ? BorderSide.none : BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: isDark ? BorderSide.none : BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.refresh, color: theme.hintColor),
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
                style: TextStyle(color: theme.hintColor, fontSize: 12),
              ),
            ],
          ),
        ),

        // --- List ---
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.people_outline, size: 64, color: theme.disabledColor),
                    const SizedBox(height: 12),
                    Text('No employees found', style: TextStyle(color: theme.hintColor)),
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
    final theme = Theme.of(context);
    final bool isActive = user.isActive;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: theme.cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDark ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isActive
              ? theme.dividerColor.withOpacity(isDark ? 0.08 : 0.1)
              : Color(0xFFDC2726).withValues(alpha: 0.3),
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
                source: ProfileSource.management,
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
                    backgroundColor: theme.primaryColor.withValues(alpha: 0.15),
                    backgroundImage: _getProfileImage(user.profilePicture),
                    child: user.profilePicture == null || user.profilePicture!.isEmpty
                        ? Text(
                            user.firstName?.isNotEmpty == true
                                ? user.firstName![0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: theme.primaryColor,
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
                          color: Color(0xFFDC2726),
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.cardColor, width: 2),
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
                            style: TextStyle(
color: isDark ? Colors.white : theme.textTheme.titleLarge?.color,
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
                              color: Color(0xFFDC2726).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Color(0xFFDC2726).withValues(alpha: 0.4)),
                            ),
                            child: const Text(
                              'Disabled',
                              style: TextStyle(color: Color(0xFFDC2726), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [user.designation, user.department].where((s) => s != null && s.isNotEmpty).join(' • '),
                      style: TextStyle(color: theme.hintColor, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: TextStyle(color: theme.hintColor.withOpacity(0.7), fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.employeeCode != null && user.employeeCode!.isNotEmpty)
                      Text(
                        user.employeeCode!,
                        style: TextStyle(color: theme.hintColor.withOpacity(0.5), fontSize: 10),
                      ),
                  ],
                ),
              ),

              // --- Admin Action Menu ---
              if (isAdmin)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: theme.hintColor),
                  color: theme.cardColor,
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
                                backgroundColor: theme.scaffoldBackgroundColor,
                              ),
                              backgroundColor: theme.scaffoldBackgroundColor,
                              body: RegistrationFormView(userToEdit: user),
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
                    if (true) // Removed kIsWeb since new form works on mobile
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit_outlined, color: theme.primaryColor, size: 18),
                          const SizedBox(width: 10),
                          Text('Edit Profile', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                        ]),
                      ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(children: [
                        Icon(
                          isActive ? Icons.block : Icons.check_box,
                          color: isActive ? Color(0xFFDC2726) : Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isActive ? 'Disable Account' : 'Enable Account',
                          style: TextStyle(color: isActive ? Color(0xFFDC2726) : Colors.green),
                        ),
                      ]),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline, color: theme.primaryColor, size: 18),
                        const SizedBox(width: 10),
                        Text('Delete Account', style: TextStyle(color: theme.primaryColor)),
                      ]),
                    ),
                  ],
                )
              else
                Icon(Icons.chevron_right, color: theme.hintColor),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider? _getProfileImage(String? path) {
    return ImageHelper.getProvider(path);
  }
}