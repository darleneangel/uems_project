import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
// note: `printing` plugin temporarily disabled in pubspec to avoid pdfium native build on Windows

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';

class StudentPanelContent extends StatefulWidget {
  final String panelType;

  const StudentPanelContent({super.key, required this.panelType});

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color tDark = Color(0xFF0F071D);
  static const Color surface = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);

  @override
  State<StudentPanelContent> createState() => _StudentPanelContentState();
}

class _StudentPanelContentState extends State<StudentPanelContent> {
  // interactive filters state
  String _selectedAcademicYear = '2025-2026';
  String _selectedSemester = '1st Semester';
  String? _selectedOfficeKey;

  @override
  Widget build(BuildContext context) {
    switch (widget.panelType) {
      case 'subject_load':
        return _buildSubjectLoadPanel(context);
      case 'assessment':
        return _buildAssessmentPanel();
      case 'grade_book':
        return _buildGradeBookPanel(context);
      case 'clearance':
        return _buildClearancePanel();
      case 'profile':
        return const ProfilePanel();
      case 'payment_upload':
        return const PaymentUploadPanel();
      case 'offices':
        return _buildOfficesPanel();
      default:
        return _buildDefaultPanel();
    }
  }

  Widget _buildOfficesPanel() {
    final offices = [
      {
        'key': 'registrar',
        'title': 'Registrar / Records',
        'icon': LucideIcons.clipboard,
      },
      {
        'key': 'cashier',
        'title': 'Cashier / Payments',
        'icon': LucideIcons.creditCard,
      },
      {
        'key': 'financial_aid',
        'title': 'Financial Aid & Scholarships',
        'icon': LucideIcons.award,
      },
      {
        'key': 'library',
        'title': 'Library Services',
        'icon': LucideIcons.bookOpen,
      },
      {
        'key': 'student_affairs',
        'title': 'Student Affairs',
        'icon': LucideIcons.users,
      },
      {'key': 'health', 'title': 'Health Services', 'icon': LucideIcons.heart},
      {
        'key': 'it',
        'title': 'IT Helpdesk / Accounts',
        'icon': LucideIcons.hardDrive,
      },
      {
        'key': 'career',
        'title': 'Career Services',
        'icon': LucideIcons.briefcase,
      },
      {
        'key': 'alumni',
        'title': 'Alumni & Degree Verification',
        'icon': LucideIcons.award,
      },
      {
        'key': 'exams',
        'title': 'Examinations / Academic Affairs',
        'icon': LucideIcons.fileText,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: StudentPanelContent.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with back button if form is open
              if (_selectedOfficeKey != null)
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _selectedOfficeKey = null),
                      icon: const Icon(Icons.arrow_back, color: Colors.white70),
                      label: const Text(
                        'Back to Offices',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Offices & Requests',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              // Show form or grid
              if (_selectedOfficeKey != null)
                _buildOfficeRequestForm(_selectedOfficeKey!)
              else
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 3.6,
                  children: offices.map((o) {
                    return InkWell(
                      onTap: () {
                        setState(() => _selectedOfficeKey = o['key'] as String);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: StudentPanelContent.aViolet.withOpacity(
                                  0.08,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                o['icon'] as IconData,
                                color: StudentPanelContent.aViolet,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    o['title'] as String,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Requests & Documents',
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOfficeRequestForm(String officeKey) {
    final officeNames = {
      'registrar': 'Registrar / Records',
      'cashier': 'Cashier / Payments',
      'financial_aid': 'Financial Aid & Scholarships',
      'library': 'Library Services',
      'student_affairs': 'Student Affairs',
      'health': 'Health Services',
      'it': 'IT Helpdesk / Accounts',
      'career': 'Career Services',
      'alumni': 'Alumni & Degree Verification',
      'exams': 'Examinations / Academic Affairs',
    };

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            officeNames[officeKey] ?? 'Request Form',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Student ID',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: '2025-00001',
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white10),
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Full Name',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'DARLENE ANGEL',
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white10),
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Contact (Email / Phone)',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'email@example.com',
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white10),
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Notes / Additional Info',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'Enter any special requests...',
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white10),
              ),
            ),
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                final ref = DateTime.now().millisecondsSinceEpoch
                    .toString()
                    .substring(7);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Request submitted — Ref: REQ-$ref')),
                );
                setState(() => _selectedOfficeKey = null);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: StudentPanelContent.aViolet,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Submit Request',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectLoadPanel(BuildContext context) {
    // Sample subject load data (replace with real data source)
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
      {
        'subject': 'CS 104 - Software Engineering',
        'day': 'Fri',
        'time': '10:00 - 12:00',
        'block': 'D',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header area matching requested compact format
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: Column(
            children: [
              Text(
                'Student Study Load',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                'School Year : $_selectedAcademicYear',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
              ),
              Text(
                'Semester : $_selectedSemester',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: StudentPanelContent.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: title + export buttons
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Subject Load',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _exportPdf(context, subjects),
                    icon: const Icon(LucideIcons.fileText),
                    label: const Text('Export PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: StudentPanelContent.aViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _exportCsv(context, subjects),
                    icon: const Icon(LucideIcons.fileSpreadsheet),
                    label: const Text('Open in Excel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: StudentPanelContent.aViolet,
                      side: BorderSide(
                        color: StudentPanelContent.aViolet.withOpacity(0.6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Table header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Subject',
                        style: GoogleFonts.inter(color: Colors.white54),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Day',
                        style: GoogleFonts.inter(color: Colors.white54),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Time',
                        style: GoogleFonts.inter(color: Colors.white54),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Block',
                        style: GoogleFonts.inter(color: Colors.white54),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Table rows
              ...subjects.map((s) {
                return Column(
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            s['subject']!,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            s['day']!,
                            style: GoogleFonts.inter(color: Colors.white70),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            s['time']!,
                            style: GoogleFonts.inter(color: Colors.white70),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            s['block']!,
                            style: GoogleFonts.inter(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(color: Colors.white10),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  // Export helpers
  Future<void> _exportPdf(
    BuildContext context,
    List<Map<String, String>> subjects,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'Student Study Load',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text('School Year : $_selectedAcademicYear'),
                pw.Text('Semester : $_selectedSemester'),
                pw.SizedBox(height: 12),
                pw.Table.fromTextArray(
                  headers: ['Subject', 'Day', 'Time', 'Block'],
                  data: subjects
                      .map(
                        (s) => [s['subject'], s['day'], s['time'], s['block']],
                      )
                      .toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/subject_load.pdf');
      await file.writeAsBytes(bytes);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved PDF to ${file.path}')));
      await OpenFile.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export PDF: $e')));
    }
  }

  Future<void> _exportCsv(
    BuildContext context,
    List<Map<String, String>> subjects,
  ) async {
    try {
      final sb = StringBuffer();
      sb.writeln('Subject,Day,Time,Block');
      for (final s in subjects) {
        sb.writeln(
          '"${s['subject']}","${s['day']}","${s['time']}","${s['block']}"',
        );
      }
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/subject_load.csv');
      await file.writeAsString(sb.toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved CSV to ${file.path}')));
      await OpenFile.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export CSV: $e')));
    }
  }

  // Gradebook exports
  Future<void> _exportGradebookPdf(
    BuildContext context,
    List<Map<String, String>> grades,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'Grade Book',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text('Academic Year: ${_selectedAcademicYear}'),
                pw.Text('Semester: ${_selectedSemester}'),
                pw.SizedBox(height: 12),
                pw.Table.fromTextArray(
                  headers: ['Subject', 'Midterm', 'Final', 'Grade'],
                  data: grades
                      .map(
                        (g) => [
                          g['subject'],
                          g['midterm'],
                          g['final'],
                          g['grade'],
                        ],
                      )
                      .toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/grade_book.pdf');
      await file.writeAsBytes(bytes);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved PDF to ${file.path}')));
      await OpenFile.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export PDF: $e')));
    }
  }

  Future<void> _exportGradebookCsv(
    BuildContext context,
    List<Map<String, String>> grades,
  ) async {
    try {
      final sb = StringBuffer();
      sb.writeln('Academic Year:${_selectedAcademicYear}');
      sb.writeln('Semester:${_selectedSemester}');
      sb.writeln();
      sb.writeln('Subject,Midterm,Final,Grade');
      for (final g in grades) {
        sb.writeln(
          '"${g['subject']}","${g['midterm']}","${g['final']}","${g['grade']}"',
        );
      }
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/grade_book.csv');
      await file.writeAsString(sb.toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved CSV to ${file.path}')));
      await OpenFile.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export CSV: $e')));
    }
  }

  Widget _buildAssessmentPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: StudentPanelContent.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              ...[
                ('CS 101 - Data Structures', '92%', true),
                ('CS 102 - Web Development', '88%', true),
                ('CS 103 - Database Management', '85%', true),
                ('CS 104 - Software Engineering', '90%', true),
              ].map((assessment) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            assessment.$1,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            assessment.$2,
                            style: GoogleFonts.inter(
                              color: StudentPanelContent.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value:
                              double.parse(assessment.$2.replaceAll('%', '')) /
                              100,
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation(
                            StudentPanelContent.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGradeBookPanel(BuildContext context) {
    // Hardcoded grade data for now
    final grades = [
      {'subject': 'CS 101', 'midterm': '92', 'final': '92', 'grade': '92%'},
      {'subject': 'CS 102', 'midterm': '88', 'final': '88', 'grade': '88%'},
      {'subject': 'CS 103', 'midterm': '85', 'final': '85', 'grade': '85%'},
      {'subject': 'CS 104', 'midterm': '90', 'final': '90', 'grade': '90%'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Academic Year: ',
                    style: GoogleFonts.inter(color: Colors.white70),
                  ),
                  const SizedBox(width: 6),
                  DropdownButton<String>(
                    value: _selectedAcademicYear,
                    dropdownColor: StudentPanelContent.pViolet,
                    style: GoogleFonts.inter(color: Colors.white),
                    underline: Container(),
                    items: const [
                      DropdownMenuItem(
                        value: '2025-2026',
                        child: Text('2025-2026'),
                      ),
                      DropdownMenuItem(
                        value: '2024-2025',
                        child: Text('2024-2025'),
                      ),
                    ],
                    onChanged: (v) => setState(() {
                      if (v != null) _selectedAcademicYear = v;
                    }),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Semester: ',
                    style: GoogleFonts.inter(color: Colors.white70),
                  ),
                  const SizedBox(width: 6),
                  DropdownButton<String>(
                    value: _selectedSemester,
                    dropdownColor: StudentPanelContent.pViolet,
                    style: GoogleFonts.inter(color: Colors.white),
                    underline: Container(),
                    items: const [
                      DropdownMenuItem(
                        value: '1st Semester',
                        child: Text('1st Semester'),
                      ),
                      DropdownMenuItem(
                        value: '2nd Semester',
                        child: Text('2nd Semester'),
                      ),
                      DropdownMenuItem(value: 'Summer', child: Text('Summer')),
                    ],
                    onChanged: (v) => setState(() {
                      if (v != null) _selectedSemester = v;
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: StudentPanelContent.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Container()),
                  ElevatedButton.icon(
                    onPressed: () => _exportGradebookPdf(context, grades),
                    icon: const Icon(LucideIcons.fileText),
                    label: const Text('Export PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: StudentPanelContent.aViolet,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _exportGradebookCsv(context, grades),
                    icon: const Icon(LucideIcons.fileSpreadsheet),
                    label: const Text('Open in Excel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: StudentPanelContent.aViolet,
                      side: BorderSide(
                        color: StudentPanelContent.aViolet.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Table(
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                  3: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: StudentPanelContent.aViolet.withOpacity(0.1),
                    ),
                    children: [
                      _tableHeader('Subject'),
                      _tableHeader('Midterm'),
                      _tableHeader('Final'),
                      _tableHeader('Grade'),
                    ],
                  ),
                  ...grades.map((g) {
                    return TableRow(
                      children: [
                        _tableCell(g['subject']!),
                        _tableCell(g['midterm']!),
                        _tableCell(g['final']!),
                        _tableCell(g['grade']!),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClearancePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: StudentPanelContent.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              ...[
                ('Library Clearance', true),
                ('Financial Clearance', true),
                ('Registrar Clearance', false),
                ('Faculty Clearance', true),
              ].map((clearance) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          (clearance.$2
                                  ? StudentPanelContent.success
                                  : StudentPanelContent.aViolet)
                              .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            (clearance.$2
                                    ? StudentPanelContent.success
                                    : StudentPanelContent.aViolet)
                                .withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          clearance.$1,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(
                          clearance.$2
                              ? LucideIcons.checkCircle2
                              : LucideIcons.clock,
                          color: clearance.$2
                              ? StudentPanelContent.success
                              : StudentPanelContent.aViolet,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: StudentPanelContent.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Center(
        child: Text(
          'Panel not implemented yet',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _tableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(text, style: GoogleFonts.inter(color: Colors.white70)),
    );
  }
}

/// Rich profile panel with background and profile picture picker.
class ProfilePanel extends StatefulWidget {
  const ProfilePanel({super.key});

  @override
  State<ProfilePanel> createState() => _ProfilePanelState();
}

class _ProfilePanelState extends State<ProfilePanel> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: const Text('Camera'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the static colors from StudentPanelContent
    final pViolet = StudentPanelContent.pViolet;
    final aViolet = StudentPanelContent.aViolet;

    return Center(
      child: Container(
        width: 460,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [pViolet.withOpacity(0.95), aViolet.withOpacity(0.95)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Decorative background circle
                Positioned(
                  top: -40,
                  child: Container(
                    width: 220,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [Colors.white10, Colors.transparent],
                        radius: 0.9,
                      ),
                      borderRadius: BorderRadius.circular(80),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.white24,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : null,
                    child: _imageFile == null
                        ? Text(
                            'DA',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'DARLENE ANGEL',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            _infoRow('Student ID', '2024-00001'),
            _infoRow('Email', 'darlene.angel@student.edu'),
            _infoRow('Program', 'Bachelor of Science in Computer Science'),
            _infoRow('Year Level', '2nd Year'),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(LucideIcons.camera),
              label: const Text('Change Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: pViolet,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 6),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Payment Upload panel: pick image and send (simulated upload).
class PaymentUploadPanel extends StatefulWidget {
  const PaymentUploadPanel({super.key});

  @override
  State<PaymentUploadPanel> createState() => _PaymentUploadPanelState();
}

class _PaymentUploadPanelState extends State<PaymentUploadPanel> {
  File? _selectedFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSending = false;

  Future<void> _pickSlip() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: const Text('Camera'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;
    final XFile? xfile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (xfile != null) setState(() => _selectedFile = File(xfile.path));
  }

  Future<void> _sendSlip() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a deposit slip first.')),
      );
      return;
    }
    setState(() => _isSending = true);

    // Simulate upload delay. Replace with your API upload logic.
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isSending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deposit slip uploaded successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = StudentPanelContent.surface;
    final aViolet = StudentPanelContent.aViolet;
    final success = StudentPanelContent.success;
    final pViolet = StudentPanelContent.pViolet;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 720),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Upload Deposit Slip',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select your deposit slip image and press Send.',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            const SizedBox(height: 18),
            if (_selectedFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedFile!,
                  height: 260,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 260,
                decoration: BoxDecoration(
                  color: aViolet.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: aViolet.withOpacity(0.12)),
                ),
                child: Center(
                  child: Text(
                    'No file selected',
                    style: GoogleFonts.inter(color: Colors.white70),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickSlip,
                  icon: const Icon(LucideIcons.upload),
                  label: const Text('Choose Image'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: aViolet.withOpacity(0.18)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendSlip,
                  icon: _isSending
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.send),
                  label: Text(_isSending ? 'Sending...' : 'Send'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: success,
                    foregroundColor: pViolet,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
