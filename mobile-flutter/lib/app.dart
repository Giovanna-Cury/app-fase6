import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

/// Root widget: configures the [MaterialApp] (theme, title) and delegates the
/// initial screen decision to [AuthGate].
class SmartHasApp extends StatelessWidget {
  const SmartHasApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart HAS',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      home: const AuthGate(),
    );
  }
}

/// Decides whether to show the login screen or the home screen, and restores a
/// persisted session on startup.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<void> _bootstrap;

  @override
  void initState() {
    super.initState();
    _bootstrap = context.read<AuthProvider>().tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrap,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final auth = context.watch<AuthProvider>();
        return auth.isAuthenticated
            ? const HomeScreen()
            : const LoginScreen();
      },
    );
  }
}
