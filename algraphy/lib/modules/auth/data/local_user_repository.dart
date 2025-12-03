

import 'package:algraphy/core/local/local_db_service.dart';
import 'package:algraphy/modules/auth/data/models/user_model.dart';

class LocalUserRepository {
  final LocalDbService db;
  static const String usersKey = 'users';

  LocalUserRepository(this.db);

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final users = await db.readJson(usersKey) as List<dynamic>? ?? [];

    // Check if user exists
    if (users.any((u) => u['email'] == email)) {
      throw Exception('Email already registered');
    }

    // Create user
    final user = UserModel(
      id: db.generateId(),
      name: name,
      email: email,
      password: password,
    );

    // Save to DB
    users.add(user.toMap());
    await db.writeJson(usersKey, users);

    return user; // ✅ return UserModel, not Map
  }

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    final users = await db.readJson(usersKey) as List<dynamic>? ?? [];

    final found = users.cast<Map<String, dynamic>>().firstWhere(
      (u) => u['email'] == email && u['password'] == password,
      orElse: () => {},
    );

    if (found.isEmpty) return null;

    return UserModel.fromMap(found);
  }
}
