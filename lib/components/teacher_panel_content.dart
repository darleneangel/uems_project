import 'package:flutter/material.dart';
import 'teacher_panels/teacher_overview_panel.dart';
import 'teacher_panels/teaching_load_panel.dart';
import 'teacher_panels/grade_encoding_panel.dart';
import 'teacher_panels/student_tracking_panel.dart';
import 'shared/messaging_panel.dart';

class TeacherPanelContent extends StatelessWidget {
  final int selectedIndex;
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const TeacherPanelContent({
    super.key,
    required this.selectedIndex,
    required this.isDarkMode,
    required this.userData,
  });

  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);

  @override
  Widget build(BuildContext context) {
    final Color textColor = isDarkMode ? Colors.white : pViolet;

    switch (selectedIndex) {
      case 0:
        return TeacherOverviewPanel(isDarkMode: isDarkMode, userData: userData);
      case 1:
        return TeachingLoadPanel(isDarkMode: isDarkMode, userData: userData);
      case 2:
        return GradeEncodingPanel(isDarkMode: isDarkMode, userData: userData);
      case 3:
        return StudentTrackingPanel(isDarkMode: isDarkMode, userData: userData);
      case 4:
        return MessagingPanel(isDarkMode: isDarkMode, userData: userData);
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
