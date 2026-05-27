import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/biometric_dialog.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword     = true;
  bool _isLoading           = false;
  bool _biometricAvailable  = false; // device supports biometric
  bool _biometricEnabled    = false; // user has set it up
  bool _hasStoredToken      = false; // token in storage
  bool _useFaceId           = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricState();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricState() async {
    final available    = await BiometricService.instance.isAvailable();
    final enabled      = await AuthService.instance.isBiometricEnabled();
    final canBioLogin  = await AuthService.instance.isBiometricLoginAvailable();
    final faceId       = await BiometricService.instance.hasFaceId();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled   = enabled;
        _hasStoredToken     = canBioLogin; // has biometric_token (survives logout)
        _useFaceId          = faceId;
      });
    }
  }

  // ── Login with email / password ─────────────────────────────────────────────

  Future<void> _onLogin() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      _showError('กรุณากรอกอีเมลและรหัสผ่าน');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.instance.login(email, password);
      await AuthService.instance.saveSession(
        data['token'] as String,
        data['profile'] as Map<String, dynamic>,
      );
      if (!mounted) return;

      // Offer to enable biometric if available but not yet set up
      final available = await BiometricService.instance.isAvailable();
      final alreadyEnabled = await AuthService.instance.isBiometricEnabled();
      if (available && !alreadyEnabled && mounted) {
        await _showEnableBiometricPrompt();
      } else if (mounted) {
        context.go('/home');
      }
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('ไม่สามารถเชื่อมต่อได้ กรุณาตรวจสอบเครือข่าย');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Biometric button tap — handles all 3 states ────────────────────────────

  Future<void> _onBiometric() async {
    if (!_hasStoredToken) {
      // No token yet — user must log in with password first
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('กรุณาเข้าสู่ระบบด้วยรหัสผ่านก่อน', style: GoogleFonts.notoSansThai()),
        backgroundColor: AppTheme.textMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }

    if (!_biometricEnabled) {
      // Has token but not set up → offer to enable
      await _showEnableBiometricPrompt();
      return;
    }

    // Enabled + has biometric token → do biometric login
    final authenticated = await BiometricService.instance.authenticate();
    if (!authenticated || !mounted) return;

    // Restore the biometric token as the active session
    final restored = await AuthService.instance.restoreFromBiometricToken();
    if (!restored || !mounted) return;

    // Refresh user profile so cache matches this user, not whoever last logged in
    try {
      final fresh = await ApiService.instance.getMe();
      final token = await AuthService.instance.getToken();
      if (token != null) await AuthService.instance.saveSession(token, fresh);
    } catch (_) {}

    if (!mounted) return;
    // Show success dialog without awaiting dismiss, auto-close after 600ms
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BiometricDialog(type: BiometricType.success),
    );
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Navigator.of(context).pop();
    context.go('/home');
  }

  // ── Prompt: enable biometric after successful password login ────────────────

  Future<void> _showEnableBiometricPrompt() async {
    final useFace = await BiometricService.instance.hasFaceId();
    if (!mounted) return;
    final label = useFace ? 'Face ID' : 'ลายนิ้วมือ';
    final icon  = useFace ? Icons.face_retouching_natural : Icons.fingerprint;

    final enable = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primary, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'เปิดใช้งาน $label?',
              style: GoogleFonts.notoSansThai(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ครั้งหน้าเข้าสู่ระบบได้เลย\nโดยไม่ต้องพิมพ์รหัสผ่าน',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansThai(
                fontSize: 14,
                color: AppTheme.textLight,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'ไว้ทีหลัง',
              style: GoogleFonts.notoSansThai(color: AppTheme.textLight, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'เปิดใช้งาน',
              style: GoogleFonts.notoSansThai(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (enable == true && mounted) {
      final confirmed = await BiometricService.instance.authenticate();
      if (confirmed) {
        await AuthService.instance.setBiometricEnabled(true);
        await AuthService.instance.saveBiometricToken();
        // Update DB so biometric_enabled=1 → won't ask again on next login
        try { await ApiService.instance.updateBiometricEnabled(true); } catch (_) {}
        if (mounted) setState(() {
          _biometricEnabled = true;
          _hasStoredToken   = true;
        });
      }
    }
    if (mounted) context.go('/home');
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.notoSansThai()),
        backgroundColor: AppTheme.priceRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

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
              const SizedBox(height: 32),
              Center(
                child: Image.asset(
                  'assets/logo/Learnsbuy_New_Logo_mail.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              _buildLabel('อีเมล'),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
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
                  hintText: '••••••••',
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
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => context.push('/forgot-password'),
                  child: Text(
                    'ลืมรหัสผ่าน?',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 14,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _onLogin,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('เข้าสู่ระบบ →'),
              ),
              // Show biometric section whenever device supports it
              if (_biometricAvailable) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'หรือเข้าสู่ระบบด้วย',
                        style: GoogleFonts.notoSansThai(fontSize: 13, color: AppTheme.textLight),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _onBiometric,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _biometricEnabled ? AppTheme.primary : AppTheme.border,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            color: _biometricEnabled ? AppTheme.primaryLight : const Color(0xFFF5F5F5),
                          ),
                          child: Icon(
                            _useFaceId ? Icons.face_retouching_natural : Icons.fingerprint,
                            color: _biometricEnabled ? AppTheme.primary : AppTheme.textLight,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _useFaceId ? 'Face ID' : 'ลายนิ้วมือ',
                        style: GoogleFonts.notoSansThai(fontSize: 12, color: AppTheme.textLight),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Center(
                child: GestureDetector(
                  onTap: () => context.push('/register'),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.notoSansThai(fontSize: 14, color: AppTheme.textMedium),
                      children: [
                        const TextSpan(text: 'ยังไม่มีบัญชี? '),
                        TextSpan(
                          text: 'สมัครสมาชิก',
                          style: GoogleFonts.notoSansThai(
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
      style: GoogleFonts.notoSansThai(
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Image.asset(
        'assets/logo/logo.png',
        height: 62,
        fit: BoxFit.contain,
      ),
    );
  }
}
