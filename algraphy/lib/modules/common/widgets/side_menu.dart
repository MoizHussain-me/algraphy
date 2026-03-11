import 'package:algraphy/modules/auth/presentation/bloc/auth_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../config/routes/app_routes.dart';
import '../../auth/data/models/user_model.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../../core/theme/colors.dart'; 
import '../../../core/theme/typography.dart'; 

class SideMenu extends StatelessWidget {
  final bool isPersistent;
  final String activeRoute;
  final UserModel currentUser; 

  const SideMenu({
    super.key,
    this.isPersistent = false,
    this.activeRoute = AppRoutes.home,
    required this.currentUser,
  });

  Widget _buildHeader(BuildContext context) {
    final String fullName = "${currentUser.firstName ?? ''} ${currentUser.lastName ?? ''}".trim();
    String role = currentUser.role;
    if (role.toLowerCase() == 'admin') role = 'Administrator';
    else if (role.toLowerCase() == 'manager') role = 'Manager';
    else if (role.toLowerCase() == 'client') role = 'System Client';
    else role = role[0].toUpperCase() + role.substring(1).toLowerCase();
    
    final String email = currentUser.email;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      color: const Color(0xFF1C1C1C), 
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryRed,
            child: Text(
              fullName.isNotEmpty ? fullName[0].toUpperCase() : "U",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isNotEmpty ? fullName : "User",
                  style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      color: Colors.grey,
                      fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      color: AppColors.primaryRed,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context,
      {required IconData icon,
      required String label,
      required String routeName}) {
    final isActive = routeName == activeRoute;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: isActive ? AppColors.primaryRed : Colors.grey),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: isActive ? AppColors.primaryRed : Colors.grey,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
        ),
      ),
      trailing: isPersistent ? null : const Icon(Icons.chevron_right, color: Colors.grey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      hoverColor: AppColors.primaryRed.withValues(alpha: 0.06),
      onTap: () {
        if (!isPersistent) Navigator.of(context).pop();
        if (routeName != activeRoute) {
          Navigator.of(context).pushReplacementNamed(routeName);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: AppColors.backgroundDark,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              const Divider(color: Colors.white10, height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    // --- Main Core (Visible to All) ---
                    _buildMenuItem(context, icon: Icons.dashboard, label: 'Algraphy Pro', routeName: AppRoutes.home),
                    _buildMenuItem(context, icon: Icons.task_alt, label: 'Tasks', routeName: AppRoutes.tasks),
                    
                    if (currentUser.role != 'client') ...[
                      const Divider(color: Colors.white10),
                      // --- Organization / Modules (Internal Only) ---
                      // _buildMenuItem(context, icon: Icons.chat, label: 'Chats', routeName: AppRoutes.chats),
                      // _buildMenuItem(context, icon: Icons.work, label: 'Work', routeName: AppRoutes.work),
                      // _buildMenuItem(context, icon: Icons.article, label: 'Plans', routeName: AppRoutes.plans),
                      // _buildMenuItem(context, icon: Icons.emoji_people, label: 'Talents', routeName: AppRoutes.talents),
                    ],
                    
                    const Divider(color: Colors.white10),

                    // --- Info & Support (Visible to All) ---
                    // _buildMenuItem(context, icon: Icons.miscellaneous_services, label: 'Services', routeName: AppRoutes.services),
                    // _buildMenuItem(context, icon: Icons.info, label: 'About', routeName: AppRoutes.about),
                    _buildMenuItem(context, icon: Icons.contact_mail, label: 'Contact', routeName: AppRoutes.contact),
                    // _buildMenuItem(context, icon: Icons.settings, label: 'Settings', routeName: AppRoutes.settings),

                    // --- Admin Section (Only for Admin/Manager) ---
                    if (currentUser.role == 'admin' || currentUser.role == 'manager') ...[
                      const Divider(color: Colors.white10),
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
                        child: Text("ADMINISTRATION", style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      _buildMenuItem(context, icon: Icons.person_add, label: 'Employees', routeName: AppRoutes.employees),
                    ],
                  ],
                ),
              ),
              // --- LOGOUT BUTTON ---
              const Divider(color: Colors.white10),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                onTap: () {
                  context.read<AuthBloc>().add(LogoutRequested());
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}