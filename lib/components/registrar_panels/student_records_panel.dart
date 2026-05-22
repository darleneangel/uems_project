import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

class StudentRecordsPanel extends StatefulWidget {
  final bool isDarkMode;
  const StudentRecordsPanel({super.key, required this.isDarkMode});

  @override
  State<StudentRecordsPanel> createState() => _StudentRecordsPanelState();
}

class _StudentRecordsPanelState extends State<StudentRecordsPanel> {
  String? _selectedStudentId;
  final TextEditingController _searchController = TextEditingController();

  // Filter State
  String? _selectedCourseFilter;
  String? _selectedYearFilter;
  List<Map<String, dynamic>> _courseList = [];
  List<Map<String, dynamic>> _yearLevelList = [];
  bool _isLoadingFilters = true;

  // Theme Constants
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
  }

  /// 🛰️ DATABASE: Loads metadata for the Smart Filter system
  Future<void> _loadFilterOptions() async {
    final client = SupabaseService().client;
    try {
      final results = await Future.wait([
        client.from('courses').select('id, name, code'),
        client.from('year_levels').select('id, definition'),
      ]);
      if (mounted) {
        setState(() {
          _courseList = List<Map<String, dynamic>>.from(results[0]);
          _yearLevelList = List<Map<String, dynamic>>.from(results[1]);
          _isLoadingFilters = false;
        });
      }
    } catch (e) {
      debugPrint("Filter Sync Error: $e");
    }
  }

  // --- PDF GENERATION ENGINE ---

  /// 📄 REGISTRATION FORM: Official Proof of Enrollment as a Formal Letter
  Future<void> _generateRegistrationForm(Map<String, dynamic> s) async {
    final pdf = pw.Document();
    final d = s['student_details'];
    final addr = s['addresses'];
    final date = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildInstitutionalLetterhead(),
                  pw.SizedBox(height: 15),
                  pw.Divider(thickness: 2, color: PdfColors.indigo900),
                  pw.SizedBox(height: 30),

                  // Formal Date & Salutation
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text("Date Issued: $date",
                        style: const pw.TextStyle(fontSize: 10)),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text("TO WHOM IT MAY CONCERN:",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.SizedBox(height: 15),

                  // Letter Body
                  pw.Text(
                    "This is to certify that the student named below is officially enrolled at Bright Future Academy for the current academic term. This document serves as official proof of enrollment and matriculation for all legal and institutional purposes.",
                    style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.4),
                    textAlign: pw.TextAlign.justify,
                  ),
                  pw.SizedBox(height: 30),

                  // II. STUDENT INFORMATION
                  pw.Text("II. STUDENT IDENTIFICATION",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                          color: PdfColors.grey700)),
                  pw.SizedBox(height: 10),
                  _pdfDataRow("Full Name:",
                      "${s['ln']}, ${s['fn']} ${s['mn'] ?? ''}".toUpperCase()),
                  _pdfDataRow("Student ID No:", s['user_id_number'] ?? 'N/A'),
                  _pdfDataRow(
                      "Degree Program:", d['courses']?['name'] ?? 'N/A'),
                  _pdfDataRow("Year Classification:",
                      d['year_levels']?['definition'] ?? 'N/A'),

                  pw.SizedBox(height: 30),

                  // III. ENROLLMENT DETAILS
                  pw.Text("III. ACADEMIC STATUS",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                          color: PdfColors.grey700)),
                  pw.SizedBox(height: 10),
                  _pdfDataRow("Academic Year:", "2025 - 2026"),
                  _pdfDataRow("Current Semester:", "2nd Semester"),
                  pw.SizedBox(height: 15),

                  pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      decoration: pw.BoxDecoration(
                          color: PdfColors.green50,
                          border: pw.Border.all(
                              color: PdfColors.green700, width: 1)),
                      child:
                          pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
                        pw.Text("ENROLLMENT STATUS: ",
                            style: const pw.TextStyle(fontSize: 10)),
                        pw.Text("VERIFIED ENROLLED",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.green900,
                                fontSize: 11)),
                      ])),

                  pw.Spacer(),
                  _buildRegistrarFooter(date),
                ])));

    _saveAndOpenPDF(pdf, "Certification_Enrollment_${s['user_id_number']}");
  }

  /// 📄 GOOD MORAL: Official Character Certification
  Future<void> _generateGoodMoralCert(Map<String, dynamic> s) async {
    final pdf = pw.Document();
    final date = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildInstitutionalLetterhead(),
                  pw.SizedBox(height: 15),
                  pw.Divider(thickness: 2, color: PdfColors.indigo900),
                  pw.SizedBox(height: 40),
                  pw.Center(
                      child: pw.Text("CERTIFICATE OF GOOD MORAL CHARACTER",
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 14))),
                  pw.SizedBox(height: 40),
                  pw.Text("TO WHOM IT MAY CONCERN:",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.SizedBox(height: 20),
                  pw.Text(
                      "This is to formally certify that ${s['fn']} ${s['ln']} with Student ID Number ${s['user_id_number']} is a student of Bright Future Academy and is known to be of good moral character.",
                      style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.6),
                      textAlign: pw.TextAlign.justify),
                  pw.SizedBox(height: 15),
                  pw.Text(
                      "As per the institutional records maintained by this office, the aforementioned student has no derogatory record nor any pending disciplinary case as of this date.",
                      style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.6),
                      textAlign: pw.TextAlign.justify),
                  pw.SizedBox(height: 30),
                  pw.Text(
                      "This certification is issued upon the request of the interested party for whatever legal or administrative purposes it may serve.",
                      style: const pw.TextStyle(fontSize: 11)),
                  pw.Spacer(),
                  _buildRegistrarFooter(date),
                ])));

    _saveAndOpenPDF(pdf, "Good_Moral_${s['user_id_number']}");
  }

  /// 📄 FORM 138: Term-based Report Card
  Future<void> _generateForm138(Map<String, dynamic> s, String semester) async {
    final pdf = pw.Document();
    final client = SupabaseService().client;

    final List<dynamic> gradesData = await client
        .from('grades')
        .select('*, study_loads!inner(subjects(*), semesters!inner(*))')
        .eq('study_loads.student_id', s['id'])
        .eq('study_loads.semesters.description', semester);

    pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
              pw.Text("FORM 138: REPORT ON LEARNING PROGRESS",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.Text("Student: ${s['fn']} ${s['ln']} | $semester",
                  style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: [
                  "CODE",
                  "SUBJECT DESCRIPTION",
                  "UNITS",
                  "FINAL",
                  "REMARKS"
                ],
                data: gradesData
                    .map((g) => [
                          g['study_loads']['subjects']['code'],
                          g['study_loads']['subjects']['name'],
                          g['study_loads']['subjects']['units'].toString(),
                          g['final_grade'] ?? '-',
                          g['status'] ?? 'Passed'
                        ])
                    .toList(),
              ),
            ]));

    _saveAndOpenPDF(pdf, "Form138_${s['user_id_number']}");
  }

  // --- PDF UI HELPERS ---

  pw.Widget _buildInstitutionalLetterhead() => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("BRIGHT FUTURE ACADEMY",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 20,
                      color: PdfColors.indigo900)),
              pw.Text("Institutional Core Campus",
                  style: const pw.TextStyle(fontSize: 9)),
              pw.Text("123 Academic Drive, Metro Manila, Philippines",
                  style: const pw.TextStyle(fontSize: 8)),
              pw.Text(
                  "Contact: (02) 888-BFA-00 | bright.future.academy.uemssp@gmail.com",
                  style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
          pw.Container(width: 60, height: 60, color: PdfColors.grey200),
        ],
      );

  pw.Widget _buildRegistrarFooter(String date) =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text("Certified by:", style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 40),
        pw.Container(
            width: 200,
            decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(width: 1)))),
        pw.Text("OFFICE OF THE UNIVERSITY REGISTRAR",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.Text("Bright Future Academy",
            style: const pw.TextStyle(fontSize: 9)),
        pw.SizedBox(height: 20),
        pw.Center(
            child: pw.Text(
                "Note: This is a system-generated document. Any alteration voids this certification. Issued on: $date",
                style: pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic)))
      ]);

  pw.Widget _pdfDataRow(String label, String value) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(children: [
        pw.SizedBox(
            width: 140,
            child: pw.Text(label,
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))),
        pw.Expanded(
            child: pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 10, fontWeight: pw.FontWeight.bold))),
      ]));

  Future<void> _saveAndOpenPDF(pw.Document pdf, String name) async {
    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/$name.pdf");
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final Color cardColor = widget.isDarkMode ? surfaceDark : Colors.white;

    if (_selectedStudentId != null) {
      return _buildComprehensiveDetailView(cardColor, textColor);
    }

    return Column(
      children: [
        _buildSmartSearchHeader(textColor, cardColor),
        const SizedBox(height: 24),
        Expanded(child: _buildStudentList(cardColor, textColor)),
      ],
    );
  }

  Widget _buildSmartSearchHeader(Color textColor, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: "Search by Name or LRD ID Number...",
                    prefixIcon: const Icon(LucideIcons.search, color: aViolet),
                    filled: true,
                    fillColor: widget.isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.02),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                  ),
                  onChanged: (v) => setState(() {}),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                  onPressed: () => _loadFilterOptions(),
                  icon: const Icon(LucideIcons.refreshCw,
                      color: aViolet, size: 20))
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(LucideIcons.filter, size: 16, color: Colors.blueGrey),
              const SizedBox(width: 12),
              Text("SMART FILTERS:",
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                      letterSpacing: 1)),
              const SizedBox(width: 16),
              _buildDropdownFilter(
                hint: "Select Program",
                value: _selectedCourseFilter,
                items: _courseList
                    .map((c) => DropdownMenuItem(
                        value: c['id'].toString(), child: Text(c['name'])))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCourseFilter = v),
              ),
              const SizedBox(width: 12),
              _buildDropdownFilter(
                hint: "Select Year",
                value: _selectedYearFilter,
                items: _yearLevelList
                    .map((y) => DropdownMenuItem(
                        value: y['id'].toString(),
                        child: Text(y['definition'])))
                    .toList(),
                onChanged: (v) => setState(() => _selectedYearFilter = v),
              ),
              const Spacer(),
              if (_selectedCourseFilter != null ||
                  _selectedYearFilter != null ||
                  _searchController.text.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() {
                    _selectedCourseFilter = null;
                    _selectedYearFilter = null;
                    _searchController.clear();
                  }),
                  icon: const Icon(LucideIcons.x, size: 14),
                  label: const Text("RESET",
                      style:
                          TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter(
      {required String hint,
      required String? value,
      required List<DropdownMenuItem<String>> items,
      required Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint,
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
          dropdownColor: surfaceDark,
          style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black,
              fontSize: 11,
              fontWeight: FontWeight.bold),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStudentList(Color cardColor, Color textColor) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseService()
          .client
          .from('profiles')
          .select('*, student_details!inner(*)')
          .eq('role', 'student'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: aViolet));
        }

        final list = (snapshot.data ?? []).where((s) {
          final details = s['student_details'];
          final name = "${s['fn']} ${s['ln']}".toUpperCase();
          final id = s['user_id_number'].toString();
          final query = _searchController.text.toUpperCase();

          final matchesSearch =
              query.isEmpty || name.contains(query) || id.contains(query);
          final matchesCourse = _selectedCourseFilter == null ||
              details['course_id'] == _selectedCourseFilter;
          final matchesYear = _selectedYearFilter == null ||
              details['year_level_id'] == _selectedYearFilter;

          return matchesSearch && matchesCourse && matchesYear;
        }).toList();

        if (list.isEmpty) return _buildEmptyState(textColor);

        return Container(
          decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10)),
          child: ListView.separated(
            itemCount: list.length,
            separatorBuilder: (c, i) =>
                const Divider(color: Colors.white10, height: 1),
            itemBuilder: (c, i) => ListTile(
              onTap: () => setState(() => _selectedStudentId = list[i]['id']),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              leading: CircleAvatar(
                  backgroundColor: aViolet.withOpacity(0.1),
                  child: Text(list[i]['ln'][0],
                      style: const TextStyle(
                          color: aViolet, fontWeight: FontWeight.bold))),
              title: Text("${list[i]['ln']}, ${list[i]['fn']}".toUpperCase(),
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              subtitle: Text(
                  "ID: ${list[i]['user_id_number']} • ${list[i]['student_details']?['enrollment_status']?.toUpperCase() ?? 'PENDING'}",
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 11)),
              trailing: const Icon(LucideIcons.chevronRight,
                  size: 16, color: Colors.blueGrey),
            ),
          ),
        );
      },
    );
  }

  Widget _buildComprehensiveDetailView(Color cardColor, Color textColor) {
    return FutureBuilder<Map<String, dynamic>>(
      future: SupabaseService().client.from('profiles').select('''
        *,
        student_details!inner (
          *,
          courses (name, code),
          year_levels (*)
        ),
        addresses (*)
      ''').eq('id', _selectedStudentId!).single(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final s = snap.data!;
        final details = s['student_details'];

        return SingleChildScrollView(
          child: Column(
            children: [
              Row(children: [
                IconButton(
                    icon: Icon(LucideIcons.arrowLeft, color: textColor),
                    onPressed: () => setState(() => _selectedStudentId = null)),
                Text("${s['fn']} ${s['ln']}".toUpperCase(),
                    style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: textColor)),
                const Spacer(),
                _badge(details['enrollment_status'] ?? "ENROLLED", success),
              ]),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      flex: 4, child: _buildDocVault(s, cardColor, textColor)),
                  const SizedBox(width: 24),
                  Expanded(
                      flex: 6,
                      child: _buildDossier(s, details, cardColor, textColor)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocVault(
      Map<String, dynamic> s, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("DOCUMENTATION VAULT",
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: aViolet,
                  letterSpacing: 1.5)),
          const SizedBox(height: 24),
          _docCard("FORM 138 (CARD)", LucideIcons.fileSpreadsheet,
              "Academic Performance", () => _showPeriodSelector(s), textColor),
          const SizedBox(height: 12),
          _docCard(
              "CERT. OF GOOD MORAL",
              LucideIcons.award,
              "Character Certification",
              () => _generateGoodMoralCert(s),
              textColor),
          const SizedBox(height: 12),
          _docCard(
              "TRANSCRIPT (TOR)",
              LucideIcons.fileText,
              "Permanent Records",
              () => _generateOfficialPDF(s, "Transcript of Records"),
              textColor),
          const SizedBox(height: 12),
          _docCard(
              "REGISTRATION FORM",
              LucideIcons.clipboardCheck,
              "Proof of Enrollment Certification",
              () => _generateRegistrationForm(s),
              textColor),
        ],
      ),
    );
  }

  Widget _buildDossier(Map<String, dynamic> s, Map<String, dynamic> d,
      Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("INSTITUTIONAL DOSSIER",
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: aViolet,
                  letterSpacing: 1.5)),
          const SizedBox(height: 32),
          _infoGrid([
            {
              "label": "LRN / Student ID",
              "value": s['user_id_number'] ?? 'N/A'
            },
            {"label": "Program", "value": d['courses']?['name'] ?? 'N/A'},
            {
              "label": "Year Level",
              "value": d['year_levels']?['definition'] ?? 'N/A'
            },
            {
              "label": "Current GWA",
              "value": d['current_gwa']?.toString() ?? '0.00'
            },
            {"label": "Email", "value": s['email'] ?? 'N/A'},
            {"label": "Gender", "value": s['gender'] ?? 'N/A'},
          ], textColor),
        ],
      ),
    );
  }

  Widget _infoGrid(List<Map<String, String>> items, Color text) {
    return Wrap(
      spacing: 40,
      runSpacing: 24,
      children: items
          .map((i) => SizedBox(
                width: 200,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(i['label']!.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: Colors.blueGrey,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(i['value']!,
                          style: TextStyle(
                              color: text,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ]),
              ))
          .toList(),
    );
  }

  void _showPeriodSelector(Map<String, dynamic> s) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: surfaceDark,
        title: const Text("Select Academic Period",
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _semItem("1st Semester 2025-2026", () {
            Navigator.pop(c);
            _generateForm138(s, "1st Semester");
          }),
          _semItem("2nd Semester 2025-2026", () {
            Navigator.pop(c);
            _generateForm138(s, "2nd Semester");
          }),
        ]),
      ),
    );
  }

  Widget _semItem(String t, VoidCallback onTap) => ListTile(
      title:
          Text(t, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      trailing: const Icon(LucideIcons.printer, color: aViolet, size: 18),
      onTap: onTap);

  Widget _docCard(
          String l, IconData i, String d, VoidCallback onTap, Color text) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10)),
          child: Row(children: [
            Icon(i, color: aViolet, size: 20),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(l,
                      style: TextStyle(
                          color: text,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                  Text(d,
                      style:
                          const TextStyle(color: Colors.blueGrey, fontSize: 9)),
                ])),
            const Icon(LucideIcons.download, color: success, size: 16),
          ]),
        ),
      );

  Widget _badge(String t, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(t.toUpperCase(),
          style:
              TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w900)));

  Widget _buildEmptyState(Color t) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(LucideIcons.users, color: aViolet.withOpacity(0.1), size: 64),
        const SizedBox(height: 16),
        Text("No student records matching your filter.",
            style: TextStyle(color: t.withOpacity(0.3)))
      ]));

  void _showToast(String m, Color c) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), backgroundColor: c));

  /// Fallback PDF Generator for TOR (Comprehensive)
  Future<void> _generateOfficialPDF(Map<String, dynamic> s, String type) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
        build: (c) =>
            pw.Center(child: pw.Text("Generating $type for ${s['fn']}..."))));
    _saveAndOpenPDF(pdf, "${type.replaceAll(' ', '_')}_${s['user_id_number']}");
  }
}
