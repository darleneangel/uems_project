import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../components/accounting_panel_content.dart';

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
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: AccountingPanelContent(
                          selectedIndex: _selectedIndex,
                          isDarkMode: _isDarkMode,
                        ),
                      ),
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
      padding: const EdgeInsets.only(left: 24, right: 16),
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
          Expanded(
            child: Text(
              "Accounting Office",
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const VerticalDivider(
            color: Colors.white10,
            indent: 25,
            endIndent: 25,
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Accounting Officer",
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  "Verified Access",
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: success,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: aViolet,
            child: const Icon(LucideIcons.user, color: Colors.white, size: 18),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: aViolet.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.school, color: aViolet, size: 24),
              ),
              if (_isSidebarExpanded) ...[
                const SizedBox(width: 12),
                Text(
                  "UEMSSP ACCOUNTING",
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _menuItem(LucideIcons.layoutDashboard, "Dashboard", 0),
                _sidebarHeader("FEES"),
                _menuItem(LucideIcons.fileText, "Fee Management", 1),
                _menuItem(LucideIcons.clipboardList, "Financial Reports", 2),
                _menuItem(LucideIcons.bookOpen, "Subject Load Fee", 3),
                _sidebarHeader("MESSAGES"),
                _menuItem(LucideIcons.mail, "Messaging", 4),
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
          ),
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

  Widget _headerAction(IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, color: color, size: 20),
  );
}
