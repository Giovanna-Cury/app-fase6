import '../../models/alert.dart';
import '../../models/sensor.dart';
import '../../models/telemetry.dart';
import '../../models/user.dart';

/// In-memory sample data used when [AppConfig.useMockData] is enabled or when a
/// real API call fails and fallback is allowed. It mirrors the exact shape the
/// Spring Boot API is expected to return.
class MockData {
  const MockData._();

  static const User adminUser = User(
    id: '1',
    name: 'Administrador',
    username: 'admin',
    email: 'admin@smarthas.com',
    role: 'ADMIN',
  );

  /// Credentials accepted by the mock auth service.
  static const Map<String, String> credentials = {'admin': '1234'};

  static List<Sensor> sensors() => [
        Sensor(
          id: '1',
          name: 'Sensor 01',
          type: 'Temperatura',
          status: SensorStatus.online,
          location: 'Centro de São Paulo',
          value: 24.5,
          unit: '°C',
          latitude: -23.5505,
          longitude: -46.6333,
          updatedAt: DateTime(2026, 8, 23, 9, 12),
          alertThreshold: 30,
          criticalThreshold: 35,
          responsibleName: 'Operador',
        ),
        Sensor(
          id: '2',
          name: 'Sensor 02',
          type: 'Nível de água',
          status: SensorStatus.offline,
          location: 'Marginal Tietê',
          value: 87,
          unit: '%',
          latitude: -23.5170,
          longitude: -46.6200,
          updatedAt: DateTime(2026, 8, 23, 8, 40),
          alertThreshold: 70,
          criticalThreshold: 90,
          responsibleName: 'Equipe de Campo',
        ),
        Sensor(
          id: '3',
          name: 'Sensor 03',
          type: 'Qualidade do ar',
          status: SensorStatus.warning,
          location: 'Av. Paulista',
          value: 68,
          unit: 'AQI',
          latitude: -23.5614,
          longitude: -46.6558,
          updatedAt: DateTime(2026, 8, 23, 9, 5),
          alertThreshold: 80,
          criticalThreshold: 150,
          responsibleName: 'Operador',
        ),
        Sensor(
          id: '4',
          name: 'Sensor 04',
          type: 'Umidade',
          status: SensorStatus.online,
          location: 'Parque Ibirapuera',
          value: 55,
          unit: '%',
          latitude: -23.5874,
          longitude: -46.6576,
          updatedAt: DateTime(2026, 8, 23, 9, 10),
          alertThreshold: 85,
          criticalThreshold: 95,
          responsibleName: 'Operador',
        ),
      ];

  static List<Alert> alerts() => [
        Alert(
          id: '1',
          title: 'Área de risco detectada',
          description: 'Movimentação anômala identificada pela camada de IA.',
          severity: AlertSeverity.critical,
          location: 'Centro de São Paulo',
          createdAt: DateTime(2026, 8, 23, 9, 12),
        ),
        Alert(
          id: '2',
          title: 'Sensor offline',
          description: 'O sensor #02 parou de reportar leituras.',
          severity: AlertSeverity.high,
          location: 'Marginal Tietê',
          createdAt: DateTime(2026, 8, 23, 8, 41),
        ),
        Alert(
          id: '3',
          title: 'Nível elevado de água',
          description: 'Leitura acima do limite seguro para a região.',
          severity: AlertSeverity.medium,
          location: 'Marginal Tietê',
          createdAt: DateTime(2026, 8, 23, 8, 30),
        ),
      ];

  // ---------------------------------------------------------------------------
  // Telemetria offline (Fase 6): espelha o formato de /readings e /indicators.
  // ---------------------------------------------------------------------------

  /// 24 hourly readings, newest first, derived deterministically from the
  /// sensor's current value.
  static List<SensorReading> readings(Sensor sensor) {
    final base = sensor.value ?? 0;
    final now = DateTime.now();
    return List.generate(24, (i) {
      final wave = ((i * 7) % 11 - 5) / 100; // -5% .. +5%
      final value = double.parse((base * (1 + wave)).toStringAsFixed(2));
      return SensorReading(
        id: '${sensor.id}${24 - i}',
        value: value,
        classification: ReadingClassification.of(
            value, sensor.alertThreshold, sensor.criticalThreshold),
        readAt: now.subtract(Duration(hours: i)),
      );
    });
  }

  static SensorIndicators indicators(Sensor sensor) {
    final history = readings(sensor);
    final normal = history
        .where((r) => r.classification == ReadingClassification.normal)
        .length;
    final conformity =
        double.parse((normal * 100 / history.length).toStringAsFixed(2));
    final risk = switch (sensor.status) {
      SensorStatus.offline => 15,
      SensorStatus.warning => 10,
      _ => 0,
    };
    final last = history.first;
    return SensorIndicators(
      conformity24h: conformity,
      conformity7d: conformity,
      riskIndex: risk,
      formattedLastReading: '${sensor.name} (${sensor.type}) | '
          '${last.value.toStringAsFixed(2).replaceAll('.', ',')} '
          '${sensor.unit ?? ''} | ${last.classification.name.toUpperCase()}',
      engine: 'MOCK',
    );
  }

  static int _mockAlertSequence = 100;

  static ReadingRegistration registerReading(Sensor sensor, double value) {
    final classification = ReadingClassification.of(
        value, sensor.alertThreshold, sensor.criticalThreshold);
    return ReadingRegistration(
      readingId: '${DateTime.now().millisecondsSinceEpoch}',
      classification: classification,
      alertId: classification == ReadingClassification.normal
          ? null
          : '${_mockAlertSequence++}',
    );
  }
}
