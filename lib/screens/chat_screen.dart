import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String? initialMessage;
  const ChatScreen({super.key, this.initialMessage});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _dio           = Dio(BaseOptions(baseUrl: AppConfig.chatApi));
  final _msgCtrl       = TextEditingController();
  final _scrollCtrl    = ScrollController();
  final _imagePicker   = ImagePicker();
  final _audioRecorder = AudioRecorder();
  final _audioPlayer   = AudioPlayer();

  Timer? _pollTimer;
  StreamSubscription<void>? _playerSub;

  List<Map<String, dynamic>> _messages = [];
  bool _loading     = true;
  bool _isSending   = false;
  bool _isRecording = false;
  DateTime? _recordStart;
  int? _playingIndex;
  int? _lastId;

  int? _myUserId;
  String _myName = 'นักเรียน';
  int? _roomId;

  @override
  void initState() {
    super.initState();
    NotificationService.instance.isChatOpen = true;
    _init();
  }

  @override
  void dispose() {
    NotificationService.instance.isChatOpen = false;
    _pollTimer?.cancel();
    _playerSub?.cancel();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    try {
      final user = await AuthService.instance.getUser();
      _myUserId = (user?['id'] as num?)?.toInt();
      _myName   = (user?['name'] as String?) ?? 'นักเรียน';

      if (_myUserId == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      // บันทึก FCM token ไปที่ server
      await NotificationService.instance.saveToken(_myUserId!);

      // get or create chat room
      final roomRes = await _dio.post('/create-room', data: {
        'student_id': _myUserId,
        'teacher_id': AppConfig.teacherId,
      });
      _roomId = (roomRes.data['room_id'] as num?)?.toInt();

      await _load(markRead: false);

      if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
        _msgCtrl.text = widget.initialMessage!;
        await _sendText();
      }

      // poll every 5 s like teacher
      _pollTimer = Timer.periodic(
        const Duration(seconds: 5), (_) => _load());
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _load({bool markRead = false}) async {
    if (_roomId == null) return;
    try {
      final r    = await _dio.get('/messages/$_roomId');
      final list = (r.data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (!mounted) return;
      final hasNew = list.isNotEmpty && (list.last['id'] as int?) != _lastId;
      setState(() {
        _messages = list;
        _loading  = false;
        if (list.isNotEmpty) _lastId = list.last['id'] as int?;
      });
      if (hasNew) _scrollToTop();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  // ── Send helpers ──────────────────────────────────────────────────────────

  Future<void> _sendText() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending || _roomId == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _msgCtrl.clear();
    setState(() => _isSending = true);
    try {
      await _dio.post('/send-message', data: {
        'room_id':      _roomId,
        'sender_id':    _myUserId,
        'message':      text,
        'message_type': 'text',
        'name':         _myName,
      });
      await _load();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendImage() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (picked == null || !mounted || _roomId == null) return;

    setState(() => _isSending = true);
    try {
      final result   = await ApiService.instance.uploadChatMedia(File(picked.path));
      final mediaUrl = result['url'] as String;
      await _dio.post('/send-message', data: {
        'room_id':      _roomId,
        'sender_id':    _myUserId,
        'message_type': 'image',
        'media_url':    mediaUrl,
        'name':         _myName,
      });
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('ส่งรูปไม่สำเร็จ: $e', style: GoogleFonts.notoSansThai())));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _toggleRecording() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_isRecording) {
      await _stopAndSendVoice();
      return;
    }
    final ok = await _audioRecorder.hasPermission();
    if (!ok) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('ไม่สามารถใช้ไมโครโฟนได้ กรุณาอนุญาตสิทธิ์ก่อน',
            style: GoogleFonts.notoSansThai())));
      return;
    }
    final dir  = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    setState(() {
      _isRecording = true;
      _recordStart = DateTime.now();
    });
  }

  Future<void> _stopAndSendVoice() async {
    final path  = await _audioRecorder.stop();
    final start = _recordStart;
    final secs  = start == null
        ? 1
        : DateTime.now().difference(start).inSeconds.clamp(1, 599).toInt();
    setState(() {
      _isRecording = false;
      _recordStart = null;
    });
    if (path == null || !mounted || _roomId == null) return;

    setState(() => _isSending = true);
    try {
      final result   = await ApiService.instance.uploadChatMedia(File(path));
      final mediaUrl = result['url'] as String;
      await _dio.post('/send-message', data: {
        'room_id':      _roomId,
        'sender_id':    _myUserId,
        'message_type': 'audio',
        'media_url':    mediaUrl,
        'duration':     secs,
        'name':         _myName,
      });
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('ส่งเสียงไม่สำเร็จ: $e', style: GoogleFonts.notoSansThai())));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ── Audio playback ────────────────────────────────────────────────────────

  Future<void> _togglePlayback(int index, String url) async {
    if (_playingIndex == index) {
      await _audioPlayer.stop();
      if (mounted) setState(() => _playingIndex = null);
      return;
    }
    await _audioPlayer.stop();
    await _playerSub?.cancel();
    _playerSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingIndex = null);
    });
    await _audioPlayer.play(UrlSource(url));
    if (mounted) setState(() => _playingIndex = index);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool _isMe(Map<String, dynamic> msg) =>
      (msg['sender_id'] as num?)?.toInt() == _myUserId;

  String _timeLabel(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }

  String _fmtDur(int s) =>
      '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded,
              color: Colors.white, size: 30),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Column(
          children: [
            Text('ส่งข้อความถึงเรา',
                style: GoogleFonts.notoSansThai(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18)),
            Text(
              _isRecording
                  ? 'กำลังอัดเสียง แตะปุ่มหยุดเพื่อส่ง'
                  : 'ครูพี่โฮมและทีมช่วยเหลือ',
              style: GoogleFonts.notoSansThai(
                  color: Colors.white.withOpacity(0.78),
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _statusStrip(),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? _emptyState()
                      : ListView.builder(
                          controller: _scrollCtrl,
                          reverse: true,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding:
                              const EdgeInsets.fromLTRB(16, 18, 16, 16),
                          itemCount: _messages.length,
                          itemBuilder: (_, listIdx) {
                            final i = _messages.length - 1 - listIdx;
                            return _bubble(i, _messages[i]);
                          },
                        ),
            ),
          ),
          _composer(),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
              color: AppTheme.primaryLight, shape: BoxShape.circle),
          child: const Icon(Icons.chat_bubble_outline_rounded,
              color: AppTheme.primary, size: 40),
        ),
        const SizedBox(height: 14),
        Text('เริ่มต้นการสนทนา',
            style: GoogleFonts.notoSansThai(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark)),
        const SizedBox(height: 6),
        Text('ส่งข้อความหาครูพี่โฮมได้เลย',
            style: GoogleFonts.notoSansThai(
                fontSize: 13,
                color: AppTheme.textLight,
                fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _statusStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: _isRecording
          ? const Color(0xFFFFF1F2)
          : const Color(0xFFF2FAF8),
      child: Row(
        children: [
          Container(
            width: 9, height: 9,
            decoration: BoxDecoration(
              color: _isRecording ? AppTheme.priceRed : AppTheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isRecording
                ? 'กำลังอัดข้อความเสียง... แตะปุ่มหยุดเพื่อส่ง'
                : 'ออนไลน์ · ปกติตอบภายใน 5-15 นาที',
            style: GoogleFonts.notoSansThai(
                fontSize: 12,
                color: AppTheme.textMedium,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _bubble(int index, Map<String, dynamic> msg) {
    final isMe      = _isMe(msg);
    final type      = (msg['message_type'] as String?) ?? 'text';
    final text      = (msg['message'] as String?) ?? '';
    final mediaUrl  = (msg['media_url'] as String?) ?? '';
    final senderName = isMe ? _myName : ((msg['name'] as String?) ?? 'ครูพี่โฮม');
    final timeStr   = _timeLabel(msg['created_at'] as String?);
    final bubbleColor = isMe ? AppTheme.primary : const Color(0xFFF0F3F6);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: type == 'image' && mediaUrl.isNotEmpty
                  ? EdgeInsets.zero
                  : const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  Radius.circular(isMe ? 18 : 5),
                  bottomRight: Radius.circular(isMe ? 5 : 18),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    Padding(
                      padding: type == 'image' && mediaUrl.isNotEmpty
                          ? const EdgeInsets.fromLTRB(13, 10, 13, 4)
                          : EdgeInsets.zero,
                      child: Text(senderName,
                          style: GoogleFonts.notoSansThai(
                              fontSize: 12,
                              color: AppTheme.textLight,
                              fontWeight: FontWeight.w900)),
                    ),
                    if (!(type == 'image' && mediaUrl.isNotEmpty))
                      const SizedBox(height: 4),
                  ],
                  _bubbleContent(index, isMe, type, text, mediaUrl, msg),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(timeStr,
                style: GoogleFonts.notoSansThai(
                    fontSize: 10, color: AppTheme.textLight)),
          ],
        ),
      ),
    );
  }

  Widget _bubbleContent(int index, bool isMe, String type,
      String text, String mediaUrl, Map<String, dynamic> msg) {
    final textColor = isMe ? Colors.white : AppTheme.textDark;

    if (type == 'image' && mediaUrl.isNotEmpty) {
      return GestureDetector(
        onTap: () => _showImageFull(mediaUrl),
        child: Stack(
          children: [
            Image.network(
              mediaUrl,
              width: 220, height: 160,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : SizedBox(
                      width: 220, height: 160,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    ),
              errorBuilder: (_, __, ___) => Container(
                  width: 220, height: 100,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image_rounded, size: 40)),
            ),
            Positioned(
              right: 8, bottom: 8,
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.28),
                    shape: BoxShape.circle),
                child: const Icon(Icons.open_in_full_rounded,
                    size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (type == 'audio' && mediaUrl.isNotEmpty) {
      final dur     = (msg['duration'] as num?)?.toInt() ?? 0;
      final playing = _playingIndex == index;
      return GestureDetector(
        onTap: () => _togglePlayback(index, mediaUrl),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 32, height: 32,
              decoration: BoxDecoration(
                  color: textColor.withOpacity(playing ? 0.24 : 0.12),
                  shape: BoxShape.circle),
              child: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: textColor, size: 21),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: playing ? null : 0.18,
                  minHeight: 5,
                  backgroundColor: textColor.withOpacity(0.24),
                  valueColor:
                      AlwaysStoppedAnimation(textColor.withOpacity(0.78)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              playing ? 'กำลังเล่น...' : 'เสียง ${_fmtDur(dur)}',
              style: GoogleFonts.notoSansThai(
                  fontSize: 13,
                  color: textColor,
                  fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );
    }

    return Text(text,
        style: GoogleFonts.notoSansThai(
            fontSize: 15,
            color: textColor,
            height: 1.4,
            fontWeight: FontWeight.w700));
  }

  void _showImageFull(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.74),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38, height: 38,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white),
                ),
              ),
            ),
            Container(
              width: double.infinity, height: 360,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22)),
              child: Image.network(url, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_rounded,
                      size: 86, color: AppTheme.primary)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Composer ──────────────────────────────────────────────────────────────

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.border))),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _iconBtn(
              icon: Icons.image_outlined,
              onTap: _isSending || _isRecording ? null : _sendImage,
            ),
            _iconBtn(
              icon: _isRecording
                  ? Icons.stop_rounded
                  : Icons.mic_none_rounded,
              onTap: _isSending ? null : _toggleRecording,
              active: _isRecording,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                minLines: 1,
                maxLines: 4,
                enabled: !_isRecording,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendText(),
                decoration: InputDecoration(
                  hintText: _isRecording
                      ? 'กำลังอัดเสียง...'
                      : 'พิมพ์ข้อความ...',
                  hintStyle: GoogleFonts.notoSansThai(
                      color: Colors.grey.shade400),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: const Color(0xFFF8F8F8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide(color: AppTheme.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide(color: AppTheme.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(
                          color: AppTheme.primary, width: 1.5)),
                ),
                style: GoogleFonts.notoSansThai(fontSize: 15),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isSending || _isRecording ? null : _sendText,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: (_isSending || _isRecording)
                      ? AppTheme.border
                      : AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isSending
                      ? Icons.hourglass_empty_rounded
                      : Icons.send_rounded,
                  color: Colors.white, size: 21,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    VoidCallback? onTap,
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: active ? AppTheme.priceRed : AppTheme.primaryLight,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color: active ? Colors.white : AppTheme.primary, size: 21),
      ),
    );
  }
}
