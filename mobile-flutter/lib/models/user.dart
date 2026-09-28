/// Represents an authenticated user of the Smart HAS platform.
class User {
  const User({
    required this.id,
    required this.name,
    required this.username,
    this.email,
    this.role = 'OPERATOR',
  });

  final String id;
  final String name;
  final String username;
  final String? email;
  final String role;

  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: '${json['id'] ?? ''}',
      name: json['name'] as String? ?? json['username'] as String? ?? 'Usuário',
      username: json['username'] as String? ?? '',
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'OPERATOR',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'email': email,
        'role': role,
      };
}
