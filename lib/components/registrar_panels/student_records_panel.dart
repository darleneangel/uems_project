import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class StudentRecordsPanel extends StatefulWidget {
  final bool isDarkMode;
  const StudentRecordsPanel({super.key, required this.isDarkMode});

  @override
  State<StudentRecordsPanel> createState() => _StudentRecordsPanelState();
}

class _StudentRecordsPanelState extends State<StudentRecordsPanel> {
  String? _selectedStudentId;
  final TextEditingController _searchController = TextEditingController();

  final Map<String, dynamic> _registrarDb = {
    "2024-00001": {
      "name": "DARLENE ANGEL",
      "id": "2024-00001",
      "course": "BS Computer Science",
      "year": "4th Year",
      "section": "BSCS-4A",
      "birthdate": "May 12, 2002",
      "contact": "+63 912 345 6789",
      "email": "darlene.a@sscr.edu.ph",
      "status": "Active",
      "enrollment": "Enrolled (2nd Sem 2025-2026)",
      "address": "Cavite City, Philippines",
    },
    "2024-00002": {
      "name": "JUAN DELA CRUZ",
      "id": "2024-00002",
      "course": "BS Info Tech",
      "year": "3rd Year",
      "section": "BSIT-3B",
      "birthdate": "November 20, 2003",
      "contact": "+63 915 555 1234",
      "email": "juan.dc@sscr.edu.ph",
      "status": "Active",
      "enrollment": "Enrolled (2nd Sem 2025-2026)",
      "address": "Bacoor, Cavite",
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

    if (_selectedStudentId != null) {
      return _buildStudentDetailView(cardColor, textColor);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: "Search Records by ID or Name...",
                  prefixIcon: const Icon(LucideIcons.search, size: 20),
                  filled: true,
                  fillColor: widget.isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.02),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            _actionIconButton(
              LucideIcons.userPlus,
              "NEW STUDENT",
              const Color(0xFF8B5CF6),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: widget.isDarkMode ? Colors.white10 : Colors.black12,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: ListView(
                children: _registrarDb.entries
                    .where(
                      (e) =>
                          e.key.contains(_searchController.text) ||
                          e.value['name'].toString().contains(
                            _searchController.text.toUpperCase(),
                          ),
                    )
                    .map((e) => _buildStudentListTile(e.value, textColor))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentListTile(Map<String, dynamic> s, Color textColor) {
    return ListTile(
      onTap: () => setState(() => _selectedStudentId = s['id']),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.1),
        child: Text(
          s['name'][0],
          style: const TextStyle(
            color: Color(0xFF8B5CF6),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        s['name'],
        style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        "${s['id']} • ${s['course']}",
        style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 12),
      ),
      trailing: const Icon(
        LucideIcons.chevronRight,
        size: 16,
        color: Colors.blueGrey,
      ),
    );
  }

  Widget _buildStudentDetailView(Color cardColor, Color textColor) {
    final student = _registrarDb[_selectedStudentId];
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(LucideIcons.arrowLeft, color: textColor),
                onPressed: () => setState(() => _selectedStudentId = null),
              ),
              const SizedBox(width: 8),
              Text(
                "Student Profile",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
            ],
          ),
          const Divider(height: 48, color: Colors.white10),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _infoField("Full Legal Name", student['name'], textColor),
                  _infoField("Student ID Number", student['id'], textColor),
                  _infoField("Program / Course", student['course'], textColor),
                  _infoField(
                    "Account Status",
                    student['status'],
                    const Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoField(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionIconButton(IconData icon, String label, Color color) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
}
