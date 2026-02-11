import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FacultyLoadPanel extends StatefulWidget {
  final bool isDarkMode;
  const FacultyLoadPanel({super.key, required this.isDarkMode});

  @override
  State<FacultyLoadPanel> createState() => _FacultyLoadPanelState();
}

class _FacultyLoadPanelState extends State<FacultyLoadPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _activeFilter = "All";

  // Modern Tonal Palette Constants
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);
  static const Color success = Color(0xFF69F0AE);

  // --- MOCK FACULTY DATA ---
  final List<Map<String, dynamic>> _faculty = [
    {
      "name": "Dr. Jane Smith",
      "designation": "Full-Time Professor",
      "specialization": "Software Engineering",
      "units": 18,
      "sections": 5,
      "rating": 4.8,
      "status": "Regular Load",
      "statusColor": success,
    },
    {
      "name": "Prof. Roberto Manalastas",
      "designation": "Associate Professor",
      "specialization": "Network Security",
      "units": 24,
      "sections": 7,
      "rating": 4.5,
      "status": "Overloaded",
      "statusColor": Colors.orangeAccent,
    },
    {
      "name": "Dr. Amara De Silva",
      "designation": "Senior Lecturer",
      "specialization": "Artificial Intelligence",
      "units": 12,
      "sections": 3,
      "rating": 4.9,
      "status": "Underloaded",
      "statusColor": Colors.blueAccent,
    },
    {
      "name": "Prof. Leo Bautista",
      "designation": "Assistant Professor",
      "specialization": "Data Science",
      "units": 21,
      "sections": 6,
      "rating": 4.2,
      "status": "Regular Load",
      "statusColor": success,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode ? Colors.white : pViolet;
    final Color bgColor = widget.isDarkMode ? surfaceDark : Colors.white;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER SECTION
          _buildHeader(textColor),
          const SizedBox(height: 32),

          // 2. ANALYTICS CARDS
          Row(
            children: [
              _statItem(
                "Total Faculty",
                "24",
                LucideIcons.users,
                aViolet,
                textColor,
              ),
              const SizedBox(width: 20),
              _statItem(
                "Avg. Rating",
                "4.6",
                LucideIcons.star,
                Colors.amber,
                textColor,
              ),
              const SizedBox(width: 20),
              _statItem(
                "Assigned Units",
                "412",
                LucideIcons.layers,
                success,
                textColor,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 3. SEARCH & FILTERS
          _buildFilterBar(textColor),
          const SizedBox(height: 24),

          // 4. FACULTY DIRECTORY LIST
          _buildFacultyList(textColor, bgColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Faculty Load & Assignment",
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: -1,
              ),
            ),
            Text(
              "Monitor teaching history, assign loads, and evaluate faculty performance.",
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white54 : Colors.blueGrey,
                fontSize: 14,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(LucideIcons.userPlus, size: 16),
          label: const Text("ADD FACULTY"),
          style: ElevatedButton.styleFrom(
            backgroundColor: aViolet,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(Color textColor) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: const InputDecoration(
                hintText: "Search faculty name or specialization...",
                hintStyle: TextStyle(color: Colors.blueGrey),
                prefixIcon: Icon(LucideIcons.search, size: 18, color: aViolet),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        _filterChip("All"),
        _filterChip("Regular"),
        _filterChip("Overloaded"),
        _filterChip("Underloaded"),
      ],
    );
  }

  Widget _buildFacultyList(Color textColor, Color bgColor) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: _faculty.map((f) => _buildFacultyItem(f, textColor)).toList(),
      ),
    );
  }

  Widget _buildFacultyItem(Map<String, dynamic> f, Color textColor) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              // Profile Circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      aViolet.withOpacity(0.2),
                      aViolet.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    f['name'].split(' ').last[0],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: aViolet,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Profile Info
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f['name'],
                      style: GoogleFonts.inter(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "${f['designation']} • ${f['specialization']}",
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Load Progress
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Current Load", style: _metaStyle()),
                        Text(
                          "${f['units']}/24 Units",
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: f['units'] / 24,
                        backgroundColor: widget.isDarkMode
                            ? Colors.white10
                            : Colors.black12,
                        color: f['statusColor'],
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              // Performance & Status
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.star,
                          color: Colors.amber,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          f['rating'].toString(),
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _statusBadge(f['status'], f['statusColor']),
                  ],
                ),
              ),
              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _iconAction(
                    LucideIcons.calendar,
                    "Assign Schedule",
                    Colors.blueGrey,
                  ),
                  _iconAction(
                    LucideIcons.barChart,
                    "Performance Details",
                    Colors.blueGrey,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(LucideIcons.chevronRight, color: aViolet),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Colors.white10),
      ],
    );
  }

  // --- UI ATOMS & COMPONENTS ---

  Widget _statItem(
    String label,
    String value,
    IconData icon,
    Color color,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: widget.isDarkMode
              ? Colors.white.withOpacity(0.03)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.orbitron(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    bool isSelected = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? aViolet : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.blueGrey.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.blueGrey,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _iconAction(IconData icon, String tooltip, Color color) {
    return IconButton(
      icon: Icon(icon, color: color.withOpacity(0.6), size: 18),
      tooltip: tooltip,
      onPressed: () {},
    );
  }

  TextStyle _metaStyle() => const TextStyle(
    color: Colors.blueGrey,
    fontSize: 10,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.5,
  );
}
