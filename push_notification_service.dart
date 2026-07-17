import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';

/// خدمة شاملة لإدارة إشعارات FCM على الويب والموبايل
/// استخدم PushNotificationService.instance.init() مرة وحدة بعد تسجيل الدخول
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // ⚠️ استبدل هاد بالـ VAPID key اللي جبته من Firebase Console
  static const String _vapidKey =
      'BCOCcMrvWOcPU2ccYoG_Fo89LKmn0bVReZLJU6Ch1YBBSf_aVg_76geRLrxXe0tlm5GYbPFax10T7aPbYGVbaH4';

  // ⚠️ استبدل هاد برابط الباك اند تبعك
  static const String _apiBaseUrl =
      'https://wanees-backend-2026.onrender.com/api';

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// نداء هاي الدالة مرة وحدة، الأفضل بعد تسجيل الدخول مباشرة
  /// [userId] معرّف الحساب (id تبع Admin أو Trainer أو User)
  /// [authToken] الـ JWT
  /// [accountType] نوع الحساب: 'admin' أو 'trainer' أو 'user'
  Future<void> init({
    required String userId,
    required String authToken,
    required String accountType, // 'admin' | 'trainer' | 'user'
  }) async {
    // 1. طلب إذن الإشعارات (ضروري بالويب و iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('⚠️ المستخدم رفض إذن الإشعارات');
      return;
    }

    // 2. جلب الـ token (لازم VAPID key بالويب فقط)
    try {
      if (kIsWeb) {
        _fcmToken = await _messaging.getToken(vapidKey: _vapidKey);
      } else {
        _fcmToken = await _messaging.getToken();
      }
    } catch (e) {
      print('❌ خطأ بجلب FCM token: $e');
      return;
    }

    if (_fcmToken == null) {
      print('⚠️ ما قدرنا نجيب FCM token');
      return;
    }

    print('✅ FCM Token: $_fcmToken');

    // 3. إرسال الـ token للباك اند وربطه بالحساب الصحيح
    await _sendTokenToBackend(
      authToken: authToken,
      accountType: accountType,
      token: _fcmToken!,
    );

    // 4. الاستماع لتحديث الـ token (بيصير أحياناً تلقائياً)
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      _sendTokenToBackend(
        authToken: authToken,
        accountType: accountType,
        token: newToken,
      );
    });

    // 5. استقبال الإشعارات وقت التطبيق مفتوح (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 إشعار وصل والتطبيق مفتوح: ${message.notification?.title}');
      _handleForegroundMessage(message);
    });

    // 6. لما المستخدم يضغط على الإشعار ويفتح التطبيق
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('👆 تم الضغط على الإشعار: ${message.data}');
      _handleNotificationTap(message);
    });
  }

  /// يبني المسار الصحيح حسب نوع الحساب
  String _endpointFor(String accountType) {
    switch (accountType) {
      case 'admin':
        return '$_apiBaseUrl/admin/fcm-token';
      case 'trainer':
        return '$_apiBaseUrl/trainers/fcm-token';
      case 'user':
      default:
        return '$_apiBaseUrl/users/fcm-token';
    }
  }

  Future<void> _sendTokenToBackend({
    required String authToken,
    required String accountType,
    required String token,
  }) async {
    final url = _endpointFor(accountType);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'fcmToken': token,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ تم حفظ FCM token بالباك اند ($accountType)');
      } else {
        print('❌ فشل حفظ FCM token: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ خطأ بالاتصال بالباك اند: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // TODO: عدّل هاد حسب احتياجك - مثلاً استخدام flutter_local_notifications
    // لعرض إشعار حتى لو التطبيق مفتوح، أو عرض in-app banner
  }

  void _handleNotificationTap(RemoteMessage message) {
    // TODO: navigation حسب نوع الإشعار
    // مثال:
    // final type = message.data['type'];
    // if (type == 'booking_approved') {
    //   navigatorKey.currentState?.pushNamed('/bookings/${message.data['bookingId']}');
    // }
  }
}
