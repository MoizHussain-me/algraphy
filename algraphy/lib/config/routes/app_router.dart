import 'package:algraphy/modules/admin/presentation/pages/employee_management_page.dart';
import 'package:algraphy/modules/admin/presentation/pages/departments_page.dart';
import 'package:algraphy/modules/admin/presentation/pages/designations_page.dart';
import 'package:algraphy/modules/admin/presentation/pages/shifts_page.dart';
import 'package:algraphy/modules/auth/presentation/bloc/auth_state.dart';
import 'package:algraphy/modules/auth/presentation/pages/login.dart';
import 'package:algraphy/modules/employee/presentation/pages/attendance_history.dart';
import 'package:algraphy/modules/profile/presentation/profile_page.dart';
import 'package:algraphy/modules/signature/data/repository/signature_repository.dart';
import 'package:algraphy/modules/signature/presentation/bloc/signature_bloc.dart';
import 'package:algraphy/modules/signature/presentation/pages/signature_view_page.dart';
import 'package:algraphy/modules/tasks/presentation/pages/tasks_page.dart';
import 'package:algraphy/core/theme/typography.dart';
import 'package:algraphy/modules/auth/presentation/pages/verify_email_page.dart';
import 'package:algraphy/modules/chat/presentation/pages/chat_list_page.dart';
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
    if (settings.name == null) return _errorRoute();

    // Parse URL for Web (e.g. /verify-email?token=xyz)
    final uri = Uri.parse(settings.name!);
    final queryParams = uri.queryParameters;
    final path = uri.path;

    switch (path) {
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
            body: ProfilePage(
              user: user, 
              loggedInUser: user, 
              source: ProfileSource.dashboard
            ),
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
                // Both can perform management tasks on BOTH Mobile and Web.
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

      case AppRoutes.departments:
        return _buildProtectedPage(
          settings: settings,
          builder: (user) {
            if (user.role == 'admin' || user.role == 'manager') {
              return MainScaffold(
                title: 'Departments',
                currentRoute: AppRoutes.departments,
                currentUser: user,
                body: const DepartmentsPage(),
              );
            }
            return _buildAccessDenied(user, AppRoutes.departments);
          },
        );

      case AppRoutes.designations:
        return _buildProtectedPage(
          settings: settings,
          builder: (user) {
            if (user.role == 'admin' || user.role == 'manager') {
              return MainScaffold(
                title: 'Designations',
                currentRoute: AppRoutes.designations,
                currentUser: user,
                body: const DesignationsPage(),
              );
            }
            return _buildAccessDenied(user, AppRoutes.designations);
          },
        );

      case AppRoutes.shifts:
        return _buildProtectedPage(
          settings: settings,
          builder: (user) {
            if (user.role == 'admin' || user.role == 'manager') {
              return MainScaffold(
                title: 'Working Shifts',
                currentRoute: AppRoutes.shifts,
                currentUser: user,
                body: const ShiftsPage(),
              );
            }
            return _buildAccessDenied(user, AppRoutes.shifts);
          },
        );

      case AppRoutes.chats:
        return _buildProtectedPage(
          settings: settings,
          builder: (user) => MainScaffold(
            title: 'Chats',
            currentRoute: AppRoutes.chats,
            currentUser: user,
            body: const ChatListPage(),
          ),
        );

      case AppRoutes.settings:

      // Inside AppRouter.dart
      case AppRoutes.signature:
      case '/signature':
        // Extract token from settings.arguments or URL parameters
        final String token = (settings.arguments as String?) ?? queryParams['token'] ?? "";

        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => SignatureBloc(SignatureRepository()),
            child: SignatureViewPage(token: token),
          ),
        );

      case AppRoutes.verifyEmail:
      case '/verify':
        final String verifyToken = (settings.arguments as String?) ?? queryParams['token'] ?? "";
        return MaterialPageRoute(
          builder: (_) => VerifyEmailPage(token: verifyToken),
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

  // --- Helper for Access Denied screen ---
  static Widget _buildAccessDenied(UserModel user, String route) {
    return MainScaffold(
      title: 'Access Denied',
      currentRoute: route,
      currentUser: user,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Access Restricted",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(child: Text('Route not found')),
      ),
    );
  }
}
