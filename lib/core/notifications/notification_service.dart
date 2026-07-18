import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/app_routes.dart';
import '../config/nav_key.dart';
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
    _listenBackgroundTap();
  }

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

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

  // Escucha toques en notificaciones cuando la app esta en background.
  static void _listenBackgroundTap() {
    FirebaseMessaging.onMessageOpenedApp.listen(_navigateFromMessage);
  }

  // Tap en notificacion local (foreground) — el payload es el data del mensaje
  // serializado como JSON por _showForegroundNotification.
  static void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      _navigateDefault();
      return;
    }
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _navigateFromData(data);
    } catch (_) {
      _navigateDefault();
    }
  }

  // Navega segun los datos del mensaje FCM.
  static void _navigateFromMessage(RemoteMessage message) {
    _navigateFromData(message.data);
  }

  static void _navigateFromData(Map<String, dynamic> data) {
    final ticketId = int.tryParse(data['ticket_id']?.toString() ?? '');
    if (ticketId != null) {
      appNavigatorKey.currentState?.pushNamed(
        AppRoutes.ticketDetail,
        arguments: ticketId,
      );
      return;
    }
    _navigateDefault();
  }

  // Destino por defecto: Mis pedidos.
  static void _navigateDefault() {
    appNavigatorKey.currentState?.pushNamed(AppRoutes.myOrders);
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title;
    final body = notification?.body;

    if (title == null && body == null) return;

    // Serializa el data del mensaje como payload para que _onLocalNotificationTap
    // pueda determinar a donde navegar cuando el usuario toca la notificacion.
    String? payload;
    try {
      if (message.data.isNotEmpty) payload = jsonEncode(message.data);
    } catch (_) {}

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
      payload: payload,
    );
  }
}
