import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../config/app_config.dart';

// Background message handler — ต้องอยู่ top-level
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _localNotif = FlutterLocalNotificationsPlugin();

  static const _channelId   = 'chat_channel';
  static const _channelName = 'ข้อความแชท';

  /// Set true when ChatScreen is active — suppresses foreground notifications
  bool isChatOpen = false;

  Future<void> init(BuildContext context) async {
    // ขอ permission
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Setup local notification channel (Android)
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
      playSound: true,
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Init plugin
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (res) {
        if (!context.mounted) return;
        if (res.payload == 'order_approved') {
          context.go('/home');
        } else {
          context.push('/chat');
        }
      },
    );

    // Foreground: แสดง local notification
    FirebaseMessaging.onMessage.listen((msg) => _showLocal(msg));

    // Background tap
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      if (!context.mounted) return;
      if (msg.data['type'] == 'order_approved') {
        context.go('/home');
      } else {
        context.push('/chat');
      }
    });
  }

  void _showLocal(RemoteMessage msg) {
    if (isChatOpen && msg.data['type'] != 'order_approved') return;
    final n = msg.notification;
    if (n == null) return;
    _localNotif.show(
      msg.hashCode,
      n.title ?? 'ข้อความใหม่',
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      payload: msg.data['type'],
    );
  }

  Future<String?> getToken() => _fcm.getToken();

  Future<void> saveToken(int userId) async {
    try {
      final token = await getToken();
      debugPrint('[FCM] token=$token userId=$userId');
      if (token == null) return;
      final resp = await Dio().post(
        '${AppConfig.chatApi}/save-fcm-token',
        data: {'user_id': userId, 'fcm_token': token},
      );
      debugPrint('[FCM] save-token resp=${resp.statusCode}');
    } catch (e) {
      debugPrint('[FCM] saveToken error: $e');
    }
  }
}

