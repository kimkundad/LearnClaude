import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildHero()),
          SliverToBoxAdapter(child: _buildFounderCard()),
          SliverToBoxAdapter(child: _buildStatsRow()),
          SliverToBoxAdapter(child: _buildHighlight()),
          SliverToBoxAdapter(child: _buildAchievements()),
          SliverToBoxAdapter(child: _buildExperience()),
          SliverToBoxAdapter(child: _buildContact(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ─── App Bar ───────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.primary,
      elevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 30),
          onPressed: () => ctx.canPop() ? ctx.pop() : ctx.go('/home'),
        ),
      ),
      title: Text(
        'เกี่ยวกับเรา',
        style: GoogleFonts.sarabun(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      centerTitle: true,
    );
  }

  // ─── Hero ──────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, Color(0xFF0A8A7E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      child: Column(
        children: [
          // Logo
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
            ),
            child: Center(
              child: Text(
                'ホ',
                style: GoogleFonts.sarabun(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ZA-SHI · Learnsbuy',
            style: GoogleFonts.sarabun(fontSize: 13, color: Colors.white.withOpacity(0.8), letterSpacing: 1.5),
          ),
          const SizedBox(height: 6),
          Text(
            'เสาหลักแห่งศิลป์ญี่ปุ่น',
            style: GoogleFonts.sarabun(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'สถาบันสอนภาษาญี่ปุ่นออนไลน์ ที่เชื่อว่าทุกคนเรียนได้\nด้วยระบบที่ออกแบบมาเพื่อผลสอบจริง',
            style: GoogleFonts.sarabun(fontSize: 14, color: Colors.white.withOpacity(0.9), height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Founder Card ──────────────────────────────────────────────────────────

  Widget _buildFounderCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Top teal band
          Container(
            height: 6,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.primary, Color(0xFF0A8A7E)]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, Color(0xFF0A8A7E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Center(
                    child: Text('ホ', style: GoogleFonts.sarabun(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('ผู้ก่อตั้ง & ผู้สอนหลัก',
                          style: GoogleFonts.sarabun(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 6),
                      Text('ครูพี่โฮม',
                        style: GoogleFonts.sarabun(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textDark)),
                      Text('อ.ประมาตร ชัยกิตติวานิช',
                        style: GoogleFonts.sarabun(fontSize: 12, color: AppTheme.textLight)),
                      const SizedBox(height: 8),
                      Text(
                        'อักษรศาสตร์บัณฑิต จุฬาฯ เกียรตินิยมอันดับ 1 เหรียญทอง เอกภาษาญี่ปุ่น',
                        style: GoogleFonts.sarabun(fontSize: 12, color: AppTheme.textMedium, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // PAT badge
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFFFF8E1), const Color(0xFFFFF3CD)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFB800).withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB800),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('คะแนน PAT ภาษาญี่ปุ่น 300/300',
                        style: GoogleFonts.sarabun(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF7B5900))),
                      Text('คนเดียวในประเทศไทยที่ทำได้',
                        style: GoogleFonts.sarabun(fontSize: 12, color: const Color(0xFF9D6C00))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stats ─────────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    final stats = [
      _Stat('12K+', 'ผู้เรียน', Icons.people_alt_rounded),
      _Stat('24', 'คอร์ส', Icons.play_lesson_rounded),
      _Stat('4.9★', 'คะแนน', Icons.star_rounded),
      _Stat('8 ปี', 'ประสบการณ์', Icons.workspace_premium_rounded),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: stats.map((s) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                Icon(s.icon, size: 20, color: AppTheme.primary),
                const SizedBox(height: 6),
                Text(s.value, style: GoogleFonts.sarabun(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.textDark)),
                Text(s.label, style: GoogleFonts.sarabun(fontSize: 10, color: AppTheme.textLight)),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }

  // ─── Highlight ─────────────────────────────────────────────────────────────

  Widget _buildHighlight() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('เกี่ยวกับเรา', Icons.info_outline_rounded),
          const SizedBox(height: 12),
          Text(
            'Learnsbuy / ZA-SHI คือสถาบันสอนภาษาออนไลน์ที่เชี่ยวชาญด้านภาษาญี่ปุ่น เกาหลี เยอรมัน และจีน ครอบคลุมทั้งการเตรียมสอบ A-Level PAT และ JLPT ทุกระดับ ด้วยระบบการสอนที่ออกแบบให้เรียนซ้ำได้ วัดผลได้จริง พร้อม PDF และช่องทางถาม-ตอบกับครูโดยตรง',
            style: GoogleFonts.sarabun(fontSize: 14, color: AppTheme.textMedium, height: 1.7),
          ),
        ],
      ),
    );
  }

  // ─── Achievements ──────────────────────────────────────────────────────────

  Widget _buildAchievements() {
    final items = [
      _Item(Icons.military_tech_rounded, 'เกียรตินิยมอันดับ 1 เหรียญทอง', 'จุฬาลงกรณ์มหาวิทยาลัย เอกภาษาญี่ปุ่น'),
      _Item(Icons.emoji_events_rounded, 'PAT ภาษาญี่ปุ่น 300/300', 'คนเดียวในประเทศไทยที่ทำได้เต็ม'),
      _Item(Icons.flight_takeoff_rounded, 'ทุนแลกเปลี่ยนที่โตเกียว', 'ได้รับทุนศึกษาภาษาญี่ปุ่น ณ กรุงโตเกียว'),
      _Item(Icons.trending_up_rounded, 'สถิติสูงสุดในไทย', 'พาผู้เรียนสอบติดจุฬาฯ สูงที่สุดในประเทศ'),
      _Item(Icons.record_voice_over_rounded, 'วิทยากรระดับนานาชาติ', 'Toyota, Mitsubishi Tokyo UFJ, EXPO 2005 Aichi'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('ผลงานและรางวัล', Icons.emoji_events_outlined),
          const SizedBox(height: 14),
          ...items.map((item) => _itemRow(item)),
        ],
      ),
    );
  }

  // ─── Experience ────────────────────────────────────────────────────────────

  Widget _buildExperience() {
    final items = [
      _Item(Icons.school_rounded, 'หัวหน้าสาขาภาษาญี่ปุ่น', 'จุฬาลงกรณ์มหาวิทยาลัย'),
      _Item(Icons.business_rounded, 'ล่ามและวิทยากรองค์กร', 'Fujitsu, JICA, กรมส่งเสริมการส่งออก'),
      _Item(Icons.language_rounded, 'ผู้สอนภาษาไทย', 'JETRO (องค์การส่งเสริมการค้าต่างประเทศของญี่ปุ่น)'),
      _Item(Icons.public_rounded, 'ผู้ประสานงาน EXPO 2005', 'งาน World Expo เมือง Aichi ประเทศญี่ปุ่น'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('ประสบการณ์', Icons.work_outline_rounded),
          const SizedBox(height: 14),
          ...items.map((item) => _itemRow(item)),
        ],
      ),
    );
  }

  // ─── Contact ───────────────────────────────────────────────────────────────

  Widget _buildContact(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF0A8A7E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              children: [
                Text('ติดต่อเรา',
                  style: GoogleFonts.sarabun(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 4),
                Text('พร้อมตอบทุกคำถามเกี่ยวกับการเรียน',
                  style: GoogleFonts.sarabun(fontSize: 13, color: Colors.white.withOpacity(0.85))),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _contactRow(context, Icons.phone_rounded, '02-658-3819 / 02-658-3986', '02-658-3819'),
                _divider(),
                _contactRow(context, Icons.email_outlined, 'learnsbuy@gmail.com', 'learnsbuy@gmail.com'),
                _divider(),
                _contactRow(context, Icons.chat_rounded, 'LINE: @learnsbuy · @za-shi', null),
                _divider(),
                _contactRow(context, Icons.language_rounded, 'learnsbuy.com', null),
              ],
            ),
          ),
          // Social row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Row(
              children: [
                _socialBtn('Facebook', Icons.facebook_rounded),
                const SizedBox(width: 10),
                _socialBtn('Instagram', Icons.camera_alt_outlined),
                const SizedBox(width: 10),
                _socialBtn('Twitter/X', Icons.close),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(BuildContext context, IconData icon, String label, String? copyText) {
    return GestureDetector(
      onTap: copyText != null
          ? () {
              Clipboard.setData(ClipboardData(text: copyText));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('คัดลอก "$copyText" แล้ว', style: GoogleFonts.sarabun()),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppTheme.primary,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: GoogleFonts.sarabun(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            if (copyText != null)
              Icon(Icons.copy_rounded, size: 14, color: Colors.white.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(height: 1, color: Colors.white.withOpacity(0.15), indent: 16, endIndent: 16);
  }

  Widget _socialBtn(String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.sarabun(fontSize: 10, color: Colors.white.withOpacity(0.9))),
          ],
        ),
      ),
    );
  }

  // ─── Shared Helpers ────────────────────────────────────────────────────────

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: AppTheme.primary),
        ),
        const SizedBox(width: 10),
        Text(title, style: GoogleFonts.sarabun(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
      ],
    );
  }

  Widget _itemRow(_Item item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(10)),
            child: Icon(item.icon, size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: GoogleFonts.sarabun(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                Text(item.subtitle, style: GoogleFonts.sarabun(fontSize: 12, color: AppTheme.textLight, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data Classes ─────────────────────────────────────────────────────────────

class _Stat {
  final String value, label;
  final IconData icon;
  const _Stat(this.value, this.label, this.icon);
}

class _Item {
  final IconData icon;
  final String title, subtitle;
  const _Item(this.icon, this.title, this.subtitle);
}
