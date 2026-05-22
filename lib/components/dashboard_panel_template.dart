import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/security_service.dart';

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
  });

  @override
  State<DashboardPanelTemplate> createState() => _DashboardPanelTemplateState();
}

class _DashboardPanelTemplateState extends State<DashboardPanelTemplate> {
  @override
  void initState() {
    super.initState();
    // Start the global inactivity guard for whichever dashboard is using this template
    SecurityService().startInactivityMonitoring(onTimeout: widget.onLogout);
  }

  @override
  void dispose() {
    SecurityService().stopInactivityMonitoring();
    super.dispose();
  }

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
      'time': '2h ago',
    },
    {
      'title': 'Advising Schedule',
      'subtitle': 'Advising is scheduled next week. Check your calendar.',
      'time': '1d ago',
    },
  ];

  // Build searchable labels from the sidebar items so search stays in sync.
  List<String> get _searchLabels =>
      widget.sidebarItems.map((e) => e.title).toList();

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white,
        title: Text(
          "Confirm Logout",
          style: GoogleFonts.inter(
            color: widget.isDarkMode ? Colors.white : const Color(0xFF2E1065),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Are you sure you want to log out?",
          style: GoogleFonts.inter(
            color: widget.isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "No",
              style: GoogleFonts.inter(
                color: widget.isDarkMode ? Colors.white54 : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Yes",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? tDark : const Color(0xFFF8FAFC);

    // Sidebar is dark if it's an admin panel OR if dark mode is enabled.
    final bool isSidebarDark = widget.isAdminPanel || widget.isDarkMode;
    final sidebarColor = widget.isAdminPanel
        ? pViolet
        : (widget.isDarkMode ? pViolet : const Color(0xFFF1F5F9));

    final sidebarTextColor = isSidebarDark ? Colors.white : pViolet;
    final sidebarSubTextColor =
        isSidebarDark ? Colors.white60 : Colors.blueGrey;
    final textColor = widget.isDarkMode ? Colors.white : pViolet;
    final subTextColor = widget.isDarkMode ? Colors.white70 : Colors.blueGrey;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => SecurityService().resetInactivityTimer(),
      onPointerMove: (_) => SecurityService().resetInactivityTimer(),
      onPointerSignal: (_) => SecurityService().resetInactivityTimer(),
      child: Scaffold(
        backgroundColor: bgColor,
        body: Row(
          children: [
            // SIDEBAR
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              // Slightly wider for admin to match the desired layout
              width: widget.isSidebarExpanded ? 280 : 80,
              color: sidebarColor,
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  // Logo Section
                  Row(
                    children: [
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: aViolet.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                        Text(
                          widget.logoText ??
                              (widget.isAdminPanel
                                  ? "UEMSSP ADMIN"
                                  : "UEMSSP Portal"),
                          style: GoogleFonts.orbitron(
                            color: sidebarTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Provide a chevron inside the sidebar for admin so the
                      // collapsed/expanded affordance matches the reference design.
                      if (widget.isSidebarExpanded && widget.isAdminPanel)
                        IconButton(
                          icon: Icon(
                            LucideIcons.chevronLeft,
                            color: sidebarSubTextColor,
                            size: 18,
                          ),
                          onPressed: () => widget.onSidebarToggle(false),
                        ),
                    ],
                  ),
                  // When collapsed, show a centered expand chevron to match the reference
                  if (!widget.isSidebarExpanded)
                    Center(
                      child: IconButton(
                        icon: Icon(
                          LucideIcons.chevronRight,
                          color: sidebarSubTextColor,
                        ),
                        onPressed: () => widget.onSidebarToggle(true),
                      ),
                    ),
                  const SizedBox(height: 40),
                  // Menu Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: List.generate(widget.sidebarItems.length, (
                        index,
                      ) {
                        final item = widget.sidebarItems[index];
                        // Keep sidebar appearance uniform regardless of selection.
                        bool isDestructive =
                            item.title.toLowerCase() == 'logout' ||
                                item.title.toLowerCase() == 'secure logout';
                        final bool isSelected = widget.selectedIndex == index;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? aViolet.withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(color: aViolet.withOpacity(0.3))
                                : null,
                          ),
                          child: ListTile(
                            onTap: () {
                              if (isDestructive) {
                                _handleLogout();
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
                                      ? (isSidebarDark ? Colors.white : pViolet)
                                      : (isSidebarDark
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
                                              ? (isSidebarDark
                                                  ? Colors.white
                                                  : pViolet)
                                              : (isSidebarDark
                                                  ? Colors.white60
                                                  : Colors.blueGrey)),
                                      fontWeight: isSelected
                                          ? FontWeight.bold
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
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => _PanelSearchDialog(
                  items: widget.sidebarItems,
                  isDarkMode: widget.isDarkMode,
                  onItemSelected: (index) {
                    Navigator.pop(context);
                    widget.onMenuItemSelected(index);
                  },
                ),
              );
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Notifications',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: widget.isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
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
                            leading: const Icon(
                              LucideIcons.megaphone,
                              size: 20,
                              color: Colors.deepPurpleAccent,
                            ),
                            title: Text(
                              n['title']!,
                              style: GoogleFonts.inter(
                                color: widget.isDarkMode
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              n['subtitle']!,
                              style: GoogleFonts.inter(
                                color: widget.isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                            trailing: Text(
                              n['time']!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: widget.isDarkMode
                                    ? Colors.white54
                                    : Colors.black45,
                              ),
                            ),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${n['title']}: ${n['subtitle']}',
                                  ),
                                ),
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

          // Theme toggle button
          IconButton(
            icon: Icon(
              widget.isDarkMode ? LucideIcons.sun : LucideIcons.moon,
              color: subTextColor,
              size: 20,
            ),
            onPressed: () => widget.themeToggle?.call(),
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

/// Panel Search Dialog - matches the admin dashboard search dialog style
class _PanelSearchDialog extends StatefulWidget {
  final List<PanelMenuItem> items;
  final bool isDarkMode;
  final Function(int) onItemSelected;

  const _PanelSearchDialog({
    required this.items,
    required this.isDarkMode,
    required this.onItemSelected,
  });

  @override
  State<_PanelSearchDialog> createState() => _PanelSearchDialogState();
}

class _PanelSearchDialogState extends State<_PanelSearchDialog> {
  late TextEditingController _searchController;
  late List<MapEntry<int, PanelMenuItem>> _filteredItems;

  final List<MapEntry<int, PanelMenuItem>> _allItems = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    // Build all items excluding logout items
    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      if (item.title.isNotEmpty &&
          item.title.toLowerCase() != 'logout' &&
          item.title.toLowerCase() != 'secure logout') {
        _allItems.add(MapEntry(i, item));
      }
    }

    _filteredItems = _allItems;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _allItems;
      } else {
        _filteredItems = _allItems
            .where(
              (item) =>
                  item.value.title.toLowerCase().contains(query.toLowerCase()),
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
    final sideColor = widget.isDarkMode ? surfaceDark : const Color(0xFFEDE9FE);
    final textColor = widget.isDarkMode ? Colors.white : pViolet;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        decoration: BoxDecoration(
          color: sideColor,
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
                              item.value.title,
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
                                : aViolet.withOpacity(0.1),
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

/// Simple SearchDelegate that returns the selected suggestion string.
class _SmartSearchDelegate extends SearchDelegate<String?> {
  final List<String> items;
  _SmartSearchDelegate(this.items);

  static const Color pViolet = Color(0xFF2E1065);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color tDark = Color(0xFF0F071D);
  static const Color lBg = Color(0xFFF8FAFC);

  @override
  String get searchFieldLabel => 'Search across portal';

  @override
  TextStyle? get searchFieldStyle => const TextStyle();

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(backgroundColor: pViolet, elevation: 0),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: GoogleFonts.inter(color: Colors.white70),
      ),
      scaffoldBackgroundColor: lBg,
      textTheme: TextTheme(bodyMedium: GoogleFonts.inter(color: pViolet)),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(LucideIcons.x, color: Colors.white),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = items
        .where((i) => i.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView(
      children: results.map((r) {
        return ListTile(
          title: Text(
            r,
            style: GoogleFonts.inter(
              color: pViolet,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () => close(context, r),
          hoverColor: aViolet.withOpacity(0.1),
        );
      }).toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty
        ? items.take(6).toList()
        : items
            .where((i) => i.toLowerCase().contains(query.toLowerCase()))
            .toList();
    return ListView(
      children: suggestions.map((s) {
        return ListTile(
          leading: const Icon(LucideIcons.search, color: aViolet, size: 18),
          title: Text(
            s,
            style: GoogleFonts.inter(
              color: pViolet,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () => close(context, s),
          hoverColor: aViolet.withOpacity(0.1),
        );
      }).toList(),
    );
  }
}
