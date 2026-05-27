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
  bool _isInitialized = false;

  static const _channelId = 'chat_channel';
  static const _channelName = 'ข้อความแชท';
  static const _deviceIdKey = 'notification_device_id';

  /// Set true when ChatScreen is active — suppresses foreground notifications
  bool isChatOpen = false;

  /// Unread chat message count — shown as badge on home chat icon
  final unreadChatCount = ValueNotifier<int>(0);

  Future<void> init(BuildContext context) async {
    await _ensureNotificationReady();

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
    FirebaseMessaging.onMessage.listen((msg) {
      debugPrint(
        '[FCM] onMessage data=${msg.data} '
        'notification=${msg.notification?.title}/${msg.notification?.body}',
      );
      _showLocal(msg);
    });

    // Background tap
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      debugPrint('[FCM] onMessageOpenedApp data=${msg.data}');
      if (!context.mounted) return;
      if (msg.data['type'] == 'order_approved') {
        context.go('/home');
      } else {
        context.push('/chat');
      }
    });
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM] initialMessage data=${initialMessage.data}');
    }
    _isInitialized = true;
  }

  Future<void> _ensureNotificationReady() async {
    await _fcm.setAutoInitEnabled(true);
    final settings =
        await _fcm.requestPermission(alert: true, badge: true, sound: true);
    debugPrint('[FCM] authorization=${settings.authorizationStatus}');
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );
  }

  void _showLocal(RemoteMessage msg) {
    final type = msg.data['type']?.toString();
    if (type != 'order_approved' && !isChatOpen) {
      unreadChatCount.value++;
    }
    if (isChatOpen) return;
    final n = msg.notification;
    final title = n?.title ??
        msg.data['title']?.toString() ??
        msg.data['notification_title']?.toString() ??
        'ข้อความใหม่';
    final body = n?.body ??
        msg.data['body']?.toString() ??
        msg.data['message']?.toString() ??
        msg.data['text']?.toString();

    if (title.trim().isEmpty && (body == null || body.trim().isEmpty)) return;

    _localNotif.show(
      msg.hashCode,
      title,
      body,
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
      payload: type,
    );
  }

  Future<String?> getToken() async {
    await _ensureNotificationReady();
    if (Platform.isIOS) {
      String? apnsToken;
      for (var i = 0; i < 20; i++) {
        apnsToken = await _fcm.getAPNSToken();
        if (apnsToken != null) break;
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      debugPrint('[FCM] apnsToken=${apnsToken == null ? 'null' : 'ready'}');
      if (apnsToken == null) return null;
    }
    return _fcm.getToken();
  }

  Future<void> saveToken(int userId) async {
    try {
      if (!_isInitialized) {
        await _ensureNotificationReady();
      }
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
      if (token == null) {
        unawaited(_retrySaveToken(userId));
        return;
      }
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

  Future<void> _retrySaveToken(int userId) async {
    await Future<void>.delayed(const Duration(seconds: 3));
    try {
      final token = await getToken();
      if (token == null) {
        debugPrint('[FCM] retry token=null userId=$userId');
        return;
      }
      final deviceId = await _getDeviceId();
      final platform = Platform.isIOS ? 'ios' : 'android';
      final resp = await Dio().post(
        '${AppConfig.chatApi}/save-fcm-token',
        data: {
          'user_id': userId,
          'fcm_token': token,
          'platform': platform,
          'device_id': deviceId,
        },
      );
      debugPrint('[FCM] retry save-token resp=${resp.statusCode}');
    } catch (e) {
      debugPrint('[FCM] retry saveToken error: $e');
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
