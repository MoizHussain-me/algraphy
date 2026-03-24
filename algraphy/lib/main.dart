import 'package:algraphy/modules/auth/data/auth_repository.dart';
import 'package:algraphy/modules/auth/presentation/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Config
import 'config/di/injector.dart';
import 'config/routes/app_router.dart';
import 'core/services/logger_service.dart';


import 'core/theme/app_theme.dart';

// Bloc
import 'modules/auth/presentation/bloc/auth_bloc.dart';
import 'modules/auth/presentation/bloc/auth_state.dart';
import 'modules/auth/presentation/bloc/auth_event.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'core/services/notification_service.dart';

// Pages
import 'modules/employee/presentation/pages/attendance_page.dart'; 
import 'modules/auth/presentation/pages/change_password_page.dart'; 
import 'modules/common/widgets/main_scaffold.dart';
import 'modules/client/presentation/pages/client_dashboard_page.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyCq31TfSN_aa9YkfCQ8JHXFC5F9iPXwKZI",
          authDomain: "al-graphy-pro.firebaseapp.com",
          projectId: "al-graphy-pro",
          storageBucket: "al-graphy-pro.firebasestorage.app",
          messagingSenderId: "620504539920",
          appId: "1:620504539920:web:f0ae5c4b8c208d93bbbb95",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await NotificationService().initialize();
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

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
        theme: AppTheme.lightTheme, // Use the light theme we built
  darkTheme: AppTheme.darkTheme, // Use the dark theme we built
  
  // Choose 'system' to follow phone settings, or 'light'/'dark' to force it
  themeMode: ThemeMode.system,
        
        
        onGenerateRoute: AppRouter.generate,
        
        // --- AUTH GUARD LOGIC ---
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            
            // Debugging: Print state changes to console
            logger.d("Current Auth State: $state");

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
            
            // 2. Initial Checks (App start only)
            else if (state is AuthInitial) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFFDC2726)),
                ),
              );
            }
            
            // 3. Login Page (Unauthenticated, Loading, Failure, etc.)
            else {
              return const LoginPage();
            }
          },
        ),
      ),
    );
  }
}