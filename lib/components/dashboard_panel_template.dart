import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';

class DashboardPanelTemplate extends StatefulWidget {
  final String panelTitle;
  final String subtitle;
  final Widget panelContent;
  final List<PanelMenuItem> sidebarItems;
  final VoidCallback onLogout;
  final bool isDarkMode;
  final Function(int) onMenuItemSelected;
  final int selectedIndex;
  final bool isSidebarExpanded;
  final Function(bool) onSidebarToggle;
  final bool isAdminPanel;
  final VoidCallback? themeToggle;
  final String? logoText;
  final IconData? logoIcon;
  final Map<String, dynamic>? userData;
  final List<Map<String, dynamic>> notifications;

  const DashboardPanelTemplate({
    super.key,
    required this.panelTitle,
    required this.subtitle,
    required this.panelContent,
    required this.sidebarItems,
    required this.onLogout,
    required this.isDarkMode,
    required this.onMenuItemSelected,
    required this.selectedIndex,
    required this.isSidebarExpanded,
    required this.onSidebarToggle,
    this.isAdminPanel = false,
    this.themeToggle,
    this.logoText,
    this.logoIcon,
    this.userData,
    this.notifications = const [],
  });

  @override
  State<DashboardPanelTemplate> createState() => _DashboardPanelTemplateState();
}

class _DashboardPanelTemplateState extends State<DashboardPanelTemplate> {
  // Institutional Palette
  static const Color pViolet = Color(0xFF2E1065);
  static const Color tDark = Color(0xFF0F071D);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1033);
  static const Color success = Color(0xFF69F0AE);

  /// 🛰️ DATABASE: Secure Logout with Attendance Sync
  /// Connects to Supabase to record check-out for faculty/staff before terminating session.
  Future<void> _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Secure Logout",
            style: GoogleFonts.inter(
                color: widget.isDarkMode ? Colors.white : pViolet,
                fontWeight: FontWeight.bold)),
        content: const Text(
            "Are you sure you want to terminate your active administrative session?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("CANCEL",
                  style: TextStyle(color: Colors.blueGrey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white),
            child: const Text("LOGOUT"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 1. Attendance Sync (Non-students)
      final String role =
          (widget.userData?['role'] ?? '').toString().toLowerCase();
      final String? userId = widget.userData?['id']?.toString();

      if (role != 'student' && userId != null) {
        try {
          await SupabaseService().recordAttendanceLogout(userId);
        } catch (e) {
          debugPrint("Logout Attendance Sync Failed: $e");
        }
      }

      // 2. Trigger parent logout
      widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? tDark : const Color(0xFFF8FAFC);
    final bool isSidebarDark = widget.isAdminPanel || widget.isDarkMode;
    final sidebarColor = widget.isAdminPanel
        ? pViolet
        : (widget.isDarkMode ? pViolet : const Color(0xFFF1F5F9));

    final sidebarTextColor = isSidebarDark ? Colors.white : pViolet;
    final sidebarSubTextColor =
        isSidebarDark ? Colors.white60 : Colors.blueGrey;
    final textColor = widget.isDarkMode ? Colors.white : pViolet;
    final subTextColor = widget.isDarkMode ? Colors.white70 : Colors.blueGrey;

    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          // --- SIDEBAR NAVIGATION ---
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: widget.isSidebarExpanded ? 280 : 80,
            color: sidebarColor,
            child: Column(
              children: [
                const SizedBox(height: 30),
                Row(
                  children: [
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: aViolet.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(
                        widget.logoIcon ??
                            (widget.isAdminPanel
                                ? LucideIcons.shield
                                : LucideIcons.graduationCap),
                        color: aViolet,
                        size: 24,
                      ),
                    ),
                    if (widget.isSidebarExpanded) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                            widget.logoText ??
                                (widget.isAdminPanel
                                    ? "ADMIN CORE"
                                    : "UEMSSP PORTAL"),
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.orbitron(
                                color: sidebarTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                    ],
                  ],
                ),
                if (!widget.isSidebarExpanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: IconButton(
                        icon: Icon(LucideIcons.chevronRight,
                            color: sidebarSubTextColor, size: 20),
                        onPressed: () => widget.onSidebarToggle(true)),
                  ),
                const SizedBox(height: 40),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: widget.sidebarItems.length,
                    itemBuilder: (context, index) {
                      final item = widget.sidebarItems[index];
                      final bool isSelected = widget.selectedIndex == index;
                      final bool isDestructive =
                          item.title.toLowerCase().contains('logout');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? aViolet.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          onTap: () => isDestructive
                              ? _handleLogout()
                              : widget.onMenuItemSelected(index),
                          minLeadingWidth: 20,
                          leading: Icon(item.icon,
                              color: isDestructive
                                  ? Colors.redAccent
                                  : (isSelected
                                      ? (isSidebarDark ? Colors.white : pViolet)
                                      : sidebarSubTextColor),
                              size: 20),
                          title: widget.isSidebarExpanded
                              ? Text(item.title,
                                  style: GoogleFonts.inter(
                                      color: isDestructive
                                          ? Colors.redAccent
                                          : (isSelected
                                              ? (isSidebarDark
                                                  ? Colors.white
                                                  : pViolet)
                                              : sidebarSubTextColor),
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      fontSize: 14))
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // --- MAIN SYSTEM VIEWPORT ---
          Expanded(
            child: Column(
              children: [
                _buildTopBar(textColor, subTextColor),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.panelTitle,
                            style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: textColor)),
                        if (widget.subtitle.isNotEmpty)
                          Text(widget.subtitle,
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: subTextColor,
                                  fontWeight: FontWeight.w500)),
                        const SizedBox(height: 32),
                        widget.panelContent,
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

  Widget _buildTopBar(Color textColor, Color subTextColor) {
    // 🛰️ DYNAMIC IDENTITY RESOLUTION: Robust extraction logic matching Supabase profiles
    final String fn =
        (widget.userData?['fn'] ?? widget.userData?['first_name'] ?? '')
            .toString();
    final String ln =
        (widget.userData?['ln'] ?? widget.userData?['last_name'] ?? '')
            .toString();
    final String role =
        (widget.userData?['role'] ?? 'Identity Pending').toString();
    final String idNum =
        (widget.userData?['user_id_number'] ?? 'N/A').toString();

    // Automatic initials calculation for the avatar
    String initials = "U";
    if (fn.isNotEmpty && ln.isNotEmpty) {
      initials = "${fn[0]}${ln[0]}".toUpperCase();
    } else if (fn.isNotEmpty) {
      initials = fn[0].toUpperCase();
    }

    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? tDark : Colors.white,
        border: Border(
            bottom: BorderSide(
                color: widget.isDarkMode ? Colors.white10 : Colors.black12)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
                widget.isSidebarExpanded
                    ? LucideIcons.menu
                    : LucideIcons.chevronRight,
                color: textColor,
                size: 20),
            onPressed: () => widget.onSidebarToggle(!widget.isSidebarExpanded),
          ),
          const SizedBox(width: 12),
          Text(
              widget.isAdminPanel
                  ? "Command Intelligence Hub"
                  : "Student Identity Terminal",
              style: GoogleFonts.inter(
                  color: subTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const Spacer(),

          // --- NOTIFICATIONS (FETCHED FROM ANNOUNCEMENTS LEDGER) ---
          _buildNotificationButton(subTextColor),

          const SizedBox(width: 12),
          IconButton(
            icon: Icon(widget.isDarkMode ? LucideIcons.sun : LucideIcons.moon,
                color: subTextColor, size: 18),
            onPressed: () => widget.themeToggle?.call(),
          ),

          const SizedBox(width: 24),
          const VerticalDivider(
              indent: 20, endIndent: 20, color: Colors.white10),
          const SizedBox(width: 24),

          // --- IDENTITY BLOCK: USER NAME & ROLE (TOP RIGHT) ---
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                  "${fn.isEmpty && ln.isEmpty ? 'Identifying User...' : '$fn $ln'}"
                      .toUpperCase(),
                  style: GoogleFonts.inter(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 12)),
              Text(role == 'student' ? "ID: $idNum" : role.toUpperCase(),
                  style: GoogleFonts.inter(
                      color: success,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
            ],
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 18,
            backgroundColor: aViolet,
            child: Text(initials,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton(Color color) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(LucideIcons.bell, color: color, size: 20),
          onPressed: () => _showNotificationSheet(),
        ),
        if (widget.notifications.isNotEmpty)
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
                      color: widget.isDarkMode ? tDark : Colors.white,
                      width: 1.5)),
            ),
          ),
      ],
    );
  }

  void _showNotificationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.isDarkMode ? tDark : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Institutional Notices',
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: widget.isDarkMode ? Colors.white : pViolet)),
                  IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            const Divider(height: 32, color: Colors.white10),
            if (widget.notifications.isEmpty)
              Padding(
                padding: const EdgeInsets.all(60),
                child: Column(
                  children: [
                    Icon(LucideIcons.megaphone,
                        color: Colors.blueGrey.withOpacity(0.2), size: 48),
                    const SizedBox(height: 16),
                    const Text("No active institutional notices found.",
                        style: TextStyle(
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.notifications.length,
                  separatorBuilder: (_, __) => const Divider(
                      color: Colors.white10, indent: 24, endIndent: 24),
                  itemBuilder: (context, i) {
                    final n = widget.notifications[i];
                    String dateStr = "Recent";
                    if (n['created_at'] != null) {
                      try {
                        DateTime parsed =
                            DateTime.parse(n['created_at'].toString());
                        dateStr = DateFormat('MMM dd, hh:mm a')
                            .format(parsed.toLocal());
                      } catch (e) {
                        dateStr = "Today";
                      }
                    }

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: aViolet.withOpacity(0.1),
                              shape: BoxShape.circle),
                          child: const Icon(LucideIcons.megaphone,
                              color: aViolet, size: 18)),
                      title: Text(n['title'] ?? 'System Notice',
                          style: TextStyle(
                              color: widget.isDarkMode ? Colors.white : pViolet,
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
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Text(dateStr,
                              style: TextStyle(
                                  color: aViolet.withOpacity(0.6),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
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

class PanelMenuItem {
  final String title;
  final IconData icon;
  const PanelMenuItem({required this.title, required this.icon});
}
