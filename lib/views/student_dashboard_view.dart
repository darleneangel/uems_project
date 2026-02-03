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

  // Panel mapping (0..6 correspond to sidebar items excluding Logout)
  final List<String> _panelTypes = [
    'dashboard',
    'subject_load',
    'assessment',
    'grade_book',
    'clearance',
    'profile',
    'payment_upload',
  ];

  // Violet Theme Colors (Dark)
  static const Color pViolet = Color(0xFF2E1065);
  static const Color tDark = Color(0xFF0F071D);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);

  @override
  Widget build(BuildContext context) {
    // Sidebar items: last item is Logout (destructive)
    final sidebarItems = [
      PanelMenuItem(title: 'Dashboard', icon: LucideIcons.home),
      PanelMenuItem(title: 'Subject Load', icon: LucideIcons.bookOpen),
      PanelMenuItem(title: 'Assessment', icon: LucideIcons.barChart3),
      PanelMenuItem(title: 'Grade Book', icon: LucideIcons.book),
      PanelMenuItem(title: 'Clearance', icon: LucideIcons.shield),
      PanelMenuItem(title: 'Profile', icon: LucideIcons.user),
      PanelMenuItem(title: 'Bank Payment', icon: LucideIcons.creditCard),
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
        panelTitle = 'Clearance';
        break;
      case 5:
        panelTitle = 'My Profile';
        break;
      case 6:
        panelTitle = 'Payment Upload';
        break;
      default:
        panelTitle = 'Dashboard';
        subtitle = 'Welcome back, DARLENE ANGEL';
    }

    // compute colors (used by dashboard content helper)
    final cardColor = _isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final subTextColor = _isDarkMode ? Colors.white70 : Colors.blueGrey;

    // The panel content: dashboard content when 0, otherwise StudentPanelContent
    final Widget panelContent = (_selectedIndex == 0)
        ? _buildPanelContentHome(cardColor, textColor, subTextColor)
        : StudentPanelContent(
            panelType: (_selectedIndex < _panelTypes.length)
                ? _panelTypes[_selectedIndex]
                : 'dashboard');

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
      onSidebarToggle: (expanded) => setState(() => _isSidebarExpanded = expanded),
      isAdminPanel: false,
    );
  }

  // --- Dashboard content (kept as helper methods) ---
  Widget _buildPanelContentHome(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The panel title is rendered by the template. Keep only the enroll banner here.
        Align(alignment: Alignment.topRight, child: _buildEnrollNowBanner()),
        const SizedBox(height: 32),
        _buildEnrollmentTrackSection(cardColor, textColor, subTextColor),
        const SizedBox(height: 32),
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
                    onPressed: () {
                      // navigate to the payment upload panel (index 6)
                      setState(() => _selectedIndex = 6);
                    },
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
