import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// شاشة تسجيل دخول المرشد — منفصلة تماماً عن شاشة دخول الأدمن
class TrainerLoginScreen extends StatefulWidget {
  const TrainerLoginScreen({super.key});

  @override
  State<TrainerLoginScreen> createState() => _TrainerLoginScreenState();
}

class _TrainerLoginScreenState extends State<TrainerLoginScreen> {
  // تشغيل على الويب (Chrome) والباك اند شغال محلياً → https://wanees-backend-2026.onrender.com
  static const String _baseUrl = 'https://wanees-backend-2026.onrender.com';
  static const Color navy = Color(0xFF14213D);
  static const Color gold = Color(0xFFE3B23C);
  static const Color background = Color(0xFFF6F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3DFD5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B67);

  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      // جلب رمز الجهاز قبل الإرسال
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint('ما قدرنا نجيب رمز الجهاز: $e');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/trainers/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': _phoneController.text.trim(),
          'password': _passwordController.text,
          'fcmToken': fcmToken,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('trainer_token', data['token']);
        await prefs.setString('trainer_name', data['trainer']['name']);

        // الاستماع لأي تغيير مستقبلي بالرمز وإرساله تلقائياً
        _setupTokenRefreshListener(data['token']);

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/trainer-dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(data['message'] ?? 'رقم الهاتف أو كلمة السر غير صحيحة')),
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

  // هاي الدالة بتستمع لأي تغيير مستقبلي بالرمز، وأول ما يتغير بترسله للسيرفر تلقائياً
  void _setupTokenRefreshListener(String trainerAuthToken) {
    FirebaseMessaging.instance.onTokenRefresh.listen((newFcmToken) async {
      try {
        await http.put(
          Uri.parse('$_baseUrl/api/trainers/update-fcm-token'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $trainerAuthToken',
          },
          body: jsonEncode({'fcmToken': newFcmToken}),
        );
        debugPrint('تم إرسال رمز الجهاز الجديد بنجاح');
      } catch (e) {
        debugPrint('فشل إرسال رمز الجهاز الجديد: $e');
      }
    });
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
                    color: gold.withValues(alpha: 0.15),
                    shape: BoxShape.circle),
                child: const Icon(Icons.fitness_center_rounded,
                    color: navy, size: 28),
              ),
              const SizedBox(height: 20),
              const Text('دخول المرشد',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textPrimary)),
              const SizedBox(height: 6),
              const Text('سجّل دخولك لإدارة جلساتك وحجوزات زبائنك',
                  style: TextStyle(fontSize: 13, color: textSecondary)),
              const SizedBox(height: 32),
              const Text('رقم الهاتف',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration:
                    _fieldDecoration('05X XXX XXXX', Icons.phone_outlined),
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
}
