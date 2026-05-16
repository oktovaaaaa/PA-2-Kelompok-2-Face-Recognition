import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id (harus sama dengan AndroidManifest.xml)
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.max,
  );

  static Future<void> initialize() async {
    // 1. Setup Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _localNotifications.initialize(settings: initializationSettings);

    // 2. Create the Android Notification Channel explicitly
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Request permissions for FCM
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 4. Update FCM config for foreground notifications (Apple mainly, but good practice)
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    print('FCM Permissions checked. Syncing token...');
    try {
      await _fcm.deleteToken();
      print('Old token deleted to force refresh');
    } catch (e) {
      print('Failed to delete token: $e');
    }
    await syncToken();

    // 5. Handle pesan saat aplikasi di foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foregound Message received: ${message.notification?.title}");
      
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // Jika pesan masuk dan memiliki notifikasi + platform android, munculkan Local Notification!
      if (notification != null && android != null) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/launcher_icon',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // 6. Handle saat notifikasi di klik dan aplikasi terbuka dari background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notification clicked! Data: ${message.data}");
    });
  }

  static Future<void> syncToken() async {
    try {
      final token = await _fcm.getToken();
      final sessionToken = await SessionStorage.getToken();
      
      if (token != null && sessionToken != null) {
        print("Syncing FCM Token: $token");
        await ApiClient.put('/api/profile/fcm-token', {'fcm_token': token});
      }
    } catch (e) {
      print("Error syncing FCM token: $e");
    }
  }

  static Future<String?> getToken() async {
    return await _fcm.getToken();
  }
}
