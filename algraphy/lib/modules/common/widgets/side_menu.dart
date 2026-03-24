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
      color: Theme.of(context).colorScheme.surface, 
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              fullName.isNotEmpty ? fullName[0].toUpperCase() : "U",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isNotEmpty ? fullName : "User",
                  style: Theme.of(context).textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: Theme.of(context).textTheme.labelSmall,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = routeName == activeRoute;

    // Define colors based on theme and active state
    final activeColor = theme.primaryColor;
    final inactiveColor = isDark ? Colors.grey[400] : AppColors.textBlack;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2), // Added slight breathing room
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        
        // --- TINTED BACKGROUND FOR ACTIVE TAB ---
        tileColor: isActive 
            ? activeColor.withValues(alpha: isDark ? 0.1 : 0.05) 
            : Colors.transparent,
            
        leading: Icon(
          icon, 
          color: isActive ? activeColor : inactiveColor, 
          size: 22
        ),
        
        title: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isActive ? activeColor : inactiveColor,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, // Slightly bolder for better legibility
          ),
        ),
        
        trailing: isPersistent 
            ? null 
            : Icon(Icons.chevron_right, color: inactiveColor, size: 18),
            
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Matches your cardTheme
        
        hoverColor: activeColor.withValues(alpha: 0.08),
        
        onTap: () {
          if (!isPersistent) Navigator.of(context).pop();
          if (routeName != activeRoute) {
            Navigator.of(context).pushReplacementNamed(routeName);
          }
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
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
                    _buildMenuItem(context, icon: Icons.dashboard, label: 'AlGraphy Pro', routeName: AppRoutes.home),
                    _buildMenuItem(context, icon: Icons.task_alt, label: 'Tasks', routeName: AppRoutes.tasks),
                    
                    if (currentUser.role != 'client') ...[
                      //const Divider(color: Colors.white10),
                      // --- Organization / Modules (Internal Only) ---
                      _buildMenuItem(context, icon: Icons.chat, label: 'Chats', routeName: AppRoutes.chats),
                      // _buildMenuItem(context, icon: Icons.work, label: 'Work', routeName: AppRoutes.work),
                      // _buildMenuItem(context, icon: Icons.article, label: 'Plans', routeName: AppRoutes.plans),
                      // _buildMenuItem(context, icon: Icons.emoji_people, label: 'Talents', routeName: AppRoutes.talents),
                    ],
                    
                    // const Divider(color: Colors.white10),

                    // --- Info & Support (Visible to All) ---
                    // _buildMenuItem(context, icon: Icons.miscellaneous_services, label: 'Services', routeName: AppRoutes.services),
                    // _buildMenuItem(context, icon: Icons.info, label: 'About', routeName: AppRoutes.about),
                    //_buildMenuItem(context, icon: Icons.contact_mail, label: 'Contact', routeName: AppRoutes.contact),
                    // _buildMenuItem(context, icon: Icons.settings, label: 'Settings', routeName: AppRoutes.settings),

                    // --- Admin Section (Only for Admin/Manager) ---
                    if (currentUser.role == 'admin' || currentUser.role == 'manager') ...[
                      const Divider(color: Colors.white10),
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
                        child: Text("ADMINISTRATION", style: Theme.of(context).textTheme.labelSmall),
                      ),
                      _buildMenuItem(context, icon: Icons.person_add, label: 'Employees', routeName: AppRoutes.employees),
                      _buildMenuItem(context, icon: Icons.business, label: 'Departments', routeName: AppRoutes.departments),
                      _buildMenuItem(context, icon: Icons.badge, label: 'Designations', routeName: AppRoutes.designations),
                      _buildMenuItem(context, icon: Icons.access_time, label: 'Working Shifts', routeName: AppRoutes.shifts),
                    ],
                  ],
                ),
              ),
              // --- LOGOUT BUTTON ---
              const Divider(color: Colors.white10),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: Text("Logout", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.redAccent, fontWeight: FontWeight.w600)),
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