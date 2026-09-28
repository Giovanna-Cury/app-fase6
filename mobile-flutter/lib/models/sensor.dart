import 'package:flutter/material.dart';

/// Operational status of a monitoring sensor.
enum SensorStatus {
  online,
  warning,
  offline,
  unknown;

  static SensorStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'ONLINE':
      case 'OK':
        return SensorStatus.online;
      case 'WARNING':
      case 'ALERT':
        return SensorStatus.warning;
      case 'OFFLINE':
      case 'ERROR':
        return SensorStatus.offline;
      default:
        return SensorStatus.unknown;
    }
  }

  String get label => switch (this) {
        SensorStatus.online => 'Online',
        SensorStatus.warning => 'Atenção',
        SensorStatus.offline => 'Offline',
        SensorStatus.unknown => 'Desconhecido',
      };

  Color get color => switch (this) {
        SensorStatus.online => Colors.green,
        SensorStatus.warning => Colors.orange,
        SensorStatus.offline => Colors.red,
        SensorStatus.unknown => Colors.grey,
      };

  IconData get icon => switch (this) {
        SensorStatus.online => Icons.check_circle,
        SensorStatus.warning => Icons.warning_amber_rounded,
        SensorStatus.offline => Icons.error_outline,
        SensorStatus.unknown => Icons.help_outline,
      };
}

/// A physical/logical sensor monitored by Smart HAS.
class Sensor {
  const Sensor({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.location,
    this.value,
    this.unit,
    this.latitude,
    this.longitude,
    this.updatedAt,
    this.alertThreshold,
    this.criticalThreshold,
    this.responsibleName,
  });

  final String id;
  final String name;
  final String type;
  final SensorStatus status;
  final String location;
  final double? value;
  final String? unit;
  final double? latitude;
  final double? longitude;
  final DateTime? updatedAt;

  /// Thresholds used by the database to classify readings (Fase 6).
  final double? alertThreshold;
  final double? criticalThreshold;

  /// User responsible for the sensor maintenance.
  final String? responsibleName;

  /// Reading formatted for display, e.g. `24.5 °C`.
  String get formattedValue {
    if (value == null) return '--';
    final v = value! % 1 == 0 ? value!.toStringAsFixed(0) : value!.toStringAsFixed(1);
    return unit == null ? v : '$v $unit';
  }

  factory Sensor.fromJson(Map<String, dynamic> json) {
    return Sensor(
      id: '${json['id'] ?? ''}',
      name: json['name'] as String? ?? 'Sensor',
      type: json['type'] as String? ?? 'GENERIC',
      status: SensorStatus.fromString(json['status'] as String?),
      location: json['location'] as String? ?? 'Local não informado',
      value: (json['value'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse('${json['updatedAt']}')
          : null,
      alertThreshold: (json['alertThreshold'] as num?)?.toDouble(),
      criticalThreshold: (json['criticalThreshold'] as num?)?.toDouble(),
      responsibleName: json['responsibleName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'status': status.name.toUpperCase(),
        'location': location,
        'value': value,
        'unit': unit,
        'latitude': latitude,
        'longitude': longitude,
        'updatedAt': updatedAt?.toIso8601String(),
        'alertThreshold': alertThreshold,
        'criticalThreshold': criticalThreshold,
        'responsibleName': responsibleName,
      };
}
