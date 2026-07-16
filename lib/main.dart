import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'admin_screens/admin-register.dart';
import 'admin_screens/admin_dashboard_screen.dart';
import 'admin_screens/admin_login_screen.dart';
import 'admin_screens/trainer-register.dart';
import 'admin_screens/trainer_dashboard_screen.dart';
import 'admin_screens/trainer_login_screen.dart';
import 'wanees_screens/auth_screen.dart';
import 'wanees_screens/home_shell.dart';

const String _baseUrl = 'http://localhost:5000';

// هاي الدالة بتشتغل مرة وحدة فور ما التطبيق يفتح
// بتشوف مين مسجل دخول (مدرب أو أدمن أو زبون) وبتبعت الرمز الحالي فوراً
Future<void> _sendCurrentFcmTokenOnStartup() async {
  try {
    final currentToken = await FirebaseMessaging.instance.getToken();
    if (currentToken == null) return;

    final prefs = await SharedPreferences.getInstance();

    final trainerAuthToken = prefs.getString('trainer_token');
    final adminAuthToken = prefs.getString('admin_token');
    final userAuthToken = prefs.getString('auth_token');

    if (trainerAuthToken != null) {
      await _pushTokenToServer(trainerAuthToken, currentToken);
    }
    if (adminAuthToken != null) {
      await _pushTokenToServer(adminAuthToken, currentToken);
    }
    if (userAuthToken != null) {
      await _pushTokenToServer(userAuthToken, currentToken);
    }
  } catch (e) {
    debugPrint('فشل إرسال الرمز عند فتح التطبيق: $e');
  }
}

// دالة مساعدة واحدة بترسل الرمز لأي صاحب حساب (مدرب أو أدمن أو زبون)
Future<void> _pushTokenToServer(String authToken, String fcmToken) async {
  try {
    await http.put(
      Uri.parse('$_baseUrl/api/update-fcm-token'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({'fcmToken': fcmToken}),
    );
    debugPrint('تم إرسال الرمز الحالي بنجاح');
  } catch (e) {
    debugPrint('فشل إرسال الرمز الحالي: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  usePathUrlStrategy();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  void showBrowserNotification(String title, String body) {
    print("TRY SHOW NOTIFICATION");

    if (!kIsWeb) return;

    print("PERMISSION: ${web.Notification.permission}");

    if (web.Notification.permission == 'granted') {
      web.Notification(
        title,
        web.NotificationOptions(
          body: body,
          icon: '/icons/Icon-192.png',
        ),
      );
    }
  }

  // إرسال الرمز الحالي فور فتح التطبيق (لو في مستخدم مسجل دخول مسبقاً)
  await _sendCurrentFcmTokenOnStartup();

  // الاستماع لأي تغيير مستقبلي بالرمز طول ما التطبيق مفتوح
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final prefs = await SharedPreferences.getInstance();

    final trainerAuthToken = prefs.getString('trainer_token');
    final adminAuthToken = prefs.getString('admin_token');
    final userAuthToken = prefs.getString('auth_token');

    if (trainerAuthToken != null) {
      await _pushTokenToServer(trainerAuthToken, newToken);
    }
    if (adminAuthToken != null) {
      await _pushTokenToServer(adminAuthToken, newToken);
    }
    if (userAuthToken != null) {
      await _pushTokenToServer(userAuthToken, newToken);
    }
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("🔥 FOREGROUND MESSAGE:");
    print(message.notification?.title);

    if (kIsWeb && message.notification != null) {
      showBrowserNotification(
        message.notification!.title ?? 'إشعار',
        message.notification!.body ?? '',
      );
    }
  });
  await initializeDateFormatting('ar', null);

  runApp(const TrainersApp());
}

class TrainersApp extends StatelessWidget {
  const TrainersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'منصة المدربين',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F4EF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF14213D),
          primary: const Color(0xFF14213D),
          secondary: const Color(0xFFE3B23C),
        ),
        textTheme: GoogleFonts.tajawalTextTheme(),
      ),
      routes: {
        '/': (context) => const HomeShell(),
        '/admin-login': (context) => const AdminLoginScreen(),
        '/trainer-login': (context) => const TrainerLoginScreen(),
        '/admin-register': (context) => const AdminRegisterScreen(),
        '/trainer-register': (context) => const TrainerRegisterScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/trainer-dashboard': (context) => const TrainerDashboardScreen(),
        '/login': (context) => AuthScreen(
              onAuthSuccess: (token, user) {
                Navigator.of(context).pop(true);
              },
            ),
      },
    );
  }
}
