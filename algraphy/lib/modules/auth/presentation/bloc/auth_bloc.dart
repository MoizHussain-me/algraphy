import 'package:algraphy/modules/auth/data/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import the separate files (Do NOT define classes here)
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;

  AuthBloc(this._repo) : super(AuthInitial()) {
    
    on<AppStarted>((event, emit) async {
            try {
        // This calls the method that prints "AUTH: Checking storage..."
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

    on<LoginRequested>((event, emit) async {
              final user = await _repo.getCurrentUser();
           emit(AuthLoading());
      try {
        emit(AuthAuthenticated(user!));
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }

    });

    on<LogoutRequested>((event, emit) async {
      emit(AuthLoading());
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
      
        print("Change Password Error: $e");
        
      }
    });
  }
}
