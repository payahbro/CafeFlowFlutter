import 'dart:convert';

import 'package:cafe/core/notifications/product_notification_payload.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AppNotificationService {
  AppNotificationService._();

  static final AppNotificationService instance = AppNotificationService._();

  static const _androidChannel = AndroidNotificationChannel(
    'product_updates',
    'Product updates',
    description: 'Notifications for newly added products.',
    importance: Importance.high,
  );

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  ValueChanged<ProductNotificationPayload>? _onProductCreatedTap;
  bool _initialized = false;

  Future<void> initialize({
    ValueChanged<ProductNotificationPayload>? onProductCreatedTap,
  }) async {
    _onProductCreatedTap = onProductCreatedTap;
    if (_initialized) {
      return;
    }
    _initialized = true;

    await _initializeLocalNotifications();
    await _requestPermission();
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: true,
    );
    await _messaging.subscribeToTopic(ProductNotificationPayload.topic);

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleOpenedMessage(initialMessage);
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final productPayload = ProductNotificationPayload.fromData(message.data);
    if (productPayload == null) {
      return;
    }

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: message.notification?.title ?? 'Produk baru tersedia',
      body:
          message.notification?.body ??
          '${productPayload.name} sudah tersedia.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'product_updates',
          'Product updates',
          channelDescription: 'Notifications for newly added products.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleOpenedMessage(RemoteMessage message) {
    final productPayload = ProductNotificationPayload.fromData(message.data);
    if (productPayload == null) {
      return;
    }
    _onProductCreatedTap?.call(productPayload);
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      return;
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(payload);
    } on FormatException {
      return;
    }
    if (decoded is! Map<String, dynamic>) {
      return;
    }

    final productPayload = ProductNotificationPayload.fromData(decoded);
    if (productPayload == null) {
      return;
    }
    _onProductCreatedTap?.call(productPayload);
  }
}
