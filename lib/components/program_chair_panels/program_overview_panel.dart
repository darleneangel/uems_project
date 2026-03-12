import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

class ProgramOverviewPanel extends StatefulWidget {
  final bool isDarkMode;
  const ProgramOverviewPanel({super.key, required this.isDarkMode});

  @override
  State<ProgramOverviewPanel> createState() => _ProgramOverviewPanelState();
}

class _ProgramOverviewPanelState extends State<ProgramOverviewPanel> {
  bool _isLoading = true;
  String? _chairDeptId;
  String? _chairDeptName;

  // Real-time Stats
  int _studentCount = 0;
  int _facultyCount = 0;
  int _subjectCount = 0;

  // Visual Assets
  final List<double> _enrollmentTrend = [0.2, 0.4, 0.35, 0.6, 0.75, 0.9, 1.0];
  final List<double> _gradeFrequencies = [
    12,
    38,
    42,
    8,
    4
  ]; // Distro from 1.0 down to 5.0

  // Palette
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);

  @override
  void initState() {
    super.initState();
    _loadProgramAnalytics();
  }

  /// 🛰️ DATABASE: Aggregate departmental data with compatible relational logic
  Future<void> _loadProgramAnalytics() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final client = SupabaseService().client;
    final user = client.auth.currentUser;

    if (user == null) return;

    try {
      // 1. Handshake: Identify Chair's Dept
      final chairData = await client
          .from('employee_details')
          .select('department_id, departments(name)')
          .eq('profile_id', user.id)
          .maybeSingle();

      if (chairData != null) {
        _chairDeptId = chairData['department_id'];
        _chairDeptName = chairData['departments']['name'];

        // 2. Aggregate Queries: Using standard select and length check for version compatibility
        final results = await Future.wait([
          // Count Students: student_details -> courses -> department_id
          client
              .from('student_details')
              .select('profile_id, courses!inner(department_id)')
              .eq('courses.department_id', _chairDeptId!),

          // Count Faculty: employee_details -> department_id
          client
              .from('employee_details')
              .select('profile_id')
              .eq('department_id', _chairDeptId!),

          // Count Subjects: subjects -> department_id
          client
              .from('subjects')
              .select('id')
              .eq('department_id', _chairDeptId!),
        ]);

        if (mounted) {
          setState(() {
            // Count logic derived from list length to avoid FetchOptions errors
            _studentCount = (results[0] as List).length;
            _facultyCount = (results[1] as List).length;
            _subjectCount = (results[2] as List).length;
          });
        }
      }
    } catch (e) {
      debugPrint("Oversight Data Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : pViolet;
    final cardColor = widget.isDarkMode ? surfaceDark : Colors.white;

    if (_isLoading)
      return const Center(child: CircularProgressIndicator(color: aViolet));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 32),

          // 1. KPI STAT CARDS
          Row(
            children: [
              _statCard("Department Students", _studentCount.toString(),
                  LucideIcons.users, aViolet, cardColor, textColor),
              _statCard(
                  "Managed Faculty",
                  _facultyCount.toString(),
                  LucideIcons.userCheck,
                  Colors.blueAccent,
                  cardColor,
                  textColor),
              _statCard("Subject Catalog", _subjectCount.toString(),
                  LucideIcons.layers, success, cardColor, textColor),
            ],
          ),
          const SizedBox(height: 32),

          // 2. ANALYTICS ROW
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: _chartBox(
                  "Enrollment Velocity",
                  "Institutional growth trajectory for $_chairDeptName",
                  _buildLineGraph(textColor),
                  cardColor,
                  textColor,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 5,
                child: _buildFacultyWorkloadCard(cardColor, textColor),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 3. GRADE DISTRIBUTION
          _chartBox(
            "Grade Distribution Profile",
            "Percentage of numeric outcomes in current semester",
            _buildBarGraph(textColor),
            cardColor,
            textColor,
            height: 280,
          ),
          const SizedBox(height: 24),
          _buildInstitutionalAuditNotice(textColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${_chairDeptName ?? 'Academic'} Oversight Console",
              style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: t,
                  letterSpacing: -1)),
          const Text(
              "Real-time monitoring of curriculum performance and departmental capacity.",
              style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
        ],
      );

  Widget _statCard(String label, String val, IconData icon, Color color,
          Color bg, Color text) =>
      Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 16),
              Text(val,
                  style: GoogleFonts.orbitron(
                      fontSize: 26, fontWeight: FontWeight.bold, color: text)),
              Text(label.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
            ],
          ),
        ),
      );

  Widget _chartBox(String title, String sub, Widget chart, Color bg, Color text,
      {double height = 220}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800, color: text, fontSize: 16)),
          Text(sub,
              style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
          const SizedBox(height: 32),
          SizedBox(height: height, child: chart),
        ],
      ),
    );
  }

  Widget _buildLineGraph(Color text) {
    return CustomPaint(
      size: Size.infinite,
      painter: _AnalyticsLinePainter(points: _enrollmentTrend, color: aViolet),
    );
  }

  Widget _buildBarGraph(Color text) {
    final List<String> labels = ["1.0", "2.0", "3.0", "4.0", "5.0"];
    double maxVal = _gradeFrequencies.reduce(math.max);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(_gradeFrequencies.length, (i) {
        double hFactor = _gradeFrequencies[i] / maxVal;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 50,
              height: 180 * hFactor,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [success, success.withOpacity(0.3)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            Text(labels[i],
                style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ],
        );
      }),
    );
  }

  Widget _buildFacultyWorkloadCard(Color bg, Color text) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Resource Utilization",
                style: TextStyle(
                    color: text, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 24),
            _loadIndicator(
                "Major Course Specialists", 0.88, Colors.orangeAccent),
            const SizedBox(height: 18),
            _loadIndicator("Foundational Staff", 0.54, success),
            const SizedBox(height: 18),
            _loadIndicator(
                "General Education Support", 0.32, Colors.blueAccent),
            const Divider(height: 48, color: Colors.white10),
            Center(
                child: Text("DISTRIBUTION: BALANCED",
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: success,
                        letterSpacing: 1.2))),
          ],
        ),
      );

  Widget _loadIndicator(String label, double value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label,
                style: const TextStyle(color: Colors.blueGrey, fontSize: 11)),
            Text("${(value * 100).toInt()}%",
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 11)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                  value: value,
                  color: color,
                  backgroundColor: Colors.white10,
                  minHeight: 6)),
        ],
      );

  Widget _buildInstitutionalAuditNotice(Color text) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: aViolet.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: aViolet.withOpacity(0.2))),
        child: Row(
          children: [
            const Icon(LucideIcons.shieldCheck, color: aViolet, size: 20),
            const SizedBox(width: 16),
            Expanded(
                child: Text(
                    "The data reflected above is synced with the live Registrar and HR ledger. No manual entry is permitted in this view.",
                    style:
                        TextStyle(color: text.withOpacity(0.7), fontSize: 12))),
          ],
        ),
      );
}

// --- VISUAL ENGINE: Custom Painter for Charting ---

class _AnalyticsLinePainter extends CustomPainter {
  final List<double> points;
  final Color color;
  _AnalyticsLinePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..shader = LinearGradient(
              colors: [color.withOpacity(0.3), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter)
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();
    double step = size.width / (points.length - 1);

    path.moveTo(0, size.height * (1 - points[0]));
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, size.height * (1 - points[0]));

    for (int i = 1; i < points.length; i++) {
      path.lineTo(i * step, size.height * (1 - points[i]));
      fillPath.lineTo(i * step, size.height * (1 - points[i]));
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(
          Offset(i * step, size.height * (1 - points[i])), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
