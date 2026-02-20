import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../components/shared/student_messaging_panel.dart';
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

  // Panel mapping (0..6 correspond to sidebar items excluding Logout)
  static const List<String> _panelTypes = [
    'dashboard',
    'subject_load',
    'assessment',
    'grade_book',
    'profile',
    'offices',
    'messaging', // New module for messaging
  ];

  // Standardized Violet Theme Palette
  static const Color primaryViolet = Color(0xFF2E1065);
  static const Color secondaryViolet = Color(0xFF4C1D95);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color accentViolet = Color(0xFF8B5CF6);
  static const Color successColor = Color(0xFF69F0AE);
  static const Color aViolet = Color(
    0xFF7C3AED,
  ); // Corrected Vivid Violet (No red tint)

  @override
  Widget build(BuildContext context) {
    // Sidebar items: last item is Logout (destructive)
    final sidebarItems = [
      PanelMenuItem(title: 'Dashboard', icon: LucideIcons.home),
      PanelMenuItem(title: 'Subject Load', icon: LucideIcons.bookOpen),
      PanelMenuItem(title: 'Assessment', icon: LucideIcons.barChart3),
      PanelMenuItem(title: 'Grade Book', icon: LucideIcons.book),
      PanelMenuItem(title: 'Profile', icon: LucideIcons.user),
      PanelMenuItem(title: 'Offices & Requests', icon: LucideIcons.building),
      PanelMenuItem(
        title: 'Messaging',
        icon: LucideIcons.messageSquare,
      ), // New module
      PanelMenuItem(title: 'Logout', icon: LucideIcons.logOut),
    ];

    // Panel title mapping
    String panelTitle = 'Dashboard';
    String subtitle = '';
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
        panelTitle = 'My Profile';
        break;
      case 5:
        panelTitle = 'Offices & Requests';
        break;
      case 6: // New case for Messaging
        panelTitle = 'Messaging';
        break;
      default:
        panelTitle = 'Dashboard';
        subtitle = 'Welcome back, DARLENE ANGEL';
    }

    // compute colors (used by dashboard content helper)
    final cardColor = _isDarkMode
        ? surfaceDark.withOpacity(0.7)
        : Colors.white.withOpacity(0.8);
    final textColor = _isDarkMode ? Colors.white : primaryViolet;
    final subTextColor = _isDarkMode ? Colors.white60 : Colors.blueGrey;

    // The panel content: dashboard content when 0, otherwise StudentPanelContent
    Widget panelContent;
    if (_selectedIndex == 0) {
      panelContent = _buildPanelContentHome(cardColor, textColor, subTextColor);
    } else if (_selectedIndex == 6) {
      // Handle Messaging panel
      panelContent = StudentMessagingPanel(isDarkMode: _isDarkMode);
    } else {
      panelContent = StudentPanelContent(
        isDarkMode: _isDarkMode,
        panelType: (_selectedIndex < _panelTypes.length)
            ? _panelTypes[_selectedIndex]
            : 'dashboard',
      );
    }

    return DashboardPanelTemplate(
      panelTitle: panelTitle,
      subtitle: subtitle,
      panelContent: panelContent,
      sidebarItems: sidebarItems,
      onLogout: () {
        widget.onLogout?.call();
      },
      isDarkMode: _isDarkMode,
      onMenuItemSelected: (index) {
        // template will call this for non-destructive items; Logout handled in template
        if (index >= 0 && index < _panelTypes.length) {
          setState(() => _selectedIndex = index);
        }
      },
      selectedIndex: _selectedIndex,
      isSidebarExpanded: _isSidebarExpanded,
      onSidebarToggle: (expanded) =>
          setState(() => _isSidebarExpanded = expanded),
      isAdminPanel: false,
      themeToggle: () => setState(() => _isDarkMode = !_isDarkMode),
    );
  }

  // --- Dashboard content (kept as helper methods) ---
  Widget _buildPanelContentHome(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNextClassCard(cardColor, textColor, subTextColor),
          const SizedBox(height: 32),
          _buildQuickStats(cardColor, textColor),
          const SizedBox(height: 32),
          _buildEnrollmentTrackSection(cardColor, textColor, subTextColor),
          const SizedBox(height: 32),
          _buildAnnouncements(cardColor, textColor, subTextColor),
        ],
      ),
    );
  }

  Widget _buildNextClassCard(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDarkMode
              ? [primaryViolet, secondaryViolet]
              : [secondaryViolet, accentViolet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: accentViolet.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(LucideIcons.clock, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "UP NEXT",
                      style: GoogleFonts.inter(
                        color: successColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white54,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "TODAY, 10:00 AM",
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Systems Integration & Architecture",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.mapPin,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Computer Lab 102 • Prof. R. Manalastas",
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() => _selectedIndex = 1),
            icon: const Icon(LucideIcons.arrowRight, size: 18),
            label: const Text("View Schedule"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryViolet,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Color cardColor, Color textColor) {
    return Row(
      children: [
        _statCard(
          "GWA Standing",
          "1.25",
          LucideIcons.trendingUp,
          Colors.blueAccent,
          cardColor,
          textColor,
        ),
        const SizedBox(width: 16),
        _statCard(
          "Units Enrolled",
          "21.0",
          LucideIcons.layers,
          const Color.fromARGB(255, 242, 64, 255),
          cardColor,
          textColor,
        ),
        const SizedBox(width: 16),
        _statCard(
          "Account Balance",
          "₱0.00",
          LucideIcons.wallet,
          successColor,
          cardColor,
          textColor,
        ),
      ],
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    Color cardColor,
    Color textColor,
  ) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    if (label == "Account Balance")
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "CLEARED",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: successColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
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
                    gradient: const LinearGradient(
                      colors: [successColor, accentViolet],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: successColor.withOpacity(0.3),
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
                    color: successColor,
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
              _statusIndicator("Submitted", true, successColor),
              _statusIndicator("Paid", true, successColor),
              _statusIndicator("Advising", true, successColor),
              _statusIndicator(
                "Assessment",
                false,
                accentViolet,
                isCurrent: true,
              ),
            ],
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
