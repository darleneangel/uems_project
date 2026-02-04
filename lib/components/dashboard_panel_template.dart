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
  
  // Temporary hardcoded notifications (can be replaced with live data)
  final List<Map<String, String>> _notifications = [
    {
      'title': 'Grades Available',
      'subtitle': 'Grades for 2nd Semester are now available.',
      'time': '2h ago'
    },
    {
      'title': 'Advising Schedule',
      'subtitle': 'Advising is scheduled next week. Check your calendar.',
      'time': '1d ago'
    },
  ];

  // Build searchable labels from the sidebar items so search stays in sync.
  List<String> get _searchLabels => widget.sidebarItems.map((e) => e.title).toList();

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

          // Search button (smart search using sidebar labels)
          IconButton(
            icon: Icon(LucideIcons.search, color: subTextColor),
            onPressed: () async {
              final result = await showSearch<String?>(
                context: context,
                delegate: _SmartSearchDelegate(_searchLabels),
              );
              if (result != null && result.isNotEmpty) {
                final match = widget.sidebarItems.indexWhere(
                    (it) => it.title.toLowerCase() == result.toLowerCase());
                if (match >= 0) {
                  widget.onMenuItemSelected(match);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No panel for "$result"')),
                  );
                }
              }
            },
          ),

          const SizedBox(width: 8),

          // Notifications (opens a bottom sheet with actions)
          IconButton(
            icon: Icon(LucideIcons.bell, color: subTextColor, size: 20),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: widget.isDarkMode ? tDark : Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                builder: (ctx) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Notifications', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: widget.isDarkMode ? Colors.white : Colors.black)),
                              IconButton(
                                icon: const Icon(LucideIcons.x),
                                onPressed: () => Navigator.of(ctx).pop(),
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        ..._notifications.map((n) {
                          return ListTile(
                            leading: const Icon(LucideIcons.megaphone, size: 20, color: Colors.deepPurpleAccent),
                            title: Text(n['title']!, style: GoogleFonts.inter(color: widget.isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.w700)),
                            subtitle: Text(n['subtitle']!, style: GoogleFonts.inter(color: widget.isDarkMode ? Colors.white70 : Colors.black54)),
                            trailing: Text(n['time']!, style: GoogleFonts.inter(fontSize: 12, color: widget.isDarkMode ? Colors.white54 : Colors.black45)),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${n['title']}: ${n['subtitle']}')),
                              );
                            },
                          );
                        }),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(width: 12),
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

/// Simple SearchDelegate that returns the selected suggestion string.
class _SmartSearchDelegate extends SearchDelegate<String?> {
  final List<String> items;
  _SmartSearchDelegate(this.items);

  @override
  String get searchFieldLabel => 'Search across portal';

  @override
  TextStyle? get searchFieldStyle => const TextStyle();

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(LucideIcons.x), onPressed: () => query = '')
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(icon: const Icon(LucideIcons.chevronLeft), onPressed: () => close(context, null));
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = items.where((i) => i.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView(
      children: results.map((r) {
        return ListTile(
          title: Text(r),
          onTap: () => close(context, r),
        );
      }).toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty
        ? items.take(6).toList()
        : items.where((i) => i.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView(
      children: suggestions.map((s) {
        return ListTile(
          title: Text(s),
          onTap: () => close(context, s),
        );
      }).toList(),
    );
  }
}
