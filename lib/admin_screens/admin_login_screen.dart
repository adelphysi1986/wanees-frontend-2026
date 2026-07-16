import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// شاشة تسجيل دخول الأدمن — منفصلة تماماً عن شاشة دخول المدرب
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  static const String _baseUrl =
      'http://localhost:5000                                               ';

  static const Color navy = Color(0xFF14213D);
  static const Color gold = Color(0xFFE3B23C);
  static const Color background = Color(0xFFF6F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3DFD5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B67);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setupAdminTokenRefreshListener(String adminAuthToken) {
    FirebaseMessaging.instance.onTokenRefresh.listen((newFcmToken) async {
      try {
        await http.post(
          Uri.parse('$_baseUrl/api/admin/fcm-token'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $adminAuthToken',
          },
          body: jsonEncode({'fcmToken': newFcmToken}),
        );
        debugPrint('تم إرسال رمز الجهاز الجديد بنجاح للأدمن');
      } catch (e) {
        debugPrint('فشل إرسال رمز الجهاز الجديد للأدمن: $e');
      }
    });
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/admin/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('admin_token', data['token']);
        await saveAdminFcmToken(data['token']);
        _setupAdminTokenRefreshListener(data['token']);
        await prefs.setString('admin_role', data['admin']?['role'] ?? 'viewer');
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(data['message'] ??
                  'البريد الإلكتروني أو كلمة السر غير صحيحة')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('ما قدرنا نوصل للسيرفر، تأكد من الاتصال بالنت')),
      );
    }
  }

  InputDecoration _fieldDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: textSecondary, fontSize: 13.5),
      prefixIcon: Icon(icon, color: textSecondary, size: 20),
      filled: true,
      fillColor: background,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: navy, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    color: navy.withValues(alpha: 0.08),
                    shape: BoxShape.circle),
                child: const Icon(Icons.admin_panel_settings_outlined,
                    color: navy, size: 30),
              ),
              const SizedBox(height: 20),
              const Text('دخول الأدمن',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textPrimary)),
              const SizedBox(height: 6),
              const Text('سجّل دخولك لإدارة المنصة والمدربين والزبائن',
                  style: TextStyle(fontSize: 13, color: textSecondary)),
              const SizedBox(height: 32),
              const Text('البريد الإلكتروني',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _fieldDecoration(
                    'admin@platform.com', Icons.mail_outline_rounded),
              ),
              const SizedBox(height: 16),
              const Text('كلمة المرور',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration:
                    _fieldDecoration('••••••••', Icons.lock_outline_rounded)
                        .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: textSecondary,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                      foregroundColor: navy, padding: EdgeInsets.zero),
                  child: const Text('نسيت كلمة المرور؟',
                      style: TextStyle(fontSize: 12.5)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.white),
                        )
                      : const Text('تسجيل الدخول',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> saveAdminFcmToken(String token) async {
    try {
      print("START GET FCM TOKEN");

      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final fcmToken = await FirebaseMessaging.instance.getToken(
        vapidKey:
            'BCOCcMrvWOcPU2ccYoG_Fo89LKmn0bVReZLJU6Ch1YBBSf_aVg_76geRLrxXe0tlm5GYbPFax10T7aPbYGVbaH4',
      );

      print("FCM TOKEN WEB = $fcmToken");

      if (fcmToken == null) {
        print("FCM TOKEN NULL");
        return;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/admin/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fcmToken': fcmToken,
        }),
      );

      print("SAVE FCM STATUS: ${response.statusCode}");
      print("SAVE FCM BODY: ${response.body}");
    } catch (e) {
      print("FCM ERROR = $e");
    }
  }
}
