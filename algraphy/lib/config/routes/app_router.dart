import 'package:algraphy/modules/admin/presentation/pages/admin_create_user_page.dart';
import 'package:algraphy/modules/attendance/presentation/pages/attendance_page.dart';
import 'package:algraphy/modules/auth/presentation/bloc/auth_bloc.dart';
import 'package:algraphy/modules/auth/presentation/bloc/auth_state.dart';
import 'package:algraphy/modules/auth/presentation/pages/login_page.dart';
import 'package:algraphy/modules/auth/presentation/pages/register_page.dart';
import 'package:algraphy/modules/common/widgets/coming_soon_page.dart';
import 'package:algraphy/modules/common/widgets/main_scaffold.dart';
import 'package:algraphy/modules/profile/presentation/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_routes.dart';

class AppRouter {
  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return MainScaffold(
                  title: 'Attendance',
                  body: const AttendancePage(),
                  currentRoute: AppRoutes.attendance, // pass explicitly
                  currentUser: state.user,
                );
              } else if (state is AuthUnauthenticated) {
                return const LoginPage();
              } else {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
            },
          ),
        );


 case AppRoutes.create_user:
        return MaterialPageRoute(
          builder: (_) => BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return MainScaffold(
                  title: 'Add Employee',
                  body: const AdminCreateUserPage(),
                  currentRoute: AppRoutes.create_user, // pass explicitly
                  currentUser: state.user,
                );
              } else if (state is AuthUnauthenticated) {
                return const LoginPage();
              } else {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
            },
          ),
        );



      case AppRoutes.attendance:
        return MaterialPageRoute(
          builder: (_) => BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return MainScaffold(
                  title: 'Attendance',
                  body: const AttendancePage(),
                  currentRoute: AppRoutes.attendance, // pass explicitly
                  currentUser: state.user,
                );
              } else if (state is AuthUnauthenticated) {
                return const LoginPage();
              } else {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
            },
          ),
        );

      // case AppRoutes.employees:
      //   return MaterialPageRoute(
      //     builder: (_) => const ComingSoonPage(title: 'Contact'),
      //   );

      // case AppRoutes.profile:
      //   return MaterialPageRoute(
      //     builder: (_) =>  MainScaffold(
      //       title: 'Profile',
      //       body: const ProfilePage(),
      //       currentRoute: AppRoutes.profile, // pass explicitly
      //     ),
      
      //   );

      // case AppRoutes.chats:
      //   return MaterialPageRoute(
      //     builder: (_) => const ComingSoonPage(title: 'Contact'),
      //   );

      // case AppRoutes.settings:
      //   return MaterialPageRoute(
      //     builder: (_) => const ComingSoonPage(title: 'Contact'),
      //   );

      // // Coming soon pages
      // case AppRoutes.algraphyPro:
      //   return MaterialPageRoute(
      //     builder: (_) => const ComingSoonPage(title: 'Algraphy Pro'),
      //   );

      // case AppRoutes.about:
      //   return MaterialPageRoute(
      //     builder: (_) => const ComingSoonPage(title: 'About'),
      //   );

      // case AppRoutes.services:
      //   return MaterialPageRoute(
      //     builder: (_) => const ComingSoonPage(title: 'Services'),
      //   );

      // case AppRoutes.work:
      //   return MaterialPageRoute(
      //     builder: (_) => const ComingSoonPage(title: 'Work'),
      //   );

      // case AppRoutes.plans:
      //   return MaterialPageRoute(
      //     builder: (_) => const ComingSoonPage(title: 'Plans'),
      //   );

      // case AppRoutes.talents:
      //   return MaterialPageRoute(
      //     builder: (_) => const ComingSoonPage(title: 'Talents'),
      //   );

      // case AppRoutes.contact:
      //   return MaterialPageRoute(
      //     builder: (_) => const ComingSoonPage(title: 'Contact'),
      //   );

      // case AppRoutes.register:
      //   return MaterialPageRoute(builder: (_) => const RegisterPage());
      // case AppRoutes.login:
      //   return MaterialPageRoute(builder: (_) => const LoginPage());

      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Route not found'))),
        );
    }
  }
}
