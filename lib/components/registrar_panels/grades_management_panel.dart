import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

class GradesManagementPanel extends StatefulWidget {
  final bool isDarkMode;
  const GradesManagementPanel({super.key, required this.isDarkMode});

  @override
  State<GradesManagementPanel> createState() => _GradesManagementPanelState();
}

class _GradesManagementPanelState extends State<GradesManagementPanel> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  String? _selectedStudentId;
  Map<String, dynamic>? _activeStudent;
  List<Map<String, dynamic>> _gradeHistory = [];
  bool _isLoading = false;

  // Institutional Palette
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color pViolet = Color(0xFF2E1065);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  /// 🛰️ DATABASE: Resolves the student and their associated grade ledger
  Future<void> _fetchStudentGrades(String studentId) async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch Student Identity
      final student = await _service.client
          .from('profiles')
          .select('*, student_details(*, courses(name, code))')
          .eq('id', studentId)
          .single();

      // 2. Fetch Grades with deep joins to subjects and semesters
      final grades = await _service.client
          .from('grades')
          .select('''
            midterm_grade, final_grade, final_numeric_grade, status,
            study_loads!inner (
              subjects (code, name, units),
              semesters (description),
              academic_years (description)
            )
          ''')
          .eq('study_loads.student_id', studentId)
          .order('graded_at', ascending: false);

      setState(() {
        _selectedStudentId = studentId;
        _activeStudent = student;
        _gradeHistory = List<Map<String, dynamic>>.from(grades);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Scholastic Sync Error: $e");
      setState(() => _isLoading = false);
    }
  }

  /// 📐 CALCULATION: Computes the institutional GWA based on units and numeric grades
  double _calculateGWA() {
    if (_gradeHistory.isEmpty) return 0.0;
    double totalWeightedPoints = 0;
    int totalUnits = 0;

    for (var grade in _gradeHistory) {
      final subject = grade['study_loads']?['subjects'];
      if (subject == null) continue;

      double numericGrade =
          double.tryParse(grade['final_numeric_grade']?.toString() ?? "0") ??
              0.0;
      int units = int.tryParse(subject['units']?.toString() ?? "0") ?? 0;

      if (numericGrade > 0) {
        totalWeightedPoints += (numericGrade * units);
        totalUnits += units;
      }
    }
    return totalUnits == 0 ? 0.0 : totalWeightedPoints / totalUnits;
  }

  /// 📄 PDF ENGINE: Generates official Transcript of Records (TOR)
  Future<void> _generateTranscript() async {
    if (_activeStudent == null) return;
    final pdf = pw.Document();
    final date = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (context) => [
              pw.Header(
                  level: 0,
                  child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("BRIGHT FUTURE ACADEMY",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 18)),
                        pw.Text("OFFICE OF THE UNIVERSITY REGISTRAR",
                            style: const pw.TextStyle(fontSize: 10)),
                        pw.Text("OFFICIAL TRANSCRIPT OF SCHOLASTIC RECORDS",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 12)),
                        pw.Divider(thickness: 2),
                      ])),
              pw.SizedBox(height: 20),
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                              "NAME: ${_activeStudent!['fn']} ${_activeStudent!['ln']}"
                                  .toUpperCase(),
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text(
                              "STUDENT NO: ${_activeStudent!['user_id_number']}"),
                          pw.Text(
                              "COURSE: ${_activeStudent!['student_details']?['courses']?['name'] ?? 'N/A'}"),
                        ]),
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text("DATE ISSUED: $date"),
                          pw.Text(
                              "INSTITUTIONAL GWA: ${_calculateGWA().toStringAsFixed(2)}"),
                        ])
                  ]),
              pw.SizedBox(height: 30),
              pw.Table.fromTextArray(
                headerStyle:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 8),
                headers: ["CODE", "DESCRIPTION", "UNITS", "FINAL", "REMARKS"],
                data: _gradeHistory
                    .map((g) => [
                          g['study_loads']['subjects']['code'],
                          g['study_loads']['subjects']['name'],
                          g['study_loads']['subjects']['units'].toString(),
                          g['final_grade'] ?? '-',
                          g['status'] ?? 'PASSED'
                        ])
                    .toList(),
              ),
              pw.SizedBox(height: 40),
              pw.Divider(),
              pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text("Digital Registrar Signature Applied",
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey))),
            ]));

    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file =
        File("${dir.path}/TOR_${_activeStudent!['user_id_number']}.pdf");
    await file.writeAsBytes(bytes);
    await OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode ? Colors.white : pViolet;
    final Color cardColor = widget.isDarkMode ? surfaceDark : Colors.white;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 32),
          Expanded(
            child: _selectedStudentId == null
                ? _buildStudentRoster(cardColor, textColor)
                : _buildGradeLedgerView(cardColor, textColor),
          ),
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
            Text("Scholastic Records Hub",
                style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -0.5)),
            const Text(
                "Audit grade distribution, compute institutional GWAs, and verify transcripts.",
                style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
          ],
        ),
        if (_selectedStudentId != null)
          ElevatedButton.icon(
            onPressed: _generateTranscript,
            icon: const Icon(LucideIcons.fileText, size: 16),
            label: const Text("GENERATE TRANSCRIPT"),
            style: ElevatedButton.styleFrom(
                backgroundColor: aViolet,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
          ),
      ],
    );
  }

  Widget _buildStudentRoster(Color cardColor, Color textColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10)),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: textColor),
            onChanged: (v) => setState(() {}),
            decoration: const InputDecoration(
              hintText: "Lookup Student by Name or LRD ID...",
              prefixIcon: Icon(LucideIcons.search, size: 18, color: aViolet),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10)),
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.client
                  .from('profiles')
                  .stream(primaryKey: ['id']).eq('role', 'student'),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(
                      child: CircularProgressIndicator(color: aViolet));

                final list = snapshot.data!.where((s) {
                  final name = "${s['fn']} ${s['ln']}".toUpperCase();
                  final id = s['user_id_number'].toString();
                  final query = _searchController.text.toUpperCase();
                  return query.isEmpty ||
                      name.contains(query) ||
                      id.contains(query);
                }).toList();

                if (list.isEmpty)
                  return _emptyState("No students found in cloud records.");

                return ListView.separated(
                  itemCount: list.length,
                  padding: const EdgeInsets.all(12),
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, i) {
                    final s = list[i];
                    return ListTile(
                      onTap: () => _fetchStudentGrades(s['id']),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                          backgroundColor: aViolet.withOpacity(0.1),
                          child: Text(s['ln'][0],
                              style: const TextStyle(
                                  color: aViolet,
                                  fontWeight: FontWeight.bold))),
                      title: Text("${s['ln']}, ${s['fn']}".toUpperCase(),
                          style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      subtitle: Text("LRD: ${s['user_id_number']}",
                          style: const TextStyle(
                              color: Colors.blueGrey, fontSize: 11)),
                      trailing: const Icon(LucideIcons.chevronRight,
                          size: 16, color: Colors.blueGrey),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradeLedgerView(Color cardColor, Color textColor) {
    if (_isLoading)
      return const Center(child: CircularProgressIndicator(color: aViolet));

    final gwa = _calculateGWA();

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                  icon: Icon(LucideIcons.arrowLeft, color: textColor),
                  onPressed: () => setState(() => _selectedStudentId = null)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "${_activeStudent!['fn']} ${_activeStudent!['ln']}"
                          .toUpperCase(),
                      style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: textColor)),
                  Text(
                      "${_activeStudent!['student_details']?['courses']?['name'] ?? 'N/A'}",
                      style: const TextStyle(
                          color: Colors.blueGrey, fontSize: 12)),
                ],
              ),
              const Spacer(),
              _statBadge("INSTITUTIONAL GWA: ${gwa.toStringAsFixed(2)}",
                  gwa > 0 ? success : Colors.orangeAccent),
            ],
          ),
          const Divider(height: 60, color: Colors.white10),
          _tableHeader([
            'CODE',
            'SUBJECT DESCRIPTION',
            'UNITS',
            'NUMERIC',
            'GRADE',
            'REMARKS'
          ]),
          Expanded(
            child: _gradeHistory.isEmpty
                ? _emptyState("No scholastic records found for this period.")
                : ListView.separated(
                    itemCount: _gradeHistory.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (context, i) {
                      final g = _gradeHistory[i];
                      final sub = g['study_loads']['subjects'];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(sub['code'],
                                    style: const TextStyle(
                                        color: Colors.blueGrey,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold))),
                            Expanded(
                                flex: 3,
                                child: Text(sub['name'],
                                    style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13))),
                            Expanded(
                                child: Text(sub['units'].toString(),
                                    style: const TextStyle(fontSize: 12))),
                            Expanded(
                                child: Text(
                                    g['final_numeric_grade']?.toString() ?? '-',
                                    style: GoogleFonts.orbitron(
                                        fontSize: 12,
                                        color: aViolet,
                                        fontWeight: FontWeight.bold))),
                            Expanded(
                                child: Text(g['final_grade'] ?? '-',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900))),
                            Expanded(
                                child: _statusChip(g['status'] ?? 'Passed')),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(List<String> titles) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.02)
                : const Color(0xFFF8FAFC),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24))),
        child: Row(
            children: titles
                .map((t) => Expanded(
                    flex: t == 'SUBJECT DESCRIPTION' ? 3 : 1,
                    child: Text(t,
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.blueGrey,
                            letterSpacing: 1.2))))
                .toList()),
      );

  Widget _statBadge(String t, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withOpacity(0.3))),
      child: Text(t,
          style: GoogleFonts.inter(
              color: c, fontSize: 10, fontWeight: FontWeight.w900)));

  Widget _statusChip(String status) {
    bool isPassed =
        status.toUpperCase() == 'PASSED' || status.toUpperCase() == 'RELEASED';
    Color color = isPassed ? success : Colors.redAccent;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6)),
        child: Text(status.toUpperCase(),
            style: GoogleFonts.inter(
                color: color, fontSize: 8, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center));
  }

  Widget _emptyState(String msg) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(LucideIcons.fileX,
            size: 48, color: Colors.blueGrey.withOpacity(0.2)),
        const SizedBox(height: 16),
        Text(msg,
            style: const TextStyle(
                color: Colors.blueGrey, fontWeight: FontWeight.bold))
      ]));
}
