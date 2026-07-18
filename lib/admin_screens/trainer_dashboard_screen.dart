import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'trainer_login_screen.dart';

class TrainerDashboardScreen extends StatefulWidget {
  const TrainerDashboardScreen({super.key});

  @override
  State<TrainerDashboardScreen> createState() => _TrainerDashboardScreenState();
}

class _TrainerDashboardScreenState extends State<TrainerDashboardScreen> {
  // غيّر هاد الرابط لرابط الباك اند تبعك
  static const String _baseUrl = 'https://wanees-backend-2026.onrender.com';

  static const Color navy = Color(0xFF14213D);
  static const Color navyDark = Color(0xFF0D1830);
  static const Color gold = Color(0xFFE3B23C);
  static const Color background = Color(0xFFF6F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3DFD5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B67);
  static const Color unavailable = Color(0xFF8C3D2A);
  String trainerName = '';
  bool isLoading = true;
  int _selectedIndex = 0; // 0 = حسابي, 1 = جلساتي, 2 = تقاريري
  List<dynamic> _sessions = [];
  bool _isLoadingSessions = false;
  bool _isLoadingReport = false;
  double platformAmount = 0;
  double trainerAmount = 0;
  int totalSessions = 0;
  int paidSessions = 0;
  int unpaidSessions = 0;
  double totalAmount = 0;

  DateTime? fromDate;
  DateTime? toDate;

  // ── تقرير "جلسات بكودي" ──
  String _reportMode = 'mine'; // 'mine' أو 'byCode'
  bool _isLoadingByCodeReport = false;
  List<dynamic> _byCodeActivities = [];
  double _byCodeTotalAmount = 0;
  double _byCodePlatformShare = 0;
  int _byCodeTotalCount = 0;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _balanceController = TextEditingController();
  final _paymentsCountController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isAvailable = true;
  bool _isBusy = false;
  String _imageUrl = '';
  bool _isUploadingImage = false;
  bool _isSavingProfile = false;

  bool _isSidebarCollapsed = false;
  @override
  void initState() {
    super.initState();
    loadTrainerData();
    _fetchSessions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _newPasswordController.dispose();
    _balanceController.dispose();
    _paymentsCountController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _fetchReport() async {
    final token = await _getToken();

    if (token == null) return;

    setState(() {
      _isLoadingReport = true;
    });

    String url = '$_baseUrl/api/trainers/report';

    if (fromDate != null || toDate != null) {
      url += '?';

      if (fromDate != null) {
        url += 'from=${fromDate!.toIso8601String()}';
      }

      if (toDate != null) {
        if (fromDate != null) url += '&';
        url += 'to=${toDate!.toIso8601String()}';
      }
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          totalSessions = data['totalCount'] ?? 0;
          paidSessions = data['paidCount'] ?? 0;
          unpaidSessions = data['unpaidCount'] ?? 0;

          totalAmount = (data['totalAmount'] ?? 0).toDouble();

          trainerAmount = totalAmount * 0.8;
          platformAmount = totalAmount * 0.2;
        });
      }
    } catch (e) {
      print("REPORT ERROR $e");
    }

    setState(() {
      _isLoadingReport = false;
    });
  }

  // ── تقرير "جلسات بكودي" ──
  Future<void> _fetchReportByCode() async {
    final token = await _getToken();
    if (token == null) return;

    setState(() {
      _isLoadingByCodeReport = true;
    });

    String url = '$_baseUrl/api/trainers/report-by-code';

    if (fromDate != null || toDate != null) {
      url += '?';
      if (fromDate != null) {
        url += 'from=${fromDate!.toIso8601String()}';
      }
      if (toDate != null) {
        if (fromDate != null) url += '&';
        url += 'to=${toDate!.toIso8601String()}';
      }
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _byCodeActivities = data['activities'] ?? [];
          _byCodeTotalAmount = (data['totalAmount'] ?? 0).toDouble();
          _byCodePlatformShare = (data['platformShare'] ?? 0).toDouble();
          _byCodeTotalCount = data['totalCount'] ?? 0;
        });
      }
    } catch (e) {
      print("BY CODE REPORT ERROR $e");
    }

    setState(() {
      _isLoadingByCodeReport = false;
    });
  }

  void _refreshCurrentReport() {
    if (_reportMode == 'mine') {
      _fetchReport();
    } else {
      _fetchReportByCode();
    }
  }

  Future<void> _openZoom(String link) async {
    final uri = Uri.parse(link);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكن فتح رابط زوم'),
        ),
      );
    }
  }

  Future<void> _fetchSessions() async {
    final token = await _getToken();

    if (token == null) {
      return;
    }

    setState(() {
      _isLoadingSessions = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/bookings/trainer'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List sessions = data['activities'] ?? [];

        sessions.sort((a, b) => DateTime.parse(b['createdAt'])
            .compareTo(DateTime.parse(a['createdAt'])));

        if (!mounted) return;

        setState(() {
          _sessions = sessions;
          _isLoadingSessions = false;
        });
      } else {
        setState(() {
          _isLoadingSessions = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingSessions = false;
      });

      print("SESSIONS ERROR: $e");
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('trainer_token');
  }

  Future<void> loadTrainerData() async {
    final token = await _getToken();

    if (token == null) {
      goToLogin();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/trainers/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final trainer = data['trainer'];

        setState(() {
          trainerName = trainer['name'] ?? 'مدرب';
          _nameController.text = trainer['name'] ?? '';
          _phoneController.text = trainer['phone'] ?? '';
          _descriptionController.text = trainer['description'] ?? '';
          _priceController.text = (trainer['price'] ?? 0).toString();
          _durationController.text = (trainer['duration'] ?? 60).toString();
          _isAvailable = trainer['isAvailable'] ?? true;
          _isBusy = trainer['isBusy'] ?? false;
          _balanceController.text = (trainer['balance'] ?? 0).toString();
          _paymentsCountController.text =
              (trainer['paymentsCount'] ?? 0).toString();
          _codeController.text = trainer['code'] ?? '';
          _imageUrl = trainer['imageUrl'] ?? '';
          isLoading = false;
        });
      } else {
        // التوكن غير صالح أو منتهي
        goToLogin();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('ما قدرنا نجيب بيانات حسابك، تأكد من الاتصال بالنت')),
      );
    }
  }

  String formatDateTime(String? value) {
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

  // ── اختيار صورة من الجهاز ورفعها مباشرة لـ Cloudinary عبر راوت /upload ──
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final bytes = await picked.readAsBytes();
      final request =
          http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload'));
      request.files.add(
        http.MultipartFile.fromBytes('image', bytes, filename: picked.name),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _imageUrl = data['url'];
          _isUploadingImage = false;
        });
      } else {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل رفع الصورة، حاول مرة ثانية')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('صار خطأ أثناء رفع الصورة')),
      );
    }
  }

  // ── حفظ التعديلات بالداتا بيز ──
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final token = await _getToken();
    if (token == null) {
      goToLogin();
      return;
    }

    setState(() => _isSavingProfile = true);

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/trainers/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'imageUrl': _imageUrl,
          'description': _descriptionController.text.trim(),
          'price': double.tryParse(_priceController.text.trim()) ?? 0,
          'duration': int.tryParse(_durationController.text.trim()) ?? 60,
          'isAvailable': _isAvailable,
          'isBusy': _isBusy,
          'balance': int.tryParse(_balanceController.text.trim()) ?? 0,
          'paymentsCount':
              int.tryParse(_paymentsCountController.text.trim()) ?? 0,
          'code': _codeController.text.trim(),
          if (_newPasswordController.text.trim().isNotEmpty)
            'password': _newPasswordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;
      setState(() => _isSavingProfile = false);

      if (response.statusCode == 200) {
        setState(() => trainerName = _nameController.text.trim());
        _newPasswordController
            .clear(); // ما نخلي كلمة المرور تنبعت مرة ثانية بالغلط
        // حدّث الاسم المخزن محلياً كمان (يستخدم بالسايد بار وشاشات تانية)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('trainer_name', _nameController.text.trim());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ التعديلات بنجاح')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'صار خطأ أثناء الحفظ')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('ما قدرنا نوصل للسيرفر، تأكد من الاتصال بالنت')),
      );
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('trainer_token');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const TrainerLoginScreen()),
      (route) => false,
    );
  }

  void goToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const TrainerLoginScreen()),
      (route) => false,
    );
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

  // ── محتوى تاب "تقاريري" ──
  Widget _buildReportContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "تقاريري",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // ── القائمة المنسدلة لاختيار نوع التقرير ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _reportMode,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: const [
                  DropdownMenuItem(value: 'mine', child: Text('جلساتي')),
                  DropdownMenuItem(value: 'byCode', child: Text('جلسات بكودي')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _reportMode = value);
                  _refreshCurrentReport();
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    fromDate = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDate: DateTime.now(),
                    );

                    _refreshCurrentReport();
                  },
                  child: Text(fromDate == null
                      ? "من تاريخ"
                      : "${fromDate!.year}-${fromDate!.month}-${fromDate!.day}"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    toDate = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDate: DateTime.now(),
                    );

                    _refreshCurrentReport();
                  },
                  child: Text(toDate == null
                      ? "إلى تاريخ"
                      : "${toDate!.year}-${toDate!.month}-${toDate!.day}"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          if (_reportMode == 'mine') ...[
            if (_isLoadingReport) const CircularProgressIndicator(),
            Card(
              child: ListTile(
                title: const Text("عدد الجلسات"),
                trailing: Text("$totalSessions"),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("الجلسات المدفوعة"),
                trailing: Text("$paidSessions"),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("الجلسات غير المدفوعة"),
                trailing: Text("$unpaidSessions"),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("إجمالي الإيرادات"),
                trailing: Text("$totalAmount ₪"),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("صافي مستحقات المدرب"),
                subtitle: const Text("80% من الإيرادات"),
                trailing: Text(
                  "${trainerAmount.toStringAsFixed(2)} ₪",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("مستحقات المنصة"),
                subtitle: const Text("20% من الإيرادات"),
                trailing: Text(
                  "${platformAmount.toStringAsFixed(2)} ₪",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ] else ...[
            if (_isLoadingByCodeReport) const CircularProgressIndicator(),
            Card(
              child: ListTile(
                title: const Text("عدد الجلسات"),
                trailing: Text("$_byCodeTotalCount"),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("إجمالي المبلغ"),
                trailing: Text("$_byCodeTotalAmount ₪"),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("نسبة المنصة"),
                subtitle: const Text("20% من الإيرادات"),
                trailing: Text(
                  "${_byCodePlatformShare.toStringAsFixed(2)} ₪",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (!_isLoadingByCodeReport && _byCodeActivities.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'ما في جلسات بهذا الكود',
                    style: TextStyle(color: textSecondary),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _byCodeActivities.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = _byCodeActivities[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['customerName'] ?? 'مستخدم غير معروف',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatDateTime(item['sessionTime']?.toString()),
                                style: const TextStyle(
                                    fontSize: 12, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "${item['paidAmount'] ?? 0} ₪",
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, color: navy),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('حسابي',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textPrimary)),
            const SizedBox(height: 4),
            const Text('عدّل بيانات ملفك الشخصي كمدرب',
                style: TextStyle(fontSize: 13, color: textSecondary)),
            const SizedBox(height: 24),

            // ── الصورة الشخصية + زر الرفع ──
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: border,
                          image: _imageUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(_imageUrl),
                                  fit: BoxFit.cover)
                              : null,
                        ),
                        child: _imageUrl.isEmpty
                            ? const Icon(Icons.person_rounded,
                                color: textSecondary, size: 46)
                            : null,
                      ),
                      InkWell(
                        onTap: _isUploadingImage ? null : _pickAndUploadImage,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                              color: navy, shape: BoxShape.circle),
                          child: _isUploadingImage
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.camera_alt_rounded,
                                  color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('اضغط الكاميرا لتغيير الصورة',
                      style: TextStyle(fontSize: 12, color: textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 28),

            const Text('الاسم الكامل',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration:
                  _fieldDecoration('اسمك', Icons.person_outline_rounded),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
            ),
            const SizedBox(height: 16),

            const Text('رقم الهاتف',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration:
                  _fieldDecoration('05X XXX XXXX', Icons.phone_outlined),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'رقم الهاتف مطلوب' : null,
            ),
            const SizedBox(height: 16),

            const Text('الوصف',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: _fieldDecoration(
                  'اكتب نبذة عن خبرتك وتخصصك...', Icons.notes_rounded),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الأجرة (₪)',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration:
                            _fieldDecoration('25', Icons.payments_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('المدة (دقيقة)',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration:
                            _fieldDecoration('60', Icons.timer_outlined),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('متاح لاستقبال حجوزات؟',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  Switch(
                    value: _isAvailable,
                    activeThumbColor: navy,
                    onChanged: (v) => setState(() => _isAvailable = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── التحكم بالانشغال ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isBusy ? 'الحالة: مشغول' : 'الحالة: فعال',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Switch(
                    value: _isBusy,
                    activeThumbColor: unavailable,
                    onChanged: (v) => setState(() => _isBusy = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الرصيد',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _balanceController,
                        readOnly: true,
                        keyboardType: TextInputType.number,
                        decoration: _fieldDecoration(
                            '0', Icons.account_balance_wallet_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('عدد الدفعات',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _paymentsCountController,
                        readOnly: true,
                        keyboardType: TextInputType.number,
                        decoration:
                            _fieldDecoration('0', Icons.receipt_long_outlined),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text('الكود',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _codeController,
              readOnly: true,
              decoration: _fieldDecoration('كود المدرب', Icons.qr_code_rounded),
            ),
            const SizedBox(height: 24),

            const Divider(color: border),
            const SizedBox(height: 16),

            const Text('تغيير كلمة المرور',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('اتركه فارغاً إذا ما بدك تغيّرها',
                style: TextStyle(fontSize: 11.5, color: textSecondary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: _fieldDecoration(
                  'كلمة مرور جديدة', Icons.lock_outline_rounded),
              validator: (v) {
                if (v == null || v.isEmpty) return null; // اختياري
                if (v.length < 6) return 'كلمة المرور 6 أحرف على الأقل';
                return null;
              },
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSavingProfile ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSavingProfile
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.white))
                    : const Text('حفظ التعديلات',
                        style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── محتوى تاب "جلساتي" ──
  Widget _buildSessionsContent() {
    if (_isLoadingSessions) {
      return const Center(
        child: CircularProgressIndicator(color: gold),
      );
    }

    if (_sessions.isEmpty) {
      return const Center(
        child: Text(
          'لا يوجد جلسات حالياً',
          style: TextStyle(
            color: textSecondary,
            fontSize: 15,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchSessions,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _sessions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _sessions[index];
          final String? zoomLink = item['zoomLink'];
          final status = item['status'] ?? 'pending';
          final String activityId = item['_id'];
          final bool showZoom = zoomLink != null &&
              zoomLink.isNotEmpty &&
              status != 'rejected' &&
              status != 'cancelled';

          Color statusColor;
          String statusLabel;

          switch (status) {
            case 'approved':
              statusColor = Colors.green;
              statusLabel = 'مؤكدة';
              break;

            case 'completed':
              statusColor = navy;
              statusLabel = 'منتهية';
              break;

            case 'rejected':
              statusColor = unavailable;
              statusLabel = 'مرفوضة';
              break;

            case 'cancelled':
              statusColor = unavailable;
              statusLabel = 'ملغاة';
              break;

            default:
              statusColor = Colors.orange;
              statusLabel = 'قيد الانتظار';
          }

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
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: .1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item['customerName'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item['description'] ?? '',
                  style: const TextStyle(
                    color: Color.fromARGB(255, 255, 3, 3),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatDateTime(item['sessionTime']?.toString()),
                  style: const TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                if (showZoom) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.videocam_outlined,
                          size: 17,
                          color: Color.fromARGB(255, 55, 96, 185),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => _openZoom(zoomLink),
                            child: Text(
                              'اضغط للدخول الى الاجتماع مع طالب الخدمة',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color.fromARGB(255, 60, 98, 181),
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ],

                // ── أزرار التحكم: قبول / إلغاء / حذف ──
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (status != 'approved' && status != 'completed')
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await _updateActivityStatus(
                              activityId,
                              'approved',
                            );
                          },
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: 18,
                          ),
                          label: const Text(
                            'قبول',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.green),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    if (status != 'approved' && status != 'completed')
                      const SizedBox(width: 10),
                    if (status != 'approved' &&
                        status != 'cancelled' &&
                        status != 'rejected' &&
                        status != 'completed')
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await _updateActivityStatus(
                              activityId,
                              status == 'pending' ? 'rejected' : 'cancelled',
                            );
                          },
                          icon: const Icon(
                            Icons.cancel_outlined,
                            color: unavailable,
                            size: 18,
                          ),
                          label: Text(
                            status == 'pending' ? 'رفض' : 'إلغاء',
                            style: const TextStyle(
                              color: unavailable,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: unavailable),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    if (status != 'approved' &&
                        status != 'cancelled' &&
                        status != 'rejected' &&
                        status != 'completed')
                      const SizedBox(width: 10),
                    InkWell(
                      onTap: () => _confirmDelete(activityId),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          border: Border.all(color: border),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sidebarItem(
      {required IconData icon, required String label, required int index}) {
    final bool selected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? gold.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: selected ? gold : Colors.white70),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: background,
        body: Center(child: CircularProgressIndicator(color: gold)),
      );
    }

    return Scaffold(
      backgroundColor: background,
      body: Column(
        children: [
          // ── الشريط العلوي — فيه أيقونة الهمبرغر ──
          Container(
            height: 56,
            color: navyDark,
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  InkWell(
                    onTap: () => setState(
                        () => _isSidebarCollapsed = !_isSidebarCollapsed),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Icon(Icons.menu_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(trainerName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // ── السايد بار ──
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: _isSidebarCollapsed ? 0 : 220,
                  color: navyDark,
                  child: _isSidebarCollapsed
                      ? null
                      : ClipRect(
                          child: SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: MediaQuery.of(context).size.height -
                                    56 -
                                    MediaQuery.of(context).padding.top,
                              ),
                              child: IntrinsicHeight(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 20),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 52,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color:
                                                  gold.withValues(alpha: 0.2),
                                              image: _imageUrl.isNotEmpty
                                                  ? DecorationImage(
                                                      image: NetworkImage(
                                                          _imageUrl),
                                                      fit: BoxFit.cover)
                                                  : null,
                                            ),
                                            child: _imageUrl.isEmpty
                                                ? const Icon(
                                                    Icons
                                                        .fitness_center_rounded,
                                                    color: gold,
                                                    size: 24)
                                                : null,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            trainerName,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          const Text('مدرب',
                                              style: TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    const Divider(
                                        color: Colors.white12, height: 1),
                                    const SizedBox(height: 12),
                                    _sidebarItem(
                                        icon: Icons.person_outline_rounded,
                                        label: 'حسابي',
                                        index: 0),
                                    _sidebarItem(
                                        icon: Icons.event_note_outlined,
                                        label: 'جلساتي',
                                        index: 1),
                                    _sidebarItem(
                                      icon: Icons.bar_chart,
                                      label: 'تقاريري',
                                      index: 2,
                                    ),
                                    const Spacer(),
                                    const Divider(
                                        color: Colors.white12, height: 1),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: InkWell(
                                        onTap: logout,
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 13),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.logout_rounded,
                                                  size: 20,
                                                  color: Colors.white70),
                                              SizedBox(width: 12),
                                              Text('تسجيل الخروج',
                                                  style: TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                            ],
                                          ),
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
                Expanded(
                  child: SafeArea(
                    top: false,
                    child: _selectedIndex == 0
                        ? _buildAccountContent()
                        : _selectedIndex == 1
                            ? _buildSessionsContent()
                            : _buildReportContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateActivityStatus(String id, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('trainer_token');

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/bookings/trainer/$id/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': status,
          'actionBy': 'trainer',
        }),
      );

      if (response.statusCode == 200) {
        await _fetchSessions(); // أو دالة جلب النشاطات التي عندك
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء تحديث الحالة'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ما قدرنا نوصل للسيرفر، تأكد من الاتصال بالنت'),
        ),
      );
    }
  }

  // ── حذف جلسة نهائياً ──
  Future<void> _deleteActivity(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('trainer_token');

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/bookings/trainer/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _sessions.removeWhere((item) => item['_id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الجلسة')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء حذف الجلسة')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ما قدرنا نوصل للسيرفر')),
      );
    }
  }

  // ── تأكيد الحذف قبل التنفيذ ──
  Future<void> _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'تأكيد الحذف',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'متأكد إنك بدك تحذف هاي الجلسة؟ هاد الإجراء ما ممكن يترجع.',
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'حذف',
              style: TextStyle(
                color: unavailable,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteActivity(id);
    }
  }
}
