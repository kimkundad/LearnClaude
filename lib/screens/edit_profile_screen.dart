import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl          = TextEditingController();
  final _emailCtrl         = TextEditingController();
  final _phoneCtrl         = TextEditingController();
  final _receiverNameCtrl  = TextEditingController();
  final _receiverPhoneCtrl = TextEditingController();
  final _addressCtrl       = TextEditingController();
  final _lineIdCtrl        = TextEditingController();

  DateTime? _birthday;
  bool _loading = true;
  bool _saving  = false;

  File?   _pickedAvatar;
  String? _avatarUrl;
  String  _avatarInitial = '?';

  static const _avatarBase = 'https://learnsbuy.com/assets/images/avatar/';

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

  String get _birthdayApi {
    if (_birthday == null) return '';
    return '${_birthday!.year}-${_birthday!.month.toString().padLeft(2, '0')}-${_birthday!.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final cached = await AuthService.instance.getUser();
    if (cached != null) _fillForm(cached);
    try {
      final fresh = await ApiService.instance.getMe();
      _fillForm(fresh);
      await AuthService.instance.saveSession(
        (await AuthService.instance.getToken())!,
        fresh,
      );
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _fillForm(Map<String, dynamic> u) {
    _nameCtrl.text          = (u['name']           as String?) ?? '';
    _emailCtrl.text         = (u['email']          as String?) ?? '';
    _phoneCtrl.text         = (u['phone']          as String?) ?? '';
    _receiverNameCtrl.text  = (u['receiver_name']  as String?) ?? '';
    _receiverPhoneCtrl.text = (u['receiver_phone'] as String?) ?? '';
    _addressCtrl.text       = (u['address']        as String?) ?? '';
    _lineIdCtrl.text        = (u['line_id']        as String?) ?? '';

    _avatarInitial = _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : '?';
    final f = u['avatar'] as String?;
    _avatarUrl = (f != null && f.isNotEmpty) ? '$_avatarBase$f' : null;

    final hbd = u['hbd'] as String?;
    if (hbd != null && hbd.isNotEmpty) {
      try { _birthday = DateTime.parse(hbd); } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _receiverNameCtrl.dispose();
    _receiverPhoneCtrl.dispose();
    _addressCtrl.dispose();
    _lineIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded, color: AppTheme.primary),
              title: Text('ถ่ายรูป', style: GoogleFonts.notoSansThai(fontSize: 15, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primary),
              title: Text('เลือกจากคลัง', style: GoogleFonts.notoSansThai(fontSize: 15, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null && mounted) setState(() => _pickedAvatar = File(picked.path));
  }

  Future<void> _pickBirthday() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));
    final now     = DateTime.now();
    final initial = _birthday ?? DateTime(2000, 1, 1);
    final picked  = await showDatePicker(
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
    if (picked != null) setState(() => _birthday = picked);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final updated = await ApiService.instance.updateProfile(
        name:          _nameCtrl.text.trim(),
        email:         '',
        phone:         '',
        hbd:           _birthdayApi.isNotEmpty ? _birthdayApi : null,
        receiverName:  _receiverNameCtrl.text.trim().isNotEmpty ? _receiverNameCtrl.text.trim() : null,
        receiverPhone: _receiverPhoneCtrl.text.trim().isNotEmpty ? _receiverPhoneCtrl.text.trim() : null,
        address:       _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : null,
        lineId:        _lineIdCtrl.text.trim().isNotEmpty ? _lineIdCtrl.text.trim() : null,
        avatar:        _pickedAvatar,
      );
      final token = await AuthService.instance.getToken();
      if (token != null) {
        await AuthService.instance.saveSession(token, updated);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('บันทึกข้อมูลเรียบร้อยแล้ว', style: GoogleFonts.notoSansThai()),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ));
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) context.canPop() ? context.pop() : context.go('/home');
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$e', style: GoogleFonts.notoSansThai()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
          style: GoogleFonts.notoSansThai(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                              keyboardType: TextInputType.name,
                              textCapitalization: TextCapitalization.words),
                          _textField('อีเมล', _emailCtrl, Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              readOnly: true),
                          _textField('เบอร์โทรศัพท์', _phoneCtrl, Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              readOnly: true),
                          _dateField(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        title: 'ที่อยู่สำหรับจัดส่ง',
                        icon: Icons.local_shipping_outlined,
                        children: [
                          _textField('ชื่อ-นามสกุล ผู้รับ', _receiverNameCtrl, Icons.person_pin_outlined,
                              keyboardType: TextInputType.name,
                              textCapitalization: TextCapitalization.words),
                          _textField('เบอร์ติดต่อผู้รับ', _receiverPhoneCtrl, Icons.phone_outlined,
                              keyboardType: TextInputType.phone),
                          _textField(
                            'ที่อยู่สำหรับจัดส่ง',
                            _addressCtrl,
                            Icons.home_outlined,
                            maxLines: 4,
                            keyboardType: TextInputType.multiline,
                          ),
                          _textField(
                            'ID LINE (ไม่บังคับ)',
                            _lineIdCtrl,
                            Icons.chat_bubble_outline_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                _buildSaveBar(),
              ],
            ),
    );
  }

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
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: _pickedAvatar != null
                  ? Image.file(_pickedAvatar!, fit: BoxFit.cover)
                  : (_avatarUrl != null
                      ? Image.network(
                          _avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _initialAvatar(),
                        )
                      : _initialAvatar()),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 2,
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6),
                  ],
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialAvatar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, Color(0xFF28A874)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          _avatarInitial,
          style: GoogleFonts.notoSansThai(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: AppTheme.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
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

  Widget _textField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.notoSansThai(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textLight,
                ),
              ),
              if (readOnly) ...[
                const SizedBox(width: 4),
                const Icon(Icons.lock_outline_rounded, size: 11, color: AppTheme.textLight),
              ],
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            readOnly: readOnly,
            style: GoogleFonts.notoSansThai(
              fontSize: 15,
              color: readOnly ? AppTheme.textLight : AppTheme.textDark,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon,
                  color: readOnly ? AppTheme.textLight : AppTheme.primary, size: 19),
              filled: readOnly,
              fillColor: readOnly ? Colors.grey.shade50 : null,
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

  Widget _dateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'วันเกิด',
            style: GoogleFonts.notoSansThai(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textLight,
            ),
          ),
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
                      style: GoogleFonts.notoSansThai(
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
                        Text(
                          'เลือก',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 11,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
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

  Widget _buildSaveBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom > 0
            ? 12
            : MediaQuery.of(context).padding.bottom + 12,
      ),
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                'บันทึกข้อมูล',
                style: GoogleFonts.notoSansThai(fontSize: 16, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }
}
