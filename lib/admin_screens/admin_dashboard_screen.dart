import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// لوحة تحكم الأدمن — سايد بار + كل الأقسام بنفس الملف
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const String _baseUrl = 'https://wanees-backend-2026.onrender.com';

  static const Color navy = Color(0xFF14213D);
  static const Color navyDark = Color(0xFF0D1830);
  static const Color gold = Color(0xFFE3B23C);
  static const Color background = Color(0xFFF6F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3DFD5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B67);
  static const Color available = Color(0xFF2F7A57);
  static const Color unavailable = Color(0xFF8C3D2A);

  static const Map<String, String> _roleLabels = {
    'full': 'كامل الصلاحية',
    'editor': 'محرر',
    'viewer': 'متابع',
  };

  bool _isChecking = true;
  String? _token;
  String _role = 'viewer';
  final String _adminName = '';
  int _selectedIndex =
      0; // 0 مدربون, 1 مستخدمون, 2 إعدادات, 3 طلبات, 4 إحصائيات

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('admin_token');
    final role = prefs.getString('admin_role');

    if (token == null || token.isEmpty || role == null || role.isEmpty) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/admin-login');
      return;
    }

    if (!mounted) return;
    setState(() {
      _token = token;
      _role = role;
      _isChecking = false;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_token');
    await prefs.remove('admin_role');
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/admin-login');
  }

  bool get _canEdit => _role == 'full' || _role == 'editor';

  bool _isSidebarCollapsed = false;
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
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: background,
        body: Center(child: CircularProgressIndicator(color: navy)),
      );
    }

    final sections = <Widget>[
      _TrainersSection(baseUrl: _baseUrl, token: _token!, canEdit: _canEdit),
      _UsersSection(baseUrl: _baseUrl, token: _token!, canEdit: _canEdit),
      _SettingsSection(baseUrl: _baseUrl, token: _token!),
      _RequestsSection(baseUrl: _baseUrl, token: _token!, canEdit: _canEdit),
      _StatsSection(baseUrl: _baseUrl, token: _token!),
      if (_role == 'full') _AdminsSection(baseUrl: _baseUrl, token: _token!),
      if (_role == 'full')
        _ReportsSection(
          baseUrl: _baseUrl,
          token: _token!,
        ),
    ];

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
                  const Text('لوحة تحكم الأدمن',
                      style: TextStyle(
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
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: _isSidebarCollapsed ? 0 : 230,
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
                                                color:
                                                    gold.withValues(alpha: 0.2),
                                                shape: BoxShape.circle),
                                            child: const Icon(
                                                Icons
                                                    .admin_panel_settings_rounded,
                                                color: gold,
                                                size: 26),
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20)),
                                            child: Text(
                                              _roleLabels[_role] ?? _role,
                                              style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    const Divider(
                                        color: Colors.white12, height: 1),
                                    const SizedBox(height: 12),
                                    _sidebarItem(
                                        icon: Icons.groups_outlined,
                                        label: 'المدربون',
                                        index: 0),
                                    _sidebarItem(
                                        icon: Icons.people_alt_outlined,
                                        label: 'المستخدمون',
                                        index: 1),
                                    _sidebarItem(
                                        icon: Icons.settings_outlined,
                                        label: 'الإعدادات',
                                        index: 2),
                                    _sidebarItem(
                                        icon: Icons.receipt_long_outlined,
                                        label: 'الطلبات',
                                        index: 3),
                                    _sidebarItem(
                                        icon: Icons.bar_chart_rounded,
                                        label: 'الإحصائيات',
                                        index: 4),
                                    if (_role == 'full')
                                      _sidebarItem(
                                          icon: Icons
                                              .admin_panel_settings_outlined,
                                          label: 'الأدمنز',
                                          index: 5),
                                    if (_role == 'full')
                                      _sidebarItem(
                                          icon: Icons.book,
                                          label: 'التقارير',
                                          index: 6),
                                    const Spacer(),
                                    const Divider(
                                        color: Colors.white12, height: 1),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: InkWell(
                                        onTap: _logout,
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
                  child: SafeArea(top: false, child: sections[_selectedIndex]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsSection extends StatefulWidget {
  final String baseUrl;
  final String token;

  const _ReportsSection({
    required this.baseUrl,
    required this.token,
  });

  @override
  State<_ReportsSection> createState() => _ReportsSectionState();
}

class _ReportsSectionState extends State<_ReportsSection> {
  String type = "trainer";
  // 'entity' = تقرير الشخص نفسه (الموجود سابقاً)، 'byCode' = جلسات بالكود
  String reportMode = "entity";
  DateTime? fromDate;
  DateTime? toDate;
  List<dynamic> people = [];
  dynamic selectedPerson;

  Map<String, dynamic>? report;
  bool isLoadingReport = false;

  Future<void> loadPeople() async {
    final url = type == "trainer" ? "/api/admin/trainers" : "/api/admin/users";

    final response = await http.get(
      Uri.parse(widget.baseUrl + url),
      headers: {"Authorization": "Bearer ${widget.token}"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        people = type == "trainer" ? data["trainers"] : data["users"];
      });
    }
  }

  Future<void> pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });

      if (selectedPerson != null) {
        _refreshReport();
      }
    }
  }

  void _refreshReport() {
    if (selectedPerson == null) return;

    if (reportMode == "entity") {
      getReport(selectedPerson["_id"]);
    } else {
      getReportByCode(selectedPerson["_id"]);
    }
  }

  Future<void> getReport(String id) async {
    setState(() => isLoadingReport = true);

    String url = "${widget.baseUrl}/api/admin/report?type=$type&id=$id";

    if (fromDate != null) {
      url += "&from=${DateFormat('yyyy-MM-dd').format(fromDate!)}";
    }

    if (toDate != null) {
      url += "&to=${DateFormat('yyyy-MM-dd').format(toDate!)}";
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      if (response.statusCode == 200) {
        setState(() {
          report = jsonDecode(response.body);
        });
      }
    } finally {
      if (mounted) setState(() => isLoadingReport = false);
    }
  }

  // ── تقرير "جلسات بالكود" — بس للمدربين ──
  Future<void> getReportByCode(String trainerId) async {
    setState(() => isLoadingReport = true);

    String url =
        "${widget.baseUrl}/api/admin/report-by-code?trainerId=$trainerId";

    if (fromDate != null) {
      url += "&from=${DateFormat('yyyy-MM-dd').format(fromDate!)}";
    }

    if (toDate != null) {
      url += "&to=${DateFormat('yyyy-MM-dd').format(toDate!)}";
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      if (response.statusCode == 200) {
        setState(() {
          report = jsonDecode(response.body);
        });
      }
    } finally {
      if (mounted) setState(() => isLoadingReport = false);
    }
  }

  @override
  void initState() {
    super.initState();

    loadPeople();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "التقارير المالية",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 15,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(
                  fromDate == null
                      ? "من تاريخ"
                      : DateFormat('yyyy-MM-dd').format(fromDate!),
                ),
                onPressed: () {
                  pickDate(true);
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(
                  toDate == null
                      ? "إلى تاريخ"
                      : DateFormat('yyyy-MM-dd').format(toDate!),
                ),
                onPressed: () {
                  pickDate(false);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 15,
            runSpacing: 10,
            children: [
              ChoiceChip(
                label: const Text("المدربون"),
                selected: type == "trainer",
                onSelected: (v) {
                  setState(() {
                    type = "trainer";
                    reportMode = "entity";
                    report = null;
                    selectedPerson = null;
                  });

                  loadPeople();
                },
              ),
              ChoiceChip(
                label: const Text("المستخدمون"),
                selected: type == "user",
                onSelected: (v) {
                  setState(() {
                    type = "user";
                    reportMode = "entity";
                    report = null;
                    selectedPerson = null;
                  });

                  loadPeople();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: DropdownButton<dynamic>(
              hint: const Text("اختر الشخص"),
              value: selectedPerson,
              isExpanded: true,
              items: people.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(p["name"] ?? p["username"] ?? ""),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedPerson = value);
                _refreshReport();
              },
            ),
          ),

          // ── خيار "جلسات بالكود" — يظهر بس لما يكون النوع "مدرب" وفي شخص مختار ──
          if (type == "trainer" && selectedPerson != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 15,
              runSpacing: 10,
              children: [
                ChoiceChip(
                  label: const Text("جلسات المدرب"),
                  selected: reportMode == "entity",
                  onSelected: (v) {
                    setState(() => reportMode = "entity");
                    _refreshReport();
                  },
                ),
                ChoiceChip(
                  label: const Text("جلسات بالكود"),
                  selected: reportMode == "byCode",
                  onSelected: (v) {
                    setState(() => reportMode = "byCode");
                    _refreshReport();
                  },
                ),
              ],
            ),
          ],

          const SizedBox(height: 30),
          if (isLoadingReport) const Center(child: CircularProgressIndicator()),
          if (report != null && !isLoadingReport) ...[
            Wrap(
              spacing: 15,
              runSpacing: 10,
              children: [
                _card("عدد الجلسات", report!["totalCount"].toString()),
                if (reportMode == "entity")
                  _card("المدفوع", report!["paidCount"].toString()),
                _card("الإيرادات", "${report!["totalAmount"]} ₪"),
                if (reportMode == "byCode")
                  _card("نسبة المنصة (20%)",
                      "${(report!["platformShare"] as num).toStringAsFixed(2)} ₪"),
              ],
            ),
            const SizedBox(height: 25),
            const Text(
              "العمليات المالية",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            report!["activities"].isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text("ما في جلسات مطابقة"),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: report!["activities"].length,
                    itemBuilder: (context, index) {
                      final a = report!["activities"][index];

                      return Card(
                        child: ListTile(
                          title: Text(a["customerName"] ?? ""),
                          subtitle: Text(a["status"] ?? ""),
                          trailing: Text("${a["paidAmount"] ?? 0} ₪"),
                        ),
                      );
                    },
                  ),
          ],
        ],
      ),
    );
  }

  Widget _card(String title, String value) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// قسم "المدربون" — قائمة + بحث حي + تعديل أي مدرب
// ═══════════════════════════════════════════
class _TrainersSection extends StatefulWidget {
  final String baseUrl;
  final String token;
  final bool canEdit;
  const _TrainersSection(
      {required this.baseUrl, required this.token, required this.canEdit});

  @override
  State<_TrainersSection> createState() => _TrainersSectionState();
}

class _TrainersSectionState extends State<_TrainersSection> {
  static const Color navy = Color(0xFF14213D);
  static const Color gold = Color(0xFFE3B23C);
  static const Color background = Color(0xFFF6F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3DFD5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B67);
  static const Color available = Color(0xFF2F7A57);
  static const Color unavailable = Color(0xFF8C3D2A);

  List<dynamic> _trainers = [];
  bool _isLoading = true;
  Timer? _debounce;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTrainers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchTrainers({String search = ''}) async {
    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse('${widget.baseUrl}/api/admin/trainers').replace(
        queryParameters: search.isNotEmpty ? {'search': search} : null,
      );
      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer ${widget.token}'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _trainers = data['trainers'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
        const Duration(milliseconds: 400), () => _fetchTrainers(search: value));
  }

  /// عنصر إحصائية صغير (أيقونة + نص) يُستخدم بصف تفاصيل كل مدرب
  Widget _trainerStat(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: textSecondary),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
              fontSize: 12.5,
              color: textSecondary,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  void _openTrainerEditor(dynamic trainer) {
    showDialog(
      context: context,
      builder: (_) => _TrainerEditDialog(
        baseUrl: widget.baseUrl,
        token: widget.token,
        trainer: trainer,
        canEdit: widget.canEdit,
        onSaved: () => _fetchTrainers(search: _searchController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('المدربون',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textPrimary)),
          const SizedBox(height: 4),
          const Text('عرض وتعديل بيانات كل المدربين',
              style: TextStyle(fontSize: 13, color: textSecondary)),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم أو رقم الهاتف...',
              prefixIcon: const Icon(Icons.search_rounded,
                  color: textSecondary, size: 20),
              filled: true,
              fillColor: surface,
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
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: navy))
                : _trainers.isEmpty
                    ? const Center(
                        child: Text('ما في نتائج',
                            style: TextStyle(color: textSecondary)))
                    : ListView.separated(
                        itemCount: _trainers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final t = _trainers[i];
                          final bool isAvailable = t['isAvailable'] ?? false;
                          final bool isBusy = t['isBusy'] ?? false;
                          final String description = t['description'] ?? '';
                          final String code = t['code'] ?? '';

                          return InkWell(
                            onTap: () => _openTrainerEditor(t),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── الصف الأول: صورة، اسم، هاتف، شارات ──
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 26,
                                        backgroundColor: border,
                                        backgroundImage:
                                            (t['imageUrl'] ?? '').isNotEmpty
                                                ? NetworkImage(t['imageUrl'])
                                                : null,
                                        child: (t['imageUrl'] ?? '').isEmpty
                                            ? const Icon(Icons.person_rounded,
                                                color: textSecondary)
                                            : null,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(t['name'] ?? '',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15)),
                                            const SizedBox(height: 2),
                                            Text(t['phone'] ?? '',
                                                style: const TextStyle(
                                                    color: textSecondary,
                                                    fontSize: 12.5)),
                                          ],
                                        ),
                                      ),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                  color: isAvailable
                                                      ? available
                                                      : unavailable),
                                            ),
                                            child: Text(
                                              isAvailable ? 'متاح' : 'غير متاح',
                                              style: TextStyle(
                                                  color: isAvailable
                                                      ? available
                                                      : unavailable,
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                          if (isBusy)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                    color: unavailable),
                                              ),
                                              child: const Text('مشغول',
                                                  style: TextStyle(
                                                      color: unavailable,
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.w700)),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.chevron_left_rounded,
                                          color: textSecondary),
                                    ],
                                  ),

                                  // ── الوصف (إذا موجود) ──
                                  if (description.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          color: textSecondary,
                                          height: 1.4),
                                    ),
                                  ],

                                  const SizedBox(height: 12),
                                  const Divider(color: border, height: 1),
                                  const SizedBox(height: 12),

                                  // ── الصف الثاني: كل الأرقام والتفاصيل ──
                                  Wrap(
                                    spacing: 18,
                                    runSpacing: 8,
                                    children: [
                                      _trainerStat(Icons.payments_outlined,
                                          '${t['price'] ?? 0} ₪ / جلسة'),
                                      _trainerStat(Icons.timer_outlined,
                                          '${t['duration'] ?? 60} دقيقة'),
                                      _trainerStat(
                                          Icons.account_balance_wallet_outlined,
                                          'الرصيد: ${t['balance'] ?? 0}'),
                                      _trainerStat(Icons.receipt_long_outlined,
                                          'الدفعات: ${t['paymentsCount'] ?? 0}'),
                                      if (code.isNotEmpty)
                                        _trainerStat(Icons.qr_code_rounded,
                                            'كود: $code'),
                                    ],
                                  ),
                                ],
                              ),
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

// ── مربع تعديل مدرب واحد ──
class _TrainerEditDialog extends StatefulWidget {
  final String baseUrl;
  final String token;
  final dynamic trainer;
  final bool canEdit;
  final VoidCallback onSaved;

  const _TrainerEditDialog({
    required this.baseUrl,
    required this.token,
    required this.trainer,
    required this.canEdit,
    required this.onSaved,
  });

  @override
  State<_TrainerEditDialog> createState() => _TrainerEditDialogState();
}

class _TrainerEditDialogState extends State<_TrainerEditDialog> {
  static const Color navy = Color(0xFF14213D);
  static const Color background = Color(0xFFF6F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3DFD5);
  static const Color textSecondary = Color(0xFF6B6B67);

  late TextEditingController _name;
  late TextEditingController _phone;
  late TextEditingController _description;
  late TextEditingController _price;
  late TextEditingController _duration;
  late TextEditingController _balance;
  late TextEditingController _paymentsCount;
  late TextEditingController _code;
  late bool _isAvailable;
  late bool _isBusy;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.trainer;
    _name = TextEditingController(text: t['name'] ?? '');
    _phone = TextEditingController(text: t['phone'] ?? '');
    _description = TextEditingController(text: t['description'] ?? '');
    _price = TextEditingController(text: (t['price'] ?? 0).toString());
    _duration = TextEditingController(text: (t['duration'] ?? 60).toString());
    _balance = TextEditingController(text: (t['balance'] ?? 0).toString());
    _paymentsCount =
        TextEditingController(text: (t['paymentsCount'] ?? 0).toString());
    _code = TextEditingController(text: t['code'] ?? '');
    _isAvailable = t['isAvailable'] ?? true;
    _isBusy = t['isBusy'] ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _description.dispose();
    _price.dispose();
    _duration.dispose();
    _balance.dispose();
    _paymentsCount.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final response = await http.put(
        Uri.parse(
            '${widget.baseUrl}/api/admin/trainers/${widget.trainer['_id']}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'name': _name.text.trim(),
          'phone': _phone.text.trim(),
          'description': _description.text.trim(),
          'price': double.tryParse(_price.text.trim()) ?? 0,
          'duration': int.tryParse(_duration.text.trim()) ?? 60,
          'balance': int.tryParse(_balance.text.trim()) ?? 0,
          'paymentsCount': int.tryParse(_paymentsCount.text.trim()) ?? 0,
          'code': _code.text.trim(),
          'isAvailable': _isAvailable,
          'isBusy': _isBusy,
        }),
      );

      final data = jsonDecode(response.body);
      if (!mounted) return;
      setState(() => _isSaving = false);

      if (response.statusCode == 200) {
        widget.onSaved();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'صار خطأ أثناء الحفظ')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ما قدرنا نوصل للسيرفر')),
      );
    }
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: background,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: navy, width: 1.4)),
      );

  @override
  Widget build(BuildContext context) {
    final bool readOnly = !widget.canEdit;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 640),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: surface, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('تعديل بيانات المدرب',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                InkWell(
                    onTap: () => Navigator.pop(context),
                    child:
                        const Icon(Icons.close_rounded, color: textSecondary)),
              ],
            ),
            if (readOnly) ...[
              const SizedBox(height: 6),
              const Text('صلاحيتك "متابع" — عرض فقط، ما تقدر تعدل',
                  style: TextStyle(fontSize: 11.5, color: navy)),
            ],
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('الاسم',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: textSecondary)),
                    const SizedBox(height: 4),
                    TextField(
                        controller: _name,
                        enabled: !readOnly,
                        decoration: _dec('الاسم')),
                    const SizedBox(height: 12),
                    const Text('الهاتف',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: textSecondary)),
                    const SizedBox(height: 4),
                    TextField(
                        controller: _phone,
                        enabled: !readOnly,
                        decoration: _dec('الهاتف')),
                    const SizedBox(height: 12),
                    const Text('الوصف',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: textSecondary)),
                    const SizedBox(height: 4),
                    TextField(
                        controller: _description,
                        enabled: !readOnly,
                        maxLines: 2,
                        decoration: _dec('الوصف')),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('الأجرة',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: textSecondary)),
                              const SizedBox(height: 4),
                              TextField(
                                  controller: _price,
                                  enabled: !readOnly,
                                  keyboardType: TextInputType.number,
                                  decoration: _dec('الأجرة')),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('المدة (د)',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: textSecondary)),
                              const SizedBox(height: 4),
                              TextField(
                                  controller: _duration,
                                  enabled: !readOnly,
                                  keyboardType: TextInputType.number,
                                  decoration: _dec('المدة (د)')),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('الرصيد',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: textSecondary)),
                              const SizedBox(height: 4),
                              TextField(
                                  controller: _balance,
                                  enabled: !readOnly,
                                  keyboardType: TextInputType.number,
                                  decoration: _dec('الرصيد')),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('عدد الدفعات',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: textSecondary)),
                              const SizedBox(height: 4),
                              TextField(
                                  controller: _paymentsCount,
                                  enabled: !readOnly,
                                  keyboardType: TextInputType.number,
                                  decoration: _dec('عدد الدفعات')),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('الكود',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: textSecondary)),
                    const SizedBox(height: 4),
                    TextField(
                        controller: _code,
                        enabled: !readOnly,
                        decoration: _dec('الكود')),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Expanded(
                            child: Text('متاح للحجز',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600))),
                        Switch(
                            value: _isAvailable,
                            activeThumbColor: navy,
                            onChanged: readOnly
                                ? null
                                : (v) => setState(() => _isAvailable = v)),
                      ],
                    ),
                    Row(
                      children: [
                        const Expanded(
                            child: Text('مشغول',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600))),
                        Switch(
                            value: _isBusy,
                            activeThumbColor: navy,
                            onChanged: readOnly
                                ? null
                                : (v) => setState(() => _isBusy = v)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (!readOnly) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.2, color: Colors.white))
                      : const Text('حفظ التعديلات'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// قسم "المستخدمون" — قائمة + بحث حي + تعديل أي مستخدم
// ═══════════════════════════════════════════
class _UsersSection extends StatefulWidget {
  final String baseUrl;
  final String token;
  final bool canEdit;
  const _UsersSection(
      {required this.baseUrl, required this.token, required this.canEdit});

  @override
  State<_UsersSection> createState() => _UsersSectionState();
}

class _UsersSectionState extends State<_UsersSection> {
  static const Color navy = Color(0xFF14213D);
  static const Color gold = Color(0xFFE3B23C);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3DFD5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B67);

  List<dynamic> _users = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 50;
  String _currentSearch = '';
  Timer? _debounce;
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _fetchUsers(search: _currentSearch, loadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchUsers({String search = '', bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasMore = true;
        _currentSearch = search;
      });
    }

    try {
      final page = loadMore ? _currentPage + 1 : 1;

      final uri = Uri.parse('${widget.baseUrl}/api/admin/users').replace(
        queryParameters: {
          if (search.isNotEmpty) 'search': search,
          'page': page.toString(),
          'limit': _pageSize.toString(),
        },
      );

      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer ${widget.token}'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> newUsers = data['users'] ?? [];

        setState(() {
          if (loadMore) {
            _users.addAll(newUsers);
            _currentPage = page;
          } else {
            _users = newUsers;
          }
          _hasMore = newUsers.length == _pageSize;
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
        const Duration(milliseconds: 400), () => _fetchUsers(search: value));
  }

  /// عنصر إحصائية صغير (أيقونة + نص) يُستخدم بصف تفاصيل كل مستخدم
  Widget _userStat(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: textSecondary),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
              fontSize: 12.5,
              color: textSecondary,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  void _openUserEditor(dynamic user) {
    showDialog(
      context: context,
      builder: (_) => _UserEditDialog(
        baseUrl: widget.baseUrl,
        token: widget.token,
        user: user,
        canEdit: widget.canEdit,
        onSaved: () => _fetchUsers(search: _searchController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('المستخدمون',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textPrimary)),
          const SizedBox(height: 4),
          const Text('عرض وتعديل بيانات كل المستخدمين',
              style: TextStyle(fontSize: 13, color: textSecondary)),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم أو رقم الجوال أو الإيميل...',
              prefixIcon: const Icon(Icons.search_rounded,
                  color: textSecondary, size: 20),
              filled: true,
              fillColor: surface,
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
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: navy))
                : _users.isEmpty
                    ? const Center(
                        child: Text('ما في نتائج',
                            style: TextStyle(color: textSecondary)))
                    : ListView.separated(
                        controller: _scrollController,
                        itemCount: _users.length + (_hasMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          if (i == _users.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                  child:
                                      CircularProgressIndicator(color: navy)),
                            );
                          }

                          final u = _users[i];
                          final String email = u['email'] ?? '';
                          final num rating = (u['rating'] ?? 0) is num
                              ? (u['rating'] ?? 0)
                              : 0;
                          final List<dynamic> favoriteTrainers =
                              u['favoriteTrainers'] ?? [];

                          return InkWell(
                            onTap: () => _openUserEditor(u),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── الصف الأول: صورة، اسم، هاتف ──
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 26,
                                        backgroundColor: border,
                                        backgroundImage:
                                            (u['imageUrl'] ?? '').isNotEmpty
                                                ? NetworkImage(u['imageUrl'])
                                                : null,
                                        child: (u['imageUrl'] ?? '').isEmpty
                                            ? const Icon(Icons.person_rounded,
                                                color: textSecondary)
                                            : null,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(u['name'] ?? '',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15)),
                                            const SizedBox(height: 2),
                                            Text(u['phone'] ?? '',
                                                style: const TextStyle(
                                                    color: textSecondary,
                                                    fontSize: 12.5)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(color: gold),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.star_rounded,
                                                size: 14, color: gold),
                                            const SizedBox(width: 3),
                                            Text(
                                              rating.toStringAsFixed(1),
                                              style: const TextStyle(
                                                  color: navy,
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.chevron_left_rounded,
                                          color: textSecondary),
                                    ],
                                  ),

                                  // ── الإيميل (إذا موجود) ──
                                  if (email.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          color: textSecondary,
                                          height: 1.4),
                                    ),
                                  ],

                                  const SizedBox(height: 12),
                                  const Divider(color: border, height: 1),
                                  const SizedBox(height: 12),

                                  // ── الصف الثاني: كل الأرقام والتفاصيل ──
                                  Wrap(
                                    spacing: 18,
                                    runSpacing: 8,
                                    children: [
                                      _userStat(
                                          Icons.account_balance_wallet_outlined,
                                          'الرصيد: ${u['balance'] ?? 0}'),
                                      _userStat(Icons.event_available_outlined,
                                          'الجلسات: ${u['sessionsCount'] ?? 0}'),
                                      _userStat(Icons.favorite_border_rounded,
                                          'المفضلون: ${favoriteTrainers.length}'),
                                    ],
                                  ),
                                ],
                              ),
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

// ── مربع تعديل مستخدم واحد ──
class _UserEditDialog extends StatefulWidget {
  final String baseUrl;
  final String token;
  final dynamic user;
  final bool canEdit;
  final VoidCallback onSaved;

  const _UserEditDialog({
    required this.baseUrl,
    required this.token,
    required this.user,
    required this.canEdit,
    required this.onSaved,
  });

  @override
  State<_UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<_UserEditDialog> {
  static const Color navy = Color(0xFF14213D);
  static const Color gold = Color(0xFFE3B23C);
  static const Color background = Color(0xFFF6F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3DFD5);
  static const Color textSecondary = Color(0xFF6B6B67);
  static const Color unavailable = Color(0xFF8C3D2A);

  late TextEditingController _name;
  late TextEditingController _phone;
  late TextEditingController _email;
  late TextEditingController _password; // كلمة سر جديدة، فارغة = بدون تغيير
  late TextEditingController _rating;
  late TextEditingController _balance;
  late TextEditingController _sessionsCount;

  // المدربون المفضلون: قائمة {'_id': ..., 'name': ...}
  List<Map<String, dynamic>> _favoriteTrainers = [];
  List<dynamic> _allTrainers = [];
  bool _isLoadingTrainers = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _name = TextEditingController(text: u['name'] ?? '');
    _phone = TextEditingController(text: u['phone'] ?? '');
    _email = TextEditingController(text: u['email'] ?? '');
    _password = TextEditingController();
    _rating = TextEditingController(text: (u['rating'] ?? 0).toString());
    _balance = TextEditingController(text: (u['balance'] ?? 0).toString());
    _sessionsCount =
        TextEditingController(text: (u['sessionsCount'] ?? 0).toString());

    final List<dynamic> favs = u['favoriteTrainers'] ?? [];
    _favoriteTrainers = favs.map<Map<String, dynamic>>((f) {
      if (f is Map) {
        return {'_id': f['_id'], 'name': f['name'] ?? ''};
      }
      // إذا كانت القيمة مجرد id نصي بدون بيانات محملة
      return {'_id': f, 'name': f.toString()};
    }).toList();

    _fetchAllTrainers();
  }

  Future<void> _fetchAllTrainers() async {
    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/api/admin/trainers'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _allTrainers = data['trainers'] ?? [];
          _isLoadingTrainers = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoadingTrainers = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingTrainers = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _rating.dispose();
    _balance.dispose();
    _sessionsCount.dispose();
    super.dispose();
  }

  void _removeFavorite(String id) {
    setState(() => _favoriteTrainers.removeWhere((f) => f['_id'] == id));
  }

  void _openAddFavoriteSheet() {
    final existingIds = _favoriteTrainers.map((f) => f['_id']).toSet();
    final searchCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = _allTrainers.where((t) {
              final name = (t['name'] ?? '').toString().toLowerCase();
              return searchCtrl.text.isEmpty ||
                  name.contains(searchCtrl.text.toLowerCase());
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SizedBox(
                height: 420,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('اختر مدرب لإضافته للمفضلة',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchCtrl,
                      onChanged: (_) => setSheetState(() {}),
                      decoration: InputDecoration(
                        hintText: 'ابحث باسم المدرب...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        filled: true,
                        fillColor: background,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: border)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _isLoadingTrainers
                          ? const Center(
                              child: CircularProgressIndicator(color: navy))
                          : filtered.isEmpty
                              ? const Center(
                                  child: Text('ما في مدربين',
                                      style: TextStyle(color: textSecondary)))
                              : ListView.builder(
                                  itemCount: filtered.length,
                                  itemBuilder: (context, i) {
                                    final t = filtered[i];
                                    final bool already =
                                        existingIds.contains(t['_id']);
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: border,
                                        backgroundImage:
                                            (t['imageUrl'] ?? '').isNotEmpty
                                                ? NetworkImage(t['imageUrl'])
                                                : null,
                                        child: (t['imageUrl'] ?? '').isEmpty
                                            ? const Icon(Icons.person_rounded,
                                                color: textSecondary)
                                            : null,
                                      ),
                                      title: Text(t['name'] ?? '',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14)),
                                      trailing: already
                                          ? const Icon(
                                              Icons.check_circle_rounded,
                                              color: navy)
                                          : const Icon(
                                              Icons.add_circle_outline_rounded,
                                              color: textSecondary),
                                      onTap: already
                                          ? null
                                          : () {
                                              setState(() {
                                                _favoriteTrainers.add({
                                                  '_id': t['_id'],
                                                  'name': t['name'] ?? ''
                                                });
                                              });
                                              Navigator.pop(sheetContext);
                                            },
                                    );
                                  },
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

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final Map<String, dynamic> body = {
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'rating': double.tryParse(_rating.text.trim()) ?? 0,
        'balance': int.tryParse(_balance.text.trim()) ?? 0,
        'sessionsCount': int.tryParse(_sessionsCount.text.trim()) ?? 0,
        'favoriteTrainers': _favoriteTrainers.map((f) => f['_id']).toList(),
      };
      if (_password.text.trim().isNotEmpty) {
        body['password'] = _password.text.trim();
      }

      final response = await http.put(
        Uri.parse('${widget.baseUrl}/api/admin/users/${widget.user['_id']}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (!mounted) return;
      setState(() => _isSaving = false);

      if (response.statusCode == 200) {
        widget.onSaved();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'صار خطأ أثناء الحفظ')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ما قدرنا نوصل للسيرفر')),
      );
    }
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: background,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: navy, width: 1.4)),
      );

  @override
  Widget build(BuildContext context) {
    final bool readOnly = !widget.canEdit;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 680),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: surface, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('تعديل بيانات المستخدم',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                InkWell(
                    onTap: () => Navigator.pop(context),
                    child:
                        const Icon(Icons.close_rounded, color: textSecondary)),
              ],
            ),
            if (readOnly) ...[
              const SizedBox(height: 6),
              const Text('صلاحيتك "متابع" — عرض فقط، ما تقدر تعدل',
                  style: TextStyle(fontSize: 11.5, color: navy)),
            ],
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('الاسم',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: textSecondary)),
                    const SizedBox(height: 4),
                    TextField(
                        controller: _name,
                        enabled: !readOnly,
                        decoration: _dec('الاسم')),
                    const SizedBox(height: 12),
                    const Text('رقم الجوال',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: textSecondary)),
                    const SizedBox(height: 4),
                    TextField(
                        controller: _phone,
                        enabled: !readOnly,
                        decoration: _dec('رقم الجوال')),
                    const SizedBox(height: 12),
                    const Text('الإيميل',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: textSecondary)),
                    const SizedBox(height: 4),
                    TextField(
                        controller: _email,
                        enabled: !readOnly,
                        decoration: _dec('الإيميل')),
                    const SizedBox(height: 12),
                    const Text('كلمة سر جديدة (اتركها فارغة لعدم التغيير)',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: textSecondary)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _password,
                      enabled: !readOnly,
                      obscureText: true,
                      decoration:
                          _dec('كلمة سر جديدة (اتركها فارغة لعدم التغيير)'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('التقييم (0-5)',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: textSecondary)),
                              const SizedBox(height: 4),
                              TextField(
                                  controller: _rating,
                                  enabled: !readOnly,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: _dec('التقييم (0-5)')),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('الرصيد',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: textSecondary)),
                              const SizedBox(height: 4),
                              TextField(
                                  controller: _balance,
                                  enabled: !readOnly,
                                  keyboardType: TextInputType.number,
                                  decoration: _dec('الرصيد')),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('عدد الجلسات',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: textSecondary)),
                    const SizedBox(height: 4),
                    TextField(
                        controller: _sessionsCount,
                        enabled: !readOnly,
                        keyboardType: TextInputType.number,
                        decoration: _dec('عدد الجلسات')),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المدربون المفضلون',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                        if (!readOnly)
                          InkWell(
                            onTap: _openAddFavoriteSheet,
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_circle_outline_rounded,
                                      size: 18, color: navy),
                                  SizedBox(width: 4),
                                  Text('إضافة',
                                      style: TextStyle(
                                          fontSize: 12.5,
                                          color: navy,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _favoriteTrainers.isEmpty
                        ? const Text('ما في مدربين مفضلين',
                            style:
                                TextStyle(fontSize: 12.5, color: textSecondary))
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _favoriteTrainers.map((f) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: background,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(f['name'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600)),
                                    if (!readOnly) ...[
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () => _removeFavorite(f['_id']),
                                        child: const Icon(Icons.close_rounded,
                                            size: 15, color: unavailable),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),
            ),
            if (!readOnly) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.2, color: Colors.white))
                      : const Text('حفظ التعديلات'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// قسم "الإعدادات" — تغيير كلمة المرور
// ═══════════════════════════════════════════
class _SettingsSection extends StatefulWidget {
  final String baseUrl;
  final String token;
  const _SettingsSection({required this.baseUrl, required this.token});

  @override
  State<_SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<_SettingsSection> {
  static const Color navy = Color(0xFF14213D);
  static const Color background = Color(0xFFF6F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3DFD5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B67);

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('عبي كلمة المرور الحالية والجديدة (6 أحرف عالأقل)')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final response = await http.put(
        Uri.parse('${widget.baseUrl}/api/admin/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'currentPassword': _currentPasswordController.text,
          'newPassword': _newPasswordController.text,
        }),
      );

      final data = jsonDecode(response.body);
      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'صار خطأ')),
      );

      if (response.statusCode == 200) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ما قدرنا نوصل للسيرفر')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الإعدادات',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textPrimary)),
          const SizedBox(height: 4),
          const Text('تغيير كلمة المرور الخاصة بحسابك',
              style: TextStyle(fontSize: 13, color: textSecondary)),
          const SizedBox(height: 24),
          Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('كلمة المرور الحالية',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(
                  controller: _currentPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: background,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: border)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('كلمة المرور الجديدة',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: background,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: border)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.2, color: Colors.white))
                        : const Text('تغيير كلمة المرور'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// قسم "الأدمنز" — عرض وتعديل حصراً لصلاحية "كامل الصلاحية"
// ═══════════════════════════════════════════
class _AdminsSection extends StatefulWidget {
  final String baseUrl;
  final String token;
  const _AdminsSection({required this.baseUrl, required this.token});

  @override
  State<_AdminsSection> createState() => _AdminsSectionState();
}

class _AdminsSectionState extends State<_AdminsSection> {
  static const Color navy = Color(0xFF14213D);
  static const Color gold = Color(0xFFE3B23C);
  static const Color background = Color(0xFFF6F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3DFD5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B67);
  static const Color unavailable = Color(0xFF8C3D2A);

  static const Map<String, String> _roleLabels = {
    'full': 'كامل الصلاحية',
    'editor': 'محرر',
    'viewer': 'متابع',
  };

  List<dynamic> _admins = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
  }

  Future<void> _fetchAdmins() async {
    print('Fetching admins...');
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/api/admin/admins'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _admins = data['admins'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _openAdminEditor(dynamic admin) {
    showDialog(
      context: context,
      builder: (_) => _AdminEditDialog(
        baseUrl: widget.baseUrl,
        token: widget.token,
        admin: admin,
        onSaved: _fetchAdmins,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الأدمنز',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textPrimary)),
          const SizedBox(height: 4),
          const Text(
              'إدارة صلاحيات حسابات الأدمن — حصري لصاحب الصلاحية الكاملة',
              style: TextStyle(fontSize: 13, color: textSecondary)),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: navy))
                : _admins.isEmpty
                    ? const Center(
                        child: Text('ما في حسابات',
                            style: TextStyle(color: textSecondary)))
                    : ListView.separated(
                        itemCount: _admins.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final a = _admins[i];
                          final String? role = a['role'];
                          return InkWell(
                            onTap: () => _openAdminEditor(a),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                        color: navy.withValues(alpha: 0.08),
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.person_rounded,
                                        color: navy),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(a['name'] ?? '',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14)),
                                        const SizedBox(height: 2),
                                        Text(a['email'] ?? '',
                                            style: const TextStyle(
                                                color: textSecondary,
                                                fontSize: 12.5)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: role == null
                                          ? unavailable.withValues(alpha: 0.1)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: role == null
                                              ? unavailable
                                              : navy),
                                    ),
                                    child: Text(
                                      role == null
                                          ? 'بانتظار التفعيل'
                                          : (_roleLabels[role] ?? role),
                                      style: TextStyle(
                                        color:
                                            role == null ? unavailable : navy,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_left_rounded,
                                      color: textSecondary),
                                ],
                              ),
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

// ── مربع تعديل أدمن واحد (اسم، إيميل، صلاحية) ──
class _AdminEditDialog extends StatefulWidget {
  final String baseUrl;
  final String token;
  final dynamic admin;
  final VoidCallback onSaved;

  const _AdminEditDialog({
    required this.baseUrl,
    required this.token,
    required this.admin,
    required this.onSaved,
  });

  @override
  State<_AdminEditDialog> createState() => _AdminEditDialogState();
}

class _AdminEditDialogState extends State<_AdminEditDialog> {
  static const Color navy = Color(0xFF14213D);
  static const Color background = Color(0xFFF6F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3DFD5);
  static const Color textSecondary = Color(0xFF6B6B67);

  static const Map<String, String> _roleLabels = {
    'full': 'كامل الصلاحية',
    'editor': 'محرر',
    'viewer': 'متابع',
  };

  late TextEditingController _name;
  late TextEditingController _email;
  String? _selectedRole; // null = بانتظار التفعيل / معلّق
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.admin['name'] ?? '');
    _email = TextEditingController(text: widget.admin['email'] ?? '');
    _selectedRole = widget.admin['role'];
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final response = await http.put(
        Uri.parse('${widget.baseUrl}/api/admin/admins/${widget.admin['_id']}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'name': _name.text.trim(),
          'email': _email.text.trim(),
          'role': _selectedRole ?? '',
        }),
      );

      final data = jsonDecode(response.body);
      if (!mounted) return;
      setState(() => _isSaving = false);

      if (response.statusCode == 200) {
        widget.onSaved();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'صار خطأ أثناء الحفظ')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ما قدرنا نوصل للسيرفر')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: surface, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('تعديل حساب أدمن',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                InkWell(
                    onTap: () => Navigator.pop(context),
                    child:
                        const Icon(Icons.close_rounded, color: textSecondary)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('الاسم',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                filled: true,
                fillColor: background,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: border)),
              ),
            ),
            const SizedBox(height: 14),
            const Text('البريد الإلكتروني',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _email,
              decoration: InputDecoration(
                filled: true,
                fillColor: background,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: border)),
              ),
            ),
            const SizedBox(height: 14),
            const Text('الصلاحية',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: _selectedRole,
                  hint: const Text('بانتظار التفعيل (بدون صلاحية)',
                      style: TextStyle(fontSize: 13, color: textSecondary)),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: textSecondary),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('بدون صلاحية (تعليق الحساب)',
                            style: TextStyle(fontSize: 13))),
                    ..._roleLabels.entries.map((e) => DropdownMenuItem<String?>(
                        value: e.key,
                        child: Text(e.value,
                            style: const TextStyle(fontSize: 13)))),
                  ],
                  onChanged: (value) => setState(() => _selectedRole = value),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.2, color: Colors.white))
                    : const Text('حفظ التعديلات'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsSection extends StatefulWidget {
  final String baseUrl;
  final String token;
  const _StatsSection({required this.baseUrl, required this.token});

  @override
  State<_StatsSection> createState() => _StatsSectionState();
}

class _StatsSectionState extends State<_StatsSection> {
  static const Color navy = Color(0xFF14213D);
  static const Color gold = Color(0xFFE3B23C);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3DFD5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B67);
  static const Color available = Color(0xFF2F7A57);
  static const Color unavailable = Color(0xFF8C3D2A);

  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/api/admin/stats'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _stats = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textPrimary)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 12.5, color: textSecondary)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: navy));
    }
    if (_stats == null) {
      return const Center(
          child: Text('ما قدرنا نجيب الإحصائيات',
              style: TextStyle(color: textSecondary)));
    }

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الإحصائيات',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textPrimary)),
          const SizedBox(height: 4),
          const Text('نظرة عامة على المدربين والمدفوعات',
              style: TextStyle(fontSize: 13, color: textSecondary)),
          const SizedBox(height: 24),
          Row(
            children: [
              _statCard('إجمالي المدربين', '${_stats!['totalTrainers']}',
                  Icons.groups_outlined, navy),
              const SizedBox(width: 14),
              _statCard('متاحون الآن', '${_stats!['availableTrainers']}',
                  Icons.check_circle_outline_rounded, available),
              const SizedBox(width: 14),
              _statCard('مشغولون', '${_stats!['busyTrainers']}',
                  Icons.timelapse_rounded, unavailable),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _statCard('إجمالي الأرصدة', '${_stats!['totalBalance']}',
                  Icons.account_balance_wallet_outlined, gold),
              const SizedBox(width: 14),
              _statCard('إجمالي الدفعات', '${_stats!['totalPayments']}',
                  Icons.receipt_long_outlined, navy),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// قسم "الطلبات" — كل طلبات الحجز + فلترة بالاسم/المدرب + قبول/إلغاء/حذف
// ═══════════════════════════════════════════
//
// ملاحظة: هاد الجزء يفترض إن الباك اند فيه هالـ Endpoints (عدّل الأسماء إذا
// كانت مختلفة عندك بالسيرفر):
//   GET    /api/admin/requests?search=&customerName=&trainerName=&status=
//          → يرجع { "requests": [ ... ] }
//   PUT    /api/admin/requests/:id     body: { "status": "approved" | "cancelled" }
//   DELETE /api/admin/requests/:id
//
// وكل عنصر "طلب" متوقّع يكون فيه تقريباً:
//   { _id, status, date, time, price, notes,
//     user: { _id, name, phone } أو customerName,
//     trainer: { _id, name, phone } أو trainerName }

class _RequestsSection extends StatefulWidget {
  final String baseUrl;
  final String token;
  final bool canEdit;
  const _RequestsSection(
      {required this.baseUrl, required this.token, required this.canEdit});

  @override
  State<_RequestsSection> createState() => _RequestsSectionState();
}

class _RequestsSectionState extends State<_RequestsSection> {
  static const Color navy = Color(0xFF14213D);
  static const Color gold = Color(0xFFE3B23C);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3DFD5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B67);
  static const Color available = Color(0xFF2F7A57);
  static const Color unavailable = Color(0xFF8C3D2A);
  static const Color pendingColor = Color(0xFFB07A1E);

  static const Map<String, String> _statusLabels = {
    'pending': 'قيد الانتظار',
    'approved': 'مقبول',
    'rejected': 'مرفوض',
    'cancelled': 'ملغي',
    'completed': 'مكتمل',
  };

  List<dynamic> _requests = [];
  bool _isLoading = true;
  Timer? _debounce;

  final _searchController = TextEditingController();
  final _userFilterController = TextEditingController();
  final _trainerFilterController = TextEditingController();
  String? _statusFilter; // null = الكل

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _userFilterController.dispose();
    _trainerFilterController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final Map<String, String> params = {};
      if (_searchController.text.trim().isNotEmpty) {
        params['search'] = _searchController.text.trim();
      }
      if (_userFilterController.text.trim().isNotEmpty) {
        params['customerName'] = _userFilterController.text.trim();
      }

      if (_trainerFilterController.text.trim().isNotEmpty) {
        params['trainerName'] = _trainerFilterController.text.trim();
      }
      if (_statusFilter != null) {
        params['status'] = _statusFilter!;
      }

      final uri = Uri.parse('${widget.baseUrl}/api/admin/activities')
          .replace(queryParameters: params.isNotEmpty ? params : null);
      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer ${widget.token}'});
      print("STATUS CODE: ${response.statusCode}");
      print("BODY: ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _requests = data['activities'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _onFilterChanged() {
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 400), () => _fetchRequests());
  }

  String _extractName(dynamic request, String nestedKey, String flatKey) {
    final nested = request[nestedKey];
    if (nested is Map) return (nested['name'] ?? '').toString();
    return (request[flatKey] ?? '').toString();
  }

  String _extractPhone(dynamic request, String nestedKey) {
    final nested = request[nestedKey];
    if (nested is Map) return (nested['phone'] ?? '').toString();
    return '';
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      final response = await http.put(
        Uri.parse('${widget.baseUrl}/api/admin/activities/$id/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'status': newStatus}),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        _fetchRequests();
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'صار خطأ أثناء التحديث')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ما قدرنا نوصل للسيرفر')),
      );
    }
  }

  Future<void> _markAsPaid(String id) async {
    try {
      final response = await http.put(
        Uri.parse('${widget.baseUrl}/api/admin/activities/$id/mark-paid'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        _fetchRequests();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل الدفع بنجاح')),
        );
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(data['message'] ?? 'صار خطأ أثناء تسجيل الدفع')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ما قدرنا نوصل للسيرفر')),
      );
    }
  }

  Future<void> _deleteRequest(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${widget.baseUrl}/api/admin/activities/$id'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        _fetchRequests();
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'صار خطأ أثناء الحذف')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ما قدرنا نوصل للسيرفر')),
      );
    }
  }

  void _confirmDelete(dynamic request) {
    final customerName = _extractName(request, 'user', 'customerName');
    final trainerName = _extractName(request, 'trainer', 'trainerName');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف الطلب؟',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Text(
            'متأكد إنك بدك تحذف طلب "$customerName" مع "$trainerName"؟ هذا الإجراء ما يمكن التراجع عنه.',
            style: const TextStyle(fontSize: 13.5, color: textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRequest(request['_id']);
            },
            child: const Text('حذف',
                style:
                    TextStyle(color: unavailable, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return available;
      case 'rejected':
      case 'cancelled':
        return unavailable;
      case 'completed':
        return navy;
      default:
        return pendingColor;
    }
  }

  Widget _filterField(
      TextEditingController controller, String hint, IconData icon) {
    return SizedBox(
      width: 220,
      child: TextField(
        controller: controller,
        onChanged: (_) => _onFilterChanged(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12.5),
          prefixIcon: Icon(icon, color: textSecondary, size: 18),
          filled: true,
          fillColor: surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: navy, width: 1.4)),
        ),
      ),
    );
  }

  Widget _statusChip(String? value, String label) {
    final bool selected = _statusFilter == value;
    return InkWell(
      onTap: () {
        setState(() => _statusFilter = value);
        _fetchRequests();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? navy : surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? navy : border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الطلبات',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textPrimary)),
          const SizedBox(height: 4),
          const Text('كل طلبات الحجز — فلترة بالمستخدم أو المدرب أو كليهما',
              style: TextStyle(fontSize: 13, color: textSecondary)),
          const SizedBox(height: 18),

          // ── صف الفلاتر ──
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _filterField(
                  _searchController, 'بحث عام...', Icons.search_rounded),
              _filterField(_userFilterController, 'اسم المستخدم...',
                  Icons.person_outline_rounded),
              _filterField(_trainerFilterController, 'اسم المدرب...',
                  Icons.sports_gymnastics_outlined),
            ],
          ),
          const SizedBox(height: 14),

          // ── شرائح الحالة ── (أضفنا "مرفوض" لأنها موجودة بالـ schema)
          Wrap(
            spacing: 8,
            children: [
              _statusChip(null, 'الكل'),
              _statusChip('pending', 'قيد الانتظار'),
              _statusChip('approved', 'مقبول'),
              _statusChip('rejected', 'مرفوض'),
              _statusChip('cancelled', 'ملغي'),
              _statusChip('completed', 'مكتمل'),
            ],
          ),
          const SizedBox(height: 18),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: navy))
                : _requests.isEmpty
                    ? const Center(
                        child: Text('ما في طلبات مطابقة',
                            style: TextStyle(color: textSecondary)))
                    : ListView.separated(
                        itemCount: _requests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final r = _requests[i];
                          final String status =
                              (r['status'] ?? 'pending').toString();
                          final String customerName =
                              _extractName(r, 'user', 'customerName');
                          final String userPhone = _extractPhone(r, 'user');
                          final String trainerName =
                              _extractName(r, 'trainer', 'trainerName');
                          final String trainerPhone =
                              _extractPhone(r, 'trainer');
                          final String description =
                              (r['description'] ?? '').toString();
                          final String zoomLink =
                              (r['zoomLink'] ?? '').toString();
                          final DateTime? sessionDateTime = DateTime.tryParse(
                              (r['sessionTime'] ?? '').toString());
                          final String date = sessionDateTime != null
                              ? DateFormat('yyyy/MM/dd', 'ar')
                                  .format(sessionDateTime)
                              : '';
                          final String time = sessionDateTime != null
                              ? DateFormat('hh:mm a', 'ar')
                                  .format(sessionDateTime)
                              : '';
                          final String actionBy =
                              (r['actionBy'] ?? '').toString();
                          final bool isPaid = r['isPaid'] ?? false;
                          final num paidAmount = (r['paidAmount'] ?? 0) is num
                              ? (r['paidAmount'] ?? 0)
                              : 0;
                          final Color statusColor = _statusColor(status);
                          final bool showActionBy =
                              (status == 'cancelled' || status == 'rejected') &&
                                  actionBy.isNotEmpty;

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                  Icons.person_outline_rounded,
                                                  size: 15,
                                                  color: textSecondary),
                                              const SizedBox(width: 5),
                                              Text(
                                                  customerName.isEmpty
                                                      ? 'مستخدم غير معروف'
                                                      : customerName,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 14.5)),
                                              if (userPhone.isNotEmpty) ...[
                                                const SizedBox(width: 6),
                                                Text('· $userPhone',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: textSecondary)),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(
                                                  Icons
                                                      .sports_gymnastics_outlined,
                                                  size: 15,
                                                  color: textSecondary),
                                              const SizedBox(width: 5),
                                              Text(
                                                  trainerName.isEmpty
                                                      ? 'مدرب غير معروف'
                                                      : trainerName,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13.5,
                                                      color: navy)),
                                              if (trainerPhone.isNotEmpty) ...[
                                                const SizedBox(width: 6),
                                                Text('· $trainerPhone',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: textSecondary)),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(
                                                alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border:
                                                Border.all(color: statusColor),
                                          ),
                                          child: Text(
                                            _statusLabels[status] ?? status,
                                            style: TextStyle(
                                                color: statusColor,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                        if (isPaid) ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color:
                                                  gold.withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(color: gold),
                                            ),
                                            child: Text(
                                              'مدفوع: $paidAmount ₪',
                                              style: const TextStyle(
                                                  color: navy,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),

                                // ── الوصف ──
                                if (description.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    description,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        color: Color.fromARGB(255, 255, 3, 3),
                                        height: 1.4),
                                  ),
                                ],

                                if (date.isNotEmpty || time.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Divider(color: border, height: 1),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 18,
                                    runSpacing: 8,
                                    children: [
                                      if (date.isNotEmpty)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                                Icons.calendar_today_outlined,
                                                size: 14,
                                                color: textSecondary),
                                            const SizedBox(width: 5),
                                            Text(date,
                                                style: const TextStyle(
                                                    fontSize: 12.5,
                                                    color: textSecondary,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ],
                                        ),
                                      if (time.isNotEmpty)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                                Icons.access_time_rounded,
                                                size: 14,
                                                color: textSecondary),
                                            const SizedBox(width: 5),
                                            Text(time,
                                                style: const TextStyle(
                                                    fontSize: 12.5,
                                                    color: textSecondary,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ],
                                        ),
                                      if ((r['price'] ?? '')
                                          .toString()
                                          .isNotEmpty)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.payments_outlined,
                                                size: 14, color: textSecondary),
                                            const SizedBox(width: 5),
                                            Text('${r['price']} ₪',
                                                style: const TextStyle(
                                                    fontSize: 12.5,
                                                    color: textSecondary,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],

                                // ── رابط الزوم ──
                                if (zoomLink.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(
                                          ClipboardData(text: zoomLink));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content:
                                                  Text('تم نسخ رابط الزوم')));
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.videocam_outlined,
                                            size: 14, color: navy),
                                        const SizedBox(width: 5),
                                        Flexible(
                                          child: Text(
                                            zoomLink,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 12.5,
                                                color: navy,
                                                fontWeight: FontWeight.w600,
                                                decoration:
                                                    TextDecoration.underline),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.copy_rounded,
                                            size: 13, color: textSecondary),
                                      ],
                                    ),
                                  ),
                                ],

                                // ── مين ألغى/رفض ──
                                if (showActionBy) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    actionBy == 'admin'
                                        ? '${status == 'rejected' ? 'رُفض' : 'أُلغي'} من قبل الأدمن'
                                        : '${status == 'rejected' ? 'رُفض' : 'أُلغي'} من قبل المدرب',
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        color: textSecondary,
                                        fontStyle: FontStyle.italic),
                                  ),
                                ],
                                if (widget.canEdit) ...[
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      if (status == 'approved' && !isPaid)
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () =>
                                                _markAsPaid(r['_id']),
                                            icon: const Icon(
                                                Icons.payments_rounded,
                                                size: 17,
                                                color: navy),
                                            label: const Text('تسجيل الدفع',
                                                style: TextStyle(
                                                    color: navy,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                            style: OutlinedButton.styleFrom(
                                              side:
                                                  const BorderSide(color: navy),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                            ),
                                          ),
                                        ),
                                      if (status == 'approved' && !isPaid)
                                        const SizedBox(width: 8),
                                      if (status != 'approved')
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _updateStatus(
                                                r['_id'], 'approved'),
                                            icon: const Icon(
                                                Icons
                                                    .check_circle_outline_rounded,
                                                size: 17,
                                                color: available),
                                            label: const Text('قبول',
                                                style: TextStyle(
                                                    color: available,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(
                                                  color: available),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                            ),
                                          ),
                                        ),
                                      if (status != 'approved')
                                        const SizedBox(width: 8),
                                      if (status != 'cancelled')
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _updateStatus(
                                                r['_id'], 'cancelled'),
                                            icon: const Icon(
                                                Icons.cancel_outlined,
                                                size: 17,
                                                color: unavailable),
                                            label: const Text('إلغاء',
                                                style: TextStyle(
                                                    color: unavailable,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(
                                                  color: unavailable),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () => _confirmDelete(r),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: border),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 18,
                                              color: textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
