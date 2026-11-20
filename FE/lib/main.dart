// lib/main.dart

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/session_provider.dart';
import 'core/providers/notification_provider.dart';
import 'firebase_options.dart';

// Bypass SSL certificate check (mencegah CERTIFICATE_VERIFY_FAILED saat development)
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await initializeDateFormatting('id', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, SessionProvider>(
          create: (context) => SessionProvider(
            authProvider: Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) {
            return previous ?? SessionProvider(authProvider: auth);
          },
        ),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const EmployeeSystemApp(),
    ),
  );
}
