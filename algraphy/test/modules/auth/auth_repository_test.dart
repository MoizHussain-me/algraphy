import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:algraphy/modules/auth/data/auth_repository.dart';
import 'package:algraphy/core/api/api_client.dart';
import 'package:algraphy/modules/auth/data/models/user_model.dart';
import 'package:algraphy/core/utils/constants.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late AuthRepository authRepository;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    authRepository = AuthRepository(api: mockApiClient);
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthRepository', () {
    test('login returns UserModel on success and saves session', () async {
      // Arrange
      final email = 'test@example.com';
      final password = 'password';
      final mockUserMap = {
        'id': 1,
        'email': email,
        'first_name': 'Test',
        'last_name': 'User',
        'employee_code': 'EMP001',
        'role': 'Employee',
        'must_change_password': 0,
        'department': 'IT',
        'designation': 'Developer',
        'joining_date': '2023-01-01',
        'status': 'Active'
      };
      final mockResponse = {
        'status': 'success',
        'user': mockUserMap,
        'token': 'test_token'
      };

      when(() => mockApiClient.post('login', any())).thenAnswer((_) async => mockResponse);

      // Act
      final user = await authRepository.login(email, password);

      // Assert
      expect(user.email, email);
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppConstants.tokenKey), 'test_token');
      final userJson = prefs.getString(AppConstants.userKey);
      expect(userJson, contains('Test'));
      expect(userJson, contains('User'));
    });

    test('login throws exception on failure', () async {
      // Arrange
      when(() => mockApiClient.post('login', any())).thenAnswer((_) async => {'status': 'error', 'message': 'Invalid credentials'});

      // Act & Assert
      expect(() => authRepository.login('email', 'password'), throwsException);
    });

    test('logout clears session', () async {
      // Arrange
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, 'token');
      await prefs.setString(AppConstants.userKey, 'user');

      // Act
      await authRepository.logout();

      // Assert
      expect(prefs.getString(AppConstants.tokenKey), null);
      expect(prefs.getString(AppConstants.userKey), null);
    });
  });
}
