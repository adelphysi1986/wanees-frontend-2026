import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteTrainersScreen extends StatefulWidget {
  final String baseUrl;
  const FavoriteTrainersScreen({super.key, required this.baseUrl});

  @override
  State<FavoriteTrainersScreen> createState() => _FavoriteTrainersScreenState();
}

class _FavoriteTrainersScreenState extends State<FavoriteTrainersScreen> {
  static const Color navy = Color(0xFF14213D);
  static const Color gold = Color(0xFFE3B23C);
  static const Color background = Color(0xFFF6F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3DFD5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B67);

  List<Map<String, dynamic>> _trainers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/api/users/favorites'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> trainersJson = data['trainers'] ?? [];

        setState(() {
          _trainers = trainersJson.map((t) {
            final name = t['name'] ?? 'مدرب';
            return {
              'id': t['_id'] ?? '',
              'name': name,
              'specialty': t['specialty'] ?? '',
              'description': t['description'] ?? '',
              'price': t['price'] ?? 0,
              'available': t['isAvailable'] ?? false,
              'busy': t['isBusy'] ?? false,
              'image': (t['imageUrl'] ?? '').toString().isNotEmpty
                  ? t['imageUrl']
                  : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=14213D&color=fff&size=256&bold=true',
              'rating': t['rating'] ?? 0,
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'فشل تحميل المفضلة (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'تعذر الاتصال بالسيرفر: $e';
        _isLoading = false;
      });
    }
  }

  // ── إزالة مدرب من المفضلة (بنفس endpoint الـ toggle الموجود) ──
  Future<void> _removeFavorite(Map<String, dynamic> trainer) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/api/users/favorites/${trainer['id']}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _trainers.removeWhere((t) => t['id'] == trainer['id']);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت الإزالة من المفضلة')),
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

  // ── حجز مباشر من الديالوج ──
  Future<void> _confirmBooking(
      BuildContext dialogContext, Map<String, dynamic> trainer) async {
    Navigator.pop(dialogContext);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final customerName = prefs.getString('user_name') ?? 'زبون';

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/api/bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "customerName": customerName,
          "trainerId": trainer['id'],
          "trainerName": trainer['name'],
          "sessionTime": DateTime.now().toIso8601String(),
          "description": '',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إرسال طلب الحجز بنجاح')),
          );
        }
      } else if (response.statusCode == 400) {
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل إنشاء الحجز (${response.statusCode})')),
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

  // ── ديالوج تفاصيل المدرب + زر حجز مباشر ──
  void _openTrainerDialog(Map<String, dynamic> trainer) {
    final bool available = trainer['available'] == true;
    final bool busy = trainer['busy'] == true;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 32),
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(22),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundImage: NetworkImage(trainer['image']),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(trainer['name'],
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 3),
                                  Text(trainer['specialty'],
                                      style: const TextStyle(
                                          color: gold,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _infoChip(
                                Icons.star_rounded, '${trainer['rating']}'),
                            const SizedBox(width: 8),
                            _infoChip(Icons.payments_outlined,
                                '${trainer['price']} ₪ / جلسة'),
                            const SizedBox(width: 8),
                            _infoChip(
                              !available
                                  ? Icons.cancel_outlined
                                  : busy
                                      ? Icons.access_time_filled_rounded
                                      : Icons.check_circle_outline,
                              !available
                                  ? 'غير متاح'
                                  : busy
                                      ? 'مشغول حالياً'
                                      : 'متاح الآن',
                            ),
                          ],
                        ),
                        if (trainer['description'].toString().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Divider(color: border),
                          const SizedBox(height: 12),
                          const Text('نبذة عن المدرب',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 6),
                          Text(trainer['description'],
                              style: const TextStyle(
                                  color: textSecondary, fontSize: 13.5)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: border)),
                ),
                child: ElevatedButton(
                  onPressed: available
                      ? () => _confirmBooking(dialogContext, trainer)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: available ? navy : border,
                    foregroundColor: available ? Colors.white : textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child:
                      Text(available ? 'احجز الآن' : 'المدرب غير متاح حالياً'),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: navy),
          const SizedBox(width: 4),
          Text(label,
              style:
                  const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المدربون المفضلون')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: navy))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _trainers.isEmpty
                  ? const Center(child: Text('لا يوجد مدربون مفضلون بعد'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _trainers.length,
                      itemBuilder: (ctx, i) {
                        final t = _trainers[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: border),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: InkWell(
                            onTap: () => _openTrainerDialog(t),
                            borderRadius: BorderRadius.circular(14),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage: NetworkImage(t['image']),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(t['name'],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Text(t['specialty'],
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: textSecondary)),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        color: gold, size: 16),
                                    const SizedBox(width: 3),
                                    Text('${t['rating']}',
                                        style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  onPressed: () => _removeFavorite(t),
                                  icon: const Icon(Icons.favorite_rounded,
                                      color: Colors.red, size: 22),
                                  tooltip: 'إزالة من المفضلة',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
