// lib/api/firebase_api.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

// ── TOP-LEVEL BG HANDLER (must NOT be inside a class)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need Firebase here: await Firebase.initializeApp();
  // Minimal work only in background.
}

class FirebaseApi {
  final _messaging = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'garden_default_channel',
    'GardenCity Notifications',
    description: 'General notifications for scheduled tasks',
    importance: Importance.high,
  );

  Future<void> init() async {
    // Request permission (Android 13+/iOS)
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Local notifications init + Android channel
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(initSettings);

    await _local
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground messages → show a local notif
    FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      _local.show(
        message.hashCode,
        n?.title ?? (message.data['title'] as String? ?? 'GardenCity'),
        n?.body ?? (message.data['body'] as String? ?? ''),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: n?.android?.smallIcon, // falls back to launcher
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });

    // (Optional) taps when app was backgrounded
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // Navigator logic if you want
    });

    final token = await _messaging.getToken();
    debugPrint('FCM token: $token');
  }
}
