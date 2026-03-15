import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:algraphy/modules/auth/data/models/user_model.dart';
import 'package:algraphy/core/utils/image_helper.dart';

enum ProfileSource { attendance, management, dashboard }

class ProfilePage extends StatelessWidget {
  final UserModel user;           // The profile being viewed
  final UserModel loggedInUser;   // The person viewing the profile
  final ProfileSource source;     // Where they came from

  const ProfilePage({
    super.key,
    required this.user,
    required this.loggedInUser,
    required this.source,
  });

  // Logic: Show sensitive data ONLY if I am looking at myself
  bool get isSelfView => user.id == loggedInUser.id;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _buildHeader(theme, isDark),
            const SizedBox(height: 24),
            
            // 1. Quick Communication (Common for both)
            _buildCommunicationRow(theme),
            const SizedBox(height: 32),

            // 2. Professional Info (Visible to everyone)
            _buildSectionTitle("Professional Details"),
            _buildInfoCard(theme, [
              _infoTile(theme, "Employee ID", user.employeeCode ?? "-", Icons.badge_outlined),
              _infoTile(theme, "Designation", user.designation ?? "-", Icons.work_outline),
              _infoTile(theme, "Department", user.department ?? "-", Icons.lan_outlined),
              _infoTile(theme, "Reporting Manager (L1)", user.reportingManagerName ?? "-", Icons.account_tree_outlined),
              if (user.secondaryReportingManagerName != null && user.secondaryReportingManagerName!.isNotEmpty)
                _infoTile(theme, "Reporting Manager (L2)", user.secondaryReportingManagerName!, Icons.account_tree_outlined),
              _infoTile(theme, "Location", user.location ?? "Office", Icons.location_on_outlined),
            ]),

            const SizedBox(height: 24),

            // 3. Manager/Admin Specific Actions
            if (source == ProfileSource.management && !isSelfView) ...[
              _buildSectionTitle("Manager Actions"),
              _buildAdminActionTile(
                "View Attendance Logs", 
                Icons.history_toggle_off, 
                Colors.blue, 
                () => print("Navigate to logs for ${user.fullName}"),
              ),
              _buildAdminActionTile(
                "Leave History", 
                Icons.calendar_month_outlined, 
                Colors.orange, 
                () => print("Navigate to leaves"),
              ),
            ],

            // 4. Private Financial Info (Only visible if Self-Viewing)
            if (isSelfView) ...[
              const SizedBox(height: 24),
              _buildSectionTitle("Private Financials"),
              _buildInfoCard(theme, [
                _infoTile(theme, "Monthly Salary", "\$${user.salary ?? '0.0'}", Icons.payments_outlined),
                _infoTile(theme, "Bank IBAN", user.iban ?? "-", Icons.account_balance_wallet_outlined),
              ]),
            ],
            
            const SizedBox(height: 40),
       ] ), // End of Column
      ), // End of SingleChildScrollView
    ), // End of SafeArea
  ); // End of Scaffold
}

  // --- UI BUILDERS ---

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.primaryColor.withOpacity(0.2), width: 2),
          ),
          child: CircleAvatar(
            radius: 55,
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            backgroundImage: user.profilePicture != null && user.profilePicture!.isNotEmpty
                ? NetworkImage(ImageHelper.getFullUrl(user.profilePicture!))
                : null,
            child: (user.profilePicture == null || user.profilePicture!.isEmpty)
                ? Text(user.firstName?[0] ?? "U", 
                    style: TextStyle(fontSize: 36, color: theme.primaryColor, fontWeight: FontWeight.bold))
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(user.fullName, 
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 4),
        Text(user.email, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        if (user.designation != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.designation!.toUpperCase(),
              style: TextStyle(color: theme.primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCommunicationRow(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _iconBtn(theme, Icons.phone, "Call", () => _launch('tel:${user.personalMobileNumber ?? user.workPhoneNumber ?? ''}')),
        _iconBtn(theme, Icons.message, "SMS", () => _launch('sms:${user.personalMobileNumber ?? user.workPhoneNumber ?? ''}')),
        _iconBtn(theme, Icons.email, "Email", () => _launch('mailto:${user.email}')),
      ],
    );
  }

  Widget _iconBtn(ThemeData theme, IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        IconButton.filledTonal(
          onPressed: onTap, 
          icon: Icon(icon, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            foregroundColor: theme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title.toUpperCase(), 
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, List<Widget> children) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _infoTile(ThemeData theme, String label, String value, IconData icon) {
    final isDark = theme.brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: Colors.grey.shade500),
      ),
      title: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      subtitle: Text(value, style: TextStyle(
        fontSize: 14, 
        fontWeight: FontWeight.w600, 
        color: isDark ? Colors.white70 : Colors.black87
      )),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildAdminActionTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), 
        side: BorderSide(color: color.withOpacity(0.1))
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color, size: 20),
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        trailing: Icon(Icons.chevron_right, color: color, size: 18),
        dense: true,
      ),
    );
  }

  Future<void> _launch(String url) async {
    if (url.isEmpty || url.endsWith(':')) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}