import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class GradeEncodingPanel extends StatefulWidget {
  final bool isDarkMode;
  const GradeEncodingPanel({super.key, required this.isDarkMode});

  @override
  State<GradeEncodingPanel> createState() => _GradeEncodingPanelState();
}

class _GradeEncodingPanelState extends State<GradeEncodingPanel> {
  // --- FILTER STATE ---
  String _selectedCourse = "BSIT";
  String _selectedYear = "3rd Year";
  String _selectedSubject = "ITCC 321";
  final TextEditingController _searchController = TextEditingController();

  // Modern Tonal Palette Constants
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);
  static const Color success = Color(0xFF69F0AE);

  // --- MOCK DATA LISTS ---
  final List<String> _courses = ["BSIT", "BSCS", "BSCpE", "BSBA", "BSHM"];
  final List<String> _yearLevels = [
    "1st Year",
    "2nd Year",
    "3rd Year",
    "4th Year",
  ];
  final List<String> _subjects = [
    "ITCC 321",
    "ITCC 411",
    "NET 102",
    "PROG 101",
  ];

  // --- MOCK ROSTER DATA ---
  final List<Map<String, dynamic>> _roster = [
    {
      "id": "2024-00001",
      "name": "DARLENE ANGEL",
      "assignment": "95",
      "exam": "92",
      "project": "98",
      "final": "1.25",
    },
    {
      "id": "2024-00005",
      "name": "MICHAEL CHEN",
      "assignment": "88",
      "exam": "85",
      "project": "90",
      "final": "1.75",
    },
    {
      "id": "2024-00012",
      "name": "SARAH JENKINS",
      "assignment": "92",
      "exam": "94",
      "project": "95",
      "final": "1.25",
    },
    {
      "id": "2024-00155",
      "name": "JUAN DELA CRUZ",
      "assignment": "78",
      "exam": "80",
      "project": "82",
      "final": "2.25",
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- PDF GENERATION ENGINE ---
  Future<void> _generateGradePDF() async {
    final pdf = pw.Document();
    final timestamp = DateTime.now().toString().split('.')[0];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                "SAN SEBASTIAN COLLEGE - RECOLETOS DE CAVITE",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            pw.Center(
              child: pw.Text(
                "OFFICIAL GRADE REPORT - $_selectedCourse $_selectedYear",
                style: pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Text("Subject: $_selectedSubject"),
            pw.Text("Faculty: PROF. ROBERTO MANALASTAS"),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: [
                "Student ID",
                "Name",
                "Asgn",
                "Exam",
                "Proj",
                "Final Grade",
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              data: _roster
                  .map(
                    (s) => [
                      s['id'],
                      s['name'],
                      s['assignment'],
                      s['exam'],
                      s['project'],
                      s['final'],
                    ],
                  )
                  .toList(),
            ),
            pw.Spacer(),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "Generated on: $timestamp",
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/GradeReport_$_selectedSubject.pdf");
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      debugPrint("PDF Export Error: $e");
    }
  }

  void _exportExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: success,
        content: const Text("Exporting data to grading_sheet.xlsx... Done!"),
      ),
    );
  }

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
          _buildHeader(textColor),
          const SizedBox(height: 32),
          _buildEncodingModule(bgColor, textColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Faculty Grade Encoding",
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: text,
            letterSpacing: -1,
          ),
        ),
        const Text(
          "Dynamic roster management based on course and academic year level.",
          style: TextStyle(color: Colors.blueGrey, fontSize: 14),
        ),
      ],
    );
  }

  // --- MAIN ENCODING MODULE ---
  Widget _buildEncodingModule(Color bg, Color text) {
    return Column(
      children: [
        // 1. FILTER & SEARCH BAR
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isDarkMode ? Colors.white10 : Colors.black12,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildDropdown(
                    "Course",
                    _selectedCourse,
                    _courses,
                    (v) => setState(() => _selectedCourse = v!),
                  ),
                  const SizedBox(width: 16),
                  _buildDropdown(
                    "Year Level",
                    _selectedYear,
                    _yearLevels,
                    (v) => setState(() => _selectedYear = v!),
                  ),
                  const SizedBox(width: 16),
                  _buildDropdown(
                    "Subject",
                    _selectedSubject,
                    _subjects,
                    (v) => setState(() => _selectedSubject = v!),
                  ),
                  const Spacer(),
                  _exportBtn(
                    LucideIcons.fileText,
                    "PDF",
                    _generateGradePDF,
                    aViolet,
                  ),
                  const SizedBox(width: 12),
                  _exportBtn(
                    LucideIcons.fileSpreadsheet,
                    "EXCEL",
                    _exportExcel,
                    success,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.isDarkMode
                            ? Colors.white.withOpacity(0.03)
                            : Colors.black.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: text, fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: "Search by Student ID or Name...",
                          hintStyle: TextStyle(color: Colors.blueGrey),
                          prefixIcon: Icon(
                            LucideIcons.search,
                            size: 18,
                            color: aViolet,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 2. GRADE TABLE
        Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: widget.isDarkMode ? Colors.white10 : Colors.black12,
            ),
          ),
          child: Column(
            children: [
              _buildTableHeader(),
              const Divider(height: 1, color: Colors.white10),
              ..._roster.map((s) => _buildGradeRow(s, text)).toList(),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        "SAVE AS DRAFT",
                        style: TextStyle(color: Colors.blueGrey),
                      ),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Grades synced with Registrar."),
                            ),
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: aViolet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "FINALIZE & SYNC",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: Colors.blueGrey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 160,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: surfaceDark,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : pViolet,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              items: items
                  .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: widget.isDarkMode
          ? Colors.white.withOpacity(0.02)
          : Colors.black.withOpacity(0.01),
      child: Row(
        children: [
          _tableHead("ID NUMBER", 2),
          _tableHead("STUDENT NAME", 4),
          _tableHead("ASSIGNMENTS", 2),
          _tableHead("EXAMS", 2),
          _tableHead("PROJECTS", 2),
          _tableHead("FINAL", 2),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildGradeRow(Map<String, dynamic> s, Color text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              s['id'],
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              s['name'],
              style: TextStyle(
                color: text,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(flex: 2, child: _gradeInput(s['assignment'])),
          Expanded(flex: 2, child: _gradeInput(s['exam'])),
          Expanded(flex: 2, child: _gradeInput(s['project'])),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  s['final'],
                  style: const TextStyle(
                    color: success,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              LucideIcons.save,
              size: 16,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHead(String text, int flex) => Expanded(
    flex: flex,
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.blueGrey,
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _gradeInput(String initial) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        textAlign: TextAlign.center,
        style: TextStyle(
          color: widget.isDarkMode ? Colors.white : pViolet,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          hintText: initial,
          hintStyle: const TextStyle(color: Colors.blueGrey),
          filled: true,
          fillColor: Colors.white.withOpacity(0.03),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _exportBtn(
    IconData icon,
    String label,
    VoidCallback onTap,
    Color color,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.2)),
        ),
      ),
    );
  }

  Widget _statusBadge(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: c.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      t,
      style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w900),
    ),
  );
}
