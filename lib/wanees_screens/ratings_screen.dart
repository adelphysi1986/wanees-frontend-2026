import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RatingsScreen extends StatefulWidget {
  const RatingsScreen({super.key});

  @override
  State<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends State<RatingsScreen> {
  static const Color navy = Color(0xFF14213D);
  static const Color gold = Color(0xFFE3B23C);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3DFD5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B67);

  final String _baseUrl = 'http://localhost:5000'; // 👈 عدّلها لنفس المصدر

  final List<Map<String, dynamic>> _reviews = [];
  final ScrollController _scrollController = ScrollController();

  int _currentPage = 1;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRatings(isInitial: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _hasMore) {
        _fetchRatings();
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
    final now = DateTime.now();
    final diff = now.difference(date);

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
    } else {
      return 'الآن';
    }
  }

  Future<void> _fetchRatings({bool isInitial = false}) async {
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
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/api/trainers/ratings/all?page=$_currentPage&limit=10'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> ratingsJson = data['ratings'] ?? [];
        final bool hasMore = data['hasMore'] ?? false;

        final newReviews = ratingsJson.map((r) {
          final customer = r['customer'] ?? {};
          final trainer = r['trainer'] ?? {};
          return {
            'customer': customer['name'] ?? 'زبون',
            'avatar': customer['avatar']?.toString().isNotEmpty == true
                ? customer['avatar']
                : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(customer['name'] ?? 'زبون')}&background=14213D&color=fff&size=150',
            'trainer': trainer['name'] ?? 'مدرب',
            'rating': (r['rating'] as num).toDouble(),
            'comment': r['comment'] ?? '',
            'createdAt': r['createdAt'] ?? '', // 👈 جديد
          };
        }).toList();

        setState(() {
          if (isInitial) {
            _reviews.clear();
          }
          _reviews.addAll(newReviews);
          _hasMore = hasMore;
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

  Future<void> _onRefresh() async {
    _hasMore = true;
    await _fetchRatings(isInitial: true);
  }

  Widget _reviewCard(Map<String, dynamic> r) {
    final double rating = r['rating'];
    final String timeAgo =
        r['createdAt'] != null && r['createdAt'].toString().isNotEmpty
            ? _timeAgo(r['createdAt'])
            : '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 20, backgroundImage: NetworkImage(r['avatar'])),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r['customer'],
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13.5)),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < rating.round()
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: gold,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('تقييم لمدرب: ${r['trainer']}',
                          style: const TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                    if (timeAgo.isNotEmpty)
                      Text(timeAgo,
                          style: const TextStyle(
                              color: textSecondary, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(r['comment'],
                    style: const TextStyle(fontSize: 13.5, color: textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: _onRefresh, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }

    if (_reviews.isEmpty) {
      return const Center(child: Text('لا توجد تقييمات بعد'));
    }

    final avg =
        _reviews.map((r) => r['rating'] as double).reduce((a, b) => a + b) /
            _reviews.length;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تقييمات الزبائن',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: navy, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Text(avg.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      i < avg.round()
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      color: gold,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                    'بناءً على ${_reviews.length} تقييم من الزبائن',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _reviewCard(_reviews[i]),
                  ),
                  childCount: _reviews.length,
                ),
              ),
            ),
            if (_isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}
