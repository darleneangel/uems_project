import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_service.dart';

class TeacherOverviewPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const TeacherOverviewPanel({
    super.key,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  State<TeacherOverviewPanel> createState() => _TeacherOverviewPanelState();
}

class _TeacherOverviewPanelState extends State<TeacherOverviewPanel> {
  final SupabaseService _service = SupabaseService();

  bool _isLoading = true;
  int _totalStudents = 0;
  int _activeClasses = 0;
  int _pendingGrades = 0;
  List<double> _gradeDistroValues = [0, 0, 0, 0, 0];
  double _completionRate = 0.0;

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);
  static const Color success = Color(0xFF69F0AE);

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  /// 🛰️ DATABASE: Aggregate institutional metrics for the faculty overview
  Future<void> _loadAnalytics() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final String profId = widget.userData['id'];

    try {
      // 1. Fetch all enrollment loads associated with this teacher
      // This includes the joined 'grades' to check for encoding completion.
      // We filter out rows where student_id is null (which are master schedule placeholders).
      final response = await _service.client
          .from('study_loads')
          .select(
              'id, student_id, subject_id, grades(final_numeric_grade, status)')
          .eq('professor_id', profId)
          .filter('student_id', 'not.is', null);

      final List<dynamic> data = response as List;

      // 🛡️ UNIQUE IDENTITY SETS: Resolves redundant data issues for analytics
      final Set<String> uniqueStudentHeadcount = {};
      final Set<String> uniqueSubjectCatalog = {};

      // Tracking unique (student + subject) slots to handle redundant enrollments
      final Set<String> processedEnrollmentSlots = {};

      int pending = 0;
      Map<String, int> distroMap = {
        "1.00": 0,
        "1.25": 0,
        "1.50": 0,
        "1.75": 0,
        "2.00+": 0
      };

      for (var row in data) {
        final String? studentId = row['student_id']?.toString();
        final String? subjectId = row['subject_id']?.toString();

        if (studentId != null && subjectId != null) {
          final String slotKey = "${studentId}_$subjectId";

          // If we've already processed this specific student for this subject, skip it
          if (processedEnrollmentSlots.contains(slotKey)) continue;
          processedEnrollmentSlots.add(slotKey);

          uniqueStudentHeadcount.add(studentId);
          uniqueSubjectCatalog.add(subjectId);

          // Check joined grades record safely handling Map vs List variations
          final dynamic gradeData = row['grades'];
          Map<String, dynamic>? activeGradeMap;

          if (gradeData is List && gradeData.isNotEmpty) {
            activeGradeMap = Map<String, dynamic>.from(gradeData.first);
          } else if (gradeData is Map) {
            activeGradeMap = Map<String, dynamic>.from(gradeData);
          }

          if (activeGradeMap == null) {
            pending++;
          } else {
            final double g = double.tryParse(
                    activeGradeMap['final_numeric_grade']?.toString() ??
                        "0.0") ??
                0.0;
            final String status =
                (activeGradeMap['status'] ?? '').toString().toUpperCase();

            // If the GWA is uncalculated or status is not 'Encoded'/'Submitted', treat as pending
            if (g == 0.0 || status == 'DRAFT' || status.isEmpty) {
              pending++;
            } else {
              // Map into the GWA visualization distro
              String key = g <= 1.0
                  ? "1.00"
                  : g <= 1.25
                      ? "1.25"
                      : g <= 1.5
                          ? "1.50"
                          : g <= 1.75
                              ? "1.75"
                              : "2.00+";
              distroMap[key] = (distroMap[key] ?? 0) + 1;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _totalStudents = uniqueStudentHeadcount.length;
          _activeClasses = uniqueSubjectCatalog.length;
          _pendingGrades = pending;

          // Completion Rate logic based on unique slots
          _completionRate = processedEnrollmentSlots.isEmpty
              ? 0.0
              : (processedEnrollmentSlots.length - pending) /
                  processedEnrollmentSlots.length;

          // Normalize distribution for the bar chart
          int maxCount = distroMap.values
              .fold(0, (prev, element) => element > prev ? element : prev);
          if (maxCount == 0) maxCount = 1;
          _gradeDistroValues =
              distroMap.values.map((v) => v / maxCount).toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Faculty Analytics Sync Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode ? Colors.white : pViolet;
    final Color bgColor = widget.isDarkMode ? surfaceDark : Colors.white;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: aViolet));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 32),
          Row(
            children: [
              _statCard("Unique Students", _totalStudents.toString(),
                  Icons.people_alt_rounded, aViolet, bgColor, textColor),
              _statCard("Active Subjects", _activeClasses.toString(),
                  Icons.menu_book_rounded, Colors.blue, bgColor, textColor),
              _statCard(
                  "Pending Encoding",
                  _pendingGrades.toString(),
                  Icons.hourglass_empty_rounded,
                  Colors.orangeAccent,
                  bgColor,
                  textColor),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  flex: 6,
                  child: _chart(
                      "Performance Distribution",
                      "Headcount per GWA grading scale bracket",
                      _buildBarChart(),
                      bgColor,
                      textColor)),
              const SizedBox(width: 24),
              Expanded(
                  flex: 4,
                  child: _chart(
                      "Encoding Completion",
                      "Institutional grade sheet progress",
                      _buildProgressDonut(textColor),
                      bgColor,
                      textColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Faculty Insight Dashboard",
              style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: t,
                  letterSpacing: -1)),
          const Text(
              "Real-time synchronization with the Grade Ledger and Student Roster.",
              style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
        ],
      );

  Widget _statCard(
          String l, String v, IconData i, Color c, Color bg, Color t) =>
      Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: widget.isDarkMode
                    ? Colors.white10
                    : Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(i, color: c, size: 24),
              const SizedBox(height: 15),
              Text(v,
                  style: GoogleFonts.inter(
                      fontSize: 28, fontWeight: FontWeight.w900, color: t)),
              Text(l.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
            ],
          ),
        ),
      );

  Widget _chart(String t, String s, Widget c, Color bg, Color tx,
          {double h = 220}) =>
      Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color: widget.isDarkMode
                  ? Colors.white10
                  : Colors.black.withOpacity(0.05)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.toUpperCase(),
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  color: tx,
                  fontSize: 12,
                  letterSpacing: 1)),
          Text(s, style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
          const SizedBox(height: 32),
          SizedBox(height: h, child: c),
        ]),
      );

  Widget _buildBarChart() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_gradeDistroValues.length, (i) {
          final double val = _gradeDistroValues[i];
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 40,
                height: (160 * val).clamp(4.0, 160.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [aViolet, aViolet.withOpacity(0.4)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              Text(["1.0", "1.2", "1.5", "1.7", "2.0+"][i],
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey)),
            ],
          );
        }),
      );

  Widget _buildProgressDonut(Color t) => Center(
        child: Stack(alignment: Alignment.center, children: [
          RepaintBoundary(
            // PERFORMANCE OPTIMIZATION: Prevents parent paint loops from invalidating this custom canvas
            child: SizedBox(
              width: 150,
              height: 150,
              child: CustomPaint(
                  painter: DonutPainter(
                      progress: _completionRate.clamp(0.0, 1.0),
                      color: success)),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("${(_completionRate * 100).toInt()}%",
                  style: GoogleFonts.inter(
                      fontSize: 28, fontWeight: FontWeight.w900, color: t)),
              const Text("COMPLETED",
                  style: TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ],
          ),
        ]),
      );
}

class DonutPainter extends CustomPainter {
  final double progress;
  final Color color;
  DonutPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..color = Colors.white.withOpacity(0.03);

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, 2 * math.pi * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(DonutPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
