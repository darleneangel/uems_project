import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../components/admin_panel_content.dart';
import '../components/program_chair_panel.dart';
import '../components/messaging_panel.dart';
import '../components/hr_panel.dart';
import '../components/report_panel.dart';
import '../components/department_management_panel.dart';
import '../components/course_management_panel.dart';
import '../components/administrative_account_management_panel.dart';
import '../components/academic_account_management_panel.dart';
import '../services/admin_user_management_service.dart';

class AdminDashboardView extends StatefulWidget {
  final VoidCallback onLogout;
  const AdminDashboardView({super.key, required this.onLogout});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  bool _isSidebarExpanded = true;
  bool _isDarkMode = true;
  int _activeModuleIndex = 0;
  final AdminUserManagementService _adminService = AdminUserManagementService();
  late Future<AdminAnalyticsSnapshot> _dbAnalyticsFuture;

  // Panel mapping
  final List<String> _panelTypes = [
    'overview',
    'announcements',
    'office_admin',
    'program_chair',
    'study_loads',
    'grade_recording',
    'hr',
    'messaging',
    'reports',
  ];

  // Violet Theme Colors (matching student dashboard - lighter version)
  static const Color pViolet = Color(0xFF2E1065);
  static const Color tDark = Color(0xFF0F071D);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B); // Lighter surface
  static const Color success = Color(0xFF69F0AE);

  // Light mode colors - lighter and softer
  static const Color lBg = Color(0xFFF8FAFC);
  static const Color lSurface = Color(0xFFF1F5F9);
  static const Color lCard = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _dbAnalyticsFuture = _adminService.fetchDatabaseAnalytics();
  }

  void _toggleTheme() => setState(() => _isDarkMode = !_isDarkMode);

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode ? tDark : lBg;
    final sideColor = _isDarkMode ? surfaceDark : lSurface;
    final textColor = _isDarkMode ? Colors.white : pViolet;
    final subTextColor = _isDarkMode ? Colors.white54 : Colors.blueGrey;

    // Build the panel content based on active module index
    String panelTitle = '';
    Widget panelContent;

    switch (_activeModuleIndex) {
      case 0:
        panelTitle = 'System Overview';
        panelContent = _buildDashboardIntelligence(textColor, subTextColor);
        break;
      case 1:
        panelTitle = 'Announcements Management';
        panelContent = AdminPanelContent(
            panelType: _panelTypes[1], isDarkMode: _isDarkMode);
        break;
      case 2:
        panelTitle = 'Office Admin - Service Requests';
        panelContent = AdminPanelContent(
            panelType: _panelTypes[2], isDarkMode: _isDarkMode);
        break;
      case 3:
        panelTitle = 'Program Chair Administration';
        panelContent = ProgramChairPanel(isDarkMode: _isDarkMode);
        break;
      case 4:
        panelTitle = 'Study Loads Management';
        panelContent = AdminPanelContent(
            panelType: _panelTypes[4], isDarkMode: _isDarkMode);
        break;
      case 5:
        panelTitle = 'Grade Recording System';
        panelContent = AdminPanelContent(
            panelType: _panelTypes[5], isDarkMode: _isDarkMode);
        break;
      case 6:
        panelTitle = 'Human Resources';
        panelContent = HRPanel(isDarkMode: _isDarkMode);
        break;
      case 7:
        panelTitle = 'Messaging';
        panelContent = MessagingPanel(isDarkMode: _isDarkMode);
        break;
      case 8:
        panelTitle = 'Error Reports & System Issues';
        panelContent = ReportPanel(isDarkMode: _isDarkMode);
        break;
      case 10:
        panelTitle = 'Department Management';
        panelContent = DepartmentManagementPanel(isDarkMode: _isDarkMode);
        break;
      case 11:
        panelTitle = 'Course Management';
        panelContent = CourseManagementPanel(isDarkMode: _isDarkMode);
        break;
      case 12:
        panelTitle = 'Administrative Account Management';
        panelContent =
            AdministrativeAccountManagementPanel(isDarkMode: _isDarkMode);
        break;
      case 13:
        panelTitle = 'Academic Account Management';
        panelContent = AcademicAccountManagementPanel(isDarkMode: _isDarkMode);
        break;
      default:
        panelTitle = 'System Overview';
        panelContent = _buildDashboardIntelligence(textColor, subTextColor);
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          // Custom sidebar with section headers (always consistent design)
          _buildSidebar(sideColor, textColor, subTextColor),

          // Main content area
          Expanded(
            child: Column(
              children: [
                _buildTopBar(sideColor, textColor, subTextColor, panelTitle),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          panelTitle,
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 32),
                        panelContent,
                      ],
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

  Widget _buildTopBar(
      Color sideColor, Color textColor, Color subTextColor, String panelTitle) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: sideColor,
        border: Border(
          bottom: BorderSide(
            color: _isDarkMode ? Colors.white10 : Colors.black12,
          ),
        ),
      ),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                panelTitle,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                "ISO/IEC 25010 QUALITY COMPLIANCE: VERIFIED",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: success,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: _toggleTheme,
            icon: Icon(
              _isDarkMode ? LucideIcons.sun : LucideIcons.moon,
              color: aViolet,
            ),
            tooltip: "Switch to ${_isDarkMode ? 'Light' : 'Dark'} Mode",
          ),
          const SizedBox(width: 16),
          _buildHeaderAction(
            LucideIcons.search,
            subTextColor,
            onTap: _showSearchDialog,
          ),
          const SizedBox(width: 16),
          _buildHeaderAction(
            LucideIcons.bell,
            subTextColor,
            onTap: _showNotificationsPanel,
          ),
          const SizedBox(width: 24),
          VerticalDivider(
            color: subTextColor.withOpacity(0.2),
            indent: 20,
            endIndent: 20,
          ),
          const SizedBox(width: 24),
          const CircleAvatar(
            backgroundColor: aViolet,
            child: Icon(
              LucideIcons.shieldCheck,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(Color sideColor, Color textColor, Color subTextColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isSidebarExpanded ? 280 : 80,
      color: sideColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(LucideIcons.shield, color: aViolet, size: 28),
                if (_isSidebarExpanded) ...[
                  const SizedBox(width: 12),
                  Text(
                    "UEMS ADMIN",
                    style: GoogleFonts.orbitron(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
                const Spacer(),
                if (_isSidebarExpanded)
                  IconButton(
                    icon: Icon(
                      LucideIcons.chevronLeft,
                      color: subTextColor,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _isSidebarExpanded = false),
                  ),
              ],
            ),
          ),
          if (!_isSidebarExpanded)
            Center(
              child: IconButton(
                icon: Icon(LucideIcons.chevronRight, color: subTextColor),
                onPressed: () => setState(() => _isSidebarExpanded = true),
              ),
            ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _sidebarHeader("CENTRAL CONTROL", subTextColor),
                _sidebarItem(
                  LucideIcons.layoutDashboard,
                  "System Overview",
                  0,
                  textColor,
                ),
                _sidebarItem(
                  LucideIcons.megaphone,
                  "Announcements",
                  1,
                  textColor,
                ),
                const SizedBox(height: 20),
                _sidebarHeader("OFFICE MANAGEMENT", subTextColor),
                _sidebarItem(
                    LucideIcons.briefcase, "Office Admin", 2, textColor),
                _sidebarItem(
                    LucideIcons.userCheck, "Program Chair", 3, textColor),
                _sidebarItem(LucideIcons.users, "HR", 6, textColor),
                const SizedBox(height: 20),
                _sidebarHeader("ACADEMIC MANAGEMENT", subTextColor),
                _sidebarItem(
                    LucideIcons.building, "Departments", 10, textColor),
                _sidebarItem(LucideIcons.bookOpen, "Courses", 11, textColor),
                const SizedBox(height: 20),
                _sidebarHeader("ACCOUNT MANAGEMENT", subTextColor),
                _sidebarItem(LucideIcons.userCog, "Administrative Accounts", 12,
                    textColor),
                _sidebarItem(LucideIcons.graduationCap, "Academic Accounts", 13,
                    textColor),
                const SizedBox(height: 20),
                _sidebarHeader("UTILITIES", subTextColor),
                _sidebarItem(
                    LucideIcons.messageSquare, "Messaging", 7, textColor),
                _sidebarItem(
                    LucideIcons.alertTriangle, "Reports", 8, textColor),
              ],
            ),
          ),
          const Divider(color: Colors.white10),
          _sidebarItem(
            LucideIcons.logOut,
            "Secure Logout",
            9,
            textColor,
            isDestructive: true,
            onTap: () => _showLogoutConfirmation(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sidebarHeader(String title, Color subTextColor) {
    if (!_isSidebarExpanded) return const SizedBox(height: 20);
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 12, top: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: subTextColor.withOpacity(0.5),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDarkMode ? surfaceDark : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.logout, color: Colors.redAccent, size: 24),
            const SizedBox(width: 12),
            Text('Confirm Logout',
                style: GoogleFonts.inter(
                    color: _isDarkMode ? Colors.white : pViolet,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to log out of the system?',
              style: GoogleFonts.inter(
                  color: _isDarkMode ? Colors.white70 : Colors.black87,
                  fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'Any unsaved changes will be lost.',
              style: GoogleFonts.inter(
                  color: _isDarkMode ? Colors.white54 : Colors.black54,
                  fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: _isDarkMode ? Colors.white10 : Colors.black12,
            ),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    color: _isDarkMode ? Colors.white70 : Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              widget.onLogout(); // Perform logout
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Logout',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _sidebarItem(
    IconData icon,
    String label,
    int index,
    Color textColor, {
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    // Keep sidebar appearance uniform regardless of selection
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap ?? () => setState(() => _activeModuleIndex = index),
        visualDensity: VisualDensity.compact,
        leading: Icon(
          icon,
          color: isDestructive ? Colors.redAccent : textColor.withOpacity(0.4),
          size: 20,
        ),
        title: _isSidebarExpanded
            ? Text(
                label,
                style: GoogleFonts.inter(
                  color: isDestructive
                      ? Colors.redAccent
                      : textColor.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildDashboardIntelligence(Color textColor, Color subTextColor) {
    return ValueListenableBuilder<List<AdminManagedAccount>>(
      valueListenable: _adminService.notifier,
      builder: (context, _, __) {
        final local = _adminService.getLocalAnalytics();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatCard(
                  "Students",
                  local.students.toString(),
                  LucideIcons.graduationCap,
                  aViolet,
                  textColor,
                  onTap: () => setState(() => _activeModuleIndex = 13),
                ),
                _buildStatCard(
                  "Teachers",
                  local.teachers.toString(),
                  LucideIcons.bookOpen,
                  Colors.blueAccent,
                  textColor,
                  onTap: () => setState(() => _activeModuleIndex = 13),
                ),
                _buildStatCard(
                  "Program Chairs",
                  local.programChairs.toString(),
                  LucideIcons.userCheck,
                  Colors.orangeAccent,
                  textColor,
                  onTap: () => setState(() => _activeModuleIndex = 13),
                ),
                _buildStatCard(
                  "Admin + HR",
                  (local.adminStaff + local.hr).toString(),
                  LucideIcons.briefcase,
                  success,
                  textColor,
                  onTap: () => setState(() => _activeModuleIndex = 12),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildStatCard(
                  "Active Accounts",
                  local.active.toString(),
                  LucideIcons.shieldCheck,
                  success,
                  textColor,
                  onTap: () => setState(() => _activeModuleIndex = 12),
                ),
                _buildStatCard(
                  "Suspended Accounts",
                  local.suspended.toString(),
                  LucideIcons.ban,
                  Colors.redAccent,
                  textColor,
                  onTap: () => setState(() => _activeModuleIndex = 12),
                ),
                _buildStatCard(
                  "Total Managed",
                  local.totalAccounts.toString(),
                  LucideIcons.users,
                  aViolet,
                  textColor,
                ),
                Expanded(
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
                        Text(
                          'Generate Reports',
                          style: GoogleFonts.inter(
                            color: textColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showPopulationReport(local),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: aViolet,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(LucideIcons.fileBarChart2),
                          label: const Text('Population Report'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: _buildAnalyticsCard(
                    "Live Role Distribution",
                    _buildRoleDistribution(local, textColor),
                    textColor,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 4,
                  child: _buildAnalyticsCard(
                    "Database Analytics Snapshot",
                    FutureBuilder<AdminAnalyticsSnapshot>(
                      future: _dbAnalyticsFuture,
                      builder: (context, snapshot) {
                        final data = snapshot.data ?? local;
                        return _buildSimpleLogsFromSnapshot(data, textColor);
                      },
                    ),
                    textColor,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showPopulationReport(AdminAnalyticsSnapshot snapshot) {
    final report = _adminService.generatePopulationReport(snapshot);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDarkMode ? surfaceDark : Colors.white,
        title: Text(
          'Generated Population Report',
          style: GoogleFonts.inter(
            color: _isDarkMode ? Colors.white : pViolet,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            report,
            style: GoogleFonts.inter(
              color: _isDarkMode ? Colors.white70 : Colors.black87,
              fontSize: 13,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: GoogleFonts.inter(color: aViolet),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDistribution(
      AdminAnalyticsSnapshot snapshot, Color textColor) {
    final items = snapshot.byRole.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (items.isEmpty) {
      return Text(
        'No analytics data available.',
        style: GoogleFonts.inter(color: _isDarkMode ? Colors.white70 : pViolet),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length > 7 ? 7 : items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final ratio = snapshot.totalAccounts == 0
            ? 0.0
            : item.value / snapshot.totalAccounts;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.key,
                    style: GoogleFonts.inter(color: textColor, fontSize: 13),
                  ),
                  Text(
                    item.value.toString(),
                    style: GoogleFonts.inter(
                      color: aViolet,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 10,
                  backgroundColor:
                      _isDarkMode ? Colors.white12 : Colors.black12,
                  valueColor: const AlwaysStoppedAnimation(aViolet),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimpleLogsFromSnapshot(
    AdminAnalyticsSnapshot snapshot,
    Color textColor,
  ) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _logRow('Total Profiles: ${snapshot.totalAccounts}', 'live',
            isSuccess: true),
        _logRow('Students: ${snapshot.students}', 'live', isSuccess: true),
        _logRow('Teachers: ${snapshot.teachers}', 'live'),
        _logRow('Program Chairs: ${snapshot.programChairs}', 'live'),
        _logRow('Admin Staff: ${snapshot.adminStaff}', 'live', isSuccess: true),
        _logRow('HR: ${snapshot.hr}', 'live', isSuccess: true),
        _logRow('Suspended: ${snapshot.suspended}', 'live'),
      ],
    );
  }

  Widget _buildAnalyticsCard(String title, Widget chart, Color textColor) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isDarkMode ? surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isDarkMode ? Colors.white10 : Colors.black12,
        ),
        boxShadow: _isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(child: chart),
        ],
      ),
    );
  }

  // CUSTOM PIE CHART
  Widget _buildPieChart() {
    return Center(
      child: SizedBox(
        width: 180,
        height: 180,
        child: CustomPaint(
          painter: PieChartPainter(),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "85%",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    color: aViolet,
                  ),
                ),
                Text(
                  "Verified",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // CUSTOM BAR CHART
  Widget _buildBarChart() {
    final List<double> values = [0.8, 0.4, 0.9, 0.6, 0.7, 0.5, 0.3];
    final List<String> labels = [
      "Reg",
      "Acc",
      "OSAS",
      "CMO",
      "Adm",
      "Lib",
      "PCH",
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(values.length, (i) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 35,
              height: 180 * values[i],
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [aViolet, aViolet.withOpacity(0.3)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              labels[i],
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.blueGrey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      }),
    );
  }

  // CUSTOM HISTOGRAM
  Widget _buildHistogram() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(15, (index) {
        double heightFactor = (math.sin(index * 0.5).abs() * 0.7) + 0.2;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            height: 200 * heightFactor,
            decoration: BoxDecoration(
              color: aViolet.withOpacity(index % 2 == 0 ? 0.8 : 0.4),
              border: Border.all(color: Colors.black12, width: 0.5),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSimpleLogs(Color textColor) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _logRow(
          "Admin #456 authorized Registrar sync",
          "2m ago",
          isSuccess: true,
        ),
        _logRow("Manual workload reduced by 15%", "15m ago", isSuccess: true),
        _logRow("Grade verification batch 4 initiated", "1h ago"),
        _logRow("OSAS database connectivity check", "3h ago", isSuccess: true),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    Color textColor, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
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
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
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

  Widget _logRow(String text, String time, {bool isSuccess = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            isSuccess ? LucideIcons.checkCircle2 : LucideIcons.activity,
            size: 16,
            color: isSuccess ? success : aViolet.withOpacity(0.5),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _isDarkMode ? Colors.white70 : pViolet,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            time,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.blueGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(
    IconData icon,
    Color subTextColor, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: subTextColor, size: 20),
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => SearchDialog(
        isDarkMode: _isDarkMode,
        onItemSelected: (index) {
          Navigator.pop(context);
          setState(() => _activeModuleIndex = index);
        },
      ),
    );
  }

  void _showNotificationsPanel() {
    showDialog(
      context: context,
      builder: (context) => NotificationsPanel(isDarkMode: _isDarkMode),
    );
  }
}

// SEARCH DIALOG CLASS
class SearchDialog extends StatefulWidget {
  final bool isDarkMode;
  final Function(int) onItemSelected;

  const SearchDialog({
    super.key,
    required this.isDarkMode,
    required this.onItemSelected,
  });

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  late TextEditingController _searchController;
  List<MapEntry<int, String>> _filteredItems = [];

  final List<MapEntry<int, String>> allItems = [
    const MapEntry(0, 'System Overview'),
    const MapEntry(1, 'Announcements'),
    const MapEntry(2, 'Admissions'),
    const MapEntry(3, 'Registrar'),
    const MapEntry(4, 'Accounting'),
    const MapEntry(6, 'Study Loads'),
    const MapEntry(7, 'Grade Recording'),
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredItems = allItems;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = allItems;
      } else {
        _filteredItems = allItems
            .where(
              (item) => item.value.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color aViolet = Color(0xFF8B5CF6);
    const Color surfaceDark = Color(0xFF1E1033);
    const Color tDark = Color(0xFF0F071D);
    const Color lBg = Color(0xFFF8FAFC);
    const Color pViolet = Color(0xFF2E1065);

    final bgColor = widget.isDarkMode ? tDark : lBg;
    final sideColor = widget.isDarkMode ? surfaceDark : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : pViolet;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        decoration: BoxDecoration(
          color: widget.isDarkMode ? sideColor : const Color(0xFFEDE9FE),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                widget.isDarkMode ? Colors.white10 : aViolet.withOpacity(0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Search Menu Items',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                onChanged: _filterItems,
                decoration: InputDecoration(
                  hintText: 'Type to search...',
                  prefixIcon: const Icon(LucideIcons.search, color: aViolet),
                  filled: true,
                  fillColor: widget.isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : pViolet.withOpacity(0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: widget.isDarkMode
                          ? Colors.white10
                          : aViolet.withOpacity(0.3),
                    ),
                  ),
                  hintStyle: GoogleFonts.inter(
                    color: widget.isDarkMode ? Colors.blueGrey : aViolet,
                  ),
                ),
                style: GoogleFonts.inter(color: textColor),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: _filteredItems.isEmpty
                    ? Center(
                        child: Text(
                          'No items found',
                          style: GoogleFonts.inter(color: Colors.blueGrey),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return ListTile(
                            title: Text(
                              item.value,
                              style: GoogleFonts.inter(
                                color: textColor,
                                fontSize: 14,
                              ),
                            ),
                            onTap: () {
                              widget.onItemSelected(item.key);
                            },
                            hoverColor: widget.isDarkMode
                                ? Colors.white10
                                : Colors.black12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// NOTIFICATIONS PANEL CLASS
class NotificationsPanel extends StatelessWidget {
  final bool isDarkMode;

  const NotificationsPanel({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    const Color aViolet = Color(0xFF8B5CF6);
    const Color surfaceDark = Color(0xFF1E1033);
    const Color tDark = Color(0xFF0F071D);
    const Color lBg = Color(0xFFF8FAFC);
    const Color pViolet = Color(0xFF2E1065);
    const Color success = Color(0xFF69F0AE);

    final bgColor = isDarkMode ? tDark : lBg;
    final sideColor = isDarkMode ? surfaceDark : Colors.white;
    final textColor = isDarkMode ? Colors.white : pViolet;

    // Hardcoded notifications
    final notifications = [
      {
        'title': 'New Student Enrollment',
        'message': '5 new students enrolled in Computer Science program',
        'time': '2m ago',
        'icon': LucideIcons.userPlus,
        'color': Colors.blueAccent,
      },
      {
        'title': 'Financial Clearance Updated',
        'message': '92% of students have completed financial clearance',
        'time': '15m ago',
        'icon': LucideIcons.checkCircle,
        'color': success,
      },
      {
        'title': 'Grade Recording Completed',
        'message': 'All grades for Fall 2025 semester have been recorded',
        'time': '1h ago',
        'icon': LucideIcons.award,
        'color': Colors.orangeAccent,
      },
      {
        'title': 'System Maintenance',
        'message': 'Scheduled maintenance completed successfully',
        'time': '3h ago',
        'icon': LucideIcons.wrench,
        'color': aViolet,
      },
      {
        'title': 'Course Registration Open',
        'message': 'Spring 2026 course registration is now open',
        'time': '5h ago',
        'icon': LucideIcons.bookOpen,
        'color': Colors.pinkAccent,
      },
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 450,
        decoration: BoxDecoration(
          color: sideColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode ? Colors.white10 : Colors.black12,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    color: Colors.blueGrey,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(
              color: isDarkMode ? Colors.white10 : Colors.black12,
              height: 0,
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDarkMode ? Colors.white10 : Colors.black12,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (notif['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            notif['icon'] as IconData,
                            color: notif['color'] as Color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notif['title'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif['message'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.blueGrey,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notif['time'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.blueGrey.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// PAINTER FOR PIE CHART
class PieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15;

    // Background Circle
    paint.color = Colors.blueGrey.withOpacity(0.1);
    canvas.drawCircle(center, radius, paint);

    // Active Segment
    paint.color = const Color(0xFF8B5CF6);
    paint.strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 1.7,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  @override
  bool hitTest(Offset position) => false;

  @override
  SemanticsBuilderCallback? get semanticsBuilder => null;
}
