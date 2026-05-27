import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_config.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class ExamV2Screen extends StatefulWidget {
  final int exerciseId;
  final String exerciseTitle;
  final bool saveAttempt;

  const ExamV2Screen({
    super.key,
    required this.exerciseId,
    required this.exerciseTitle,
    this.saveAttempt = false,
  });

  @override
  State<ExamV2Screen> createState() => _ExamV2ScreenState();
}

class _ExamV2ScreenState extends State<ExamV2Screen>
    with SingleTickerProviderStateMixin {
  // ── loading state ──
  bool _loading = true;
  String? _error;

  // ── exam data ──
  Map<String, dynamic> _exercise = {};
  List<_Question> _questions = [];

  // ── exam state ──
  int _current = 0;
  final Map<int, int?> _answers = {}; // questionIndex → optionId
  bool _answered = false;
  int _secondsLeft = 0;
  int _totalSeconds = 0;
  Timer? _timer;
  bool _submitted = false;
  Map<String, dynamic>? _result;
  bool _submitting = false;

  late final AnimationController _shakeController;
  late final Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shake = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn));
    _loadExam();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _loadExam() async {
    try {
      final data = await ApiService.instance.getExamDetail(widget.exerciseId);
      final ex = data['exercise'] as Map<String, dynamic>;
      final rawQs = data['questions'] as List<dynamic>;

      final questions = rawQs.map((q) {
        final opts = (q['options'] as List<dynamic>).map((o) => _Option(
          id: (o['id'] as num).toInt(),
          text: o['option_text'] as String,
        )).toList();
        return _Question(
          id: (q['id'] as num).toInt(),
          text: q['question_text'] as String,
          image: q['question_image'] as String?,
          options: opts,
        );
      }).toList();

      final timeLimitMin = (ex['time_limit'] as num?)?.toInt() ?? 0;
      final secs = timeLimitMin > 0 ? timeLimitMin * 60 : questions.length * 60;

      setState(() {
        _exercise = ex;
        _questions = questions;
        _secondsLeft = secs;
        _totalSeconds = secs;
        _loading = false;
      });
      _startTimer();
    } catch (e) {
      setState(() {
        _error = 'โหลดข้อสอบไม่สำเร็จ';
        _loading = false;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        if (!_submitted) _autoSubmit();
      }
    });
  }

  void _autoSubmit() {
    _timer?.cancel();
    _doSubmit();
  }

  void _selectOption(int optionId) {
    if (_answered) return;
    setState(() {
      _answers[_current] = optionId;
      _answered = true;
    });
  }

  void _nextQuestion() {
    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
        _answered = _answers.containsKey(_current);
      });
    } else {
      _doSubmit();
    }
  }

  void _prevQuestion() {
    if (_current > 0) {
      setState(() {
        _current--;
        _answered = _answers.containsKey(_current);
      });
    }
  }

  Future<void> _doSubmit() async {
    if (_submitted) return;
    _timer?.cancel();
    setState(() => _submitting = true);

    final timeTaken = _totalSeconds - _secondsLeft;

    if (widget.saveAttempt) {
      try {
        final answerList = _questions.asMap().entries.map((e) => {
          'question_id': e.value.id,
          'option_id': _answers[e.key],
        }).toList();

        final result = await ApiService.instance.submitExam(
          widget.exerciseId,
          answerList,
          timeTaken,
        );
        setState(() {
          _result = result;
          _submitted = true;
          _submitting = false;
        });
      } catch (e) {
        setState(() => _submitting = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ส่งคำตอบไม่สำเร็จ กรุณาลองใหม่')),
        );
      }
    } else {
      // Guest mode — calculate locally
      int earned = 0;
      for (int i = 0; i < _questions.length; i++) {
        // We don't know correct answer client-side (not sent from API)
        // mark all as unevaluated — show score 0 with note
      }
      setState(() {
        _result = {
          'success': true,
          'score': earned,
          'total_score': _questions.length,
          'percentage': 0.0,
          'passed': false,
          'pass_score': _exercise['pass_score'] ?? 70,
          'guest_mode': true,
        };
        _submitted = true;
        _submitting = false;
      });
    }
  }

  // ── timer helpers ──────────────────────────────────────────────────────────

  String get _timerText {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_secondsLeft > _totalSeconds * 0.5) return AppTheme.primary;
    if (_secondsLeft > _totalSeconds * 0.25) return const Color(0xFFFF9800);
    return AppTheme.priceRed;
  }

  double get _progress => _questions.isEmpty ? 0 : (_current + 1) / _questions.length;

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F8FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Text(widget.exerciseTitle,
              style: GoogleFonts.notoSansThai(fontSize: 15, fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F8FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.priceRed),
              const SizedBox(height: 12),
              Text(_error!, style: GoogleFonts.notoSansThai(fontSize: 16, color: AppTheme.textDark)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () { setState(() { _loading = true; _error = null; }); _loadExam(); },
                  child: Text('ลองใหม่', style: GoogleFonts.notoSansThai())),
            ],
          ),
        ),
      );
    }

    if (_submitted && _result != null) {
      return _buildResultScreen();
    }

    final q = _questions[_current];
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildProgressSection(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNavigationDots(),
                  const SizedBox(height: 20),
                  _buildQuestionCard(q),
                  const SizedBox(height: 16),
                  ...q.options.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildOptionCard(e.key, e.value, q),
                  )),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    final answeredCount = _answers.length;
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('ออกจากแบบทดสอบ?',
                  style: GoogleFonts.notoSansThai(fontWeight: FontWeight.w900, fontSize: 16)),
              content: Text('ความคืบหน้าจะหายไป',
                  style: GoogleFonts.notoSansThai(fontSize: 14, color: AppTheme.textMedium)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context),
                    child: Text('ยกเลิก', style: GoogleFonts.notoSansThai(color: AppTheme.textMedium))),
                TextButton(onPressed: () { Navigator.pop(context); context.pop(); },
                    child: Text('ออก', style: GoogleFonts.notoSansThai(color: AppTheme.priceRed, fontWeight: FontWeight.w800))),
              ],
            ),
          );
        },
      ),
      title: Text(widget.exerciseTitle,
          style: GoogleFonts.notoSansThai(fontSize: 15, fontWeight: FontWeight.w800),
          overflow: TextOverflow.ellipsis),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 14),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.edit_note_rounded, size: 14, color: AppTheme.primary),
              const SizedBox(width: 4),
              Text('$answeredCount/${_questions.length}',
                  style: GoogleFonts.notoSansThai(
                      fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppTheme.border, height: 1),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: _timerColor, width: 2),
                  borderRadius: BorderRadius.circular(30),
                  color: _timerColor.withOpacity(0.05),
                ),
                child: Text(
                  _timerText,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 28, fontWeight: FontWeight.w900,
                    color: _timerColor, letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('${(_progress * 100).round()}% Complete',
                  style: GoogleFonts.notoSansThai(
                      fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${_current + 1} of ${_questions.length}',
                  style: GoogleFonts.notoSansThai(
                      fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              backgroundColor: AppTheme.border.withOpacity(0.5),
              valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationDots() {
    return Row(
      children: [
        _navArrow(Icons.chevron_left_rounded, _current > 0, _prevQuestion),
        const SizedBox(width: 4),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_questions.length, (i) {
                final isCurrent = i == _current;
                final isAnswered = _answers.containsKey(i);
                return GestureDetector(
                  onTap: () => setState(() {
                    _current = i;
                    _answered = _answers.containsKey(i);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: isCurrent ? 36 : 32,
                    height: isCurrent ? 36 : 32,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppTheme.priceRed
                          : isAnswered
                              ? AppTheme.primary.withOpacity(0.15)
                              : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrent
                            ? AppTheme.priceRed
                            : isAnswered
                                ? AppTheme.primary
                                : AppTheme.border,
                        width: isCurrent ? 0 : 1.5,
                      ),
                      boxShadow: isCurrent
                          ? [BoxShadow(
                              color: AppTheme.priceRed.withOpacity(0.3),
                              blurRadius: 8, offset: const Offset(0, 3))]
                          : [],
                    ),
                    child: Center(
                      child: Text('${i + 1}',
                          style: GoogleFonts.notoSansThai(
                              fontSize: 13, fontWeight: FontWeight.w800,
                              color: isCurrent
                                  ? Colors.white
                                  : isAnswered
                                      ? AppTheme.primary
                                      : AppTheme.textMedium)),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 4),
        _navArrow(Icons.chevron_right_rounded,
            _current < _questions.length - 1, _nextQuestion),
      ],
    );
  }

  Widget _navArrow(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? AppTheme.border : AppTheme.border.withOpacity(0.3)),
        ),
        child: Icon(icon, size: 20,
            color: enabled ? AppTheme.textMedium : AppTheme.border),
      ),
    );
  }

  Widget _buildQuestionCard(_Question q) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05), blurRadius: 10,
            offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q.text,
              style: GoogleFonts.notoSansThai(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppTheme.textDark, height: 1.6)),
          if (q.image != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                '${_imageBaseUrl()}${q.image}',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _imageBaseUrl() {
    return '${AppConfig.mainUrl}/uploads/exercise_v2/';
  }

  Widget _buildOptionCard(int index, _Option opt, _Question q) {
    final selectedOptId = _answers[_current];
    final isSelected = selectedOptId == opt.id;

    Color bgColor = Colors.white;
    Color borderColor = AppTheme.border;
    Color textColor = AppTheme.textDark;
    Color numBg = const Color(0xFFF0F2F5);
    Color numColor = AppTheme.textMedium;

    if (isSelected) {
      bgColor = AppTheme.primaryLight;
      borderColor = AppTheme.primary;
      numBg = AppTheme.primary;
      numColor = Colors.white;
    }

    return GestureDetector(
      onTap: () => _selectOption(opt.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8,
              offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 32, height: 32,
              decoration: BoxDecoration(color: numBg, borderRadius: BorderRadius.circular(9)),
              child: Center(
                child: Text('${index + 1}',
                    style: GoogleFonts.notoSansThai(
                        fontSize: 14, fontWeight: FontWeight.w800, color: numColor)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(opt.text,
                  style: GoogleFonts.notoSansThai(
                      fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final allAnswered = _answers.length == _questions.length;
    final isLast = _current == _questions.length - 1;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border.withOpacity(0.6))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _current > 0 ? _prevQuestion : null,
              icon: const Icon(Icons.chevron_left_rounded, size: 18),
              label: Text('ย้อนกลับ',
                  style: GoogleFonts.notoSansThai(fontSize: 14, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textMedium,
                side: const BorderSide(color: AppTheme.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _submitting
                ? ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                : ElevatedButton.icon(
                    onPressed: isLast
                        ? (allAnswered
                            ? _doSubmit
                            : _doSubmit) // allow submit even if not all answered
                        : (_answers.containsKey(_current) ? _nextQuestion : _nextQuestion),
                    icon: Icon(
                      isLast ? Icons.emoji_events_rounded : Icons.chevron_right_rounded,
                      size: 18),
                    label: Text(
                      isLast ? 'ส่งคำตอบ' : 'ข้อต่อไป',
                      style: GoogleFonts.notoSansThai(fontSize: 14, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Result Screen ──────────────────────────────────────────────────────────

  Widget _buildResultScreen() {
    final r = _result!;
    final isGuest = r['guest_mode'] == true;
    final score = (r['score'] as num?)?.toInt() ?? 0;
    final total = (r['total_score'] as num?)?.toInt() ?? _questions.length;
    final pct = (r['percentage'] as num?)?.toDouble() ?? 0.0;
    final passed = r['passed'] == true;
    final passScore = (r['pass_score'] as num?)?.toDouble() ?? 70.0;
    final attemptNo = (r['attempt_no'] as num?)?.toInt() ?? 1;
    final color = passed ? AppTheme.primary : AppTheme.priceRed;
    final review = r['review'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('ผลการทำแบบทดสอบ',
            style: GoogleFonts.notoSansThai(fontSize: 16, fontWeight: FontWeight.w900)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Score card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Column(
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(
                      passed ? Icons.emoji_events_rounded : Icons.refresh_rounded,
                      size: 48, color: color),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    passed ? 'ยอดเยี่ยม! ผ่านแล้ว' : 'ยังไม่ผ่าน ลองใหม่ได้เลย',
                    style: GoogleFonts.notoSansThai(
                        fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textDark)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24)),
                    child: Text('${pct.toStringAsFixed(1)}%',
                        style: GoogleFonts.notoSansThai(
                            fontSize: 32, color: color, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 12),
                  if (!isGuest) ...[
                    Text('$score / $total คะแนน',
                        style: GoogleFonts.notoSansThai(
                            fontSize: 16, color: AppTheme.textMedium, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('เกณฑ์ผ่าน $passScore%  |  รอบที่ $attemptNo',
                        style: GoogleFonts.notoSansThai(
                            fontSize: 13, color: AppTheme.textLight, fontWeight: FontWeight.w600)),
                  ] else ...[
                    Text('$score / $total คะแนน',
                        style: GoogleFonts.notoSansThai(
                            fontSize: 16, color: AppTheme.textMedium, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFCC02))),
                      child: Text('ทดลองทำ — ไม่บันทึกคะแนน',
                          style: GoogleFonts.notoSansThai(
                              fontSize: 12, color: const Color(0xFF5D4037), fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Review (only when saved)
            if (!isGuest && review.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10, offset: const Offset(0, 3))]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('เฉลยคำตอบ',
                        style: GoogleFonts.notoSansThai(
                            fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.textDark)),
                    const SizedBox(height: 12),
                    ...review.asMap().entries.map((e) {
                      final rv = e.value as Map<String, dynamic>;
                      final correct = rv['is_correct'] == true;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: correct
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: correct ? AppTheme.primary : AppTheme.priceRed,
                            width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                  size: 16,
                                  color: correct ? AppTheme.primary : AppTheme.priceRed),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text('ข้อ ${e.key + 1}: ${rv['question_text']}',
                                      style: GoogleFonts.notoSansThai(
                                          fontSize: 13, fontWeight: FontWeight.w700,
                                          color: AppTheme.textDark)),
                                ),
                              ],
                            ),
                            if (rv['selected_option'] != null) ...[
                              const SizedBox(height: 4),
                              Text('คำตอบของคุณ: ${rv['selected_option']}',
                                  style: GoogleFonts.notoSansThai(
                                      fontSize: 12, color: AppTheme.textMedium)),
                            ],
                            if (!correct && rv['correct_option'] != null) ...[
                              const SizedBox(height: 2),
                              Text('เฉลย: ${rv['correct_option']}',
                                  style: GoogleFonts.notoSansThai(
                                      fontSize: 12, color: AppTheme.primary,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _answers.clear();
                        _current = 0;
                        _answered = false;
                        _submitted = false;
                        _result = null;
                        _secondsLeft = _totalSeconds;
                      });
                      _startTimer();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text('ทำใหม่',
                        style: GoogleFonts.notoSansThai(fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text('เสร็จสิ้น',
                        style: GoogleFonts.notoSansThai(fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Data Classes ──────────────────────────────────────────────────────────────

class _Question {
  final int id;
  final String text;
  final String? image;
  final List<_Option> options;
  const _Question({required this.id, required this.text, this.image, required this.options});
}

class _Option {
  final int id;
  final String text;
  const _Option({required this.id, required this.text});
}
