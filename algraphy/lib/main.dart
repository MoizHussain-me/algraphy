import 'package:algraphy/modules/auth/data/auth_repository.dart';
import 'package:algraphy/modules/auth/presentation/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Config
import 'config/di/injector.dart';
import 'config/routes/app_router.dart';

// Bloc
import 'modules/auth/presentation/bloc/auth_bloc.dart';
import 'modules/auth/presentation/bloc/auth_state.dart';
import 'modules/auth/presentation/bloc/auth_event.dart';

// Pages
import 'modules/employee/presentation/pages/attendance_page.dart'; 
import 'modules/auth/presentation/pages/change_password_page.dart'; 
import 'modules/common/widgets/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setup(); 

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(getIt<AuthRepository>())..add(AppStarted()),
      child: MaterialApp(
        title: 'Algraphy People',
        debugShowCheckedModeBanner: false,
        
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF080808),
          primaryColor: const Color(0xFFDC2726),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1C1C1C),
            elevation: 0,
          ),
        ),
        
        onGenerateRoute: AppRouter.generate,
        
        // --- AUTH GUARD LOGIC ---
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            
            // Debugging: Print state changes to console
            print("Current Auth State: $state");

            // 1. Logged In Successfully
            if (state is AuthAuthenticated) {
              if (state.user.mustChangePassword) {
                return const ChangePasswordPage();
              }
              return MainScaffold(
                title: 'Dashboard',
                currentUser: state.user,
                body: AttendancePage(currentUser: state.user), 
              );
            } 
            
            // 2. Explicitly Not Logged In
            else if (state is AuthUnauthenticated) {
              return const LoginPage();
            }
            
            // 3. Waiting for Storage Check (AuthInitial or AuthLoading)
            else {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFFDC2726)),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}