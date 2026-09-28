// Smoke tests for the Smart HAS app.
//
// Run with: flutter test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fasequatrog/models/alert.dart';
import 'package:fasequatrog/models/sensor.dart';
import 'package:fasequatrog/models/telemetry.dart';
import 'package:fasequatrog/widgets/sensor_card.dart';

void main() {
  group('Model parsing', () {
    test('Sensor.fromJson maps status and value correctly', () {
      final sensor = Sensor.fromJson({
        'id': 1,
        'name': 'Sensor Teste',
        'type': 'Temperatura',
        'status': 'ONLINE',
        'location': 'São Paulo',
        'value': 24.5,
        'unit': '°C',
      });

      expect(sensor.name, 'Sensor Teste');
      expect(sensor.status, SensorStatus.online);
      expect(sensor.formattedValue, '24.5 °C');
    });

    test('Telemetry models parse the Fase 6 API contract', () {
      final indicators = SensorIndicators.fromJson({
        'sensorId': 3,
        'conformity24h': 66.67,
        'conformity7d': null,
        'riskIndex': 50,
        'formattedLastReading': 'Sensor 03 (Qualidade do Ar) | 162,40 AQI | CRITICA',
        'engine': 'ORACLE_PLSQL',
      });
      final registration = ReadingRegistration.fromJson(
          {'readingId': 10, 'classification': 'CRITICA', 'alertId': 43});

      expect(indicators.conformity7d, isNull);
      expect(indicators.riskLevel, 'Alto');
      expect(registration.classification, ReadingClassification.critica);
      expect(registration.alertId, '43');
      expect(ReadingClassification.of(31, 30, 35), ReadingClassification.alerta);
    });

    test('Alert.fromJson defaults severity to medium when unknown', () {
      final alert = Alert.fromJson({
        'id': 9,
        'title': 'Teste',
        'severity': 'INEXISTENTE',
        'location': 'SP',
      });

      expect(alert.severity, AlertSeverity.medium);
      expect(alert.title, 'Teste');
    });
  });

  testWidgets('SensorCard renders sensor name and status label',
      (WidgetTester tester) async {
    const sensor = Sensor(
      id: '1',
      name: 'Sensor 01',
      type: 'Temperatura',
      status: SensorStatus.online,
      location: 'São Paulo',
      value: 24.5,
      unit: '°C',
    );

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SensorCard(sensor: sensor))),
    );

    expect(find.text('Sensor 01'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('24.5 °C'), findsOneWidget);
  });
}
