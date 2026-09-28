import '../core/network/api_client.dart';
import '../models/auth_response.dart';

/// Talks to the authentication endpoints of the Spring Boot API.
///
/// Endpoint: `POST /api/auth/login` with body `{ "username", "password" }`.
class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  Future<AuthResponse> login(String username, String password) async {
    final data = await _api.post(
      '/auth/login',
      body: {'username': username, 'password': password},
    );
    return AuthResponse.fromJson((data as Map).cast<String, dynamic>());
  }
}
