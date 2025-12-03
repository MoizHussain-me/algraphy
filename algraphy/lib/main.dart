import 'package:algraphy/config/di/injector.dart';
import 'package:algraphy/config/routes/app_router.dart';
import 'package:algraphy/core/theme/app_theme.dart';
import 'package:algraphy/modules/attendance/presentation/pages/attendance_page.dart';
import 'package:algraphy/modules/auth/data/local_user_repository.dart';
import 'package:algraphy/modules/auth/presentation/bloc/auth_bloc.dart';
import 'package:algraphy/modules/auth/presentation/bloc/auth_event.dart';
import 'package:algraphy/modules/auth/presentation/bloc/auth_state.dart';
import 'package:algraphy/modules/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setup();

  final localUserRepo = getIt<LocalUserRepository>();

  runApp(
    BlocProvider(
      create: (_) => AuthBloc(localUserRepo)..add(AppStarted()),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Algraphy People",
      debugShowCheckedModeBanner: true,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      onGenerateRoute: AppRouter.generate, // keeps routing working
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthInitial || state is AuthLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (state is AuthAuthenticated) {
            return const AttendancePage(); // first page after login
          } else if (state is AuthUnauthenticated) {
            return const LoginPage(); // first page if not logged in
          } else {
            return const Scaffold(
              body: Center(child: Text("Something went wrong")),
            );
          }
        },
      ),
    );
  }
}
