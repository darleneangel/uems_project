import 'package:flutter/material.dart';
import 'package:uems_project/components/shared/program_chair_messaging_panel.dart';
import 'program_chair_panels/curriculum_review_panel.dart';
import 'program_chair_panels/faculty_load_panel.dart';
import 'program_chair_panels/program_overview_panel.dart';
import 'program_chair_panels/assessment_summary_panel.dart';

class ProgramChairPanelContent extends StatelessWidget {
  final int selectedIndex;
  final bool isDarkMode;

  const ProgramChairPanelContent({
    super.key,
    required this.selectedIndex,
    required this.isDarkMode,
  });

  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);

  @override
  Widget build(BuildContext context) {
    final Color textColor = isDarkMode ? Colors.white : pViolet;
    final Color panelColor = isDarkMode ? surfaceDark : Colors.white;
    final Color subTextColor = isDarkMode ? Colors.white54 : Colors.blueGrey;

    switch (selectedIndex) {
      case 0:
        return ProgramOverviewPanel(isDarkMode: isDarkMode);
      case 1:
        return CurriculumReviewPanel(isDarkMode: isDarkMode);
      case 2:
        return FacultyLoadPanel(isDarkMode: isDarkMode);
      case 3:
        return AssessmentSummaryPanel(isDarkMode: isDarkMode);
      case 4:
        return ProgramChairMessagingPanel(isDarkMode: isDarkMode);
      default:
        return _placeholderPanel("Module Under Construction", textColor);
    }
  }

  Widget _placeholderPanel(String title, Color textColor) {
    return Center(
      child: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
