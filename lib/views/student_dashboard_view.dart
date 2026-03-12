import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../components/shared/student_messaging_panel.dart';
import '../components/dashboard_panel_template.dart';
import '../components/student_panel_content.dart';
import '../services/supabase_service.dart';

class StudentDashboardView extends StatefulWidget {
  final VoidCallback? onLogout;
  final Map<String, dynamic>? userData;
  const StudentDashboardView({super.key, this.onLogout, this.userData});

  @override
  State<StudentDashboardView> createState() => _StudentDashboardViewState();
}

class _StudentDashboardViewState extends State<StudentDashboardView> {
  // Theme state
  bool _isDarkMode = true;
  bool _isSidebarExpanded = true;
  int _selectedIndex = 0;

  // Database Data State
  List<Map<String, dynamic>> _grades = [];
  List<Map<String, dynamic>> _assessments = [];
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _announcements = [];
  Map<String, dynamic>? _nextClass;
  double _enrollmentProgress = 0.0;
  bool _isDataLoading = false;

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
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    if (widget.userData == null) return;
    setState(() => _isDataLoading = true);

    final client = SupabaseService().client;
    final studentId = widget.userData!['id'];
    final now = DateTime.now();
    final timeOnly =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00";

    try {
      // Parallel data fetching for performance
      final results = await Future.wait([
        client
            .from('study_loads')
            .select('*, subjects(*)')
            .eq('student_id', studentId),
        client.from('payments').select().eq('student_id', studentId),
        client.from('office_requests').select().eq('student_id', studentId),
        client
            .from('announcements')
            .select()
            .order('created_at', ascending: false)
            .limit(5),
        client
            .from('study_loads')
            .select('*, subjects(*)')
            .eq('student_id', studentId)
            .gte('time_start', now)
            .order('time_start')
            .limit(1)
            .maybeSingle(),
        client
            .from('student_details')
            .select('enrollment_status')
            .eq('profile_id', studentId)
            .maybeSingle(),
      ]);

      if (mounted) {
        setState(() {
          _grades = List<Map<String, dynamic>>.from(results[0] as List? ?? []);
          _assessments =
              List<Map<String, dynamic>>.from(results[1] as List? ?? []);
          _requests =
              List<Map<String, dynamic>>.from(results[2] as List? ?? []);
          _announcements =
              List<Map<String, dynamic>>.from(results[3] as List? ?? []);
          _nextClass = results[4] as Map<String, dynamic>?;

          final status =
              (results[5] as Map<String, dynamic>?)?['enrollment_status'];
          _enrollmentProgress = status == 'Enrolled' ? 1.0 : 0.5;

          _isDataLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Sync Error: $e");
      if (mounted) setState(() => _isDataLoading = false);
    }
  }

  Map<String, dynamic> _getCombinedData() {
    final detailsData = widget.userData?['student_details'];
    final details = (detailsData is List && detailsData.isNotEmpty)
        ? detailsData.first
        : (detailsData is Map ? detailsData : {});
    return {
      ...(widget.userData ?? {}),
      ...details,
      'grade_book': _grades, // Matches _panelTypes[3]
      'assessment': _assessments, // Matches _panelTypes[2]
      'offices': _requests, // Matches _panelTypes[5]
    };
  }

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
        subtitle =
            'Welcome to Bright Future Academy, ${widget.userData?['fn'] ?? 'STUDENT'}';
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
      panelContent = StudentMessagingPanel(
        isDarkMode: _isDarkMode,
        studentId: widget.userData?['id']?.toString(),
      );
    } else {
      panelContent = StudentPanelContent(
        isDarkMode: _isDarkMode,
        panelType: (_selectedIndex < _panelTypes.length)
            ? _panelTypes[_selectedIndex]
            : 'dashboard',
        studentData: _getCombinedData(),
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
    return SingleChildScrollView(
      // Wrap the content in a SingleChildScrollView
      child: TweenAnimationBuilder<double>(
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
            _buildQuickStats(cardColor, textColor, subTextColor),
            const SizedBox(height: 32),
            _buildEnrollmentTrackSection(cardColor, textColor, subTextColor),
            const SizedBox(height: 32),
            _buildMVGSection(cardColor, textColor, subTextColor),
            const SizedBox(height: 32),
            _buildAnnouncements(cardColor, textColor, subTextColor),
          ],
        ),
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
                      _nextClass != null
                          ? "TODAY, ${_nextClass!['time_start']}"
                          : "NO CLASSES REMAINING",
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
                  _nextClass?['subjects']?['name'] ?? "No Upcoming Class",
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
                      "${_nextClass?['room_number'] ?? 'N/A'} • ${_nextClass?['professor_id'] ?? 'N/A'}",
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

  Widget _buildQuickStats(
      Color cardColor, Color textColor, Color subTextColor) {
    return Row(
      children: [
        _buildAnimatedCard(
          index: 0,
          child: _statCard(
            "GWA Standing",
            _getCombinedData()['current_gwa']?.toString() ?? "0.00",
            LucideIcons.trendingUp,
            Colors.blueAccent,
            cardColor,
            textColor,
          ),
        ),
        const SizedBox(width: 16),
        _buildAnimatedCard(
          index: 1,
          child: _statCard(
            "Units Enrolled",
            _getCombinedData()['enrolled_units']?.toString() ?? "0.0",
            LucideIcons.layers,
            const Color.fromARGB(255, 242, 64, 255),
            cardColor,
            textColor,
          ),
        ),
        const SizedBox(width: 16),
        _buildAnimatedCard(
          index: 2,
          child: _statCard(
            "Account Balance",
            "₱${_getCombinedData()['account_balance'] ?? '0.00'}",
            LucideIcons.wallet,
            successColor,
            cardColor,
            textColor,
          ),
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
    return SizedBox(
      width: double.infinity,
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
                widthFactor: _enrollmentProgress,
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
        if (_announcements.isEmpty && !_isDataLoading)
          _announcementItem(
            "Bright Future Academy",
            "System",
            "No new announcements at this time.",
            cardColor,
            textColor,
            subTextColor,
          )
        else
          ..._announcements.map((ann) => _announcementItem(
                ann['author'] ?? "Bright Future Academy",
                ann['created_at']?.toString().split('T')[0] ?? "",
                ann['content'] ?? "",
                cardColor,
                textColor,
                subTextColor,
              )),
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

  Widget _buildMVGSection(
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
            "Bright Future Academy Identity",
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),
          _mvgItem(
            "Mission",
            "To provide holistic education that empowers students to become globally competitive leaders through innovation and character formation.",
            LucideIcons.target,
            Colors.blueAccent,
          ),
          const SizedBox(height: 16),
          _mvgItem(
            "Vision",
            "A premier institution recognized for academic excellence, research innovation, and community-driven transformation.",
            LucideIcons.eye,
            Colors.orangeAccent,
          ),
          const SizedBox(height: 16),
          _mvgItem(
            "Goals",
            "• Foster Academic Rigor\n• Promote Holistic Development\n• Strengthen Community Engagement",
            LucideIcons.flag,
            Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  Widget _mvgItem(String title, String content, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold, color: color, fontSize: 16)),
              const SizedBox(height: 4),
              Text(content,
                  style: GoogleFonts.inter(
                      color: _isDarkMode ? Colors.white70 : Colors.blueGrey,
                      fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedCard({required Widget child, required int index}) {
    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 400 + (index * 150)),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: child,
      ),
    );
  }
}
