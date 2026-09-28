import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
import '../core/mock/mock_data.dart';
import '../core/network/api_exception.dart';
import '../models/sensor.dart';
import '../models/telemetry.dart';
import '../services/sensor_service.dart';

/// Provides sensor data, transparently choosing between the real API and mock
/// data (and falling back to mock if the back-end is unreachable).
class SensorRepository {
  SensorRepository(this._service);

  final SensorService _service;

  Future<List<Sensor>> getSensors() =>
      _withFallback(_service.fetchAll, MockData.sensors, 'sensors');

  /// Telemetry history (newest first).
  Future<List<SensorReading>> getReadings(Sensor sensor) => _withFallback(
      () => _service.fetchReadings(sensor.id),
      () => MockData.readings(sensor),
      'readings');

  /// Indicators computed by the Oracle functions (conformity, risk, format).
  Future<SensorIndicators> getIndicators(Sensor sensor) => _withFallback(
      () => _service.fetchIndicators(sensor.id),
      () => MockData.indicators(sensor),
      'indicators');

  /// Sends a reading; on the API this runs PRC_REGISTRAR_LEITURA in Oracle.
  Future<ReadingRegistration> registerReading(Sensor sensor, double value) =>
      _withFallback(
          () => _service.registerReading(sensor.id, value),
          () => MockData.registerReading(sensor, value),
          'registerReading');

  /// Single place for the mock / offline-fallback policy of this repository.
  Future<T> _withFallback<T>(
    Future<T> Function() remote,
    T Function() mock,
    String operation,
  ) async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return mock();
    }
    try {
      return await remote();
    } on NetworkException {
      if (AppConfig.fallbackToMockOnError) {
        debugPrint('[SensorRepository] API offline, using mock $operation.');
        return mock();
      }
      rethrow;
    }
  }
}
