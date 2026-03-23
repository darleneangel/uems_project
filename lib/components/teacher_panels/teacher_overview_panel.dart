import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/supabase_service.dart';

class TeacherOverviewPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const TeacherOverviewPanel(
      {super.key, required this.isDarkMode, required this.userData});

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

  /// 🛰️ DATABASE: Corrected to join 'grades' table to fix "final_grade does not exist" error
  Future<void> _loadAnalytics() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final String profId = widget.userData['id'];

    try {
      // FIX: Joining grades table correctly according to the SQL schema
      final response = await _service.client
          .from('study_loads')
          .select('id, student_id, subject_id, grades(final_numeric_grade)')
          .eq('professor_id', profId);

      final List<dynamic> data = response as List;
      final Set<String> uniqueStudents = {};
      final Set<String> uniqueSubjects = {};
      int pending = 0;
      Map<String, int> distroMap = {
        "1.00": 0,
        "1.25": 0,
        "1.50": 0,
        "1.75": 0,
        "2.00+": 0
      };

      for (var row in data) {
        if (row['student_id'] != null) {
          uniqueStudents.add(row['student_id'].toString());
          uniqueSubjects.add(row['subject_id'].toString());

          // Supabase relation can come back as either a list or a single map.
          final dynamic gradeRaw = row['grades'];
          Map<String, dynamic>? gradeEntry;

          if (gradeRaw is List && gradeRaw.isNotEmpty) {
            final first = gradeRaw.first;
            if (first is Map) {
              gradeEntry = Map<String, dynamic>.from(first);
            }
          } else if (gradeRaw is Map) {
            gradeEntry = Map<String, dynamic>.from(gradeRaw);
          }

          if (gradeEntry == null) {
            pending++;
          } else {
            final double g = double.tryParse(
                    gradeEntry['final_numeric_grade']?.toString() ??
                        "0.0") ??
                0.0;
            if (g == 0) {
              pending++;
            } else {
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
          _totalStudents = uniqueStudents.length;
          _activeClasses = uniqueSubjects.length;
          _pendingGrades = pending;
          _completionRate =
              data.isEmpty ? 0.0 : (data.length - pending) / data.length;

          int maxCount = distroMap.values.reduce(math.max);
          if (maxCount == 0) maxCount = 1;
          _gradeDistroValues =
              distroMap.values.map((v) => v / maxCount).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Analytics Sync Error: $e");
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
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 32),
          Row(children: [
            _statCard("Students", _totalStudents.toString(), LucideIcons.users,
                aViolet, bgColor, textColor),
            _statCard("Subjects", _activeClasses.toString(),
                LucideIcons.bookOpen, Colors.blue, bgColor, textColor),
            _statCard("Pending", _pendingGrades.toString(), LucideIcons.clock,
                Colors.orangeAccent, bgColor, textColor),
          ]),
          const SizedBox(height: 32),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                flex: 6,
                child: _chart(
                    "Grade Distribution",
                    "Count per transmuted bracket",
                    _bar(),
                    bgColor,
                    textColor)),
            const SizedBox(width: 24),
            Expanded(
                flex: 4,
                child: _chart("Grading Completion", "Roster progress",
                    _pie(textColor), bgColor, textColor)),
          ]),
        ],
      ),
    );
  }

  Widget _buildHeader(Color t) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Faculty Management Hub",
            style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: t,
                letterSpacing: -1)),
        const Text("Institutional Ceiling: 95.0 | GWA 1.00 - 5.00 Scale",
            style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
      ]);

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
                      color:
                          widget.isDarkMode ? Colors.white10 : Colors.black12)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(i, color: c),
                    const SizedBox(height: 15),
                    Text(v,
                        style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: t)),
                    Text(l,
                        style: const TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 11,
                            fontWeight: FontWeight.bold))
                  ])));

  Widget _chart(String t, String s, Widget c, Color bg, Color tx,
          {double h = 220}) =>
      Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: widget.isDarkMode ? Colors.white10 : Colors.black12)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800, color: tx, fontSize: 16)),
            Text(s,
                style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
            const SizedBox(height: 24),
            SizedBox(height: h, child: c)
          ]));

  Widget _bar() => Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(
          _gradeDistroValues.length,
          (i) => Container(
              width: 35,
              height: 150 * _gradeDistroValues[i],
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [aViolet, aViolet.withOpacity(0.3)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter),
                  borderRadius: BorderRadius.circular(6)))));

  Widget _pie(Color t) => Center(
          child: Stack(alignment: Alignment.center, children: [
        SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
                painter:
                    DonutPainter(progress: _completionRate, color: success))),
        Text("${(_completionRate * 100).toInt()}%",
            style: GoogleFonts.inter(
                fontSize: 24, fontWeight: FontWeight.w900, color: t))
      ]));
}

class DonutPainter extends CustomPainter {
  final double progress;
  final Color color;
  DonutPainter({required this.progress, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    paint.color = Colors.white.withOpacity(0.05);
    canvas.drawCircle(center, size.width / 2, paint);
    paint.color = color;
    canvas.drawArc(Rect.fromCircle(center: center, radius: size.width / 2),
        -math.pi / 2, 2 * math.pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(CustomPainter old) => true;
}
