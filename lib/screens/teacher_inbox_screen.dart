import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_config.dart';
import '../theme/app_theme.dart';
import 'teacher_chat_screen.dart';

class TeacherInboxScreen extends StatefulWidget {
  const TeacherInboxScreen({super.key});

  @override
  State<TeacherInboxScreen> createState() => _TeacherInboxScreenState();
}

class _TeacherInboxScreenState extends State<TeacherInboxScreen> {
  final _dio = Dio(BaseOptions(baseUrl: AppConfig.chatApi));
  final _searchCtrl = TextEditingController();
  Timer? _refreshTimer;

  List<Map<String, dynamic>> _rooms = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _load());
    _searchCtrl.addListener(_applySearch);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await _dio.get('/students-chats');
      if (!mounted) return;
      final list = (r.data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      setState(() {
        _rooms    = list;
        _isLoading = false;
      });
      _applySearch();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applySearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_rooms)
          : _rooms.where((r) {
              final name = ((r['name'] as String?) ?? '').toLowerCase();
              return name.contains(q);
            }).toList();
    });
  }

  String _timeLabel(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1)  return 'เมื่อกี้';
      if (diff.inMinutes < 60) return '${diff.inMinutes} น. ก่อน';
      if (diff.inHours   < 24) return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      if (diff.inDays    == 1) return 'เมื่อวาน';
      if (diff.inDays    < 7)  return _thaiWeekday(dt.weekday);
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }

  String _thaiWeekday(int w) {
    const days = ['จันทร์', 'อังคาร', 'พุธ', 'พฤหัสฯ', 'ศุกร์', 'เสาร์', 'อาทิตย์'];
    return days[(w - 1).clamp(0, 6)];
  }

  static const _avatarBase = 'https://learnsbuy.com/assets/images/avatar/';

  String _avatarUrl(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    if (raw.startsWith('http')) return raw;
    if (raw.startsWith('./') || raw.startsWith('assets/')) {
      return 'https://learnsbuy.com/$raw';
    }
    return '$_avatarBase$raw';
  }

  // รองรับทั้ง format เก่า (is_read) และใหม่ (unread_count)
  int _unreadCount(Map<String, dynamic> room) {
    final newField = room['unread_count'];
    if (newField != null) return (newField as num).toInt();
    final isRead = room['is_read'];
    if (isRead == null) return 0;
    final isReadInt = isRead is bool ? (isRead ? 1 : 0) : (isRead as num).toInt();
    return isReadInt == 0 ? 1 : 0;
  }

  String _previewText(Map<String, dynamic> room) {
    final type = (room['message_type'] as String?) ?? 'text';
    final lastSender = room['last_sender_id'];
    final isTeacher = lastSender != null
        ? (lastSender as num).toInt() == AppConfig.teacherId
        : false;
    final prefix = isTeacher ? 'คุณ: ' : '';
    if (type == 'image') return '${prefix}ส่งรูปภาพ';
    if (type == 'audio') return '${prefix}ส่งข้อความเสียง';
    return '$prefix${(room['message'] as String?) ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'แชท',
          style: GoogleFonts.sarabun(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () { setState(() => _isLoading = true); _load(); },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            indent: 80,
                            endIndent: 16,
                          ),
                          itemBuilder: (_, i) => _buildRow(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'ค้นหา',
          hintStyle: GoogleFonts.sarabun(color: Colors.grey.shade400),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () { _searchCtrl.clear(); _applySearch(); },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF2F3F5),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        style: GoogleFonts.sarabun(fontSize: 15),
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> room) {
    final name       = (room['name'] as String?) ?? 'นักเรียน';
    final avatarUrl  = _avatarUrl(room['avatar'] as String?);
    final preview    = _previewText(room);
    final timeLabel  = _timeLabel(room['created_at'] as String?);
    final unread     = _unreadCount(room);
    final roomId     = (room['room_id'] as num?)?.toInt() ?? 0;

    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TeacherChatScreen(
              roomId:      roomId,
              studentName: name,
              avatarUrl:   avatarUrl.isNotEmpty ? avatarUrl : null,
            ),
          ),
        );
        _load(); // refresh unread after returning
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            _buildAvatar(name, avatarUrl, unread > 0),
            const SizedBox(width: 12),
            // Name + preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.sarabun(
                            fontSize: 15,
                            fontWeight: unread > 0 ? FontWeight.w900 : FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeLabel,
                        style: GoogleFonts.sarabun(
                          fontSize: 11,
                          color: unread > 0 ? AppTheme.primary : AppTheme.textLight,
                          fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.sarabun(
                            fontSize: 13,
                            color: unread > 0 ? AppTheme.textDark : AppTheme.textLight,
                            fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: GoogleFonts.sarabun(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, String url, bool hasUnread) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Stack(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppTheme.primaryLight,
          backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
          child: url.isEmpty
              ? Text(
                  initials,
                  style: GoogleFonts.sarabun(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                  ),
                )
              : null,
        ),

        if (hasUnread)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Text(
        'ยังไม่มีข้อความ',
        style: GoogleFonts.sarabun(fontSize: 15, color: AppTheme.textLight),
      ),
    );
  }
}
