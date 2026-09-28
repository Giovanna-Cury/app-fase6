import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../core/state/view_state.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';

/// Holds the authentication state of the app and exposes login/logout actions.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository);

  final AuthRepository _repository;

  ViewState _state = ViewState.idle;
  User? _user;
  String? _errorMessage;

  ViewState get state => _state;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _state == ViewState.loading;

  /// Tries to restore a persisted session at startup.
  Future<void> tryAutoLogin() async {
    final restored = await _repository.restoreSession();
    if (restored) {
      _user = _repository.currentUser();
      _state = ViewState.success;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.login(username.trim(), password);
      _user = response.user;
      _state = ViewState.success;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = ViewState.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Ocorreu um erro inesperado. Tente novamente.';
      _state = ViewState.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _user = null;
    _state = ViewState.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
