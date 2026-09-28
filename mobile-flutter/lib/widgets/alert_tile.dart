import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/alert.dart';

/// List item that displays a single [Alert] with severity and timestamp.
class AlertTile extends StatelessWidget {
  const AlertTile({super.key, required this.alert});

  final Alert alert;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('dd/MM • HH:mm').format(alert.createdAt);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: alert.severity.color.withValues(alpha: 0.15),
          child: Icon(alert.severity.icon, color: alert.severity.color),
        ),
        title: Text(
          alert.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (alert.description.isNotEmpty) Text(alert.description),
            const SizedBox(height: 4),
            Text(
              '${alert.location} • $dateLabel',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: _SeverityPill(severity: alert.severity),
        isThreeLine: alert.description.isNotEmpty,
      ),
    );
  }
}

class _SeverityPill extends StatelessWidget {
  const _SeverityPill({required this.severity});

  final AlertSeverity severity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: severity.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        severity.label,
        style: TextStyle(
          color: severity.color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
