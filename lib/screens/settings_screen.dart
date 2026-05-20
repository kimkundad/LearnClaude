import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String  _name      = '';
  String  _initial   = '';
  String  _points    = '';
  String? _avatarUrl;

  static const _avatarBase = 'https://learnsbuy.com/assets/images/avatar/';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // ใช้ cache ก่อนเพื่อให้แสดงเร็ว
    final cached = await AuthService.instance.getUser();
    if (cached != null) _applyProfile(cached);
    // ดึงข้อมูลใหม่จาก API
    try {
      final fresh = await ApiService.instance.getMe();
      _applyProfile(fresh);
      final token = await AuthService.instance.getToken();
      if (token != null) await AuthService.instance.saveSession(token, fresh);
    } catch (_) {}
  }

  void _applyProfile(Map<String, dynamic> u) {
    if (!mounted) return;
    final name = (u['name'] as String?) ?? '';
    final points = (u['user_coin'] as num?)?.toStringAsFixed(0) ?? '';
    final f = u['avatar'] as String?;
    setState(() {
      _name      = name;
      _initial   = name.isNotEmpty ? name[0].toUpperCase() : '?';
      _points    = points;
      _avatarUrl = (f != null && f.isNotEmpty) ? '$_avatarBase$f' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildProfileHeader()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  children: [
                    _buildMenuGroup([
                      _MenuItem(
                        icon: Icons.person_outline_rounded,
                        label: 'Edit Profile',
                        labelTh: 'แก้ไขโปรไฟล์',
                        onTap: () async {
                          await context.push('/edit-profile');
                          _loadProfile();
                        },
                      ),
                      _MenuItem(
                        icon: Icons.lock_reset_rounded,
                        label: 'Reset Password',
                        labelTh: 'เปลี่ยนรหัสผ่าน',
                        onTap: () => context.push('/change-password'),
                      ),
                      _MenuItem(
                        icon: Icons.headset_mic_outlined,
                        label: 'Help Center',
                        labelTh: 'ช่วยเหลือ',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ChatScreen()),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    _buildMenuGroup([
                      _MenuItem(
                        icon: Icons.notifications_none_rounded,
                        label: 'Notification',
                        labelTh: 'การแจ้งเตือน',
                        trailing: Switch(
                          value: _notificationsEnabled,
                          onChanged: (v) => setState(() => _notificationsEnabled = v),
                          activeColor: AppTheme.primary,
                          activeTrackColor: AppTheme.primaryLight,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: AppTheme.border,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    _buildMenuGroup([
                      _MenuItem(
                        icon: Icons.campaign_rounded,
                        label: 'Announcement',
                        labelTh: 'ประชาสัมพันธ์',
                        onTap: () => context.push('/articles'),
                      ),
                      _MenuItem(
                        icon: Icons.lock_outline_rounded,
                        label: 'Privacy Policy',
                        labelTh: 'นโยบายความเป็นส่วนตัว',
                        onTap: () => context.push('/privacy'),
                      ),
                      _MenuItem(
                        icon: Icons.info_outline_rounded,
                        label: 'About Us',
                        labelTh: 'เกี่ยวกับเรา',
                        onTap: () => context.push('/about-us'),
                      ),
                      _MenuItem(
                        icon: Icons.article_outlined,
                        label: 'Terms of Service',
                        labelTh: 'ข้อกำหนดการใช้บริการ',
                        onTap: () => context.push('/terms'),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    _buildMenuGroup([
                      _MenuItem(
                        icon: Icons.logout_rounded,
                        label: 'Logout',
                        labelTh: 'ออกจากระบบ',
                        isDestructive: true,
                        onTap: () => _showLogoutDialog(context),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildDeleteAccountButton(context),
                    const SizedBox(height: 32),
                    Text(
                      'ครูพี่โฮม · เวอร์ชัน 1.0.0',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 12,
                        color: AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _initialCircle() {
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
          _initial,
          style: GoogleFonts.notoSansThai(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _avatarUrl != null
                      ? Image.network(
                          _avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _initialCircle(),
                        )
                      : _initialCircle(),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => context.push('/edit-profile'),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _name,
            style: GoogleFonts.notoSansThai(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, size: 14, color: AppTheme.primary),
                const SizedBox(width: 4),
                Text(
                  'POINT $_points',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGroup(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return Column(
            children: [
              _buildMenuRow(item),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 56),
                  child: Divider(height: 1, color: AppTheme.border),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMenuRow(_MenuItem item) {
    final iconBg = item.isDestructive
        ? AppTheme.priceRed.withOpacity(0.1)
        : AppTheme.primaryLight;
    final iconColor = item.isDestructive ? AppTheme.priceRed : AppTheme.primary;
    final textColor = item.isDestructive ? AppTheme.priceRed : AppTheme.textDark;

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    item.labelTh,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 11,
                      color: item.isDestructive
                          ? AppTheme.priceRed.withOpacity(0.7)
                          : AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            if (item.trailing != null)
              item.trailing!
            else
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: item.isDestructive ? AppTheme.priceRed : AppTheme.textLight,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDeleteAccountDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.priceRed.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.priceRed.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.priceRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.priceRed),
            ),
            const SizedBox(width: 10),
            Text(
              'Delete Account',
              style: GoogleFonts.notoSansThai(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.priceRed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'ออกจากระบบ',
          style: GoogleFonts.notoSansThai(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'คุณต้องการออกจากระบบใช่หรือไม่?',
          style: GoogleFonts.notoSansThai(color: AppTheme.textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'ยกเลิก',
              style: GoogleFonts.notoSansThai(color: AppTheme.textLight),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.instance.logout();
              if (context.mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.priceRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('ออกจากระบบ', style: GoogleFonts.notoSansThai(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'ลบบัญชี',
          style: GoogleFonts.notoSansThai(fontWeight: FontWeight.w800, color: AppTheme.priceRed),
        ),
        content: Text(
          'การลบบัญชีจะไม่สามารถกู้คืนได้ คุณแน่ใจหรือไม่?',
          style: GoogleFonts.notoSansThai(color: AppTheme.textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'ยกเลิก',
              style: GoogleFonts.notoSansThai(color: AppTheme.textLight),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.priceRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('ลบบัญชี', style: GoogleFonts.notoSansThai(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String labelTh;
  final bool isDestructive;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.labelTh,
    this.isDestructive = false,
    this.onTap,
    this.trailing,
  });
}
