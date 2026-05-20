import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../services/api_service.dart';

class ExamV2ListScreen extends StatefulWidget {
  final int courseId;
  final String courseTitle;

  const ExamV2ListScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<ExamV2ListScreen> createState() => _ExamV2ListScreenState();
}

class _ExamV2ListScreenState extends State<ExamV2ListScreen> {
  bool _loading = true;
  List<dynamic> _exercises = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ApiService.instance.getExamList(widget.courseId);
      if (mounted) setState(() { _exercises = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('แบบทดสอบ',
                style: GoogleFonts.notoSansThai(fontSize: 16, fontWeight: FontWeight.w900,
                    color: AppTheme.textDark)),
            Text(widget.courseTitle,
                style: GoogleFonts.notoSansThai(fontSize: 11, color: AppTheme.textLight,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.border, height: 1),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _exercises.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 14),
                      ..._exercises.map((ex) =>
                          _ExerciseCard(
                            ex: ex as Map<String, dynamic>,
                            onRefresh: _load,
                          )),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF32D191), Color(0xFF0A8C80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.assignment_turned_in_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('แบบทดสอบทั้งหมด',
                    style: GoogleFonts.notoSansThai(
                        fontSize: 15, color: Colors.white, fontWeight: FontWeight.w800)),
                Text('${_exercises.length} ชุด · บันทึกคะแนนทุกครั้ง',
                    style: GoogleFonts.notoSansThai(
                        fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment_outlined, size: 64, color: AppTheme.border),
          const SizedBox(height: 12),
          Text('ยังไม่มีแบบทดสอบ',
              style: GoogleFonts.notoSansThai(
                  fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
          const SizedBox(height: 6),
          Text('แบบทดสอบจะแสดงเมื่อผู้สอนเพิ่มเข้ามา',
              style: GoogleFonts.notoSansThai(fontSize: 13, color: AppTheme.textLight)),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatefulWidget {
  final Map<String, dynamic> ex;
  final VoidCallback? onRefresh;
  const _ExerciseCard({required this.ex, this.onRefresh});

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  bool _showHistory = false;
  bool _historyLoading = false;
  List<dynamic> _attempts = [];
  double? _bestScore;

  Map<String, dynamic> get ex => widget.ex;

  int get id => (ex['id'] as num).toInt();
  String get title => ex['title'] as String? ?? 'แบบทดสอบ';
  int get qCount => (ex['question_count'] as num?)?.toInt() ?? 0;
  double get passScore => (ex['pass_score'] as num?)?.toDouble() ?? 70.0;
  int? get timeLimit => (ex['time_limit'] as num?)?.toInt();
  double? get bestScore => ex['best_score'] != null
      ? double.tryParse(ex['best_score'].toString())
      : null;
  int get attemptCount => (ex['attempt_count'] as num?)?.toInt() ?? 0;

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    try {
      final data = await ApiService.instance.getExamHistory(id);

      final attempts = data['attempts'] as List<dynamic>? ?? [];
      final best = data['best_score'] != null
          ? double.tryParse(data['best_score'].toString())
          : null;
      if (mounted) {
        setState(() {
          _attempts = attempts;
          _bestScore = best;
          _historyLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  void _toggleHistory() {
    if (!_showHistory) {
      _loadHistory();
    }
    setState(() => _showHistory = !_showHistory);
  }

  @override
  Widget build(BuildContext context) {
    final hasBest = bestScore != null;
    final passed = hasBest && bestScore! >= passScore;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Main card
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF32D191).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.assignment_turned_in_rounded,
                          color: Color(0xFF32D191), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: GoogleFonts.notoSansThai(
                                  fontSize: 14, fontWeight: FontWeight.w800,
                                  color: AppTheme.textDark)),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.help_outline_rounded,
                                  size: 13, color: AppTheme.textLight),
                              const SizedBox(width: 3),
                              Text('$qCount ข้อ',
                                  style: GoogleFonts.notoSansThai(
                                      fontSize: 12, color: AppTheme.textLight,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              const Icon(Icons.flag_outlined,
                                  size: 13, color: AppTheme.textLight),
                              const SizedBox(width: 3),
                              Text('ผ่าน $passScore%',
                                  style: GoogleFonts.notoSansThai(
                                      fontSize: 12, color: AppTheme.textLight,
                                      fontWeight: FontWeight.w600)),
                              if (timeLimit != null) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.timer_outlined,
                                    size: 13, color: AppTheme.textLight),
                                const SizedBox(width: 2),
                                Text('$timeLimit น.',
                                    style: GoogleFonts.notoSansThai(
                                        fontSize: 12, color: AppTheme.textLight,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Best score badge (if has attempts)
                if (hasBest) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: passed
                              ? AppTheme.primary.withOpacity(0.1)
                              : AppTheme.priceRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              passed ? Icons.emoji_events_rounded : Icons.refresh_rounded,
                              size: 14,
                              color: passed ? AppTheme.primary : AppTheme.priceRed),
                            const SizedBox(width: 4),
                            Text(
                              'คะแนนสูงสุด ${bestScore!.toStringAsFixed(1)}%',
                              style: GoogleFonts.notoSansThai(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: passed ? AppTheme.primary : AppTheme.priceRed)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('$attemptCount ครั้ง',
                          style: GoogleFonts.notoSansThai(
                              fontSize: 12, color: AppTheme.textLight,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await context.push('/exam-v2', extra: {
                            'exerciseId':    id,
                            'exerciseTitle': title,
                            'saveAttempt':   true,
                          });
                          widget.onRefresh?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF32D191),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: Text(
                          hasBest ? 'ทำอีกครั้ง' : 'เริ่มทำ',
                          style: GoogleFonts.notoSansThai(fontWeight: FontWeight.w800)),
                      ),
                    ),
                    if (attemptCount > 0) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _toggleHistory,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textMedium,
                          side: const BorderSide(color: AppTheme.border),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(
                          _showHistory
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.history_rounded,
                          size: 18),
                        label: Text('ประวัติ',
                            style: GoogleFonts.notoSansThai(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // History panel
          if (_showHistory) ...[
            Container(height: 1, color: AppTheme.border.withOpacity(0.5)),
            _buildHistoryPanel(),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryPanel() {
    if (_historyLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_attempts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('ยังไม่มีประวัติ',
            style: GoogleFonts.notoSansThai(fontSize: 13, color: AppTheme.textLight)),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ประวัติการทำแบบทดสอบ',
              style: GoogleFonts.notoSansThai(
                  fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          ..._attempts.map((a) => _attemptRow(a as Map<String, dynamic>)),
        ],
      ),
    );
  }

  Widget _attemptRow(Map<String, dynamic> a) {
    final pct = double.tryParse(a['percentage']?.toString() ?? '0') ?? 0.0;
    final passed = a['passed'] == 1 || a['passed'] == true;
    final attemptNo = (a['attempt_no'] as num?)?.toInt() ?? 1;
    final score = (a['score'] as num?)?.toInt() ?? 0;
    final total = (a['total_score'] as num?)?.toInt() ?? 0;
    final timeTaken = (a['time_taken'] as num?)?.toInt() ?? 0;
    final createdAt = a['created_at'] as String? ?? '';
    final color = passed ? AppTheme.primary : AppTheme.priceRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Center(
              child: Text('$attemptNo',
                  style: GoogleFonts.notoSansThai(
                      fontSize: 13, fontWeight: FontWeight.w900, color: color)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('$score/$total คะแนน',
                        style: GoogleFonts.notoSansThai(
                            fontSize: 13, fontWeight: FontWeight.w800,
                            color: AppTheme.textDark)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(passed ? 'ผ่าน' : 'ไม่ผ่าน',
                          style: GoogleFonts.notoSansThai(
                              fontSize: 11, color: color, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${pct.toStringAsFixed(1)}%  ·  ${_fmtTime(timeTaken)}  ·  ${_fmtDate(createdAt)}',
                  style: GoogleFonts.notoSansThai(
                      fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return m > 0 ? '${m}น. ${s}ว.' : '${s}ว.';
  }

  String _fmtDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day}/${dt.month}/${dt.year + 543}';
    } catch (_) {
      return raw;
    }
  }
}
