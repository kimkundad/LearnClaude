import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
                        _buildContactBox(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildAcceptButton(context, 'ยอมรับข้อกำหนด'),
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
            'ข้อกำหนดการใช้บริการ',
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
          colors: [AppTheme.primary, Color(0xFF0A8A7E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🌸', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 10),
          Text(
            'ยินดีต้อนรับสู่ LearnsBuy',
            style: GoogleFonts.sarabun(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'เราปลูกฝนคณะและสร้างแรงบันดาลใจทางการเรียนรู้ให้เด็กไทยก้าวทันโลก โปรดอ่านข้อกำหนดด้านล่างก่อนใช้บริการ',
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

  Widget _buildContactBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ติดต่อเรา:',
            style: GoogleFonts.sarabun(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'learnsbuy@gmail.com · 02-658-3819\nLINE: @learnsbuy, @za-shi',
            style: GoogleFonts.sarabun(
              fontSize: 13,
              color: AppTheme.primary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptButton(BuildContext context, String label) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: ElevatedButton(
        onPressed: () => context.pop(),
        child: Text(label),
      ),
    );
  }

  static const List<_SectionData> _sections = [
    _SectionData(
      number: 1,
      title: 'การสมัครสมาชิก',
      body: 'การสมัครเป็นสมาชิกไม่มีค่าธรรมเนียม หลังสมัครเสร็จ บริษัทจะส่งอีเมลแจ้งประจำตัวและรหัสผ่านเพื่อเข้าใช้บริการต่างๆ ได้ทันที',
    ),
    _SectionData(
      number: 2,
      title: 'ระยะเวลาการเป็นสมาชิก',
      body: 'สถานะสมาชิกมีผลตลอดไปจนกว่าจะแจ้งยกเลิกเป็นลายลักษณ์อักษรทางอีเมล learnsbuy@gmail.com หรือบริษัทยกเลิกเนื่องจากทำผิดข้อกำหนด',
    ),
    _SectionData(
      number: 3,
      title: 'คำรับรองของสมาชิก',
      bullets: [
        'ข้อมูลสมาชิกที่ให้ไว้เป็นความจริงและสามารถระบุตัวตนได้',
        'รักษารหัสประจำตัวและรหัสผ่านไว้เป็นความลับ ไม่เปิดเผยให้ผู้อื่น',
        'เนื้อหาที่โพสต์ต้องไม่หายวนาย ไม่ผิดกฎหมาย ไม่ผิดศีลธรรม',
      ],
    ),
    _SectionData(
      number: 4,
      title: 'ข้อมูลส่วนตัว',
      body: 'บริษัทจะเก็บรักษาข้อมูลส่วนตัวของสมาชิกตามนโยบายความเป็นส่วนตัว และจะไม่เปิดเผยต่อบุคคลที่สามโดยไม่ได้รับความยินยอม',
    ),
    _SectionData(
      number: 5,
      title: 'ทรัพย์สินทางปัญญา',
      body: 'เนื้อหาทั้งหมดในเว็บไซต์รวมถึงวิดีโอ เอกสาร และรูปภาพเป็นลิขสิทธิ์ของบริษัท ห้ามคัดลอกหรือเผยแพร่โดยไม่ได้รับอนุญาต',
    ),
    _SectionData(
      number: 6,
      title: 'ข้อจำกัดความรับผิดชอบ',
      body: 'บริษัทจะพยายามให้บริการอย่างต่อเนื่อง แต่ไม่รับผิดชอบต่อความเสียหายที่เกิดจากเหตุสุดวิสัยหรือปัญหาทางเทคนิคที่อยู่นอกเหนือการควบคุม',
    ),
    _SectionData(
      number: 7,
      title: 'การโอนสิทธิ',
      body: 'สมาชิกไม่สามารถโอนสิทธิให้บุคคลอื่นได้ เว้นแต่ได้รับความยินยอมเป็นลายลักษณ์อักษรจากบริษัท',
    ),
    _SectionData(
      number: 8,
      title: 'การสิ้นสุดการให้บริการ',
      bullets: [
        'สมาชิกแจ้งยกเลิกเป็นลายลักษณ์อักษร',
        'ทำผิดกฎ / กฎหมาย / เงื่อนไข',
        'ไม่แก้ไขภายในเวลาที่บริษัทกำหนด',
      ],
    ),
    _SectionData(
      number: 9,
      title: 'นโยบายการคืนเงิน',
      bullets: [
        'รับชมวิดีโอไม่เกิน 15% ของคอร์ส',
        'แจ้งคืนเงินภายใน 7 วันหลังชำระเงิน',
        'ปัญหาเกิดจากระบบ ไม่ใช่ผู้เรียน',
        'คืนเงินภายใน 7-15 วันทำการ เข้าบัตรเครดิตหรือบัญชีที่ใช้สั่งซื้อ',
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
