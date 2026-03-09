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
          emit(AuthAuthenticated(user));
        } else {
          emit(AuthUnauthenticated());
        }
      } catch (_) {
        emit(AuthUnauthenticated());
      }
    });

    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        // 1. Try Internal Login First
        try {
          final user = await _repo.login(event.email, event.password);
          emit(AuthAuthenticated(user));
          return;
        } catch (e) {
          logger.d("AUTH: Internal login failed, trying Talent: $e");
        }

        // 2. Try Talent Login Fallback
        final data = await _repo.loginTalent(event.email, event.password);
        final url = data['webview_url'];
        if (url != null) {
          emit(AuthTalentRedirect(url));
        } else {
          emit(AuthFailure("Invalid login credentials"));
        }
      } catch (e) {
        emit(AuthFailure("Login failed: Invalid email or password"));
      }
    });

    on<TalentLoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final data = await _repo.loginTalent(event.email, event.password);
        final url = data['webview_url'];
        if (url != null) {
          emit(AuthTalentRedirect(url));
        } else {
          emit(AuthFailure("Talent portal URL not found"));
        }
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    on<TalentSignupRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final data = await _repo.signupTalent(
          name: event.name,
          email: event.email,
          password: event.password,
          userType: event.userType,
          talentType: event.talentType,
        );
        final url = data['webview_url'];
        if (url != null) {
          emit(AuthTalentRedirect(url));
        } else {
          emit(AuthFailure("Talent portal URL not found"));
        }
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
  }
}