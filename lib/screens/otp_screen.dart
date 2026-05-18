import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class OTPScreen extends StatefulWidget {
  final String email;

  const OTPScreen({super.key, required this.email});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _secondsLeft = 60;
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    for (var c in _controllers) {
      c.addListener(() => setState(() {}));
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        t.cancel();
      }
    });
  }

  Future<void> _resend() async {
    try {
      await ApiService.instance.forgotPassword(widget.email);
      if (mounted) {
        setState(() => _secondsLeft = 60);
        _startTimer();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('ส่งรหัสใหม่แล้ว', style: GoogleFonts.sarabun()),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (_) {
      if (mounted) _showError('ส่งรหัสไม่สำเร็จ กรุณาลองใหม่');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();
  bool get _isComplete => _otp.length == 6;

  Future<void> _onVerify() async {
    setState(() => _isLoading = true);
    try {
      final resetToken = await ApiService.instance.verifyOtp(widget.email, _otp);
      if (mounted) {
        context.push('/set-password', extra: {
          'email': widget.email,
          'reset_token': resetToken,
        });
      }
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('ไม่สามารถเชื่อมต่อได้ กรุณาตรวจสอบเครือข่าย');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.sarabun()),
      backgroundColor: AppTheme.priceRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final maskedEmail = _maskEmail(widget.email);

    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chevron_left, color: AppTheme.textDark),
                ),
              ),
              const SizedBox(height: 16),
              _StepProgress(currentStep: 2, totalSteps: 3),
              const SizedBox(height: 32),
              Text(
                'กรอกรหัสยืนยัน',
                style: GoogleFonts.sarabun(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.sarabun(fontSize: 14, color: AppTheme.textLight),
                  children: [
                    const TextSpan(text: 'รหัส 6 หลักถูกส่งไปที่\n'),
                    TextSpan(
                      text: maskedEmail,
                      style: GoogleFonts.sarabun(
                        fontSize: 14,
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _buildOtpBox(i)),
              ),
              const SizedBox(height: 28),
              Center(
                child: _secondsLeft > 0
                    ? Text(
                        'ไม่ได้รับรหัส? ส่งใหม่ได้ใน ${_secondsLeft}s',
                        style: GoogleFonts.sarabun(
                          fontSize: 13,
                          color: AppTheme.textLight,
                        ),
                      )
                    : GestureDetector(
                        onTap: _resend,
                        child: Text(
                          'ส่งรหัสใหม่อีกครั้ง',
                          style: GoogleFonts.sarabun(
                            fontSize: 13,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: (_isComplete && !_isLoading) ? _onVerify : null,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('ยืนยันรหัส →'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 46,
      height: 54,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: GoogleFonts.sarabun(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppTheme.textDark,
        ),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: _controllers[index].text.isNotEmpty
                  ? AppTheme.primary
                  : AppTheme.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
          ),
        ),
        onChanged: (v) {
          if (v.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (v.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '${name[0]}***@$domain';
    return '${name.substring(0, 2)}${'*' * (name.length - 2)}@$domain';
  }
}

class _StepProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepProgress({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final active = i < currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: active ? AppTheme.primary : AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
