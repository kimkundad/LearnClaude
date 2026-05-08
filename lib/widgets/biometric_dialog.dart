import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum BiometricType { fingerprint, faceId, success }

class BiometricDialog extends StatelessWidget {
  final BiometricType type;

  const BiometricDialog({super.key, required this.type});

  static Future<void> show(BuildContext context, BiometricType type) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => BiometricDialog(type: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            const SizedBox(height: 20),
            Text(
              _title,
              style: GoogleFonts.sarabun(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _subtitle,
              style: GoogleFonts.sarabun(
                fontSize: 14,
                color: AppTheme.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (type == BiometricType.success) {
      return Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
          color: AppTheme.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 40),
      );
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primary, width: 3),
        color: AppTheme.primaryLight,
      ),
      child: Icon(
        type == BiometricType.faceId
            ? Icons.face_retouching_natural
            : Icons.fingerprint,
        color: AppTheme.primary,
        size: 40,
      ),
    );
  }

  String get _title {
    switch (type) {
      case BiometricType.fingerprint:
        return 'แตะเซ็นเซอร์';
      case BiometricType.faceId:
        return 'มอง Face ID';
      case BiometricType.success:
        return 'สำเร็จ!';
    }
  }

  String get _subtitle {
    switch (type) {
      case BiometricType.fingerprint:
        return 'เพื่อเข้าสู่ระบบอย่างปลอดภัย';
      case BiometricType.faceId:
        return 'เพื่อเข้าสู่ระบบอย่างปลอดภัย';
      case BiometricType.success:
        return 'กำลังเข้าสู่ระบบ...';
    }
  }
}
