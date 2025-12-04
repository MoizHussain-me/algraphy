import 'package:algraphy/modules/auth/data/models/user_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/local_user_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LocalUserRepository _repo;

  AuthBloc(this._repo) : super(AuthInitial()) {
    // App start
    on<AppStarted>((event, emit) async {
      // Default to unauthenticated for demo purposes
      emit(AuthUnauthenticated());
    });

    // Registration
    // on<RegisterRequested>((event, emit) async {
    //   emit(AuthLoading());
    //   try {
    //     final user = await _repo.register(
    //       name: event.name,
    //       email: event.email,
    //       password: event.password,
    //     );

    //     // Emit success
    //     emit(AuthAuthenticated(user));
    //   } catch (ex) {
    //     // Only emit AuthFailure once
    //     emit(AuthFailure(ex.toString()));
    //   }
    // });

    // Login
    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await _repo.login(
          email: event.email,
          password: event.password,
        );

        if (user != null) {
          emit(AuthAuthenticated(user as UserModel));
        } else {
          emit(AuthFailure('Invalid credentials'));
        }
      } catch (ex) {
        emit(AuthFailure(ex.toString()));
      }
    });

    // Logout
    on<LogoutRequested>((event, emit) async {
      emit(AuthUnauthenticated());
    });
  }
}
