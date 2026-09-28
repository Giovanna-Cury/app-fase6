import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/state/view_state.dart';
import '../providers/alert_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/sensor_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/sensor_card.dart';
import '../widgets/stat_card.dart';
import 'alert_screen.dart';
import 'map_screen.dart';
import 'sensor_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load data after the first frame so context is fully available.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    await Future.wait([
      context.read<SensorProvider>().load(),
      context.read<AlertProvider>().load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart HAS'),
        actions: [
          IconButton(
            tooltip: 'Alternar tema',
            icon: Icon(settings.isDark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
            onPressed: () => context.read<SettingsProvider>().toggleTheme(),
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Olá, ${auth.user?.name ?? 'Operador'} 👋',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Painel de monitoramento em tempo real',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            const _StatsSection(),
            const SizedBox(height: 20),
            _QuickActions(
              onAlerts: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AlertScreen()),
              ),
              onMap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapScreen()),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sensores',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const _SensorsSection(),
          ],
        ),
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context) {
    final sensors = context.watch<SensorProvider>();
    final alerts = context.watch<AlertProvider>();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        StatCard(
          icon: Icons.sensors,
          value: '${sensors.onlineCount}/${sensors.total}',
          label: 'Sensores online',
          color: Colors.green,
        ),
        StatCard(
          icon: Icons.warning_amber_rounded,
          value: '${alerts.activeCount}',
          label: 'Alertas ativos',
          color: Colors.red,
        ),
        StatCard(
          icon: Icons.error_outline,
          value: '${sensors.offlineCount}',
          label: 'Sensores offline',
          color: Colors.orange,
        ),
        StatCard(
          icon: Icons.location_on_outlined,
          value: '${sensors.total}',
          label: 'Pontos monitorados',
          color: Colors.blue,
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onAlerts, required this.onMap});

  final VoidCallback onAlerts;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onAlerts,
            icon: const Icon(Icons.warning_amber_rounded),
            label: const Text('Alertas'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onMap,
            icon: const Icon(Icons.map_outlined),
            label: const Text('Mapa'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _SensorsSection extends StatelessWidget {
  const _SensorsSection();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SensorProvider>();

    switch (provider.state) {
      case ViewState.loading:
      case ViewState.idle:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: LoadingView(message: 'Carregando sensores...'),
        );
      case ViewState.error:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: ErrorView(
            message: provider.errorMessage ?? 'Erro ao carregar sensores.',
            onRetry: () => context.read<SensorProvider>().load(),
          ),
        );
      case ViewState.success:
        return Column(
          children: provider.sensors
              .map((s) => SensorCard(
                    sensor: s,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SensorDetailScreen(sensor: s),
                      ),
                    ),
                  ))
              .toList(),
        );
    }
  }
}
