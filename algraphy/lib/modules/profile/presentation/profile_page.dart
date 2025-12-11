import 'package:algraphy/config/routes/app_routes.dart';
import 'package:algraphy/modules/auth/data/models/user_model.dart';
import 'package:algraphy/modules/common/widgets/main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:intl/intl.dart'; // Ensure intl is imported
import '../../../../core/utils/image_helper.dart';

class ProfilePage extends StatelessWidget {
  final UserModel user;
  final bool showScaffold; // NEW: Control flag to enable/disable the wrapper

  const ProfilePage({
    super.key, 
    required this.user,
    this.showScaffold = true, // Default to true (Standalone mode)
  });

  // --- Helper: Format Date ---
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == "0000-00-00") {
      return "-";
    }
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMM yyyy').format(date);
    } catch (_) {
      return dateStr; // Fallback if parsing fails
    }
  }

  // --- Helper: Get Manager Name ---
  String _getManagerName() {
    if (user.reportingManagerName != null && user.reportingManagerName!.isNotEmpty) {
      return user.reportingManagerName!;
    }
    return user.reportingManager ?? "-";
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundDark = Color(0xFF080808);
    const Color cardColor = Color(0xFF1C1C1C);

    // 1. Define the actual page content separate from the Scaffold
    Widget pageContent = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 1. Profile Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: _getProfileImage(user.profilePicture),
                  child: user.profilePicture == null
                      ? Text(
                          user.firstName?[0] ?? "U",
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                
                Text(
                  user.fullName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  "${user.designation ?? 'No Designation'} • ${user.department ?? 'No Dept'}",
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 8),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    user.employeeStatus ?? "Active",
                    style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
      
          const SizedBox(height: 24),
      
          // 2. Info Sections
          _buildSection(
            title: "Work Information",
            children: [
              _buildInfoRow(Icons.badge, "Employee ID", user.employeeId ?? "-"),
              _buildInfoRow(Icons.email, "Work Email", user.email),
              _buildInfoRow(Icons.calendar_today, "Date of Joining", _formatDate(user.dateOfJoining)), 
              _buildInfoRow(Icons.timer, "Employment Type", user.employmentType ?? "-"),
              _buildInfoRow(Icons.supervisor_account, "Reporting Manager", _getManagerName()), 
              _buildInfoRow(Icons.location_on, "Office Location", user.location ?? "-"),
            ],
          ),
      
          const SizedBox(height: 16),
      
          _buildSection(
            title: "Contact Details",
            children: [
              _buildInfoRow(Icons.phone_iphone, "Mobile", user.personalMobileNumber ?? "-"),
              _buildInfoRow(Icons.phone, "Work Phone", user.workPhoneNumber ?? "-"),
              _buildInfoRow(Icons.email_outlined, "Personal Email", user.personalEmailAddress ?? "-"),
              _buildInfoRow(Icons.chair, "Seating Location", user.seatingLocation ?? "-"),
            ],
          ),
      
          const SizedBox(height: 16),
      
          _buildSection(
            title: "Personal Information",
            children: [
              _buildInfoRow(Icons.cake, "Date of Birth", _formatDate(user.dateOfBirth)), 
              _buildInfoRow(Icons.person, "Gender", user.gender ?? "-"),
              _buildInfoRow(Icons.family_restroom, "Marital Status", user.maritalStatus ?? "-"),
              _buildInfoRow(Icons.account_balance, "IBAN", user.iban ?? "-"),
            ],
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );

    // 2. Conditional Return
    // If showScaffold is true, wrap in MainScaffold (adds AppBar + Drawer/Menu)
    if (showScaffold) {
      return MainScaffold(
        title: "Profile",
        currentUser: user,
        currentRoute: AppRoutes.profile,      
        body: pageContent,
      );
    } 
    
    // If false (embedded mode), return plain scaffold/container to avoid duplicate AppBar
    return Scaffold(
      backgroundColor: backgroundDark,
      body: pageContent,
    );
  }

  ImageProvider? _getProfileImage(String? path) {
    if (path == null || path.isEmpty) return null;
    return NetworkImage(ImageHelper.getFullUrl(path));
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Color(0xFFDC2726), fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}