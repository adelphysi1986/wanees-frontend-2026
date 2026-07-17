import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// شاشة تعرض كل الطلبات المؤكدة (الموافق عليها) للزبون المسجل دخوله
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  // عدّل الرابط حسب مكان تشغيل السيرفر تبعك
  static const String _baseUrl = 'https://wanees-backend-2026.onrender.com';

  static const Color navy = Color(0xFF14213D);
  static const Color gold = Color(0xFFE3B23C);
  static const Color background = Color(0xFFF6F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3DFD5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B67);

  List<dynamic> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchConfirmedBookings();
  }

  Future<void> _fetchConfirmedBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'يجب تسجيل الدخول أولاً';
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/users/getorders'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);
        setState(() {
          _bookings = data['activities'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'حدث خطأ أثناء جلب الطلبات';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'ما قدرنا نوصل للسيرفر، تأكد من الاتصال بالنت';
      });
    }
  }

  String _formatDateTime(String? value) {
    if (value == null || value.isEmpty) return '';

    try {
      final dt = DateTime.parse(value).toLocal();

      const months = [
        'كانون ثاني',
        'شباط',
        'اذار',
        'نيسان',
        'ايار',
        'حزيران',
        'تموز',
        'آب',
        'أيلول',
        'تشرين أول',
        'تشرين ثاني',
        'كانون أول',
      ];

      final hour24 = dt.hour;
      final period = hour24 >= 12 ? 'م' : 'ص';

      int hour12 = hour24 % 12;
      if (hour12 == 0) hour12 = 12;

      final minute = dt.minute.toString().padLeft(2, '0');

      return '${dt.day} ${months[dt.month - 1]} ${dt.year} · '
          '$hour12:$minute $period';
    } catch (e) {
      return value;
    }
  }

  Future<void> _openZoom(String link) async {
    final uri = Uri.parse(link);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن فتح رابط الاجتماع')),
      );
    }
  }

  Widget _buildBookingCard(dynamic item) {
    final String? zoomLink = item['zoomLink'];
    final bool showZoom = zoomLink != null && zoomLink.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.check_circle_rounded, color: Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['trainerName'] ?? 'مدرب',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDateTime(item['sessionTime']?.toString()),
                      style: const TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'مؤكدة',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (item['description'] != null &&
              (item['description'] as String).isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item['description'],
              style: const TextStyle(fontSize: 13, color: textSecondary),
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
              child: Row(
                children: [
                  const Icon(Icons.videocam_outlined,
                      size: 17, color: Color(0xFF3760B9)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => _openZoom(zoomLink),
                      child: const Text(
                        'اضغط للدخول إلى الاجتماع مع المدرب',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF3760B9),
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          title: const Text('طلباتي المؤكدة',
              style: TextStyle(fontWeight: FontWeight.w800)),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: gold))
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: textSecondary, fontSize: 14),
                      ),
                    ),
                  )
                : _bookings.isEmpty
                    ? const Center(
                        child: Text(
                          'لا يوجد طلبات مؤكدة حالياً',
                          style: TextStyle(color: textSecondary, fontSize: 15),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchConfirmedBookings,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _bookings.length,
                          itemBuilder: (context, index) =>
                              _buildBookingCard(_bookings[index]),
                        ),
                      ),
      ),
    );
  }
}
