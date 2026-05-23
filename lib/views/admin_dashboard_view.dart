import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/admin_panel_content.dart';
import '../services/supabase_service.dart';
import '../services/security_service.dart';

class AdminDashboardView extends StatefulWidget {
  final VoidCallback onLogout;
  final Map<String, dynamic> userData;

  const AdminDashboardView(
      {super.key, required this.onLogout, required this.userData});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  final SupabaseService _service = SupabaseService();
  bool _isSidebarExpanded = true;
  bool _isDarkMode = true;
  int _activeModuleIndex = 0;

  // Institutional Panel Mapping
  final List<String> _panelTypes = [
    'overview', // 0
    'announcements', // 1
    'office_admin', // 2
    'lifecycle', // 3
    'scholastic', // 4
    'security', // 5
    'hr', // 6
    'messaging', // 7
    'reports', // 8
  ];

  // Palette
  static const Color pViolet = Color(0xFF2E1065);
  static const Color tDark = Color(0xFF0F071D);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color success = Color(0xFF69F0AE);

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
          "Are you sure you want to logout from the system?",
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
  void initState() {
    super.initState();
    SecurityService().startInactivityMonitoring(onTimeout: widget.onLogout);
  }

  @override
  void dispose() {
    SecurityService().stopInactivityMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode ? tDark : const Color(0xFFF8FAFC);
    final sideColor = _isDarkMode ? surfaceDark : const Color(0xFFF1F5F9);
    final textColor = _isDarkMode ? Colors.white : pViolet;
    final subTextColor = _isDarkMode ? Colors.white54 : Colors.blueGrey;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => SecurityService().resetInactivityTimer(),
      onPointerMove: (_) => SecurityService().resetInactivityTimer(),
      onPointerSignal: (_) => SecurityService().resetInactivityTimer(),
      child: Scaffold(
        backgroundColor: bgColor,
        body: Row(
          children: [
            _buildSidebar(sideColor, textColor, subTextColor),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(sideColor, textColor, subTextColor),
                  // 🛰️ DYNAMIC CONTENT VIEWPORT
                  // FIXED: Wrapped in Expanded to provide a bounded height constraint.
                  // This allows sub-panels to use Expanded and Flexible widgets internally
                  // without triggering "unbounded height" layout exceptions.
                  Expanded(
                    child: _buildModuleRouter(textColor, subTextColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleRouter(Color textColor, Color subTextColor) {
    // Index 0: Institutional Intelligence (Overview)
    // Overview requires its own scroll view since it's a long static dashboard.
    if (_activeModuleIndex == 0) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        physics: const BouncingScrollPhysics(),
        child: _buildInstitutionalIntelligence(textColor, subTextColor),
      );
    }

    // Indices 1-8: Specialized Admin Modules
    // We pass the bounded height context to the router.
    if (_activeModuleIndex <= 8) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: AdminPanelContent(
          selectedIndex: _activeModuleIndex,
          isDarkMode: _isDarkMode,
          userData: widget.userData,
        ),
      );
    }

    return const Center(
        child: Text("Administrative Module Under Configuration"));
  }

  Widget _buildTopBar(Color sideColor, Color textColor, Color subTextColor) {
    final String firstName = (widget.userData['fn'] ?? 'Admin').toString();
    final String lastName = (widget.userData['ln'] ?? '').toString();

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: sideColor,
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
            onPressed: () =>
                setState(() => _isSidebarExpanded = !_isSidebarExpanded),
          ),
          const SizedBox(width: 16),
          Text("Institutional System Control",
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: -0.5)),
          const Spacer(),
          IconButton(
            onPressed: _toggleTheme,
            icon: Icon(_isDarkMode ? LucideIcons.sun : LucideIcons.moon,
                color: aViolet),
          ),
          const SizedBox(width: 24),
          const VerticalDivider(
              color: Colors.white10, indent: 20, endIndent: 20),
          const SizedBox(width: 24),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("$firstName $lastName".toUpperCase(),
                  style: GoogleFonts.inter(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              const Text("SYSTEM ADMINISTRATOR",
                  style: TextStyle(
                      color: success,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ],
          ),
          const SizedBox(width: 12),
          const CircleAvatar(
            backgroundColor: aViolet,
            child: Icon(LucideIcons.shieldCheck, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(Color sideColor, Color textColor, Color subTextColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isSidebarExpanded ? 280 : 85,
      color: sideColor,
      child: Column(
        children: [
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.shield, color: aViolet, size: 28),
                if (_isSidebarExpanded) ...[
                  const SizedBox(width: 12),
                  Text("UEMS ADMIN",
                      style: GoogleFonts.orbitron(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _sidebarHeader("CENTRAL CONTROL"),
                _sidebarItem(LucideIcons.layoutDashboard, "System Overview", 0),
                _sidebarItem(LucideIcons.megaphone, "Broadcasting", 1),
                _sidebarHeader("INSTITUTIONAL LOGIC"),
                _sidebarItem(LucideIcons.calendar, "Academic Lifecycle", 3),
                _sidebarItem(LucideIcons.fileEdit, "Scholastic Control", 4),
                _sidebarItem(LucideIcons.shieldAlert, "Access & Security", 5),
                _sidebarHeader("MANAGEMENT"),
                _sidebarItem(LucideIcons.users, "HR / Workforce", 6),
                _sidebarItem(LucideIcons.messageSquare, "Messaging", 7),
                _sidebarItem(LucideIcons.alertTriangle, "System Reports", 8),
              ],
            ),
          ),
          const Divider(color: Colors.white10, indent: 20, endIndent: 20),
          _sidebarItem(LucideIcons.logOut, "Logout System", 9,
              isDestructive: true, onTap: _confirmLogout),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInstitutionalIntelligence(Color textColor, Color subTextColor) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchLiveAnalytics(),
      builder: (context, snapshot) {
        final data = snapshot.data ??
            {
              'students': 0,
              'faculty': 0,
              'pending_apps': 0,
              'pending_req': 0,
              'revenue': 0.0
            };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("System Overview",
                style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: textColor)),
            const SizedBox(height: 32),
            Row(
              children: [
                _statCard("STUDENTS", data['students'].toString(),
                    LucideIcons.graduationCap, aViolet, textColor),
                _statCard("FACULTY", data['faculty'].toString(),
                    LucideIcons.bookOpen, Colors.blueAccent, textColor),
                _statCard("PENDING INTAKE", data['pending_apps'].toString(),
                    LucideIcons.userPlus, Colors.orangeAccent, textColor),
                _statCard("DOCUMENT QUEUE", data['pending_req'].toString(),
                    LucideIcons.fileText, success, textColor),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _statCard(
                    "TOTAL COLLECTIONS",
                    "₱${NumberFormat('#,###').format(data['revenue'])}",
                    LucideIcons.banknote,
                    success,
                    textColor),
                _statCard("SYSTEM STATUS", "OPTIMAL", LucideIcons.activity,
                    aViolet, textColor),
              ],
            ),
            const SizedBox(height: 32),
            _buildRecentActivityStream(textColor),
          ],
        );
      },
    );
  }

  /// 🛰️ DATABASE: Aggregate real counters using standardized fetch logic
  Future<Map<String, dynamic>> _fetchLiveAnalytics() async {
    try {
      final res = await Future.wait([
        _service.client.from('profiles').select('id').eq('role', 'student'),
        _service.client
            .from('profiles')
            .select('id')
            .filter('role', 'in', '("professor","faculty")'),
        _service.client.from('applicants').select('id').eq('status', 'Pending'),
        _service.client
            .from('office_requests')
            .select('id')
            .eq('request_status', 'Submitted'),
        _service.client
            .from('payments')
            .select('amount')
            .eq('status', 'Success'),
      ]);

      double totalRevenue = 0;
      final List payments = (res[4] as List? ?? []);
      for (var p in payments) {
        totalRevenue += (p['amount'] ?? 0).toDouble();
      }

      return {
        'students': (res[0] as List? ?? []).length,
        'faculty': (res[1] as List? ?? []).length,
        'pending_apps': (res[2] as List? ?? []).length,
        'pending_req': (res[3] as List? ?? []).length,
        'revenue': totalRevenue,
      };
    } catch (e) {
      return {
        'students': 0,
        'faculty': 0,
        'pending_apps': 0,
        'pending_req': 0,
        'revenue': 0.0
      };
    }
  }

  Widget _buildRecentActivityStream(Color textColor) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _isDarkMode ? surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("REAL-TIME SYSTEM ACTIVITY",
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: aViolet,
                  letterSpacing: 1.5)),
          const SizedBox(height: 24),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _service.client
                .from('office_requests')
                .stream(primaryKey: ['id']).limit(5),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              final logs = snapshot.data ?? [];

              if (logs.isEmpty) {
                return const Text("No recent activity.",
                    style: TextStyle(color: Colors.blueGrey, fontSize: 12));
              }

              return Column(
                children: logs.map((log) {
                  final String sid = (log['student_id'] ?? '').toString();
                  final String displayId =
                      sid.length > 8 ? sid.substring(0, 8) : sid;
                  return _logRow(
                      "Student ID $displayId requested ${(log['request_type'] ?? 'Document')}",
                      "Just now",
                      isSuccess: true);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- UI UTILS ---

  Widget _sidebarItem(IconData icon, String label, int index,
      {bool isDestructive = false, VoidCallback? onTap}) {
    bool isSelected = _activeModuleIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? aViolet.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: onTap ?? () => setState(() => _activeModuleIndex = index),
        visualDensity: VisualDensity.compact,
        leading: Icon(icon,
            color: isSelected
                ? (isDestructive ? Colors.redAccent : aViolet)
                : Colors.blueGrey,
            size: 20),
        title: _isSidebarExpanded
            ? Text(label,
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
              // Ensure visibility in light mode
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: _isDarkMode
                  ? Colors.blueGrey.withOpacity(0.5)
                  : Colors.black.withOpacity(0.5),
              letterSpacing: 1.5)),
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color, Color textColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _isDarkMode ? surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: _isDarkMode ? Colors.white10 : Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20)),
            const SizedBox(height: 20),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: textColor)),
            Text(label,
                style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _logRow(String text, String time, {bool isSuccess = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(isSuccess ? LucideIcons.checkCircle2 : LucideIcons.activity,
              size: 16, color: isSuccess ? success : aViolet.withOpacity(0.5)),
          const SizedBox(width: 14),
          Expanded(
              child: Text(text,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: _isDarkMode ? Colors.white70 : pViolet,
                      fontWeight: FontWeight.w500))),
          Text(time,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
