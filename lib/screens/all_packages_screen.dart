import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_config.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AllPackagesScreen extends StatefulWidget {
  const AllPackagesScreen({super.key});

  @override
  State<AllPackagesScreen> createState() => _AllPackagesScreenState();
}

class _AllPackagesScreenState extends State<AllPackagesScreen> {
  List<Map<String, dynamic>> _packages = [];
  bool _loading = true;

  static const _gradients = [
    [Color(0xFF2C3E7A), Color(0xFF1A237E)],
    [Color(0xFFB8860B), Color(0xFFF57F17)],
    [Color(0xFF1565C0), Color(0xFF0D47A1)],
    [Color(0xFFE65100), Color(0xFFBF360C)],
    [Color(0xFF6A1B9A), Color(0xFF4A148C)],
    [Color(0xFF00695C), Color(0xFF004D40)],
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ApiService.instance.getPackages();
      if (!mounted) return;
      setState(() {
        _packages = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading  = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded,
              color: Colors.white, size: 30),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(
          'แพ็กเกจสุดคุ้ม',
          style: GoogleFonts.sarabun(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _packages.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: (_packages.length / 2).ceil(),
                    itemBuilder: (_, row) {
                      final l = row * 2;
                      final r = l + 1;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _packageCard(_packages[l], l)),
                            const SizedBox(width: 12),
                            r < _packages.length
                                ? Expanded(child: _packageCard(_packages[r], r))
                                : const Expanded(child: SizedBox()),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                  color: AppTheme.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: AppTheme.primary, size: 48),
            ),
            const SizedBox(height: 16),
            Text('ยังไม่มีแพ็กเกจ',
                style: GoogleFonts.sarabun(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark)),
            const SizedBox(height: 6),
            Text('กรุณาลองใหม่ภายหลัง',
                style: GoogleFonts.sarabun(
                    fontSize: 13,
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _packageCard(Map<String, dynamic> p, int i) {
    final id           = (p['id'] as num?)?.toInt() ?? 0;
    final title        = (p['c_pack_name'] as String?) ?? '-';
    final original     = (p['c_pack_price'] as num?)?.toInt() ?? 0;
    final sale         = (p['c_pack_price_2'] as num?)?.toInt() ?? original;
    final isFree       = sale == 0;
    final hasDiscount  = original > sale;
    final imgFile      = p['c_pack_image'] as String?;
    final imageUrl     = (imgFile != null && imgFile.isNotEmpty)
        ? '${AppConfig.uploadsBase}$imgFile'
        : null;
    final gradient     = _gradients[i % _gradients.length];

    return GestureDetector(
      onTap: () => context.push('/package', extra: id),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image / gradient header
            SizedBox(
              height: 115,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _gradientBg(gradient),
                          )
                        : _gradientBg(gradient),
                  ),
                  // Badge
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppTheme.priceRed,
                          borderRadius: BorderRadius.circular(6)),
                      child: Text('แพ็กเกจ',
                          style: GoogleFonts.sarabun(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ),
                  if (isFree)
                    Positioned(
                      bottom: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text('ฟรี',
                            style: GoogleFonts.sarabun(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primary)),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.sarabun(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                        height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  if (isFree)
                    Text('เรียนฟรี ไม่มีค่าใช้จ่าย',
                        style: GoogleFonts.sarabun(
                            fontSize: 11,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700))
                  else ...[
                    if (hasDiscount)
                      Text('จาก ฿${_fmt(original)}',
                          style: GoogleFonts.sarabun(
                              fontSize: 10,
                              color: AppTheme.textLight,
                              decoration: TextDecoration.lineThrough)),
                    Text('฿${_fmt(sale)}',
                        style: GoogleFonts.sarabun(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary)),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push('/package', extra: id),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        textStyle: GoogleFonts.sarabun(
                            fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                      child: const Text('ดูรายละเอียด'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientBg(List<Color> colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.workspace_premium_rounded,
            color: Colors.white.withOpacity(0.3), size: 48),
      ),
    );
  }
}
