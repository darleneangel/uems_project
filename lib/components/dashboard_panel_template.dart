import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
  });

  @override
  State<DashboardPanelTemplate> createState() => _DashboardPanelTemplateState();
}

class _DashboardPanelTemplateState extends State<DashboardPanelTemplate> {
  // Violet Theme Colors
  static const Color pViolet = Color(0xFF2E1065);
  static const Color tDark = Color(0xFF0F071D);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1033);

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? tDark : const Color(0xFFF8FAFC);
    final sidebarColor =
        widget.isAdminPanel ? surfaceDark : (widget.isDarkMode ? pViolet : const Color(0xFFF1F5F9));
    final textColor = widget.isDarkMode ? Colors.white : pViolet;
    final subTextColor = widget.isDarkMode ? Colors.white70 : Colors.blueGrey;

    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          // SIDEBAR
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: widget.isSidebarExpanded ? 260 : 80,
            color: sidebarColor,
            child: Column(
              children: [
                const SizedBox(height: 30),
                // Logo Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: aViolet.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.isAdminPanel
                            ? LucideIcons.shield
                            : LucideIcons.graduationCap,
                        color: aViolet,
                        size: 24,
                      ),
                    ),
                    if (widget.isSidebarExpanded) ...[
                      const SizedBox(width: 12),
                      Text(
                        widget.isAdminPanel ? "UEMS ADMIN" : "UEMS Portal",
                        style: GoogleFonts.orbitron(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 40),
                // Menu Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: List.generate(widget.sidebarItems.length, (index) {
                      final item = widget.sidebarItems[index];
                      bool isSelected = widget.selectedIndex == index;
                      bool isDestructive =
                          item.title.toLowerCase() == 'logout' ||
                              item.title.toLowerCase() == 'secure logout';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? aViolet.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          onTap: () {
                            if (isDestructive) {
                              widget.onLogout();
                            } else {
                              widget.onMenuItemSelected(index);
                            }
                          },
                          minLeadingWidth: 20,
                          leading: Icon(
                            item.icon,
                            color: isDestructive
                                ? Colors.redAccent
                                : (isSelected
                                    ? aViolet
                                    : (widget.isDarkMode
                                        ? Colors.white54
                                        : Colors.blueGrey)),
                            size: 20,
                          ),
                          title: widget.isSidebarExpanded
                              ? Text(
                                  item.title,
                                  style: GoogleFonts.inter(
                                    color: isDestructive
                                        ? Colors.redAccent
                                        : (isSelected
                                            ? Colors.white
                                            : (widget.isDarkMode
                                                ? Colors.white60
                                                : Colors.blueGrey)),
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                )
                              : null,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // MAIN CONTENT AREA
          Expanded(
            child: Column(
              children: [
                // TOP BAR
                _buildTopBar(textColor, subTextColor),
                // PANEL CONTENT
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.panelTitle,
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                        if (widget.subtitle.isNotEmpty)
                          Text(
                            widget.subtitle,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: subTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? tDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              widget.isSidebarExpanded
                  ? LucideIcons.menu
                  : LucideIcons.chevronRight,
              color: textColor,
            ),
            onPressed: () => widget.onSidebarToggle(!widget.isSidebarExpanded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.panelTitle,
              style: GoogleFonts.inter(
                color: subTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          Icon(LucideIcons.bell, color: subTextColor, size: 20),
          const SizedBox(width: 24),
          CircleAvatar(
            radius: 18,
            backgroundColor: aViolet,
            child: Text(
              "DA",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PanelMenuItem {
  final String title;
  final IconData icon;

  PanelMenuItem({required this.title, required this.icon});
}
