import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class GradeBookPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> studentData;

  const GradeBookPanel({
    super.key,
    required this.isDarkMode,
    required this.studentData,
  });

  @override
  State<GradeBookPanel> createState() => _GradeBookPanelState();
}

class _GradeBookPanelState extends State<GradeBookPanel> {
  String _selectedSemester = "2nd Semester 2025-2026";
  final List<String> _semesters = [
    "2nd Semester 2025-2026",
    "1st Semester 2025-2026",
    "Summer 2025",
    "2nd Semester 2024-2025",
  ];

  // --- MOCK GRADE DATA PER SEMESTER ---
  final Map<String, List<Map<String, dynamic>>> _semesterGrades = {
    "2nd Semester 2025-2026": [
      {
        "code": "ITCC 411",
        "title": "Systems Integration & Architecture",
        "units": 3,
        "mid": "1.25",
        "final": "1.25",
        "grade": "1.25",
        "status": "Passed",
      },
      {
        "code": "ITCC 412",
        "title": "Information Assurance & Security",
        "units": 3,
        "mid": "1.50",
        "final": "1.25",
        "grade": "1.50",
        "status": "Passed",
      },
      {
        "code": "ITCP 413",
        "title": "Capstone Project 1",
        "units": 3,
        "mid": "1.00",
        "final": "1.00",
        "grade": "1.00",
        "status": "Passed",
      },
      {
        "code": "ITEE 414",
        "title": "Mobile Applications Development",
        "units": 3,
        "mid": "1.75",
        "final": "1.50",
        "grade": "1.75",
        "status": "Passed",
      },
    ],
    "1st Semester 2025-2026": [
      {
        "code": "CS 311",
        "title": "Automata Theory",
        "units": 3,
        "mid": "1.75",
        "final": "2.00",
        "grade": "2.00",
        "status": "Passed",
      },
      {
        "code": "CS 312",
        "title": "Software Engineering 2",
        "units": 3,
        "mid": "1.25",
        "final": "1.50",
        "grade": "1.50",
        "status": "Passed",
      },
      {
        "code": "CS 313",
        "title": "Networks & Communications",
        "units": 3,
        "mid": "2.25",
        "final": "2.00",
        "grade": "2.25",
        "status": "Passed",
      },
      {
        "code": "MATH 101",
        "title": "Linear Algebra",
        "units": 3,
        "mid": "1.50",
        "final": "1.75",
        "grade": "1.75",
        "status": "Passed",
      },
    ],
    "Summer 2025": [
      {
        "code": "OJT 1",
        "title": "Practicum / OJT (300 Hours)",
        "units": 6,
        "mid": "P",
        "final": "P",
        "grade": "1.00",
        "status": "Passed",
      },
    ],
    "2nd Semester 2024-2025": [
      {
        "code": "CS 221",
        "title": "Data Structures & Algorithms",
        "units": 3,
        "mid": "1.50",
        "final": "1.75",
        "grade": "1.75",
        "status": "Passed",
      },
      {
        "code": "CS 222",
        "title": "Object Oriented Programming",
        "units": 3,
        "mid": "1.25",
        "final": "1.25",
        "grade": "1.25",
        "status": "Passed",
      },
    ],
  };

  double _calculateGWA(List<Map<String, dynamic>> grades) {
    if (grades.isEmpty) return 0.0;
    double totalPoints = 0;
    double totalUnits = 0;
    for (var g in grades) {
      double grade = double.tryParse(g['grade']) ?? 0.0;
      int units = g['units'];
      if (grade > 0) {
        totalPoints += grade * units;
        totalUnits += units;
      }
    }
    return totalUnits == 0 ? 0.0 : totalPoints / totalUnits;
  }

  Future<void> _exportGradesPdf() async {
    final grades = _semesterGrades[_selectedSemester] ?? [];
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "SAN SEBASTIAN COLLEGE - RECOLETOS DE CAVITE",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              pw.Text(
                "OFFICIAL GRADE REPORT",
                style: pw.TextStyle(fontSize: 10),
              ),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(
                "Student: ${widget.studentData['name']} (${widget.studentData['id']})",
              ),
              pw.Text("Period: $_selectedSemester"),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: [
                  "Code",
                  "Description",
                  "Units",
                  "Midterm",
                  "Final",
                  "Grade",
                  "Status",
                ],
                data: grades
                    .map(
                      (g) => [
                        g['code'],
                        g['title'],
                        g['units'].toString(),
                        g['mid'],
                        g['final'],
                        g['grade'],
                        g['status'],
                      ],
                    )
                    .toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                "GWA: ${_calculateGWA(grades).toStringAsFixed(2)}",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Spacer(),
              pw.Text("Generated on: ${DateTime.now()}"),
            ],
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/grades_${widget.studentData['id']}.pdf");
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor = widget.isDarkMode
        ? const Color(0xFF1E1B4B)
        : Colors.white;
    final Color textColor = widget.isDarkMode
        ? Colors.white
        : const Color(0xFF2E1065);
    final Color subTextColor = widget.isDarkMode
        ? Colors.white54
        : Colors.blueGrey;

    final currentGrades = _semesterGrades[_selectedSemester] ?? [];
    final gwa = _calculateGWA(currentGrades);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. SEMESTER SELECTOR
        _buildSemesterSelector(cardColor, textColor),
        const SizedBox(height: 24),

        // 2. SUMMARY CARD
        _buildSummaryCard(
          cardColor,
          textColor,
          subTextColor,
          gwa,
          currentGrades.length,
        ),
        const SizedBox(height: 24),

        // 3. EXPORT BUTTON
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _exportGradesPdf,
            icon: const Icon(LucideIcons.fileDown, size: 16),
            label: const Text("DOWNLOAD PDF"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 4. GRADES LIST
        if (currentGrades.isEmpty)
          Center(
            child: Text(
              "No records found for this semester.",
              style: TextStyle(color: subTextColor),
            ),
          )
        else
          _buildGradeTable(currentGrades, cardColor, textColor, subTextColor),
      ],
    );
  }

  Widget _buildSemesterSelector(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSemester,
          isExpanded: true,
          dropdownColor: cardColor,
          icon: Icon(LucideIcons.chevronDown, color: textColor),
          style: GoogleFonts.inter(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() => _selectedSemester = newValue);
            }
          },
          items: _semesters.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    Color cardColor,
    Color textColor,
    Color subTextColor,
    double gwa,
    int subjectCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isDarkMode
              ? [const Color(0xFF2E1065), const Color(0xFF4C1D95)]
              : [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "GWA Standing",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                gwa.toStringAsFixed(2),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (gwa <= 1.75 && gwa > 0)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF69F0AE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "DEAN'S LISTER",
                    style: TextStyle(
                      color: Color(0xFF1E1B4B),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Total Subjects",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                subjectCount.toString(),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Academic Status",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                "REGULAR",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGradeTable(
    List<Map<String, dynamic>> grades,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FlexColumnWidth(1.5), // Code
          1: FlexColumnWidth(3), // Title
          2: FlexColumnWidth(0.8), // Units
          3: FlexColumnWidth(0.8), // Mid
          4: FlexColumnWidth(0.8), // Final
          5: FlexColumnWidth(0.8), // Grade
          6: FlexColumnWidth(1.2), // Status
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: subTextColor.withOpacity(0.1)),
              ),
            ),
            children: [
              _tableHeader("Code", subTextColor),
              _tableHeader("Description", subTextColor),
              _tableHeader("Units", subTextColor, align: TextAlign.center),
              _tableHeader("Mid", subTextColor, align: TextAlign.center),
              _tableHeader("Final", subTextColor, align: TextAlign.center),
              _tableHeader("Grade", subTextColor, align: TextAlign.center),
              _tableHeader("Status", subTextColor, align: TextAlign.center),
            ],
          ),
          ...grades.map((grade) {
            return TableRow(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: subTextColor.withOpacity(0.05)),
                ),
              ),
              children: [
                _tableCell(
                  grade['code'],
                  const Color(0xFF8B5CF6),
                  isBold: true,
                ),
                _tableCell(grade['title'], textColor),
                _tableCell(
                  grade['units'].toString(),
                  textColor,
                  align: TextAlign.center,
                ),
                _tableCell(grade['mid'], textColor, align: TextAlign.center),
                _tableCell(grade['final'], textColor, align: TextAlign.center),
                _tableCell(
                  grade['grade'],
                  textColor,
                  align: TextAlign.center,
                  isBold: true,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: _statusBadge(grade['status'])),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _tableHeader(
    String text,
    Color color, {
    TextAlign align = TextAlign.left,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text.toUpperCase(),
        textAlign: align,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _tableCell(
    String text,
    Color color, {
    TextAlign align = TextAlign.left,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      child: Text(
        text,
        textAlign: align,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 13,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final isPassed = status == 'Passed';
    final color = isPassed ? const Color(0xFF69F0AE) : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
