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

  // Color Palette
  static const Color accentRed = Color(0xFFDC2726);
  static const Color backgroundDark = Color(0xFF0A0A0A);
  static const Color surfaceColor = Color(0xFF161616);
  static const Color cardBorder = Color(0xFF262626);

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
    final bool isClient = user.role == 'client';

    Widget pageContent = CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 1. Sleek Header
        SliverToBoxAdapter(child: _buildHeader(context)),

        // 2. Action Bar (Quick Contact)
        SliverToBoxAdapter(child: _buildQuickActions()),

        // 3. Information Grid/List
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (user.aboutMe != null && user.aboutMe!.isNotEmpty) ...[
                _buildSection(
                  title: "About Me",
                  icon: Icons.info_outline,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        user.aboutMe!,
                        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              if (isClient) ...[
                _buildSection(
                  title: "Business Information",
                  icon: Icons.business_outlined,
                  children: [
                    _buildInfoTile("Company / Brand", user.companyName ?? "-", Icons.storefront_outlined),
                    _buildInfoTile("Industry", user.industry ?? "-", Icons.category_outlined),
                    _buildInfoTile("Services Needed", user.servicesNeeded ?? "-", Icons.handyman_outlined),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              if (!isClient) ...[
                _buildSection(
                  title: "Work Information",
                  icon: Icons.work_outline,
                  children: [
                    _buildInfoTile("Employee ID", user.employeeId ?? "-", Icons.badge_outlined),
                    _buildInfoTile("Employee Code", user.employeeCode ?? "-", Icons.qr_code_outlined),
                    _buildInfoTile("Nick Name", user.nickName ?? "-", Icons.face_outlined),
                    _buildInfoTile("Reporting To", user.reportingManagerName ?? "-", Icons.account_tree_outlined),
                    _buildInfoTile("Date of Joining", _formatDate(user.dateOfJoining), Icons.calendar_month_outlined),
                    _buildInfoTile("Department", user.department ?? "-", Icons.lan_outlined),
                    _buildInfoTile("Location", user.location ?? "-", Icons.location_on_outlined),
                    _buildInfoTile("Designation", user.designation ?? "-", Icons.work_outline),
                    _buildInfoTile("Employment Type", user.employmentType ?? "-", Icons.assignment_ind_outlined),
                    _buildInfoTile("Status", user.employeeStatus ?? "-", Icons.check_circle_outline),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: "Financial Information",
                  icon: Icons.account_balance_wallet_outlined,
                  children: [
                    _buildInfoTile("Monthly Salary", _formatCurrency(user.salary), Icons.payments_outlined),
                    _buildInfoTile("Hourly Rate", _formatCurrency(user.employeeHourlyRate), Icons.timer_outlined),
                    _buildInfoTile("Last Month Commission", _formatCurrency(user.lastMonthCommission), Icons.trending_up),
                    _buildInfoTile("IBAN", user.iban ?? "-", Icons.credit_card_outlined),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: "Experience & Expertise",
                  icon: Icons.psychology_outlined,
                  children: [
                    _buildInfoTile("Current Experience", user.currentExperience ?? "-", Icons.history_toggle_off),
                    _buildInfoTile("Total Experience", user.totalExperience ?? "-", Icons.history),
                    _buildInfoTile("Expertise", user.expertise ?? "-", Icons.star_outline),
                    _buildInfoTile("Source of Hire", user.sourceOfHire ?? "-", Icons.campaign_outlined),
                    _buildInfoTile("Job Description", user.jobDescription ?? "-", Icons.description_outlined),
                    _buildInfoTile("Sub Job Description", user.subJobDescription ?? "-", Icons.subject_outlined),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              _buildSection(
                title: "Contact Details",
                icon: Icons.contact_mail_outlined,
                children: [
                  _buildInfoTile("Work Email", user.email, Icons.alternate_email),
                  _buildInfoTile("Personal Email", user.personalEmailAddress ?? "-", Icons.email_outlined),
                  _buildInfoTile("Mobile", user.personalMobileNumber ?? "-", Icons.phone_android),
                  if (!isClient) ...[
                    _buildInfoTile("Work Phone", user.workPhoneNumber ?? "-", Icons.phone_callback_outlined),
                    _buildInfoTile("Extension", user.extension ?? "-", Icons.phone_forwarded_outlined),
                    _buildInfoTile("Seating", user.seatingLocation ?? "-", Icons.chair_alt_outlined),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              if (!isClient) ...[
                _buildSection(
                  title: "Addresses",
                  icon: Icons.home_outlined,
                  children: [
                    _buildInfoTile("Present Address", user.presentAddress ?? "-", Icons.location_searching),
                    _buildInfoTile("Permanent Address", user.permanentAddress ?? "-", Icons.house_outlined),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: "Personal Information",
                  icon: Icons.person_outline,
                  children: [
                    _buildInfoTile("Birthday", _formatDate(user.dateOfBirth), Icons.cake_outlined),
                    _buildInfoTile("Gender", user.gender ?? "-", Icons.fingerprint),
                    _buildInfoTile("Marital Status", user.maritalStatus ?? "-", Icons.favorite_border),
                  ],
                ),
              ],
              const SizedBox(height: 24),

              // --- DELETE ACCOUNT (REQUIRED BY APPLE) ---
              if (user.role == 'client') ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withOpacity(0.1)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          "Account Management",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
        body: Container(color: backgroundDark, child: pageContent),
      );
    }
    return Scaffold(backgroundColor: backgroundDark, body: pageContent);
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF251010), backgroundDark],
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
                  border: Border.all(color: accentRed.withOpacity(0.5), width: 2),
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: surfaceColor,
                  backgroundImage: _getProfileImage(user.profilePicture),
                  child: user.profilePicture == null
                      ? Text(
                          user.firstName?[0] ?? "U",
                          style: const TextStyle(fontSize: 36, color: Colors.white),
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
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          if (user.role != 'client') ...[
            const SizedBox(height: 6),
            Text(
              user.designation?.toUpperCase() ?? 'STAFF',
              style: TextStyle(color: accentRed.withOpacity(0.9), fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 1.2),
            ),
            const SizedBox(height: 4),
            Text(
              user.department ?? 'General',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _actionIcon(Icons.phone, "Call"),
          _actionIcon(Icons.message_rounded, "Message"),
          _actionIcon(Icons.email_rounded, "Email"),
          _actionIcon(Icons.share_rounded, "Share"),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          height: 45,
          width: 45,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _buildSection({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                Icon(icon, color: accentRed, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          const Divider(color: cardBorder, thickness: 1),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: backgroundDark, borderRadius: BorderRadius.circular(8)),
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
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
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
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Account?", style: TextStyle(color: Colors.white)),
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
              Navigator.pop(dialogContext); // Close dialog
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