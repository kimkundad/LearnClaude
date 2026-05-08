import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageCtrl = TextEditingController();
  final _imagePicker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  StreamSubscription<void>? _playerCompleteSub;

  int? _playingVoiceIndex;
  bool _isRecording = false;
  DateTime? _recordStartedAt;

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      sender: 'ครูพี่โฮม',
      text: 'สวัสดีครับ มีอะไรให้พี่โฮมช่วยดูไหมครับ',
      isMe: false,
      type: _MessageType.text,
    ),
    const _ChatMessage(
      sender: 'kim kundad.',
      text: 'อยากถามเรื่องวันหมดอายุคอร์สค่ะ',
      isMe: true,
      type: _MessageType.text,
    ),
    const _ChatMessage(
      sender: 'ครูพี่โฮม',
      text: 'ส่งชื่อคอร์สหรือรูปหน้าจอมาได้เลยครับ เดี๋ยวทีมช่วยเช็กให้',
      isMe: false,
      type: _MessageType.text,
    ),
  ];

  @override
  void dispose() {
    _playerCompleteSub?.cancel();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _sendText() {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _messages.add(
        _ChatMessage(
          sender: 'kim kundad.',
          text: text,
          isMe: true,
          type: _MessageType.text,
        ),
      );
      _messageCtrl.clear();
    });
  }

  Future<void> _sendImage() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() {
      _messages.add(
        _ChatMessage(
          sender: 'kim kundad.',
          text: image.name,
          isMe: true,
          type: _MessageType.image,
          mediaPath: image.path,
        ),
      );
    });
  }

  Future<void> _toggleRecording() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_isRecording) {
      await _stopRecordingAndSend();
      return;
    }

    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ไม่สามารถใช้ไมโครโฟนได้ กรุณาอนุญาตสิทธิ์ก่อน',
            style: GoogleFonts.sarabun(),
          ),
        ),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    setState(() {
      _isRecording = true;
      _recordStartedAt = DateTime.now();
    });
  }

  Future<void> _stopRecordingAndSend() async {
    final path = await _audioRecorder.stop();
    final startedAt = _recordStartedAt;
    final seconds = startedAt == null
        ? 1
        : DateTime.now().difference(startedAt).inSeconds.clamp(1, 599).toInt();

    setState(() {
      _isRecording = false;
      _recordStartedAt = null;
    });

    if (path == null) return;
    setState(() {
      _messages.add(
        _ChatMessage(
          sender: 'kim kundad.',
          text: 'ข้อความเสียง ${_formatDuration(seconds)}',
          isMe: true,
          type: _MessageType.voice,
          mediaPath: path,
          durationSeconds: seconds,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 30),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Column(
          children: [
            Text(
              'ส่งข้อความถึงเรา',
              style: GoogleFonts.sarabun(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            Text(
              _isRecording ? 'กำลังอัดเสียง แตะปุ่มหยุดเพื่อส่ง' : 'ครูพี่โฮมและทีมช่วยเหลือ',
              style: GoogleFonts.sarabun(
                color: Colors.white.withOpacity(0.78),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
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
              child: ListView.builder(
                reverse: true,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                itemCount: _messages.length,
                itemBuilder: (_, index) {
                  final messageIndex = _messages.length - 1 - index;
                  final message = _messages[messageIndex];
                  return _bubble(message, messageIndex);
                },
              ),
            ),
          ),
          _composer(),
        ],
      ),
    );
  }

  Widget _statusStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: _isRecording ? const Color(0xFFFFF1F2) : const Color(0xFFF2FAF8),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
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
            style: GoogleFonts.sarabun(
              fontSize: 12,
              color: AppTheme.textMedium,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(_ChatMessage message, int messageIndex) {
    final bubbleColor = message.isMe ? AppTheme.primary : const Color(0xFFF0F3F6);
    final textColor = message.isMe ? Colors.white : AppTheme.textDark;

    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(message.isMe ? 18 : 5),
            bottomRight: Radius.circular(message.isMe ? 5 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isMe) ...[
              Text(
                message.sender,
                style: GoogleFonts.sarabun(
                  fontSize: 12,
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
            ],
            _messageContent(message, messageIndex, textColor),
          ],
        ),
      ),
    );
  }

  Widget _messageContent(_ChatMessage message, int messageIndex, Color textColor) {
    if (message.type == _MessageType.image) {
      return GestureDetector(
        onTap: () => _showImagePreview(message),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'chat-image-$messageIndex',
              child: Container(
                width: 190,
                height: 120,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(message.isMe ? 0.22 : 1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: message.isMe
                        ? Colors.white.withOpacity(0.22)
                        : AppTheme.border,
                  ),
                ),
                child: Stack(
                  children: [
                    if (message.mediaPath != null)
                      Positioned.fill(
                        child: Image.file(
                          File(message.mediaPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imageFallback(message),
                        ),
                      )
                    else
                      _imageFallback(message),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.28),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.open_in_full_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.sarabun(
                fontSize: 14,
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    if (message.type == _MessageType.voice) {
      final isPlaying = _playingVoiceIndex == messageIndex;
      return GestureDetector(
        onTap: () => _toggleVoice(messageIndex),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: textColor.withOpacity(isPlaying ? 0.24 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: textColor,
                size: 21,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 118,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: isPlaying ? null : 0.18,
                  minHeight: 5,
                  backgroundColor: textColor.withOpacity(0.24),
                  valueColor: AlwaysStoppedAnimation(textColor.withOpacity(0.78)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isPlaying
                  ? 'กำลังเล่น...'
                  : 'เสียง ${_formatDuration(message.durationSeconds ?? 0)}',
              style: GoogleFonts.sarabun(
                fontSize: 13,
                color: textColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      message.text,
      style: GoogleFonts.sarabun(
        fontSize: 16,
        color: textColor,
        height: 1.4,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _imageFallback(_ChatMessage message) {
    return Center(
      child: Icon(
        Icons.image_rounded,
        color: message.isMe ? Colors.white : AppTheme.primary,
        size: 42,
      ),
    );
  }

  void _showImagePreview(_ChatMessage message) {
    FocusManager.instance.primaryFocus?.unfocus();
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.74),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: 38,
                    height: 38,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                height: 360,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: message.mediaPath == null
                    ? const Icon(
                        Icons.image_rounded,
                        size: 86,
                        color: AppTheme.primary,
                      )
                    : Image.file(
                        File(message.mediaPath!),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image_rounded,
                          size: 86,
                          color: AppTheme.primary,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleVoice(int messageIndex) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final message = _messages[messageIndex];
    final mediaPath = message.mediaPath;

    if (_playingVoiceIndex == messageIndex) {
      await _audioPlayer.stop();
      if (mounted) setState(() => _playingVoiceIndex = null);
      return;
    }

    if (mediaPath == null) return;
    await _audioPlayer.stop();
    await _playerCompleteSub?.cancel();
    _playerCompleteSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => _playingVoiceIndex = null);
    });
    await _audioPlayer.play(DeviceFileSource(mediaPath));
    if (mounted) setState(() => _playingVoiceIndex = messageIndex);
  }

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _iconButton(Icons.image_outlined, _sendImage),
            _iconButton(
              _isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
              _toggleRecording,
              isActive: _isRecording,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _messageCtrl,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendText(),
                enabled: !_isRecording,
                decoration: InputDecoration(
                  hintText: _isRecording ? 'กำลังอัดเสียง...' : 'พิมพ์ข้อความ...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: const Color(0xFFF8F8F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(color: AppTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(color: AppTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isRecording ? null : _sendText,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isRecording ? AppTheme.border : AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 21),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconButton(
    IconData icon,
    VoidCallback onTap, {
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? AppTheme.priceRed : AppTheme.primaryLight,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : AppTheme.primary,
          size: 21,
        ),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

enum _MessageType { text, image, voice }

class _ChatMessage {
  final String sender;
  final String text;
  final bool isMe;
  final _MessageType type;
  final String? mediaPath;
  final int? durationSeconds;

  const _ChatMessage({
    required this.sender,
    required this.text,
    required this.isMe,
    required this.type,
    this.mediaPath,
    this.durationSeconds,
  });
}
