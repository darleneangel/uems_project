import 'package:flutter/material.dart';
import 'program_chair_panels/curriculum_review_panel.dart';
import 'program_chair_panels/faculty_load_panel.dart';
import 'program_chair_panels/program_overview_panel.dart';
import 'program_chair_panels/assessment_summary_panel.dart';
import 'program_chair_panels/student_masterlist_panel.dart';
import 'shared/messaging_panel.dart';
import 'shared/staff_profile_portal.dart';

class ProgramChairPanelContent extends StatelessWidget {
  final int selectedIndex;
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const ProgramChairPanelContent({
    super.key,
    required this.selectedIndex,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    // This component acts as the primary router for the Program Chair's workspace.
    // It propagates the 'userData' (containing the chair's ID and department context)
    // to all child panels so they can perform authorized database queries.

    switch (selectedIndex) {
      case 0:
        // Dashboard: Departmental stats and student master list
        return ProgramOverviewPanel(
          isDarkMode: isDarkMode,
          userData: userData,
        );
      case 1:
        // Curriculum Review: Processing enrollment queue and study loads
        return CurriculumReviewPanel(
          isDarkMode: isDarkMode,
          userData: userData,
        );
      case 2:
        // Faculty Management: Viewing and assigning faculty workloads
        return FacultyLoadPanel(
          isDarkMode: isDarkMode,
          userData: userData,
        );
      case 3:
        // Assessment: Summaries of student academic performance
        return AssessmentSummaryPanel(
          isDarkMode: isDarkMode,
          userData: userData,
        );
      case 4:
        // Student Master List: Comprehensive view of all students in the department
        return StudentMasterListPanel(
          isDarkMode: isDarkMode,
          userData: userData,
        );
      case 5:
        // Messaging: Communication hub for student inquiries and faculty coordination
        return MessagingPanel(
          isDarkMode: isDarkMode,
          userData: userData,
        );

      case 6:
        // Profile: View and edit the Program Chair's own profile
        return StaffProfilePortal(
          isDarkMode: isDarkMode,
          userData: userData,
        );

      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.dashboard_outlined,
                size: 64,
                color: isDarkMode ? Colors.white24 : Colors.black12,
              ),
              const SizedBox(height: 16),
              Text(
                "Select an Academic Module",
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
    }
  }
}
