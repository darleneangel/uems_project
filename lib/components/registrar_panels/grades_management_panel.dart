import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class GradesManagementPanel extends StatefulWidget {
  final bool isDarkMode;
  const GradesManagementPanel({super.key, required this.isDarkMode});

  @override
  State<GradesManagementPanel> createState() => _GradesManagementPanelState();
}

class _GradesManagementPanelState extends State<GradesManagementPanel> {
  String? _selectedStudentId;
  final TextEditingController _searchController = TextEditingController();

  final Map<String, dynamic> _mockGrades = {
    "2024-00001": {
      "name": "DARLENE ANGEL",
      "gpa": "1.25",
      "status": "Honor Roll",
      "subjects": [
        {"code": "ITCC 411", "title": "System Integration", "grade": "1.0"},
        {"code": "ITCC 412", "title": "Information Security", "grade": "1.25"},
        {"code": "ITCP 413", "title": "Capstone 1", "grade": "1.5"},
      ],
    },
    "2024-00002": {
      "name": "JUAN DELA CRUZ",
      "gpa": "1.75",
      "status": "Good Standing",
      "subjects": [
        {"code": "ITCC 411", "title": "System Integration", "grade": "1.75"},
        {"code": "ITCC 412", "title": "Information Security", "grade": "2.0"},
      ],
    },
  };

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode
        ? Colors.white
        : const Color(0xFF2E1065);
    final Color cardColor = widget.isDarkMode
        ? const Color(0xFF1E1B4B)
        : Colors.white;
    final Color subTextColor = widget.isDarkMode
        ? Colors.white54
        : Colors.blueGrey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(textColor, subTextColor),
        const SizedBox(height: 24),
        Expanded(
          child: _selectedStudentId == null
              ? _buildSearchGrid(cardColor, textColor, subTextColor)
              : _buildStudentGradeView(cardColor, textColor, subTextColor),
        ),
      ],
    );
  }

  Widget _buildHeader(Color textColor, Color subTextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Grades & Academic Records",
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            Text(
              "Monitor academic progress, compute GPAs, and audit submitted grades.",
              style: TextStyle(color: subTextColor, fontSize: 13),
            ),
          ],
        ),
        _actionButton(
          LucideIcons.fileText,
          "EXPORT TRANSCRIPT",
          const Color(0xFF8B5CF6),
        ),
      ],
    );
  }

  Widget _buildSearchGrid(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: "Search Student to View Grades...",
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: _mockGrades.entries
                  .where(
                    (e) =>
                        e.key.contains(_searchController.text) ||
                        e.value['name'].contains(
                          _searchController.text.toUpperCase(),
                        ),
                  )
                  .map(
                    (e) => ListTile(
                      onTap: () => setState(() => _selectedStudentId = e.key),
                      leading: CircleAvatar(
                        backgroundColor: const Color(
                          0xFF8B5CF6,
                        ).withOpacity(0.1),
                        child: const Icon(
                          LucideIcons.star,
                          size: 16,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                      title: Text(
                        e.value['name'],
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "Student ID: ${e.key} • GPA: ${e.value['gpa']}",
                        style: TextStyle(color: subTextColor, fontSize: 12),
                      ),
                      trailing: const Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: Colors.white24,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentGradeView(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    final s = _mockGrades[_selectedStudentId];
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(LucideIcons.arrowLeft, color: textColor),
                onPressed: () => setState(() => _selectedStudentId = null),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s['name'],
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    "Official Grade Record • ${s['status']}",
                    style: TextStyle(color: subTextColor, fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              _statBadge(
                "CUMULATIVE GPA: ${s['gpa']}",
                const Color(0xFF69F0AE),
              ),
            ],
          ),
          const Divider(height: 48, color: Colors.white10),
          Expanded(
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(4),
                2: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: widget.isDarkMode
                            ? Colors.white10
                            : Colors.black12,
                      ),
                    ),
                  ),
                  children: [
                    _tableHead("CODE"),
                    _tableHead("SUBJECT TITLE"),
                    _tableHead("GRADE"),
                  ],
                ),
                ...(s['subjects'] as List)
                    .map(
                      (sub) => TableRow(
                        children: [
                          _tableCell(sub['code'], textColor),
                          _tableCell(sub['title'], textColor),
                          _tableCell(
                            sub['grade'],
                            const Color(0xFF8B5CF6),
                            isBold: true,
                          ),
                        ],
                      ),
                    )
                    ,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHead(String text) => Padding(
    padding: const EdgeInsets.all(12),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.blueGrey,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
  Widget _tableCell(String text, Color c, {bool isBold = false}) => Padding(
    padding: const EdgeInsets.all(12),
    child: Text(
      text,
      style: TextStyle(
        color: c,
        fontSize: 14,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      ),
    ),
  );

  Widget _actionButton(IconData icon, String label, Color c) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: c,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _statBadge(String text, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: c.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: c.withOpacity(0.3)),
    ),
    child: Text(
      text,
      style: GoogleFonts.inter(
        color: c,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}
