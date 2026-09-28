import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
import '../core/mock/mock_data.dart';
import '../core/network/api_exception.dart';
import '../models/alert.dart';
import '../services/alert_service.dart';

/// Provides alert data, transparently choosing between the real API and mock
/// data. In mock mode, created alerts are kept in an in-memory list so the UI
/// behaves realistically during a demo.
class AlertRepository {
  AlertRepository(this._service);

  final AlertService _service;

  final List<Alert> _mockStore = MockData.alerts();

  Future<List<Alert>> getAlerts() async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return List.unmodifiable(_mockStore);
    }
    try {
      return await _service.fetchAll();
    } on NetworkException {
      if (AppConfig.fallbackToMockOnError) {
        debugPrint('[AlertRepository] API offline, using mock alerts.');
        return List.unmodifiable(_mockStore);
      }
      rethrow;
    }
  }

  Future<Alert> createAlert(Alert alert) async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      final created = Alert(
        id: '${_mockStore.length + 1}',
        title: alert.title,
        description: alert.description,
        severity: alert.severity,
        location: alert.location,
        createdAt: alert.createdAt,
      );
      _mockStore.insert(0, created);
      return created;
    }
    return _service.create(alert);
  }
}
