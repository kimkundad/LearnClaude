import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../data/address_data.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _receiverNameCtrl  = TextEditingController();
  final _receiverPhoneCtrl = TextEditingController();
  final _addressDetailCtrl = TextEditingController();
  final _studentPhoneCtrl  = TextEditingController();

  String? _province;
  String? _district;
  String? _subdistrict;
  String? _zipCode;
  DateTime? _birthday;
  bool _saving = false;

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

  bool get _canSave =>
      _receiverNameCtrl.text.trim().isNotEmpty &&
      _receiverPhoneCtrl.text.trim().isNotEmpty &&
      _province != null &&
      _district != null &&
      _subdistrict != null &&
      _addressDetailCtrl.text.trim().isNotEmpty &&
      _birthday != null &&
      _studentPhoneCtrl.text.trim().length >= 9;

  @override
  void dispose() {
    _receiverNameCtrl.dispose();
    _receiverPhoneCtrl.dispose();
    _addressDetailCtrl.dispose();
    _studentPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
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

  Future<void> _openPicker(
    List<String> items,
    String title,
    void Function(String) onSelect,
  ) async {
    final search = ValueNotifier('');
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  title,
                  style: GoogleFonts.sarabun(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'ค้นหา...',
                    hintStyle: GoogleFonts.sarabun(color: AppTheme.textLight),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textLight),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) => search.value = v,
                ),
              ),
              Divider(height: 1, color: AppTheme.border),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: search,
                  builder: (_, q, __) {
                    final filtered = q.isEmpty
                        ? items
                        : items.where((e) => e.contains(q)).toList();
                    return ListView.builder(
                      controller: scrollCtrl,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => ListTile(
                        title: Text(
                          filtered[i],
                          style: GoogleFonts.sarabun(fontSize: 15, color: AppTheme.textDark),
                        ),
                        onTap: () {
                          onSelect(filtered[i]);
                          Navigator.pop(ctx);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final updated = await ApiService.instance.updateProfile(
        name:          '',
        email:         '',
        phone:         '',
        hbd:           _birthdayApi.isNotEmpty ? _birthdayApi : null,
        receiverName:  _receiverNameCtrl.text.trim(),
        receiverPhone: _receiverPhoneCtrl.text.trim(),
        province:      _province,
        district:      _district,
        subdistrict:   _subdistrict,
        zipCode:       _zipCode,
        addressDetail: _addressDetailCtrl.text.trim(),
      );
      final token = await AuthService.instance.getToken();
      if (token != null) await AuthService.instance.saveSession(token, updated);
      if (!mounted) return;
      context.go('/phone-otp', extra: _studentPhoneCtrl.text.trim());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$e', style: GoogleFonts.sarabun()),
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
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                _buildInfoBanner(),
                const SizedBox(height: 20),
                _buildSection(
                  step: '1',
                  title: 'ที่อยู่สำหรับจัดส่งหนังสือ',
                  subtitle: 'เราจะส่งหนังสือและของขวัญพิเศษถึงบ้านคุณ',
                  icon: Icons.local_shipping_rounded,
                  color: const Color(0xFF2C7BE5),
                  children: [
                    _textField('ชื่อ-นามสกุล ผู้รับ *', _receiverNameCtrl, Icons.person_outline_rounded,
                        hint: 'ชื่อผู้รับหนังสือและของขวัญ',
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.words),
                    _textField('เบอร์ติดต่อผู้รับ *', _receiverPhoneCtrl, Icons.phone_outlined,
                        hint: 'เบอร์โทรสำหรับติดต่อผู้รับ',
                        keyboardType: TextInputType.phone),
                    _pickerField(
                      label: 'จังหวัด *',
                      value: _province,
                      icon: Icons.location_city_outlined,
                      hint: 'เลือกจังหวัด',
                      onTap: () => _openPicker(
                        AddressService.getProvinces(),
                        'เลือกจังหวัด',
                        (v) => setState(() {
                          _province = v;
                          _district = null;
                          _subdistrict = null;
                          _zipCode = null;
                        }),
                      ),
                    ),
                    _pickerField(
                      label: 'เขต/อำเภอ *',
                      value: _district,
                      icon: Icons.map_outlined,
                      enabled: _province != null,
                      hint: _province == null ? 'เลือกจังหวัดก่อน' : 'เลือกเขต/อำเภอ',
                      onTap: () => _openPicker(
                        AddressService.getDistricts(_province!),
                        'เลือกเขต/อำเภอ',
                        (v) => setState(() {
                          _district = v;
                          _subdistrict = null;
                          _zipCode = null;
                        }),
                      ),
                    ),
                    _pickerField(
                      label: 'แขวง/ตำบล *',
                      value: _subdistrict,
                      icon: Icons.place_outlined,
                      enabled: _district != null,
                      hint: _district == null ? 'เลือกเขต/อำเภอก่อน' : 'เลือกแขวง/ตำบล',
                      onTap: () => _openPicker(
                        AddressService.getSubdistricts(_province!, _district!)
                            .map((e) => e['name']!)
                            .toList(),
                        'เลือกแขวง/ตำบล',
                        (v) => setState(() {
                          _subdistrict = v;
                          _zipCode = AddressService.getZip(_province!, _district!, v);
                        }),
                      ),
                    ),
                    _zipDisplay(),
                    _textField('บ้านเลขที่ / ซอย / ถนน *', _addressDetailCtrl, Icons.home_outlined,
                        hint: 'เช่น 123/45 ซอยลาดพร้าว 48',
                        maxLines: 2,
                        keyboardType: TextInputType.multiline),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  step: '2',
                  title: 'วันเกิด',
                  subtitle: 'เราจะส่งของขวัญวันเกิดพิเศษให้คุณ 🎂',
                  icon: Icons.cake_rounded,
                  color: const Color(0xFFE83E8C),
                  children: [_birthdayField()],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  step: '3',
                  title: 'เบอร์ติดต่อนักเรียน',
                  subtitle: 'เบอร์จริงของนักเรียนหรือผู้ปกครอง\nต้องยืนยัน OTP ในขั้นตอนถัดไป',
                  icon: Icons.phone_iphone_rounded,
                  color: const Color(0xFF32D191),
                  children: [
                    _textField('เบอร์โทรศัพท์ *', _studentPhoneCtrl, Icons.phone_outlined,
                        hint: 'เบอร์มือถือสำหรับติดต่อนักเรียน',
                        keyboardType: TextInputType.phone),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFF16A34A), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'จะมีขั้นตอนยืนยัน OTP ผ่าน SMS หลังบันทึก',
                              style: GoogleFonts.sarabun(
                                fontSize: 12,
                                color: const Color(0xFF15803D),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, Color(0xFF28A874)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'ホ',
                        style: GoogleFonts.sarabun(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ครูพี่โฮม',
                    style: GoogleFonts.sarabun(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'ยินดีต้อนรับ! 🎉',
                style: GoogleFonts.sarabun(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'กรอกข้อมูลเพิ่มเติมเพื่อรับสิทธิพิเศษ\nและจัดส่งหนังสือถึงบ้านคุณ',
                style: GoogleFonts.sarabun(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.85),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              _buildStepIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _stepDot('1', Icons.local_shipping_rounded, true),
        _stepLine(),
        _stepDot('2', Icons.cake_rounded, true),
        _stepLine(),
        _stepDot('3', Icons.phone_iphone_rounded, true),
        _stepLine(),
        _stepDot('✓', Icons.check_rounded, false),
      ],
    );
  }

  Widget _stepDot(String label, IconData icon, bool active) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: label == '✓'
            ? Icon(icon, size: 16, color: AppTheme.primary.withOpacity(0.5))
            : Text(
                label,
                style: GoogleFonts.sarabun(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: active ? AppTheme.primary : Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _stepLine() {
    return Expanded(
      child: Container(
        height: 2,
        color: Colors.white.withOpacity(0.3),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'ข้อมูลนี้ใช้สำหรับจัดส่งหนังสือ ของขวัญวันเกิด และติดต่อนักเรียน กรุณากรอกให้ครบถ้วน',
              style: GoogleFonts.sarabun(
                fontSize: 13,
                color: const Color(0xFF92400E),
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String step,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
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
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ขั้นตอน $step',
                              style: GoogleFonts.sarabun(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            title,
                            style: GoogleFonts.sarabun(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: GoogleFonts.sarabun(
                          fontSize: 12,
                          color: AppTheme.textLight,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
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
    String hint = '',
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.sarabun(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.sarabun(
              fontSize: 15,
              color: AppTheme.textDark,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.sarabun(color: AppTheme.textLight, fontSize: 14),
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

  Widget _pickerField({
    required String label,
    required String? value,
    required IconData icon,
    bool enabled = true,
    String hint = 'กรุณาเลือก',
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.sarabun(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: enabled ? onTap : null,
            child: Container(
              decoration: BoxDecoration(
                color: enabled ? Colors.white : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: value != null ? AppTheme.primary.withOpacity(0.4) : AppTheme.border,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: enabled ? AppTheme.primary : AppTheme.textLight,
                    size: 19,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      value ?? hint,
                      style: GoogleFonts.sarabun(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: value != null ? AppTheme.textDark : AppTheme.textLight,
                      ),
                    ),
                  ),
                  Icon(
                    value != null
                        ? Icons.check_circle_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: value != null ? AppTheme.primary : AppTheme.textLight,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _zipDisplay() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'รหัสไปรษณีย์',
            style: GoogleFonts.sarabun(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.local_post_office_outlined, color: AppTheme.textLight, size: 19),
                const SizedBox(width: 12),
                Text(
                  _zipCode ?? 'กรอกอัตโนมัติเมื่อเลือกแขวง/ตำบล',
                  style: GoogleFonts.sarabun(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _zipCode != null ? AppTheme.textDark : AppTheme.textLight,
                  ),
                ),
                if (_zipCode != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 18),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _birthdayField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: _pickBirthday,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _birthday != null
                  ? AppTheme.primary.withOpacity(0.4)
                  : AppTheme.border,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.cake_outlined, color: AppTheme.primary, size: 22),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _birthday != null ? AppTheme.primary : AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _birthday != null ? Icons.check_rounded : Icons.edit_calendar_rounded,
                      size: 14,
                      color: _birthday != null ? Colors.white : AppTheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _birthday != null ? 'เลือกแล้ว' : 'เลือก',
                      style: GoogleFonts.sarabun(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _birthday != null ? Colors.white : AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_canSave)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'กรุณากรอกข้อมูลให้ครบทุกช่องที่มี * ก่อนกดบันทึก',
                style: GoogleFonts.sarabun(
                  fontSize: 12,
                  color: AppTheme.textLight,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ElevatedButton.icon(
            onPressed: (_canSave && !_saving) ? _save : null,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.arrow_forward_rounded, size: 20),
            label: Text(
              _saving ? 'กำลังบันทึก...' : 'บันทึกและยืนยันเบอร์โทร',
              style: GoogleFonts.sarabun(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
