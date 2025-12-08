import 'package:algraphy/modules/auth/data/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import the separate files (Do NOT define classes here)
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;

  AuthBloc(this._repo) : super(AuthInitial()) {
    
    on<AppStarted>((event, emit) async {
      // Check for persisted token logic here if implementing auto-login
      // For now, default to Unauthenticated
      emit(AuthUnauthenticated());
    });

    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await _repo.login(event.email, event.password);
        emit(AuthAuthenticated(user));
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    on<LogoutRequested>((event, emit) async {
      await _repo.logout();
      emit(AuthUnauthenticated());
    });

    on<ChangePasswordRequested>((event, emit) async {
      try {
        await _repo.changePassword(event.newPassword);
        
        if (state is AuthAuthenticated) {
          final currentUser = (state as AuthAuthenticated).user;
          
          // Success: Update flag and go to Dashboard
          final updatedUser = currentUser.copyWith(
            mustChangePassword: false,
          );
          emit(AuthAuthenticated(updatedUser));
        }
      } catch (e) {
        // 🛑 CRITICAL FIX:
        // Do NOT emit AuthFailure here. That causes logout.
        // Instead, we just print the error. 
        // Ideally, emit a side-effect state, but for now, doing nothing 
        // keeps the user on the "Change Password" page so they can try again.
        print("Change Password Error: $e");
        
        // Optional: If you want to show a SnackBar, you'd need a separate 
        // "SubmissionFailed" state that extends AuthAuthenticated, 
        // but simply catching it here prevents the Logout crash.
      }
    });
  }
}