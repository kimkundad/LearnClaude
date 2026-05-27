import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final String courseTitle;
  final int price;

  const PaymentSuccessScreen({
    super.key,
    this.courseTitle = 'ติวโค้งสุดท้าย A-Level ญี่ปุ่น',
    this.price = 0,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with TickerProviderStateMixin {
  late final AnimationController _checkController;
  late final AnimationController _fadeController;
  late final AnimationController _particleController;
  late final Animation<double> _checkScale;
  late final Animation<double> _checkOpacity;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );
    _checkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _checkController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      _checkController.forward();
      _particleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _fadeController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  static const _thMonths = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
  ];

  String get _orderDate {
    final now = DateTime.now();
    return '${now.day} ${_thMonths[now.month - 1]} ${now.year + 543}';
  }

  String get _orderNumber {
    final now = DateTime.now();
    return 'ORD${now.year}${now.month.toString().padLeft(2, '0')}${now.millisecondsSinceEpoch % 100000}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHero(),
                    _buildOrderCard(),
                    const SizedBox(height: 16),
                    _buildStepsCard(),
                    const SizedBox(height: 16),
                    _buildNoteCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF32D191), Color(0xFF0A8C80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _particleController,
            builder: (_, __) => CustomPaint(
              size: const Size(double.infinity, 220),
              painter: _ConfettiPainter(_particleController.value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _checkController,
                  builder: (_, __) => Opacity(
                    opacity: _checkOpacity.value,
                    child: Transform.scale(
                      scale: _checkScale.value,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppTheme.primary,
                          size: 52,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _fadeIn,
                  child: Column(
                    children: [
                      Text(
                        'ส่งหลักฐานสำเร็จ!',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ทีมงานจะตรวจสอบและยืนยันการชำระเงิน\nภายใน 1-3 ชั่วโมงในวันทำการ',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSansThai(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
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

  Widget _buildOrderCard() {
    return FadeTransition(
      opacity: _fadeIn,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_rounded,
                      color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Text('รายละเอียดคำสั่งซื้อ',
                    style: GoogleFonts.notoSansThai(
                        fontSize: 15, fontWeight: FontWeight.w800,
                        color: AppTheme.textDark)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.pending_rounded,
                          size: 13, color: Color(0xFFE65100)),
                      const SizedBox(width: 4),
                      Text('รอตรวจสอบ',
                          style: GoogleFonts.notoSansThai(
                              fontSize: 11, color: const Color(0xFFE65100),
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _orderRow(Icons.tag_rounded, 'หมายเลขคำสั่งซื้อ', _orderNumber),
            const Divider(height: 20, color: Color(0xFFF0F0F0)),
            _orderRow(Icons.school_rounded, 'คอร์สเรียน', widget.courseTitle,
                valueMaxLines: 2),
            const Divider(height: 20, color: Color(0xFFF0F0F0)),
            _orderRow(Icons.calendar_today_rounded, 'วันที่สั่งซื้อ', _orderDate),
            const Divider(height: 20, color: Color(0xFFF0F0F0)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.payments_rounded,
                    size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text('ยอดชำระ',
                    style: GoogleFonts.notoSansThai(
                        fontSize: 13, color: AppTheme.textLight,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(
                    '฿${widget.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                    style: GoogleFonts.notoSansThai(
                        fontSize: 18, color: AppTheme.primary,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderRow(IconData icon, String label, String value,
      {int valueMaxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(label,
            style: GoogleFonts.notoSansThai(
                fontSize: 13, color: AppTheme.textLight,
                fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value,
              textAlign: TextAlign.right,
              maxLines: valueMaxLines,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.notoSansThai(
                  fontSize: 13, color: AppTheme.textDark,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildStepsCard() {
    final steps = [
      _StepInfo(Icons.upload_file_rounded, 'ส่งหลักฐาน',
          'อัปโหลดสลิปเรียบร้อยแล้ว', true),
      _StepInfo(Icons.manage_search_rounded, 'ตรวจสอบ',
          'ทีมงานกำลังดำเนินการ', false),
      _StepInfo(Icons.verified_rounded, 'ยืนยัน',
          'รอการยืนยันจากทีมงาน', false),
      _StepInfo(Icons.play_circle_rounded, 'เรียนได้เลย!',
          'เข้าถึงคอร์สได้ทันที', false),
    ];

    return FadeTransition(
      opacity: _fadeIn,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.timeline_rounded,
                      color: Color(0xFF388E3C), size: 20),
                ),
                const SizedBox(width: 10),
                Text('ขั้นตอนการดำเนินการ',
                    style: GoogleFonts.notoSansThai(
                        fontSize: 15, fontWeight: FontWeight.w800,
                        color: AppTheme.textDark)),
              ],
            ),
            const SizedBox(height: 20),
            ...List.generate(steps.length, (i) {
              final step = steps[i];
              final isLast = i == steps.length - 1;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: step.done
                              ? AppTheme.primary
                              : AppTheme.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(step.icon,
                            size: 18,
                            color: step.done
                                ? Colors.white
                                : AppTheme.primary.withOpacity(0.4)),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 36,
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: step.done
                                  ? [AppTheme.primary, AppTheme.primary.withOpacity(0.2)]
                                  : [AppTheme.border, AppTheme.border],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          top: 6, bottom: isLast ? 0 : 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(step.title,
                              style: GoogleFonts.notoSansThai(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: step.done
                                      ? AppTheme.textDark
                                      : AppTheme.textLight)),
                          const SizedBox(height: 2),
                          Text(step.subtitle,
                              style: GoogleFonts.notoSansThai(
                                  fontSize: 12,
                                  color: step.done
                                      ? AppTheme.primary
                                      : AppTheme.textLight,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  if (step.done)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('สำเร็จ',
                            style: GoogleFonts.notoSansThai(
                                fontSize: 11, color: AppTheme.primary,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard() {
    return FadeTransition(
      opacity: _fadeIn,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFE082)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded,
                color: Color(0xFFE65100), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'หากไม่ได้รับการยืนยันภายใน 3 ชั่วโมง กรุณาติดต่อทีมงานผ่าน Line Official @ZA-SHI',
                style: GoogleFonts.notoSansThai(
                  fontSize: 13,
                  color: const Color(0xFF5D4037),
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 14, 16, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border.withOpacity(0.6))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.home_rounded, size: 20),
            label: Text('กลับหน้าหลัก',
                style: GoogleFonts.notoSansThai(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.push('/chat'),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: Text('ติดต่อทีมงาน',
                style: GoogleFonts.notoSansThai(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppTheme.primary)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: AppTheme.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepInfo {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool done;
  const _StepInfo(this.icon, this.title, this.subtitle, this.done);
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_Particle> _particles;

  _ConfettiPainter(this.progress)
      : _particles = List.generate(28, (i) {
          final rng = math.Random(i * 37);
          return _Particle(
            x: rng.nextDouble(),
            y: rng.nextDouble() * 0.6,
            size: 4.0 + rng.nextDouble() * 6,
            color: _colors[i % _colors.length],
            speed: 0.4 + rng.nextDouble() * 0.6,
            angle: rng.nextDouble() * math.pi * 2,
          );
        });

  static const _colors = [
    Colors.white,
    Color(0xFFFFD700),
    Color(0xFFFF6B6B),
    Color(0xFF4FC3F7),
    Color(0xFFA5D6A7),
    Color(0xFFCE93D8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final animP = (progress * p.speed).clamp(0.0, 1.0);
      if (animP == 0) continue;
      final paint = Paint()
        ..color = p.color.withOpacity((1 - animP) * 0.7)
        ..style = PaintingStyle.fill;

      final x = p.x * size.width + math.sin(p.angle + progress * 3) * 20;
      final y = p.y * size.height - animP * size.height * 0.5;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * 4 + p.angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class _Particle {
  final double x, y, size, speed, angle;
  final Color color;
  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speed,
    required this.angle,
  });
}
