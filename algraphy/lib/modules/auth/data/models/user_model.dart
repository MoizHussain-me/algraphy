class UserModel {
  final String id;
  final String name;
  final String email;
  final String password; // plain for demo only — do NOT store plain in production

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
  });

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
        id: m['id'] as String,
        name: m['name'] as String,
        email: m['email'] as String,
        password: m['password'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
      };
}
