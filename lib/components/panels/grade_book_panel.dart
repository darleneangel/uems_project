import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../../services/supabase_service.dart';

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
  String? _selectedSemester;
  List<String> _semesters = [];
  List<Map<String, dynamic>> _allGrades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLiveGrades();
  }

  /// DATABASE ENGINE: Fetches grades with joined subject and semester data
  Future<void> _fetchLiveGrades() async {
    setState(() => _isLoading = true);
    final client = SupabaseService().client;

    try {
      // JOINED QUERY: grades -> study_loads -> subjects & semesters
      final response = await client.from('grades').select('''
            midterm_grade,
            final_grade,
            final_numeric_grade,
            status,
            study_loads!inner (
              student_id,
              section_block,
              subjects (code, name, units),
              semesters (description),
              academic_years (description)
            )
          ''').eq('study_loads.student_id', widget.studentData['id']);

      if (mounted) {
        final List<Map<String, dynamic>> fetched =
            List<Map<String, dynamic>>.from(response);

        // Derive unique semesters from the data
        final Set<String> semesterSet = {};
        for (var row in fetched) {
          final sem = row['study_loads']['semesters']['description'];
          final year = row['study_loads']['academic_years']['description'];
          semesterSet.add("$sem $year");
        }

        setState(() {
          _allGrades = fetched;
          _semesters = semesterSet.toList()
            ..sort((a, b) => b.compareTo(a)); // Newest first
          if (_semesters.isNotEmpty) {
            _selectedSemester = _semesters.first;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Grade Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredGrades() {
    if (_selectedSemester == null) return [];
    return _allGrades.where((g) {
      final sem = g['study_loads']['semesters']['description'];
      final year = g['study_loads']['academic_years']['description'];
      return "$sem $year" == _selectedSemester;
    }).toList();
  }

  double _calculateGWA(List<Map<String, dynamic>> grades) {
    if (grades.isEmpty) return 0.0;
    double totalPoints = 0;
    double totalUnits = 0;
    for (var g in grades) {
      final numericGrade =
          double.tryParse(g['final_numeric_grade']?.toString() ?? "0.0") ?? 0.0;
      final units = double.tryParse(
              g['study_loads']['subjects']['units']?.toString() ?? "0.0") ??
          0.0;
      if (numericGrade > 0) {
        totalPoints += numericGrade * units;
        totalUnits += units;
      }
    }
    return totalUnits == 0 ? 0.0 : totalPoints / totalUnits;
  }

  // --- PDF GENERATION ENGINE (Using Live Data) ---
  Future<void> _exportGradesPdf() async {
    final filtered = _getFilteredGrades();
    if (filtered.isEmpty) return;

    final pdf = pw.Document();
    final String timestamp = DateTime.now().toString().split('.')[0];
    final PdfColor brandViolet = PdfColor.fromInt(0xFF7C3AED);

    pw.ImageProvider? logoImage;
    try {
      final ByteData data = await rootBundle.load('assets/image/logo (2).png');
      logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(children: [
                    if (logoImage != null)
                      pw.Container(
                          width: 40, height: 40, child: pw.Image(logoImage)),
                    pw.SizedBox(width: 12),
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("UEMSSP",
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 22,
                                  color: brandViolet)),
                          pw.Text("OFFICIAL GRADE REPORTING NODE",
                              style: pw.TextStyle(
                                  fontSize: 8, color: PdfColors.grey700)),
                        ]),
                  ]),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("OFFICIAL DOCUMENT",
                            style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey500)),
                        pw.Text("SCHOLASTIC RECORD",
                            style: pw.TextStyle(
                                fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ]),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: brandViolet, thickness: 1.5),
              pw.SizedBox(height: 25),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8)),
                child: pw.Column(children: [
                  pw.Row(children: [
                    pw.Expanded(
                        child: _pdfMetaItem("NAME",
                            "${widget.studentData['fn']} ${widget.studentData['ln']}")),
                    pw.Expanded(
                        child: _pdfMetaItem(
                            "ID NUMBER", widget.studentData['user_id_number'])),
                  ]),
                  pw.SizedBox(height: 10),
                  pw.Row(children: [
                    pw.Expanded(
                        child: _pdfMetaItem(
                            "ACADEMIC PERIOD", _selectedSemester ?? "N/A")),
                    pw.Expanded(child: _pdfMetaItem("GENERATED ON", timestamp)),
                  ]),
                ]),
              ),
              pw.SizedBox(height: 40),
              pw.Table.fromTextArray(
                headers: [
                  "CODE",
                  "DESCRIPTION",
                  "UNITS",
                  "MID",
                  "FINAL",
                  "STATUS"
                ],
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8,
                    color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: brandViolet),
                cellStyle: pw.TextStyle(fontSize: 8),
                data: filtered
                    .map((g) => [
                          g['study_loads']['subjects']['code'],
                          g['study_loads']['subjects']['name'],
                          g['study_loads']['subjects']['units'].toString(),
                          g['midterm_grade'] ?? '-',
                          g['final_grade'] ?? '-',
                          g['status'] ?? 'N/A'
                        ])
                    .toList(),
              ),
              pw.SizedBox(height: 25),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
                pw.Text("TERM GWA: ",
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text(_calculateGWA(filtered).toStringAsFixed(2),
                    style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: brandViolet)),
              ]),
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("AUTHENTICATED VIA SUPABASE CLOUD",
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    pw.Text(
                        "Verification Hash: ${widget.studentData['id'].toString().substring(0, 8)}",
                        style: pw.TextStyle(fontSize: 7)),
                  ]),
            ],
          );
        },
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final file = File(
          "${dir.path}/Grades_${_selectedSemester?.replaceAll(' ', '_')}.pdf");
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (_) {}
  }

  pw.Widget _pdfMetaItem(String label, String val) =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 7,
                color: PdfColors.grey600,
                fontWeight: pw.FontWeight.bold)),
        pw.Text(val,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))
      ]);

  @override
  Widget build(BuildContext context) {
    final Color cardColor =
        widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    final Color textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final Color subTextColor =
        widget.isDarkMode ? Colors.white54 : Colors.blueGrey;

    if (_isLoading)
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));

    final filtered = _getFilteredGrades();
    final gwa = _calculateGWA(filtered);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_semesters.isNotEmpty) ...[
          _buildSemesterSelector(cardColor, textColor),
          const SizedBox(height: 24),
          _buildSummaryCard(
              cardColor, textColor, subTextColor, gwa, filtered.length),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: filtered.isEmpty ? null : _exportGradesPdf,
              icon: const Icon(LucideIcons.fileDown, size: 16),
              label: const Text("DOWNLOAD PDF"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            ),
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            Center(
                child: Text("No records found for this period.",
                    style: TextStyle(color: subTextColor)))
          else
            _buildGradeTable(filtered, cardColor, textColor, subTextColor),
        ] else
          _buildEmptyState(subTextColor),
      ],
    );
  }

  Widget _buildSemesterSelector(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: widget.isDarkMode ? Colors.white10 : Colors.black12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSemester,
          isExpanded: true,
          dropdownColor: cardColor,
          icon: Icon(LucideIcons.chevronDown, color: textColor),
          style: GoogleFonts.inter(
              color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
          onChanged: (String? newValue) =>
              setState(() => _selectedSemester = newValue),
          items: _semesters
              .map<DropdownMenuItem<String>>((String value) =>
                  DropdownMenuItem<String>(value: value, child: Text(value)))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Color cardColor, Color textColor, Color subTextColor,
      double gwa, int count) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: widget.isDarkMode
                  ? [const Color(0xFF2E1065), const Color(0xFF4C1D95)]
                  : [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("GWA Standing",
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text(gwa.toStringAsFixed(2),
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900)),
            if (gwa <= 1.75 && gwa > 0)
              Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: const Color(0xFF69F0AE),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text("DEAN'S LISTER",
                      style: TextStyle(
                          color: Color(0xFF1E1B4B),
                          fontSize: 10,
                          fontWeight: FontWeight.bold))),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text("Subjects",
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text(count.toString(),
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
                widget.studentData['status']?.toString().toUpperCase() ??
                    "ACTIVE",
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1)),
          ]),
        ],
      ),
    );
  }

  Widget _buildGradeTable(List<Map<String, dynamic>> grades, Color cardColor,
      Color textColor, Color subTextColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: widget.isDarkMode ? Colors.white10 : Colors.black12)),
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FlexColumnWidth(1.2),
          1: FlexColumnWidth(3),
          2: FlexColumnWidth(0.8),
          3: FlexColumnWidth(0.8),
          4: FlexColumnWidth(0.8),
          5: FlexColumnWidth(1.2)
        },
        children: [
          TableRow(
              decoration: BoxDecoration(
                  border: Border(
                      bottom:
                          BorderSide(color: subTextColor.withOpacity(0.1)))),
              children: [
                _tableHeader("Code", subTextColor),
                _tableHeader("Subject", subTextColor),
                _tableHeader("Units", subTextColor, align: TextAlign.center),
                _tableHeader("Mid", subTextColor, align: TextAlign.center),
                _tableHeader("Final", subTextColor, align: TextAlign.center),
                _tableHeader("Status", subTextColor, align: TextAlign.center),
              ]),
          ...grades.map((grade) {
            final s = grade['study_loads']['subjects'];
            return TableRow(
                decoration: BoxDecoration(
                    border: Border(
                        bottom:
                            BorderSide(color: subTextColor.withOpacity(0.05)))),
                children: [
                  _tableCell(s['code'], const Color(0xFF8B5CF6), isBold: true),
                  _tableCell(s['name'], textColor),
                  _tableCell(s['units'].toString(), textColor,
                      align: TextAlign.center),
                  _tableCell(grade['midterm_grade'] ?? '-', textColor,
                      align: TextAlign.center),
                  _tableCell(grade['final_grade'] ?? '-', textColor,
                      align: TextAlign.center),
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                          child: _statusBadge(grade['status'] ?? 'Enrolled'))),
                ]);
          }),
        ],
      ),
    );
  }

  Widget _tableHeader(String t, Color c, {TextAlign align = TextAlign.left}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(t.toUpperCase(),
              textAlign: align,
              style: GoogleFonts.inter(
                  color: c,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)));
  Widget _tableCell(String t, Color c,
          {TextAlign align = TextAlign.left, bool isBold = false}) =>
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          child: Text(t,
              textAlign: align,
              style: GoogleFonts.inter(
                  color: c,
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500)));

  Widget _statusBadge(String status) {
    final isPassed = status == 'Passed';
    final color = isPassed
        ? const Color(0xFF69F0AE)
        : (status == 'Enrolled' ? const Color(0xFF8B5CF6) : Colors.redAccent);
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Text(status.toUpperCase(),
            style: GoogleFonts.inter(
                color: color, fontSize: 10, fontWeight: FontWeight.w900)));
  }

  Widget _buildEmptyState(Color sub) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(LucideIcons.inbox, size: 48, color: sub.withOpacity(0.3)),
        const SizedBox(height: 16),
        Text("No academic records found in database.",
            style: TextStyle(color: sub))
      ]));
}
