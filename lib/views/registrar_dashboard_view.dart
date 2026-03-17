import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uems_project/components/registrar_panel_content.dart';
import '../components/smart_search_widget.dart';

class RegistrarDashboardView extends StatefulWidget {
  final VoidCallback onLogout;
  const RegistrarDashboardView({super.key, required this.onLogout});

  @override
  State<RegistrarDashboardView> createState() => _RegistrarDashboardViewState();
}

class _RegistrarDashboardViewState extends State<RegistrarDashboardView> {
  bool _isDarkMode = true;
  bool _isSidebarExpanded = true;
  int _selectedIndex = 0;

  // Map sidebar index to the Hub's panel types
  final List<String> _panelTypes = [
    'overview', // 0
    'records', // 1
    'enrollment', // 2
    'grades', // 3
    'credentials', // 4
    'eligibility', // 5
    'curriculum', // 6
    'reports', // 7
    'messages', // 8
    'requests', // 9
    'audit', // 10
  ];

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
    final bgColor = _isDarkMode ? tDark : const Color(0xFFF8FAFC);
    final sideColor = _isDarkMode ? pViolet : const Color(0xFFF1F5F9);
    final textColor = _isDarkMode ? Colors.white : pViolet;
    final subTextColor = _isDarkMode ? Colors.white54 : Colors.blueGrey;

    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          // 1. SIDEBAR
          _buildSidebar(sideColor, textColor, subTextColor),

          // 2. MAIN PANEL
          Expanded(
            child: Column(
              children: [
                _buildTopBar(textColor, subTextColor),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    // THE BRIDGE: This calls the modular Registrar Hub
                    child: RegistrarPanelContent(
                      isDarkMode: _isDarkMode,
                      panelType: _panelTypes[_selectedIndex],
                      userData: {}, // Replace with actual user data if available
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
            "Registrar Office",
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 24),
          // Smart Search Widget
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SmartSearchWidget(
                isDarkMode: _isDarkMode,
                defaultDepartment: 'Registrar',
                onResultTap: (result) {
                  // Handle result tap - e.g., navigate to specific panel
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Selected: ${result.title}'),
                      backgroundColor: aViolet,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _toggleTheme,
            icon: Icon(
              _isDarkMode ? LucideIcons.sun : LucideIcons.moon,
              color: aViolet,
            ),
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
                "REGISTRAR_ADMIN",
                style: GoogleFonts.inter(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                "Verified Session",
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
              LucideIcons.shieldCheck,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(Color sideColor, Color textColor, Color subTextColor) {
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
                _menuItem(LucideIcons.layoutDashboard, "Dashboard", 0),
                _sidebarHeader("RECORDS"),
                _menuItem(LucideIcons.contact, "Student Directory", 1),
                _menuItem(LucideIcons.clipboardCheck, "Enrollment Verify", 2),
                _sidebarHeader("ACADEMICS"),
                _menuItem(LucideIcons.star, "Grade Management", 3),
                _menuItem(LucideIcons.fileText, "Transcripts & TOR", 4),
                _sidebarHeader("SYSTEM"),
                _menuItem(LucideIcons.mail, "Student Inbox", 8),
                _menuItem(LucideIcons.fileSignature, "Document Requests", 9),
                _menuItem(LucideIcons.history, "Institutional Audit", 10),
              ],
            ),
          ),
          const Divider(color: Colors.white10),
          _menuItem(
            LucideIcons.logOut,
            "Logout",
            10,
            isDestructive: true,
            onTap: _confirmLogout,
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
    final inactiveColor = isDestructive ? Colors.redAccent : Colors.blueGrey;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? aViolet.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap ?? () => setState(() => _selectedIndex = index),
        visualDensity: VisualDensity.compact,
        leading: Icon(
          icon,
          color: isSelected ? activeColor : inactiveColor,
          size: 18,
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

  Widget _buildLogo(Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(LucideIcons.bookOpen, color: aViolet, size: 24),
        if (_isSidebarExpanded) ...[
          const SizedBox(width: 12),
          Text(
            "UEMSSP Registrar",
            style: GoogleFonts.orbitron(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ],
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
