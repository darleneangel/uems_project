import 'package:flutter/foundation.dart'
    show kIsWeb; // FIXED: Imported platform check for safe web downloads
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart'; // Standard cross-platform PDF layout/share engine
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

class TeachingLoadPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const TeachingLoadPanel({
    super.key,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  State<TeachingLoadPanel> createState() => _TeachingLoadPanelState();
}

class _TeachingLoadPanelState extends State<TeachingLoadPanel> {
  final SupabaseService _service = SupabaseService();

  List<Map<String, dynamic>> _teachingLoad = [];
  bool _isLoading = true;

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);
  static const Color success = Color(0xFF69F0AE);

  @override
  void initState() {
    super.initState();
    _loadTeachingLoad();
  }

  /// 🛰️ DATABASE: Fetches subjects assigned to this specific teacher
  Future<void> _loadTeachingLoad() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final String profId = widget.userData['id'];

    try {
      // 1. Fetch Master Schedule entries for this Professor
      final masterResponse = await _service.client
          .from('study_loads')
          .select('*, subjects(*)')
          .eq('professor_id', profId)
          .filter('student_id', 'is', null);

      List<Map<String, dynamic>> loadData =
          List<Map<String, dynamic>>.from(masterResponse);

      // 2. Aggregate Student Counts per Subject
      for (var load in loadData) {
        final List res = await _service.client
            .from('study_loads')
            .select('student_id')
            .eq('professor_id', profId)
            .eq('subject_id', load['subject_id'])
            .filter('student_id', 'not.is', null);

        // 🛡️ UNIQUE CALCULATION: Handles duplicate database entries (e.g. Amber appearing 3x)
        final uniqueStudents = res.map((e) => e['student_id']).toSet();
        load['student_count'] = uniqueStudents.length;
      }

      if (mounted) {
        setState(() {
          _teachingLoad = loadData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Teaching Load Sync Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🛰️ DATABASE: Fetches the roster and filters out duplicates
  Future<List<Map<String, dynamic>>> _getRosterData(String subjectId) async {
    final response = await _service.client
        .from('study_loads')
        .select('''
            profiles!study_loads_student_id_fkey(
              id,
              user_id_number, 
              fn, 
              ln,
              student_details(student_type)
            )
        ''')
        .eq('professor_id', widget.userData['id'])
        .eq('subject_id', subjectId)
        .filter('student_id', 'not.is', null);

    final List<Map<String, dynamic>> rawRoster =
        List<Map<String, dynamic>>.from(response);

    // 🛡️ UNIQUE FILTER: Prevents duplicate student list rendering
    final Map<String, Map<String, dynamic>> uniqueRoster = {};
    for (var entry in rawRoster) {
      final profile = entry['profiles'];
      if (profile != null) {
        final String studentId = profile['user_id_number'].toString();
        uniqueRoster[studentId] = profile;
      }
    }

    return uniqueRoster.values.toList();
  }

  void _showRosterDialog(Map<String, dynamic> load) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            const Icon(Icons.people_rounded, color: aViolet, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Class Roster",
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          color: widget.isDarkMode ? Colors.white : pViolet)),
                  Text(
                      "${load['subjects']?['code'] ?? 'N/A'} • ${load['section_block'] ?? 'MASTER'}",
                      style: const TextStyle(
                          fontSize: 12, color: Colors.blueGrey)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _generateRosterPDF(load),
              icon: const Icon(Icons.file_download_rounded,
                  color: aViolet, size: 24),
            ),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _getRosterData(load['subject_id'].toString()),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                    height: 200,
                    child: Center(
                        child: CircularProgressIndicator(color: aViolet)));
              }

              final roster = snapshot.data ?? [];
              if (roster.isEmpty) {
                return const SizedBox(
                    height: 100,
                    child: Center(
                        child: Text("No students enrolled.",
                            style: TextStyle(color: Colors.blueGrey))));
              }

              return SingleChildScrollView(
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(4),
                    2: FlexColumnWidth(2)
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: Colors.white10))),
                      children: [
                        _tableCell("ID NUMBER", isHeader: true),
                        _tableCell("STUDENT NAME", isHeader: true),
                        _tableCell("CLASSIFICATION", isHeader: true),
                      ],
                    ),
                    ...roster.map((profile) {
                      final detailsRaw = profile['student_details'];
                      final details =
                          (detailsRaw is List && detailsRaw.isNotEmpty)
                              ? detailsRaw.first
                              : detailsRaw;
                      final String type = details?['student_type'] ?? "Regular";

                      return TableRow(
                        children: [
                          _tableCell(profile['user_id_number'].toString()),
                          _tableCell("${profile['ln']}, ${profile['fn']}"
                              .toUpperCase()),
                          _tableCell(type.toString().toUpperCase(),
                              isStatus: true),
                        ],
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CLOSE"))
        ],
      ),
    );
  }

  Widget _tableCell(String text,
      {bool isHeader = false, bool isStatus = false}) {
    final Color textColor = widget.isDarkMode ? Colors.white : pViolet;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isHeader ? 10 : 12,
          fontWeight:
              isHeader || isStatus ? FontWeight.w900 : FontWeight.normal,
          color: isHeader
              ? Colors.blueGrey
              : (isStatus
                  ? (text == "REGULAR" ? success : Colors.orangeAccent)
                  : textColor),
        ),
      ),
    );
  }

  /// 📥 PDF GENERATION: Unified, web-safe, cross-platform export and save action for teaching load
  Future<void> _generateTeachingLoadPDF() async {
    final pdf = pw.Document();
    final date = DateFormat('MMMM dd, yyyy').format(DateTime.now());
    final profName =
        "${widget.userData['fn']} ${widget.userData['ln']}".toUpperCase();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("OFFICIAL TEACHING LOAD",
              style:
                  pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Divider(),
          pw.SizedBox(height: 20),
          pw.Text("FACULTY: $profName"),
          pw.Text("DATE GENERATED: $date"),
          pw.SizedBox(height: 30),
          pw.Table.fromTextArray(
            headers: ["CODE", "SUBJECT TITLE", "SECTION", "STUDENTS"],
            data: _teachingLoad
                .map((l) => [
                      l['subjects']['code'],
                      l['subjects']['name'],
                      l['section_block'] ?? 'MASTER',
                      l['student_count'].toString()
                    ])
                .toList(),
          ),
        ],
      ),
    ));

    try {
      final bytes = await pdf.save();
      // FIXED FOR WEB & DESKTOP: Bypasses the native path/sharing locks by conditionally calling Printing layout or share triggers
      if (kIsWeb) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => bytes,
          name: 'TeachingLoad_${widget.userData['ln']}.pdf',
        );
        _showToast("PDF Teaching Load ready for print/download!", success);
      } else {
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'TeachingLoad_${widget.userData['ln']}.pdf',
        );
        _showToast("PDF Teaching Load successfully saved!", success);
      }
    } catch (e) {
      _showToast("Could not save PDF file.", Colors.redAccent);
    }
  }

  /// 📥 PDF GENERATION: Unified, web-safe, cross-platform export and save action for class roster
  Future<void> _generateRosterPDF(Map<String, dynamic> load) async {
    final roster = await _getRosterData(load['subject_id'].toString());
    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("OFFICIAL CLASS ROSTER",
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Text(
              "Subject: ${load['subjects']['name']} (${load['subjects']['code']})"),
          pw.Divider(),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ["ID NUMBER", "NAME", "CLASSIFICATION"],
            data: roster.map((p) {
              final details = p['student_details'];
              final String type = (details is List && details.isNotEmpty)
                  ? details.first['student_type']
                  : "Regular";
              return [
                p['user_id_number'].toString(),
                "${p['ln']}, ${p['fn']}".toUpperCase(),
                type.toUpperCase()
              ];
            }).toList(),
          ),
        ],
      ),
    ));

    try {
      final bytes = await pdf.save();
      // FIXED FOR WEB & DESKTOP: Bypasses the native path/sharing locks by conditionally calling Printing layout or share triggers
      if (kIsWeb) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => bytes,
          name: 'Roster_${load['subjects']['code']}.pdf',
        );
        _showToast("PDF Class Roster ready for print/download!", success);
      } else {
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'Roster_${load['subjects']['code']}.pdf',
        );
        _showToast("PDF Class Roster successfully saved!", success);
      }
    } catch (e) {
      _showToast("Could not save PDF file.", Colors.redAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode ? Colors.white : pViolet;
    final Color bgColor = widget.isDarkMode ? surfaceDark : Colors.white;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: aViolet));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Faculty Teaching Load",
                        style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: -1)),
                    const SizedBox(height: 4),
                    const Text("Active Semester: 2nd Semester SY 2025-2026",
                        style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                  onPressed: _generateTeachingLoadPDF,
                  icon: const Icon(Icons.file_download_rounded, size: 20),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: aViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0),
                  label: const Text("DOWNLOAD LOAD",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13))),
            ],
          ),
          const SizedBox(height: 32),
          if (_teachingLoad.isEmpty)
            _buildEmptyState(textColor)
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _teachingLoad.length,
              itemBuilder: (context, index) {
                final load = _teachingLoad[index];
                final subject = load['subjects'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: widget.isDarkMode
                              ? Colors.white10
                              : Colors.black12)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(subject?['code'] ?? 'N/A',
                                style: const TextStyle(
                                    color: aViolet,
                                    fontWeight: FontWeight.bold)),
                            Text(subject?['name'] ?? 'Undefined Subject',
                                style: TextStyle(
                                    color: textColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            Text(
                                "${load['section_block'] ?? 'MASTER'} • ${load['student_count']} Active Students",
                                style: const TextStyle(color: Colors.blueGrey)),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                          onPressed: () => _showRosterDialog(load),
                          icon: const Icon(Icons.people_outline_rounded,
                              size: 18),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: aViolet,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          label: const Text("VIEW ROSTER",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color t) => Center(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Icon(Icons.menu_book_rounded, size: 64, color: t.withOpacity(0.1)),
            const SizedBox(height: 24),
            const Text("No teaching loads assigned in current cycle.",
                style: TextStyle(
                    color: Colors.blueGrey, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  void _showToast(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }
}
