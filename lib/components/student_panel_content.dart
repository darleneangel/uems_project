import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import your modular panel files
import 'panels/subject_load_panel.dart';
import 'panels/assessment_panel.dart';
import 'panels/grade_book_panel.dart';
import 'panels/profile_panel.dart';
import 'panels/offices_panel.dart';

class StudentPanelContent extends StatelessWidget {
  final String panelType;
  final bool isDarkMode;
  final Map<String, dynamic> studentData;

  const StudentPanelContent({
    super.key,
    required this.panelType,
    required this.isDarkMode,
    required this.studentData,
  });

  // Theme Constants
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color tDark = Color(0xFF0F071D);
  static const Color surface = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _buildActivePanel(context),
    );
  }

  Widget _buildActivePanel(BuildContext context) {
    // Every panel below now receives studentData to satisfy the 'required' parameter you added.
    switch (panelType) {
      case 'subject_load':
        return SubjectLoadPanel(
          isDarkMode: isDarkMode,
          studentData: studentData,
        );
      case 'assessment':
        return AssessmentPanel(
          isDarkMode: isDarkMode,
          studentData: studentData,
        );
      case 'grade_book':
        return GradeBookPanel(
          isDarkMode: isDarkMode,
          studentData: studentData,
        );
      case 'profile':
        return ProfilePanel(
          isDarkMode: isDarkMode,
          studentData: studentData,
        );
      case 'offices':
        return OfficesPanel(
          isDarkMode: isDarkMode,
          studentData: studentData,
        );
      default:
        return _buildDefaultPanel();
    }
  }

  Widget _buildDefaultPanel() {
    final Color bgColor = isDarkMode ? surface : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : pViolet;

    return Container(
      key: const ValueKey('default_panel'),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: aViolet.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: aViolet, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'Unified Systems Active',
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please select a module to access school records and services.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
