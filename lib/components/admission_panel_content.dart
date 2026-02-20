import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'admission_panels/applicant_management_panel.dart';
import 'admission_panels/document_verification_panel.dart';
import 'admission_panels/interview_management_panel.dart';
import 'admission_panels/admission_workflow_panel.dart';
import 'admission_panels/admission_messaging_panel.dart';
import 'admission_panels/enrollment_verification_panel.dart';

class AdmissionPanelContent extends StatelessWidget {
  final int selectedIndex;
  final bool isDarkMode;

  const AdmissionPanelContent({
    super.key,
    required this.selectedIndex,
    required this.isDarkMode,
  });

  // Theme Constants
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);

  @override
  Widget build(BuildContext context) {
    final Color textColor = isDarkMode ? Colors.white : pViolet;
    final Color panelColor = isDarkMode ? surfaceDark : Colors.white;
    final Color subTextColor = isDarkMode ? Colors.white54 : Colors.blueGrey;

    switch (selectedIndex) {
      case 0:
        return _buildOverviewPanel(panelColor, textColor, subTextColor);
      case 1:
        return ApplicantManagementPanel(isDarkMode: isDarkMode);
      case 2:
        return InterviewManagementPanel(isDarkMode: isDarkMode);
      case 3:
        return DocumentVerificationPanel(isDarkMode: isDarkMode);
      case 4:
        return AdmissionMessagingPanel(isDarkMode: isDarkMode);
      case 5:
        return EnrollmentVerificationPanel(isDarkMode: isDarkMode);
      case 6:
        return AdmissionWorkflowPanel(isDarkMode: isDarkMode);
      default:
        return Center(
          child: Text(
            "Module Under Construction",
            style: TextStyle(color: subTextColor),
          ),
        );
    }
  }

  // --- MODULE: OVERVIEW ---
  Widget _buildOverviewPanel(
    Color panelColor,
    Color textColor,
    Color subTextColor,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Admissions Overview",
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 32),

          // Stat Cards Row
          Row(
            children: [
              _statCard(
                "Total Applicants",
                "1,240",
                LucideIcons.users,
                aViolet,
                textColor,
              ),
              _statCard(
                "Pending Review",
                "142",
                LucideIcons.clock,
                Colors.orangeAccent,
                textColor,
              ),
              _statCard(
                "Admitted Status",
                "856",
                LucideIcons.checkCircle,
                success,
                textColor,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Graphs Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Enrollment Shares Pie Chart
              Expanded(
                flex: 4,
                child: _buildChartCard(
                  "Enrollment Shares",
                  "Applicant distribution by category",
                  _AdmissionPieChart(isDarkMode: isDarkMode),
                  panelColor,
                  textColor,
                ),
              ),
              const SizedBox(width: 24),
              // 2. Application Frequency Histogram
              Expanded(
                flex: 6,
                child: _buildChartCard(
                  "Intake Frequency",
                  "Daily application volume (Last 14 days)",
                  _AdmissionHistogram(isDarkMode: isDarkMode),
                  panelColor,
                  textColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          Text(
            "Quick Actions",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionGrid(panelColor, textColor),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildChartCard(
    String title,
    String sub,
    Widget chart,
    Color cardBg,
    Color text,
  ) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
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
          const SizedBox(height: 32),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  Widget _statCard(
    String label,
    String val,
    IconData icon,
    Color color,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDarkMode ? surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDarkMode ? Colors.white10 : Colors.black12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 15),
            Text(
              val,
              style: GoogleFonts.orbitron(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: textColor,
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

  Widget _buildActionGrid(Color panelColor, Color textColor) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 3.5,
      children: [
        _quickActionButton(
          "New Application",
          LucideIcons.userPlus,
          aViolet,
          textColor,
        ),
        _quickActionButton(
          "Schedule Exams",
          LucideIcons.calendar,
          Colors.blue,
          textColor,
        ),
        _quickActionButton(
          "Generate Letters",
          LucideIcons.mail,
          success,
          textColor,
        ),
        _quickActionButton(
          "System Audit",
          LucideIcons.shieldCheck,
          Colors.orangeAccent,
          textColor,
        ),
      ],
    );
  }

  Widget _quickActionButton(
    String label,
    IconData icon,
    Color color,
    Color textColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          LucideIcons.chevronRight,
          size: 16,
          color: Colors.white24,
        ),
        onTap: () {},
      ),
    );
  }
}

// --- CHART WIDGETS ---

class _AdmissionPieChart extends StatelessWidget {
  final bool isDarkMode;
  const _AdmissionPieChart({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: CustomPaint(
              painter: AdmissionPiePainter(isDarkMode: isDarkMode),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "68%",
                style: GoogleFonts.orbitron(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AdmissionPanelContent.aViolet,
                ),
              ),
              const Text(
                "VERIFIED",
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
}

class AdmissionPiePainter extends CustomPainter {
  final bool isDarkMode;
  AdmissionPiePainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    // Background track
    paint.color = isDarkMode
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.05);
    canvas.drawCircle(center, radius, paint);

    // Verified Share (Violet)
    paint.color = AdmissionPanelContent.aViolet;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 1.36, false, paint);

    // Pending Share (Success Green)
    paint.color = AdmissionPanelContent.success.withOpacity(0.6);
    canvas.drawArc(rect, math.pi * 0.86, math.pi * 0.4, false, paint);
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}

class _AdmissionHistogram extends StatelessWidget {
  final bool isDarkMode;
  const _AdmissionHistogram({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    // Mock data heights
    final List<double> values = [
      0.2,
      0.5,
      0.4,
      0.8,
      0.6,
      0.9,
      0.7,
      0.3,
      0.5,
      0.8,
      0.4,
      0.6,
      0.9,
      0.75,
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: values.map((val) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              height: 180 * val,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AdmissionPanelContent.aViolet,
                    AdmissionPanelContent.aViolet.withOpacity(0.3),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
