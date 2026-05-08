import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class MyCourseScreen extends StatefulWidget {
  const MyCourseScreen({super.key});

  @override
  State<MyCourseScreen> createState() => _MyCourseScreenState();
}

class _MyCourseScreenState extends State<MyCourseScreen>
    with SingleTickerProviderStateMixin {
  int _tab = 0;
  late final AnimationController _slideController;
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideIn = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _switchTab(int i) {
    if (_tab == i) return;
    setState(() => _tab = i);
    _slideController
      ..reset()
      ..forward();
  }

  static const _courses = [
    _OwnedCourse(
      title: 'ติวโค้งสุดท้าย A-Level ญี่ปุ่น',
      teacher: 'ครูพี่โฮม',
      progress: 0.68,
      expiresAt: '31 ธ.ค. 2569',
      daysLeft: 242,
      lessonsDone: 26,
      lessonsTotal: 38,
      gradient: [Color(0xFFFF7B8A), Color(0xFFE8273D)],
      icon: Icons.track_changes_rounded,
    ),
    _OwnedCourse(
      title: 'Minna no Nihongo เล่ม 1-2 จาก 0 สู่ N5',
      teacher: 'ครูพี่โฮม',
      progress: 0.34,
      expiresAt: '15 ก.ย. 2569',
      daysLeft: 135,
      lessonsDone: 18,
      lessonsTotal: 54,
      gradient: [Color(0xFF34D399), Color(0xFF047857)],
      icon: Icons.menu_book_rounded,
    ),
    _OwnedCourse(
      title: 'Reading คันจิ ศัพท์ A-Level ญี่ปุ่น N4 N5',
      teacher: 'ครูพี่โฮม',
      progress: 0.12,
      expiresAt: '20 ส.ค. 2569',
      daysLeft: 109,
      lessonsDone: 4,
      lessonsTotal: 32,
      gradient: [Color(0xFF60A5FA), Color(0xFF2563EB)],
      icon: Icons.translate_rounded,
    ),
  ];

  static const _pendingOrders = [
    _PendingOrder(
      orderNumber: 'ORD202605041823',
      title: 'แพ็กเกจสุดคุ้ม ครูพี่โฮม All-in-One',
      price: 8990,
      bankName: 'ธนาคารกสิกรไทย',
      submittedAt: 'วันนี้ 18:23 น.',
      status: _OrderStatus.reviewing,
      gradient: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
      icon: Icons.workspace_premium_rounded,
    ),
    _PendingOrder(
      orderNumber: 'ORD202605031140',
      title: 'ติวโค้งสุดท้าย A-Level ญี่ปุ่น',
      price: 3950,
      bankName: 'ธนาคารไทยพาณิชย์',
      submittedAt: 'เมื่อวาน 11:40 น.',
      status: _OrderStatus.confirmed,
      gradient: [Color(0xFFFF7B8A), Color(0xFFE8273D)],
      icon: Icons.track_changes_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: SlideTransition(
              position: _slideIn,
              child: FadeTransition(
                opacity: _slideController,
                child: _tab == 0 ? _buildActiveTab() : _buildPendingTab(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final pendingCount = _pendingOrders
        .where((o) => o.status != _OrderStatus.confirmed)
        .length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Course',
                  style: GoogleFonts.sarabun(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  _tab == 0
                      ? 'คอร์สทั้งหมดที่ซื้อแล้ว พร้อมวันหมดอายุ'
                      : 'ติดตามสถานะการชำระเงินของคุณ',
                  style: GoogleFonts.sarabun(
                    fontSize: 13,
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school_rounded, color: AppTheme.primary),
              ),
              if (pendingCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8273D),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$pendingCount',
                        style: GoogleFonts.sarabun(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final pendingCount = _pendingOrders
        .where((o) => o.status != _OrderStatus.confirmed)
        .length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _tabItem(0, Icons.play_circle_rounded, 'กำลังเรียน', null),
          _tabItem(1, Icons.pending_actions_rounded, 'รอยืนยัน',
              pendingCount > 0 ? pendingCount : null),
        ],
      ),
    );
  }

  Widget _tabItem(int index, IconData icon, String label, int? badge) {
    final selected = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? AppTheme.primary : AppTheme.textLight,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.sarabun(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? AppTheme.primary : AppTheme.textLight,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary
                        : const Color(0xFFE8273D),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$badge',
                    style: GoogleFonts.sarabun(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Tab 0: กำลังเรียน ──────────────────────────────────────────────────────

  Widget _buildActiveTab() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildSummary()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => Padding(
                padding: EdgeInsets.only(
                  bottom: i == _courses.length - 1 ? 0 : 14,
                ),
                child: _courseCard(_courses[i], context),
              ),
              childCount: _courses.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _summaryItem('3', 'คอร์สที่มี'),
          _divider(),
          _summaryItem('48', 'บทเรียนแล้ว'),
          _divider(),
          _summaryItem('109', 'วันขั้นต่ำ'),
        ],
      ),
    );
  }

  Widget _summaryItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.sarabun(
              fontSize: 24,
              height: 1,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: GoogleFonts.sarabun(
              fontSize: 11,
              color: Colors.white.withOpacity(0.86),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 34,
        color: Colors.white.withOpacity(0.22),
      );

  Widget _courseCard(_OwnedCourse course, BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/course'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            SizedBox(
              height: 132,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: course.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 22,
                    top: 32,
                    child: Icon(
                      course.icon,
                      size: 66,
                      color: Colors.white.withOpacity(0.72),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${course.lessonsDone}/${course.lessonsTotal} lessons',
                        style: GoogleFonts.sarabun(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 92,
                    bottom: 16,
                    child: Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.sarabun(
                        fontSize: 18,
                        height: 1.22,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_rounded,
                          size: 16, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          course.teacher,
                          style: GoogleFonts.sarabun(
                            fontSize: 13,
                            color: AppTheme.textMedium,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _expiryBadge(course.daysLeft),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: course.progress,
                      minHeight: 8,
                      backgroundColor: AppTheme.border.withOpacity(0.65),
                      valueColor:
                          const AlwaysStoppedAnimation(AppTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Text(
                        '${(course.progress * 100).round()}% completed',
                        style: GoogleFonts.sarabun(
                          fontSize: 12,
                          color: AppTheme.textLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'หมดอายุ ${course.expiresAt}',
                        style: GoogleFonts.sarabun(
                          fontSize: 12,
                          color: AppTheme.textMedium,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/video'),
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: Text(
                      'เรียนต่อ',
                      style: GoogleFonts.sarabun(fontWeight: FontWeight.w900),
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

  Widget _expiryBadge(int daysLeft) {
    final isSoon = daysLeft <= 120;
    final color = isSoon ? AppTheme.priceRed : AppTheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'เหลือ $daysLeft วัน',
        style: GoogleFonts.sarabun(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // ─── Tab 1: รอยืนยัน ────────────────────────────────────────────────────────

  Widget _buildPendingTab() {
    if (_pendingOrders.isEmpty) {
      return _buildEmptyPending();
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _buildPendingBanner(),
        const SizedBox(height: 16),
        ..._pendingOrders.map((o) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _pendingOrderCard(o),
            )),
      ],
    );
  }

  Widget _buildPendingBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFECB3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_rounded,
                color: Color(0xFFE65100), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'ทีมงานจะตรวจสอบสลิปและยืนยันการชำระภายใน 1-3 ชม. ในวันทำการ',
              style: GoogleFonts.sarabun(
                fontSize: 12,
                color: const Color(0xFF5D4037),
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pendingOrderCard(_PendingOrder order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Thumbnail header
          Container(
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: order.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 16,
                  top: 12,
                  child: Icon(order.icon,
                      size: 58, color: Colors.white.withOpacity(0.18)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          _statusPill(order.status),
                          const Spacer(),
                          Text(
                            '#${order.orderNumber.substring(order.orderNumber.length - 6)}',
                            style: GoogleFonts.sarabun(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        order.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.sarabun(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Info row
                Row(
                  children: [
                    _infoChip(
                      Icons.payments_rounded,
                      '฿${order.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                      AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    _infoChip(
                        Icons.account_balance_rounded,
                        order.bankName.replaceFirst('ธนาคาร', ''),
                        const Color(0xFF5C6BC0)),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 13, color: AppTheme.textLight),
                        const SizedBox(width: 4),
                        Text(
                          order.submittedAt,
                          style: GoogleFonts.sarabun(
                            fontSize: 12,
                            color: AppTheme.textLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Timeline
                _buildTimeline(order.status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(_OrderStatus status) {
    final info = _statusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: info.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            info.label,
            style: GoogleFonts.sarabun(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.sarabun(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(_OrderStatus currentStatus) {
    final steps = [
      _TimelineStep(
        icon: Icons.upload_file_rounded,
        label: 'ส่งสลิปแล้ว',
        done: true,
        active: false,
      ),
      _TimelineStep(
        icon: Icons.manage_search_rounded,
        label: 'กำลังตรวจสอบ',
        done: currentStatus.index >= _OrderStatus.confirmed.index,
        active: currentStatus == _OrderStatus.reviewing,
      ),
      _TimelineStep(
        icon: Icons.verified_rounded,
        label: 'ยืนยันแล้ว',
        done: currentStatus == _OrderStatus.confirmed,
        active: false,
      ),
      _TimelineStep(
        icon: Icons.play_circle_rounded,
        label: 'เรียนได้เลย!',
        done: currentStatus == _OrderStatus.confirmed,
        active: false,
      ),
    ];

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // connector line
          final leftDone = steps[i ~/ 2].done;
          return Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: leftDone
                      ? [AppTheme.primary, AppTheme.primary.withOpacity(0.3)]
                      : [AppTheme.border, AppTheme.border],
                ),
              ),
            ),
          );
        }
        final step = steps[i ~/ 2];
        return _timelineNode(step);
      }),
    );
  }

  Widget _timelineNode(_TimelineStep step) {
    Color bg;
    Color iconColor;
    if (step.done) {
      bg = AppTheme.primary;
      iconColor = Colors.white;
    } else if (step.active) {
      bg = const Color(0xFFFF9800);
      iconColor = Colors.white;
    } else {
      bg = AppTheme.border.withOpacity(0.5);
      iconColor = AppTheme.textLight;
    }

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: step.active
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF9800).withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: step.active
              ? Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.3),
                    ),
                  ),
                )
              : Icon(step.icon, size: 16, color: iconColor),
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: 60,
          child: Text(
            step.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.sarabun(
              fontSize: 10,
              color: step.done
                  ? AppTheme.primary
                  : step.active
                      ? const Color(0xFFE65100)
                      : AppTheme.textLight,
              fontWeight: step.done || step.active
                  ? FontWeight.w700
                  : FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPending() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppTheme.primary, size: 48),
          ),
          const SizedBox(height: 16),
          Text('ไม่มีรายการรอยืนยัน',
              style: GoogleFonts.sarabun(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark)),
          const SizedBox(height: 6),
          Text('การชำระเงินทั้งหมดได้รับการยืนยันแล้ว',
              style: GoogleFonts.sarabun(
                  fontSize: 13, color: AppTheme.textLight,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  _StatusInfo _statusInfo(_OrderStatus status) {
    switch (status) {
      case _OrderStatus.reviewing:
        return _StatusInfo('กำลังตรวจสอบ', const Color(0xFFFF9800));
      case _OrderStatus.confirmed:
        return _StatusInfo('ยืนยันแล้ว', AppTheme.primary);
    }
  }
}

// ─── Data Classes ─────────────────────────────────────────────────────────────

class _OwnedCourse {
  final String title;
  final String teacher;
  final double progress;
  final String expiresAt;
  final int daysLeft;
  final int lessonsDone;
  final int lessonsTotal;
  final List<Color> gradient;
  final IconData icon;

  const _OwnedCourse({
    required this.title,
    required this.teacher,
    required this.progress,
    required this.expiresAt,
    required this.daysLeft,
    required this.lessonsDone,
    required this.lessonsTotal,
    required this.gradient,
    required this.icon,
  });
}

enum _OrderStatus { reviewing, confirmed }

class _PendingOrder {
  final String orderNumber;
  final String title;
  final int price;
  final String bankName;
  final String submittedAt;
  final _OrderStatus status;
  final List<Color> gradient;
  final IconData icon;

  const _PendingOrder({
    required this.orderNumber,
    required this.title,
    required this.price,
    required this.bankName,
    required this.submittedAt,
    required this.status,
    required this.gradient,
    required this.icon,
  });
}

class _TimelineStep {
  final IconData icon;
  final String label;
  final bool done;
  final bool active;
  const _TimelineStep(
      {required this.icon,
      required this.label,
      required this.done,
      required this.active});
}

class _StatusInfo {
  final String label;
  final Color dotColor;
  const _StatusInfo(this.label, this.dotColor);
}
