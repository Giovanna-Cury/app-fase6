import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../core/state/view_state.dart';
import '../models/alert.dart';
import '../repositories/alert_repository.dart';

/// Exposes the list of alerts and the action to create a new one.
class AlertProvider extends ChangeNotifier {
  AlertProvider(this._repository);

  final AlertRepository _repository;

  ViewState _state = ViewState.idle;
  List<Alert> _alerts = [];
  String? _errorMessage;

  ViewState get state => _state;
  List<Alert> get alerts => List.unmodifiable(_alerts);
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == ViewState.loading;
  int get activeCount => _alerts.where((a) => !a.resolved).length;

  Future<void> load() async {
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _alerts = await _repository.getAlerts();
      _state = ViewState.success;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = ViewState.error;
    } catch (_) {
      _errorMessage = 'Não foi possível carregar os alertas.';
      _state = ViewState.error;
    }
    notifyListeners();
  }

  /// Creates an alert and refreshes the list. Returns `true` on success.
  Future<bool> createAlert(Alert alert) async {
    try {
      await _repository.createAlert(alert);
      await load();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}
