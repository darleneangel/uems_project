import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HrDashboardView extends StatefulWidget {
  final VoidCallback onLogout;
  const HrDashboardView({super.key, required this.onLogout});

  @override
  State<HrDashboardView> createState() => _HrDashboardViewState();
}

class _HrDashboardViewState extends State<HrDashboardView> {
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
            "heuheuhuehueh try",
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _toggleTheme,
            icon: Icon(
              _isDarkMode ? LucideIcons.sun : LucideIcons.moon,
              color: aViolet,
            ),
            tooltip: "Switch Theme",
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
                "PROF_MANALASTAS",
                style: GoogleFonts.inter(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                "Academic Faculty",
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
                child: const Icon(
                  LucideIcons.graduationCap,
                  color: aViolet,
                  size: 24,
                ),
              ),
              if (_isSidebarExpanded) ...[
                const SizedBox(width: 12),
                Text(
                  "UEMS Teacher",
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
                _menuItem(LucideIcons.layoutDashboard, "TESTING", 0),
                _sidebarHeader("INSTRUCTION"),
                _menuItem(LucideIcons.calendar, "Classes & Schedules", 1),
                _menuItem(LucideIcons.uploadCloud, "Syllabi & Materials", 2),
                _menuItem(LucideIcons.bookOpen, "Learning Resources", 3),
                _sidebarHeader("ACADEMICS"),
                _menuItem(
                  LucideIcons.clipboardCheck,
                  "Attendance & Participation",
                  4,
                ),
                _menuItem(LucideIcons.star, "Grade Recording", 5),
                _menuItem(LucideIcons.filePieChart, "Progress Reports", 6),
                _sidebarHeader("FACULTY SERVICES"),
                _menuItem(LucideIcons.messagesSquare, "Communications", 7),
                _menuItem(LucideIcons.briefcase, "Teaching Load & Payroll", 8),
              ],
            ),
          ),
          const Divider(color: Colors.white10),
          _menuItem(
            LucideIcons.logOut,
            "Logout System",
            9,
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
        return _buildSchedulePanel(panelColor, textColor);
      case 5:
        return _buildGradingPanel(panelColor, textColor);
      case 8:
        return _buildFacultyServicesPanel(panelColor, textColor);
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
            "Faculty Overview",
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
                "Students Taught",
                "185",
                LucideIcons.users,
                aViolet,
                textColor,
              ),
              _statCard(
                "Grading Progress",
                "72%",
                LucideIcons.trendingUp,
                success,
                textColor,
              ),
              _statCard(
                "Classes Today",
                "4",
                LucideIcons.calendar,
                Colors.blueAccent,
                textColor,
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildActionGrid(panelColor, textColor),
        ],
      ),
    );
  }

  // --- MODULE: SCHEDULES ---
  Widget _buildSchedulePanel(Color panelColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Assigned Courses & Schedules",
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text(
                  "Loading Timetable...",
                  style: TextStyle(color: Colors.white24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MODULE: GRADING ---
  Widget _buildGradingPanel(Color panelColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Grade Recording Hub",
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Select class to encode grades for assignments and exams:",
            style: TextStyle(color: textColor.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _classCard(
                  "System Integration 101",
                  "BSCS-4A",
                  panelColor,
                  textColor,
                ),
                _classCard(
                  "Software Engineering",
                  "BSCS-3B",
                  panelColor,
                  textColor,
                ),
                _classCard("Data Structures", "BSCS-2A", panelColor, textColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- MODULE: HR & PAYROLL ---
  Widget _buildFacultyServicesPanel(Color panelColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Faculty Services & HR",
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _serviceCard(
                "Payroll & Payslips",
                LucideIcons.wallet,
                panelColor,
                textColor,
              ),
              _serviceCard(
                "Teaching Load Report",
                LucideIcons.fileText,
                panelColor,
                textColor,
              ),
              _serviceCard(
                "HR Information",
                LucideIcons.userCircle,
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

  Widget _buildActionGrid(Color panelColor, Color textColor) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 3.5,
      children: [
        _quickActionButton("Post Announcement", LucideIcons.megaphone, aViolet),
        _quickActionButton("Upload Resources", LucideIcons.share2, Colors.blue),
        _quickActionButton(
          "Generate Progress Report",
          LucideIcons.filePieChart,
          success,
        ),
        _quickActionButton("Exam Schedules", LucideIcons.clock, Colors.orange),
      ],
    );
  }

  Widget _quickActionButton(String label, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: _isDarkMode ? surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: TextStyle(
            color: _isDarkMode ? Colors.white : pViolet,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          LucideIcons.chevronRight,
          size: 16,
          color: Colors.white24,
        ),
        onTap: () {},
      ),
    );
  }

  Widget _classCard(
    String name,
    String section,
    Color panelColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.book, color: aViolet, size: 20),
          const SizedBox(width: 15),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                section,
                style: const TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          const Icon(LucideIcons.arrowRight, color: Colors.white12, size: 16),
        ],
      ),
    );
  }

  Widget _serviceCard(
    String title,
    IconData icon,
    Color panelColor,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: aViolet, size: 32),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Access Details",
              style: TextStyle(color: aViolet, fontSize: 11),
            ),
          ],
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
