import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../network/api_client.dart';
import '../storage/token_storage.dart';

class NotificationService {
  NotificationService._();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'eco_customer_channel',
        'Eco Customer Notifications',
        importance: Importance.high,
      );

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final TokenStorage _tokenStorage = TokenStorage();

  static Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _requestPermission();
    final token = await _printFcmToken();
    await registerCurrentTokenIfAuthenticated(token: token);
    _listenTokenRefresh();
    _listenForegroundMessages();
  }

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(settings: initializationSettings);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);
  }

  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('FCM PERMISSION: ${settings.authorizationStatus.name}');
  }

  static Future<String?> _printFcmToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('FCM TOKEN: ${token ?? 'No disponible'}');
      return token;
    } catch (error) {
      debugPrint('FCM TOKEN ERROR: $error');
      return null;
    }
  }

  static Future<void> registerCurrentTokenIfAuthenticated({
    String platform = 'android',
    String? token,
  }) async {
    try {
      final hasSession = await _tokenStorage.hasAccessToken();
      if (!hasSession) return;

      final fcmToken = token ?? await _messaging.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      await ApiClient.instance.dio.post<Map<String, dynamic>>(
        '/notifications/fcm-token/',
        data: {'token': fcmToken, 'platform': platform},
      );

      debugPrint('FCM TOKEN REGISTERED');
    } catch (error) {
      debugPrint('FCM TOKEN REGISTER ERROR: $error');
    }
  }

  static void _listenTokenRefresh() {
    _messaging.onTokenRefresh.listen((token) async {
      await registerCurrentTokenIfAuthenticated(token: token);
    });
  }

  static void _listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen((message) async {
      debugPrint(
        'FCM FOREGROUND MESSAGE: '
        'title=${message.notification?.title}, '
        'body=${message.notification?.body}, '
        'data=${message.data}',
      );
      await _showForegroundNotification(message);
    });
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title;
    final body = notification?.body;

    if (title == null && body == null) return;

    await _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: 'Notificaciones para clientes ECO.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
