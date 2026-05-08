import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
// ignore: unused_import
import 'video_player_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  int _tabIndex = 0;
  bool _showFullDesc = false;

  static const String _description =
      'เรียน มินนะ โนะ นิฮงโกะ ออนไลน์ Minna no Nihongo เล่ม 1 เล่ม 2 ONLINE คอร์ส เรียนภาษาญี่ปุ่น สุดคุ้ม "จาก 0 สู่ N5" ราคา คอร์สเรียน เฉลี่ยเดือนละ 375 บาท ที่เดียวที่สอน accent การออกเสียง ภาษาญี่ปุ่น เสียงสูงต่ำ อย่างละเอียด ทุกคำ อ่านอักษร ฮิรางานะ คาตาคานะ ได้คล่อง เข้าใจไวยากรณ์ Minna 1+2 ครบทุกบท พูดทักทาย แนะนำตัว ใช้ในชีวิตประจำวันได้';

  static const List<_LessonItem> _lessons = [
    _LessonItem('แนะนำคอร์ส และวิธีการเรียน', '12 min', Color(0xFFFF6B8A), Icons.play_circle_outline),
    _LessonItem('มินนะ บทที่ 1 หน้า 54 練習A ไวยากรณ์ は', '15 min', Color(0xFF5B8DEF), Icons.menu_book_outlined),
    _LessonItem('มินนะ บทที่ 1 หน้า 54 練習A ไวยากรณ์ です', '18 min', Color(0xFFFFB347), Icons.emoji_emotions_outlined),
    _LessonItem('ไวยากรณ์ มินนะ บทที่ 7 あげます (1) ละเอียดสุด', '20 min', Color(0xFF7EC8E3), Icons.edit_outlined),
    _LessonItem('ไวยากรณ์ มินนะ บทที่ 7 あげます (2) ละเอียดสุด', '22 min', Color(0xFFD291BC), Icons.remove_red_eye_outlined),
    _LessonItem('ไวยากรณ์ มินนะ บทที่ 7 くれます ละเอียดสุด', '25 min', Color(0xFF87CEAB), Icons.map_outlined),
    _LessonItem('การแยกกลุ่มกริยา (นอกเหนือตำราเรียนร่วมกับคอร์ส AD1)', '12 min', Color(0xFFFF8C69), Icons.flag_outlined),
    _LessonItem('การผันกริยารูป ます (นอกเหนือตำราเรียนร่วมกับคอร์ส AD1)', '15 min', Color(0xFFDDA0DD), Icons.local_florist_outlined),
  ];

  static const List<_Review> _reviews = [
    _Review('น้องไอย์', 5, 'อธิบายเข้าใจง่ายมากค่ะ ครูพี่โฮมสอนละเอียดทุก step คุ้มค่าคาจริงๆ', Color(0xFFFF8FAB)),
    _Review('พี่ตูน', 5, 'จาก 0 มาถึง N5 ได้จริง ดูซ้ำได้ไม่จำกัดด้วย', Color(0xFF6BCB77)),
    _Review('น้องบีม', 5, 'เนื้อหาแน่นมาก แถม PDF ให้กกทวนด้วย ประกันใจสุดๆ', Color(0xFFFFAA5A)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildVideoThumbnail()),
          SliverToBoxAdapter(child: _buildCourseInfo()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBar(
              tabIndex: _tabIndex,
              onChanged: (i) => setState(() => _tabIndex = i),
            ),
          ),
          SliverToBoxAdapter(child: _buildTabContent()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  // ─── App Bar ───────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 30),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
      title: Text(
        'รายละเอียดคอร์ส',
        style: GoogleFonts.sarabun(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
    );
  }

  // ─── Video Thumbnail ───────────────────────────────────────────────────────

  Widget _buildVideoThumbnail() {
    return Container(
      height: 210,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B8A), Color(0xFFFF8E53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30, right: -30,
            child: Container(
              width: 130, height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -20, left: 60,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 16, left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'MINNA',
                      style: GoogleFonts.sarabun(
                        fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '1+2',
                        style: GoogleFonts.sarabun(
                          fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'ภาษาญี่ปุ่น',
                  style: GoogleFonts.sarabun(
                    fontSize: 13, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Container(
              width: 58, height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 5))],
              ),
              child: const Icon(Icons.play_arrow_rounded, color: AppTheme.primary, size: 34),
            ),
          ),
          Positioned(
            top: 12, right: 12,
            child: Row(
              children: [
                _overlayBtn(Icons.bookmark_border_rounded),
                const SizedBox(width: 8),
                _overlayBtn(Icons.share_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _overlayBtn(IconData icon) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: AppTheme.textDark),
    );
  }

  // ─── Course Info ───────────────────────────────────────────────────────────

  Widget _buildCourseInfo() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ติวโค้งสุดท้าย A-Level ญี่ปุ่น',
            style: GoogleFonts.sarabun(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark, height: 1.3),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: [
              _chip(Icons.access_time_rounded, '2h 30m', AppTheme.primary),
              _chip(Icons.flag_outlined, 'ได้สุดท้าย A-Level', AppTheme.primary),
              _chip(Icons.star_rounded, '5.0', const Color(0xFFFFB800)),
            ],
          ),
          const SizedBox(height: 10),
          Text('953 students', style: GoogleFonts.sarabun(fontSize: 13, color: AppTheme.textLight)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.sarabun(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─── Tab Content Router ────────────────────────────────────────────────────

  Widget _buildTabContent() {
    switch (_tabIndex) {
      case 1: return _buildLessonsContent();
      case 2: return _buildReviewsContent();
      case 3: return _buildQuizContent();
      default: return _buildOverviewContent();
    }
  }

  // ─── Overview ─────────────────────────────────────────────────────────────

  Widget _buildOverviewContent() {
    return Column(
      children: [
        _buildDescSection(),
        _buildWhatYouLearnSection(),
        _buildInstructorSection(),
        _buildFeaturesSection(),
        _buildLessonsPreview(),
      ],
    );
  }

  Widget _buildDescSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Overview'),
          const SizedBox(height: 10),
          Text(
            _description,
            maxLines: _showFullDesc ? null : 4,
            overflow: _showFullDesc ? null : TextOverflow.ellipsis,
            style: GoogleFonts.sarabun(fontSize: 13, color: AppTheme.textMedium, height: 1.7),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _showFullDesc = !_showFullDesc),
            child: Text(
              _showFullDesc ? 'Show less' : 'Show more',
              style: GoogleFonts.sarabun(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatYouLearnSection() {
    const items = [
      'อ่าน ฮิรางานะ คาตาคานะ ได้คล่อง',
      'เข้าใจไวยากรณ์ Minna 1+2 ครบทุกบท',
      'พูดทักทาย แนะนำตัว ใช้ในชีวิตประจำวันได้',
      'ฝึกกริยา て-form / て-form / ない-form / Plain ได้',
      'พร้อมต่อยอดสู่ระดับ N4 และเตรียมสอบ JLPT N5',
    ];
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('สิ่งที่คุณจะได้เรียน'),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20, height: 20,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(5)),
                  child: const Icon(Icons.check, size: 13, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(item, style: GoogleFonts.sarabun(fontSize: 13, color: AppTheme.textMedium, height: 1.5)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildInstructorSection() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('ผู้สอน'),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 58, height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF0A8A7E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Center(
                  child: Text('ホ', style: GoogleFonts.sarabun(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ครูพี่โฮม', style: GoogleFonts.sarabun(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                    Text('ผู้เชี่ยวชาญภาษาญี่ปุ่น JLPT N1', style: GoogleFonts.sarabun(fontSize: 12, color: AppTheme.textLight)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _stat('12K+', 'ผู้เรียน'),
                        const SizedBox(width: 16),
                        _stat('24', 'คอร์ส'),
                        const SizedBox(width: 16),
                        _stat('4.9★', 'คะแนน'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.sarabun(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primary)),
        Text(label, style: GoogleFonts.sarabun(fontSize: 10, color: AppTheme.textLight)),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      const _Feature(Icons.play_circle_outline_rounded, 'ดูได้ไม่จำกัด'),
      const _Feature(Icons.devices_rounded, 'ดูได้ทุกอุปกรณ์'),
      const _Feature(Icons.picture_as_pdf_outlined, 'มี PDF ดาวน์โหลด'),
      const _Feature(Icons.chat_bubble_outline_rounded, 'ถาม-ตอบกับครูได้'),
      const _Feature(Icons.workspace_premium_outlined, 'มีประกาศนียบัตร'),
      const _Feature(Icons.refresh_rounded, 'คืนเงินใน 7 วัน'),
    ];
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('คุณสมบัติของคอร์ส'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: features.map((f) {
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 52) / 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(f.icon, size: 16, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(f.label, style: GoogleFonts.sarabun(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsPreview() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Lessons'),
          const SizedBox(height: 4),
          Text('38 Lessons · ทั้งหมด 13 ชั่วโมง', style: GoogleFonts.sarabun(fontSize: 12, color: AppTheme.textLight)),
          const SizedBox(height: 12),
          ..._lessons.take(3).map((l) => _lessonRow(l)),
          GestureDetector(
            onTap: () => setState(() => _tabIndex = 1),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              child: Text(
                'ดูบทเรียนทั้งหมด 38 บท →',
                style: GoogleFonts.sarabun(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Lessons ───────────────────────────────────────────────────────────────

  Widget _buildLessonsContent() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Lessons'),
                const SizedBox(height: 4),
                Text('38 Lessons · ทั้งหมด 13 ชั่วโมง', style: GoogleFonts.sarabun(fontSize: 12, color: AppTheme.textLight)),
              ],
            ),
          ),
          ..._lessons.map((l) => _lessonRow(l)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text('ดูบทเรียนทั้งหมด 38 บท →', style: GoogleFonts.sarabun(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lessonRow(_LessonItem lesson) {
    return GestureDetector(
      onTap: () => context.push('/video'),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border.withOpacity(0.5)))),
      child: Row(
        children: [
          Container(
            width: 52, height: 42,
            decoration: BoxDecoration(color: lesson.color, borderRadius: BorderRadius.circular(10)),
            child: Icon(lesson.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lesson.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.sarabun(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark, height: 1.4)),
                const SizedBox(height: 3),
                Text(lesson.duration, style: GoogleFonts.sarabun(fontSize: 11, color: AppTheme.textLight)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(color: AppTheme.primaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.play_arrow_rounded, color: AppTheme.primary, size: 18),
          ),
        ],
      ),
    ));
  }

  // ─── Reviews ───────────────────────────────────────────────────────────────

  Widget _buildReviewsContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildRatingSummary(),
          const SizedBox(height: 16),
          ..._reviews.map((r) => _reviewCard(r)),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text('5.0',
                style: GoogleFonts.sarabun(fontSize: 48, fontWeight: FontWeight.w900, color: AppTheme.textDark, height: 1)),
              const SizedBox(height: 6),
              Row(children: List.generate(5, (_) => const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB800)))),
              const SizedBox(height: 4),
              Text('248 รีวิว', style: GoogleFonts.sarabun(fontSize: 11, color: AppTheme.textLight)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                _ratingBar(5, 0.82, '82%'),
                _ratingBar(4, 0.14, '14%'),
                _ratingBar(3, 0.03, '3%'),
                _ratingBar(2, 0.01, '1%'),
                _ratingBar(1, 0.00, '0%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingBar(int star, double value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$star★', style: GoogleFonts.sarabun(fontSize: 11, color: AppTheme.textLight)),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: AppTheme.border,
                valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 28,
            child: Text(label, textAlign: TextAlign.right, style: GoogleFonts.sarabun(fontSize: 11, color: AppTheme.textLight)),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(_Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: review.avatarColor, shape: BoxShape.circle),
            child: Center(
              child: Text(review.name.substring(0, 1),
                style: GoogleFonts.sarabun(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(review.name, style: GoogleFonts.sarabun(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                const SizedBox(height: 3),
                Row(children: List.generate(review.rating, (_) => const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFFB800)))),
                const SizedBox(height: 6),
                Text(review.text, style: GoogleFonts.sarabun(fontSize: 13, color: AppTheme.textMedium, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Quiz Tab ──────────────────────────────────────────────────────────────

  static const _quizSets = [
    _QuizSet('แบบฝึกหัด บทที่ 1 は・です', 5, 'ง่าย', Color(0xFF4CAF50)),
    _QuizSet('แบบฝึกหัด บทที่ 7 あげます・くれます', 5, 'ปานกลาง', Color(0xFFFF9800)),
    _QuizSet('แบบฝึกหัด การผันกริยา กลุ่ม 1-3', 8, 'ยาก', Color(0xFFE8273D)),
    _QuizSet('ทบทวนรวม Minna บทที่ 1-7', 10, 'ปานกลาง', Color(0xFFFF9800)),
  ];

  Widget _buildQuizContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0FB5A6), Color(0xFF0A8C80)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.quiz_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('แบบฝึกหัดทั้งหมด',
                          style: GoogleFonts.sarabun(
                              fontSize: 15, color: Colors.white,
                              fontWeight: FontWeight.w800)),
                      Text('${_quizSets.length} ชุด · ทำได้ไม่จำกัดครั้ง',
                          style: GoogleFonts.sarabun(
                              fontSize: 12, color: Colors.white70,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ..._quizSets.map((q) => _quizSetCard(q, context)),
        ],
      ),
    );
  }

  Widget _quizSetCard(_QuizSet quiz, BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/quiz', extra: quiz.title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.assignment_rounded,
                  color: AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quiz.title,
                      style: GoogleFonts.sarabun(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.help_outline_rounded,
                          size: 13, color: AppTheme.textLight),
                      const SizedBox(width: 3),
                      Text('${quiz.questionCount} ข้อ',
                          style: GoogleFonts.sarabun(
                              fontSize: 12, color: AppTheme.textLight,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: quiz.diffColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(quiz.difficulty,
                            style: GoogleFonts.sarabun(
                                fontSize: 11, color: quiz.diffColor,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: AppTheme.primary, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Bar ────────────────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('฿5,530',
                style: GoogleFonts.sarabun(fontSize: 13, color: AppTheme.textLight, decoration: TextDecoration.lineThrough)),
              Text('฿3,950',
                style: GoogleFonts.sarabun(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textDark, height: 1.1)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => context.push('/payment', extra: {
                'title': 'ติวโค้งสุดท้าย A-Level ญี่ปุ่น',
                'price': 3950,
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text('จองคอร์สเรียน', style: GoogleFonts.sarabun(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4, height: 18,
          decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.sarabun(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
      ],
    );
  }
}

// ─── Sticky Tab Bar ───────────────────────────────────────────────────────────

class _StickyTabBar extends SliverPersistentHeaderDelegate {
  final int tabIndex;
  final ValueChanged<int> onChanged;

  const _StickyTabBar({required this.tabIndex, required this.onChanged});

  static const _tabs = ['Overview', 'Lessons (38)', 'รีวิว (248)', 'แบบฝึกหัด'];

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
        boxShadow: overlapsContent
            ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 3))]
            : [],
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final selected = tabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected ? AppTheme.primary : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _tabs[i],
                  style: GoogleFonts.sarabun(
                    fontSize: 11.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected ? AppTheme.primary : AppTheme.textLight,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyTabBar old) =>
      old.tabIndex != tabIndex;
}

// ─── Data Classes ─────────────────────────────────────────────────────────────

class _LessonItem {
  final String title, duration;
  final Color color;
  final IconData icon;
  const _LessonItem(this.title, this.duration, this.color, this.icon);
}

class _Review {
  final String name, text;
  final int rating;
  final Color avatarColor;
  const _Review(this.name, this.rating, this.text, this.avatarColor);
}

class _QuizSet {
  final String title;
  final int questionCount;
  final String difficulty;
  final Color diffColor;
  const _QuizSet(this.title, this.questionCount, this.difficulty, this.diffColor);
}

class _Feature {
  final IconData icon;
  final String label;
  const _Feature(this.icon, this.label);
}
