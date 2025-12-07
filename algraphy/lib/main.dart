import 'package:algraphy/modules/auth/data/auth_repository.dart';
import 'package:algraphy/modules/auth/presentation/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'config/di/injector.dart';
import 'config/routes/app_router.dart';
import 'modules/auth/presentation/bloc/auth_bloc.dart';
import 'modules/employee/presentation/pages/attendance_page.dart';
import 'modules/common/widgets/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setup(); // Initialize Mock DI

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Get the MockRepo from GetIt and start the app
      create: (context) => AuthBloc(getIt<AuthRepository>())..add(AppStarted()),
      child: MaterialApp(
        title: 'Algraphy People',
        debugShowCheckedModeBanner: false,
        
        // Dark Theme Configuration
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF080808),
          primaryColor: const Color(0xFFDC2726),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1C1C1C),
            elevation: 0,
          ),
        ),
        
        // Routing
        onGenerateRoute: AppRouter.generate,
        
        // Initial Screen Logic (Auth Guard)
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              // User is logged in -> Show Dashboard with Attendance
              return MainScaffold(
                title: 'Dashboard',
                currentUser: state.user,
                body: AttendancePage(currentUser:  state.user), 
              );
            } else {
              // User is NOT logged in -> Show Unified Login Page
              return const LoginPage(); 
            }
          },
        ),
      ),
    );
  }
}