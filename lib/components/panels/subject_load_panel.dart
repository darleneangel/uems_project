import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class SubjectLoadPanel extends StatelessWidget {
  final bool isDarkMode;
  const SubjectLoadPanel({super.key, required this.isDarkMode});

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surface = Color(0xFF1E1B4B);

  @override
  Widget build(BuildContext context) {
    final subjects = [
      {
        'subject': 'CS 101 - Data Structures',
        'day': 'Mon/Wed',
        'time': '08:00 - 09:30',
        'block': 'A',
      },
      {
        'subject': 'CS 102 - Web Development',
        'day': 'Tue/Thu',
        'time': '09:45 - 11:15',
        'block': 'B',
      },
      {
        'subject': 'CS 103 - Database Management',
        'day': 'Mon/Wed',
        'time': '13:00 - 14:30',
        'block': 'C',
      },
    ];

    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subject Load',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _exportPdf(context, subjects),
                        icon: const Icon(LucideIcons.fileText, size: 16),
                        label: const Text('PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: aViolet,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildTable(subjects),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(
            'School Year : 2025-2026',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
          ),
          Text(
            'Semester : 1st Semester',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<Map<String, String>> subjects) {
    return Table(
      children: subjects
          .map(
            (s) => TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    s['subject']!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    s['day']!,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    s['time']!,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  Future<void> _exportPdf(
    BuildContext context,
    List<Map<String, String>> data,
  ) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context ctx) => pw.Text("Student Subject Load Export"),
      ),
    );
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/load.pdf');
    await file.writeAsBytes(bytes);
    OpenFile.open(file.path);
  }
}
