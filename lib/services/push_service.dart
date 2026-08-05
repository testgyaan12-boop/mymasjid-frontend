import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_client.dart';

class PushService {
  PushService._internal();
  static final PushService instance = PushService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  String? _token;

  Future<void> init() async {
    // Android notification channel used for foreground notifications
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(
      settings: const InitializationSettings(android: android),
    );

    // Channel
    final channel = AndroidNotificationChannel(
      'masjid_alerts',
      'Masjid Alerts',
      description: 'Notifications from your masjid',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Foreground handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocal(message);
    });

    // App opened from background notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleOpen(message);
    });

    // Tap on terminated app
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleOpen(initial);
    }

    // Request permission (Android 13+)
    await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );
  }

  Future<String?> getToken() async {
    _token = await _messaging.getToken();
    return _token;
  }

  Future<void> registerToken(int masjidId) async {
    try {
      final token = await getToken();
      if (token == null) return;
      await ApiClient().dio.post('/notifications/register', data: {
        'token': token,
        'masjidId': masjidId,
        'platform': Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'other'),
      });
    } catch (_) {
      // Token registration is best-effort; retried on next launch
    }
  }

  Future<void> unregisterToken() async {
    try {
      final token = await getToken();
      if (token == null) return;
      await ApiClient().dio.post('/notifications/unregister', data: {'token': token});
    } catch (_) {}
  }

  void _handleOpen(RemoteMessage message) {
    final type = message.data['type'];
    // deep link to alerts handled at call site via callback
    onOpen?.call(type);
  }

  Function(String? type)? onOpen;

  void _showLocal(RemoteMessage message) {
    final n = message.notification;
    _local.show(
      id: DateTime.now().millisecondsSinceEpoch,
      title: n?.title ?? 'Masjid Update',
      body: n?.body ?? '',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'masjid_alerts',
          'Masjid Alerts',
          channelDescription: 'Notifications from your masjid',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}