import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class StudentTrackingPanel extends StatelessWidget {
  final bool isDarkMode;
  const StudentTrackingPanel({super.key, required this.isDarkMode});

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);
  static const Color success = Color(0xFF69F0AE);

  Future<void> _generateReport(BuildContext context, String name) async {
    final pdf = pw.Document();
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
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              pw.SizedBox(height: 40),
              pw.Text("Student Name: $name"),
              pw.Text("Date: ${DateTime.now().toString().split(' ')[0]}"),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text("Academic Performance Summary:"),
              pw.SizedBox(height: 10),
              pw.Bullet(text: "Current Progress: 85%"),
              pw.Bullet(text: "Attendance: Satisfactory"),
              pw.Bullet(text: "Participation: High"),
              pw.Spacer(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  "Certified by: FACULTY_INSTRUCTOR_HUB",
                  style: pw.TextStyle(fontSize: 8),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        "${dir.path}/Progress_Report_${name.replaceAll(' ', '_')}.pdf",
      );
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      debugPrint("PDF Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = isDarkMode ? Colors.white : pViolet;
    final Color cardColor = isDarkMode ? surfaceDark : Colors.white;

    return SingleChildScrollView(
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
            ),
          ),
          const SizedBox(height: 32),
          _buildTrackingList(context, cardColor, textColor),
        ],
      ),
    );
  }

  Widget _buildTrackingList(
    BuildContext context,
    Color cardColor,
    Color textColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        children: List.generate(
          5,
          (index) => ListTile(
            contentPadding: const EdgeInsets.all(24),
            leading: const CircleAvatar(
              backgroundColor: aViolet,
              child: Icon(LucideIcons.user, color: Colors.white, size: 16),
            ),
            title: Text(
              "Sarah Jenkins",
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  "Current Progress: 85%",
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 0.85,
                    backgroundColor: Colors.white10,
                    color: aViolet,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
            trailing: ElevatedButton.icon(
              onPressed: () => _generateReport(context, "Sarah Jenkins"),
              icon: const Icon(LucideIcons.fileText, size: 14),
              label: const Text(
                "Generate Report",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: aViolet.withOpacity(0.1),
                foregroundColor: aViolet,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
