import 'package:flutter/material.dart';

import '../models/sensor.dart';

/// List item that displays a single [Sensor] with its status.
class SensorCard extends StatelessWidget {
  const SensorCard({super.key, required this.sensor, this.onTap});

  final Sensor sensor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: sensor.status.color.withValues(alpha: 0.15),
          child: Icon(sensor.status.icon, color: sensor.status.color),
        ),
        title: Text(
          sensor.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${sensor.type} • ${sensor.location}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              sensor.formattedValue,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              sensor.status.label,
              style: TextStyle(color: sensor.status.color, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
