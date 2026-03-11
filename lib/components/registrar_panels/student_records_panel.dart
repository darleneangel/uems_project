import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/supabase_service.dart';

class StudentRecordsPanel extends StatefulWidget {
  final bool isDarkMode;
  const StudentRecordsPanel({super.key, required this.isDarkMode});

  @override
  State<StudentRecordsPanel> createState() => _StudentRecordsPanelState();
}

class _StudentRecordsPanelState extends State<StudentRecordsPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedStudentId;
  final TextEditingController _searchController = TextEditingController();

  // Filter State
  String? _selectedCourseFilter;
  String? _selectedYearFilter;
  List<Map<String, dynamic>> _courseList = [];
  List<Map<String, dynamic>> _yearLevelList = [];

  // Theme Constants
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFilterOptions();
  }

  /// DATABASE: Pre-loads the metadata needed for the Smart Filter dropdowns
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
        });
      }
    } catch (e) {
      debugPrint("Filter Load Error: $e");
    }
  }

  // --- REGISTRAR SCANNER ENGINE ---

  void _openScanner() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F071D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        content: SizedBox(
          width: 500,
          height: 600,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("OFFICE TICKET SCANNER",
                      style: GoogleFonts.inter(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.x, color: Colors.white24)),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: aViolet)),
                  child: MobileScanner(
                    onDetect: (capture) {
                      final String? code = capture.barcodes.first.rawValue;
                      if (code != null) {
                        Navigator.pop(context);
                        _handleScannedTicket(code);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Align the student's QR code within the frame.",
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  /// SCAN LOGIC: Processes the QR data and allows status update to 'Released'
  Future<void> _handleScannedTicket(String hash) async {
    final client = SupabaseService().client;

    // Fetch request data joined with profile
    final request = await client
        .from('office_requests')
        .select('*, profiles(fn, ln, user_id_number, email)')
        .eq('qr_hash', hash)
        .maybeSingle();

    if (request == null) {
      _showToast(
          "Invalid QR: Ticket not found in cloud ledger.", Colors.redAccent);
      return;
    }

    final p = request['profiles'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Document Stub: ${request['request_type']}",
            style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow("Student:", "${p['fn']} ${p['ln']}"),
            _infoRow("Student ID:", p['user_id_number']),
            _infoRow("Payment:", request['payment_status'],
                color: request['payment_status'] == 'Paid'
                    ? success
                    : Colors.orangeAccent),
            _infoRow("Current Status:", request['request_status']),
            const Divider(color: Colors.white10, height: 32),
            const Text(
                "Action: By clicking 'RELEASE', you verify that the physical document has been handed to the student.",
                style: TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              await client.from('office_requests').update(
                  {'request_status': 'Released'}).eq('id', request['id']);
              Navigator.pop(context);
              _showToast(
                  "Document officially Released to ${p['fn']}.", success);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: success, foregroundColor: Colors.black),
            child: const Text("RELEASE DOCUMENT"),
          )
        ],
      ),
    );
  }

  // --- PDF GENERATION ENGINE ---

  Future<void> _generateOfficialPDF(Map<String, dynamic> s, String type,
      {String? semesterFilter}) async {
    final pdf = pw.Document();
    final client = SupabaseService().client;
    final String fullName = "${s['fn']} ${s['ln']}".toUpperCase();
    final String idNum = s['user_id_number'];

    var gradeQuery = client.from('grades').select('''
      midterm_grade, final_grade, status,
      study_loads!inner (
        section_block,
        subjects (code, name, units),
        semesters (description),
        academic_years (description)
      )
    ''').eq('study_loads.student_id', s['id']);

    if (semesterFilter != null) {
      gradeQuery = gradeQuery.eq(
          'study_loads.semesters.description', semesterFilter.split(' ')[0]);
    }

    final List<dynamic> gradesData = await gradeQuery;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) => [
        pw.Center(
            child: pw.Text("SAN SEBASTIAN COLLEGE - RECOLETOS DE CAVITE",
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 14))),
        pw.Center(
            child: pw.Text("OFFICE OF THE REGISTRAR",
                style: pw.TextStyle(fontSize: 10))),
        pw.SizedBox(height: 30),
        pw.Text(type.toUpperCase(),
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text("Student: $fullName"),
          pw.Text("ID: $idNum"),
        ]),
        pw.SizedBox(height: 20),
        pw.Table.fromTextArray(
          headers: ["CODE", "SUBJECT", "UNITS", "MID", "FINAL", "STATUS"],
          headerStyle:
              pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          cellStyle: const pw.TextStyle(fontSize: 8),
          data: gradesData
              .map((g) => [
                    g['study_loads']['subjects']['code'],
                    g['study_loads']['subjects']['name'],
                    g['study_loads']['subjects']['units'].toString(),
                    g['midterm_grade'] ?? '-',
                    g['final_grade'] ?? '-',
                    g['status'] ?? 'Passed'
                  ])
              .toList(),
        ),
        pw.Spacer(),
        pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text("Digital Registrar Signature Applied",
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey))),
      ],
    ));

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/${type.replaceAll(' ', '_')}_$idNum.pdf");
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final Color cardColor =
        widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;

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
                    hintText: "Smart Search: Name, ID, or Email...",
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
              _actionButton(
                  LucideIcons.scanLine, "SCAN STUB", success, _openScanner),
              const SizedBox(width: 12),
              _actionButton(LucideIcons.userPlus, "ADD NEW", aViolet, () {}),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(LucideIcons.filter, size: 16, color: Colors.blueGrey),
              const SizedBox(width: 12),
              Text("FILTERS:",
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                      letterSpacing: 1)),
              const SizedBox(width: 16),
              _buildDropdownFilter(
                hint: "All Programs",
                value: _selectedCourseFilter,
                items: _courseList
                    .map((c) => DropdownMenuItem(
                        value: c['id'].toString(), child: Text(c['name'])))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCourseFilter = v),
              ),
              const SizedBox(width: 12),
              _buildDropdownFilter(
                hint: "All Year Levels",
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
                  label: const Text("CLEAR ALL",
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
              style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
          dropdownColor: surfaceDark,
          style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStudentList(Color cardColor, Color textColor) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService()
          .client
          .from('profiles')
          .stream(primaryKey: ['id']).eq('role', 'student'),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator(color: aViolet));

        final list = snapshot.data!.where((s) {
          final matchesSearch = _searchController.text.isEmpty ||
              "${s['fn']} ${s['ln']}"
                  .toUpperCase()
                  .contains(_searchController.text.toUpperCase()) ||
              s['user_id_number'].toString().contains(_searchController.text);
          return matchesSearch;
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
                  child: Text(list[i]['fn'][0],
                      style: const TextStyle(
                          color: aViolet, fontWeight: FontWeight.bold))),
              title: Text("${list[i]['fn']} ${list[i]['ln']}",
                  style:
                      TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              subtitle: Text(
                  "ID: ${list[i]['user_id_number']} • ${list[i]['role'].toString().toUpperCase()}",
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
          year_levels (definition)
        ),
        addresses (*)
      ''').eq('id', _selectedStudentId!).single(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator(color: aViolet));
        if (!snap.hasData)
          return const Center(child: Text("Error retrieving student record."));

        final s = snap.data!;
        final details = s['student_details'];
        final address = s['addresses'] != null ? s['addresses'] : null;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildDetailHeader(s, textColor),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      flex: 4,
                      child: _buildVaultSection(s, cardColor, textColor)),
                  const SizedBox(width: 24),
                  Expanded(
                      flex: 6,
                      child: _buildDossierSection(
                          s, details, address, cardColor, textColor)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailHeader(Map<String, dynamic> s, Color t) {
    return Row(
      children: [
        IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: t),
            onPressed: () => setState(() => _selectedStudentId = null)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${s['fn']} ${s['ln']}",
                style: GoogleFonts.inter(
                    fontSize: 24, fontWeight: FontWeight.w900, color: t)),
            Text("Student Profile Record • Authenticated via SSCR-Cloud",
                style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
          ],
        ),
        const Spacer(),
        _badge(
            s['student_details']?['enrollment_status'] ?? "Unknown", success),
      ],
    );
  }

  Widget _buildVaultSection(
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
          _docPrintCard("FORM 138", LucideIcons.fileSpreadsheet,
              "Term Report Card", () => _showSemSelector(s), textColor),
          const SizedBox(height: 12),
          _docPrintCard(
              "TRANSCRIPT (TOR)",
              LucideIcons.fileText,
              "Permanent Academic Record",
              () => _generateOfficialPDF(s, "Official Transcript of Records"),
              textColor),
          const SizedBox(height: 12),
          _docPrintCard(
              "REGISTRATION",
              LucideIcons.clipboardCheck,
              "Current Term Matriculation",
              () => _generateOfficialPDF(s, "Registration Form"),
              textColor),
        ],
      ),
    );
  }

  Widget _buildDossierSection(Map<String, dynamic> s, Map<String, dynamic> d,
      Map<String, dynamic>? a, Color cardColor, Color textColor) {
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
          _sectionTitle("Academic Data"),
          _infoGrid([
            {"label": "Institutional ID", "value": s['user_id_number']},
            {
              "label": "Program / Course",
              "value": d?['courses']?['name'] ?? "Not Assigned"
            },
            {
              "label": "Year Level",
              "value": d?['year_levels']?['definition'] ?? "N/A"
            },
            {
              "label": "Current GWA",
              "value": d?['current_gwa']?.toString() ?? "0.00"
            },
            {
              "label": "Account Balance",
              "value": "₱${d?['account_balance'] ?? '0.00'}"
            },
            {"label": "Student Type", "value": d?['student_type'] ?? "Regular"},
          ], textColor),
          const Divider(height: 60, color: Colors.white10),
          _sectionTitle("Personal Identity"),
          _infoGrid([
            {"label": "Gender", "value": s['gender'] ?? 'Not Specified'},
            {"label": "Birthdate", "value": s['dob'] ?? 'N/A'},
            {"label": "Email", "value": s['email']},
          ], textColor),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(t,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.blueGrey)));

  Widget _infoGrid(List<Map<String, String>> items, Color text) {
    return Wrap(
      spacing: 32,
      runSpacing: 24,
      children: items
          .map((i) => SizedBox(
                width: 250,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(i['label']!.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.blueGrey,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(i['value']!,
                          style: TextStyle(
                              color: text,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ]),
              ))
          .toList(),
    );
  }

  void _showSemSelector(Map<String, dynamic> s) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text("Select Reporting Period",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _semItem("1st Semester 2025-2026", () {
            Navigator.pop(c);
            _generateOfficialPDF(s, "Form 138",
                semesterFilter: "1st Semester 2025-2026");
          }),
          _semItem("2nd Semester 2025-2026", () {
            Navigator.pop(c);
            _generateOfficialPDF(s, "Form 138",
                semesterFilter: "2nd Semester 2025-2026");
          }),
        ]),
      ),
    );
  }

  Widget _semItem(String t, VoidCallback onTap) => ListTile(
      title: Text(t, style: const TextStyle(color: Colors.white70)),
      trailing: const Icon(LucideIcons.printer, color: aViolet, size: 18),
      onTap: onTap);

  Widget _docPrintCard(String label, IconData icon, String desc,
          VoidCallback onTap, Color text) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10)),
          child: Row(children: [
            Icon(icon, color: aViolet, size: 24),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: TextStyle(
                          color: text,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  Text(desc,
                      style: const TextStyle(
                          color: Colors.blueGrey, fontSize: 10)),
                ])),
            const Text("PRINT",
                style: TextStyle(
                    color: success, fontSize: 10, fontWeight: FontWeight.w900)),
          ]),
        ),
      );

  Widget _badge(String t, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(t.toUpperCase(),
          style:
              TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w900)));
  Widget _actionButton(IconData i, String l, Color c, VoidCallback onTap) =>
      ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(i, size: 16),
          label: Text(l,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          style: ElevatedButton.styleFrom(
              backgroundColor: c,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))));
  Widget _buildEmptyState(Color t) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(LucideIcons.searchX, color: aViolet.withOpacity(0.1), size: 64),
        const SizedBox(height: 16),
        Text("No students match your current filters.",
            style: TextStyle(color: t.withOpacity(0.3)))
      ]));
  Widget _infoRow(String l, String v, {Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l, style: const TextStyle(color: Colors.white54)),
        Text(v,
            style: TextStyle(
                color: color ?? Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14))
      ]));
  void _showToast(String m, Color c) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), backgroundColor: c));
}
