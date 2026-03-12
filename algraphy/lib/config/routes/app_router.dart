import 'package:algraphy/modules/admin/presentation/pages/employee_management_page.dart';
import 'package:algraphy/modules/auth/presentation/bloc/auth_state.dart';
import 'package:algraphy/modules/auth/presentation/pages/login.dart';
import 'package:algraphy/modules/employee/presentation/pages/attendance_history.dart';
import 'package:algraphy/modules/profile/presentation/profile_page.dart';
import 'package:algraphy/modules/signature/data/repository/signature_repository.dart';
import 'package:algraphy/modules/signature/presentation/bloc/signature_bloc.dart';
import 'package:algraphy/modules/signature/presentation/pages/signature_view_page.dart';
import 'package:algraphy/modules/tasks/presentation/pages/tasks_page.dart';
import 'package:algraphy/core/theme/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Key for Platform check
import '../../modules/auth/data/models/user_model.dart';
import '../../modules/auth/presentation/bloc/auth_bloc.dart';
import '../../modules/client/presentation/pages/client_dashboard_page.dart';
import '../../modules/client/presentation/pages/pending_dashboard_page.dart';
import '../../modules/employee/presentation/pages/attendance_page.dart';
import '../../modules/common/widgets/main_scaffold.dart';
import '../../modules/common/widgets/coming_soon_page.dart';
import 'app_routes.dart';

class AppRouter {
  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      // -----------------------------------------------------------------------
      // HOME (Default Dashboard - usually Attendance)
      // -----------------------------------------------------------------------
      case AppRoutes.home:
        return _buildProtectedPage(
          settings: settings,
          builder: (user) {
            // Route based on role
            if (user.role == 'Client' || user.role == 'client') {
              return MainScaffold(
                title: 'Client Dashboard',
                currentRoute: AppRoutes.home,
                currentUser: user,
                body: ClientDashboardPage(currentUser: user),
              );
            }
            
            // Default for employees/admins
            return MainScaffold(
              title: 'Dashboard',
              currentRoute: AppRoutes.home,
              currentUser: user,
              body: AttendancePage(currentUser: user),
            );
          },
        );

      // -----------------------------------------------------------------------
      // ATTENDANCE
      // -----------------------------------------------------------------------
      case AppRoutes.attendance:
        return _buildProtectedPage(
          settings: settings,
          builder: (user) => MainScaffold(
            title: 'Attendance',
            currentRoute: AppRoutes.attendance,
            currentUser: user,
            body: AttendancePage(currentUser: user),
          ),
        );

      // -----------------------------------------------------------------------
      // ATTENDANCE
      // -----------------------------------------------------------------------
      case AppRoutes.attendanceHistory:
        return _buildProtectedPage(
          settings: settings,
          builder: (user) => MainScaffold(
            title: 'History',
            currentRoute:
                AppRoutes.attendance, // Keep 'Attendance' active in drawer
            currentUser: user,
            body: const AttendanceHistoryPage(),
          ),
        );

      // -----------------------------------------------------------------------
      // LOGIN (Public Route - Unified)
      // -----------------------------------------------------------------------
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => LoginPage());

      // -----------------------------------------------------------------------
      // PROFILE & OTHER MENU ITEMS
      // (Using Coming Soon to prevent errors until you build the Profile UI)
      // -----------------------------------------------------------------------
      case AppRoutes.profile:
        return _buildProtectedPage(
          settings: settings,
          builder: (user) => MainScaffold(
            title: 'Profile',
            currentRoute: AppRoutes.profile,
            currentUser: user,
            body: ProfilePage(user: user, showScaffold: false),
          ),
        );

      case AppRoutes.employees:
        return _buildProtectedPage(
          settings: settings,
          builder: (user) {
            // Allow Admin/Manager on BOTH Mobile and Web
            if (user.role == 'admin' || user.role == 'manager') {
              return MainScaffold(
                title: 'Employees',
                currentRoute: AppRoutes.employees,
                currentUser: user,
                // Both can perform management tasks; 
                // Stepper will still show 'Portal Only' on mobile.
                body: EmployeeManagementPage(isAdmin: true, currentUser: user),
              );
            } else {
              // Access Denied Fallback for normal employees/clients
              return MainScaffold(
                title: 'Employees',
                currentRoute: AppRoutes.employees,
                currentUser: user,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_clock, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "Access Restricted",
                        style: AppTypography.textTheme.titleLarge,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "This section is only available to Administrators.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        );

      case AppRoutes.tasks:
        return _buildProtectedPage(
          settings: settings,
          builder: (user) => MainScaffold(
            title: 'Tasks',
            currentRoute: AppRoutes.tasks,
            currentUser: user,
            body: const TasksPage(),
          ),
        );

      case AppRoutes.chats:
      case AppRoutes.settings:
      case AppRoutes.algraphyPro:
      case AppRoutes.about:
      case AppRoutes.services:
      case AppRoutes.work:
      case AppRoutes.plans:
      case AppRoutes.talents:
      case AppRoutes.contact:
      case AppRoutes.privacyPolicy:
        return _buildProtectedPage(
          settings: settings,
          builder: (user) => MainScaffold(
            title: _getTitleFromRoute(settings.name),
            currentRoute: settings.name ?? '',
            currentUser: user,
            body: ComingSoonPage(title: _getTitleFromRoute(settings.name)),
          ),
        );

      // Inside AppRouter.dart
      case AppRoutes.signature:
        // Extract token from settings.arguments or URL parameters
        final String token = settings.arguments as String? ?? "";

        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => SignatureBloc(SignatureRepository()),
            child: SignatureViewPage(token: token),
          ),
        );

      // -----------------------------------------------------------------------
      // 404 Not Found
      // -----------------------------------------------------------------------
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Route not found'))),
        );
    }
  }

  // --- Helper to handle Auth Protection & User Injection ---
  static MaterialPageRoute _buildProtectedPage({
    required RouteSettings settings,
    required Widget Function(UserModel user) builder,
  }) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            // User is logged in, show the protected page
            return builder(state.user);
          } else if (state is AuthUnauthenticated) {
            // Not logged in, redirect to Unified Login
            return const LoginPage();
          } else {
            // Loading state (AuthInitial or AuthLoading)
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }

  // --- Helper to format title strings ---
  static String _getTitleFromRoute(String? route) {
    if (route == null) return '';
    // Removes slash and creates a clean title (e.g., "/about" -> "ABOUT")
    return route.replaceAll('/', '').toUpperCase();
  }
}
