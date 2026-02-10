import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class DocumentVerificationPanel extends StatefulWidget {
  final bool isDarkMode;
  const DocumentVerificationPanel({super.key, required this.isDarkMode});

  @override
  State<DocumentVerificationPanel> createState() =>
      _DocumentVerificationPanelState();
}

class _DocumentVerificationPanelState extends State<DocumentVerificationPanel> {
  // Modern Tonal Palette
  static const Color pViolet = Color(0xFF2E1065);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color success = Color(0xFF69F0AE);

  // --- INTERNAL STATE ---
  final List<Map<String, dynamic>> _queue = [
    {
      "name": "MICHAEL CHEN",
      "id": "APL-2026-004",
      "course": "BS Information Technology",
      "isApproved": false,
      "docs": [
        {"name": "PSA Birth Certificate", "status": true},
        {"name": "Form 138 (Report Card)", "status": true},
        {"name": "Certificate of Good Moral", "status": true},
        {"name": "Medical Certificate", "status": false},
        {"name": "Entrance Exam Results", "status": true},
      ],
    },
    {
      "name": "SARAH JENKINS",
      "id": "APL-2026-001",
      "course": "BS Computer Science",
      "isApproved": false,
      "docs": [
        {"name": "PSA Birth Certificate", "status": true},
        {"name": "Form 138 (Report Card)", "status": false},
        {"name": "Certificate of Good Moral", "status": false},
        {"name": "Medical Certificate", "status": false},
        {"name": "Entrance Exam Results", "status": true},
      ],
    },
  ];

  // Transaction History List (Archived)
  final List<Map<String, dynamic>> _history = [];

  // Logic to calculate progress percentage
  double _calculateProgress(List<dynamic> docs) {
    int verified = docs.where((d) => d['status'] == true).length;
    return verified / docs.length;
  }

  // --- ACTIONS ---

  void _toggleDoc(int studentIndex, int docIndex) {
    setState(() {
      _queue[studentIndex]['docs'][docIndex]['status'] =
          !_queue[studentIndex]['docs'][docIndex]['status'];
    });
  }

  Future<void> _finalizeAndTransfer(
    int index, {
    bool isHistoryItem = false,
  }) async {
    final student = isHistoryItem ? _history[index] : _queue[index];

    // 1. Generate PDF
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(30),
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
                    "OFFICE OF ADMISSIONS",
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 20),
                pw.Text(
                  "OFFICIAL ADMISSION SLIP",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text("Student Name: ${student['name']}"),
                pw.Text("Application ID: ${student['id']}"),
                pw.Text("Course/Program: ${student['course']}"),
                pw.SizedBox(height: 30),
                pw.Text(
                  "DOCUMENTATION STATUS: CLEARANCE OBTAINED",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  "The applicant has successfully submitted and verified the following requirements:",
                ),
                pw.SizedBox(height: 10),
                ...student['docs']
                    .where((d) => d['status'] == true)
                    .map((doc) => pw.Bullet(text: doc['name'])),
                pw.Spacer(),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "Issued by: ADMISSIONS_OFFICER",
                          style: pw.TextStyle(fontSize: 8),
                        ),
                        pw.Text(
                          "Date: ${DateTime.now().toString().split(' ')[0]}",
                          style: pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                    pw.Text(
                      "System Verified Copy",
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/Admission_Slip_${student['id']}.pdf");
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);

      if (!isHistoryItem) {
        // 2. Perform Transfer to History
        setState(() {
          final completedStudent = _queue.removeAt(index);
          completedStudent['isApproved'] = true;
          completedStudent['transferDate'] = DateTime.now().toString().split(
            '.',
          )[0];
          _history.insert(0, completedStudent);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: success,
            content: Text(
              "Admissions Package Generated for ${student['name']}. Moved to Transaction History.",
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Error processing document: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode ? Colors.white : pViolet;
    final Color cardColor = widget.isDarkMode ? surfaceDark : Colors.white;
    final Color subTextColor = widget.isDarkMode
        ? Colors.white54
        : Colors.blueGrey;

    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(textColor),
            const SizedBox(height: 24),
            _buildTabBar(textColor),
            const SizedBox(height: 32),
            Expanded(
              child: TabBarView(
                children: [
                  // TAB 1: ACTIVE QUEUE
                  _queue.isEmpty
                      ? _buildEmptyState(
                          "No active applicants in queue.",
                          subTextColor,
                        )
                      : ListView.builder(
                          itemCount: _queue.length,
                          itemBuilder: (context, index) {
                            final student = _queue[index];
                            final progress = _calculateProgress(
                              student['docs'],
                            );
                            return _buildVerificationCard(
                              index,
                              student,
                              progress,
                              cardColor,
                              textColor,
                              subTextColor,
                              false,
                            );
                          },
                        ),
                  // TAB 2: TRANSACTION HISTORY
                  _history.isEmpty
                      ? _buildEmptyState(
                          "No completed transactions yet.",
                          subTextColor,
                        )
                      : ListView.builder(
                          itemCount: _history.length,
                          itemBuilder: (context, index) {
                            final student = _history[index];
                            final progress = _calculateProgress(
                              student['docs'],
                            );
                            return _buildVerificationCard(
                              index,
                              student,
                              progress,
                              cardColor,
                              textColor,
                              subTextColor,
                              true,
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Document Verification Pipeline",
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: textColor,
            letterSpacing: -1,
          ),
        ),
        const Text(
          "Verify requirements and archive cleared applicants into the system ledger.",
          style: TextStyle(color: Colors.blueGrey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTabBar(Color textColor) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: aViolet,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.blueGrey,
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: "VERIFICATION QUEUE"),
          Tab(text: "TRANSACTION HISTORY"),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, Color subTextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.inbox,
            size: 48,
            color: subTextColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: subTextColor)),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(
    int sIndex,
    Map<String, dynamic> student,
    double progress,
    Color cardColor,
    Color textColor,
    Color subTextColor,
    bool isHistory,
  ) {
    bool isComplete = progress == 1.0;
    bool isApproved = student['isApproved'];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          leading: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                backgroundColor: widget.isDarkMode
                    ? Colors.white10
                    : Colors.grey[200],
                color: isComplete ? success : aViolet,
                strokeWidth: 6,
              ),
              if (isComplete)
                const Icon(LucideIcons.check, size: 16, color: success),
            ],
          ),
          title: Text(
            student['name'],
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              color: textColor,
              fontSize: 18,
            ),
          ),
          subtitle: Text(
            "${student['id']} • ${student['course']}",
            style: TextStyle(color: subTextColor, fontSize: 12),
          ),
          trailing: isHistory
              ? _badge("ARCHIVED", success)
              : (isComplete
                    ? _badge("READY", aViolet)
                    : _badge(
                        "${(progress * 100).toInt()}% COMPLETE",
                        Colors.blueGrey,
                      )),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 32, color: Colors.white10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "REQUIREMENT CHECKLIST",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.blueGrey,
                          letterSpacing: 1,
                        ),
                      ),
                      if (isHistory)
                        Text(
                          "Transferred: ${student['transferDate']}",
                          style: const TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(student['docs'].length, (dIndex) {
                    final doc = student['docs'][dIndex];
                    return _buildDocToggle(
                      sIndex,
                      dIndex,
                      doc,
                      textColor,
                      isHistory,
                    );
                  }),
                  const SizedBox(height: 32),
                  if (isComplete && !isApproved && !isHistory)
                    _buildApprovalAction(sIndex),
                  if (isHistory) _buildPostApprovalUI(sIndex),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocToggle(
    int sIndex,
    int dIndex,
    Map<String, dynamic> doc,
    Color textColor,
    bool isHistory,
  ) {
    bool isVerified = doc['status'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: isHistory ? null : () => _toggleDoc(sIndex, dIndex),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isVerified ? success.withOpacity(0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isVerified ? success.withOpacity(0.2) : Colors.white10,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isVerified ? LucideIcons.checkCircle : LucideIcons.circle,
                color: isVerified ? success : Colors.blueGrey,
                size: 20,
              ),
              const SizedBox(width: 16),
              Text(
                doc['name'],
                style: TextStyle(
                  color: isVerified ? textColor : Colors.blueGrey,
                  fontWeight: isVerified ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const Spacer(),
              Text(
                isVerified ? "VERIFIED" : "PENDING",
                style: TextStyle(
                  color: isVerified ? success : Colors.blueGrey,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalAction(int index) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: aViolet.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: aViolet.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.shieldCheck, color: aViolet, size: 32),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Verification Finalized",
                  style: TextStyle(fontWeight: FontWeight.bold, color: aViolet),
                ),
                Text(
                  "Process transfer to move this record to the system history.",
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _finalizeAndTransfer(index),
            icon: const Icon(LucideIcons.database, size: 18),
            label: const Text("TRANSFER & ARCHIVE"),
            style: ElevatedButton.styleFrom(
              backgroundColor: aViolet,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostApprovalUI(int index) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.history, color: success, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "TRANSACTION LOGGED IN REGISTRAR SYSTEM",
              style: TextStyle(
                color: success,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => _finalizeAndTransfer(index, isHistoryItem: true),
            icon: const Icon(LucideIcons.printer, size: 14, color: success),
            label: const Text(
              "RE-PRINT SLIP",
              style: TextStyle(
                color: success,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
