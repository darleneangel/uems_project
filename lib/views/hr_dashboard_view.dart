import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../components/hr_panel_content.dart';

class HRDashboardView extends StatefulWidget {
  final VoidCallback onLogout;
  final Map<String, dynamic> userData;

  const HRDashboardView(
      {super.key, required this.onLogout, required this.userData});

  @override
  State<HRDashboardView> createState() => _HRDashboardViewState();
}

class _HRDashboardViewState extends State<HRDashboardView> {
  // Navigation & Theme State
  bool _isDarkMode = true;
  bool _isSidebarExpanded = true;
  int _selectedIndex = 0;

  // Visual Palette
  static const Color pViolet = Color(0xFF2E1065);
  static const Color tDark = Color(0xFF0F071D);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color success = Color(0xFF69F0AE);

  void _toggleSidebar() =>
      setState(() => _isSidebarExpanded = !_isSidebarExpanded);
  void _toggleTheme() => setState(() => _isDarkMode = !_isDarkMode);

  Future<void> _confirmLogout() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDarkMode ? surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Confirm Logout",
          style: GoogleFonts.inter(
            color: _isDarkMode ? Colors.white : pViolet,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          "Are you sure you want to logout from the HR system?",
          style: GoogleFonts.inter(
            color: _isDarkMode ? Colors.white70 : Colors.blueGrey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode ? tDark : const Color(0xFFF8FAFC);
    final textColor = _isDarkMode ? Colors.white : pViolet;

    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          // 1. MODULAR SIDEBAR
          _buildSidebar(textColor),

          // 2. MAIN WORKSPACE
          Expanded(
            child: Column(
              children: [
                _buildTopBar(textColor),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: HRPanelContent(
                      selectedIndex: _selectedIndex,
                      isDarkMode: _isDarkMode,
                      userData: widget.userData,
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
            onPressed: _toggleSidebar,
          ),
          const SizedBox(width: 16),
          Text(
            "Personnel & Human Resources Management",
            style: GoogleFonts.inter(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5),
          ),
          const Spacer(),
          IconButton(
              onPressed: _toggleTheme,
              icon: Icon(_isDarkMode ? LucideIcons.sun : LucideIcons.moon,
                  color: aViolet)),
          const SizedBox(width: 24),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                  "${widget.userData['fn']} ${widget.userData['ln']}"
                      .toUpperCase(),
                  style: GoogleFonts.inter(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              const Text("HR ADMINISTRATOR",
                  style: TextStyle(
                      color: success,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 12),
          const CircleAvatar(
              backgroundColor: aViolet,
              child:
                  Icon(LucideIcons.userCheck, color: Colors.white, size: 18)),
        ],
      ),
    );
  }

  Widget _buildSidebar(Color textColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isSidebarExpanded ? 280 : 85,
      color: _isDarkMode ? pViolet : const Color(0xFFF1F5F9),
      child: Column(
        children: [
          const SizedBox(height: 30),
          // Institutional Branding
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: aViolet.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(LucideIcons.shieldCheck,
                    color: aViolet, size: 24),
              ),
              if (_isSidebarExpanded) ...[
                const SizedBox(width: 12),
                Text("UEMSSP HR",
                    style: GoogleFonts.orbitron(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ],
          ),
          const SizedBox(height: 40),
          // Navigation Menu
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _menuItem(LucideIcons.layoutDashboard, "HR Overview", 0),
                _sidebarHeader("WORKFORCE"),
                _menuItem(LucideIcons.users, "Staff Directory", 1),
                _menuItem(LucideIcons.fileSignature, "Attendance Logs",
                    3), // Same index, handles sub-logic

                _menuItem(LucideIcons.clock, "Leave Requests", 5),
                _menuItem(LucideIcons.monitor, "Payroll", 6),
                _menuItem(LucideIcons.list, "Employee Records",
                    7), // Same index, handles sub-logic
                _sidebarHeader("COMMUNICATION"),
                _menuItem(
                    LucideIcons.messagesSquare, "Institutional Messenger", 2),
                _menuItem(LucideIcons.facebook, "Profile", 4)
              ],
            ),
          ),
          const Divider(color: Colors.white10, indent: 20, endIndent: 20),
          _menuItem(LucideIcons.logOut, "Logout", -1,
              isDestructive: true, onTap: _confirmLogout),
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
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 13))
            : null,
      ),
    );
  }

  Widget _sidebarHeader(String title) {
    if (!_isSidebarExpanded) return const SizedBox(height: 20);
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 10, top: 20),
      child: Text(title,
          style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.blueGrey.withOpacity(0.5),
              letterSpacing: 1.5)),
    );
  }
}
