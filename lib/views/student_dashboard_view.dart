import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../components/student_panel_content.dart';
import '../components/shared/messaging_panel.dart';

class StudentDashboardView extends StatefulWidget {
  final VoidCallback onLogout;
  final Map<String, dynamic> userData;

  const StudentDashboardView(
      {super.key, required this.onLogout, required this.userData});

  @override
  State<StudentDashboardView> createState() => _StudentDashboardViewState();
}

class _StudentDashboardViewState extends State<StudentDashboardView> {
  // Navigation & UI State
  bool _isDarkMode = true;
  bool _isSidebarExpanded = true;
  int _selectedIndex = 0;
  bool _isDataLoading = false;
  List<Map<String, dynamic>> _announcements = [];
  Map<String, dynamic>? _nextClass;
  double _enrollmentProgress = 0.0;
  double _currentUnits = 0.0;

  // Institutional Palette
  static const Color primaryViolet = Color(0xFF2E1065);
  static const Color secondaryViolet = Color(0xFF6D28D9);
  static const Color accentViolet = Color(0xFF8B5CF6);
  static const Color tDark = Color(0xFF0F071D);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color successColor = Color(0xFF69F0AE);
  static const Color aViolet = Color(0xFFB794F4);

  @override
  void initState() {
    super.initState();
    _loadStudentDashboardData();
    _checkInstitutionalSecurity();
  }

  /// 🛰️ DATABASE ENGINE: Forces a fresh sync of scholastic records
  Future<void> _loadStudentDashboardData() async {
    if (!mounted) return;
    setState(() => _isDataLoading = true);

    try {
      final client = SupabaseService().client;
      final String studentUuid = widget.userData['id'] ?? "";

      debugPrint("🛰️ CONNECTING: Fetching loads for UUID: $studentUuid");

      // 1. DYNAMIC UNIT SYNC: Using the explicit relationship mapping from your SQL
      final loadsRes = await client
          .from('study_loads')
          .select('*, subjects!study_loads_subject_id_fkey(units, name, code)')
          .eq('student_id', studentUuid);

      final List loads = List.from(loadsRes);
      debugPrint(
          "🛰️ SYNC COMPLETE: Found ${loads.length} subjects in ledger.");

      double totalUnits = 0.0;
      Map<String, dynamic>? upcoming;

      for (var l in loads) {
        final double u =
            double.tryParse(l['subjects']?['units']?.toString() ?? "0") ?? 0.0;
        totalUnits += u;
        debugPrint("   - Assigned: ${l['subjects']?['name']} ($u Units)");
      }

      if (loads.isNotEmpty) {
        upcoming = loads.first;
      }

      // 2. BROADCAST FETCH
      final annRes = await client
          .from('announcements')
          .select()
          .or('target_audience.eq.All,target_audience.eq.Students')
          .order('created_at', ascending: false)
          .limit(5);

      // 3. RESOLVE ENROLLMENT STATUS
      final details = widget.userData['student_details'];
      final String status = (details is List && details.isNotEmpty)
          ? (details.first['enrollment_status'] ?? "")
          : (details is Map ? (details['enrollment_status'] ?? "") : "");

      if (mounted) {
        setState(() {
          _announcements = List<Map<String, dynamic>>.from(annRes);
          _enrollmentProgress =
              (status == 'Enrolled' || status == 'Cleared') ? 1.0 : 0.75;
          _currentUnits = totalUnits;
          _nextClass = upcoming;
          _isDataLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ CRITICAL DATABASE ERROR: $e");
      if (mounted) setState(() => _isDataLoading = false);
    }
  }

  /// 📐 LOGIC: Resolves full identity map
  Map<String, dynamic> _getResolvedIdentity() {
    final Map<String, dynamic> data =
        Map<String, dynamic>.from(widget.userData);
    final detailsRaw = data['student_details'];
    if (detailsRaw != null) {
      if (detailsRaw is List && detailsRaw.isNotEmpty) {
        data.addAll(Map<String, dynamic>.from(detailsRaw.first));
      } else if (detailsRaw is Map)
        data.addAll(Map<String, dynamic>.from(detailsRaw));
    }
    return data;
  }

  void _checkInstitutionalSecurity() {
    final String currentPass =
        widget.userData['password_hash']?.toString() ?? "";
    final String lastName =
        widget.userData['ln']?.toString().toLowerCase().trim() ?? "";
    if (currentPass == lastName && currentPass.isNotEmpty) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showForcePasswordDialog());
    }
  }

  Future<void> _handleLogout() async {
    final Color dialogBodyColor = _isDarkMode ? Colors.white70 : Colors.black87;
    final Color dialogCancelColor = _isDarkMode ? Colors.white70 : primaryViolet;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Terminate Session",
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : primaryViolet)),
<<<<<<< HEAD
        content: const Text(
          "Are you sure you want to log out of the institutional portal?",
        ),
=======
        content: Text(
          "Are you sure you want to log out of the institutional portal?",
          style: GoogleFonts.inter(color: dialogBodyColor)),
>>>>>>> 9639ff007888ce8f3766b8d257130e7753f2c578
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
            child: Text("CANCEL",
              style: GoogleFonts.inter(
                color: dialogCancelColor, fontWeight: FontWeight.w600))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text("LOGOUT",
              style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirm == true) {
      widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode ? tDark : const Color(0xFFF8FAFC);
    final textColor = _isDarkMode ? Colors.white : primaryViolet;

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
                        child: _buildActiveViewport(),
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

  Widget _buildActiveViewport() {
    if (_selectedIndex == 0) return _buildHomeDashboard();
    if (_selectedIndex == 6) {
      return MessagingPanel(
          key: const ValueKey(6),
          isDarkMode: _isDarkMode,
          userData: widget.userData);
    }

    final List<String> panelTypes = [
      'dashboard',
      'subject_load',
      'assessment',
      'grade_book',
      'profile',
      'offices',
      'messaging'
    ];
    return StudentPanelContent(
      key: ValueKey(_selectedIndex),
      isDarkMode: _isDarkMode,
      panelType: panelTypes[_selectedIndex],
      studentData: _getResolvedIdentity(),
    );
  }

  Widget _buildHomeDashboard() {
    final cardColor = _isDarkMode
        ? surfaceDark.withOpacity(0.7)
        : Colors.white.withOpacity(0.8);
    final textColor = _isDarkMode ? Colors.white : primaryViolet;
    final subTextColor = _isDarkMode ? Colors.white60 : Colors.blueGrey;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNextClassCard(cardColor, textColor, subTextColor),
          const SizedBox(height: 32),
          _buildQuickStats(cardColor, textColor, subTextColor),
          const SizedBox(height: 32),
          _buildEnrollmentTrackSection(cardColor, textColor, subTextColor),
          const SizedBox(height: 32),
          _buildAnnouncements(cardColor, textColor, subTextColor),
          const SizedBox(height: 32),
          _buildMVGSection(cardColor, textColor, subTextColor),
        ],
      ),
    );
  }

  Widget _buildNextClassCard(
      Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: _isDarkMode
                ? [primaryViolet, secondaryViolet]
                : [secondaryViolet, accentViolet],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: accentViolet.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        children: [
          Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20)),
              child:
                  const Icon(LucideIcons.clock, color: Colors.white, size: 32)),
          const SizedBox(width: 24),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Text("UP NEXT",
                      style: GoogleFonts.inter(
                          color: successColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5)),
                  const SizedBox(width: 8),
                  Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                          color: Colors.white54, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(
                      _nextClass != null
                          ? "TODAY, ${_nextClass!['time_start'] ?? 'TBA'}"
                          : "SCHOLASTIC BREAK",
                      style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 8),
                Text(
                    _nextClass?['subjects']?['name'] ??
                        "No Classes Scheduled Today",
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ])),
          ElevatedButton.icon(
              onPressed: () => setState(() => _selectedIndex = 1),
              icon: const Icon(LucideIcons.arrowRight, size: 18),
              label: const Text("View Load"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primaryViolet,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16))),
        ],
      ),
    );
  }

  Widget _buildQuickStats(
      Color cardColor, Color textColor, Color subTextColor) {
    final identity = _getResolvedIdentity();
    return Row(
      children: [
        _buildAnimatedCard(
            index: 0,
            child: _statCard(
                "GWA Standing",
                identity['current_gwa']?.toString() ?? "0.00",
                LucideIcons.trendingUp,
                Colors.blueAccent,
                cardColor,
                textColor)),
        const SizedBox(width: 16),
        _buildAnimatedCard(
            index: 2,
            child: _statCard(
                "Account Balance",
                "₱${NumberFormat('#,###.00').format(double.tryParse(identity['account_balance']?.toString() ?? '0') ?? 0)}",
                LucideIcons.wallet,
                successColor,
                cardColor,
                textColor)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color iconColor,
      Color cardColor, Color textColor) {
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
                        : Colors.black.withOpacity(0.05))),
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
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(icon, color: iconColor, size: 20)),
                      if (label == "Account Balance" &&
                          (double.tryParse(
                                      _getResolvedIdentity()['account_balance']
                                              ?.toString() ??
                                          "0") ??
                                  0) <=
                              0)
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: successColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Text("CLEARED",
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: successColor))),
                    ]),
                const SizedBox(height: 20),
                Text(value,
                    style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: textColor)),
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnrollmentTrackSection(
      Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          border:
              Border.all(color: _isDarkMode ? Colors.white10 : Colors.black12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Institutional Enrollment Track",
              style: GoogleFonts.inter(
                  fontSize: 22, fontWeight: FontWeight.w800, color: textColor)),
          Text("Current Cycle: Academic Year 2025-2026",
              style: GoogleFonts.inter(fontSize: 13, color: subTextColor)),
          const SizedBox(height: 40),
          Stack(children: [
            Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.white10 : Colors.black12,
                    borderRadius: BorderRadius.circular(10))),
            FractionallySizedBox(
                widthFactor: _enrollmentProgress,
                child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [successColor, accentViolet]),
                        borderRadius: BorderRadius.circular(10)))),
            if (_enrollmentProgress == 1.0)
              const Positioned(
                  right: 0,
                  top: -25,
                  child: Text("Official Enrollment Verified",
                      style: TextStyle(
                          color: successColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14))),
          ]),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _statusIndicator("Submitted", true, successColor),
            _statusIndicator("Paid", true, successColor),
            _statusIndicator("Advising", true, successColor),
            _statusIndicator("Official Enrolled", _enrollmentProgress == 1.0,
                _enrollmentProgress == 1.0 ? successColor : accentViolet,
                isCurrent: _enrollmentProgress < 1.0),
          ]),
        ],
      ),
    );
  }

  Widget _statusIndicator(String label, bool isDone, Color color,
      {bool isCurrent = false}) {
    return Column(children: [
      Icon(
          isDone
              ? LucideIcons.checkCircle2
              : (isCurrent ? LucideIcons.circleDot : LucideIcons.circle),
          color: color,
          size: 20),
      const SizedBox(height: 8),
      Text(label,
          style: GoogleFonts.inter(
              color: isDone || isCurrent ? color : Colors.blueGrey,
              fontWeight: FontWeight.bold,
              fontSize: 11)),
    ]);
  }

  Widget _buildAnnouncements(
      Color cardColor, Color textColor, Color subTextColor) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(LucideIcons.megaphone, color: accentViolet, size: 24),
        const SizedBox(width: 12),
        Text("Institutional Broadcasts",
            style: GoogleFonts.inter(
                fontSize: 20, fontWeight: FontWeight.w800, color: textColor))
      ]),
      const SizedBox(height: 20),
      if (_isDataLoading)
        const Center(
            child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: accentViolet)))
      else if (_announcements.isEmpty)
        _announcementItem(
            "SYSTEM CORE",
            "BFA ADMINISTRATION",
            "MARCH 2026",
            "No active institutional broadcasts recorded.",
            cardColor,
            textColor,
            subTextColor)
      else
        ..._announcements.map((ann) {
          final date = ann['created_at'] != null
              ? DateFormat('MMMM dd, yyyy')
                  .format(DateTime.parse(ann['created_at']))
              : "RECENT";
          return _announcementItem(
              (ann['title'] ?? "NOTICE").toString().toUpperCase(),
              (ann['office'] ?? "Administration").toString().toUpperCase(),
              date,
              ann['content'] ?? "No details provided.",
              cardColor,
              textColor,
              subTextColor);
        }),
    ]);
  }

  Widget _announcementItem(String title, String office, String date, String msg,
      Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: _isDarkMode ? Colors.white10 : Colors.black12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: accentViolet.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(office,
                  style: const TextStyle(
                      color: accentViolet,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1))),
          Text(date,
              style: GoogleFonts.inter(color: subTextColor, fontSize: 12)),
        ]),
        const SizedBox(height: 16),
        Text(title,
            style: GoogleFonts.inter(
                color: textColor,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Text(msg,
            style: GoogleFonts.inter(
                color: subTextColor, height: 1.6, fontSize: 14)),
      ]),
    );
  }

  Widget _buildMVGSection(
      Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          border:
              Border.all(color: _isDarkMode ? Colors.white10 : Colors.black12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Mission & Vision",
            style: GoogleFonts.inter(
                fontSize: 22, fontWeight: FontWeight.w800, color: textColor)),
        const SizedBox(height: 24),
        _mvgItem(
            "Institutional Mission",
            "To provide a technology-driven academic ecosystem that empowers students.",
            LucideIcons.target,
            Colors.blueAccent),
        const SizedBox(height: 16),
        _mvgItem(
            "Institutional Vision",
            "To be a premier institution recognized for academic rigor and global human potential.",
            LucideIcons.eye,
            Colors.orangeAccent),
      ]),
    );
  }

  Widget _mvgItem(String title, String content, IconData icon, Color color) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20)),
      const SizedBox(width: 16),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        Text(content,
            style: GoogleFonts.inter(
                color: _isDarkMode ? Colors.white70 : Colors.blueGrey,
                fontSize: 14))
      ])),
    ]);
  }

  Widget _buildTopBar(Color textColor) {
    final subTextColor = _isDarkMode ? Colors.white70 : Colors.blueGrey;
    final String fn =
        (widget.userData['fn'] ?? widget.userData['first_name'] ?? 'STUDENT')
            .toString();
    final String ln =
        (widget.userData['ln'] ?? widget.userData['last_name'] ?? '')
            .toString();
    final String idNum =
        (widget.userData['user_id_number'] ?? 'N/A').toString();
    final dynamic detailsRaw = widget.userData['student_details'];
    Map<String, dynamic>? details;
    if (detailsRaw is List && detailsRaw.isNotEmpty) {
      details = detailsRaw.first;
    } else if (detailsRaw is Map<String, dynamic>) details = detailsRaw;
    final String programName =
        details?['courses']?['name'] ?? 'College Department';

    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
          color: _isDarkMode ? tDark : Colors.white,
          border: Border(
              bottom: BorderSide(
                  color: _isDarkMode ? Colors.white10 : Colors.black12))),
      child: Row(children: [
        IconButton(
            icon: Icon(
                _isSidebarExpanded
                    ? LucideIcons.menu
                    : LucideIcons.chevronRight,
                color: textColor),
            onPressed: () =>
                setState(() => _isSidebarExpanded = !_isSidebarExpanded)),
        const SizedBox(width: 16),
        Text("Student Terminal Hub",
            style: GoogleFonts.inter(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5)),
        const Spacer(),
        _buildNotificationButton(subTextColor),
        const SizedBox(width: 12),
        IconButton(
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
            icon: Icon(_isDarkMode ? LucideIcons.sun : LucideIcons.moon,
                color: aViolet)),
        const SizedBox(width: 24),
        Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${fn}_$ln".toUpperCase(),
                  style: GoogleFonts.inter(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              Text(programName,
                  style: GoogleFonts.inter(
                      color: accentViolet,
                      fontSize: 10,
                      fontWeight: FontWeight.w800)),
              Text("ID: $idNum",
                  style: GoogleFonts.inter(
                      color: successColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ]),
        const SizedBox(width: 12),
        CircleAvatar(
            backgroundColor: aViolet,
            radius: 18,
            child: Text(fn.isNotEmpty ? fn[0].toUpperCase() : 'S',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12))),
      ]),
    );
  }

  Widget _buildSidebar(Color textColor) {
    final sidebarColor = _isDarkMode ? primaryViolet : const Color(0xFFF1F5F9);
    final subText = _isDarkMode ? Colors.white60 : Colors.blueGrey;
    final logoutTextColor = _isDarkMode ? Colors.white : Colors.redAccent;
    final items = [
      {'title': 'Dashboard', 'icon': LucideIcons.home},
      {'title': 'Subject Load', 'icon': LucideIcons.bookOpen},
      {'title': 'Assessment', 'icon': LucideIcons.barChart3},
      {'title': 'Grade Book', 'icon': LucideIcons.book},
      {'title': 'My Profile', 'icon': LucideIcons.user},
      {'title': 'Offices & Requests', 'icon': LucideIcons.building},
      {'title': 'Messaging', 'icon': LucideIcons.messageSquare}
    ];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isSidebarExpanded ? 280 : 85,
      color: sidebarColor,
      child: Column(children: [
        const SizedBox(height: 30),
        _buildLogo(textColor),
        const SizedBox(height: 40),
        Expanded(
            child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final bool isSelected = _selectedIndex == index;
                  return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                          color: isSelected
                              ? accentViolet.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                          onTap: () => setState(() => _selectedIndex = index),
                          leading: Icon(items[index]['icon'] as IconData,
                              color: isSelected
                                  ? (_isDarkMode ? Colors.white : primaryViolet)
                                  : subText,
                              size: 20),
                          title: _isSidebarExpanded
                              ? Text(items[index]['title'] as String,
                                  style: GoogleFonts.inter(
                                      color:
                                          isSelected ? Colors.white : subText,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      fontSize: 13))
                              : null));
                })),
        const Divider(color: Colors.white10),
        ListTile(
            onTap: _handleLogout,
            leading: const Icon(LucideIcons.logOut,
                color: Colors.redAccent, size: 20),
            title: _isSidebarExpanded
            ? Text("Logout System",
                    style: TextStyle(
                color: logoutTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13))
                : null),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildLogo(Color textColor) =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: accentViolet.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(LucideIcons.graduationCap,
                color: accentViolet, size: 24)),
        if (_isSidebarExpanded) ...[
          const SizedBox(width: 12),
          Text("UEMSSP PORTAL",
              style: GoogleFonts.orbitron(
                  color: textColor, fontWeight: FontWeight.bold, fontSize: 14))
        ]
      ]);

  Widget _buildNotificationButton(Color color) => Stack(children: [
        IconButton(
            icon: Icon(LucideIcons.bell, color: color, size: 20),
            onPressed: () => _showNotificationSheet()),
        if (_announcements.isNotEmpty)
          Positioned(
              right: 10,
              top: 10,
              child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _isDarkMode ? tDark : Colors.white,
                          width: 1.5))))
      ]);

  void _showNotificationSheet() {
    showModalBottomSheet(
        context: context,
        backgroundColor: _isDarkMode ? tDark : Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (ctx) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Institutional Notices',
                            style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: _isDarkMode
                                    ? Colors.white
                                    : primaryViolet)),
                        IconButton(
                            icon: const Icon(LucideIcons.x, size: 20),
                            onPressed: () => Navigator.pop(ctx))
                      ])),
              const Divider(height: 32, color: Colors.white10),
              if (_announcements.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(60),
                    child: Text("No active institutional notices found.",
                        style: TextStyle(color: Colors.blueGrey)))
              else
                Flexible(
                    child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _announcements.length,
                        separatorBuilder: (_, __) => const Divider(
                            color: Colors.white10, indent: 24, endIndent: 24),
                        itemBuilder: (context, i) {
                          final n = _announcements[i];
                          String dateStr = "Recent";
                          if (n['created_at'] != null) {
                            dateStr = DateFormat('MMM dd, hh:mm a').format(
                                DateTime.parse(n['created_at'].toString())
                                    .toLocal());
                          }
                          return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 8),
                              leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                      color: accentViolet.withOpacity(0.1),
                                      shape: BoxShape.circle),
                                  child: const Icon(LucideIcons.megaphone,
                                      color: accentViolet, size: 18)),
                              title: Text(n['title'] ?? 'System Notice',
                                  style: TextStyle(
                                      color: _isDarkMode
                                          ? Colors.white
                                          : primaryViolet,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(n['content'] ?? '',
                                        style: const TextStyle(
                                            color: Colors.blueGrey,
                                            fontSize: 12,
                                            height: 1.4),
                                        maxLines: 3),
                                    const SizedBox(height: 8),
                                    Text(dateStr,
                                        style: TextStyle(
                                            color:
                                                accentViolet.withOpacity(0.6),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold))
                                  ]));
                        }))
            ])));
  }

  Widget _buildAnimatedCard({required Widget child, required int index}) =>
      Expanded(
          child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 400 + (index * 150)),
              curve: Curves.easeOutBack,
              builder: (context, value, child) => Transform.scale(
                  scale: value,
                  child: Opacity(opacity: value.clamp(0.0, 1.0), child: child)),
              child: child));

  void _showForcePasswordDialog() {
    // Standard institutional policy password reset...
  }
}
