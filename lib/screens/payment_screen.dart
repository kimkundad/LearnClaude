import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../services/api_service.dart';

class PaymentScreen extends StatefulWidget {
  final String courseTitle;
  final int price;
  final int itemId;       // course_id or package_id
  final String itemType;  // 'course' | 'package'

  const PaymentScreen({
    super.key,
    this.courseTitle = 'ติวโค้งสุดท้าย A-Level ญี่ปุ่น',
    this.price = 3950,
    this.itemId = 0,
    this.itemType = 'package',
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedAccount = 0;
  DateTime _transferDate = DateTime.now();
  TimeOfDay _transferTime = TimeOfDay.now();
  File? _slipImage;
  bool _isSubmitting = false;
  bool _loadingBanks = true;
  List<_AccountInfo> _accounts = [];

  // Coupon (course only)
  final _couponCtrl = TextEditingController();
  int? _couponId;
  int _discountAmount = 0;
  bool _couponChecking = false;
  String? _couponMsg;
  bool _couponValid = false;

  int get _finalPrice => widget.price - _discountAmount;

  static _AccountInfo _bankToAccount(Map<String, dynamic> b) {
    final name = (b['bank_name'] as String?) ?? '';
    Color c1, c2;
    if (name.contains('ไทยพาณิชย์') || name.contains('SCB')) {
      c1 = const Color(0xFF7B1FA2); c2 = const Color(0xFF4A148C);
    } else if (name.contains('กสิกร') || name.contains('KBank')) {
      c1 = const Color(0xFF2E7D32); c2 = const Color(0xFF1B5E20);
    } else if (name.contains('กรุงไทย') || name.contains('KTB')) {
      c1 = const Color(0xFF1565C0); c2 = const Color(0xFF0D47A1);
    } else if (name.contains('กรุงเทพ') || name.contains('BBL')) {
      c1 = const Color(0xFF1A237E); c2 = const Color(0xFF0D1472);
    } else {
      c1 = const Color(0xFF37474F); c2 = const Color(0xFF263238);
    }
    return _AccountInfo(
      id: (b['id'] as int?) ?? 0,
      bankName: name,
      accountNumber: (b['bank_number'] as String?) ?? '',
      accountName: (b['bank_owner'] as String?) ?? '',
      color: c2,
      gradientColors: [c1, c2],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkCoupon() async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() { _couponChecking = true; _couponMsg = null; _couponValid = false; });
    try {
      final result = await ApiService.instance.checkCoupon(code, widget.itemId);
      final discount = (result['coupon_price'] as num?)?.toInt() ?? 0;
      setState(() {
        _couponId = result['coupon_id'] as int?;
        _discountAmount = discount;
        _couponValid = true;
        _couponMsg = 'ส่วนลด ฿${discount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}';
      });
    } on ApiException catch (e) {
      setState(() {
        _couponMsg = e.message;
        _couponValid = false;
        _discountAmount = 0;
        _couponId = null;
      });
    } catch (_) {
      setState(() {
        _couponMsg = 'ไม่สามารถตรวจสอบคูปองได้';
        _couponValid = false;
      });
    } finally {
      setState(() => _couponChecking = false);
    }
  }

  Future<void> _loadBanks() async {
    try {
      final list = await ApiService.instance.getBanks();
      setState(() {
        _accounts = list.map((b) => _bankToAccount(b as Map<String, dynamic>)).toList();
        _loadingBanks = false;
      });
    } catch (_) {
      setState(() => _loadingBanks = false);
    }
  }

  static const _thMonths = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
  ];

  String get _formattedDate {
    final d = _transferDate;
    return '${d.day} ${_thMonths[d.month - 1]} ${d.year + 543}';
  }

  String get _formattedTime {
    final h = _transferTime.hour.toString().padLeft(2, '0');
    final m = _transferTime.minute.toString().padLeft(2, '0');
    return '$h:$m น.';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transferDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
      locale: const Locale('th'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _transferDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _transferTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _transferTime = picked);
  }

  Future<void> _pickSlip() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SourceSheet(),
    );
    if (source == null) return;
    final img = await picker.pickImage(source: source, imageQuality: 85);
    if (img != null) setState(() => _slipImage = File(img.path));
  }

  Future<void> _submit() async {
    if (_accounts.isEmpty) {
      _showDebug('accounts ว่าง — getBanks() ล้มเหลว');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final d = _transferDate;
      final t = _transferTime;
      final dateStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final timeStr = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      final bankId  = _accounts[_selectedAccount].id;

      debugPrint('[SUBMIT] type=${widget.itemType} id=${widget.itemId} bank=$bankId amount=$_finalPrice date=$dateStr time=$timeStr coupon=$_couponId');

      if (widget.itemType == 'package') {
        await ApiService.instance.submitPackagePayment(
          packId: widget.itemId,
          bankId: bankId,
          amount: widget.price,
          date: dateStr,
          time: timeStr,
          slipImage: _slipImage,
        );
      } else {
        await ApiService.instance.submitCoursePayment(
          courseId: widget.itemId,
          bankId: bankId,
          amount: _finalPrice,
          date: dateStr,
          time: timeStr,
          slipImage: _slipImage,
          couponId: _couponId,
        );
      }
      if (mounted) context.pushReplacement('/payment-success', extra: {
        'title': widget.courseTitle,
        'price': _finalPrice,
      });
    } on ApiException catch (e) {
      debugPrint('[SUBMIT] ApiException: ${e.message}');
      if (mounted) _showDebug('API: ${e.message}');
    } catch (e, st) {
      debugPrint('[SUBMIT] Error: $e\n$st');
      if (mounted) _showDebug(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showDebug(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SelectableText(msg,
            style: GoogleFonts.notoSansThai(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: AppTheme.priceRed,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('ชำระเงิน',
            style: GoogleFonts.notoSansThai(fontSize: 18, fontWeight: FontWeight.w800)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.border, height: 1),
        ),
      ),
      body: _loadingBanks
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _CourseCard(title: widget.courseTitle, price: widget.price, isPackage: widget.itemType == 'package'),
                        if (widget.itemType == 'course') ...[
                          const SizedBox(height: 16),
                          _buildCoupon(),
                        ],
                        const SizedBox(height: 16),
                        _buildAccountSelector(),
                        const SizedBox(height: 16),
                        if (_accounts.isNotEmpty) _buildSelectedAccountCard(),
                        const SizedBox(height: 16),
                        _buildDateTime(),
                        const SizedBox(height: 16),
                        _buildSlipUpload(),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                _buildSubmitBar(),
              ],
            ),
    );
  }

  Widget _buildAccountSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
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
                child: const Icon(Icons.account_balance_rounded,
                    color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('เลือกบัญชีรับโอน',
                      style: GoogleFonts.notoSansThai(
                          fontSize: 15, fontWeight: FontWeight.w800,
                          color: AppTheme.textDark)),
                  Text('โอนมาที่บัญชีที่เลือกด้านล่าง',
                      style: GoogleFonts.notoSansThai(
                          fontSize: 12, color: AppTheme.textLight,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(_accounts.length, (i) {
            final acc = _accounts[i];
            final selected = _selectedAccount == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedAccount = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(bottom: i < _accounts.length - 1 ? 10 : 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? acc.color.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? acc.color : AppTheme.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: acc.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          acc.bankName.isNotEmpty ? acc.bankName.substring(0, 1) : 'B',
                          style: GoogleFonts.notoSansThai(
                              fontSize: 16, color: Colors.white,
                              fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(acc.bankName,
                              style: GoogleFonts.notoSansThai(
                                  fontSize: 13,
                                  color: selected ? acc.color : AppTheme.textDark,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(acc.accountNumber,
                              style: GoogleFonts.notoSansThai(
                                  fontSize: 14,
                                  color: selected ? acc.color : AppTheme.textMedium,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: selected ? acc.color : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? acc.color : AppTheme.border,
                          width: 2,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded,
                              size: 13, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSelectedAccountCard() {
    final acc = _accounts[_selectedAccount];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_selectedAccount),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: acc.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: acc.color.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_rounded,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 7),
                Text(acc.bankName,
                    style: GoogleFonts.notoSansThai(
                        fontSize: 13, color: Colors.white70,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('บัญชีรับโอน',
                      style: GoogleFonts.notoSansThai(
                          fontSize: 11, color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('เลขบัญชี',
                          style: GoogleFonts.notoSansThai(
                              fontSize: 11, color: Colors.white60,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(acc.accountNumber,
                          style: GoogleFonts.notoSansThai(
                              fontSize: 24, color: Colors.white,
                              fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final raw = acc.accountNumber.replaceAll('-', '');
                    Clipboard.setData(ClipboardData(text: raw));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('คัดลอกเลขบัญชีแล้ว',
                            style: GoogleFonts.notoSansThai(fontWeight: FontWeight.w700)),
                        backgroundColor: AppTheme.primary,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.copy_rounded,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 5),
                        Text('คัดลอก',
                            style: GoogleFonts.notoSansThai(
                                fontSize: 13, color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('ชื่อบัญชี: ${acc.accountName}',
                style: GoogleFonts.notoSansThai(
                    fontSize: 13, color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTime() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
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
                child: const Icon(Icons.schedule_rounded,
                    color: Color(0xFF388E3C), size: 20),
              ),
              const SizedBox(width: 10),
              Text('วันที่และเวลาโอน',
                  style: GoogleFonts.notoSansThai(
                      fontSize: 15, fontWeight: FontWeight.w800,
                      color: AppTheme.textDark)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DateTimeButton(
                  icon: Icons.calendar_today_rounded,
                  label: 'วันที่โอน',
                  value: _formattedDate,
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateTimeButton(
                  icon: Icons.access_time_rounded,
                  label: 'เวลาโอน',
                  value: _formattedTime,
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlipUpload() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: Color(0xFF1565C0), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('แนบสลิปการโอน',
                            style: GoogleFonts.notoSansThai(
                                fontSize: 15, fontWeight: FontWeight.w800,
                                color: AppTheme.textDark)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.textLight.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('ไม่บังคับ',
                              style: GoogleFonts.notoSansThai(
                                  fontSize: 11, color: AppTheme.textLight,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    Text('รองรับไฟล์ JPG, PNG',
                        style: GoogleFonts.notoSansThai(
                            fontSize: 12, color: AppTheme.textLight,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (_slipImage != null)
                GestureDetector(
                  onTap: () => setState(() => _slipImage = null),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.priceRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: AppTheme.priceRed, size: 18),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _pickSlip,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: _slipImage != null ? 220 : 140,
              decoration: BoxDecoration(
                color: _slipImage != null ? Colors.black : AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _slipImage != null
                      ? AppTheme.primary
                      : AppTheme.primary.withOpacity(0.3),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _slipImage != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(_slipImage!, fit: BoxFit.contain),
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit_rounded,
                                    size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                                Text('เปลี่ยนรูป',
                                    style: GoogleFonts.notoSansThai(
                                        fontSize: 12, color: Colors.white,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_photo_alternate_rounded,
                              color: AppTheme.primary, size: 32),
                        ),
                        const SizedBox(height: 10),
                        Text('แตะเพื่อแนบสลิป (ถ้ามี)',
                            style: GoogleFonts.notoSansThai(
                                fontSize: 14, color: AppTheme.primary,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('ไม่แนบก็ส่งได้ — รองรับ JPG, PNG',
                            style: GoogleFonts.notoSansThai(
                                fontSize: 12, color: AppTheme.textLight,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoupon() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_offer_rounded,
                    color: Color(0xFFF9A825), size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('คูปองส่วนลด',
                      style: GoogleFonts.notoSansThai(
                          fontSize: 15, fontWeight: FontWeight.w800,
                          color: AppTheme.textDark)),
                  Text('ใส่รหัสคูปองเพื่อรับส่วนลด',
                      style: GoogleFonts.notoSansThai(
                          fontSize: 12, color: AppTheme.textLight,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponCtrl,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) {
                    if (_couponValid) {
                      setState(() {
                        _couponValid = false;
                        _couponId = null;
                        _discountAmount = 0;
                        _couponMsg = null;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'รหัสคูปอง',
                    hintStyle: GoogleFonts.notoSansThai(
                        fontSize: 14, color: AppTheme.textLight),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    filled: true,
                    fillColor: const Color(0xFFF6F8FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                    ),
                    suffixIcon: _couponValid
                        ? const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF388E3C), size: 20)
                        : null,
                  ),
                  style: GoogleFonts.notoSansThai(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _couponChecking ? null : _checkCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF9A825),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(80, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 0,
                  ),
                  child: _couponChecking
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('ตรวจสอบ',
                          style: GoogleFonts.notoSansThai(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
          if (_couponMsg != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _couponValid
                      ? Icons.check_circle_outline_rounded
                      : Icons.cancel_outlined,
                  size: 16,
                  color: _couponValid
                      ? const Color(0xFF388E3C)
                      : AppTheme.priceRed,
                ),
                const SizedBox(width: 6),
                Text(
                  _couponMsg!,
                  style: GoogleFonts.notoSansThai(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _couponValid
                          ? const Color(0xFF388E3C)
                          : AppTheme.priceRed),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 14, 16, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border:
            Border(top: BorderSide(color: AppTheme.border.withOpacity(0.6))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ยอดชำระ',
                  style: GoogleFonts.notoSansThai(
                      fontSize: 12, color: AppTheme.textLight,
                      fontWeight: FontWeight.w600)),
              if (_discountAmount > 0)
                Text(
                  '฿${widget.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                  style: GoogleFonts.notoSansThai(
                      fontSize: 13,
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.lineThrough),
                ),
              Text(
                '฿${_finalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                style: GoogleFonts.notoSansThai(
                    fontSize: 22,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text('ส่งหลักฐานการชำระ',
                            style: GoogleFonts.notoSansThai(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
}

// ─── Shared Widgets ──────────────────────────────────────────────────────────

class _CourseCard extends StatelessWidget {
  final String title;
  final int price;
  final bool isPackage;
  const _CourseCard({required this.title, required this.price, this.isPackage = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF32D191), Color(0xFF0A8C80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isPackage ? Icons.card_giftcard_rounded : Icons.school_rounded,
              color: Colors.white, size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isPackage ? 'แพ็กเกจสุดคุ้ม' : 'คอร์สเรียน',
                    style: GoogleFonts.notoSansThai(
                        fontSize: 11, color: Colors.white70,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSansThai(
                        fontSize: 14, color: Colors.white,
                        fontWeight: FontWeight.w800, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('ราคา',
                  style: GoogleFonts.notoSansThai(
                      fontSize: 11, color: Colors.white70,
                      fontWeight: FontWeight.w600)),
              Text(
                '฿${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                style: GoogleFonts.notoSansThai(
                    fontSize: 20, color: Colors.white,
                    fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateTimeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateTimeButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: AppTheme.primary),
                const SizedBox(width: 5),
                Text(label,
                    style: GoogleFonts.notoSansThai(
                        fontSize: 11, color: AppTheme.primary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.notoSansThai(
                    fontSize: 14, color: AppTheme.textDark,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _SourceSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('เลือกรูปสลิป',
              style: GoogleFonts.notoSansThai(
                  fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _sourceOption(
                    context,
                    icon: Icons.camera_alt_rounded,
                    label: 'ถ่ายภาพ',
                    color: const Color(0xFF0D47A1),
                    source: ImageSource.camera,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _sourceOption(
                    context,
                    icon: Icons.photo_library_rounded,
                    label: 'แกลเลอรี่',
                    color: AppTheme.primary,
                    source: ImageSource.gallery,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ยกเลิก',
                  style: GoogleFonts.notoSansThai(
                      fontSize: 15, color: AppTheme.textLight,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _sourceOption(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required ImageSource source}) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, source),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.notoSansThai(
                    fontSize: 14, color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ─── Data Classes ─────────────────────────────────────────────────────────────

class _AccountInfo {
  final int id;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final Color color;
  final List<Color> gradientColors;

  const _AccountInfo({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.color,
    required this.gradientColors,
  });
}
