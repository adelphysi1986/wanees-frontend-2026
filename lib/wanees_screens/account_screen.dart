import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainers_app/google_auth_service.dart';
import 'package:trainers_app/wanees_screens/fav_screen.dart';
import 'package:trainers_app/wanees_screens/mycompleted_activities.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => AccountScreenState();
}

class AccountScreenState extends State<AccountScreen> {
  static const Color navy = Color(0xFF14213D);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3DFD5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B67);
  static const Color unavailable = Color(0xFF8C3D2A);

  static const String _baseUrl =
      'https://wanees-backend-2026.onrender.com'; // 👈 عدّلها لنفس مصدر باقي الشاشات

  String _name = '';
  String _phone = '';
  String _avatar = '';
  String _code = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> checkAuthAndLoad() async {
    await _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      setState(() {
        _name = '';
        _phone = '';
        _avatar = '';
        _code = '';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/users/profile/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];
        setState(() {
          _name = user['name'] ?? '';
          _phone = user['phone'] ?? '';
          _avatar = user['avatar'] ?? '';
          _code = user['code'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تسجيل الخروج',
                style: TextStyle(color: unavailable)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await GoogleAuthService.instance.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    await prefs.remove('user_data');

    if (mounted) {
      await checkAuthAndLoad();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  void _showEditCodeDialog() {
    final codeController = TextEditingController(text: _code);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إدخال الكود'),
        content: TextField(
          controller: codeController,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(
            hintText: 'اكتب الكود هنا',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _saveCode(codeController.text.trim());
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCode(String newCode) async {
    if (newCode.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/users/profile/code'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'code': newCode}),
      );

      if (response.statusCode == 200) {
        setState(() => _code = newCode);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ الكود بنجاح')),
          );
        }
      } else {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'فشل حفظ الكود')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر الاتصال بالسيرفر: $e')),
        );
      }
    }
  }

  Widget _tile(IconData icon, String title,
      {Color color = textPrimary, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: const Icon(Icons.chevron_left_rounded, color: textSecondary),
        onTap: onTap ?? () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: navy));
    }

    if (_name.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off_outlined,
                  size: 48, color: textSecondary),
              const SizedBox(height: 12),
              const Text('يرجى تسجيل الدخول لعرض بيانات حسابك',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textSecondary, fontSize: 13.5)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await Navigator.of(context).pushNamed('/login');
                  await checkAuthAndLoad();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('تسجيل الدخول'),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Text('حسابي', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: NetworkImage(
                    _avatar.isNotEmpty
                        ? _avatar
                        : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_name)}&background=14213D&color=fff&size=256&bold=true',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(_phone,
                          style: const TextStyle(
                              fontSize: 13, color: textSecondary)),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: navy,
                    side: const BorderSide(color: border, width: 1.4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('تعديل', style: TextStyle(fontSize: 12.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.confirmation_number_outlined,
                    color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الكود',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 3),
                      Text(
                        _code.isNotEmpty ? _code : 'لم تقم بإدخال كود بعد',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: _code.isNotEmpty ? 17 : 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: _code.isNotEmpty ? 2 : 0),
                      ),
                    ],
                  ),
                ),
                if (_code == '')
                  IconButton(
                    onPressed: _showEditCodeDialog,
                    icon: const Icon(Icons.edit_rounded,
                        color: Colors.white, size: 20),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('إعدادات',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary)),
          const SizedBox(height: 10),
          _tile(
            Icons.calendar_month_outlined,
            'جلساتي المحجوزة',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
            ),
          ),
          _tile(
            Icons.favorite_border,
            'المرشدون المفضلون',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FavoriteTrainersScreen(baseUrl: _baseUrl),
              ),
            ),
          ),
          _tile(
            Icons.notifications_none_rounded,
            'الإشعارات',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PlaceholderScreen(
                  title: 'الإشعارات',
                  message: 'لا يوجد إشعارات حالياً',
                  icon: Icons.notifications_off_outlined,
                ),
              ),
            ),
          ),
          _tile(
            Icons.lock_outline_rounded,
            'الخصوصية والأمان',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const PlaceholderScreen(
                        title: 'سياسة الخصوصية',
                        icon: Icons.privacy_tip_outlined,
                        message: '''
سياسة الخصوصية

نرحب بك في منصة ونيس. نحن نولي خصوصية المستخدمين وأمن بياناتهم أهمية كبيرة، ونسعى إلى توفير بيئة آمنة للأطفال وأولياء الأمور والمرشدين.

1. جمع البيانات
قد نقوم بجمع بعض البيانات الأساسية مثل الاسم، رقم الهاتف، البريد الإلكتروني (إن وجد)، والصورة الشخصية، وذلك لإنشاء الحساب وتقديم خدمات المنصة.

2. استخدام البيانات
تستخدم البيانات لإدارة الحسابات، وتنظيم الجلسات، والتواصل مع المستخدمين، وتحسين جودة الخدمات، وتوفير تجربة استخدام أفضل.

3. حماية الخصوصية
لا يتم عرض أرقام الهواتف أو وسائل التواصل الشخصية بين المستخدمين والمرشدين، ويتم التواصل وإدارة الجلسات من خلال المنصة فقط.

4. التحقق من المرشدين
تقوم إدارة المنصة بالتحقق من هوية المرشدين قبل اعتماد حساباتهم، كما تحتفظ بحق مراجعة الحسابات أو إيقافها عند مخالفة سياسات المنصة.

5. الجلسات
قد تقوم إدارة المنصة بالإشراف أو متابعة بعض الجلسات عند الحاجة لضمان جودة الخدمة وحماية الأطفال، مع احترام خصوصية جميع الأطراف.

6. التقييمات
يمكن للمستخدمين إضافة تقييماتهم وآرائهم وفقاً لسياسات المنصة، وتحتفظ الإدارة بحق إزالة أي تقييم يتضمن إساءة أو معلومات غير لائقة.

7. مشاركة البيانات
لا تقوم منصة ونيس ببيع أو مشاركة البيانات الشخصية مع أي جهة خارجية إلا إذا كان ذلك مطلوباً بموجب القانون أو ضرورياً لتقديم الخدمة.

8. حذف الحساب
يمكن للمستخدم طلب حذف حسابه أو تعديل بياناته من خلال التواصل مع إدارة المنصة، مع مراعاة أي التزامات قانونية تتعلق بالاحتفاظ بالبيانات.

9. تحديث السياسة
قد يتم تحديث سياسة الخصوصية من وقت لآخر، ويعد استمرار استخدام المنصة موافقة على آخر نسخة من هذه السياسة.

باستخدامك لمنصة ونيس فإنك تقر بأنك قرأت هذه السياسة وتوافق على ما ورد فيها.

لأي استفسار أو ملاحظة، يرجى التواصل معنا عبر صفحة "اتصل بنا".
''',
                      )),
            ),
          ),
          _tile(
            Icons.language_rounded,
            'اللغة',
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('اللغة'),
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: navy),
                    SizedBox(width: 10),
                    Text('العربية'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('حسناً'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _tile(Icons.logout_rounded, 'تسجيل الخروج',
              color: unavailable, onTap: _logout),
        ],
      ),
    );
  }
}

// ── شاشة عامة فاضية (تستخدم للإشعارات، المفضلة، الخصوصية) ──

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.construction_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Center(
              child: Icon(
                icon,
                size: 56,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            if (message.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  message,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.8,
                    color: Colors.black87,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
// ── شاشة جلساتي المحجوزة (سجل، مع Pagination) ──
