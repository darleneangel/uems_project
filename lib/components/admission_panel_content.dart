import 'package:flutter/material.dart';
import 'admission_panels/admission_overview_panel.dart';
import 'admission_panels/applicant_management_panel.dart';
import 'admission_panels/document_verification_panel.dart';
import 'shared/messaging_panel.dart';
import 'admission_panels/enrollment_verification_panel.dart';
import 'admission_panels/admission_transactions_panel.dart';
import 'shared/staff_profile_portal.dart';

class AdmissionPanelContent extends StatelessWidget {
  final int selectedIndex;
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const AdmissionPanelContent({
    super.key,
    required this.selectedIndex,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    // Modular Routing for Admission Officer Workspace
    switch (selectedIndex) {
      case 0:
        return AdmissionOverviewPanel(
            isDarkMode: isDarkMode, userData: userData);
      case 1:
        return ApplicationsManagementPanel(
            isDarkMode: isDarkMode, userData: userData);
      case 2:
        // INTEGRATED: Transaction Ledger & Report Generation
        return AdmissionTransactionsPanel(
            isDarkMode: isDarkMode, userData: userData);
      case 3:
        return DocumentVerificationPanel(
            isDarkMode: isDarkMode, userData: userData);
      case 4:
        return MessagingPanel(isDarkMode: isDarkMode, userData: userData);
      case 5:
        return StaffProfilePortal(isDarkMode: isDarkMode, userData: userData);
      case 6:
        return EnrollmentVerificationPanel(
            isDarkMode: isDarkMode, userData: userData);
      default:
        return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_shared_outlined,
              size: 64, color: isDarkMode ? Colors.white24 : Colors.black12),
          const SizedBox(height: 16),
          const Text("Academic Module Selected",
              style: TextStyle(color: Colors.blueGrey)),
        ],
      ),
    );
  }
}
