import 'package:flutter/material.dart';

// Modular Panel Imports
import 'registrar_panels/registrar_overview_panel.dart';
import 'registrar_panels/student_records_panel.dart';
import 'registrar_panels/enrollment_registration_panel.dart';
import 'registrar_panels/grades_management_panel.dart';
import 'registrar_panels/credentials_certification_panel.dart';
import 'registrar_panels/curriculum_catalog_panel.dart';
import 'registrar_panels/reporting_compliance_panel.dart';
import 'registrar_panels/registrar_messages_panel.dart';
import 'registrar_panels/student_requests_panel.dart';
import 'registrar_panels/audit_trail_panel.dart';
import 'shared/messaging_panel.dart';
import 'shared/staff_profile_portal.dart';

class RegistrarPanelContent extends StatelessWidget {
  final String panelType;
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const RegistrarPanelContent({
    super.key,
    required this.panelType,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _buildActivePanel(),
    );
  }

  Widget _buildActivePanel() {
    // Switch based on panelType string from RegistrarDashboardView
    switch (panelType) {
      case 'records':
        return StudentRecordsPanel(
          key: const ValueKey('records'),
          isDarkMode: isDarkMode,
        );
      case 'enrollment':
        return RegistrarEnrollmentPanel(
          key: const ValueKey('enrollment'),
          isDarkMode: isDarkMode,
          userData: userData,
        );
      case 'grades':
        return GradesManagementPanel(
          key: const ValueKey('grades'),
          isDarkMode: isDarkMode,
        );
      case 'credentials':
        return CredentialsCertificationPanel(
          key: const ValueKey('credentials'),
          isDarkMode: isDarkMode,
        );
      case 'curriculum':
        return CurriculumCatalogPanel(
          key: const ValueKey('curriculum'),
          isDarkMode: isDarkMode,
        );
      case 'reports':
        return ReportingCompliancePanel(
          key: const ValueKey('reports'),
          isDarkMode: isDarkMode,
        );
      case 'messages':
        return RegistrarMessagesPanel(
          key: const ValueKey('messages'),
          isDarkMode: isDarkMode,
        );
      case 'requests':
        return StudentRequestsPanel(
          key: const ValueKey('requests'),
          isDarkMode: isDarkMode,
        );
      case 'audit':
        return AuditTrailPanel(
          key: const ValueKey('audit'),
          isDarkMode: isDarkMode,
        );
      case 'overview':
      default:
        return RegistrarOverviewPanel(
          key: const ValueKey('overview'),
          isDarkMode: isDarkMode,
        );
    }
  }
}
