import 'package:flutter/material.dart';
import '../components/admission_panels/applicant_management_panel.dart';
import '../components/admission_panels/document_verification_panel.dart';
import '../components/admission_panels/admission_workflow_panel.dart';
import '../components/admission_panels/admission_messaging_panel.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

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

  @override
  Widget build(BuildContext context) {
    // Map the selected index from the sidebar to the correct live module
    switch (selectedIndex) {
      case 1: // "Applications" menu item
        return ApplicantManagementPanel(isDarkMode: isDarkMode);
      case 3: // "Document Verification" menu item
        return DocumentVerificationPanel(isDarkMode: isDarkMode);
      case 4: // "Messaging" menu item
        return AdmissionMessagingPanel(isDarkMode: isDarkMode);
      case 6: // "Workflow" menu item
        return AdmissionWorkflowPanel(isDarkMode: isDarkMode);
      case 0: // "Overview"
      default:
        return _buildOverviewPlaceholder();
    }
  }

  Widget _buildOverviewPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.layoutDashboard,
              size: 64, color: aViolet.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text("ADMISSIONS CONTROL CENTER",
              style: GoogleFonts.orbitron(
                  color: Colors.white24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2)),
          const Text(
              "Select a management module from the sidebar to begin processing.",
              style: TextStyle(color: Colors.white10, fontSize: 12)),
        ],
      ),
    );
  }
}
