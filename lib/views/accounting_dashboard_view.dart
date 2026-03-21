import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../components/accounting_panels/fee_management_panel.dart';
import '../components/accounting_panels/payroll_panel.dart';
import '../components/accounting_panels/financial_reports_panel.dart';
import '../components/accounting_panels/accounting_overview_panel.dart';
import '../components/accounting_panels/registration_payment_panel.dart';
import '../components/shared/messaging_panel.dart';
import '../components/accounting_panels/tuition_assessment_panel.dart';
import '../components/shared/staff_profile_portal.dart';
import '../components/accounting_panels/accounting_payroll_manager_panel.dart';
import '../services/supabase_service.dart';
import '../components/accounting_panels/clearance_assessment_terminal_panel.dart';
import '../components/accounting_panels/student_payment_portal_panel.dart';

class AccountingDashboardView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onLogout;
  const AccountingDashboardView(
      {super.key, required this.onLogout, required this.userData});

  @override
  State<AccountingDashboardView> createState() =>
      _AccountingDashboardViewState();
}

class _AccountingDashboardViewState extends State<AccountingDashboardView> {
  bool _isDarkMode = true;
  bool _isSidebarExpanded = true;
  int _selectedIndex = 0;

  static const Color pViolet = Color(0xFF2E1065);
  static const Color tDark = Color(0xFF0F071D);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color success = Color(0xFF69F0AE);

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode ? tDark : const Color(0xFFF8FAFC);
    final sideColor = _isDarkMode ? pViolet : const Color(0xFFF1F5F9);
    final textColor = _isDarkMode ? Colors.white : pViolet;

    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          _buildSidebar(sideColor, textColor),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(textColor),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    child: _getActivePanel(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getActivePanel() {
    switch (_selectedIndex) {
      case 1:
        return FeeManagementPanel(
          isDarkMode: _isDarkMode,
          userData: widget.userData,
        );
      case 3:
        return AccountingPayrollManager(
            isDarkMode: _isDarkMode, userData: widget.userData);
      case 2:
        return FinancialReportsPanel(isDarkMode: _isDarkMode);
      case 4:
        return RegistrationPaymentPanel(
            isDarkMode: _isDarkMode, userData: widget.userData);
      case 5:
        return TuitionAssessmentPanel(
            isDarkMode: _isDarkMode, userData: widget.userData);
      case 6:
        return MessagingPanel(
            isDarkMode: _isDarkMode, userData: widget.userData);
      case 7:
        return StaffProfilePortal(
          isDarkMode: _isDarkMode,
          userData: widget.userData,
        );
      case 8:
        return StudentPaymentPortal(
            isDarkMode: _isDarkMode, userData: widget.userData);
      case 9:
        return ClearanceAssessmentTerminal(
            isDarkMode: _isDarkMode, userData: widget.userData);
      case 0:
      default:
        return AccountingOverviewPanel(isDarkMode: _isDarkMode);
    }
  }

  Widget _buildTopBar(Color textColor) {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: _isDarkMode ? tDark : Colors.white,
        border: Border(
            bottom: BorderSide(
                color: _isDarkMode ? Colors.white10 : Colors.black12)),
      ),
      child: Row(
        children: [
          IconButton(
              icon: Icon(
                  _isSidebarExpanded
                      ? LucideIcons.menu
                      : LucideIcons.chevronRight,
                  color: textColor),
              onPressed: () =>
                  setState(() => _isSidebarExpanded = !_isSidebarExpanded)),
          const SizedBox(width: 16),
          Text("Financial Core Interface",
              style: GoogleFonts.inter(
                  color: textColor, fontSize: 18, fontWeight: FontWeight.w900)),
          const Spacer(),
          IconButton(
              onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
              icon: Icon(_isDarkMode ? LucideIcons.sun : LucideIcons.moon,
                  color: aViolet)),
          const SizedBox(width: 24),
          const VerticalDivider(
              color: Colors.white10, indent: 20, endIndent: 20),
          const SizedBox(width: 24),
          Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("CHIEF_ACCOUNTANT",
                    style: GoogleFonts.inter(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                Text("Full Ledger Access",
                    style: GoogleFonts.inter(
                        color: success,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ]),
          const SizedBox(width: 12),
          const CircleAvatar(
              backgroundColor: aViolet,
              child: Icon(LucideIcons.wallet, color: Colors.white, size: 18)),
        ],
      ),
    );
  }

  Widget _buildSidebar(Color sideColor, Color textColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isSidebarExpanded ? 260 : 85,
      color: sideColor,
      child: Column(
        children: [
          const SizedBox(height: 30),
          _buildLogo(textColor),
          const SizedBox(height: 40),
          Expanded(
              child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                _menuItem(LucideIcons.layoutDashboard, "Overview", 0),
                _sidebarHeader("COLLECTIONS"),
                _menuItem(LucideIcons.receipt, "Fee Management", 1),
                _menuItem(LucideIcons.pieChart, "Tuition Assessment", 5),
                _menuItem(LucideIcons.piggyBank, "Enrollment Payment", 4),
                _menuItem(LucideIcons.wallet, "Student Payment Portal", 8),
                _menuItem(LucideIcons.fileCheck, "Financial Clearance", 9),
                _sidebarHeader("INTERNAL"),
                _menuItem(LucideIcons.users, "Employee Payroll", 3),
                _sidebarHeader("MESSAGES"),
                _menuItem(LucideIcons.messageCircle, "Messaging", 6),
                _menuItem(LucideIcons.facebook, "Profile", 7),
              ])),
          const Divider(color: Colors.white10),
          _menuItem(LucideIcons.logOut, "Logout System", 8,
              isDestructive: true, onTap: widget.onLogout),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, int index,
      {bool isDestructive = false, VoidCallback? onTap}) {
    bool isSelected = _selectedIndex == index;
    final activeColor = isDestructive ? Colors.redAccent : aViolet;
    return Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
            color: isSelected ? aViolet.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(14)),
        child: ListTile(
            onTap: onTap ?? () => setState(() => _selectedIndex = index),
            visualDensity: VisualDensity.compact,
            leading: Icon(icon,
                color: isSelected ? activeColor : Colors.blueGrey, size: 20),
            title: _isSidebarExpanded
                ? Text(title,
                    style: GoogleFonts.inter(
                        color: isSelected ? Colors.white : Colors.blueGrey,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w500,
                        fontSize: 13))
                : null));
  }

  Widget _sidebarHeader(String title) => _isSidebarExpanded
      ? Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 10, top: 20),
          child: Text(title,
              style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.blueGrey.withOpacity(0.5),
                  letterSpacing: 1.5)))
      : const SizedBox(height: 20);
  Widget _buildLogo(Color textColor) =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(LucideIcons.landmark, color: aViolet, size: 24),
        if (_isSidebarExpanded) ...[
          const SizedBox(width: 12),
          Text("UEMS Finance",
              style: GoogleFonts.orbitron(
                  color: textColor, fontWeight: FontWeight.bold, fontSize: 14))
        ]
      ]);
}
