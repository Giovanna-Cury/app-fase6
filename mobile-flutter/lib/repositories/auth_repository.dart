import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/mock/mock_data.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/auth_response.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Coordinates authentication: talks to [AuthService] (or the mock), keeps the
/// [ApiClient] token in sync and persists it with [SharedPreferences] so the
/// session survives an app restart.
class AuthRepository {
  AuthRepository({required ApiClient apiClient, AuthService? authService})
      : _api = apiClient,
        _service = authService ?? AuthService(apiClient);

  final ApiClient _api;
  final AuthService _service;

  Future<AuthResponse> login(String username, String password) async {
    if (AppConfig.useMockData) {
      return _mockLogin(username, password);
    }
    try {
      final response = await _service.login(username, password);
      await _persistToken(response.token);
      _api.setAuthToken(response.token);
      return response;
    } on NetworkException {
      if (AppConfig.fallbackToMockOnError) {
        debugPrint('[AuthRepository] API offline, using mock login.');
        return _mockLogin(username, password);
      }
      rethrow;
    }
  }

  Future<AuthResponse> _mockLogin(String username, String password) async {
    await Future.delayed(AppConfig.mockLatency);
    final expected = MockData.credentials[username];
    if (expected == null || expected != password) {
      throw const UnauthorizedException('Usuário ou senha inválidos.');
    }
    const token = 'mock-token';
    await _persistToken(token);
    _api.setAuthToken(token);
    return const AuthResponse(token: token, user: MockData.adminUser);
  }

  /// Restores a previously saved token (if any). Returns `true` when a session
  /// was restored.
  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConfig.tokenStorageKey);
    if (token == null || token.isEmpty) return false;
    _api.setAuthToken(token);
    return true;
  }

  /// Returns the currently logged user. With a real API this could hit
  /// `GET /api/auth/me`; here we return the mock admin for a restored session.
  User currentUser() => MockData.adminUser;

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.tokenStorageKey);
    _api.setAuthToken(null);
  }

  Future<void> _persistToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.tokenStorageKey, token);
  }
}
