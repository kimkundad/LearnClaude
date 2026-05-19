import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 12),
                        ..._sections.map((s) => _buildSection(s)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildAcceptButton(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: const Icon(Icons.chevron_left, color: AppTheme.textDark, size: 28),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'นโยบายความเป็นส่วนตัว',
            style: GoogleFonts.sarabun(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          Text(
            'learnsbuy.com · อัปเดตล่าสุด เม.ย. 2026',
            style: GoogleFonts.sarabun(fontSize: 11, color: AppTheme.textLight),
          ),
        ],
      ),
      titleSpacing: 0,
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF28A874)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_outline, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            'ความเป็นส่วนตัวของคุณสำคัญกับเรา',
            style: GoogleFonts.sarabun(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'เรารักษาข้อมูลของผู้เรียนอย่างรัดกุม โปรดอ่านเพื่อทราบสิทธิและข้อกำหนดในการใช้เว็บไซต์',
            style: GoogleFonts.sarabun(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(_SectionData s) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${s.number}',
                    style: GoogleFonts.sarabun(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.title,
                  style: GoogleFonts.sarabun(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          if (s.body != null) ...[
            const SizedBox(height: 10),
            Text(
              s.body!,
              style: GoogleFonts.sarabun(
                fontSize: 13,
                color: AppTheme.textMedium,
                height: 1.6,
              ),
            ),
          ],
          if (s.bullets != null) ...[
            const SizedBox(height: 10),
            ...s.bullets!.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        b,
                        style: GoogleFonts.sarabun(
                          fontSize: 13,
                          color: AppTheme.textMedium,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAcceptButton(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: ElevatedButton(
        onPressed: () => context.pop(),
        child: const Text('ยอมรับนโยบาย'),
      ),
    );
  }

  static const List<_SectionData> _sections = [
    _SectionData(
      number: 1,
      title: 'การยอมรับข้อตกลง',
      body: 'การเข้าใช้เว็บไซต์ถือว่าผู้ใช้ตกลงและยืนยอมปฏิบัติตามข้อตกลงและข้อจำกัดความรับผิดทั้งหมดที่ระบุไว้',
    ),
    _SectionData(
      number: 2,
      title: 'การเปลี่ยนแปลงข้อกำหนด',
      body: 'บริษัทขอสงวนสิทธิ์ในการแก้ไขหรือเพิ่มเติมเงื่อนไขได้โดยไม่ต้องแจ้งล่วงหน้า การเข้าใช้งานหลังจากแก้ไขถือว่าตกลงตามข้อกำหนดใหม่แล้ว',
    ),
    _SectionData(
      number: 3,
      title: 'อุปกรณ์และการเชื่อมต่อ',
      body: 'ผู้ใช้รับผิดชอบอุปกรณ์ คอมพิวเตอร์ อินเทอร์เน็ต และค่าใช้จ่ายทั้งหมดที่จำเป็นสำหรับการเข้าใช้เว็บไซต์ด้วยตนเอง',
    ),
    _SectionData(
      number: 4,
      title: 'การใช้งานอย่างถูกต้อง',
      bullets: [
        'ห้ามโพสต์หรือส่งข้อมูลที่ผิดกฎหมาย ผิดศีลธรรม หรือละเมิดสิทธิ์ผู้อื่น',
        'ห้ามรบกวนการทำงานของระบบหรือพยายามเข้าถึงข้อมูลที่ไม่ได้รับอนุญาต',
        'ห้ามใช้บอทหรือซอฟต์แวร์อัตโนมัติในการเข้าถึงบริการ',
      ],
    ),
    _SectionData(
      number: 5,
      title: 'การเก็บรวบรวมข้อมูล',
      body: 'เราเก็บข้อมูลที่จำเป็นเท่านั้น ได้แก่ ชื่อ อีเมล และประวัติการเรียน เพื่อปรับปรุงประสบการณ์การใช้งานของคุณ',
    ),
    _SectionData(
      number: 6,
      title: 'การใช้ข้อมูล',
      bullets: [
        'ส่งการแจ้งเตือนและอัปเดตคอร์สที่สมัครไว้',
        'ปรับปรุงและพัฒนาบริการของเรา',
        'ส่งข้อมูลโปรโมชั่นที่คุณสนใจ (สามารถยกเลิกได้)',
      ],
    ),
    _SectionData(
      number: 7,
      title: 'การแบ่งปันข้อมูล',
      body: 'เราจะไม่ขายหรือแบ่งปันข้อมูลส่วนตัวของคุณให้กับบุคคลที่สาม เว้นแต่ได้รับความยินยอมจากคุณหรือตามที่กฎหมายกำหนด',
    ),
    _SectionData(
      number: 8,
      title: 'ความปลอดภัยของข้อมูล',
      body: 'เราใช้มาตรการรักษาความปลอดภัยระดับมาตรฐานอุตสาหกรรม รวมถึงการเข้ารหัส SSL เพื่อปกป้องข้อมูลของคุณ',
    ),
    _SectionData(
      number: 9,
      title: 'สิทธิของผู้ใช้',
      bullets: [
        'สิทธิ์เข้าถึงข้อมูลส่วนตัวของคุณ',
        'สิทธิ์แก้ไขข้อมูลที่ไม่ถูกต้อง',
        'สิทธิ์ขอลบข้อมูลของคุณออกจากระบบ',
        'สิทธิ์คัดค้านการประมวลผลข้อมูล',
      ],
    ),
  ];
}

class _SectionData {
  final int number;
  final String title;
  final String? body;
  final List<String>? bullets;

  const _SectionData({
    required this.number,
    required this.title,
    this.body,
    this.bullets,
  });
}
