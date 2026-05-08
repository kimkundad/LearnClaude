import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(() => setState(() {}));
    _confirmCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  double get _passwordStrength {
    final p = _passwordCtrl.text;
    if (p.isEmpty) return 0;
    double strength = 0;
    if (p.length >= 8) strength += 0.25;
    if (p.contains(RegExp(r'[a-z]'))) strength += 0.25;
    if (p.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (p.contains(RegExp(r'[0-9!@#\$%^&*]'))) strength += 0.25;
    return strength;
  }

  Color get _strengthColor {
    final s = _passwordStrength;
    if (s <= 0.25) return AppTheme.priceRed;
    if (s <= 0.5) return AppTheme.warning;
    if (s <= 0.75) return Colors.orange;
    return AppTheme.primary;
  }

  String get _strengthLabel {
    final s = _passwordStrength;
    if (s <= 0.25) return 'อ่อน';
    if (s <= 0.5) return 'พอใช้';
    if (s <= 0.75) return 'ดี';
    return 'แข็งแกร่ง';
  }

  bool get _passwordsMatch =>
      _confirmCtrl.text.isNotEmpty &&
      _passwordCtrl.text == _confirmCtrl.text;

  bool get _canSubmit =>
      _usernameCtrl.text.isNotEmpty &&
      _emailCtrl.text.isNotEmpty &&
      _passwordCtrl.text.length >= 6 &&
      _passwordsMatch &&
      _acceptTerms;

  void _onRegister() {
    context.go('/home');
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
              const SizedBox(height: 24),
              _AppLogoHeader(),
              const SizedBox(height: 32),
              Text(
                'สมัครสมาชิก 🎉',
                style: GoogleFonts.sarabun(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'สร้างบัญชีเพื่อเริ่มเรียน',
                style: GoogleFonts.sarabun(fontSize: 15, color: AppTheme.textLight),
              ),
              const SizedBox(height: 28),
              _buildLabel('ชื่อผู้ใช้'),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameCtrl,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'เช่น พี่โฮม',
                  prefixIcon: Icon(Icons.person_outline, color: AppTheme.textLight),
                ),
              ),
              const SizedBox(height: 16),
              _buildLabel('อีเมล'),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
                onChanged: (_) => setState(() {}),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'you@example.com',
                  prefixIcon: Icon(Icons.mail_outline, color: AppTheme.textLight),
                ),
              ),
              const SizedBox(height: 16),
              _buildLabel('รหัสผ่าน'),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'อย่างน้อย 6 ตัวอักษร',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textLight),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppTheme.textLight,
                    ),
                  ),
                ),
              ),
              if (_passwordCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _passwordStrength,
                          backgroundColor: AppTheme.border,
                          valueColor: AlwaysStoppedAnimation(_strengthColor),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _strengthLabel,
                      style: GoogleFonts.sarabun(
                        fontSize: 12,
                        color: _strengthColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              _buildLabel('ยืนยันรหัสผ่าน'),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  hintText: 'พิมพ์รหัสผ่านอีกครั้ง',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textLight),
                  suffixIcon: _confirmCtrl.text.isEmpty
                      ? GestureDetector(
                          onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          child: Icon(
                            _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppTheme.textLight,
                          ),
                        )
                      : Icon(
                          _passwordsMatch ? Icons.check_circle : Icons.cancel,
                          color: _passwordsMatch ? AppTheme.primary : AppTheme.priceRed,
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _acceptTerms,
                    onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.sarabun(fontSize: 13, color: AppTheme.textMedium),
                          children: [
                            const TextSpan(text: 'ยอมรับ '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => context.push('/terms'),
                                child: Text(
                                  'ข้อกำหนด',
                                  style: GoogleFonts.sarabun(
                                    fontSize: 13,
                                    color: AppTheme.primary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            const TextSpan(text: ' และ '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => context.push('/privacy'),
                                child: Text(
                                  'นโยบายความเป็นส่วนตัว',
                                  style: GoogleFonts.sarabun(
                                    fontSize: 13,
                                    color: AppTheme.primary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _canSubmit ? _onRegister : null,
                child: const Text('สร้างบัญชี →'),
              ),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.sarabun(fontSize: 14, color: AppTheme.textMedium),
                      children: [
                        const TextSpan(text: 'มีบัญชีอยู่แล้ว? '),
                        TextSpan(
                          text: 'เข้าสู่ระบบ',
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.sarabun(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textDark,
      ),
    );
  }
}

class _AppLogoHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              'ホ',
              style: GoogleFonts.sarabun(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ครูพี่โฮม',
              style: GoogleFonts.sarabun(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            Text(
              'เรียนภาษาญี่ปุ่นออนไลน์',
              style: GoogleFonts.sarabun(fontSize: 12, color: AppTheme.textLight),
            ),
          ],
        ),
      ],
    );
  }
}
