import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// شاشة إنشاء حساب مدرب جديد — الحقول الأساسية بس، متصلة بالباك اند
class TrainerRegisterScreen extends StatefulWidget {
  const TrainerRegisterScreen({super.key});

  @override
  State<TrainerRegisterScreen> createState() => _TrainerRegisterScreenState();
}

class _TrainerRegisterScreenState extends State<TrainerRegisterScreen> {
  // تشغيل على الويب (Chrome) والباك اند شغال محلياً → http://localhost:5000
  // Android Emulator → http://10.0.2.2:5000
  // جهاز حقيقي بنفس الشبكة → http://192.168.x.x:5000 (آي بي جهاز الكمبيوتر)
  // Render بعد الرفع → https://your-backend.onrender.com
  static const String _baseUrl =
      'http://localhost:5000                                               ';

  static const Color navy = Color(0xFF14213D);
  static const Color gold = Color(0xFFE3B23C);
  static const Color background = Color(0xFFF6F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3DFD5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B67);
  static const Color unavailable = Color(0xFF8C3D2A);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  final List<String> _specialties = const [
    'لياقة بدنية',
    'يوغا وتأمل',
    'تغذية علاجية',
    'كروس فيت',
    'ملاكمة',
  ];
  String? _selectedSpecialty;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSpecialty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر تخصصك من فضلك')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ملاحظة: بعت بس الحقول الأساسية (الاسم، الهاتف، كلمة السر) للباك اند
      // التخصص لسا محلي بالفرونت إند بس، ما في له حقل بالموديل حالياً
      final response = await http.post(
        Uri.parse('$_baseUrl/api/trainers/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('trainer_token', data['token']);
        await prefs.setString('trainer_name', data['trainer']['fullName']);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/trainer-dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(data['message'] ?? 'صار في خطأ، حاول مرة ثانية')),
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
          borderSide: const BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: navy, width: 1.4)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: unavailable)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: unavailable, width: 1.4)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.15),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.fitness_center_rounded,
                      color: navy, size: 26),
                ),
                const SizedBox(height: 18),
                const Text('إنشاء حساب مدرب',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textPrimary)),
                const SizedBox(height: 6),
                const Text('عبّي بياناتك للانضمام كمدرب على المنصة',
                    style: TextStyle(fontSize: 13, color: textSecondary)),
                const SizedBox(height: 28),
                const Text('الاسم الكامل',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: _fieldDecoration(
                      'مثال: أحمد الزعبي', Icons.person_outline_rounded),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
                ),
                const SizedBox(height: 16),
                const Text('رقم الهاتف',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration:
                      _fieldDecoration('05X XXX XXXX', Icons.phone_outlined),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'رقم الهاتف مطلوب'
                      : null,
                ),
                const SizedBox(height: 16),
                const Text('التخصص',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedSpecialty,
                      hint: const Text('اختر تخصصك',
                          style:
                              TextStyle(fontSize: 13.5, color: textSecondary)),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: textSecondary),
                      items: _specialties
                          .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s,
                                  style: const TextStyle(fontSize: 13.5))))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedSpecialty = value),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('كلمة المرور',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextFormField(
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
                          size: 20),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'كلمة المرور 6 أحرف على الأقل'
                      : null,
                ),
                const SizedBox(height: 16),
                const Text('تأكيد كلمة المرور',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration:
                      _fieldDecoration('••••••••', Icons.lock_outline_rounded)
                          .copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: textSecondary,
                          size: 20),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) => (v != _passwordController.text)
                      ? 'كلمتا المرور غير متطابقتين'
                      : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
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
                                strokeWidth: 2.4, color: Colors.white))
                        : const Text('إنشاء الحساب',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
