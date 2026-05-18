import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_config.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({super.key});

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  List<dynamic> _articles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.instance.getArticles();
      if (mounted) setState(() { _articles = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _imageUrl(String? img) {
    if (img == null || img.isEmpty) return '';
    return '${AppConfig.mainUrl}/assets/blog/$img';
  }

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day}/${dt.month}/${dt.year + 543}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28, color: AppTheme.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ประชาสัมพันธ์',
          style: GoogleFonts.sarabun(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? _errorView()
              : _articles.isEmpty
                  ? _emptyView()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: _articles.length,
                        itemBuilder: (_, i) => _card(_articles[i]),
                      ),
                    ),
    );
  }

  Widget _card(Map<String, dynamic> article) {
    final imgUrl = _imageUrl(article['image'] as String?);
    final title  = (article['title_blog'] as String?) ?? '';
    final date   = _formatDate(article['created_at'] as String?);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: article)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imgUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  imgUrl, height: 180, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.sarabun(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark, height: 1.4)),
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textLight),
                      const SizedBox(width: 4),
                      Text(date, style: GoogleFonts.sarabun(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w600)),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyView() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: AppTheme.primaryLight, shape: BoxShape.circle),
        child: const Icon(Icons.newspaper_rounded, color: AppTheme.primary, size: 40),
      ),
      const SizedBox(height: 14),
      Text('ยังไม่มีประกาศ', style: GoogleFonts.sarabun(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
      const SizedBox(height: 6),
      Text('ติดตามข่าวสารได้ที่นี่', style: GoogleFonts.sarabun(fontSize: 13, color: AppTheme.textLight)),
    ]),
  );

  Widget _errorView() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.textLight),
      const SizedBox(height: 12),
      Text('โหลดข้อมูลไม่สำเร็จ', style: GoogleFonts.sarabun(fontSize: 15, color: AppTheme.textMedium)),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: () { setState(() { _loading = true; _error = null; }); _load(); },
        style: ElevatedButton.styleFrom(minimumSize: const Size(140, 44)),
        child: Text('ลองใหม่', style: GoogleFonts.sarabun(fontWeight: FontWeight.w700)),
      ),
    ]),
  );
}

// ── Detail Screen ─────────────────────────────────────────────────────────────

class ArticleDetailScreen extends StatelessWidget {
  final Map<String, dynamic> article;
  const ArticleDetailScreen({super.key, required this.article});

  String _imageUrl(String? img) {
    if (img == null || img.isEmpty) return '';
    return '${AppConfig.mainUrl}/assets/blog/$img';
  }

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day}/${dt.month}/${dt.year + 543}';
    } catch (_) { return ''; }
  }

  // แบ่ง HTML เป็น segments: { type: 'text'|'img', value: '...' }
  List<Map<String, String>> _parseHtml(String html) {
    final segments = <Map<String, String>>[];
    // จับ <img src="..."> หรือ <img src='...'>
    final imgReg = RegExp(r'''<img[^>]+src=["']([^"']+)["'][^>]*>''', caseSensitive: false);
    int cursor = 0;
    for (final m in imgReg.allMatches(html)) {
      if (m.start > cursor) {
        final text = _stripTags(html.substring(cursor, m.start)).trim();
        if (text.isNotEmpty) segments.add({'type': 'text', 'value': text});
      }
      segments.add({'type': 'img', 'value': m.group(1)!});
      cursor = m.end;
    }
    if (cursor < html.length) {
      final text = _stripTags(html.substring(cursor)).trim();
      if (text.isNotEmpty) segments.add({'type': 'text', 'value': text});
    }
    return segments;
  }

  String _stripTags(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>',  caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<p[^>]*>',   caseSensitive: false), '')
        .replaceAll(RegExp(r'</p>',        caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<li[^>]*>',  caseSensitive: false), '• ')
        .replaceAll(RegExp(r'<[^>]+>'),    '')
        .replaceAll(RegExp(r'&nbsp;'),     ' ')
        .replaceAll(RegExp(r'&amp;'),      '&')
        .replaceAll(RegExp(r'&lt;'),       '<')
        .replaceAll(RegExp(r'&gt;'),       '>')
        .replaceAll(RegExp(r'&quot;'),     '"')
        .replaceAll(RegExp(r'\n{3,}'),     '\n\n')
        .trim();
  }

  String _resolveImgUrl(String src) {
    if (src.startsWith('http')) return src;
    if (src.startsWith('/')) return '${AppConfig.mainUrl}$src';
    return '${AppConfig.mainUrl}/$src';
  }

  @override
  Widget build(BuildContext context) {
    final title   = (article['title_blog'] as String?) ?? '';
    final detail  = (article['detail_blog_website'] as String?)?.isNotEmpty == true
        ? (article['detail_blog_website'] as String)
        : (article['detail_blog'] as String?) ?? '';
    final imgUrl  = _imageUrl(article['image'] as String?);
    final date    = _formatDate(article['created_at'] as String?);
    final segments = _parseHtml(detail);

    debugPrint('[Article] keys: ${article.keys.toList()}');
    debugPrint('[Article] detail_blog length: ${detail.length}');
    debugPrint('[Article] detail_blog preview: ${detail.length > 200 ? detail.substring(0, 200) : detail}');
    debugPrint('[Article] segments: ${segments.length}');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28, color: AppTheme.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('ประชาสัมพันธ์',
            style: GoogleFonts.sarabun(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover image ──────────────────────────────────────────
            if (imgUrl.isNotEmpty)
              Image.network(
                imgUrl, height: 220, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),

            // ── Title + date ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.sarabun(
                          fontSize: 21, fontWeight: FontWeight.w900,
                          color: AppTheme.textDark, height: 1.35)),
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.calendar_today_outlined, size: 13, color: AppTheme.textLight),
                      const SizedBox(width: 4),
                      Text(date, style: GoogleFonts.sarabun(
                          fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w600)),
                    ]),
                  ],
                  const SizedBox(height: 14),
                  Divider(color: AppTheme.border),
                  const SizedBox(height: 6),
                ],
              ),
            ),

            // ── Content segments ─────────────────────────────────────
            if (detail.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('ไม่มีเนื้อหา',
                    style: GoogleFonts.sarabun(fontSize: 14, color: AppTheme.textLight)),
              )
            else if (segments.isEmpty)
              // fallback: แสดง raw stripped text
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  _stripTags(detail),
                  style: GoogleFonts.sarabun(fontSize: 15, color: AppTheme.textDark, height: 1.75),
                ),
              )
            else
              ...segments.map((seg) {
                if (seg['type'] == 'img') {
                  final url = _resolveImgUrl(seg['value']!);
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        url, width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Text(seg['value']!,
                      style: GoogleFonts.sarabun(
                          fontSize: 15, color: AppTheme.textDark,
                          height: 1.75, fontWeight: FontWeight.w400)),
                );
              }),
          ],
        ),
      ),
    );
  }
}
