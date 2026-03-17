import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/supabase_service.dart';
import '../components/admission_panel_content.dart';

class AdmissionDashboardView extends StatefulWidget {
  final VoidCallback onLogout;
  final Map<String, dynamic> userData;
  const AdmissionDashboardView(
      {super.key, required this.onLogout, required this.userData});

  @override
  State<AdmissionDashboardView> createState() => _AdmissionDashboardViewState();
}

class _AdmissionDashboardViewState extends State<AdmissionDashboardView> {
  // Navigation & Theme State
  bool _isDarkMode = true;
  bool _isSidebarExpanded = true;
  int _selectedIndex = 0;
  bool _isLoadingStats = false;

  // Admission Stats from Database
  int _totalPending = 0;
  int _admittedToday = 0;

  // Standardized Violet/Plum Palette
  static const Color pViolet = Color(0xFF2E1065);
  static const Color tDark = Color(0xFF0F071D);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color success = Color(0xFF69F0AE);

  @override
  void initState() {
    super.initState();
    _fetchLiveAdmissionStats();
  }

  /// CRITICAL: Fetches aggregate counts from Supabase for the header cards
  Future<void> _fetchLiveAdmissionStats() async {
    setState(() => _isLoadingStats = true);
    final client = SupabaseService().client;

    try {
      final results = await Future.wait([
        // Total Pending Apps
        client.from('applicants').select('id').eq('status', 'Pending'),
        // Admitted Today (Filters by date and status)
        client.from('applicants').select('id').eq('status', 'Verified'),
      ]);

      if (mounted) {
        setState(() {
          _totalPending = (results[0] as List).length;
          _admittedToday = (results[1] as List).length;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint("Admission Stats Sync Error: $e");
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  void _toggleSidebar() =>
      setState(() => _isSidebarExpanded = !_isSidebarExpanded);

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceDark,
        title:
            const Text("Secure Logout", style: TextStyle(color: Colors.white)),
        content: const Text("Terminate active administrative session?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onLogout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("LOGOUT"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode ? tDark : const Color(0xFFF8FAFC);
    final textColor = _isDarkMode ? Colors.white : pViolet;

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
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGreetingAndStats(textColor),
                        if (_selectedIndex == 0) const SizedBox(height: 40),
                        // THE BRIDGE: Switches between modular Admission sub-panels
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: AdmissionPanelContent(
                              key: ValueKey(_selectedIndex),
                              selectedIndex: _selectedIndex,
                              isDarkMode: _isDarkMode,
                              userData: widget.userData,
                            ),
                          ),
                        ),
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

  Widget _buildGreetingAndStats(Color textColor) {
    if (_selectedIndex != 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Admissions Pipeline",
            style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: -1)),
        const Text(
            "Real-time monitoring of applicant intake and verification status.",
            style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
        const SizedBox(height: 32),
        Row(
          children: [
            _statCard("Pending Apps", _totalPending.toString(),
                LucideIcons.fileText, aViolet, textColor),
            _statCard("Verified Status", _admittedToday.toString(),
                LucideIcons.checkCircle, success, textColor),
          ],
        ),
      ],
    );
  }

  Widget _buildTopBar(Color textColor) {
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
            "Admissions Intelligence Terminal",
            style: GoogleFonts.inter(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
            icon: Icon(_isDarkMode ? LucideIcons.sun : LucideIcons.moon,
                color: aViolet),
          ),
          const SizedBox(width: 20),
          _headerAction(LucideIcons.bell, textColor.withOpacity(0.5)),
          const SizedBox(width: 24),
          const VerticalDivider(
              color: Colors.white10, indent: 20, endIndent: 20),
          const SizedBox(width: 24),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("ADMISSIONS_OFFICER",
                  style: GoogleFonts.inter(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              Text("Verified Session",
                  style: GoogleFonts.inter(
                      color: success,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 12),
          CircleAvatar(
              backgroundColor: aViolet,
              child: const Icon(LucideIcons.userPlus,
                  color: Colors.white, size: 18)),
        ],
      ),
    );
  }

  Widget _buildSidebar(Color textColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isSidebarExpanded ? 260 : 85,
      color: _isDarkMode ? pViolet : const Color(0xFFF1F5F9),
      child: Column(
        children: [
          const SizedBox(height: 30),
          _buildLogo(textColor),
          const SizedBox(height: 40),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _menuItem(LucideIcons.layoutDashboard, "Overview", 0),
                _sidebarHeader("APPLICANT MANAGEMENT"),
                _menuItem(LucideIcons.fileText, "Applications", 1),
                _menuItem(LucideIcons.shieldCheck, "Document Verification", 3),
                _sidebarHeader("ENROLLMENT"),
                _menuItem(LucideIcons.userCheck, "Enrollment Verification", 6),
                _sidebarHeader("COMMUNICATIONS"),
                _menuItem(LucideIcons.mail, "Messaging", 4),
                _sidebarHeader("TRANSACTIONS"),
                _menuItem(LucideIcons.mail, "Transaction History", 2),
              ],
            ),
          ),
          const Divider(color: Colors.white10),
          _menuItem(LucideIcons.logOut, "Logout System", 8,
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
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: onTap ??
            () => setState(() {
                  _selectedIndex = index;
                  _fetchLiveAdmissionStats(); // Refresh stats on navigation
                }),
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

  Widget _statCard(
      String label, String val, IconData icon, Color color, Color text) {
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 15),
            _isLoadingStats
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.blueGrey))
                : Text(val,
                    style: GoogleFonts.orbitron(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: text)),
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

  Widget _buildLogo(Color textColor) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.school, color: aViolet, size: 24),
          if (_isSidebarExpanded) ...[
            const SizedBox(width: 12),
            Text("UEMS Intake",
                style: GoogleFonts.orbitron(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ]
        ],
      );

  Widget _headerAction(IconData icon, Color color) => Container(
      padding: const EdgeInsets.all(10),
      decoration:
          BoxDecoration(color: color.withOpacity(0.05), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 20));
}
