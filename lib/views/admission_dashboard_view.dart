import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
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

  // Standardized Institutional Palette
  static const Color pViolet = Color(0xFF2E1065);
  static const Color tDark = Color(0xFF0F071D);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color success = Color(0xFF69F0AE);

  @override
  void initState() {
    super.initState();
  }

  void _toggleSidebar() =>
      setState(() => _isSidebarExpanded = !_isSidebarExpanded);

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Secure Logout",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            child: const Text("LOGOUT SYSTEM"),
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
        ],
      ),
    );
  }

  Widget _buildTopBar(Color textColor) {
    // RESOLVE USER IDENTITY: Extracting from the userData map passed from Supabase login
    final String fullName =
        "${widget.userData['fn'] ?? ''} ${widget.userData['ln'] ?? ''}"
            .toUpperCase();
    final String role =
        (widget.userData['role'] ?? 'OFFICER').toString().toUpperCase();

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
          const SizedBox(width: 24),
          const VerticalDivider(
              color: Colors.white10, indent: 20, endIndent: 20),
          const SizedBox(width: 24),

          // 🛰️ DYNAMIC PROFILE: Connected to DB Context
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(fullName,
                  style: GoogleFonts.inter(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              Text(role,
                  style: GoogleFonts.inter(
                      color: success,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ],
          ),
          const SizedBox(width: 12),
          const CircleAvatar(
            backgroundColor: aViolet,
            child: Icon(LucideIcons.userCheck, color: Colors.white, size: 18),
          ),
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
                _menuItem(LucideIcons.user, "Profile", 5),
                _sidebarHeader("TRANSACTIONS"),
                _menuItem(LucideIcons.history, "Transaction History", 2),
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
}
