import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sensor.dart';
import '../providers/sensor_provider.dart';
import '../widgets/loading_view.dart';

/// Stylized monitoring map. It plots each sensor by projecting its
/// latitude/longitude onto the panel, coloring the marker by status.
///
/// A real Google Maps integration is documented in the project roadmap; this
/// self-contained view keeps the app runnable with zero external API keys.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<SensorProvider>();
    if (provider.sensors.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => provider.load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SensorProvider>();
    final sensors = provider.sensors;

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa Inteligente')),
      body: provider.isLoading && sensors.isEmpty
          ? const LoadingView(message: 'Carregando mapa...')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _MapPanel(sensors: sensors),
                const SizedBox(height: 16),
                const _Legend(),
                const SizedBox(height: 16),
                Text(
                  'Status dos sensores',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...sensors.map((s) => Card(
                      child: ListTile(
                        leading: Icon(s.status.icon, color: s.status.color),
                        title: Text(s.name),
                        subtitle: Text(s.location),
                        trailing: Text(
                          s.status.label,
                          style: TextStyle(color: s.status.color),
                        ),
                      ),
                    )),
              ],
            ),
    );
  }
}

class _MapPanel extends StatelessWidget {
  const _MapPanel({required this.sensors});

  final List<Sensor> sensors;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const height = 320.0;
        final width = constraints.maxWidth;

        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade900,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  Icons.public,
                  size: 180,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              const Positioned(
                top: 16,
                left: 16,
                child: Text(
                  'REGIÃO MONITORADA',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              ..._buildMarkers(width, height),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Tempo real',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildMarkers(double width, double height) {
    final located =
        sensors.where((s) => s.latitude != null && s.longitude != null).toList();
    if (located.isEmpty) return [];

    // Compute bounding box to normalize coordinates into the panel area.
    final lats = located.map((s) => s.latitude!);
    final lngs = located.map((s) => s.longitude!);
    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLng = lngs.reduce((a, b) => a < b ? a : b);
    final maxLng = lngs.reduce((a, b) => a > b ? a : b);

    const pad = 40.0;

    // Fraction 0..1 of where a value sits within its range (0.5 if flat).
    double frac(double v, double min, double max) =>
        max == min ? 0.5 : (v - min) / (max - min);

    return located.map((s) {
      // Longitude grows to the east -> left to right.
      final left = pad + frac(s.longitude!, minLng, maxLng) * (width - 2 * pad);
      // Latitude grows to the north, but screen Y grows downward -> invert.
      final top =
          pad + (1 - frac(s.latitude!, minLat, maxLat)) * (height - 2 * pad);
      return Positioned(
        left: left - 20,
        top: top - 40,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, color: s.status.color, size: 40),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                s.name,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: c, size: 12),
            const SizedBox(width: 6),
            Text(label),
          ],
        );

    return Wrap(
      spacing: 20,
      runSpacing: 8,
      children: [
        item(Colors.green, 'Online'),
        item(Colors.orange, 'Atenção'),
        item(Colors.red, 'Offline'),
      ],
    );
  }
}
