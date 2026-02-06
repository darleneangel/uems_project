import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
            "Admissions Intelligence & Recruitment",
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
                "ADMISSIONS_OFFICER",
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
                  "UEMS Admissions",
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
                _menuItem(LucideIcons.clipboardList, "Exams & Interviews", 2),
                _menuItem(LucideIcons.shieldCheck, "Document Verification", 3),
                _sidebarHeader("LIFECYCLE"),
                _menuItem(LucideIcons.mail, "Admission Letters", 4),
                _menuItem(LucideIcons.refreshCw, "Fee Coordination", 5),
                _menuItem(LucideIcons.database, "Registrar Transfer", 6),
                _sidebarHeader("ANALYTICS"),
                _menuItem(LucideIcons.barChart, "Recruitment Stats", 7),
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
        return _buildApplicationsPanel(panelColor, textColor);
      case 7:
        return _buildStatsPanel(panelColor, textColor);
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
            "Admissions Overview",
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
                "Total Applicants",
                "1,240",
                LucideIcons.users,
                aViolet,
                textColor,
              ),
              _statCard(
                "Pending Review",
                "142",
                LucideIcons.clock,
                Colors.orangeAccent,
                textColor,
              ),
              _statCard(
                "Admitted Status",
                "856",
                LucideIcons.checkCircle,
                success,
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

  // --- MODULE: APPLICATIONS ---
  Widget _buildApplicationsPanel(Color panelColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Application Processing",
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: "Search Applicants (Online/Offline)...",
                    prefixIcon: const Icon(LucideIcons.search),
                    filled: true,
                    fillColor: panelColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _actionIcon(LucideIcons.filter, panelColor),
            ],
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
                  "Processing Queue: Loading data...",
                  style: TextStyle(color: Colors.white24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MODULE: STATISTICS ---
  Widget _buildStatsPanel(Color panelColor, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.pieChart, color: aViolet, size: 64),
          const SizedBox(height: 24),
          Text(
            "Recruitment Analytics Engine",
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            "Acceptance Rates | Demographic Trends",
            style: TextStyle(color: Colors.white24),
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
        _quickActionButton("New Application", LucideIcons.userPlus, aViolet),
        _quickActionButton("Schedule Exams", LucideIcons.calendar, Colors.blue),
        _quickActionButton("Generate Letters", LucideIcons.mail, success),
        _quickActionButton(
          "Registrar Transfer",
          LucideIcons.database,
          Colors.orange,
        ),
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

  Widget _actionIcon(IconData icon, Color panelColor) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: panelColor,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Icon(icon, color: Colors.blueGrey),
  );

  Widget _headerAction(IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, color: color, size: 20),
  );
}
