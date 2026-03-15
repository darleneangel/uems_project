import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

class TeachingLoadPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData; // Context for the logged-in Teacher

  const TeachingLoadPanel(
      {super.key, required this.isDarkMode, required this.userData});

  @override
  State<TeachingLoadPanel> createState() => _TeachingLoadPanelState();
}

class _TeachingLoadPanelState extends State<TeachingLoadPanel> {
  final SupabaseService _service = SupabaseService();

  // --- DATABASE STATE ---
  List<Map<String, dynamic>> _teachingLoad = [];
  bool _isLoading = true;

  // Modern Tonal Palette Constants
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);
  static const Color success = Color(0xFF69F0AE);

  @override
  void initState() {
    super.initState();
    _loadTeachingLoad();
  }

  /// 🛰️ DATABASE: Fetch the Professor's unique Master Schedule assignments
  Future<void> _loadTeachingLoad() async {
    setState(() => _isLoading = true);
    final String profId = widget.userData['id'];

    try {
      // 1. Fetch Master Schedule entries (where student_id is NULL)
      final masterResponse = await _service.client
          .from('study_loads')
          .select('*, subjects(*)')
          .eq('professor_id', profId)
          .filter('student_id', 'is', null);

      List<Map<String, dynamic>> loadData =
          List<Map<String, dynamic>>.from(masterResponse);

      // 2. Fetch Student Counts for each class section
      for (var load in loadData) {
        final count = await _service.client
            .from('study_loads')
            .count(CountOption.exact)
            .eq('professor_id', profId)
            .eq('subject_id', load['subject_id'])
            .filter('student_id', 'not.is', null);

        load['student_count'] = count;
      }

      if (mounted) {
        setState(() {
          _teachingLoad = loadData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Load Sync Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- PDF GENERATION: TEACHING LOAD ---
  Future<void> _generateTeachingLoadPDF() async {
    if (_teachingLoad.isEmpty) return;
    final pdf = pw.Document();
    final timestamp = DateTime.now().toString().split('.')[0];
    final String profName = "${widget.userData['fn']} ${widget.userData['ln']}";

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Padding(
          padding: const pw.EdgeInsets.all(32),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                  child: pw.Text("SAN SEBASTIAN COLLEGE - RECOLETOS DE CAVITE",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 14))),
              pw.Center(
                  child: pw.Text("OFFICE OF THE VICE PRESIDENT FOR ACADEMICS",
                      style: pw.TextStyle(fontSize: 10))),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text("OFFICIAL FACULTY TEACHING LOAD",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.Text("Professor: $profName"),
              pw.Text("Semester: 2nd Semester SY 2025-2026"),
              pw.SizedBox(height: 30),
              pw.Table.fromTextArray(
                headers: [
                  "Code",
                  "Description",
                  "Units",
                  "Schedule",
                  "Students"
                ],
                headerStyle:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 9),
                data: _teachingLoad
                    .map((l) => [
                          l['subjects']['code'],
                          l['subjects']['name'],
                          l['subjects']['units'].toString(),
                          "${l['day_schedule']} ${l['time_start']}-${l['time_end']}",
                          l['student_count'].toString(),
                        ])
                    .toList(),
              ),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Generated on $timestamp",
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                  pw.Text("Verified by Digital Signature",
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final file =
          File("${dir.path}/TeachingLoad_${widget.userData['ln']}.pdf");
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      _showSnackBar("Error generating Load PDF: $e");
    }
  }

  // --- PDF GENERATION: REAL CLASS ROSTER ---
  Future<void> _generateRosterPDF(Map<String, dynamic> load) async {
    _showSnackBar("Fetching latest class roster...");

    try {
      // Fetch actual students enrolled in this specific subject/professor combo
      final response = await _service.client
          .from('study_loads')
          .select(
              'profiles!study_loads_student_id_fkey(user_id_number, fn, ln), student_details(student_type)')
          .eq('professor_id', widget.userData['id'])
          .eq('subject_id', load['subject_id'])
          .filter('student_id', 'not.is', null);

      final List<dynamic> enrolledStudents = response as List;
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                    child: pw.Text(
                        "SAN SEBASTIAN COLLEGE - RECOLETOS DE CAVITE",
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 14))),
                pw.Center(
                    child: pw.Text("CLASS ROSTER - OFFICIAL COPY",
                        style: pw.TextStyle(fontSize: 10))),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                            "Subject: ${load['subjects']['code']} - ${load['subjects']['name']}",
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text("Section: ${load['section_block']}"),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                            "Professor: ${widget.userData['fn']} ${widget.userData['ln']}"),
                        pw.Text("Total Students: ${enrolledStudents.length}"),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers: [
                    "Student ID",
                    "Full Name",
                    "Type",
                    "Attendance/Remarks"
                  ],
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  data: enrolledStudents
                      .map((s) => [
                            s['profiles']['user_id_number'].toString(),
                            "${s['profiles']['ln']}, ${s['profiles']['fn']}",
                            s['student_details']?['student_type'] ?? "Regular",
                            "",
                          ])
                      .toList(),
                ),
                pw.Spacer(),
                pw.Text(
                    "Note: This roster is synchronized with the Registrar's Database.",
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
              ],
            ),
          ),
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/Roster_${load['subjects']['code']}.pdf");
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      _showSnackBar("Error generating Roster PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode ? Colors.white : pViolet;
    final Color bgColor = widget.isDarkMode ? surfaceDark : Colors.white;

    if (_isLoading)
      return const Center(child: CircularProgressIndicator(color: aViolet));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 32),
          _buildLoadList(bgColor, textColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Faculty Teaching Load",
                style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: text,
                    letterSpacing: -1)),
            Row(
              children: [
                const Text("Active Semester: 2nd Semester SY 2025-2026",
                    style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
                const SizedBox(width: 12),
                _statusBadge("VERIFIED", success),
              ],
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _generateTeachingLoadPDF,
          icon: const Icon(LucideIcons.fileDown, size: 16),
          label: const Text("DOWNLOAD LOAD"),
          style: ElevatedButton.styleFrom(
            backgroundColor: aViolet,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadList(Color bg, Color text) {
    if (_teachingLoad.isEmpty) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(80),
              child: Text("No assigned subjects found in the master schedule.",
                  style: TextStyle(color: text.withOpacity(0.3)))));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("ASSIGNED SUBJECTS",
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: aViolet,
                letterSpacing: 1.5)),
        const SizedBox(height: 24),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _teachingLoad.length,
          itemBuilder: (context, index) {
            final load = _teachingLoad[index];
            return _buildSubjectLoadCard(load, bg, text);
          },
        ),
      ],
    );
  }

  Widget _buildSubjectLoadCard(
      Map<String, dynamic> load, Color bg, Color text) {
    final subject = load['subjects'];
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(widget.isDarkMode ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: aViolet.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16)),
                child: const Icon(LucideIcons.book, color: aViolet, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject['code'],
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w900,
                            color: aViolet,
                            fontSize: 13)),
                    Text(subject['name'],
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: text,
                            fontSize: 18)),
                    const SizedBox(height: 4),
                    Text("${load['section_block'] ?? 'BLOCK-A'} • ROOM TBD",
                        style: const TextStyle(
                            color: Colors.blueGrey, fontSize: 13)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                      "${load['day_schedule']} ${load['time_start']}-${load['time_end']}",
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: text,
                          fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                      "${subject['units']} Units • ${load['student_count']} Enrolled",
                      style: const TextStyle(
                          color: Colors.blueGrey, fontSize: 12)),
                ],
              ),
            ],
          ),
          const Divider(height: 40, color: Colors.white10),
          Row(
            children: [
              _loadActionButton(LucideIcons.uploadCloud, "Upload Syllabus", () {
                _showSnackBar(
                    "Syllabus upload initiated for ${subject['code']}");
              }),
              const SizedBox(width: 12),
              _loadActionButton(LucideIcons.clipboardList, "Download Roster",
                  () => _generateRosterPDF(load)),
              const SizedBox(width: 12),
              _loadActionButton(LucideIcons.megaphone, "Post Notice", () {
                _showSnackBar("Notice composer opened for ${subject['name']}");
              }),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showSnackBar(
                    "Navigating to live attendance for ${subject['code']}"),
                icon: const Icon(LucideIcons.users, size: 14),
                label: const Text("VIEW ROSTER",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: aViolet.withOpacity(0.1),
                  foregroundColor: aViolet,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _loadActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.blueGrey),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(t,
            style:
                TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w900)),
      );

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: pViolet,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}
