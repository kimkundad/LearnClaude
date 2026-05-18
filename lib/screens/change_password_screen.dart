import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showCurrent = false;
  bool _showNew     = false;
  bool _showConfirm = false;
  bool _loading     = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _currentCtrl.text.isNotEmpty &&
      _newCtrl.text.length >= 6 &&
      _newCtrl.text == _confirmCtrl.text;

  Future<void> _submit() async {
    if (!_canSubmit || _loading) return;
    setState(() => _loading = true);
    try {
      await ApiService.instance.changePassword(
        currentPassword: _currentCtrl.text.trim(),
        newPassword: _newCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('เปลี่ยนรหัสผ่านสำเร็จ', style: GoogleFonts.sarabun(color: Colors.white)),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
      ));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: GoogleFonts.sarabun(color: Colors.white)),
        backgroundColor: AppTheme.priceRed,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28, color: AppTheme.textDark),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'เปลี่ยนรหัสผ่าน',
          style: GoogleFonts.sarabun(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _infoCard(),
            const SizedBox(height: 24),
            _fieldLabel('รหัสผ่านปัจจุบัน'),
            const SizedBox(height: 8),
            _passwordField(
              controller: _currentCtrl,
              hint: 'กรอกรหัสผ่านปัจจุบัน',
              visible: _showCurrent,
              onToggle: () => setState(() => _showCurrent = !_showCurrent),
            ),
            const SizedBox(height: 20),
            _fieldLabel('รหัสผ่านใหม่'),
            const SizedBox(height: 8),
            _passwordField(
              controller: _newCtrl,
              hint: 'อย่างน้อย 6 ตัวอักษร',
              visible: _showNew,
              onToggle: () => setState(() => _showNew = !_showNew),
            ),
            const SizedBox(height: 20),
            _fieldLabel('ยืนยันรหัสผ่านใหม่'),
            const SizedBox(height: 8),
            _passwordField(
              controller: _confirmCtrl,
              hint: 'กรอกรหัสผ่านใหม่อีกครั้ง',
              visible: _showConfirm,
              onToggle: () => setState(() => _showConfirm = !_showConfirm),
              errorText: _confirmCtrl.text.isNotEmpty &&
                      _newCtrl.text != _confirmCtrl.text
                  ? 'รหัสผ่านไม่ตรงกัน'
                  : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _canSubmit && !_loading ? _submit : null,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      'บันทึกรหัสผ่านใหม่',
                      style: GoogleFonts.sarabun(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'รหัสผ่านใหม่ต้องมีอย่างน้อย 6 ตัวอักษร',
              style: GoogleFonts.sarabun(
                fontSize: 13,
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.sarabun(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.textDark,
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool visible,
    required VoidCallback onToggle,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textLight, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppTheme.textLight,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        errorText: errorText,
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
