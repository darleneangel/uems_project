import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CurriculumCatalogPanel extends StatefulWidget {
  final bool isDarkMode;
  const CurriculumCatalogPanel({super.key, required this.isDarkMode});

  @override
  State<CurriculumCatalogPanel> createState() => _CurriculumCatalogPanelState();
}

class _CurriculumCatalogPanelState extends State<CurriculumCatalogPanel> {
  String _selectedProgram = "BS Computer Science";

  final Map<String, List<Map<String, dynamic>>> _curriculumData = {
    "BS Computer Science": [
      {
        "year": "4th Year - 1st Semester",
        "subjects": [
          {
            "code": "ITCC 411",
            "title": "Systems Integration",
            "units": 3,
            "pre": "ITCC 322",
          },
          {
            "code": "ITCC 412",
            "title": "Information Assurance",
            "units": 3,
            "pre": "None",
          },
          {
            "code": "ITCP 413",
            "title": "Capstone Project 1",
            "units": 3,
            "pre": "Senior Standing",
          },
        ],
      },
      {
        "year": "4th Year - 2nd Semester",
        "subjects": [
          {
            "code": "ITCP 421",
            "title": "Capstone Project 2",
            "units": 3,
            "pre": "ITCP 413",
          },
          {
            "code": "ITEE 422",
            "title": "Social & Professional Issues",
            "units": 3,
            "pre": "None",
          },
          {
            "code": "ITPR 423",
            "title": "Practicum (480 Hours)",
            "units": 6,
            "pre": "All Major Subjects",
          },
        ],
      },
    ],
    "BS Info Tech": [
      {
        "year": "3rd Year - 1st Semester",
        "subjects": [
          {
            "code": "IPT 101",
            "title": "Integrative Programming",
            "units": 3,
            "pre": "PROG 102",
          },
        ],
      },
    ],
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
        Row(
          children: [
            _programFilter("BS Computer Science"),
            const SizedBox(width: 12),
            _programFilter("BS Info Tech"),
            const SizedBox(width: 12),
            _programFilter("BS Business Ad"),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView(
            children: (_curriculumData[_selectedProgram] ?? [])
                .map(
                  (yearGroup) => _buildYearSection(
                    yearGroup,
                    cardColor,
                    textColor,
                    subTextColor,
                  ),
                )
                .toList(),
          ),
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
              "Curriculum & Course Catalog",
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            Text(
              "Official program structures and prerequisite mapping.",
              style: TextStyle(color: subTextColor, fontSize: 13),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(LucideIcons.plus, size: 16),
          label: const Text("UPDATE CURRICULUM"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _programFilter(String title) {
    bool isSelected = _selectedProgram == title;
    return InkWell(
      onTap: () => setState(() => _selectedProgram = title),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8B5CF6)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white10,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildYearSection(
    Map<String, dynamic> data,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['year'],
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8B5CF6),
            ),
          ),
          const Divider(height: 32, color: Colors.white10),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(3),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(2),
            },
            children: [
              TableRow(
                children: [
                  _tableHead("CODE"),
                  _tableHead("TITLE"),
                  _tableHead("UNITS"),
                  _tableHead("PREREQUISITE"),
                ],
              ),
              ...(data['subjects'] as List)
                  .map(
                    (s) => TableRow(
                      children: [
                        _tableCell(s['code'], textColor),
                        _tableCell(s['title'], textColor),
                        _tableCell(s['units'].toString(), textColor),
                        _tableCell(s['pre'], const Color(0xFF69F0AE)),
                      ],
                    ),
                  )
                  .toList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableHead(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.blueGrey,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
  Widget _tableCell(String text, Color c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(text, style: TextStyle(color: c, fontSize: 13)),
  );
}
