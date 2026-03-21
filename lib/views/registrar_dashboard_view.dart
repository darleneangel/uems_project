import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../components/registrar_panel_content.dart';

class RegistrarDashboardView extends StatefulWidget {
  final VoidCallback onLogout;
  final Map<String, dynamic> userData;

  const RegistrarDashboardView(
      {super.key, required this.onLogout, required this.userData});

  @override
  State<RegistrarDashboardView> createState() => _RegistrarDashboardViewState();
}

class _RegistrarDashboardViewState extends State<RegistrarDashboardView> {
  // Navigation & Theme State
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

  // Institutional Palette
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
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Secure Logout",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
            "Are you sure you want to terminate this administrative session?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onLogout();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white),
            child: const Text("LOGOUT SYSTEM"),
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
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: RegistrarPanelContent(
                      key: ValueKey(_selectedIndex),
                      isDarkMode: _isDarkMode,
                      panelType: _panelTypes[_selectedIndex],
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
    // 🛰️ IDENTITY RESOLUTION: Fetching from DB context
    final String fullName =
        "${widget.userData['fn'] ?? ''} ${widget.userData['ln'] ?? ''}"
            .toUpperCase();
    final String role =
        (widget.userData['role'] ?? 'REGISTRAR').toString().toUpperCase();

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
            "Registrar Intelligence Terminal",
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
                color: aViolet),
          ),
          const SizedBox(width: 20),
          _headerAction(LucideIcons.bell, textColor.withOpacity(0.5)),
          const SizedBox(width: 24),
          const VerticalDivider(
              color: Colors.white10, indent: 20, endIndent: 20),
          const SizedBox(width: 24),

          // 🛰️ DYNAMIC PROFILE: Database Connected
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(fullName,
                  style: GoogleFonts.inter(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              Text(role,
                  style: GoogleFonts.inter(
                      color: success,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ],
          ),
          const SizedBox(width: 12),
          const CircleAvatar(
            backgroundColor: aViolet,
            child: Icon(LucideIcons.shieldCheck, color: Colors.white, size: 18),
          ),
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
                _sidebarHeader("RECORDS"),
                _menuItem(LucideIcons.users, "Student Directory", 1),
                _menuItem(LucideIcons.clipboardCheck, "Enrollment Verify", 2),
                _sidebarHeader("ACADEMICS"),
                _menuItem(LucideIcons.star, "Grade Management", 3),
                _sidebarHeader("COMMUNICATIONS"),
                _menuItem(LucideIcons.mail, "Messaging", 8),
                _menuItem(LucideIcons.fileSignature, "Document Requests", 9),
                _sidebarHeader("SYSTEM"),
                _menuItem(LucideIcons.history, "Institutional Audit", 10),
              ],
            ),
          ),
          const Divider(color: Colors.white10),
          _menuItem(LucideIcons.logOut, "Logout System", 99,
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
        borderRadius: BorderRadius.circular(14),
      ),
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

  Widget _buildLogo(Color textColor) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.bookOpen, color: aViolet, size: 24),
          if (_isSidebarExpanded) ...[
            const SizedBox(width: 12),
            Text("UEMS Registrar",
                style: GoogleFonts.orbitron(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ]
        ],
      );

  Widget _headerAction(IconData icon, Color color) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color.withOpacity(0.05), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      );
}
