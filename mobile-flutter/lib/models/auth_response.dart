import 'user.dart';

/// Payload returned by `POST /api/auth/login`.
///
/// Expected JSON shape (produced by the Spring Boot back-end):
/// ```json
/// { "token": "<jwt>", "user": { "id": 1, "name": "...", "role": "ADMIN" } }
/// ```
class AuthResponse {
  const AuthResponse({required this.token, required this.user});

  final String token;
  final User user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String? ?? '',
      user: User.fromJson(
        (json['user'] as Map?)?.cast<String, dynamic>() ?? json,
      ),
    );
  }
}
