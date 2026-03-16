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
  final Map<String, dynamic> userData;

  const TeachingLoadPanel(
      {super.key, required this.isDarkMode, required this.userData});

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

  Future<void> _loadTeachingLoad() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final String profId = widget.userData['id'];

    try {
      final masterResponse = await _service.client
          .from('study_loads')
          .select('*, subjects(*)')
          .eq('professor_id', profId)
          .filter('student_id', 'is', null);

      List<Map<String, dynamic>> loadData =
          List<Map<String, dynamic>>.from(masterResponse);

      for (var load in loadData) {
        // Correct count usage
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

  /// 🛰️ DATABASE: Fixed Relational Join
  /// Accesses student_details via the profiles relationship
  Future<List<Map<String, dynamic>>> _getRosterData(String subjectId) async {
    final response = await _service.client
        .from('study_loads')
        .select('''
            profiles!study_loads_student_id_fkey(
              user_id_number, 
              fn, 
              ln,
              student_details(student_type)
            )
        ''')
        .eq('professor_id', widget.userData['id'])
        .eq('subject_id', subjectId)
        .filter('student_id', 'not.is', null);

    return List<Map<String, dynamic>>.from(response);
  }

  void _showRosterDialog(Map<String, dynamic> load) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            const Icon(LucideIcons.users, color: aViolet),
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
                      "${load['subjects']['code']} • ${load['section_block'] ?? 'N/A'}",
                      style: const TextStyle(
                          fontSize: 12, color: Colors.blueGrey)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _generateRosterPDF(load),
              icon: const Icon(LucideIcons.fileDown, color: aViolet, size: 20),
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
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox(
                    height: 100,
                    child: Center(
                        child: Text("No students enrolled.",
                            style: TextStyle(color: Colors.blueGrey))));
              }

              final roster = snapshot.data!;
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
                        _tableCell("NAME", isHeader: true),
                        _tableCell("STANDING", isHeader: true),
                      ],
                    ),
                    ...roster.map((s) {
                      final profile = s['profiles'];
                      // Access nested student_details safely
                      final detailsList = profile['student_details'];
                      final details =
                          (detailsList is List && detailsList.isNotEmpty)
                              ? detailsList.first
                              : detailsList;
                      final type = details?['student_type'] ?? "Regular";

                      return TableRow(
                        children: [
                          _tableCell(profile['user_id_number'].toString()),
                          _tableCell("${profile['ln']}, ${profile['fn']}"),
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

  Future<void> _generateTeachingLoadPDF() async {
    if (_teachingLoad.isEmpty) return;
    final pdf = pw.Document();
    final String profName = "${widget.userData['fn']} ${widget.userData['ln']}";
    pdf.addPage(pw.Page(
        build: (c) => pw.Center(child: pw.Text("Teaching Load: $profName"))));
    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/TeachingLoad_${widget.userData['ln']}.pdf");
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  Future<void> _generateRosterPDF(Map<String, dynamic> load) async {
    _showSnackBar("Fetching roster...");
    try {
      final enrolled = await _getRosterData(load['subject_id'].toString());
      final pdf = pw.Document();
      pdf.addPage(pw.Page(
          build: (c) => pw.Column(children: [
                pw.Text("Class Roster: ${load['subjects']['code']}"),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  data: enrolled
                      .map((s) => [
                            s['profiles']['user_id_number'].toString(),
                            "${s['profiles']['ln']}, ${s['profiles']['fn']}"
                          ])
                      .toList(),
                )
              ])));
      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/Roster_${load['subjects']['code']}.pdf");
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      _showSnackBar("PDF Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode ? Colors.white : pViolet;
    final Color bgColor = widget.isDarkMode ? surfaceDark : Colors.white;

    if (_isLoading)
      return const Center(child: CircularProgressIndicator(color: aViolet));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Faculty Teaching Load",
                      style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -1)),
                  const Text("Active Semester: 2nd Semester SY 2025-2026",
                      style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
                ],
              ),
              ElevatedButton.icon(
                  onPressed: _generateTeachingLoadPDF,
                  icon: const Icon(LucideIcons.fileDown),
                  label: const Text("DOWNLOAD LOAD")),
            ],
          ),
          const SizedBox(height: 32),
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
                          Text(subject['code'],
                              style: const TextStyle(
                                  color: aViolet, fontWeight: FontWeight.bold)),
                          Text(subject['name'],
                              style: TextStyle(
                                  color: textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          Text(
                              "${load['section_block'] ?? 'TBD'} • ${load['student_count']} Students",
                              style: const TextStyle(color: Colors.blueGrey)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                        onPressed: () => _showRosterDialog(load),
                        child: const Text("VIEW ROSTER")),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: pViolet,
        behavior: SnackBarBehavior.floating));
  }
}
