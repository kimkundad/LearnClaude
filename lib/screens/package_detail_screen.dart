import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

class PackageDetailScreen extends StatefulWidget {
  final int packageId;
  const PackageDetailScreen({super.key, required this.packageId});

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  static const _imgBase = 'https://learnsbuy.com/assets/uploads/';

  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic> _pack = {};
  List<Map<String, dynamic>> _courses = [];

  static const _courseColors = <List<Color>>[
    [Color(0xFFFF6B8A), Color(0xFFFF4757)],
    [Color(0xFF9B59B6), Color(0xFF6C3483)],
    [Color(0xFF0FB5A6), Color(0xFF0A8A7E)],
    [Color(0xFFFF9F43), Color(0xFFEE5A24)],
    [Color(0xFF3498DB), Color(0xFF1A73C7)],
    [Color(0xFF2ECC71), Color(0xFF1A9B5F)],
    [Color(0xFFE74C3C), Color(0xFFC0392B)],
    [Color(0xFF2C3E7A), Color(0xFF1A2460)],
  ];

  @override
  void initState() {
    super.initState();
    _loadPackage();
  }

  Future<void> _loadPackage() async {
    if (widget.packageId <= 0) {
      setState(() { _error = 'ไม่พบข้อมูลแพ็กเกจ'; _isLoading = false; });
      return;
    }
    try {
      final data = await ApiService.instance.getPackageById(widget.packageId);
      if (!mounted) return;
      setState(() {
        _pack    = Map<String, dynamic>.from(data['pack'] as Map);
        _courses = (data['courses'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  int get _salePrice     => (_pack['c_pack_price']   as num?)?.toInt() ?? 0;
  int get _originalPrice => (_pack['c_pack_price_2'] as num?)?.toInt() ?? _salePrice;
  int get _savedAmount   => _originalPrice - _salePrice;
  int get _discountPct   => _originalPrice > 0
      ? ((_savedAmount / _originalPrice) * 100).round()
      : 0;

  String _fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FAF8),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? _buildError()
              : CustomScrollView(
                  slivers: [
                    _buildAppBar(context),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHero(),
                            const SizedBox(height: 16),
                            _buildTitleBlock(),
                            const SizedBox(height: 14),
                            _buildPriceCard(),
                            const SizedBox(height: 16),
                            _buildDescription(),
                            const SizedBox(height: 18),
                            _sectionTitle('คอร์สเรียนภายในแพ็กเกจ'),
                            const SizedBox(height: 4),
                            Text(
                              '${_courses.length} คอร์ส · มูลค่ารวม ฿${_fmt(_originalPrice)}',
                              style: GoogleFonts.sarabun(
                                fontSize: 12,
                                color: AppTheme.textLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._courses.asMap().entries.map((e) =>
                                _buildCourseCard(e.key, e.value)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: _isLoading || _error.isNotEmpty ? null : _buildBottomBar(context),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          _error,
          style: GoogleFonts.sarabun(fontSize: 15, color: AppTheme.textLight),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.primary,
      elevation: 0,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Center(
          child: GestureDetector(
            onTap: () => context.canPop() ? context.pop() : context.go('/home'),
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: AppTheme.primary,
                size: 26,
              ),
            ),
          ),
        ),
      ),
      title: Text(
        'แพ็กเกจสุดคุ้ม',
        style: GoogleFonts.sarabun(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildHero() {
    final imgFile = (_pack['c_pack_image'] as String?) ?? '';
    final hasImage = imgFile.isNotEmpty;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF2C3E7A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.network(
              '$_imgBase$imgFile',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _heroGradient(),
            )
          else
            _heroGradient(),
          // gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                stops: const [0.4, 1.0],
              ),
            ),
          ),
          // discount badge
          if (_discountPct > 0)
            Positioned(
              top: 14,
              right: 14,
              child: _discountBadge('-$_discountPct%'),
            ),
          // bottom info
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    (_pack['c_pack_name'] as String?) ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sarabun(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.25,
                      shadows: const [Shadow(color: Colors.black38, blurRadius: 4)],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.28),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_courses.length} คอร์ส',
                    style: GoogleFonts.sarabun(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2C3E7A), Color(0xFF1A2460)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _discountBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5B72),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5B72).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.sarabun(
          fontSize: 13,
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildTitleBlock() {
    final name = (_pack['c_pack_name'] as String?) ?? '';
    return Text(
      name,
      style: GoogleFonts.sarabun(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: AppTheme.textDark,
        height: 1.3,
      ),
    );
  }

  Widget _buildPriceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDF1EE)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '฿${_fmt(_salePrice)}',
                      style: GoogleFonts.sarabun(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary,
                        height: 1,
                      ),
                    ),
                    if (_savedAmount > 0) ...[
                      const SizedBox(width: 10),
                      Text(
                        '฿${_fmt(_originalPrice)}',
                        style: GoogleFonts.sarabun(
                          fontSize: 14,
                          color: AppTheme.textLight,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                if (_savedAmount > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    'ประหยัด ฿${_fmt(_savedAmount)}',
                    style: GoogleFonts.sarabun(
                      fontSize: 12,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (_courses.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'เฉลี่ยเพียง ฿${_fmt((_salePrice / _courses.length).round())} ต่อคอร์ส',
                    style: GoogleFonts.sarabun(
                      fontSize: 12,
                      color: AppTheme.textMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_discountPct > 0) _discountBadge('-$_discountPct%'),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    final detail = ((_pack['c_pack_detail'] as String?) ?? '').trim();
    if (detail.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('เกี่ยวกับแพ็กเกจ'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Text(
            detail,
            style: GoogleFonts.sarabun(
              fontSize: 14,
              color: AppTheme.textMedium,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(int index, Map<String, dynamic> course) {
    final colors = _courseColors[index % _courseColors.length];
    final imgFile = (course['image_course'] as String?) ?? '';
    final hasImg  = imgFile.isNotEmpty;
    final title   = (course['title_course'] as String?) ?? '-';
    final price   = (course['price_course'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // ภาพซ้าย
          SizedBox(
            width: 100,
            height: 90,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasImg)
                  Image.network(
                    '$_imgBase$imgFile',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _courseGrad(colors),
                  )
                else
                  _courseGrad(colors),
                // หมายเลขคอร์ส
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.sarabun(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ข้อมูลขวา
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sarabun(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '฿${_fmt(price)} บาท',
                    style: GoogleFonts.sarabun(
                      fontSize: 12,
                      color: AppTheme.priceRed,
                      fontWeight: FontWeight.w900,
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

  Widget _courseGrad(List<Color> colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.sarabun(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_savedAmount > 0)
                    Text(
                      '฿${_fmt(_originalPrice)}',
                      style: GoogleFonts.sarabun(
                        fontSize: 11,
                        color: AppTheme.textLight,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    '฿${_fmt(_salePrice)}',
                    style: GoogleFonts.sarabun(
                      fontSize: 20,
                      height: 1,
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.push('/payment', extra: {
                  'type': 'package',
                  'id': widget.packageId,
                  'title': (_pack['c_pack_name'] as String?) ?? 'แพ็กเกจสุดคุ้ม',
                  'price': _salePrice,
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: Text(
                  'ซื้อแพ็กเกจนี้',
                  style: GoogleFonts.sarabun(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
