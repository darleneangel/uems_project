import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../components/dashboard_panel_template.dart';
import '../components/accounting_panel_content.dart'; // Ensure this file exists
import '../components/shared/messaging_panel.dart';

class AccountingDashboardView extends StatefulWidget {
  final VoidCallback onLogout;
  const AccountingDashboardView({super.key, required this.onLogout});

  @override
  State<AccountingDashboardView> createState() =>
      _AccountingDashboardViewState();
}

class _AccountingDashboardViewState extends State<AccountingDashboardView> {
  bool _isDarkMode = true;
  bool _isSidebarExpanded = true;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final sidebarItems = [
      PanelMenuItem(title: 'Dashboard', icon: LucideIcons.layoutDashboard),
      PanelMenuItem(title: 'Fee Management', icon: LucideIcons.receipt),
      PanelMenuItem(title: 'Payroll', icon: LucideIcons.users),
      PanelMenuItem(title: 'Financial Reports', icon: LucideIcons.pieChart),
      PanelMenuItem(title: 'Messaging', icon: LucideIcons.messageSquare),
      PanelMenuItem(title: 'Logout', icon: LucideIcons.logOut),
    ];

    String panelTitle = "Dashboard";
    String subtitle = "Financial Dashboard";

    switch (_selectedIndex) {
      case 1:
        panelTitle = "Fee Management";
        subtitle = "Student Billing, Payments & Scholarships";
        break;
      case 2:
        panelTitle = "Payroll Processing";
        subtitle = "Faculty & Staff Salaries";
        break;
      case 3:
        panelTitle = "Financial Reports";
        subtitle = "Statements, Balance Sheets & Audit Logs";
        break;
      case 4:
        panelTitle = "Messaging Center";
        subtitle = "Conversations with students and admins";
        break;
      case 0:
      default:
        panelTitle = "Dashboard";
        subtitle = "Financial Health & Quick Stats";
        break;
    }

    final Widget panelContent = _selectedIndex == 4
        ? MessagingPanel(isDarkMode: _isDarkMode)
        : AccountingPanelContent(
            selectedIndex: _selectedIndex,
            isDarkMode: _isDarkMode,
          );

    return DashboardPanelTemplate(
      panelTitle: panelTitle,
      subtitle: subtitle,
      panelContent: panelContent,
      sidebarItems: sidebarItems,
      onLogout: widget.onLogout,
      isDarkMode: _isDarkMode,
      onMenuItemSelected: (index) {
        // There are 5 main items before Logout
        if (index < 5) setState(() => _selectedIndex = index);
      },
      selectedIndex: _selectedIndex,
      isSidebarExpanded: _isSidebarExpanded,
      onSidebarToggle: (val) => setState(() => _isSidebarExpanded = val),
      isAdminPanel: true,
      logoText: "UEMS ACCOUNTING",
      themeToggle: () => setState(() => _isDarkMode = !_isDarkMode),
    );
  }
}
