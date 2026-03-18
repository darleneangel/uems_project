import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../../services/supabase_service.dart';

class StudentTrackingPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData; // Context for the logged-in Teacher

  const StudentTrackingPanel(
      {super.key, required this.isDarkMode, required this.userData});

  @override
  State<StudentTrackingPanel> createState() => _StudentTrackingPanelState();
}

class _StudentTrackingPanelState extends State<StudentTrackingPanel> {
  final SupabaseService _service = SupabaseService();

  // --- DATABASE STATE ---
  List<Map<String, dynamic>> _studentTrackingList = [];
  bool _isLoading = true;

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);
  static const Color success = Color(0xFF69F0AE);

  @override
  void initState() {
    super.initState();
    _loadTrackingData();
  }

  /// 🛰️ DATABASE: Fetch all students under this teacher's instruction and calculate progress
  Future<void> _loadTrackingData() async {
    setState(() => _isLoading = true);
    final String profId = widget.userData['id'];

    try {
      // Fetch study loads assigned to this professor, including student profiles
      final response = await _service.client.from('study_loads').select('''
            *,
            profiles!study_loads_student_id_fkey(id, fn, ln, user_id_number),
            subjects(code, name)
          ''').eq('professor_id', profId).filter('student_id', 'not.is', null);

      final List<dynamic> rawData = response as List;

      // Process data: Aggregate multiple subjects per student if necessary
      // For this panel, we'll show unique student-subject pairs to track specific progress
      final List<Map<String, dynamic>> processed =
          rawData.map<Map<String, dynamic>>((load) {
        double progressValue = 0.0;
        int completedFields = 0;

        // Progress logic: Check if Assignment, Exam, and Project grades are entered
        if (load['assignment_grade'] != null && load['assignment_grade'] != 0) {
          completedFields++;
        }
        if (load['exam_grade'] != null && load['exam_grade'] != 0) {
          completedFields++;
        }
        if (load['project_grade'] != null && load['project_grade'] != 0) {
          completedFields++;
        }

        progressValue = completedFields / 3.0;

        return {
          ...load,
          'progress_percent': (progressValue * 100).toInt(),
          'progress_value': progressValue,
          'student_name': "${load['profiles']['fn']} ${load['profiles']['ln']}",
          'student_id_num': load['profiles']['user_id_number'],
        };
      }).toList();

      if (mounted) {
        setState(() {
          _studentTrackingList = processed;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Tracking Sync Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 📄 PDF ENGINE: Generates a real-time progress report for a specific student record
  Future<void> _generateReport(
      BuildContext context, Map<String, dynamic> data) async {
    final pdf = pw.Document();
    final String timestamp = DateTime.now().toString().split('.')[0];
    final String profName = "${widget.userData['fn']} ${widget.userData['ln']}";

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Padding(
          padding: const pw.EdgeInsets.all(40),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  "UEMS ACADEMIC PROGRESS REPORT",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 16),
                ),
              ),
              pw.SizedBox(height: 40),
              pw.Text("Student Name: ${data['student_name']}"),
              pw.Text("Student ID: ${data['student_id_num']}"),
              pw.Text(
                  "Subject: ${data['subjects']['code']} - ${data['subjects']['name']}"),
              pw.Text("Date Generated: $timestamp"),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text("Instructional Feedback Summary:",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Bullet(
                  text:
                      "Current Subject Completion: ${data['progress_percent']}%"),
              pw.Bullet(
                  text:
                      "Final Grade Standing: ${data['final_grade'] ?? 'In-Progress'}"),
              pw.Bullet(text: "Roster Status: Verified Enrolled"),
              pw.Spacer(),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("Certified by: $profName",
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text("Department Faculty Instructor",
                        style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final String fileName =
          "Progress_${data['student_id_num']}_${data['subjects']['code']}.pdf";
      final file = File("${dir.path}/$fileName");
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      debugPrint("PDF Generation Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode ? Colors.white : pViolet;
    final Color cardColor = widget.isDarkMode ? surfaceDark : Colors.white;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Student Progress Tracking",
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: -1,
            ),
          ),
          const Text(
            "Monitor academic milestones and syllabus completion across your assigned classes.",
            style: TextStyle(color: Colors.blueGrey, fontSize: 14),
          ),
          const SizedBox(height: 32),
          if (_isLoading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(100),
                    child: CircularProgressIndicator(color: aViolet)))
          else if (_studentTrackingList.isEmpty)
            _buildEmptyState(textColor)
          else
            _buildTrackingList(context, cardColor, textColor),
        ],
      ),
    );
  }

  Widget _buildTrackingList(
      BuildContext context, Color cardColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _studentTrackingList.length,
        separatorBuilder: (context, i) =>
            const Divider(height: 1, color: Colors.white10),
        itemBuilder: (context, index) {
          final data = _studentTrackingList[index];
          final double progress = data['progress_value'];
          final int percent = data['progress_percent'];

          return ListTile(
            contentPadding: const EdgeInsets.all(24),
            leading: CircleAvatar(
              backgroundColor: aViolet.withOpacity(0.1),
              child: const Icon(LucideIcons.user, color: aViolet, size: 18),
            ),
            title: Text(
              data['student_name'],
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  "${data['subjects']['code']} • ID: ${data['student_id_num']}",
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Subject Progress: $percent%",
                      style: const TextStyle(
                          color: aViolet,
                          fontSize: 10,
                          fontWeight: FontWeight.w900),
                    ),
                    if (percent == 100)
                      const Icon(LucideIcons.checkCircle2,
                          color: success, size: 14),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: widget.isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                    color: percent == 100 ? success : aViolet,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
            trailing: ElevatedButton.icon(
              onPressed: () => _generateReport(context, data),
              icon: const Icon(LucideIcons.fileText, size: 14),
              label: const Text(
                "GENERATE REPORT",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: aViolet.withOpacity(0.1),
                foregroundColor: aViolet,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(Color t) => Center(
        child: Padding(
          padding: const EdgeInsets.all(80),
          child: Column(
            children: [
              Icon(LucideIcons.users, size: 48, color: t.withOpacity(0.1)),
              const SizedBox(height: 16),
              Text("No students currently assigned to your load.",
                  style: TextStyle(color: t.withOpacity(0.3))),
            ],
          ),
        ),
      );
}
