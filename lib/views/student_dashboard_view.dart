import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../components/dashboard_panel_template.dart';
import '../components/student_panel_content.dart';

class StudentDashboardView extends StatefulWidget {
  final VoidCallback? onLogout;
  const StudentDashboardView({super.key, this.onLogout});

  @override
  State<StudentDashboardView> createState() => _StudentDashboardViewState();
}

class _StudentDashboardViewState extends State<StudentDashboardView> {
  // Theme state
  bool _isDarkMode = true;
  bool _isSidebarExpanded = true;
  int _selectedIndex = 0;
  
  // Panel mapping
  final List<String> _panelTypes = [
    'dashboard',
    'subject_load',
    'assessment',
    'grade_book',
    'clearance',
    'profile',
    'health_declaration',
  ];

  // Violet Theme Colors (Dark)
  static const Color pViolet = Color(0xFF2E1065);
  static const Color tDark = Color(0xFF0F071D);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);

  // Layout logic
  void _toggleSidebar() =>
      setState(() => _isSidebarExpanded = !_isSidebarExpanded);

  @override
  Widget build(BuildContext context) {
    if (_selectedIndex == 0) {
      return _buildDashboardHome();
    }

    final sidebarItems = [
      PanelMenuItem(title: 'Dashboard', icon: LucideIcons.home),
      PanelMenuItem(title: 'Subject Load', icon: LucideIcons.bookOpen),
      PanelMenuItem(title: 'Assessment', icon: LucideIcons.barChart3),
      PanelMenuItem(title: 'Grade Book', icon: LucideIcons.book),
      PanelMenuItem(title: 'Clearance', icon: LucideIcons.shield),
      PanelMenuItem(title: 'Profile', icon: LucideIcons.user),
      PanelMenuItem(title: 'Health Declaration', icon: LucideIcons.heartPulse),
      PanelMenuItem(title: 'Logout', icon: LucideIcons.logOut),
    ];

    String panelTitle = '';
    switch (_selectedIndex) {
      case 1:
        panelTitle = 'Subject Load';
        break;
      case 2:
        panelTitle = 'Assessment';
        break;
      case 3:
        panelTitle = 'Grade Book';
        break;
      case 4:
        panelTitle = 'Clearance';
        break;
      case 5:
        panelTitle = 'My Profile';
        break;
      case 6:
        panelTitle = 'Health Declaration';
        break;
    }

    return DashboardPanelTemplate(
      panelTitle: panelTitle,
      subtitle: '',
      panelContent: StudentPanelContent(panelType: _panelTypes[_selectedIndex]),
      sidebarItems: sidebarItems,
      onLogout: () {
        widget.onLogout?.call();
      },
      isDarkMode: _isDarkMode,
      onMenuItemSelected: (index) => setState(() => _selectedIndex = index),
      selectedIndex: _selectedIndex,
      isSidebarExpanded: _isSidebarExpanded,
      onSidebarToggle: (expanded) =>
          setState(() => _isSidebarExpanded = expanded),
      isAdminPanel: false,
    );
  }

  Widget _buildDashboardHome() {
    // Dynamic theme colors
    final bgColor = _isDarkMode ? const Color(0xFF0F071D) : const Color(0xFFF8FAFC);
    final cardColor = _isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final subTextColor = _isDarkMode ? Colors.white70 : Colors.blueGrey;

    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          // 1. FIXED TOGGLEABLE SIDEBAR
          _buildSidebar(cardColor, textColor, subTextColor),

          // 2. MAIN PANEL
          Expanded(
            child: Column(
              children: [
                _buildTopBar(textColor, subTextColor),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: _buildPanelContentHome(
                      cardColor,
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
      height: 70,
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
          const SizedBox(width: 12),
          Text(
            "Home > Dashboard",
            style: GoogleFonts.inter(
              color: subTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Theme Toggle
          IconButton(
            icon: Icon(
              _isDarkMode ? LucideIcons.sun : LucideIcons.moon,
              color: textColor,
            ),
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          ),
          const SizedBox(width: 20),
          Icon(LucideIcons.bell, color: subTextColor, size: 20),
          const SizedBox(width: 24),
          CircleAvatar(
            radius: 18,
            backgroundColor: aViolet,
            child: Text(
              "DA",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(Color cardColor, Color textColor, Color subTextColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isSidebarExpanded ? 260 : 80,
      color: _isDarkMode ? pViolet : const Color(0xFFF1F5F9),
      child: Column(
        children: [
          const SizedBox(height: 30),
          // Logo Section
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: aViolet.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
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
                  "UEMS Portal",
                  style: GoogleFonts.orbitron(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 40),
          // "Enroll Now" Prompt from image
          if (_isSidebarExpanded)
            _buildSidebarEnrollCard()
          else
            const Icon(LucideIcons.plusCircle, color: success),
          const SizedBox(height: 30),
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _menuItem(LucideIcons.home, "Dashboard", 0),
                _menuItem(LucideIcons.bookOpen, "Subject Load", 1),
                _menuItem(LucideIcons.barChart3, "Assessment", 2),
                _menuItem(LucideIcons.book, "Grade Book", 3),
                _menuItem(LucideIcons.shield, "Clearance", 4),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(color: Colors.white10),
                ),
                _menuItem(LucideIcons.user, "Profile", 5),
                _menuItem(LucideIcons.heartPulse, "Health Declaration", 6),
                _menuItem(LucideIcons.logOut, "Logout", 7, isDestructive: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarEnrollCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: success.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.zap, color: success, size: 20),
          const SizedBox(width: 12),
          Text(
            "Enroll Now",
            style: GoogleFonts.inter(
              color: success,
              fontWeight: FontWeight.w800,
              fontSize: 13,
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
  }) {
    bool isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? aViolet.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () {
          if (isDestructive) {
            widget.onLogout?.call();
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        minLeadingWidth: 20,
        leading: Icon(
          icon,
          color: isDestructive
              ? Colors.redAccent
              : (isSelected ? aViolet : Colors.blueGrey),
          size: 20,
        ),
        title: _isSidebarExpanded
            ? Text(
                title,
                style: GoogleFonts.inter(
                  color: isDestructive
                      ? Colors.redAccent
                      : (isSelected ? Colors.white : Colors.blueGrey),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildPanelContentHome(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header from image
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Dashboard",
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
                Text(
                  "Welcome back, DARLENE ANGEL",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: subTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            // Enrollment Banner from image
            _buildEnrollNowBanner(),
          ],
        ),
        const SizedBox(height: 32),
        // ENROLLMENT TRACKS (Main Section from Image)
        _buildEnrollmentTrackSection(cardColor, textColor, subTextColor),
        const SizedBox(height: 32),
        // ANNOUNCEMENTS
        _buildAnnouncements(cardColor, textColor, subTextColor),
      ],
    );
  }

  Widget _buildEnrollNowBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [pViolet, aViolet]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: aViolet.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.laptop, color: Colors.white, size: 30),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ENROLL NOW",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              Text(
                "2nd Semester SY 2025-2026",
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 20),
          const Icon(LucideIcons.chevronRight, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildEnrollmentTrackSection(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Enrollment Tracks",
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          Text(
            "School Year: 2025-2026 | Semester: 2nd Semester",
            style: GoogleFonts.inter(fontSize: 13, color: subTextColor),
          ),
          const SizedBox(height: 40),
          // Progress Bar
          Stack(
            children: [
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.white10 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.85,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [success, aViolet]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: success.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                right: 0,
                top: -25,
                child: Text(
                  "You are Now Enrolled",
                  style: TextStyle(
                    color: success,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statusIndicator("Submitted", true, success),
              _statusIndicator("Paid", true, success),
              _statusIndicator("Advising", true, success),
              _statusIndicator("Assessment", false, aViolet, isCurrent: true),
            ],
          ),
          const SizedBox(height: 40),
          // Payment Upload Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? Colors.white.withOpacity(0.03)
                  : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isDarkMode ? Colors.white10 : Colors.black12,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "For BANK PAYMENT, upload your deposit slip here.",
                  style: GoogleFonts.inter(color: subTextColor, fontSize: 14),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 250,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(LucideIcons.upload, size: 18),
                    label: const Text("UPLOAD & SEND"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: success,
                      foregroundColor: pViolet,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  Widget _statusIndicator(
    String label,
    bool isDone,
    Color color, {
    bool isCurrent = false,
  }) {
    return Column(
      children: [
        Icon(
          isDone
              ? LucideIcons.checkCircle2
              : (isCurrent ? LucideIcons.circleDot : LucideIcons.circle),
          color: color,
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            color: isDone || isCurrent ? color : Colors.blueGrey,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncements(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Latest Announcements",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 20),
        _announcementItem(
          "San Sebastian College - Recoletos de Cavite",
          "03/26/2026",
          "Grades for the 2nd Semester are now available for viewing. Check your Grade Book.",
          cardColor,
          textColor,
          subTextColor,
        ),
      ],
    );
  }

  Widget _announcementItem(
    String office,
    String date,
    String msg,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: aViolet.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.megaphone, color: aViolet, size: 20),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      office,
                      style: GoogleFonts.inter(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      date,
                      style: GoogleFonts.inter(
                        color: subTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  msg,
                  style: GoogleFonts.inter(
                    color: subTextColor,
                    height: 1.5,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
