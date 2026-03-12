import 'package:algraphy/config/routes/app_routes.dart';
import 'package:algraphy/modules/auth/data/models/user_model.dart';
import 'package:algraphy/modules/common/widgets/main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/image_helper.dart';
import 'package:algraphy/modules/auth/presentation/bloc/auth_bloc.dart';
import 'package:algraphy/modules/auth/presentation/bloc/auth_event.dart';

class ProfilePage extends StatelessWidget {
  final UserModel user;
  final UserModel? loggedInUser;
  final bool showScaffold;

  const ProfilePage({
    super.key,
    required this.user,
    this.loggedInUser,
    this.showScaffold = true,
  });

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == "0000-00-00") return "-";
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMM yyyy').format(date);
    } catch (_) { return dateStr; }
  }

  String _formatCurrency(double? value) {
    if (value == null) return "-";
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isClient = user.role == 'client';

    Widget pageContent = CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        SliverToBoxAdapter(child: _buildQuickActions(context)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (user.aboutMe != null && user.aboutMe!.isNotEmpty) ...[
                _buildSection(
                  context: context,
                  title: "About Me",
                  icon: Icons.info_outline,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        user.aboutMe!,
                        style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14, height: 1.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              if (isClient) ...[
                _buildSection(
                  context: context,
                  title: "Business Information",
                  icon: Icons.business_outlined,
                  children: [
                    _buildInfoTile(context, "Company / Brand", user.companyName ?? "-", Icons.storefront_outlined),
                    _buildInfoTile(context, "Industry", user.industry ?? "-", Icons.category_outlined),
                    _buildInfoTile(context, "Services Needed", user.servicesNeeded ?? "-", Icons.handyman_outlined),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              if (!isClient) ...[
                _buildSection(
                  context: context,
                  title: "Work Information",
                  icon: Icons.work_outline,
                  children: [
                    _buildInfoTile(context, "Employee ID", user.employeeId ?? "-", Icons.badge_outlined),
                    _buildInfoTile(context, "Employee Code", user.employeeCode ?? "-", Icons.qr_code_outlined),
                    _buildInfoTile(context, "Nick Name", user.nickName ?? "-", Icons.face_outlined),
                    _buildInfoTile(context, "Reporting To", user.reportingManagerName ?? "-", Icons.account_tree_outlined),
                    _buildInfoTile(context, "Date of Joining", _formatDate(user.dateOfJoining), Icons.calendar_month_outlined),
                    _buildInfoTile(context, "Department", user.department ?? "-", Icons.lan_outlined),
                    _buildInfoTile(context, "Location", user.location ?? "-", Icons.location_on_outlined),
                    _buildInfoTile(context, "Designation", user.designation ?? "-", Icons.work_outline),
                    _buildInfoTile(context, "Employment Type", user.employmentType ?? "-", Icons.assignment_ind_outlined),
                    _buildInfoTile(context, "Status", user.employeeStatus ?? "-", Icons.check_circle_outline),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context: context,
                  title: "Financial Information",
                  icon: Icons.account_balance_wallet_outlined,
                  children: [
                    _buildInfoTile(context, "Monthly Salary", _formatCurrency(user.salary), Icons.payments_outlined),
                    _buildInfoTile(context, "Hourly Rate", _formatCurrency(user.employeeHourlyRate), Icons.timer_outlined),
                    _buildInfoTile(context, "Last Month Commission", _formatCurrency(user.lastMonthCommission), Icons.trending_up),
                    _buildInfoTile(context, "IBAN", user.iban ?? "-", Icons.credit_card_outlined),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context: context,
                  title: "Experience & Expertise",
                  icon: Icons.psychology_outlined,
                  children: [
                    _buildInfoTile(context, "Current Experience", user.currentExperience ?? "-", Icons.history_toggle_off),
                    _buildInfoTile(context, "Total Experience", user.totalExperience ?? "-", Icons.history),
                    _buildInfoTile(context, "Expertise", user.expertise ?? "-", Icons.star_outline),
                    _buildInfoTile(context, "Source of Hire", user.sourceOfHire ?? "-", Icons.campaign_outlined),
                    _buildInfoTile(context, "Job Description", user.jobDescription ?? "-", Icons.description_outlined),
                    _buildInfoTile(context, "Sub Job Description", user.subJobDescription ?? "-", Icons.subject_outlined),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              _buildSection(
                context: context,
                title: "Contact Details",
                icon: Icons.contact_mail_outlined,
                children: [
                  _buildInfoTile(context, "Work Email", user.email, Icons.alternate_email),
                  _buildInfoTile(context, "Personal Email", user.personalEmailAddress ?? "-", Icons.email_outlined),
                  _buildInfoTile(context, "Mobile", user.personalMobileNumber ?? "-", Icons.phone_android),
                  if (!isClient) ...[
                    _buildInfoTile(context, "Work Phone", user.workPhoneNumber ?? "-", Icons.phone_callback_outlined),
                    _buildInfoTile(context, "Extension", user.extension ?? "-", Icons.phone_forwarded_outlined),
                    _buildInfoTile(context, "Seating", user.seatingLocation ?? "-", Icons.chair_alt_outlined),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              if (!isClient) ...[
                _buildSection(
                  context: context,
                  title: "Addresses",
                  icon: Icons.home_outlined,
                  children: [
                    _buildInfoTile(context, "Present Address", user.presentAddress ?? "-", Icons.location_searching),
                    _buildInfoTile(context, "Permanent Address", user.permanentAddress ?? "-", Icons.house_outlined),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context: context,
                  title: "Personal Information",
                  icon: Icons.person_outline,
                  children: [
                    _buildInfoTile(context, "Birthday", _formatDate(user.dateOfBirth), Icons.cake_outlined),
                    _buildInfoTile(context, "Gender", user.gender ?? "-", Icons.fingerprint),
                    _buildInfoTile(context, "Marital Status", user.maritalStatus ?? "-", Icons.favorite_border),
                  ],
                ),
              ],
              const SizedBox(height: 24),

              if (user.role == 'client') ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(isDark ? 0.05 : 0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withOpacity(0.1)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          "Account Management",
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Deleting your account is permanent and cannot be undone.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showDeleteConfirmation(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Delete Account", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );

    if (showScaffold) {
      return MainScaffold(
        title: "Profile",
        currentUser: loggedInUser ?? user,
        currentRoute: AppRoutes.profile,
        body: Container(color: theme.scaffoldBackgroundColor, child: pageContent),
      );
    }
    return Scaffold(backgroundColor: theme.scaffoldBackgroundColor, body: pageContent);
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark 
            ? [const Color(0xFF251010), theme.scaffoldBackgroundColor] 
            : [const Color(0xFFFEECEC), theme.scaffoldBackgroundColor],
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.primaryColor.withOpacity(0.5), width: 2),
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: theme.cardColor,
                  backgroundImage: _getProfileImage(user.profilePicture),
                  child: user.profilePicture == null
                      ? Text(
                          user.firstName?[0] ?? "U",
                          style: TextStyle(fontSize: 36, color: theme.textTheme.bodyLarge?.color),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 5,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user.fullName,
            style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          if (user.role != 'client') ...[
            const SizedBox(height: 6),
            Text(
              user.designation?.toUpperCase() ?? 'STAFF',
              style: TextStyle(color: theme.primaryColor.withOpacity(0.9), fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 1.2),
            ),
            const SizedBox(height: 4),
            Text(
              user.department ?? 'General',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5), fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _actionIcon(context, Icons.phone, "Call"),
          _actionIcon(context, Icons.message_rounded, "Message"),
          _actionIcon(context, Icons.email_rounded, "Email"),
          _actionIcon(context, Icons.share_rounded, "Share"),
        ],
      ),
    );
  }

  Widget _actionIcon(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          height: 45,
          width: 45,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          ),
          child: Icon(icon, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7), size: 20),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _buildSection({required BuildContext context, required String title, required IconData icon, required List<Widget> children}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                Icon(icon, color: theme.primaryColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                ),
              ],
            ),
          ),
          Divider(color: theme.dividerColor.withOpacity(0.1), thickness: 1),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: theme.scaffoldBackgroundColor.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.grey[600], size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _getProfileImage(String? path) {
    if (path == null || path.isEmpty) return null;
    return NetworkImage(ImageHelper.getFullUrl(path));
  }

  void _showDeleteConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Delete Account?", style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        content: const Text(
          "Are you absolutely sure? This will permanently delete your profile and all associated data. This action cannot be undone.",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(DeleteAccountRequested());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete Forever"),
          ),
        ],
      ),
    );
  }
}