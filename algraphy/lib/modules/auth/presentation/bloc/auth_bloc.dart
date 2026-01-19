import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:algraphy/modules/auth/data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../../../core/services/logger_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;

  AuthBloc(this._repo) : super(AuthInitial()) {
    
    // 1. App Start: Check Storage
    on<AppStarted>((event, emit) async {
      try {
        final user = await _repo.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(AuthUnauthenticated());
        }
      } catch (_) {
        emit(AuthUnauthenticated());
      }
    });

    // 2. Login: Call API (NOT Storage)
    on<LoginRequested>((event, emit) async {
      emit(AuthLoading()); // 1. Show Loading Spinner
      
      try {
        // FIX: Call login() to hit API, not getCurrentUser()
        final user = await _repo.login(event.email, event.password);
        
        // login() returns a non-null User on success, so no '!' needed
        emit(AuthAuthenticated(user)); 
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    // 3. Logout
    on<LogoutRequested>((event, emit) async {
      emit(AuthLoading());
      await _repo.logout();
      emit(AuthUnauthenticated());
    });

    // 4. Change Password
    on<ChangePasswordRequested>((event, emit) async {
      try {
        await _repo.changePassword(event.newPassword);
        
        if (state is AuthAuthenticated) {
          final currentUser = (state as AuthAuthenticated).user;
          // Update the local user model so UI updates immediately
          final updatedUser = currentUser.copyWith(mustChangePassword: false);
          emit(AuthAuthenticated(updatedUser));
        }
      } catch (e) {
        // Ideally emit a failure state or show a snackbar via a listener, 
        // but for now we catch it to prevent crashing.
        logger.e("Change Password Error: $e");
        emit(AuthFailure(e.toString()));
      }
    });
  }
}