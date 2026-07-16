import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// شاشة "النشاط" — تعرض حجوزات وجلسات الزبون المسجل دخول فقط.
/// إذا الزبون مو مسجل دخول، بتعرض بدل النشاط دعوة لتسجيل الدخول.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => ActivityScreenState();
}

class ActivityScreenState extends State<ActivityScreen> {
  static const String _baseUrl =
      'http://localhost:5000                                               ';

  static const Color navy = Color(0xFF14213D);
  static const Color background = Color(0xFFF6F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3DFD5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B67);
  static const Color available = Color(0xFF2F7A57);
  static const Color unavailable = Color(0xFF8C3D2A);
  static const Color pendingColor = Color(0xFFB8860B);
  static const Color zoomBlue = Color(0xFF2D6CDF);

  bool _isChecking = true;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _token;
  List<dynamic> _activities = [];
  String? _errorMessage;

  // ⬅️ جديد — السوكيت الخاص بالتحديث اللحظي
  IO.Socket? _socket;

  @override
  void initState() {
    super.initState();
    checkAuthAndLoad();
  }

  @override
  void dispose() {
    _disconnectSocket(); // ⬅️ جديد
    super.dispose();
  }

  // ── دالة عامة (public) عشان تنقدر تنستدعى من برّا (مثلاً من HomeShell بعد تسجيل الدخول) ──
  Future<void> checkAuthAndLoad() async {
    setState(() => _isChecking = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoggedIn = false;
        _isChecking = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _token = token;
      _isLoggedIn = true;
      _isChecking = false;
    });
    _fetchActivities();
    _connectSocket(); // ⬅️ جديد — نفعّل التحديث اللحظي بعد ما نتأكد إنه مسجل دخول
  }

  // ⬅️ جديد — الاتصال بالسوكيت والاستماع لتغييرات النشاط
  void _connectSocket() {
    if (_token == null) return;

    _disconnectSocket(); // تأكيد ما في اتصال قديم مفتوح

    _socket = IO.io(
      _baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': _token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('Socket connected');
    });

    _socket!.on('activityChanged', (data) {
      if (!mounted) return;

      String message = 'تم تحديث نشاطك';
      if (data is Map && data['type'] == 'created') {
        message = 'تم إضافة حجز جديد';
      } else if (data is Map && data['type'] == 'deleted') {
        message = 'تم حذف أحد حجوزاتك';
      } else if (data is Map && data['type'] == 'updated') {
        message = 'تم تحديث حالة حجزك';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );

      _fetchActivities();
    });

    _socket!.onConnectError((err) {
      print('Socket connect error: $err');
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected');
    });
  }

  // ⬅️ جديد
  void _disconnectSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  Future<void> _fetchActivities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/customer/activities'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        print('Fetched activities: ${data['activities']}');
        setState(() {
          _activities = data['activities'] ?? [];
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        // التوكن منتهي أو غير صالح — رجّع لحالة غير مسجل دخول
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
        if (!mounted) return;
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
        _disconnectSocket(); // ⬅️ جديد
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'صار خطأ أثناء جلب النشاطات';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'ما قدرنا نوصل للسيرفر';
        _isLoading = false;
      });
    }
  }

  Future<void> _goToLogin() async {
    final result = await Navigator.of(context).pushNamed('/login');
    if (result == true) {
      checkAuthAndLoad();
    }
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      const months = [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر',
      ];
      final hour24 = dt.hour;
      final period = hour24 >= 12 ? 'م' : 'ص';
      int hour12 = hour24 % 12;
      if (hour12 == 0) hour12 = 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} · $hour12:$minute $period';
    } catch (e) {
      return isoString;
    }
  }

  Map<String, dynamic> _statusInfo(String status) {
    switch (status) {
      case 'approved':
        return {
          'label': 'مؤكدة',
          'color': available,
          'icon': Icons.check_circle_outline_rounded,
        };
      case 'completed':
        return {
          'label': 'منتهية',
          'color': navy,
          'icon': Icons.task_alt_rounded,
        };
      case 'rejected':
        return {
          'label': 'مرفوضة',
          'color': unavailable,
          'icon': Icons.cancel_outlined,
        };
      case 'cancelled':
        return {
          'label': 'ملغاة',
          'color': unavailable,
          'icon': Icons.event_busy_outlined,
        };
      case 'pending':
      default:
        return {
          'label': 'قيد الانتظار',
          'color': pendingColor,
          'icon': Icons.hourglass_top_rounded,
        };
    }
  }

  String _actionByLabel(String? actionBy) {
    if (actionBy == 'admin') return 'الأدمن';
    if (actionBy == 'trainer') return 'المدرب';
    return '';
  }

  Widget _buildLoggedOutState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                  color: navy.withValues(alpha: 0.08), shape: BoxShape.circle),
              child:
                  const Icon(Icons.lock_outline_rounded, color: navy, size: 38),
            ),
            const SizedBox(height: 18),
            const Text(
              'سجّل دخولك لعرض نشاطك',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'كل حجوزاتك وجلساتك رح تظهر هون بعد تسجيل الدخول',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textSecondary),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _goToLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('سجّل الآن',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                  color: navy.withValues(alpha: 0.08), shape: BoxShape.circle),
              child:
                  const Icon(Icons.event_note_outlined, color: navy, size: 38),
            ),
            const SizedBox(height: 18),
            const Text(
              'ما في نشاط لسا',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'حجوزاتك رح تظهر هون أول ما تحجز جلسة',
              style: TextStyle(fontSize: 12.5, color: textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: textSecondary, size: 38),
            const SizedBox(height: 14),
            Text(_errorMessage ?? 'صار خطأ',
                style: const TextStyle(fontSize: 13, color: textSecondary)),
            const SizedBox(height: 14),
            TextButton(
                onPressed: _fetchActivities,
                child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final String status = item['status'] ?? 'pending';
    final info = _statusInfo(status);
    final String? zoomLink = item['zoomLink'];
    final bool showZoom = zoomLink != null &&
        zoomLink.isNotEmpty &&
        status != 'rejected' &&
        status != 'cancelled';
    final bool showActionBy = (status == 'rejected' || status == 'cancelled');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (info['color'] as Color).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(info['icon'] as IconData,
                    color: info['color'] as Color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مع المدرب ${item['trainerName'] ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 13, color: textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateTime(item['sessionTime']),
                          style: const TextStyle(
                              fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const SizedBox(width: 4),
                        Text(
                          item['description'] ?? '',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color.fromARGB(255, 30, 30, 30)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (info['color'] as Color).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: info['color'] as Color),
                ),
                child: Text(
                  info['label'] as String,
                  style: TextStyle(
                    color: info['color'] as Color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (showActionBy) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: info['color'] as Color),
                const SizedBox(width: 5),
                Text(
                  '${status == 'rejected' ? 'تم الرفض من قبل' : 'تم الإلغاء من قبل'} ${_actionByLabel(item['actionBy'])}',
                  style: TextStyle(
                    fontSize: 12,
                    color: info['color'] as Color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (showZoom) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border),
              ),
              child: status == 'approved'
                  ? Row(
                      children: [
                        const Icon(Icons.videocam_outlined,
                            size: 15, color: zoomBlue),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            )
                                .animate(onPlay: (c) => c.repeat())
                                .fade(begin: 0.2, end: 1, duration: 700.ms)
                                .then()
                                .fade(begin: 1, end: 0.2, duration: 700.ms),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'اضغط هنا للدخول إلى الاجتماع مع المدرب',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        )),
                        //InkWell(
                        //    onTap: () {
                        //   Clipboard.setData(ClipboardData(text: zoomLink));
                        //    ScaffoldMessenger.of(context).showSnackBar(
                        //     const SnackBar(content: Text('تم نسخ رابط زوم')),
                        //     );
                        //     },
                        //    child: const Icon(Icons.copy_rounded,
                        //    size: 16, color: navy),
                        //   ),
                      ],
                    )
                  :

                  // ignore: prefer_const_constructors
                  Text(
                      'جاري تحضير الجلسة',
                      style:
                          const TextStyle(fontSize: 12, color: textSecondary),
                    ),
            )
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_isChecking) {
      body = const Center(child: CircularProgressIndicator(color: navy));
    } else if (!_isLoggedIn) {
      body = _buildLoggedOutState();
    } else if (_isLoading && _activities.isEmpty) {
      body = const Center(child: CircularProgressIndicator(color: navy));
    } else if (_errorMessage != null && _activities.isEmpty) {
      body = _buildErrorState();
    } else if (_activities.isEmpty) {
      body = _buildEmptyState();
    } else {
      body = RefreshIndicator(
        color: navy,
        onRefresh: _fetchActivities,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          itemCount: _activities.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _buildCard(_activities[i]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('النشاط',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textPrimary)),
                  SizedBox(height: 4),
                  Text('حجوزاتك وجلساتك',
                      style: TextStyle(color: textSecondary)),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
