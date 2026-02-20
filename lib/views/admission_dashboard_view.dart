import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../components/admission_panel_content.dart';

class AdmissionDashboardView extends StatefulWidget {
  final VoidCallback onLogout;
  const AdmissionDashboardView({super.key, required this.onLogout});

  @override
  State<AdmissionDashboardView> createState() => _AdmissionDashboardViewState();
}

class _AdmissionDashboardViewState extends State<AdmissionDashboardView> {
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

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out of the system?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text("LOG OUT"),
          ),
        ],
      ),
    );
  }

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
                        child: AdmissionPanelContent(
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
      padding: const EdgeInsets.only(left: 24, right: 0),
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
              "Admissions Office",
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
            indent: 20,
            endIndent: 20,
          ),
          const SizedBox(width: 24),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "ADMISSIONS_OFFICER",
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
            child: const Icon(
              LucideIcons.userPlus,
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
                  "UEMSSP Admissions",
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
                _menuItem(LucideIcons.layoutDashboard, "Overview", 0),
                _sidebarHeader("APPLICANT MANAGEMENT"),
                _menuItem(LucideIcons.fileText, "Applications", 1),
                _menuItem(LucideIcons.clipboardList, "Interview Management", 2),
                _menuItem(LucideIcons.shieldCheck, "Document Verification", 3),
                _sidebarHeader("ENROLLMENT"),
                _menuItem(LucideIcons.userCheck, "Enrollment Verification", 5),
                _sidebarHeader("MESSAGES"),
                _menuItem(LucideIcons.mail, "Admission Letters", 4),
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
<<<<<<< HEAD
=======
          const Divider(color: Colors.white10),
          _menuItem(
            LucideIcons.logOut,
            "Logout System",
            8,
            isDestructive: true,
            onTap: _confirmLogout,
          ),
          const SizedBox(height: 20),
>>>>>>> ade0bf853b14f953354f82427841c11017197893
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
    final inactiveColor = isDestructive ? Colors.redAccent : Colors.blueGrey;
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
          color: isSelected ? activeColor : inactiveColor,
          size: 20,
        ),
        title: _isSidebarExpanded
            ? Text(
                title,
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.white : inactiveColor,
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
