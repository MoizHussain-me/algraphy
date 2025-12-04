import 'package:algraphy/core/local/local_db_service.dart';
import 'package:algraphy/modules/auth/data/models/user_model.dart';

class LocalUserRepository {
  final LocalDbService db;
  static const String usersKey = 'users';

  LocalUserRepository(this.db);

  /// Ensure default admin exists
  Future<void> ensureAdmin() async {
    final users = await _readAllUsers();

    final adminExists = users.any((u) => u['email'] == 'admin@algraphy.com');
    if (!adminExists) {
      final admin = UserModel(
        id: db.generateId(),
        email: 'admin@algraphy.com',
        password: 'admin123', // default password
        role: 'admin',
        mustChangePassword: false, // admin can keep default initially
        firstName: 'Admin',
        lastName: 'User',
      );

      users.add(admin.toMap());
      await db.writeJson(usersKey, users);
    }
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final users = await _readAllUsers();

    // Check if user exists
    if (users.any((u) => u['email'] == email)) {
      throw Exception('Email already registered');
    }

    final user = UserModel(
      id: db.generateId(),
      email: email,
      password: password,
      firstName: name,
    );

    users.add(user.toMap());
    await db.writeJson(usersKey, users);

    return user;
  }

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    final users = await _readAllUsers();

    final found = users.cast<Map<String, dynamic>>().firstWhere(
      (u) => u['email'] == email && u['password'] == password,
      orElse: () => {},
    );

    if (found.isEmpty) return null;

    return UserModel.fromMap(found);
  }

  Future<List<Map<String, dynamic>>> _readAllUsers() async {
    final raw = await db.readJson(usersKey);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(raw as List);
  }

  Future<UserModel> createEmployee({
    required String email,
    required String firstName,
    required String lastName,
  }) async {
    final users = await _readAllUsers();
    final id = db.generateId();

    final user = UserModel(
      id: id,
      email: email,
      password: "123456", // TEMP PASSWORD
      role: "employee",
      mustChangePassword: true,
      firstName: firstName,
      lastName: lastName,
    );

    users.add(user.toMap());
    await db.writeJson(usersKey, users);
    return user;
  }
}
