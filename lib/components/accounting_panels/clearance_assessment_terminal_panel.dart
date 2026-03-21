import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file_plus/open_file_plus.dart';
import '../../services/supabase_service.dart';

class ClearanceAssessmentTerminal extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const ClearanceAssessmentTerminal({
    super.key,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  State<ClearanceAssessmentTerminal> createState() =>
      _ClearanceAssessmentTerminalState();
}

class _ClearanceAssessmentTerminalState
    extends State<ClearanceAssessmentTerminal> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _activeStudent;
  List<Map<String, dynamic>> _studentLoad = [];

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF0F071D);

  /// SEARCH: Resolves student academic load and balance for assessment
  Future<void> _fetchStudentAssessment() async {
    final term = _searchController.text.trim();
    if (term.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      // 1. Fetch Profile and current balance
      final student = await _service.client
          .from('profiles')
          .select('*, student_details(*, courses(name))')
          .eq('role', 'student')
          .ilike('user_id_number', term)
          .maybeSingle();

      if (student == null) {
        _showToast(
            "Identity not found in student records.", Colors.orangeAccent);
        setState(() => _isLoading = false);
        return;
      }

      // 2. Fetch academic load (subjects) to compute assessment breakdown
      final load = await _service.client
          .from('study_loads')
          .select('*, subjects(*)')
          .eq('student_id', student['id']);

      setState(() {
        _activeStudent = student;
        _studentLoad = List<Map<String, dynamic>>.from(load);
        _isLoading = false;
      });
    } catch (e) {
      _showToast("Database Sync Error: $e", Colors.redAccent);
      setState(() => _isLoading = false);
    }
  }

  /// PDF ENGINE: Generates a formal Statement of Account (SOA)
  Future<void> _generateSOA() async {
    if (_activeStudent == null) return;

    final pdf = pw.Document();
    final d = _activeStudent!['student_details'];
    final double balance = (d['account_balance'] ?? 0.0).toDouble();

    pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                      child: pw.Text("BRIGHT FUTURE ACADEMY",
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 16))),
                  pw.Center(
                      child: pw.Text("OFFICE OF THE COMPTROLLER",
                          style: const pw.TextStyle(fontSize: 10))),
                  pw.Center(
                      child: pw.Text("STATEMENT OF ACCOUNT",
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 12))),
                  pw.SizedBox(height: 30),
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                  "STUDENT: ${_activeStudent!['fn']} ${_activeStudent!['ln']}"
                                      .toUpperCase(),
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold)),
                              pw.Text(
                                  "ID NO: ${_activeStudent!['user_id_number']}"),
                              pw.Text(
                                  "COURSE: ${d['courses']?['name'] ?? 'N/A'}"),
                            ]),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                  "DATE: ${DateFormat('MM/dd/yyyy').format(DateTime.now())}"),
                              pw.Text(
                                  "STATUS: ${balance > 0 ? 'UNCLEARED' : 'CLEARED'}",
                                  style: pw.TextStyle(
                                      color: balance > 0
                                          ? PdfColors.red
                                          : PdfColors.green)),
                            ])
                      ]),
                  pw.SizedBox(height: 20),
                  pw.Divider(),
                  pw.Text("ACADEMIC LOAD ASSESSMENT",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.SizedBox(height: 10),
                  pw.TableHelper.fromTextArray(
                    headers: ['SUBJECT CODE', 'UNITS', 'LAB FEE', 'TOTAL'],
                    data: _studentLoad
                        .map((l) => [
                              l['subjects']['code'],
                              l['subjects']['units'].toString(),
                              "₱${l['subjects']['lab_fee'] ?? 0.0}",
                              "₱${(l['subjects']['units'] * 500) + (l['subjects']['lab_fee'] ?? 0.0)}" // Mock calc
                            ])
                        .toList(),
                    headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 9),
                    cellStyle: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.SizedBox(height: 30),
                  pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Container(
                          width: 250,
                          padding: const pw.EdgeInsets.all(10),
                          decoration:
                              pw.BoxDecoration(border: pw.Border.all(width: 1)),
                          child: pw.Column(children: [
                            _soaLine("TOTAL ASSESSMENT:",
                                25000.00), // Placeholder logic
                            _soaLine("TOTAL PAYMENTS:", 25000.00 - balance),
                            pw.Divider(),
                            _soaLine("OUTSTANDING BALANCE:", balance,
                                isBold: true),
                          ]))),
                  pw.Spacer(),
                  pw.Text(
                      "NOTE: This is a formal assessment. Surcharges may apply for late payments.",
                      style: pw.TextStyle(
                          // Removed 'const' keyword
                          fontSize: 8,
                          fontStyle: pw.FontStyle.italic)),
                  pw.SizedBox(height: 20),
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(children: [
                          pw.Container(
                              width: 150,
                              decoration: const pw.BoxDecoration(
                                  border:
                                      pw.Border(top: pw.BorderSide(width: 1)))),
                          pw.Text("Accounting Staff",
                              style: const pw.TextStyle(fontSize: 8)),
                        ]),
                        pw.Column(children: [
                          pw.Container(
                              width: 150,
                              decoration: const pw.BoxDecoration(
                                  border:
                                      pw.Border(top: pw.BorderSide(width: 1)))),
                          pw.Text("University Registrar",
                              style: const pw.TextStyle(fontSize: 8)),
                        ])
                      ])
                ]))));

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final path = "${dir.path}/SOA_${_activeStudent!['user_id_number']}.pdf";
    final file = File(path);
    await file
        .writeAsBytes(bytes); // Changed from OpenFilePlus.open to OpenFile.open
    await OpenFile.open(path);
  }

  pw.Widget _soaLine(String label, double val, {bool isBold = false}) =>
      pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(label,
                    style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: isBold
                            ? pw.FontWeight.bold
                            : pw.FontWeight.normal)),
                pw.Text("PHP ${NumberFormat('#,###.00').format(val)}",
                    style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: isBold
                            ? pw.FontWeight.bold
                            : pw.FontWeight.normal)),
              ]));

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF1E1B4B);
    final cardColor =
        widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 32),
          _buildTerminalControls(cardColor, textColor),
          const SizedBox(height: 24),
          if (_activeStudent != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    flex: 3, child: _buildAssessmentGrid(cardColor, textColor)),
                const SizedBox(width: 24),
                Expanded(
                    flex: 2,
                    child: _buildClearanceWidget(cardColor, textColor)),
              ],
            )
          else
            _buildWelcomeState(textColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color textColor) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Billing & Clearance Terminal",
              style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: -1)),
          const Text(
              "Formal assessment generation and final institutional clearance auditing.",
              style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
        ],
      );

  Widget _buildTerminalControls(Color cardColor, Color textColor) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: widget.isDarkMode ? Colors.white10 : Colors.black12)),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(LucideIcons.fingerprint, color: aViolet, size: 24),
            const SizedBox(width: 16),
            Expanded(
                child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _fetchStudentAssessment(),
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                  hintText: "Enter Student ID for Billing Audit...",
                  border: InputBorder.none),
            )),
            ElevatedButton.icon(
              onPressed: _fetchStudentAssessment,
              icon: _isLoading
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(LucideIcons.search, size: 18),
              label: const Text("AUDIT ACCOUNT"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: aViolet,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18)),
            ),
          ],
        ),
      );

  Widget _buildAssessmentGrid(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("OFFICIAL STUDY LOAD",
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: aViolet,
                      letterSpacing: 1.5)),
              Text("${_studentLoad.length} ENROLLED SUBJECTS",
                  style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _studentLoad.length,
            itemBuilder: (context, i) {
              final item = _studentLoad[i];
              final sub = item['subjects'];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: widget.isDarkMode
                        ? Colors.white.withOpacity(0.03)
                        : Colors.black.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Container(
                        width: 60,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: aViolet.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(sub['units'].toString(),
                            style: const TextStyle(
                                color: aViolet, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(sub['name'],
                              style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                          Text(sub['code'],
                              style: const TextStyle(
                                  color: Colors.blueGrey, fontSize: 11)),
                        ])),
                    Text("₱${(sub['units'] * 500.0).toStringAsFixed(2)}",
                        style: GoogleFonts.orbitron(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClearanceWidget(Color cardColor, Color textColor) {
    final d = _activeStudent!['student_details'];
    final double balance = (d['account_balance'] ?? 0.0).toDouble();
    final bool isCleared = balance <= 0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: isCleared
                    ? [const Color(0xFF065F46), const Color(0xFF064E3B)]
                    : [const Color(0xFF7F1D1D), const Color(0xFF450A0A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            children: [
              Icon(
                  isCleared ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
                  color: Colors.white,
                  size: 48),
              const SizedBox(height: 16),
              Text(isCleared ? "FINANCIALLY CLEARED" : "CLEARANCE ON HOLD",
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                  isCleared
                      ? "Student is eligible for exams and credentials."
                      : "Outstanding balance must be settled.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 12)),
              const Divider(height: 40, color: Colors.white24),
              Text("₱${NumberFormat('#,###.00').format(balance)}",
                  style: GoogleFonts.orbitron(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              const Text("REMAINING ACCOUNTABILITY",
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: widget.isDarkMode ? Colors.white10 : Colors.black12)),
          child: Column(
            children: [
              _actionTile("Generate Statement (SOA)", LucideIcons.fileText,
                  _generateSOA),
              _actionTile("Email Billing Reminder", LucideIcons.mail,
                  () => _showToast("Reminder Sent.", success)),
              _actionTile("Verify Promissory Note", LucideIcons.fileSignature,
                  () => {}),
            ],
          ),
        )
      ],
    );
  }

  Widget _actionTile(String title, IconData icon, VoidCallback onTap) =>
      ListTile(
        onTap: onTap,
        leading: Icon(icon, color: aViolet, size: 20),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        trailing: const Icon(LucideIcons.chevronRight,
            size: 16, color: Colors.blueGrey),
      );

  Widget _buildWelcomeState(Color textColor) => Center(
        child: Column(children: [
          const SizedBox(height: 100),
          Icon(LucideIcons.calculator,
              size: 64, color: Colors.blueGrey.withOpacity(0.1)),
          const SizedBox(height: 24),
          Text("Billing Terminal Idle",
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey)),
          const Text("Search a Student ID to perform a full billing audit.",
              style: TextStyle(color: Colors.blueGrey)),
        ]),
      );

  void _showToast(String m, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m),
          backgroundColor: c,
          behavior: SnackBarBehavior.floating));
}
