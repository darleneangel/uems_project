import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'admission_panels/applicant_management_panel.dart';
import 'admission_panels/document_verification_panel.dart';
import 'admission_panels/interview_management_panel.dart';
import 'admission_panels/admission_workflow_panel.dart';
import 'admission_panels/admission_messaging_panel.dart';

class AdmissionPanelContent extends StatelessWidget {
  final int selectedIndex;
  final bool isDarkMode;

  const AdmissionPanelContent({
    super.key,
    required this.selectedIndex,
    required this.isDarkMode,
  });

  // Theme Constants (matching AdmissionDashboardView)
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
            ),
          ),
          const SizedBox(height: 32),
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
          _buildActionGrid(panelColor, textColor),
        ],
      ),
    );
  }

  // --- UI HELPERS ---
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
            Icon(icon, color: color),
            const SizedBox(height: 15),
            Text(
              val,
              style: GoogleFonts.inter(
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
