import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'providers/alert_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/sensor_provider.dart';
import 'providers/settings_provider.dart';
import 'repositories/alert_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/sensor_repository.dart';
import 'services/alert_service.dart';
import 'services/sensor_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Dependency wiring (composition root) ---------------------------------
  // A single ApiClient is shared by every service so the auth token set at
  // login is automatically used by all subsequent requests.
  final apiClient = ApiClient();

  final authRepository = AuthRepository(apiClient: apiClient);
  final sensorRepository = SensorRepository(SensorService(apiClient));
  final alertRepository = AlertRepository(AlertService(apiClient));

  runApp(
    MultiProvider(
      providers: [
        // Repository exposed directly for screens with local state (detalhe do sensor).
        Provider<SensorRepository>.value(value: sensorRepository),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
        ChangeNotifierProvider(create: (_) => SensorProvider(sensorRepository)),
        ChangeNotifierProvider(create: (_) => AlertProvider(alertRepository)),
      ],
      child: const SmartHasApp(),
    ),
  );
}
