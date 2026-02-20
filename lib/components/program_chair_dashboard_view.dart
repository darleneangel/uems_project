import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'program_chair_panel_content.dart';

class ProgramChairDashboardView extends StatefulWidget {
  final VoidCallback onLogout;
  const ProgramChairDashboardView({super.key, required this.onLogout});

  @override
  State<ProgramChairDashboardView> createState() =>
      _ProgramChairDashboardViewState();
}

class _ProgramChairDashboardViewState extends State<ProgramChairDashboardView> {
  bool _isDarkMode = true;
  bool _isSidebarExpanded = true;
  int _selectedIndex = 0;

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
    final bgColor = _isDarkMode ? tDark : const Color(0xFFF8FAFC);
    final textColor = _isDarkMode ? Colors.white : pViolet;

    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          _buildSidebar(textColor),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(textColor),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: ProgramChairPanelContent(
                          key: ValueKey(_selectedIndex),
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

  Widget _buildTopBar(Color textColor) {
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
            "Academic Leadership Console",
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
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
          const SizedBox(width: 24),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "PROGRAM_CHAIR_HUB",
                style: GoogleFonts.inter(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                "Department Head",
                style: GoogleFonts.inter(
                  color: success,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          const CircleAvatar(
            backgroundColor: aViolet,
            child: Icon(
              LucideIcons.graduationCap,
              color: Colors.white,
              size: 18,
            ),
          ),
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
          _buildLogo(textColor),
          const SizedBox(height: 40),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _menuItem(LucideIcons.layoutDashboard, "Dashboard", 0),
                _sidebarHeader("ACADEMIC MANAGEMENT"),
                _menuItem(LucideIcons.bookOpen, "Curriculum Review", 1),
                _menuItem(LucideIcons.users, "Faculty Load", 2),
                _sidebarHeader("STUDENT AFFAIRS"),
                _menuItem(LucideIcons.fileText, "Final Assessment", 3),
                _menuItem(LucideIcons.mail, "Messaging", 4),
              ],
            ),
          ),
          const Divider(color: Colors.white10),
          _menuItem(
            LucideIcons.logOut,
            "Logout",
            9,
            isDestructive: true,
            onTap: widget.onLogout,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLogo(Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: aViolet.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(LucideIcons.shield, color: aViolet, size: 24),
        ),
        if (_isSidebarExpanded) ...[
          const SizedBox(width: 12),
          Text(
            "UEMSSP Program Chair",
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
}
