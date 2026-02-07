import 'package:flutter/material.dart';

// Import your modular panel files here
import 'panels/subject_load_panel.dart';
import 'panels/assessment_panel.dart';
import 'panels/grade_book_panel.dart';
import 'panels/clearance_panel.dart';
import 'panels/profile_panel.dart';
import 'panels/payment_upload_panel.dart';
import 'panels/offices_panel.dart';

class StudentPanelContent extends StatelessWidget {
  final String panelType;
  final bool isDarkMode; // Add this field

  // Update constructor to require isDarkMode
  const StudentPanelContent({
    super.key,
    required this.panelType,
    required this.isDarkMode,
  });

  // Theme Constants matching your professional violet scheme
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color tDark = Color(0xFF0F071D);
  static const Color surface = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);

  @override
  Widget build(BuildContext context) {
    // This Hub now delegates the 'isDarkMode' state to each sub-panel
    switch (panelType) {
      case 'subject_load':
        return SubjectLoadPanel(isDarkMode: isDarkMode);
      case 'assessment':
        return AssessmentPanel(isDarkMode: isDarkMode);
      case 'grade_book':
        return GradeBookPanel(isDarkMode: isDarkMode);
      case 'clearance':
        // This calls the code you have in the Canvas
        return ClearancePanel(isDarkMode: isDarkMode);
      case 'profile':
        return ProfilePanel(isDarkMode: isDarkMode);
      case 'payment_upload':
        return PaymentUploadPanel(isDarkMode: isDarkMode);
      case 'offices':
        return OfficesPanel(isDarkMode: isDarkMode);
      default:
        return _buildDefaultPanel();
    }
  }

  Widget _buildDefaultPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: const Center(
        child: Text(
          'Panel not implemented yet',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
