import 'package:algraphy/config/routes/app_routes.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class SideMenu extends StatelessWidget {
final bool isPersistent;
final String activeRoute;

const SideMenu({super.key, this.isPersistent = false, this.activeRoute = AppRoutes.home});

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryRed,
            child: const Icon(Icons.person, color: AppColors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'John Doe',
                  style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text(
                  'Product Designer',
                  style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      color: AppColors.textGrey,
                      fontSize: 12),
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
    leading: Icon(icon, color: isActive ? AppColors.primaryRed : AppColors.textGrey),
    title: Text(
      label,
      style: TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: isActive ? AppColors.primaryRed : AppColors.textGrey,
        fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
      ),
    ),
    trailing: isPersistent ? null : const Icon(Icons.chevron_right, color: AppColors.textGrey),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    hoverColor: AppColors.primaryRed.withOpacity(0.06),
    onTap: () {
      if (!isPersistent) Navigator.of(context).pop(); // close drawer if mobile
      if (routeName != activeRoute) {
        Navigator.of(context).pushNamed(routeName);
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
              const Divider(color: AppColors.textGrey, height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildMenuItem(
                        context,
                        icon: Icons.access_time,
                        label: 'Attendance',
                        routeName: AppRoutes.attendance),
                    _buildMenuItem(
                        context,
                        icon: Icons.people,
                        label: 'Profile',
                        routeName: AppRoutes.profile),
                    _buildMenuItem(
                        context,
                        icon: Icons.business,
                        label: 'Algraphy Pro',
                        routeName: AppRoutes.algraphyPro),
                    _buildMenuItem(
                        context,
                        icon: Icons.chat,
                        label: 'Chats',
                        routeName: AppRoutes.chats),
                    _buildMenuItem(
                        context,
                        icon: Icons.info,
                        label: 'About',
                        routeName: AppRoutes.about),
                    _buildMenuItem(
                        context,
                        icon: Icons.miscellaneous_services,
                        label: 'Services',
                        routeName: AppRoutes.services),
                    _buildMenuItem(
                        context,
                        icon: Icons.work,
                        label: 'Work',
                        routeName: AppRoutes.work),
                    _buildMenuItem(
                        context,
                        icon: Icons.article,
                        label: 'Plans',
                        routeName: AppRoutes.plans),
                    _buildMenuItem(
                        context,
                        icon: Icons.emoji_people,
                        label: 'Employees',
                        routeName: AppRoutes.employees),
                    _buildMenuItem(
                        context,
                        icon: Icons.contact_mail,
                        label: 'Contact',
                        routeName: AppRoutes.contact),
                    _buildMenuItem(
                        context,
                        icon: Icons.settings,
                        label: 'Settings',
                        routeName: AppRoutes.settings),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
