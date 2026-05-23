import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'admin_panels/academic_lifecycle_panel.dart';
import 'admin_panels/scholastic_control_panel.dart';
import 'admin_panels/access_security_panel.dart';
import 'admin_panels/announcement_management_panel.dart';
import 'admin_panels/account_control_panel.dart';
import 'request_receiver.dart';
import 'hr_panel.dart';
import 'shared/messaging_panel.dart';
import 'report_panel.dart';

class AdminPanelContent extends StatefulWidget {
  final int selectedIndex;
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const AdminPanelContent({
    super.key,
    required this.selectedIndex,
    this.isDarkMode = true,
    required this.userData,
  });

  @override
  State<AdminPanelContent> createState() => _AdminPanelContentState();
}

class _AdminPanelContentState extends State<AdminPanelContent> {
  @override
  Widget build(BuildContext context) {
    // 🛰️ INSTITUTIONAL ROUTING ENGINE (Numeric Mapping)
    // Indices are mapped based on the AdminDashboard sidebar order.
    // Every panel is provided with the administrator's userData for institutional auditing.

    switch (widget.selectedIndex) {
      case 1:
        return AnnouncementManagementPanel(
            isDarkMode: widget.isDarkMode, userData: widget.userData);

      case 2:
        // The master terminal for auditing document service tickets across the university
        return RequestReceiver(
            isDarkMode: widget.isDarkMode, userData: widget.userData);

      case 3:
        return AcademicLifecyclePanel(
            isDarkMode: widget.isDarkMode, userData: widget.userData);

      case 4:
        return ScholasticControlPanel(
            isDarkMode: widget.isDarkMode, userData: widget.userData);

      case 5:
        return AccessSecurityPanel(
            isDarkMode: widget.isDarkMode, userData: widget.userData);

      case 6:
        return HRPanel(
            isDarkMode: widget.isDarkMode, userData: widget.userData);

      case 7:
        return MessagingPanel(
            isDarkMode: widget.isDarkMode, userData: widget.userData);

      case 8:
        return ReportPanel(
            isDarkMode: widget.isDarkMode, userData: widget.userData);

      case 9:
        return AccountControlPanel(
            isDarkMode: widget.isDarkMode, userData: widget.userData);

      case 10: // Advanced Management - Study Loads
        return _buildPlaceholder(
            "Study Load Audit Terminal", LucideIcons.bookOpen);

      case 11: // Advanced Management - Grade Recording
        return _buildPlaceholder(
            "Scholastic Grade Monitor", LucideIcons.barChart3);

      default:
        // Fallback for overview (index 0) or unmapped indices
        return _buildPlaceholder(
            "Administrative Module Configuration", LucideIcons.wrench);
    }
  }

  /// 📐 UI UTILITY: Consistent placeholder for unlinked modules
  Widget _buildPlaceholder(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? Colors.white.withOpacity(0.03)
                  : Colors.black.withOpacity(0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 64,
                color: widget.isDarkMode ? Colors.white24 : Colors.black12),
          ),
          const SizedBox(height: 24),
          Text(
            text,
            style: TextStyle(
              color: Colors.blueGrey.withOpacity(0.6),
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "This administrative module is currently being synchronized with the cloud core.",
            style: TextStyle(color: Colors.blueGrey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
