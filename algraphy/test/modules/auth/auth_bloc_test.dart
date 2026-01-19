import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:algraphy/modules/auth/presentation/bloc/auth_bloc.dart';
import 'package:algraphy/modules/auth/presentation/bloc/auth_event.dart';
import 'package:algraphy/modules/auth/presentation/bloc/auth_state.dart';
import 'package:algraphy/modules/auth/data/auth_repository.dart';
import 'package:algraphy/modules/auth/data/models/user_model.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockRepo;
  
  final testUser = UserModel(
    id: '1',
    email: 'test@example.com',
    password: 'password',
    firstName: 'Test',
    lastName: 'User',
    employeeCode: 'EMP001',
    role: 'Employee',
    mustChangePassword: false,
    department: 'IT',
    designation: 'Dev',
    dateOfJoining: '2023-01-01',
    employeeStatus: 'Active'
  );

  setUp(() {
    mockRepo = MockAuthRepository();
    authBloc = AuthBloc(mockRepo);
  });

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, isA<AuthInitial>());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when LoginRequested is successful',
      build: () {
        when(() => mockRepo.login(any(), any())).thenAnswer((_) async => testUser);
        return authBloc;
      },
      act: (bloc) => bloc.add(LoginRequested('test@example.com', 'password')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>().having((state) => state.user.email, 'email', 'test@example.com'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] when LoginRequested fails',
      build: () {
        when(() => mockRepo.login(any(), any())).thenThrow(Exception('Login failed'));
        return authBloc;
      },
      act: (bloc) => bloc.add(LoginRequested('test@example.com', 'password')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthFailure>().having((state) => state.message, 'message', contains('Login failed')),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when LogoutRequested is added',
      build: () {
        when(() => mockRepo.logout()).thenAnswer((_) async {});
        return authBloc;
      },
      act: (bloc) => bloc.add(LogoutRequested()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthUnauthenticated>(),
      ],
    );
  });
}
