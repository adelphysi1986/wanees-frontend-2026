import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'activity_screen.dart';

/// شاشة المدربين — كل شي هون: الألوان، جلب الداتا من الباك اند، القائمة، السجل، ومربع التفاصيل
class TrainersScreen extends StatefulWidget {
  final VoidCallback? onNavigateToActivity;
  const TrainersScreen(
      {super.key,
      this.onNavigateToActivity,
      required Future<void> Function() onAuthChanged});

  @override
  State<TrainersScreen> createState() => _TrainersScreenState();
}

class _TrainersScreenState extends State<TrainersScreen> {
  // ── الألوان (محلية لهاي الشاشة فقط) ──
  static const Color navy = Color(0xFF14213D);
  static const Color gold = Color(0xFFE3B23C);
  static const Color background = Color(0xFFF6F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3DFD5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B67);
  static const Color available = Color(0xFF2F7A57);
  static const Color unavailable = Color(0xFF8C3D2A);

  // ══════════════════════════════════════════════════════════════
  // ⚠️ عدّل هذا الرابط ليطابق سيرفرك:
  //  - إذا محاكي أندرويد (Android emulator) استخدم: http://10.0.2.2:5000
  //  - إذا محاكي iOS أو Chrome/Web استخدم: https://wanees-backend-2026.onrender.com
  //  - إذا جهاز حقيقي أو سيرفر مرفوع (deployed) استخدم رابطه الحقيقي (https://...)
  // ══════════════════════════════════════════════════════════════
  static const String _baseUrl = 'https://wanees-backend-2026.onrender.com';
  static const String _trainersEndpoint = '$_baseUrl/api/trainers';

  List<Map<String, dynamic>> _trainers = [];
  bool _isLoading = true;
  String? _errorMessage;
  final notesController = TextEditingController();

  String _filter = 'الكل';
  final List<String> _filters = const ['الكل', 'متاح الآن', 'غير متاح'];

  @override
  void initState() {
    super.initState();
    _fetchTrainers();
  }

  Future<void> _openWhatsApp() async {
    final Uri url = Uri.parse(
        'https://wa.me/972599071301?text=${Uri.encodeComponent("السلام عليكم")}');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // ── جلب المدربين من الباك اند (GET /api/trainers) ──
  Future<void> _fetchTrainers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .get(Uri.parse(_trainersEndpoint))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final mapped = data
            .map((raw) => _mapTrainer(raw as Map<String, dynamic>))
            .toList();

        // 👇 جديد: جيب قائمة المفضلة الحقيقية وطابقها
        final favoriteIds = await _fetchFavoriteIds();
        for (final trainer in mapped) {
          trainer['isFavorite'] = favoriteIds.contains(trainer['id']);
        }

        setState(() {
          _trainers = mapped;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'فشل تحميل المدربين (كود ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'تعذر الاتصال بالسيرفر. تحقق من الاتصال بالإنترنت.';
        _isLoading = false;
      });
    }
  }

// 👇 دالة جديدة: تجيب قائمة IDs المدربين المفضلين عند الزبون الحالي
  Future<Set<String>> _fetchFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) return {};

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/users/favorites'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> trainersJson = data['trainers'] ?? [];
        return trainersJson.map((t) => t['_id'].toString()).toSet();
      }
    } catch (e) {
      // تجاهل الخطأ، رح ترجع مجموعة فاضية
    }
    return {};
  }

  // ── يحوّل عنصر Trainer القادم من الباك اند إلى الشكل الذي تتوقعه الواجهة ──
  // ملاحظة: إذا كانت أسماء الحقول بموديل Trainer (Mongoose) مختلفة عن هذي،
  // بس عدّل المفاتيح (keys) هون فقط بدون لمس باقي الملف.
  Map<String, dynamic> _mapTrainer(Map<String, dynamic> raw) {
    String pick(List<String> keys, String fallback) {
      for (final k in keys) {
        final v = raw[k];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString();
      }
      return fallback;
    }

    num pickNum(List<String> keys, num fallback) {
      for (final k in keys) {
        final v = raw[k];
        if (v != null) {
          if (v is num) return v;
          final parsed = num.tryParse(v.toString());
          if (parsed != null) return parsed;
        }
      }
      return fallback;
    }

    bool pickBool(List<String> keys, bool fallback) {
      for (final k in keys) {
        final v = raw[k];
        if (v != null) {
          if (v is bool) return v;
          if (v is String) return v.toLowerCase() == 'true';
        }
      }
      return fallback;
    }

    final name = pick(['name', 'fullName', 'trainerName'], 'مدرب');

    return {
      'id': raw['_id'] ?? raw['id'] ?? '',
      'name': name,
      'specialty': pick(['specialty', 'specialization', 'category'], ''),
      'description': pick(['description', 'bio', 'about'], ''),
      'image': pick(
        ['image', 'photo', 'avatar', 'imageUrl', 'profileImage'],
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=14213D&color=fff&size=256&bold=true',
      ),
      'available': pickBool(['available', 'isAvailable', 'status'], false),
      'busy': pickBool(['busy', 'isBusy', 'status'], false),

      'price': pickNum(['price', 'sessionPrice', 'pricePerSession'], 0),
      'rating': pickNum(['rating', 'avgRating'], 0),
      'reviews': pickNum(['reviews', 'reviewsCount', 'reviewCount'], 0),
      'isFavorite': false, // 👈 جديد
    };
  }

  // ── تتأكد إذا في تسجيل دخول، وإذا مافي بتوديه لصفحة اللوجن وتنتظر النتيجة ──
  Future<bool> _ensureAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null && token.isNotEmpty) return true;

    final result = await Navigator.of(context).pushNamed('/login');
    return result == true;
  }

  void _openQuickBookingDialog() {
    final availableTrainers =
        _trainers.where((t) => t['available'] == true).toList();
    Map<String, dynamic>? selectedTrainer =
        availableTrainers.isNotEmpty ? availableTrainers.first : null;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 32),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: surface, borderRadius: BorderRadius.circular(22)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('حجز جلسة جديدة',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textPrimary)),
                        InkWell(
                          onTap: () => Navigator.pop(dialogContext),
                          child: const Icon(Icons.close_rounded,
                              color: textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Text(
                            'يفضل التواصل معنا قبل الحجز لضمان سرعة الحجز وتجربة أفضل',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 255, 0, 0),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _openWhatsApp,
                          child: const Text(
                            'تواصل معنا',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text('اختر المدرب',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Map<String, dynamic>>(
                          isExpanded: true,
                          value: selectedTrainer,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: textSecondary),
                          hint: const Text('لا يوجد مدربون متاحون حالياً'),
                          items: availableTrainers
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                      '${t['name']} · ${t['specialty']}',
                                      style: const TextStyle(fontSize: 13.5)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setDialogState(() => selectedTrainer = value),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('ملاحظات إضافية',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'اكتب أي تفاصيل حابب تشاركها مع المدرب...',
                        filled: true,
                        fillColor: background,
                        contentPadding: const EdgeInsets.all(12),
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
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selectedTrainer == null
                            ? null
                            : () async {
                                await _confirmBooking(
                                    dialogContext, selectedTrainer!);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('احجز الآن'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showConnectingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 26),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(strokeWidth: 3, color: navy),
              ),
              SizedBox(height: 18),
              Text(
                'جاري توصيلك بالونيس',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: textPrimary),
              ),
              SizedBox(height: 6),
              Text(
                'انتظر لحظات...',
                style: TextStyle(fontSize: 12.5, color: textSecondary),
              ),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      Navigator.pop(context);

      if (widget.onNavigateToActivity != null) {
        widget.onNavigateToActivity!();
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ActivityScreen(),
          ),
        );
      }
    });
  }

  void _openTrainerDialog(Map<String, dynamic> trainer) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return _buildTrainerDialog(trainer, setDialogState);
        },
      ),
    );
  }

  Future<void> _confirmBooking(
      BuildContext dialogContext, Map<String, dynamic> trainer) async {
    Navigator.pop(dialogContext);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final customerName = prefs.getString('user_name') ?? 'زبون';

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "customerName": customerName,
          "trainerId": trainer['id'],
          "trainerName": trainer['name'],
          "sessionTime": DateTime.now().toIso8601String(),

          // الوصف القادم من حقل الملاحظات
          "description": notesController.text.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showConnectingDialog();
      } else if (response.statusCode == 400) {
        // ⬅️ جديد — حالة "طلب سابق خلال آخر ساعة"
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'لا يمكن إتمام الطلب حالياً';

        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('تنبيه'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('حسناً'),
                ),
              ],
            ),
          );
        }
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل إنشاء الحجز (${response.statusCode})'),
          ),
        );
      }
    } catch (e) {
      print('Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر الاتصال بالسيرفر: $e'),
        ),
      );
    }
  }

  Widget _buildTrainerDialog(
      Map<String, dynamic> trainer, StateSetter setDialogState) {
    final textTheme = Theme.of(context).textTheme;
    final bool isAvailable = trainer['available'] as bool;
    final Color statusColor = isAvailable ? available : unavailable;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 32),
      child: Builder(
        builder: (dialogContext) => Container(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 620),
          decoration: BoxDecoration(
              color: surface, borderRadius: BorderRadius.circular(22)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 1.6,
                            child: Image.network(trainer['image'],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                      color: background,
                                      child: const Icon(Icons.person,
                                          size: 48, color: textSecondary),
                                    )),
                          ),
                          Positioned(
                            left: 10,
                            top: 10,
                            child: InkWell(
                              onTap: () => Navigator.pop(dialogContext),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.close_rounded,
                                    size: 18, color: textPrimary),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(trainer['name'],
                                      style: textTheme.headlineSmall
                                          ?.copyWith(fontSize: 19)),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _toggleFavorite(trainer, setDialogState),
                                  icon: Icon(
                                    trainer['isFavorite'] == true
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: trainer['isFavorite'] == true
                                        ? Colors.red
                                        : textSecondary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: statusColor, width: 1.3),
                                  ),
                                  child: Text(
                                    isAvailable ? 'متاح الآن' : 'غير متاح',
                                    style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              trainer['specialty'],
                              style: textTheme.bodyMedium?.copyWith(
                                  color: gold, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _showTrainerReviewsDialog(
                                          context, trainer),
                                      child: _infoChip(Icons.star_rounded,
                                          '${trainer['rating']} (${trainer['reviews']} تقييم)'),
                                    ),
                                    const SizedBox(width: 10),
                                    _infoChip(Icons.payments_outlined,
                                        '${trainer['price']} ₪ / جلسة'),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const Divider(color: border),
                            const SizedBox(height: 14),
                            Text('نبذة عن المدرب',
                                style: textTheme.titleMedium
                                    ?.copyWith(fontSize: 14.5)),
                            const SizedBox(height: 8),
                            Text(
                              trainer['description'],
                              style: textTheme.bodyLarge?.copyWith(
                                  color: textSecondary, fontSize: 13.5),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: border))),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showRatingDialog(context, trainer),
                        icon: const Icon(Icons.star_border_rounded, size: 20),
                        label: const Text('قيّم المدرب'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: gold,
                          side: const BorderSide(color: gold, width: 1.3),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isAvailable
                            ? () async {
                                await _openWhatsApp();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAvailable ? navy : border,
                          foregroundColor:
                              isAvailable ? Colors.white : textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('تواصل معنا قبل الحجز'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: navy),
          const SizedBox(width: 6),
          Text(label,
              style:
                  const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTrainerTile(Map<String, dynamic> trainer) {
    final textTheme = Theme.of(context).textTheme;
    final bool isAvailable = trainer['available'] as bool;
    final bool isBusy = trainer['busy'] as bool? ?? false;

    final Color statusColor = !isAvailable
        ? unavailable
        : isBusy
            ? Colors.orange
            : available;

    final String statusLabel = !isAvailable
        ? 'غير متاح'
        : isBusy
            ? 'مشغول حالياً'
            : 'متاح';

    final String name = trainer['name'];

    return InkWell(
      onTap: () => _openTrainerDialog(trainer),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: border,
              backgroundImage: NetworkImage(trainer['image']),
              onBackgroundImageError: (_, __) {},
              child: Text(
                name.isNotEmpty ? name[0] : '',
                style: const TextStyle(
                    color: textSecondary, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: textTheme.titleMedium?.copyWith(
                              fontSize: 15, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor, width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: statusColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 4),
                            Text(statusLabel,
                                style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    trainer['specialty'],
                    style: const TextStyle(
                        fontSize: 12, color: gold, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trainer['description'],
                    style: const TextStyle(fontSize: 12, color: textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 15, color: gold),
                      const SizedBox(width: 2),
                      Text(
                        (trainer['rating'] as num).toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 12,
                            color: textPrimary,
                            fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        '${trainer['price']} ₪ / الجلسة',
                        style: const TextStyle(
                            fontSize: 12.5,
                            color: navy,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── حالة التحميل ──
  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 80),
        child: CircularProgressIndicator(color: navy),
      ),
    );
  }

  // ── حالة الخطأ مع زر إعادة المحاولة ──
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: textSecondary),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'حدث خطأ ما',
              textAlign: TextAlign.center,
              style: const TextStyle(color: textSecondary, fontSize: 13.5),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchTrainers,
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  // ── حالة عدم وجود مدربين ──
  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 60),
        child: Text('لا يوجد مدربون حالياً',
            style: TextStyle(color: textSecondary, fontSize: 13.5)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trainers = _trainers.where((t) {
      if (_filter == 'متاح الآن') return t['available'] == true;
      if (_filter == 'غير متاح') return t['available'] == false;
      return true;
    }).toList()
      ..sort((a, b) => (b['rating'] as num).compareTo(a['rating'] as num));

    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration: const BoxDecoration(
              color: background,
              border: Border(bottom: BorderSide(color: border)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('المدربون',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: textPrimary)),
                      SizedBox(height: 4),
                      Text('اختر مدربك وابدأ جلستك الأولى اليوم',
                          style: TextStyle(fontSize: 13, color: textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        if (await _ensureAuthenticated()) {
                          _openQuickBookingDialog();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('احجز الآن'),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        'https://res.cloudinary.com/dg7ylyz6l/image/upload/v1784410598/087e8259-8131-44a9-8230-e65abb4c25fd_tnyyfz.jpg',
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: navy,
              onRefresh: _fetchTrainers,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 44,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _filters.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final f = _filters[i];
                            final selected = f == _filter;
                            return ChoiceChip(
                              label: Text(f),
                              selected: selected,
                              onSelected: (_) => setState(() => _filter = f),
                              showCheckmark: false,
                              backgroundColor: surface,
                              selectedColor: navy,
                              side: BorderSide(color: selected ? navy : border),
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  if (_isLoading)
                    SliverFillRemaining(child: _buildLoadingState())
                  else if (_errorMessage != null)
                    SliverFillRemaining(child: _buildErrorState())
                  else if (trainers.isEmpty)
                    SliverFillRemaining(child: _buildEmptyState())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildTrainerTile(trainers[i]),
                          ),
                          childCount: trainers.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context, Map<String, dynamic> trainer) {
    int selectedRating = 0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => Dialog(
          backgroundColor: surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'قيّم ${trainer['name']}',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return IconButton(
                      onPressed: () {
                        setDialogState(() => selectedRating = starIndex);
                      },
                      icon: Icon(
                        starIndex <= selectedRating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: gold,
                        size: 34,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'اكتب تعليقك هنا (اختياري)',
                    hintStyle:
                        const TextStyle(color: textSecondary, fontSize: 13),
                    filled: true,
                    fillColor: background,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedRating == 0
                        ? null
                        : () async {
                            Navigator.pop(dialogCtx);
                            await _submitRating(
                              trainer['id'],
                              selectedRating,
                              commentController.text.trim(),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('إرسال التقييم'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitRating(
      String trainerId, int rating, String comment) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/trainers/$trainerId/rate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'rating': rating,
          'comment': comment,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال تقييمك بنجاح')),
        );
      } else if (response.statusCode == 400) {
        print(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonDecode(response.body)['message'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر الاتصال بالسيرفر: $e')),
      );
    }
  }

  void _showTrainerReviewsDialog(
      BuildContext context, Map<String, dynamic> trainer) {
    print('DEBUG trainer map: $trainer'); // 👈 ضيفه هون

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 40),
        child: _TrainerReviewsSheet(
          trainerId: trainer['id'],
          trainerName: trainer['name'],
          baseUrl: _baseUrl, // 👈 تأكد نفس متغير الرابط المستخدم بباقي الملف
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(
      Map<String, dynamic> trainer, StateSetter setDialogState) async {
    final authenticated = await _ensureAuthenticated();
    if (!authenticated) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/users/favorites/${trainer['id']}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setDialogState(() {
          trainer['isFavorite'] = data['isFavorite'];
        });
        setState(() {
          trainer['isFavorite'] = data['isFavorite'];
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'])),
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
}

class _TrainerReviewsSheet extends StatefulWidget {
  final String trainerId;
  final String trainerName;
  final String baseUrl;

  const _TrainerReviewsSheet({
    required this.trainerId,
    required this.trainerName,
    required this.baseUrl,
  });

  @override
  State<_TrainerReviewsSheet> createState() => _TrainerReviewsSheetState();
}

class _TrainerReviewsSheetState extends State<_TrainerReviewsSheet> {
  static const Color navy = Color(0xFF14213D);
  static const Color gold = Color(0xFFE3B23C);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3DFD5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B67);

  final List<Map<String, dynamic>> _reviews = [];
  final ScrollController _scrollController = ScrollController();

  int _currentPage = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  double _averageRating = 0;
  int _totalRatings = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchReviews(isInitial: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _hasMore) {
        _fetchReviews();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _timeAgo(String isoDate) {
    final date = DateTime.parse(isoDate).toLocal();
    final diff = DateTime.now().difference(date);

    if (diff.inDays >= 365) {
      final years = (diff.inDays / 365).floor();
      return 'منذ $years ${years == 1 ? "سنة" : "سنوات"}';
    } else if (diff.inDays >= 30) {
      final months = (diff.inDays / 30).floor();
      return 'منذ $months ${months == 1 ? "شهر" : "أشهر"}';
    } else if (diff.inDays >= 7) {
      final weeks = (diff.inDays / 7).floor();
      return 'منذ $weeks ${weeks == 1 ? "أسبوع" : "أسابيع"}';
    } else if (diff.inDays >= 1) {
      return 'منذ ${diff.inDays} ${diff.inDays == 1 ? "يوم" : "أيام"}';
    } else if (diff.inHours >= 1) {
      return 'منذ ${diff.inHours} ${diff.inHours == 1 ? "ساعة" : "ساعات"}';
    } else if (diff.inMinutes >= 1) {
      return 'منذ ${diff.inMinutes} ${diff.inMinutes == 1 ? "دقيقة" : "دقائق"}';
    }
    return 'الآن';
  }

  Future<void> _fetchReviews({bool isInitial = false}) async {
    if (isInitial) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 1;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final url =
          '${widget.baseUrl}/api/trainers/${widget.trainerId}/ratings?page=$_currentPage&limit=10';
      print('DEBUG FULL URL: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> ratingsJson = data['ratings'] ?? [];

        final newReviews = ratingsJson.map((r) {
          final customer = r['customer'] ?? {};
          return {
            'customer': customer['name'] ?? 'زبون',
            'avatar': customer['avatar']?.toString().isNotEmpty == true
                ? customer['avatar']
                : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(customer['name'] ?? 'زبون')}&background=14213D&color=fff&size=150',
            'rating': (r['rating'] as num).toDouble(),
            'comment': r['comment'] ?? '',
            'createdAt': r['createdAt'] ?? '',
          };
        }).toList();

        setState(() {
          if (isInitial) _reviews.clear();
          _reviews.addAll(newReviews);
          _hasMore = data['hasMore'] ?? false;
          _averageRating = (data['averageRating'] as num?)?.toDouble() ?? 0;
          _totalRatings = data['totalRatings'] ?? 0;
          _currentPage++;
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _errorMessage = 'فشل تحميل التقييمات (${response.statusCode})';
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'تعذر الاتصال بالسيرفر: $e';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420, maxHeight: 600),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            color: navy,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('تقييمات ${widget.trainerName}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      const SizedBox(height: 4),
                      if (!_isLoading)
                        Text(
                          '$_averageRating ★  •  $_totalRatings تقييم',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12.5),
                        ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          Flexible(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _errorMessage != null && _reviews.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child:
                            Text(_errorMessage!, textAlign: TextAlign.center),
                      )
                    : _reviews.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('لا توجد تقييمات بعد لهذا المدرب'),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(16),
                            itemCount:
                                _reviews.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (ctx, i) {
                              if (i == _reviews.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                );
                              }
                              final r = _reviews[i];
                              final timeAgo =
                                  r['createdAt'].toString().isNotEmpty
                                      ? _timeAgo(r['createdAt'])
                                      : '';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: border),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                        radius: 18,
                                        backgroundImage:
                                            NetworkImage(r['avatar'])),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(r['customer'],
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 13)),
                                              Row(
                                                children: List.generate(
                                                  5,
                                                  (idx) => Icon(
                                                    idx < r['rating'].round()
                                                        ? Icons.star_rounded
                                                        : Icons
                                                            .star_border_rounded,
                                                    color: gold,
                                                    size: 13,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (timeAgo.isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 2),
                                              child: Text(timeAgo,
                                                  style: const TextStyle(
                                                      color: textSecondary,
                                                      fontSize: 11)),
                                            ),
                                          if (r['comment']
                                              .toString()
                                              .isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 6),
                                              child: Text(r['comment'],
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      color: textPrimary)),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
