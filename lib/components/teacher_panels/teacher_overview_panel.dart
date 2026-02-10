import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TeacherOverviewPanel extends StatefulWidget {
  final bool isDarkMode;
  const TeacherOverviewPanel({super.key, required this.isDarkMode});

  @override
  State<TeacherOverviewPanel> createState() => _TeacherOverviewPanelState();
}

class _TeacherOverviewPanelState extends State<TeacherOverviewPanel> {
  // Modern Tonal Palette Constants
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);
  static const Color success = Color(0xFF69F0AE);

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode ? Colors.white : pViolet;
    final Color bgColor = widget.isDarkMode ? surfaceDark : Colors.white;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 32),
          _buildAnalyticsOverview(bgColor, textColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Faculty Management Hub",
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: text,
            letterSpacing: -1,
          ),
        ),
        const Text(
          "Analyze performance trends and manage classroom data points.",
          style: TextStyle(color: Colors.blueGrey, fontSize: 14),
        ),
      ],
    );
  }

  // --- MODULE 0: ANALYTICS OVERVIEW (MODERNIZED) ---
  Widget _buildAnalyticsOverview(Color bg, Color text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Stat Cards
        Row(
          children: [
            _statCard(
              "Total Students",
              "142",
              LucideIcons.users,
              aViolet,
              bg,
              text,
            ),
            const SizedBox(width: 20),
            _statCard(
              "Active Classes",
              "4",
              LucideIcons.bookOpen,
              Colors.blue,
              bg,
              text,
            ),
            const SizedBox(width: 20),
            _statCard(
              "Pending Grades",
              "12",
              LucideIcons.clock,
              Colors.orangeAccent,
              bg,
              text,
            ),
          ],
        ),
        const SizedBox(height: 32),

        // 2. Charts Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bar Graph Section
            Expanded(
              flex: 6,
              child: _chartContainer(
                "Grade Distribution",
                "Number of students per grade bracket",
                _buildBarGraph(text),
                bg,
                text,
              ),
            ),
            const SizedBox(width: 24),
            // Pie Chart Section
            Expanded(
              flex: 4,
              child: _chartContainer(
                "Syllabus Completion",
                "Course material coverage progress",
                _buildPieChart(text),
                bg,
                text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 3. Line Graph Section (Full Width)
        _chartContainer(
          "Performance Trend",
          "Average student performance across terms",
          _buildLineGraph(text),
          bg,
          text,
          height: 250,
        ),
      ],
    );
  }

  // --- CHART BUILDERS ---

  Widget _buildBarGraph(Color text) {
    final List<double> values = [0.4, 0.8, 0.6, 0.9, 0.3];
    final List<String> labels = ["1.0", "1.25", "1.5", "1.75", "2.0"];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(values.length, (i) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 40,
              height: 150 * values[i],
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [aViolet, aViolet.withOpacity(0.4)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              labels[i],
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPieChart(Color text) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: DonutPainter(progress: 0.75, color: success),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "75%",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: text,
                ),
              ),
              const Text(
                "COMPLETE",
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLineGraph(Color text) {
    return Container(
      width: double.infinity,
      height: 150,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: CustomPaint(
        painter: LineGraphPainter(
          points: [0.2, 0.5, 0.4, 0.8, 0.7, 0.9],
          color: aViolet,
        ),
      ),
    );
  }

  Widget _chartContainer(
    String title,
    String sub,
    Widget chart,
    Color bg,
    Color text, {
    double height = 220,
  }) {
    return Container(
      height: height + 100,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              color: text,
              fontSize: 16,
            ),
          ),
          Text(
            sub,
            style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
          ),
          const Spacer(),
          SizedBox(height: height, child: chart),
        ],
      ),
    );
  }

  Widget _statCard(
    String label,
    String val,
    IconData icon,
    Color color,
    Color bg,
    Color text,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 15),
            Text(
              val,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: text,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- CUSTOM PAINTERS ---

class DonutPainter extends CustomPainter {
  final double progress;
  final Color color;
  DonutPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    // Background
    paint.color = Colors.white.withOpacity(0.05);
    canvas.drawCircle(center, radius, paint);

    // Progress
    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LineGraphPainter extends CustomPainter {
  final List<double> points;
  final Color color;
  LineGraphPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.2), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
