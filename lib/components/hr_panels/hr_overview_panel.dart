import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/supabase_service.dart';

class HROverviewPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const HROverviewPanel(
      {super.key, required this.isDarkMode, required this.userData});

  @override
  State<HROverviewPanel> createState() => _HROverviewPanelState();
}

class _HROverviewPanelState extends State<HROverviewPanel> {
  final SupabaseService _service = SupabaseService();
  bool _isLoading = true;

  // Aggregate Stats
  int _totalEmployees = 0;
  int _activeStaff = 0;
  int _archivedStaff = 0;

  // Chart Data Structures
  Map<String, int> _roleCounts = {};
  List<double> _hiringTrend = [0, 0, 0, 0, 0, 0];
  int? _hoveredIndex;

  // Visual Palette
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);
  static const List<Color> chartColors = [
    aViolet,
    Colors.blueAccent,
    success,
    Colors.orangeAccent,
    Colors.pinkAccent,
    Colors.cyanAccent
  ];

  @override
  void initState() {
    super.initState();
    _loadHRIntelligence();
  }

  /// 🛰️ DATABASE ENGINE: Processes workforce data for visualization
  Future<void> _loadHRIntelligence() async {
    setState(() => _isLoading = true);
    try {
      final response = await _service.client
          .from('profiles')
          .select('role, created_at, employee_details(employment_status)')
          .neq('role', 'student');

      final List data = response as List;
      int active = 0;
      int archived = 0;
      Map<String, int> roles = {};

      final now = DateTime.now();
      List<int> months = List.filled(6, 0);

      for (var row in data) {
        final status =
            row['employee_details']?['employment_status'] ?? 'Active';
        if (status == 'Archived') {
          archived++;
        } else {
          active++;
        }

        String r = row['role'].toString().toUpperCase();
        roles[r] = (roles[r] ?? 0) + 1;

        if (row['created_at'] != null) {
          DateTime created = DateTime.parse(row['created_at']);
          int diff = (now.year - created.year) * 12 + now.month - created.month;
          if (diff >= 0 && diff < 6) {
            months[5 - diff]++;
          }
        }
      }

      if (mounted) {
        setState(() {
          _totalEmployees = data.length;
          _activeStaff = active;
          _archivedStaff = archived;
          _roleCounts = roles;
          _hiringTrend = months.map((m) => m.toDouble()).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("HR Analytics Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : pViolet;
    final cardColor = widget.isDarkMode ? surfaceDark : Colors.white;

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
          Row(
            children: [
              _statCard("Total Headcount", _totalEmployees.toString(),
                  LucideIcons.users, aViolet, cardColor, textColor),
              _statCard("Active Personnel", _activeStaff.toString(),
                  LucideIcons.userCheck, success, cardColor, textColor),
              _statCard(
                  "Archived Vault",
                  _archivedStaff.toString(),
                  LucideIcons.archive,
                  Colors.orangeAccent,
                  cardColor,
                  textColor),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FIXED: Smaller Pie Chart with Hover Logic
              Expanded(
                  flex: 4,
                  child: _chartContainer(
                      "Workforce Composition",
                      "Hover segments for detail",
                      _buildInteractivePie(textColor),
                      cardColor,
                      textColor)),
              const SizedBox(width: 24),
              Expanded(
                  flex: 6,
                  child: _chartContainer(
                      "Hiring Trajectory",
                      "Institutional growth trends",
                      _buildHiringLine(textColor),
                      cardColor,
                      textColor)),
            ],
          ),
          const SizedBox(height: 24),
          _chartContainer(
              "Personnel Capacity Bar",
              "Workload distribution by role",
              _buildRoleBar(textColor),
              cardColor,
              textColor,
              height: 300),
        ],
      ),
    );
  }

  Widget _buildHeader(Color t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("HR Intelligence Overview",
              style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: t,
                  letterSpacing: -1)),
          const Text(
              "Strategic personnel distribution and institutional growth metrics.",
              style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
        ],
      );

  Widget _statCard(
          String l, String v, IconData i, Color c, Color bg, Color t) =>
      Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: c.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16)),
                  child: Icon(i, color: c, size: 24)),
              const SizedBox(height: 20),
              Text(v,
                  style: GoogleFonts.orbitron(
                      fontSize: 28, fontWeight: FontWeight.bold, color: t)),
              Text(l.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5)),
            ],
          ),
        ),
      );

  Widget _chartContainer(String t, String s, Widget c, Color bg, Color tx,
          {double height = 280}) =>
      Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800, color: tx, fontSize: 16)),
            Text(s,
                style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
            const SizedBox(height: 32),
            SizedBox(height: height, child: c),
          ],
        ),
      );

  // --- INTERACTIVE PIE CHART ---

  Widget _buildInteractivePie(Color textColor) {
    if (_roleCounts.isEmpty) return const Center(child: Text("No data"));

    final List<double> values =
        _roleCounts.values.map((v) => v.toDouble()).toList();
    final List<String> labels = _roleCounts.keys.toList();
    final double total = values.fold(0, (p, c) => p + c);

    return MouseRegion(
      onHover: (event) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final Offset localOffset = event.localPosition;

        // This is a simplified hit test logic for the circular area
        // Center is roughly at 150, 150 relative to chart container logic
        // We calculate index based on angle
        double dx = localOffset.dx - 100; // Assuming 200 width
        double dy = localOffset.dy - 100;

        double angle = math.atan2(dy, dx) + (math.pi / 2);
        if (angle < 0) angle += 2 * math.pi;

        double currentAngle = 0;
        int? newHoveredIndex;
        for (int i = 0; i < values.length; i++) {
          double sweep = (values[i] / total) * 2 * math.pi;
          if (angle >= currentAngle && angle <= currentAngle + sweep) {
            newHoveredIndex = i;
            break;
          }
          currentAngle += sweep;
        }

        if (newHoveredIndex != _hoveredIndex) {
          setState(() => _hoveredIndex = newHoveredIndex);
        }
      },
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: Center(
        child: SizedBox(
          width: 180, // Made smaller to fit card
          height: 180,
          child: CustomPaint(
            painter: PieChartPainter(
              data: values,
              colors: chartColors,
              hoveredIndex: _hoveredIndex,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_hoveredIndex != null ? labels[_hoveredIndex!] : "TOTAL",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                  Text(
                      _hoveredIndex != null
                          ? values[_hoveredIndex!].toInt().toString()
                          : _totalEmployees.toString(),
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 22)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHiringLine(Color textColor) {
    return CustomPaint(
      size: Size.infinite,
      painter: LineChartPainter(
        points: _hiringTrend,
        color: success,
        textColor: Colors.blueGrey,
      ),
    );
  }

  Widget _buildRoleBar(Color textColor) {
    final List<int> values = _roleCounts.values.toList();
    final List<String> labels = _roleCounts.keys.toList();
    if (values.isEmpty) return const SizedBox();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(values.length, (i) {
        double max = values.reduce(math.max).toDouble();
        if (max == 0) max = 1.0;
        double heightFactor = values[i] / max;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(values[i].toString(),
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              width: 45,
              height: 180 * heightFactor,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  chartColors[i % chartColors.length],
                  chartColors[i % chartColors.length].withOpacity(0.3)
                ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            Text(labels[i],
                style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 9,
                    fontWeight: FontWeight.bold)),
          ],
        );
      }),
    );
  }
}

// --- UPDATED CUSTOM PAINTERS ---

class PieChartPainter extends CustomPainter {
  final List<double> data;
  final List<Color> colors;
  final int? hoveredIndex;

  PieChartPainter(
      {required this.data, required this.colors, this.hoveredIndex});

  @override
  void paint(Canvas canvas, Size size) {
    double total = data.fold(0, (p, c) => p + c);
    if (total == 0) return;

    double startRadian = -math.pi / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < data.length; i++) {
      final sweepRadian = (data[i] / total) * 2 * math.pi;
      final bool isHovered = hoveredIndex == i;

      paint.color =
          colors[i % colors.length].withOpacity(isHovered ? 1.0 : 0.6);
      paint.strokeWidth = isHovered ? 28 : 20; // Visual pop on hover

      canvas.drawArc(rect, startRadian, sweepRadian, false, paint);
      startRadian += sweepRadian;
    }

    // Outer subtle guide ring
    canvas.drawCircle(
        center,
        radius + 10,
        Paint()
          ..color = Colors.white.withOpacity(0.02)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant PieChartPainter old) =>
      old.hoveredIndex != hoveredIndex;
}

class LineChartPainter extends CustomPainter {
  final List<double> points;
  final Color color;
  final Color textColor;
  LineChartPainter(
      {required this.points, required this.color, required this.textColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..shader = LinearGradient(
              colors: [color.withOpacity(0.2), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter)
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    double maxVal = points.reduce(math.max);
    if (maxVal == 0) maxVal = 1;

    final path = Path();
    final fillPath = Path();
    double stepX = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      double x = i * stepX;
      double y = size.height - (points[i] / maxVal * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;
    for (int i = 0; i < 4; i++) {
      double y = size.height / 3 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
