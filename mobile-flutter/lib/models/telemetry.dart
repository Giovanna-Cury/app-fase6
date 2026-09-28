import 'package:flutter/material.dart';

/// Classification of a reading against the sensor thresholds.
///
/// Computed in the database by `FN_CLASSIFICAR_LEITURA` (Oracle PL/SQL) and
/// returned by the API as `NORMAL`, `ALERTA` or `CRITICA`.
enum ReadingClassification {
  normal,
  alerta,
  critica;

  static ReadingClassification fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'CRITICA':
        return ReadingClassification.critica;
      case 'ALERTA':
        return ReadingClassification.alerta;
      default:
        return ReadingClassification.normal;
    }
  }

  /// Same rule as the PL/SQL function; used only by the offline mock.
  static ReadingClassification of(
      double value, double? alertThreshold, double? criticalThreshold) {
    if (criticalThreshold != null && value >= criticalThreshold) {
      return ReadingClassification.critica;
    }
    if (alertThreshold != null && value >= alertThreshold) {
      return ReadingClassification.alerta;
    }
    return ReadingClassification.normal;
  }

  String get label => switch (this) {
        ReadingClassification.normal => 'Normal',
        ReadingClassification.alerta => 'Alerta',
        ReadingClassification.critica => 'Crítica',
      };

  Color get color => switch (this) {
        ReadingClassification.normal => Colors.green,
        ReadingClassification.alerta => Colors.orange,
        ReadingClassification.critica => Colors.red,
      };
}

/// One entry of the sensor telemetry history (`GET /sensors/{id}/readings`).
class SensorReading {
  const SensorReading({
    required this.id,
    required this.value,
    required this.classification,
    required this.readAt,
  });

  final String id;
  final double value;
  final ReadingClassification classification;
  final DateTime readAt;

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      id: '${json['id'] ?? ''}',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      classification:
          ReadingClassification.fromString(json['classification'] as String?),
      readAt: DateTime.tryParse('${json['readAt']}') ?? DateTime.now(),
    );
  }
}

/// Indicators calculated by the PL/SQL functions
/// (`GET /sensors/{id}/indicators`).
class SensorIndicators {
  const SensorIndicators({
    this.conformity24h,
    this.conformity7d,
    required this.riskIndex,
    required this.formattedLastReading,
    required this.engine,
  });

  /// `FN_CALC_CONFORMIDADE` — % of normal readings; null when there is no data.
  final double? conformity24h;
  final double? conformity7d;

  /// `FN_CALC_INDICE_RISCO` — 0..100 for the sensor location.
  final int riskIndex;

  /// `FN_FORMATAR_LEITURA`.
  final String formattedLastReading;

  /// `ORACLE_PLSQL`, `JPA` (API without Oracle) or `MOCK` (offline app).
  final String engine;

  String get riskLevel {
    if (riskIndex >= 50) return 'Alto';
    if (riskIndex >= 20) return 'Moderado';
    return 'Baixo';
  }

  String get engineLabel => switch (engine) {
        'ORACLE_PLSQL' => 'Calculado no Oracle (PL/SQL)',
        'JPA' => 'Calculado pela API (modo local)',
        _ => 'Modo demonstração (offline)',
      };

  factory SensorIndicators.fromJson(Map<String, dynamic> json) {
    return SensorIndicators(
      conformity24h: (json['conformity24h'] as num?)?.toDouble(),
      conformity7d: (json['conformity7d'] as num?)?.toDouble(),
      riskIndex: (json['riskIndex'] as num?)?.toInt() ?? 0,
      formattedLastReading: json['formattedLastReading'] as String? ?? '',
      engine: json['engine'] as String? ?? 'MOCK',
    );
  }
}

/// Result of `POST /sensors/{id}/readings` (OUT parameters of
/// `PRC_REGISTRAR_LEITURA`).
class ReadingRegistration {
  const ReadingRegistration({
    required this.readingId,
    required this.classification,
    this.alertId,
  });

  final String readingId;
  final ReadingClassification classification;

  /// Alert created, escalated or reused by the procedure (null when NORMAL).
  final String? alertId;

  factory ReadingRegistration.fromJson(Map<String, dynamic> json) {
    return ReadingRegistration(
      readingId: '${json['readingId'] ?? ''}',
      classification:
          ReadingClassification.fromString(json['classification'] as String?),
      alertId: json['alertId'] == null ? null : '${json['alertId']}',
    );
  }
}
