import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'trainers_screen.dart';
import 'activity_screen.dart';
import 'account_screen.dart';
import 'ratings_screen.dart';
import 'contact_screen.dart';

/// الهيكل العام + شريط التنقل السفلي
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const Color navy = Color(0xFF14213D);
  static const Color gold = Color(0xFFE3B23C);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF6F4EF);
  static const Color border = Color(0xFFE3DFD5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B67);

  int _index = 0;
  bool _isLoggedIn = false;
  String? _userName;

  final GlobalKey<ActivityScreenState> _activityKey =
      GlobalKey<ActivityScreenState>();

  final GlobalKey<AccountScreenState> _accountKey =
      GlobalKey<AccountScreenState>();

  @override
  void initState() {
    super.initState();
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userDataRaw = prefs.getString('user_data');

    if (token != null && token.isNotEmpty && userDataRaw != null) {
      final user = jsonDecode(userDataRaw) as Map<String, dynamic>;
      final userName = user['name']?.toString();

      if (userName != null && userName.isNotEmpty) {
        await prefs.setString('user_name', userName);
      }

      if (!mounted) return;
      setState(() {
        _isLoggedIn = true;
        _userName = userName;
      });
    } else {
      if (!mounted) return;
      setState(() {
        _isLoggedIn = false;
        _userName = null;
      });
    }

    _activityKey.currentState?.checkAuthAndLoad();
    _accountKey.currentState?.checkAuthAndLoad();
  }

  late final List<Widget> _screens = [
    TrainersScreen(
      onNavigateToActivity: () => setState(() => _index = 1),
      onAuthChanged: _loadAuthState,
    ),
    ActivityScreen(key: _activityKey),
    AccountScreen(key: _accountKey),
    const RatingsScreen(),
    const ContactScreen(),
  ];

  final _items = const [
    {
      'icon': Icons.groups_outlined,
      'active': Icons.groups_rounded,
      'label': 'المدربون'
    },
    {
      'icon': Icons.timeline_outlined,
      'active': Icons.timeline_rounded,
      'label': 'النشاط'
    },
    {
      'icon': Icons.person_outline_rounded,
      'active': Icons.person_rounded,
      'label': 'حسابي'
    },
    {
      'icon': Icons.star_border_rounded,
      'active': Icons.star_rounded,
      'label': 'تقييمات'
    },
    {
      'icon': Icons.phone_outlined,
      'active': Icons.phone_rounded,
      'label': 'اتصل بنا'
    },
  ];

  Widget _buildAuthBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: navy,
      ),
      child: SafeArea(
        bottom: false,
        child: _isLoggedIn
            ? Row(
                children: [
                  const Icon(Icons.person_rounded, color: gold, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'مرحباً ${_userName ?? ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  const Icon(Icons.person_outline_rounded,
                      color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'ليس لديك حساب؟',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      await Navigator.of(context).pushNamed('/login');
                      _loadAuthState();
                    },
                    child: const Text(
                      'إنشاء حساب',
                      style: TextStyle(
                        color: gold,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                        decorationColor: gold,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Column(
          children: [
            _buildAuthBar(),
            Expanded(
              child: IndexedStack(index: _index, children: _screens),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: surface,
            border: Border(top: BorderSide(color: border)),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 62,
              child: Row(
                children: List.generate(_items.length, (i) {
                  final selected = i == _index;
                  final item = _items[i];
                  return Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _index = i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            selected
                                ? item['active'] as IconData
                                : item['icon'] as IconData,
                            color: selected ? navy : textSecondary,
                            size: 22,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item['label'] as String,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected ? navy : textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
