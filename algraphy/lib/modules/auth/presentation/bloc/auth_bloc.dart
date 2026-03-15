import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:algraphy/modules/auth/data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../../../core/services/logger_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;

  AuthBloc(this._repo) : super(AuthInitial()) {
    
    on<AppStarted>((event, emit) async {
      try {
        final user = await _repo.getCurrentUser();
        if (user != null) {
          // Verify with server to ensure account still exists
          try {
            final verifiedUser = await _repo.validateSession();
            emit(AuthAuthenticated(verifiedUser));
          } catch (e) {
            logger.w("AUTH: Session stale or user deleted: $e");
            await _repo.logout();
            emit(AuthUnauthenticated());
          }
        } else {
          emit(AuthUnauthenticated());
        }
      } catch (e) {
        logger.e("AUTH: App start error: $e");
        emit(AuthUnauthenticated());
      }
    });

    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await _repo.login(event.email, event.password);
        emit(AuthAuthenticated(user));
      } catch (e) {
        emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
      }
    });

    on<ClientSignupRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await _repo.signupClient(
          name: event.name,
          email: event.email,
          password: event.password,
          phone: event.phone,
          companyName: event.companyName,
          industry: event.industry,
          servicesNeeded: event.servicesNeeded,
        );
        // Emitting ClientSignupSuccess instead of AuthAuthenticated
        // so they stay on LoginPage but can be toggled back to 'login' mode
        emit(ClientSignupSuccess());
      } catch (e) {
        emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
      }
    });


    // 3. Logout
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
          final updatedUser = currentUser.copyWith(mustChangePassword: false);
          emit(AuthAuthenticated(updatedUser));
        }
      } catch (e) {
        logger.e("Change Password Error: $e");
        emit(AuthFailure(e.toString()));
      }
    });

    on<DeleteAccountRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await _repo.deleteUser();
        emit(AuthUnauthenticated());
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });
  }
}