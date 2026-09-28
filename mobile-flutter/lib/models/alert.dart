import 'package:flutter/material.dart';

/// How severe an alert is.
enum AlertSeverity {
  low,
  medium,
  high,
  critical;

  static AlertSeverity fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'LOW':
        return AlertSeverity.low;
      case 'MEDIUM':
        return AlertSeverity.medium;
      case 'HIGH':
        return AlertSeverity.high;
      case 'CRITICAL':
        return AlertSeverity.critical;
      default:
        return AlertSeverity.medium;
    }
  }

  String get label => switch (this) {
        AlertSeverity.low => 'Baixa',
        AlertSeverity.medium => 'Média',
        AlertSeverity.high => 'Alta',
        AlertSeverity.critical => 'Crítica',
      };

  Color get color => switch (this) {
        AlertSeverity.low => Colors.blue,
        AlertSeverity.medium => Colors.orange,
        AlertSeverity.high => Colors.deepOrange,
        AlertSeverity.critical => Colors.red,
      };

  IconData get icon => switch (this) {
        AlertSeverity.low => Icons.info_outline,
        AlertSeverity.medium => Icons.warning_amber_rounded,
        AlertSeverity.high => Icons.priority_high,
        AlertSeverity.critical => Icons.dangerous_outlined,
      };
}

/// An alert/occurrence raised by the monitoring system.
class Alert {
  const Alert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.location,
    required this.createdAt,
    this.resolved = false,
  });

  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final String location;
  final DateTime createdAt;
  final bool resolved;

  Alert copyWith({bool? resolved}) => Alert(
        id: id,
        title: title,
        description: description,
        severity: severity,
        location: location,
        createdAt: createdAt,
        resolved: resolved ?? this.resolved,
      );

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: '${json['id'] ?? ''}',
      title: json['title'] as String? ?? 'Alerta',
      description: json['description'] as String? ?? '',
      severity: AlertSeverity.fromString(json['severity'] as String?),
      location: json['location'] as String? ?? 'Local não informado',
      createdAt:
          DateTime.tryParse('${json['createdAt']}') ?? DateTime(2024),
      resolved: json['resolved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'severity': severity.name.toUpperCase(),
        'location': location,
        'createdAt': createdAt.toIso8601String(),
        'resolved': resolved,
      };
}
