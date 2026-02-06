import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AccountingDashboardView extends StatefulWidget {
  final VoidCallback onLogout;
  const AccountingDashboardView({super.key, required this.onLogout});

  @override
  State<AccountingDashboardView> createState() =>
      _AccountingDashboardViewState();
}

class _AccountingDashboardViewState extends State<AccountingDashboardView> {
  // Navigation & Theme State
  bool _isDarkMode = true;
  bool _isSidebarExpanded = true;
  int _selectedIndex = 0;

  // Standardized Violet/Plum Palette
  static const Color pViolet = Color(0xFF2E1065);
  static const Color tDark = Color(0xFF0F071D);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color success = Color(0xFF69F0AE);

  void _toggleSidebar() =>
      setState(() => _isSidebarExpanded = !_isSidebarExpanded);
  void _toggleTheme() => setState(() => _isDarkMode = !_isDarkMode);

  @override
  Widget build(BuildContext context) {
    // Dynamic theme colors
    final bgColor = _isDarkMode ? tDark : const Color(0xFFF8FAFC);
    final panelColor = _isDarkMode ? surfaceDark : Colors.white;
    final textColor = _isDarkMode ? Colors.white : pViolet;
    final subTextColor = _isDarkMode ? Colors.white54 : Colors.blueGrey;

    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          // 1. FIXED TOGGLEABLE SIDEBAR
          _buildSidebar(panelColor, textColor, subTextColor),

          // 2. MAIN PANEL AREA
          Expanded(
            child: Column(
              children: [
                _buildTopBar(textColor, subTextColor),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildPanelContent(
                      panelColor,
                      textColor,
                      subTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(Color textColor, Color subTextColor) {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: _isDarkMode ? tDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _isDarkMode ? Colors.white10 : Colors.black12,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isSidebarExpanded ? LucideIcons.menu : LucideIcons.chevronRight,
              color: textColor,
            ),
            onPressed: _toggleSidebar,
          ),
          const SizedBox(width: 16),
          Text(
            "Accounting Office Control Panel",
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          // Theme Toggle
          IconButton(
            onPressed: _toggleTheme,
            icon: Icon(
              _isDarkMode ? LucideIcons.sun : LucideIcons.moon,
              color: aViolet,
            ),
            tooltip: "Toggle Visual Mode",
          ),
          const SizedBox(width: 20),
          _headerAction(LucideIcons.bell, subTextColor),
          const SizedBox(width: 24),
          const VerticalDivider(
            color: Colors.white10,
            indent: 20,
            endIndent: 20,
          ),
          const SizedBox(width: 24),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "ACCOUNTING_ADMIN",
                style: GoogleFonts.inter(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                "Verified Access",
                style: GoogleFonts.inter(
                  color: success,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: aViolet,
            child: const Icon(
              LucideIcons.wallet,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(Color panelColor, Color textColor, Color subTextColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isSidebarExpanded ? 280 : 85,
      color: _isDarkMode ? pViolet : const Color(0xFFF1F5F9),
      child: Column(
        children: [
          const SizedBox(height: 30),
          // Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: aViolet.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.landmark,
                  color: aViolet,
                  size: 24,
                ),
              ),
              if (_isSidebarExpanded) ...[
                const SizedBox(width: 12),
                Text(
                  "UEMS Finance",
                  style: GoogleFonts.orbitron(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 40),
          // Menu Items based on Core Functions
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _menuItem(LucideIcons.layoutDashboard, "Overview", 0),
                _sidebarHeader("STUDENT FINANCIALS"),
                _menuItem(LucideIcons.receipt, "Fee Management", 1),
                _menuItem(LucideIcons.creditCard, "Online Payments", 2),
                _menuItem(LucideIcons.award, "Scholarships & Aid", 3),
                _sidebarHeader("INTERNAL OPERATIONS"),
                _menuItem(LucideIcons.users, "Payroll Processing", 4),
                _menuItem(LucideIcons.shoppingCart, "Vendor Payments", 5),
                _sidebarHeader("REPORTING"),
                _menuItem(LucideIcons.pieChart, "Financial Reports", 6),
                _menuItem(LucideIcons.shieldCheck, "Audit & Compliance", 7),
              ],
            ),
          ),
          const Divider(color: Colors.white10),
          _menuItem(
            LucideIcons.logOut,
            "Logout System",
            8,
            isDestructive: true,
            onTap: widget.onLogout,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String title,
    int index, {
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    bool isSelected = _selectedIndex == index;
    final activeColor = isDestructive ? Colors.redAccent : aViolet;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? aViolet.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: onTap ?? () => setState(() => _selectedIndex = index),
        visualDensity: VisualDensity.compact,
        leading: Icon(
          icon,
          color: isSelected ? activeColor : Colors.blueGrey,
          size: 20,
        ),
        title: _isSidebarExpanded
            ? Text(
                title,
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.white : Colors.blueGrey,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 13,
                ),
              )
            : null,
      ),
    );
  }

  Widget _sidebarHeader(String title) {
    if (!_isSidebarExpanded) return const SizedBox(height: 20);
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 10, top: 20),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: Colors.blueGrey.withOpacity(0.5),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildPanelContent(
    Color panelColor,
    Color textColor,
    Color subTextColor,
  ) {
    switch (_selectedIndex) {
      case 1:
        return _buildFeeManagementPanel(panelColor, textColor);
      case 4:
        return _buildPayrollPanel(panelColor, textColor);
      case 6:
        return _buildReportsPanel(panelColor, textColor);
      case 0:
      default:
        return _buildOverviewPanel(panelColor, textColor);
    }
  }

  // --- MODULE: OVERVIEW ---
  Widget _buildOverviewPanel(Color panelColor, Color textColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Financial Overview",
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _statCard(
                "Total Revenue",
                "₱4,821,000",
                LucideIcons.trendingUp,
                success,
                textColor,
              ),
              _statCard(
                "Unpaid Balances",
                "₱240,500",
                LucideIcons.alertCircle,
                Colors.orangeAccent,
                textColor,
              ),
              _statCard(
                "Active Grants",
                "152",
                LucideIcons.award,
                Colors.blueAccent,
                textColor,
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildTransactionTable(panelColor, textColor),
        ],
      ),
    );
  }

  // --- MODULE: STUDENT FEES ---
  Widget _buildFeeManagementPanel(Color panelColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Student Fee Management",
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        "Create Invoice",
                        LucideIcons.filePlus,
                        aViolet,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _actionButton(
                        "Reconcile Bank",
                        LucideIcons.refreshCw,
                        success,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _actionButton(
                        "Send Reminders",
                        LucideIcons.send,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- MODULE: PAYROLL ---
  Widget _buildPayrollPanel(Color panelColor, Color textColor) {
    return Center(
      child: Text(
        "Payroll Engine Loaded: Processing Faculty Salaries...",
        style: TextStyle(color: textColor.withOpacity(0.5)),
      ),
    );
  }

  // --- MODULE: REPORTS ---
  Widget _buildReportsPanel(Color panelColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Row(
            children: [
              _reportCard(
                "Income Statement",
                LucideIcons.fileText,
                panelColor,
                textColor,
              ),
              _reportCard(
                "Balance Sheet",
                LucideIcons.fileBarChart,
                panelColor,
                textColor,
              ),
              _reportCard(
                "Cash Flow",
                LucideIcons.activity,
                panelColor,
                textColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _statCard(
    String label,
    String val,
    IconData icon,
    Color color,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _isDarkMode ? surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isDarkMode ? Colors.white10 : Colors.black12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 15),
            Text(
              val,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Color color) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    );
  }

  Widget _reportCard(
    String title,
    IconData icon,
    Color panelColor,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Icon(icon, color: aViolet, size: 40),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Generate PDF",
              style: TextStyle(color: aViolet, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTable(Color panelColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recent Fee Settlements",
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                "Real-time Ledger Integration: Active",
                style: TextStyle(color: Colors.white24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerAction(IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, color: color, size: 20),
  );
}
