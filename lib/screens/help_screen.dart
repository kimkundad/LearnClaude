import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import 'chat_screen.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header(context)),
          SliverToBoxAdapter(child: _searchBox()),
          SliverToBoxAdapter(child: _quickActions(context)),
          SliverToBoxAdapter(child: _faqList()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF28A874)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.26),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ต้องการความช่วยเหลือ?',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 23,
                    height: 1.16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'คุยกับทีมครูพี่โฮม หรืออ่านคำตอบยอดนิยมได้ที่นี่',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.86),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => _openChat(context),
                  icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                  label: Text(
                    'แชทกับครูพี่โฮม',
                    style: GoogleFonts.notoSansThai(fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primary,
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.support_agent_rounded, size: 44, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppTheme.textLight),
          const SizedBox(width: 10),
          Text(
            'ค้นหาปัญหา เช่น ดูคอร์สไม่ได้, ขอใบเสร็จ',
            style: GoogleFonts.notoSansThai(
              fontSize: 13,
              color: AppTheme.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    final items = [
      _HelpAction(Icons.play_circle_outline_rounded, 'ดูคอร์สไม่ได้', 'ตรวจสิทธิ์และอุปกรณ์', 'ดูคอร์สไม่ได้'),
      _HelpAction(Icons.receipt_long_rounded, 'ใบเสร็จ/ชำระเงิน', 'ส่งหลักฐานหรือขอเอกสาร', 'ใบเสร็จ/ชำระเงิน'),
      _HelpAction(Icons.local_shipping_rounded, 'จัดส่งหนังสือ', 'ตรวจที่อยู่และสถานะ', 'จัดส่งหนังสือ'),
      _HelpAction(Icons.lock_reset_rounded, 'รหัสผ่าน/บัญชี', 'กู้คืนและตั้งค่าใหม่', 'รหัสผ่าน/บัญชี'),
      _HelpAction(Icons.quiz_rounded, 'แบบทดสอบ', 'วิธีทำและดูผลคะแนน', 'แบบทดสอบ'),
      _HelpAction(Icons.local_offer_rounded, 'คูปองส่วนลด', 'วิธีกรอกและเงื่อนไข', 'คูปองส่วนลด'),
      _HelpAction(Icons.stars_rounded, 'คะแนน (Point)', 'การรับและใช้คะแนน', 'คะแนน (Point)'),
      _HelpAction(Icons.card_giftcard_rounded, 'แพ็กเกจสุดคุ้ม', 'คอร์สรวมและราคาพิเศษ', 'แพ็กเกจสุดคุ้ม'),
    ];

    final isTablet = MediaQuery.of(context).size.width > 600;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isTablet ? 4 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isTablet ? 1.2 : 1.35,
        ),
        itemBuilder: (_, i) {
          final item = items[i];
          return GestureDetector(
            onTap: () => _openChat(context, item.message),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: AppTheme.primary, size: 20),
                  ),
                  const Spacer(),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 11,
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _faqList() {
    final faqs = [
      ['ซื้อแล้วคอร์สอยู่ตรงไหน?', 'ไปที่แท็บ My Course กดปุ่ม "เข้าเรียน" เพื่อเริ่มดูวิดีโอได้ทันที'],
      ['ดูได้กี่อุปกรณ์?', 'สามารถใช้งานได้บนมือถือ แท็บเล็ต และเว็บ ภายใต้บัญชีเดิม'],
      ['ขอเปลี่ยนที่อยู่จัดส่งหนังสือได้ไหม?', 'แก้ไขได้ที่ Edit Profile ก่อนเข้าสู่รอบจัดส่ง'],
      ['มีแบบฝึกหัดและ PDF ไหม?', 'คอร์สที่รองรับจะแสดงไฟล์ประกอบในหน้าบทเรียน'],
      ['ใช้คูปองส่วนลดได้ยังไง?', 'กรอกรหัสคูปองในหน้าชำระเงิน (เฉพาะคอร์สเดี่ยว) แล้วกด "ตรวจสอบ" ก่อนส่งสลิป'],
      ['คะแนน (Point) ได้มาจากไหน?', 'คะแนนจะถูกเพิ่มเข้าบัญชีโดยอัตโนมัติเมื่อแอดมินอนุมัติคำสั่งซื้อ ดูยอดคงเหลือได้ที่หน้า Settings'],
      ['แบบทดสอบใช้งานอย่างไร?', 'เปิดหน้า My Course เลือกคอร์ส แล้วไปที่แท็บ "แบบทดสอบ" เพื่อทำข้อสอบ ดูผลคะแนนได้ทันทีหลังส่ง'],
      ['แพ็กเกจสุดคุ้มต่างจากคอร์สเดี่ยวอย่างไร?', 'แพ็กเกจรวมหลายคอร์สในราคาเดียว เมื่ออนุมัติแล้วจะได้รับสิทธิ์ทุกคอร์สในแพ็กเกจพร้อมกัน'],
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'คำถามยอดนิยม',
            style: GoogleFonts.notoSansThai(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 10),
          ...faqs.map(
            (faq) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border.withOpacity(0.7)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.help_outline_rounded, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          faq[0],
                          style: GoogleFonts.notoSansThai(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          faq[1],
                          style: GoogleFonts.notoSansThai(
                            fontSize: 12,
                            color: AppTheme.textMedium,
                            height: 1.45,
                          ),
                        ),
                      ],
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

  void _openChat(BuildContext context, [String? message]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatScreen(initialMessage: message)),
    );
  }
}

class _HelpAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final String message;

  const _HelpAction(this.icon, this.title, this.subtitle, this.message);
}
