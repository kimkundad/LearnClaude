import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class PhoneOtpScreen extends StatefulWidget {
  final String phone;
  const PhoneOtpScreen({super.key, required this.phone});

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  final List<TextEditingController> _ctrl =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focus = List.generate(6, (_) => FocusNode());

  bool _sending   = false;
  bool _verifying = false;
  bool _sent      = false;
  int  _countdown = 0;
  Timer? _timer;

  String get _otp => _ctrl.map((c) => c.text).join();
  bool get _otpComplete => _otp.length == 6 && _otp.split('').every((c) => c.isNotEmpty);

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrl) c.dispose();
    for (final f in _focus) f.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_countdown > 0) _countdown--; else _timer?.cancel();
      });
    });
  }

  Future<void> _sendOtp() async {
    setState(() => _sending = true);
    try {
      await ApiService.instance.sendPhoneOtp(widget.phone);
      if (mounted) {
        setState(() { _sent = true; });
        _startCountdown();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _focus[0].requestFocus();
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnack('$e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verify() async {
    if (!_otpComplete) return;
    FocusScope.of(context).unfocus();
    setState(() => _verifying = true);
    try {
      final updated = await ApiService.instance.verifyPhoneOtp(widget.phone, _otp);
      final token = await AuthService.instance.getToken();
      if (token != null) await AuthService.instance.saveSession(token, updated);
      if (!mounted) return;
      _showSnack('ยืนยันเบอร์โทรสำเร็จ! 🎉');
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        _showSnack('$e', isError: true);
        for (final c in _ctrl) c.clear();
        _focus[0].requestFocus();
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focus[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focus[index - 1].requestFocus();
    }
    if (_otpComplete) _verify();
    setState(() {});
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.sarabun()),
      backgroundColor: isError ? Colors.red : AppTheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildTop(),
              const SizedBox(height: 40),
              _buildOtpBox(),
              const SizedBox(height: 32),
              _buildVerifyButton(),
              const SizedBox(height: 20),
              _buildResend(),
              const SizedBox(height: 40),
              _buildSkipButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTop() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, Color(0xFF0A8A7E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.sms_outlined, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 24),
        Text(
          'ยืนยันเบอร์โทรศัพท์',
          style: GoogleFonts.sarabun(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'กรุณากรอกรหัส OTP 6 หลัก\nที่ส่งไปยังเบอร์',
          style: GoogleFonts.sarabun(
            fontSize: 14,
            color: AppTheme.textLight,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            widget.phone,
            style: GoogleFonts.sarabun(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.primary,
              letterSpacing: 1.5,
            ),
          ),
        ),
        if (_sending) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
              ),
              const SizedBox(width: 10),
              Text(
                'กำลังส่ง OTP...',
                style: GoogleFonts.sarabun(fontSize: 13, color: AppTheme.textLight),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildOtpBox() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => _otpCell(i)),
        ),
      ],
    );
  }

  Widget _otpCell(int i) {
    final filled = _ctrl[i].text.isNotEmpty;
    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: _ctrl[i],
        focusNode: _focus[i],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (v) => _onDigitChanged(i, v),
        style: GoogleFonts.sarabun(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: AppTheme.textDark,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: filled ? AppTheme.primary : AppTheme.border,
              width: filled ? 2 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
          ),
          filled: true,
          fillColor: filled ? AppTheme.primaryLight : Colors.white,
        ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    return ElevatedButton.icon(
      onPressed: (_otpComplete && !_verifying) ? _verify : null,
      icon: _verifying
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.verified_outlined, size: 20),
      label: Text(
        _verifying ? 'กำลังยืนยัน...' : 'ยืนยัน OTP',
        style: GoogleFonts.sarabun(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildResend() {
    return _countdown > 0
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined, size: 16, color: AppTheme.textLight),
              const SizedBox(width: 6),
              Text(
                'ส่งรหัสใหม่ได้ใน $_countdown วินาที',
                style: GoogleFonts.sarabun(fontSize: 13, color: AppTheme.textLight),
              ),
            ],
          )
        : TextButton.icon(
            onPressed: _sending ? null : _sendOtp,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              'ส่งรหัส OTP ใหม่',
              style: GoogleFonts.sarabun(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          );
  }

  Widget _buildSkipButton() {
    return GestureDetector(
      onTap: () => context.go('/home'),
      child: Text(
        'ข้ามขั้นตอนนี้ก่อน (ยืนยันภายหลังใน Settings)',
        style: GoogleFonts.sarabun(
          fontSize: 13,
          color: AppTheme.textLight,
          decoration: TextDecoration.underline,
          decorationColor: AppTheme.textLight,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
