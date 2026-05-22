import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../components/shared/messaging_panel.dart';
import '../services/supabase_service.dart';

class TeacherDashboardView extends StatefulWidget {
  final VoidCallback onLogout;
  final Map<String, dynamic> userData; // Context for the logged-in Teacher

  const TeacherDashboardView(
      {super.key, required this.onLogout, required this.userData});

  @override
  State<TeacherDashboardView> createState() => _TeacherDashboardViewState();
}

class _TeacherDashboardViewState extends State<TeacherDashboardView> {
  final SupabaseService _service = SupabaseService();

  // Navigation & Theme State
  bool _isDarkMode = true;
  bool _isSidebarExpanded = true;
  int _selectedIndex = 0;

  // Database Data State
  List<Map<String, dynamic>> _myClasses = [];
  int _studentCount = 0;
  int _classesToday = 0;
  bool _isLoading = true;

  // Standardized Violet/Plum Palette
  static const Color pViolet = Color(0xFF2E1065);
  static const Color tDark = Color(0xFF0F071D);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color success = Color(0xFF69F0AE);

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  /// 🛰️ DATABASE: Fetch instructional load and aggregate stats
  Future<void> _loadTeacherData() async {
    setState(() => _isLoading = true);
    final String profId = widget.userData['id'];

    try {
      // 1. Fetch assigned classes from study_loads
      final response = await _service.client
          .from('study_loads')
          .select('*, subjects(*)')
          .eq('professor_id', profId);

      final List<Map<String, dynamic>> data =
          List<Map<String, dynamic>>.from(response);

      // 2. Compute Aggregates
      // Count unique students across all assigned subjects
      final Set<String> uniqueStudents =
          data.map((e) => e['student_id']?.toString() ?? "").toSet();
      uniqueStudents.remove(""); // Remove null/empty entries (Master Schedules)

      // Count classes scheduled for today (Simulated based on day_schedule matching current day)
      final String today = _getTodayDayCode();
      final int countToday = data
          .where((e) => e['day_schedule'].toString().contains(today))
          .length;

      if (mounted) {
        setState(() {
          _myClasses = data;
          _studentCount = uniqueStudents.length;
          _classesToday = countToday;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Faculty Sync Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getTodayDayCode() {
    final now = DateTime.now();
    switch (now.weekday) {
      case 1:
        return "M";
      case 2:
        return "TUE";
      case 3:
        return "WED";
      case 4:
        return "THU";
      case 5:
        return "FRI";
      case 6:
        return "SAT";
      default:
        return "SUN";
    }
  }

  void _toggleSidebar() =>
      setState(() => _isSidebarExpanded = !_isSidebarExpanded);
  void _toggleTheme() => setState(() => _isDarkMode = !_isDarkMode);

  Future<void> _confirmLogout() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDarkMode ? surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Confirm Logout",
          style: GoogleFonts.inter(
            color: _isDarkMode ? Colors.white : pViolet,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          "Do you want to log out from the faculty portal?",
          style: GoogleFonts.inter(
            color: _isDarkMode ? Colors.white70 : Colors.blueGrey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode ? tDark : const Color(0xFFF8FAFC);
    final panelColor = _isDarkMode ? surfaceDark : Colors.white;
    final textColor = _isDarkMode ? Colors.white : pViolet;
    final subTextColor = _isDarkMode ? Colors.white54 : Colors.blueGrey;

    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          _buildSidebar(panelColor, textColor, subTextColor),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(textColor, subTextColor),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: aViolet))
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _buildPanelContent(
                              panelColor, textColor, subTextColor),
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
            "Faculty Instruction & Management Portal",
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
              tooltip: "Switch Theme"),
          const SizedBox(width: 24),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                  "${widget.userData['fn']} ${widget.userData['ln']}"
                      .toUpperCase(),
                  style: GoogleFonts.inter(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              Text("Academic Faculty",
                  style: GoogleFonts.inter(
                      color: success,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 12),
          const CircleAvatar(
              backgroundColor: aViolet,
              child:
                  Icon(LucideIcons.user, color: Colors.white, size: 18)),
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
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(LucideIcons.graduationCap,
                    color: aViolet, size: 24),
              ),
              if (_isSidebarExpanded) ...[
                const SizedBox(width: 12),
                Text("UEMSSP Faculty Teacher",
                    style: GoogleFonts.orbitron(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _menuItem(LucideIcons.layoutDashboard, "Overview", 0),
                _sidebarHeader("AACADEMIC MANAGEMENT"),
                _menuItem(LucideIcons.calendar, "Classes & Schedules", 1),
                _menuItem(LucideIcons.uploadCloud, "Grade Recording", 5),
                _menuItem(LucideIcons.bookOpen, "Learning Resources", 3),
                _sidebarHeader("FACULTY SERVICES"),
                _menuItem(LucideIcons.messagesSquare, "Messenger", 7),
                _menuItem(LucideIcons.briefcase, "Teaching Load", 8),
              ],
            ),
          ),
          const Divider(color: Colors.white10),
          _menuItem(LucideIcons.logOut, "Logout System", 9,
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
          borderRadius: BorderRadius.circular(14)),
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

  Widget _buildPanelContent(
      Color panelColor, Color textColor, Color subTextColor) {
    switch (_selectedIndex) {
      case 7:
        return MessagingPanel(
            isDarkMode: _isDarkMode, userData: widget.userData);
      case 1:
        return _buildSchedulePanel(panelColor, textColor);
      case 5:
        return _buildGradingPanel(panelColor, textColor);
      case 0:
      default:
        return _buildOverviewPanel(panelColor, textColor);
    }
  }

  Widget _buildOverviewPanel(Color panelColor, Color textColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Faculty Overview",
              style: GoogleFonts.inter(
                  fontSize: 28, fontWeight: FontWeight.w900, color: textColor)),
          const SizedBox(height: 32),
          Row(
            children: [
              _statCard("Students Taught", _studentCount.toString(),
                  LucideIcons.users, aViolet, textColor),
              _statCard("Total Assignments", _myClasses.length.toString(),
                  LucideIcons.layers, Colors.orangeAccent, textColor),
              _statCard("Classes Today", _classesToday.toString(),
                  LucideIcons.calendar, Colors.blueAccent, textColor),
            ],
          ),
          const SizedBox(height: 32),
          _buildActionGrid(panelColor, textColor),
        ],
      ),
    );
  }

  Widget _buildSchedulePanel(Color panelColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Current Course Assignments",
              style: GoogleFonts.inter(
                  fontSize: 28, fontWeight: FontWeight.w900, color: textColor)),
          const SizedBox(height: 24),
          Expanded(
            child: _myClasses.isEmpty
                ? const Center(
                    child: Text("No courses assigned for this semester.",
                        style: TextStyle(color: Colors.white24)))
                : ListView.builder(
                    itemCount: _myClasses.length,
                    itemBuilder: (context, i) {
                      final cls = _myClasses[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                            color: panelColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white10)),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.book, color: aViolet),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      cls['subjects']?['name'] ??
                                          "Unknown Subject",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                  Text(
                                      "${cls['day_schedule']} • ${cls['time_start']} - ${cls['time_end']}",
                                      style: const TextStyle(
                                          color: Colors.blueGrey,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            _badge(cls['section_block'] ?? "N/A", success),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradingPanel(Color panelColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Grade Recording Hub",
              style: GoogleFonts.inter(
                  fontSize: 28, fontWeight: FontWeight.w900, color: textColor)),
          const SizedBox(height: 24),
          Text("Select a class to encode academic outcomes:",
              style: TextStyle(color: textColor.withOpacity(0.5))),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16),
              itemCount: _myClasses.length,
              itemBuilder: (context, i) {
                final cls = _myClasses[i];
                return _classCard(cls['subjects']?['name'] ?? "Subject",
                    cls['section_block'] ?? "Block", panelColor, textColor);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      String label, String val, IconData icon, Color color, Color textColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: _isDarkMode ? surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: _isDarkMode ? Colors.white10 : Colors.black12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 15),
            Text(val,
                style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: textColor)),
            Text(label,
                style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
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
            "Class Attendance", LucideIcons.clipboardCheck, success),
        _quickActionButton(
            "Exam Management", LucideIcons.fileText, Colors.orange),
      ],
    );
  }

  Widget _quickActionButton(String label, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
          color: _isDarkMode ? surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: _isDarkMode ? Colors.white10 : Colors.black12)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label,
            style: TextStyle(
                color: _isDarkMode ? Colors.white : pViolet,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        trailing: const Icon(LucideIcons.chevronRight,
            size: 16, color: Colors.white24),
        onTap: () {},
      ),
    );
  }

  Widget _classCard(
      String name, String section, Color panelColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          const Icon(LucideIcons.book, color: aViolet, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                    overflow: TextOverflow.ellipsis),
                Text(section,
                    style:
                        const TextStyle(color: Colors.white24, fontSize: 12)),
              ],
            ),
          ),
          const Icon(LucideIcons.arrowRight, color: Colors.white12, size: 16),
        ],
      ),
    );
  }

  Widget _badge(String t, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(t,
          style:
              TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.bold)));
}
