import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSend() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ApiService.instance.forgotPassword(email);
      if (mounted) context.push('/otp', extra: email);
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
              _StepProgress(currentStep: 1, totalSteps: 3),
              const SizedBox(height: 32),
              Text(
                'ลืมรหัสผ่าน?',
                style: GoogleFonts.sarabun(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'กรอกอีเมลที่ใช้สมัคร เราจะส่งรหัสยืนยัน 6 หลักไปให้',
                style: GoogleFonts.sarabun(fontSize: 14, color: AppTheme.textLight),
              ),
              const SizedBox(height: 32),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    color: AppTheme.primary,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'อีเมล',
                style: GoogleFonts.sarabun(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'you@example.com',
                  prefixIcon: Icon(Icons.mail_outline, color: AppTheme.textLight),
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: (_emailCtrl.text.isNotEmpty && !_isLoading) ? _onSend : null,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('ส่งรหัสยืนยัน →'),
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/login'),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.sarabun(fontSize: 14, color: AppTheme.textMedium),
                      children: [
                        const TextSpan(text: 'จำรหัสได้แล้ว? '),
                        TextSpan(
                          text: 'กลับไปเข้าสู่ระบบ',
                          style: GoogleFonts.sarabun(
                            fontSize: 14,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
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
