import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class TeachingLoadPanel extends StatefulWidget {
  final bool isDarkMode;
  const TeachingLoadPanel({super.key, required this.isDarkMode});

  @override
  State<TeachingLoadPanel> createState() => _TeachingLoadPanelState();
}

class _TeachingLoadPanelState extends State<TeachingLoadPanel> {
  // Modern Tonal Palette Constants
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);
  static const Color success = Color(0xFF69F0AE);

  // --- MOCK TEACHING LOAD DATA ---
  final List<Map<String, dynamic>> _teachingLoad = [
    {
      "code": "ITCC 321",
      "title": "Systems Integration & Architecture",
      "section": "BSIT-3A",
      "schedule": "Mon/Wed 08:00 AM - 09:30 AM",
      "units": 3.0,
      "room": "CL 102",
      "students": 32,
    },
    {
      "code": "ITCC 411",
      "title": "Information Assurance & Security",
      "section": "BSCS-4B",
      "schedule": "Tue/Thu 10:30 AM - 12:00 PM",
      "units": 3.0,
      "room": "CL 105",
      "students": 28,
    },
    {
      "code": "NET 102",
      "title": "Fundamentals of Networking",
      "section": "BSCpE-1A",
      "schedule": "Fri 01:00 PM - 04:00 PM",
      "units": 3.0,
      "room": "LAB 4",
      "students": 45,
    },
    {
      "code": "PROG 101",
      "title": "Introduction to Programming",
      "section": "BSIT-1C",
      "schedule": "Sat 08:00 AM - 11:00 AM",
      "units": 3.0,
      "room": "CL 101",
      "students": 50,
    },
  ];

  // --- PDF GENERATION: TEACHING LOAD ---
  Future<void> _generateTeachingLoadPDF() async {
    final pdf = pw.Document();
    final timestamp = DateTime.now().toString().split('.')[0];

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
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  "OFFICE OF THE VICE PRESIDENT FOR ACADEMICS",
                  style: pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(
                "OFFICIAL FACULTY TEACHING LOAD",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text("Professor: PROF. ROBERTO MANALASTAS"),
              pw.Text("Semester: 2nd Semester SY 2025-2026"),
              pw.SizedBox(height: 30),
              pw.Table.fromTextArray(
                headers: [
                  "Code",
                  "Description",
                  "Units",
                  "Section",
                  "Schedule/Room",
                ],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                data: _teachingLoad
                    .map(
                      (l) => [
                        l['code'],
                        l['title'],
                        l['units'].toString(),
                        l['section'],
                        "${l['schedule']} (${l['room']})",
                      ],
                    )
                    .toList(),
              ),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "Generated on $timestamp",
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                  ),
                  pw.Text(
                    "Verified by Program Chair Signature",
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/Faculty_Load_Manalastas.pdf");
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      _showSnackBar("Error generating Load PDF: $e");
    }
  }

  // --- PDF GENERATION: CLASS ROSTER ---
  Future<void> _generateRosterPDF(Map<String, dynamic> load) async {
    final pdf = pw.Document();

    // Mock Student List for Roster
    final List<List<String>> mockStudents = [
      ["2024-00001", "ANGEL, DARLENE", "Regular"],
      ["2024-00005", "CHEN, MICHAEL", "Regular"],
      ["2024-00012", "JENKINS, SARAH", "Irregular"],
      ["2024-00155", "DELA CRUZ, JUAN", "Regular"],
      ["2024-00160", "SANTOS, MARIA", "Regular"],
    ];

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
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  "CLASS ROSTER - OFFICIAL COPY",
                  style: pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Subject: ${load['code']} - ${load['title']}",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text("Section: ${load['section']}"),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("Professor: PROF. MANALASTAS"),
                      pw.Text("Total Students: ${load['students']}"),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: [
                  "Student ID",
                  "Full Name",
                  "Standing",
                  "Attendance Log (Remarks)",
                ],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                data: mockStudents.map((s) => [s[0], s[1], s[2], ""]).toList(),
              ),
              pw.Spacer(),
              pw.Text(
                "Note: This roster is synchronized with the Registrar's Database.",
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        "${dir.path}/Roster_${load['section']}_${load['code']}.pdf",
      );
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
            Text(
              "Faculty Teaching Load",
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: text,
                letterSpacing: -1,
              ),
            ),
            Row(
              children: [
                const Text(
                  "Active Semester: 2nd Semester SY 2025-2026",
                  style: TextStyle(color: Colors.blueGrey, fontSize: 14),
                ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadList(Color bg, Color text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "ASSIGNED SUBJECTS",
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: aViolet,
            letterSpacing: 1.5,
          ),
        ),
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
    Map<String, dynamic> load,
    Color bg,
    Color text,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDarkMode ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(LucideIcons.book, color: aViolet, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      load['code'],
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        color: aViolet,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      load['title'],
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: text,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${load['section']} • ${load['room']}",
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    load['schedule'],
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: text,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${load['units']} Units • ${load['students']} Students",
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 40, color: Colors.white10),
          Row(
            children: [
              _loadActionButton(LucideIcons.uploadCloud, "Upload Syllabus", () {
                _showSnackBar("Syllabus upload initiated for ${load['code']}");
              }),
              const SizedBox(width: 12),
              _loadActionButton(
                LucideIcons.clipboardList,
                "Download Roster",
                () {
                  _generateRosterPDF(load);
                },
              ),
              const SizedBox(width: 12),
              _loadActionButton(LucideIcons.megaphone, "Post Notice", () {
                _showSnackBar("Notice composer opened for ${load['title']}");
              }),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  _showSnackBar("Navigating to roster: ${load['section']}");
                },
                icon: const Icon(LucideIcons.users, size: 14),
                label: const Text(
                  "VIEW ROSTER",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: aViolet.withOpacity(0.1),
                  foregroundColor: aViolet,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- UI HELPERS ---

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
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.blueGrey),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String t, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        t,
        style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w900),
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: pViolet,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
