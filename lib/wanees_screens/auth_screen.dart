import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// شاشة تسجيل الدخول / إنشاء حساب — كل شي هون بملف واحد:
/// الألوان، النماذج، الاتصال بالباك اند، وتسجيل الدخول عبر جوجل
class AuthScreen extends StatefulWidget {
  final void Function(String token, Map<String, dynamic> user) onAuthSuccess;
  const AuthScreen({super.key, required this.onAuthSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // ── الألوان ──
  static const Color navy = Color(0xFF14213D);
  static const Color gold = Color(0xFFE3B23C);
  static const Color background = Color(0xFFF6F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3DFD5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B67);
  static const Color danger = Color(0xFF8C3D2A);

  // ══════════════════════════════════════════════════════════════
  // ⚠️ عدّل هذا الرابط ليطابق سيرفرك (نفس ملاحظة trainers_screen.dart)
  // ══════════════════════════════════════════════════════════════
  static const String _baseUrl = 'https://wanees-backend-2026.onrender.com';
  static const String _registerEndpoint = '$_baseUrl/api/users/register';
  static const String _loginEndpoint = '$_baseUrl/api/users/login';
  static const String _googleEndpoint = '$_baseUrl/api/users/google';

  // ⚠️ عدّل الـ clientId بعد ما تجهزه من Google Cloud Console (خطوات فوق)
  static const String _googleWebClientId =
      '159001548872-sr9rktlivt6g9ops83m5toh17k0lf11g.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: _googleWebClientId,
    scopes: ['email', 'profile'],
  );

  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  // حقول تسجيل الدخول
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // حقول إنشاء الحساب
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── حفظ التوكن ومعلومات المستخدم محلياً ──
  Future<void> _saveSession(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_data', jsonEncode(user));
  }

  // ── تسجيل الدخول بالإيميل وكلمة السر ──
  Future<void> _handleLogin() async {
    if (_loginEmailController.text.trim().isEmpty ||
        _loginPasswordController.text.isEmpty) {
      setState(
          () => _errorMessage = 'الرجاء إدخال البريد الإلكتروني وكلمة السر');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse(_loginEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': _loginEmailController.text.trim(),
              'password': _loginPasswordController.text,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        await _saveSession(data['token'], data['user']);
        widget.onAuthSuccess(data['token'], data['user']);
      } else {
        setState(() => _errorMessage = data['message'] ?? 'فشل تسجيل الدخول');
      }
    } catch (e) {
      setState(() =>
          _errorMessage = 'تعذر الاتصال بالسيرفر. تحقق من الاتصال بالإنترنت.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── إنشاء حساب جديد ──
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse(_registerEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': _nameController.text.trim(),
              'phone': _phoneController.text.trim(),
              'email': _emailController.text.trim(),
              'description': _descriptionController.text.trim(),
              'password': _passwordController.text,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        await _saveSession(data['token'], data['user']);
        widget.onAuthSuccess(data['token'], data['user']);
      } else {
        setState(() => _errorMessage = data['message'] ?? 'فشل إنشاء الحساب');
      }
    } catch (e) {
      setState(() =>
          _errorMessage = 'تعذر الاتصال بالسيرفر. تحقق من الاتصال بالإنترنت.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleAuth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        setState(() => _isLoading = false);
        return;
      }

      final auth = await account.authentication;
      final accessToken = auth.accessToken;

      if (accessToken == null) {
        setState(() {
          _errorMessage = 'تعذر الحصول على بيانات جوجل';
          _isLoading = false;
        });
        return;
      }

      final response = await http
          .post(
            Uri.parse(_googleEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'accessToken': accessToken}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        await _saveSession(data['token'], data['user']);
        widget.onAuthSuccess(data['token'], data['user']);
      } else {
        setState(() =>
            _errorMessage = data['message'] ?? 'فشل تسجيل الدخول عبر جوجل');
      }
    } catch (e) {
      setState(() => _errorMessage = 'حدث خطأ أثناء تسجيل الدخول عبر جوجل');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _switchMode(bool loginMode) {
    setState(() {
      _isLoginMode = loginMode;
      _errorMessage = null;
    });
  }

  // ── حقل نصي موحد الشكل ──
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: textSecondary),
        prefixIcon: Icon(icon, size: 20, color: textSecondary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _loginEmailController,
          label: 'البريد الإلكتروني',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _loginPasswordController,
          label: 'كلمة السر',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: textSecondary,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _nameController,
            label: 'الاسم الكامل',
            icon: Icons.person_outline_rounded,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'الرجاء إدخال الاسم' : null,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _phoneController,
            label: 'رقم الجوال',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'الرجاء إدخال رقم الجوال'
                : null,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _emailController,
            label: 'البريد الإلكتروني',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'الرجاء إدخال البريد الإلكتروني';
              }
              if (!v.contains('@') || !v.contains('.')) {
                return 'البريد الإلكتروني غير صحيح';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _descriptionController,
            label: 'نبذة عنك (اختياري)',
            icon: Icons.notes_rounded,
            maxLines: 2,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _passwordController,
            label: 'كلمة السر',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: textSecondary,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'الرجاء إدخال كلمة السر';
              if (v.length < 6) return 'كلمة السر يجب أن تكون 6 أحرف على الأقل';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'تأكيد كلمة السر',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirm,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: textSecondary,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) {
              if (v != _passwordController.text) return 'كلمة السر غير متطابقة';
              return null;
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: navy,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.fitness_center_rounded,
                            color: gold, size: 30),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _isLoginMode ? 'مرحباً بعودتك' : 'إنشاء حساب جديد',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isLoginMode
                          ? 'سجل دخولك لمتابعة رحلتك التدريبية'
                          : 'عبّي بياناتك للبدء',
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(fontSize: 13, color: textSecondary),
                    ),
                    const SizedBox(height: 22),

                    // ── تبديل بين تسجيل الدخول وإنشاء حساب ──
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _switchMode(true),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color:
                                      _isLoginMode ? navy : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'تسجيل الدخول',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _isLoginMode
                                        ? Colors.white
                                        : textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _switchMode(false),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color:
                                      !_isLoginMode ? navy : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'حساب جديد',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: !_isLoginMode
                                        ? Colors.white
                                        : textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: danger.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12.5, color: danger),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    _isLoginMode ? _buildLoginForm() : _buildRegisterForm(),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : (_isLoginMode ? _handleLogin : _handleRegister),
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
                            : Text(
                                _isLoginMode ? 'تسجيل الدخول' : 'إنشاء الحساب'),
                      ),
                    ),

                    const SizedBox(height: 18),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: border)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('أو',
                              style: TextStyle(
                                  fontSize: 12, color: textSecondary)),
                        ),
                        Expanded(child: Divider(color: border)),
                      ],
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleGoogleAuth,
                        icon: Image.network(
                          'https://www.svgrepo.com/show/475656/google-color.svg',
                          width: 20,
                          height: 20,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.g_mobiledata_rounded,
                              color: navy),
                        ),
                        label: const Text('المتابعة عبر جوجل'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textPrimary,
                          side: const BorderSide(color: border),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
