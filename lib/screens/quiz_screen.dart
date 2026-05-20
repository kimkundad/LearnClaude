import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class QuizScreen extends StatefulWidget {
  final String quizTitle;
  const QuizScreen({
    super.key,
    this.quizTitle = 'แบบฝึกหัด บทที่ 7 あげます・くれます',
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  int _current = 0;
  int? _selected;
  bool _answered = false;
  int _secondsLeft = 30;
  Timer? _timer;
  int _score = 0;
  late final AnimationController _shakeController;
  late final Animation<double> _shake;

  static const _questions = [
    _Question(
      text: 'ข้อที่ 1.\nประโยค "私は友達に本をあげます" มีความหมายว่าอะไร?',
      choices: [
        'ฉันให้หนังสือแก่เพื่อน',
        'เพื่อนให้หนังสือแก่ฉัน',
        'ฉันรับหนังสือจากเพื่อน',
        'ฉันซื้อหนังสือให้เพื่อน',
      ],
      correct: 0,
    ),
    _Question(
      text: 'ข้อที่ 2.\nลักษณนามของ "หนังสือ" ในภาษาญี่ปุ่นคืออะไร?',
      choices: [
        'เล่ม (さつ)',
        'อัน (ほん)',
        'ตัว (ひき)',
        'คัน (だい)',
      ],
      correct: 0,
    ),
    _Question(
      text: 'ข้อที่ 3.\nกริยาใดต่อไปนี้เป็นกริยากลุ่ม 2?',
      choices: [
        'たべます (กิน)',
        'かきます (เขียน)',
        'のみます (ดื่ม)',
        'いきます (ไป)',
      ],
      correct: 0,
    ),
    _Question(
      text: 'ข้อที่ 4.\n"くれます" ใช้ในสถานการณ์ใด?',
      choices: [
        'คนอื่นให้สิ่งของแก่ฉัน/คนใกล้ชิด',
        'ฉันให้สิ่งของแก่คนอื่น',
        'ฉันรับสิ่งของจากคนอื่น',
        'คนอื่นรับสิ่งของจากฉัน',
      ],
      correct: 0,
    ),
    _Question(
      text: 'ข้อที่ 5.\nรูป て-form ของ "かきます" คืออะไร?',
      choices: [
        'かいて',
        'かいた',
        'かきて',
        'かって',
      ],
      correct: 0,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shake = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        if (!_answered) _timeOut();
      }
    });
  }

  void _timeOut() {
    setState(() {
      _answered = true;
      _selected = null;
    });
    _shakeController.forward(from: 0);
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    _timer?.cancel();
    setState(() {
      _selected = index;
      _answered = true;
      if (index == _questions[_current].correct) _score++;
    });
  }

  void _nextQuestion() {
    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
        _selected = null;
        _answered = false;
      });
      _startTimer();
    } else {
      _showResult();
    }
  }

  void _prevQuestion() {
    if (_current > 0) {
      setState(() {
        _current--;
        _selected = null;
        _answered = false;
      });
      _startTimer();
    }
  }

  void _showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        score: _score,
        total: _questions.length,
        onRetry: () {
          Navigator.pop(context);
          setState(() {
            _current = 0;
            _selected = null;
            _answered = false;
            _score = 0;
          });
          _startTimer();
        },
        onExit: () {
          Navigator.pop(context);
          context.pop();
        },
      ),
    );
  }

  double get _progress => (_current + 1) / _questions.length;

  bool get _isLastQuestion => _current == _questions.length - 1;

  Color get _timerColor {
    if (_secondsLeft > 15) return AppTheme.primary;
    if (_secondsLeft > 8) return const Color(0xFFFF9800);
    return AppTheme.priceRed;
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_current];
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.quizTitle,
          style: GoogleFonts.notoSansThai(fontSize: 15, fontWeight: FontWeight.w800),
          overflow: TextOverflow.ellipsis,
        ),
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
                const Icon(Icons.emoji_events_rounded,
                    size: 14, color: AppTheme.primary),
                const SizedBox(width: 4),
                Text('$_score/${_questions.length}',
                    style: GoogleFonts.notoSansThai(
                        fontSize: 13, color: AppTheme.primary,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.border, height: 1),
        ),
      ),
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
                  ...List.generate(q.choices.length, (i) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildChoiceCard(i, q),
                      )),
                  if (_answered && _selected == null) ...[
                    const SizedBox(height: 4),
                    _buildTimeOutBanner(q.correct),
                  ],
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

  Widget _buildProgressSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _shakeController,
                builder: (_, __) => Transform.translate(
                  offset: Offset(
                    _answered && _selected == null
                        ? 4 * (1 - _shakeController.value) *
                            ((_current % 2 == 0) ? 1 : -1)
                        : 0,
                    0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: _timerColor, width: 2),
                      borderRadius: BorderRadius.circular(30),
                      color: _timerColor.withOpacity(0.05),
                    ),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: GoogleFonts.notoSansThai(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: _timerColor,
                        letterSpacing: 2,
                      ),
                      child: Text(
                        '${(_secondsLeft ~/ 60).toString().padLeft(2, '0')}:${(_secondsLeft % 60).toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${(_progress * 100).round()}% Complete',
                style: GoogleFonts.notoSansThai(
                  fontSize: 12,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${_current + 1} of ${_questions.length}',
                style: GoogleFonts.notoSansThai(
                  fontSize: 12,
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _navArrow(Icons.chevron_left_rounded, _current > 0, _prevQuestion),
        const SizedBox(width: 8),
        ...List.generate(_questions.length, (i) {
          final isCurrent = i == _current;
          return GestureDetector(
            onTap: () {
              if (i != _current) {
                setState(() {
                  _current = i;
                  _selected = null;
                  _answered = false;
                });
                _startTimer();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: isCurrent ? 36 : 34,
              height: isCurrent ? 36 : 34,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isCurrent ? AppTheme.priceRed : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrent ? AppTheme.priceRed : AppTheme.border,
                  width: isCurrent ? 0 : 1.5,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: AppTheme.priceRed.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isCurrent ? Colors.white : AppTheme.textMedium,
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        _navArrow(Icons.chevron_right_rounded,
            _current < _questions.length - 1, _nextQuestion),
      ],
    );
  }

  Widget _navArrow(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? AppTheme.border : AppTheme.border.withOpacity(0.3),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppTheme.textMedium : AppTheme.border,
        ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        q.text,
        style: GoogleFonts.notoSansThai(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.textDark,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildChoiceCard(int index, _Question q) {
    final isSelected = _selected == index;
    final isCorrect = index == q.correct;

    Color bgColor = Colors.white;
    Color borderColor = AppTheme.border;
    Color textColor = AppTheme.textDark;
    Color numBg = const Color(0xFFF0F2F5);
    Color numColor = AppTheme.textMedium;
    Widget? trailing;

    if (_answered) {
      if (isCorrect) {
        bgColor = const Color(0xFFE8F5E9);
        borderColor = AppTheme.primary;
        textColor = const Color(0xFF1B5E20);
        numBg = AppTheme.primary;
        numColor = Colors.white;
        trailing = const Icon(Icons.check_circle_rounded,
            color: AppTheme.primary, size: 20);
      } else if (isSelected) {
        bgColor = const Color(0xFFFFEBEE);
        borderColor = AppTheme.priceRed;
        textColor = AppTheme.priceRed;
        numBg = AppTheme.priceRed;
        numColor = Colors.white;
        trailing = const Icon(Icons.cancel_rounded,
            color: AppTheme.priceRed, size: 20);
      }
    } else if (isSelected) {
      bgColor = AppTheme.primaryLight;
      borderColor = AppTheme.primary;
      numBg = AppTheme.primary;
      numColor = Colors.white;
    }

    return GestureDetector(
      onTap: () => _selectAnswer(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: _answered && isCorrect ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: numBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: numColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                q.choices[index],
                style: GoogleFonts.notoSansThai(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeOutBanner(int correctIndex) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCC02)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_off_rounded,
              color: Color(0xFFE65100), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'หมดเวลา! เฉลยคือตัวเลือกที่ ${correctIndex + 1}',
              style: GoogleFonts.notoSansThai(
                fontSize: 13,
                color: const Color(0xFF5D4037),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
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
              label: Text('ข้อก่อนหน้า',
                  style: GoogleFonts.notoSansThai(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textMedium,
                side: const BorderSide(color: AppTheme.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _answered ? (_isLastQuestion ? _showResult : _nextQuestion) : null,
              icon: Icon(
                _isLastQuestion
                    ? Icons.emoji_events_rounded
                    : Icons.chevron_right_rounded,
                size: 18,
              ),
              label: Text(
                _isLastQuestion ? 'ดูผลลัพธ์' : 'ข้อต่อไป',
                style: GoogleFonts.notoSansThai(
                    fontSize: 14, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Result Dialog ────────────────────────────────────────────────────────────

class _ResultDialog extends StatelessWidget {
  final int score;
  final int total;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  const _ResultDialog({
    required this.score,
    required this.total,
    required this.onRetry,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (score / total * 100).round();
    final passed = pct >= 60;
    final color = passed ? AppTheme.primary : AppTheme.priceRed;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                passed ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
                size: 44,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              passed ? 'ยอดเยี่ยม!' : 'ลองอีกครั้งนะ!',
              style: GoogleFonts.notoSansThai(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.notoSansThai(
                    fontSize: 15, color: AppTheme.textMedium,
                    fontWeight: FontWeight.w600),
                children: [
                  const TextSpan(text: 'คุณตอบถูก '),
                  TextSpan(
                    text: '$score/$total ข้อ',
                    style: GoogleFonts.notoSansThai(
                        fontSize: 18, color: color,
                        fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$pct%',
                style: GoogleFonts.notoSansThai(
                    fontSize: 24, color: color, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text('ทำใหม่',
                        style: GoogleFonts.notoSansThai(fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onExit,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text('เสร็จสิ้น',
                        style: GoogleFonts.notoSansThai(fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data Classes ─────────────────────────────────────────────────────────────

class _Question {
  final String text;
  final List<String> choices;
  final int correct;
  const _Question(
      {required this.text, required this.choices, required this.correct});
}
