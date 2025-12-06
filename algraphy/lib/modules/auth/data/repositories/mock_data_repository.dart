import '../models/user_model.dart';

class MockAuthRepository {
  // Hardcoded DB
  final List<UserModel> _users = [
    UserModel(
      id: "1",
      email: "admin@algraphy.com",
      password: "123",
      role: "admin",
      firstName: "Super",
      lastName: "Admin",
      designation: "System Owner",
      mustChangePassword: false,
    ),
    UserModel(
      id: "2",
      email: "emp@algraphy.com",
      password: "123",
      role: "employee",
      firstName: "John",
      lastName: "Doe",
      designation: "Flutter Dev",
      mustChangePassword: true, // Test force password change later
    ),
  ];

  Future<UserModel?> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    try {
      return _users.firstWhere(
        (u) => u.email == email && u.password == password,
      );
    } catch (e) {
      return null; // User not found
    }
  }

  Future<void> createEmployee(UserModel newUser) async {
    await Future.delayed(const Duration(seconds: 1));
    _users.add(newUser);
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}