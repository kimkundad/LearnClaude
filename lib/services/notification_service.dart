import 'dart:async';
import 'dart:math';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

// Background message handler — ต้องอยู่ top-level
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _localNotif = FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenRefreshSubscription;

  static const _channelId = 'chat_channel';
  static const _channelName = 'ข้อความแชท';
  static const _deviceIdKey = 'notification_device_id';

  /// Set true when ChatScreen is active — suppresses foreground notifications
  bool isChatOpen = false;

  Future<void> init(BuildContext context) async {
    // ขอ permission
    final settings =
        await _fcm.requestPermission(alert: true, badge: true, sound: true);
    debugPrint('[FCM] authorization=${settings.authorizationStatus}');
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

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
      iOS: DarwinInitializationSettings(),
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
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: msg.data['type'],
    );
  }

  Future<String?> getToken() async {
    if (Platform.isIOS) {
      for (var i = 0; i < 10; i++) {
        final apnsToken = await _fcm.getAPNSToken();
        if (apnsToken != null) break;
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }
    return _fcm.getToken();
  }

  Future<void> saveToken(int userId) async {
    try {
      final token = await getToken();
      final deviceId = await _getDeviceId();
      final platform = Platform.isIOS ? 'ios' : 'android';
      final payload = {
        'user_id': userId,
        'fcm_token': token,
        'platform': platform,
        'device_id': deviceId,
      };
      debugPrint('[FCM] token=$token userId=$userId platform=$platform');
      if (token == null) return;
      final resp = await Dio().post(
        '${AppConfig.chatApi}/save-fcm-token',
        data: payload,
      );
      debugPrint('[FCM] save-token resp=${resp.statusCode}');
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = _fcm.onTokenRefresh.listen((newToken) async {
        try {
          await Dio().post(
            '${AppConfig.chatApi}/save-fcm-token',
            data: {
              ...payload,
              'fcm_token': newToken,
            },
          );
        } catch (e) {
          debugPrint('[FCM] save refreshed token error: $e');
        }
      });
    } catch (e) {
      debugPrint('[FCM] saveToken error: $e');
    }
  }

  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final id = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await prefs.setString(_deviceIdKey, id);
    return id;
  }
}
