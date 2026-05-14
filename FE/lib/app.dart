// lib/app.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/providers/auth_provider.dart';
import 'core/providers/session_provider.dart';
import 'features/admin/presentation/screens/splash_gate.dart';
import 'features/admin/presentation/screens/login_screen.dart' as features_login;
import 'core/services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class EmployeeSystemApp extends StatelessWidget {
  const EmployeeSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _handleUserInteraction(context),
      onPointerMove: (_) => _handleUserInteraction(context),
      onPointerUp: (_) => _handleUserInteraction(context),
      child: const _LifecycleWatcher(
        child: _AppContent(),
      ),
    );
  }

  void _handleUserInteraction(BuildContext context) {
    try {
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
      if (Provider.of<AuthProvider>(context, listen: false).isAuthenticated) {
        sessionProvider.resetTimer();
      }
    } catch (_) {}
  }
}

class _AppContent extends StatelessWidget {
  const _AppContent();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Employee System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4D64F5),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      builder: (context, child) {
        return Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return Stack(
              children: [
                if (child != null) child,
                if (auth.isSessionLocked)
                  Positioned.fill(
                    key: const ValueKey('lock_screen_overlay'),
                    child: PopScope(
                      canPop: false,
                      child: Navigator(
                        key: const ValueKey('lock_screen_navigator'),
                        onGenerateRoute: (settings) => MaterialPageRoute(
                          builder: (context) => features_login.LoginScreen(
                            key: const ValueKey('login_pin_only'),
                            pinOnlyMode: true,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
      home: const SplashGate(),
    );
  }
}

class _LifecycleWatcher extends StatefulWidget {
  final Widget child;
  const _LifecycleWatcher({required this.child});

  @override
  State<_LifecycleWatcher> createState() => _LifecycleWatcherState();
}

class _LifecycleWatcherState extends State<_LifecycleWatcher> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Inisialisasi notifikasi (minta izin, token, dll)
    NotificationService.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("DEBUG: _LifecycleWatcher received state: $state");
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    sessionProvider.handleAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}