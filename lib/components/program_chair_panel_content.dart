import 'package:flutter/material.dart';
import 'program_chair_panels/curriculum_review_panel.dart';
import 'program_chair_panels/faculty_load_panel.dart';
import 'program_chair_panels/program_overview_panel.dart';
import 'program_chair_panels/assessment_summary_panel.dart';

class ProgramChairPanelContent extends StatelessWidget {
  final int selectedIndex;
  final bool isDarkMode;
  final Map<String, dynamic> userData; // THE FIX: Defined the missing parameter

  const ProgramChairPanelContent({
    super.key,
    required this.selectedIndex,
    required this.isDarkMode,
    required this.userData, // THE FIX: Added to constructor
  });

  @override
  Widget build(BuildContext context) {
    switch (selectedIndex) {
      case 0:
        // Pass identity to overview for departmental stats
        return ProgramOverviewPanel(isDarkMode: isDarkMode);
      case 1:
        // THE BRIDGE: Passing '6001' data to resolve the IT Department
        return CurriculumReviewPanel(
            isDarkMode: isDarkMode, userData: userData);
      case 2:
        return FacultyLoadPanel(isDarkMode: isDarkMode);
      case 3:
        return AssessmentSummaryPanel(isDarkMode: isDarkMode);
      default:
        return const Center(child: Text("Select an Academic Module"));
    }
  }
}
