import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl = TextEditingController(text: 'kim kundad.');
  final _emailCtrl = TextEditingController(text: 'kim@example.com');
  final _phoneCtrl = TextEditingController(text: '089-123-4567');
  final _addressCtrl = TextEditingController(
    text: '88/12 ซอยสุขุมวิท 24 แขวงคลองตัน เขตคลองเตย กรุงเทพฯ 10110',
  );

  DateTime? _birthday = DateTime(2004, 1, 12);

  static const _thMonths = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน',
    'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม',
    'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
  ];

  String get _birthdayLabel {
    if (_birthday == null) return 'เลือกวันเกิด';
    final d = _birthday!;
    return '${d.day} ${_thMonths[d.month - 1]} ${d.year + 543}';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    // close keyboard first
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));

    final now = DateTime.now();
    final initial = _birthday ?? DateTime(2000, 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
      locale: const Locale('th'),
      builder: (ctx, child) => Theme(
        data: ThemeData(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primary,
            onPrimary: Colors.white,
            onSurface: AppTheme.textDark,
            surface: Colors.white,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
          ),
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _birthday = picked);
    }
  }

  void _save() {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('บันทึกข้อมูลเรียบร้อยแล้ว', style: GoogleFonts.sarabun()),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) context.canPop() ? context.pop() : context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 30),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(
          'แก้ไขโปรไฟล์',
          style: GoogleFonts.sarabun(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: true,
      ),
      // ── body is a Column so the save button rides up with the keyboard ──
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              children: [
                _buildAvatar(),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'ข้อมูลส่วนตัว',
                  icon: Icons.person_outline_rounded,
                  children: [
                    _textField('ชื่อ-นามสกุล', _nameCtrl, Icons.badge_outlined,
                        keyboardType: TextInputType.name, textCapitalization: TextCapitalization.words),
                    _textField('อีเมล', _emailCtrl, Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress),
                    _textField('เบอร์โทรศัพท์', _phoneCtrl, Icons.phone_outlined,
                        keyboardType: TextInputType.phone),
                    _dateField(),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: 'ที่อยู่สำหรับจัดส่ง',
                  icon: Icons.local_shipping_outlined,
                  children: [
                    _textField('ที่อยู่จัดส่ง', _addressCtrl, Icons.home_outlined,
                        maxLines: 4, keyboardType: TextInputType.multiline),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── Save button — moves up when keyboard opens ──────────────────
          _buildSaveBar(),
        ],
      ),
    );
  }

  // ─── Avatar ────────────────────────────────────────────────────────────────

  Widget _buildAvatar() {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.primary, Color(0xFF0A8A7E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text('K',
                style: GoogleFonts.sarabun(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 2,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section Card ──────────────────────────────────────────────────────────

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, size: 16, color: AppTheme.primary),
                ),
                const SizedBox(width: 10),
                Text(title,
                  style: GoogleFonts.sarabun(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  // ─── Text Field ────────────────────────────────────────────────────────────

  Widget _textField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
            style: GoogleFonts.sarabun(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            style: GoogleFonts.sarabun(fontSize: 15, color: AppTheme.textDark, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppTheme.primary, size: 19),
              alignLabelWithHint: maxLines > 1,
              contentPadding: maxLines > 1
                  ? const EdgeInsets.fromLTRB(0, 14, 16, 14)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Date Field (tappable → date picker) ──────────────────────────────────

  Widget _dateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('วันเกิด',
            style: GoogleFonts.sarabun(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickBirthday,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.cake_outlined, color: AppTheme.primary, size: 19),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _birthdayLabel,
                      style: GoogleFonts.sarabun(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _birthday != null ? AppTheme.textDark : AppTheme.textLight,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_calendar_rounded, size: 13, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text('เลือก',
                          style: GoogleFonts.sarabun(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w700)),
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

  // ─── Save Bar ──────────────────────────────────────────────────────────────

  Widget _buildSaveBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -3)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16, 12, 16,
        MediaQuery.of(context).viewInsets.bottom > 0
            ? 12
            : MediaQuery.of(context).padding.bottom + 12,
      ),
      child: ElevatedButton(
        onPressed: _save,
        child: Text('บันทึกข้อมูล',
          style: GoogleFonts.sarabun(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
    );
  }
}
