import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
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

  // --- DATABASE-BACKED RECONCILIATION STATE (NEW) ---
  Map<String, dynamic>? _billingRecord;
  Map<String, dynamic>? _billingBreakdown;
  double _totalAssessment = 0.0;
  double _totalPayments = 0.0;
  double _accountBalance = 0.0;

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF0F071D);

  @override
  void initState() {
    super.initState();
  }

  /// 🛰️ DATABASE: Resolves actual student academic load, payment history, and balances
  Future<void> _fetchStudentAssessment() async {
    final term = _searchController.text.trim();
    if (term.isEmpty) return;

    setState(() {
      _isLoading = true;
      _activeStudent = null;
      _studentLoad = [];
      _billingRecord = null;
      _billingBreakdown = null;
      _totalAssessment = 0.0;
      _totalPayments = 0.0;
      _accountBalance = 0.0;
    });

    try {
      // 1. Fetch Profile and current active details
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

      // 2. Fetch academic load (subjects) assigned to this student
      final load = await _service.client
          .from('study_loads')
          .select('*, subjects(*)')
          .eq('student_id', student['id']);

      // 3. Fetch released Billing assessment record issued by Accounting
      final billing = await _service.client
          .from('payments')
          .select()
          .eq('student_id', student['id'])
          .eq('payment_type', 'Enrollment Assessment')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      // 4. Fetch all payment transactions to dynamically calculate total paid amount
      final paymentsList = await _service.client
          .from('payments')
          .select()
          .eq('student_id', student['id']);

      double totalPaid = 0.0;
      if (paymentsList != null) {
        for (var p in paymentsList) {
          // Exclude the initial unpaid "billing assessment" itself when summing up transactions
          if (p['payment_type'] != 'Enrollment Assessment') {
            totalPaid +=
                double.tryParse(p['amount_paid']?.toString() ?? "0.0") ?? 0.0;
          }
        }
      }

      double totalAssessed = 0.0;
      Map<String, dynamic>? decodedBreakdown;
      if (billing != null) {
        totalAssessed =
            double.tryParse(billing['amount']?.toString() ?? "0.0") ?? 0.0;
        if (billing['remarks'] != null) {
          try {
            decodedBreakdown = jsonDecode(billing['remarks']);
          } catch (_) {
            debugPrint(
                "⚠️ Remarks parsing failed or contains plaintext remarks.");
          }
        }
      }

      final d = student['student_details'];
      double currentBalance =
          double.tryParse(d?['account_balance']?.toString() ?? "0.0") ?? 0.0;

      setState(() {
        _activeStudent = student;
        _studentLoad = List<Map<String, dynamic>>.from(load);
        _billingRecord = billing;
        _billingBreakdown = decodedBreakdown;
        _totalAssessment = totalAssessed;
        _totalPayments = totalPaid;
        _accountBalance = currentBalance;
        _isLoading = false;
      });
    } catch (e) {
      _showToast("Database Sync Error: $e", Colors.redAccent);
      setState(() => _isLoading = false);
    }
  }

  /// 🛰️ EDGE FUNCTION TRANSACTION ENGINE
  /// Invokes centralized SMTP gateway to dispatch detailed assessment statement to student's email
  Future<void> _sendBillingReminderEmail() async {
    if (_activeStudent == null) return;

    final String recipientEmail =
        _activeStudent!['email'] ?? 'lustredarlene45@gmail.com';
    final String studentName =
        "${_activeStudent!['fn'] ?? ''} ${_activeStudent!['ln'] ?? ''}";

    setState(() => _isLoading = true);

    try {
      double totalUnitsCount = _studentLoad.fold(
          0.0,
          (sum, l) =>
              sum +
              (double.tryParse(l['subjects']['units']?.toString() ?? "0.0") ??
                  0.0));

      // Compile detailed items of study load
      final List<String> loadedSubjectStrings = _studentLoad.map((s) {
        final sub = s['subjects'];
        return "${sub['code']} - ${sub['name']} (${s['section_block'] ?? 'TBA'} | Rm: ${s['room_number'] ?? 'TBA'} | Schedule: ${s['day_schedule'] ?? 'TBA'} ${s['time_start'] ?? ''}-${s['time_end'] ?? ''})";
      }).toList();

      debugPrint(
          "📧 UEMSSP Core: Invoking billing reminder gateway for $recipientEmail...");

      // Call Supabase Edge Function to send email
      final response = await _service.client.functions.invoke(
        'send-otp',
        body: {
          'type': 'assessment_billing', // Reuses professional invoice template
          'toEmail': recipientEmail,
          'name': studentName,
          'totalUnits': totalUnitsCount.toStringAsFixed(1),
          'tuitionFee':
              "₱${NumberFormat('#,##0.00').format(_totalAssessment - _totalPayments)}",
          'labFee': "₱0.00",
          'totalNetFees':
              "₱${NumberFormat('#,##0.00').format(_accountBalance)}",
          'documents': loadedSubjectStrings,
        },
      );

      if (response.status == 200) {
        _showToast("Billing reminder email dispatched successfully.", success);
      } else {
        _showToast("Failed to dispatch billing reminder.", Colors.redAccent);
      }
    } catch (e) {
      _showToast("SMTP Connection Error: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// PDF ENGINE: Generates a formal Statement of Account (SOA) using correct database values
  Future<void> _generateSOA() async {
    if (_activeStudent == null) return;

    final pdf = pw.Document();
    final d = _activeStudent!['student_details'];

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
                                  "STATUS: ${_accountBalance > 0 ? 'UNCLEARED' : 'CLEARED'}",
                                  style: pw.TextStyle(
                                      color: _accountBalance > 0
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

                  // FIXED COMPILATION BUG: pw.TableHelper is replaced with pw.Table.fromTextArray
                  pw.Table.fromTextArray(
                    headers: [
                      'SUBJECT CODE',
                      'DESCRIPTION',
                      'ROOM',
                      'DAYS/TIME'
                    ],
                    data: _studentLoad
                        .map((l) => [
                              l['subjects']['code'] ?? 'N/A',
                              l['subjects']['name'] ?? 'N/A',
                              l['room_number'] ?? 'TBA',
                              "${l['day_schedule'] ?? 'TBA'} ${l['time_start'] ?? ''}-${l['time_end'] ?? ''}"
                            ])
                        .toList(),
                    headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 9),
                    cellStyle: const pw.TextStyle(fontSize: 8),
                    cellPadding: const pw.EdgeInsets.all(6),
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
                            _soaLine("TOTAL ASSESSMENT:", _totalAssessment),
                            _soaLine("TOTAL PAYMENTS:", _totalPayments),
                            pw.Divider(),
                            _soaLine("OUTSTANDING BALANCE:", _accountBalance,
                                isBold: true),
                          ]))),
                  pw.Spacer(),
                  pw.Text(
                      "NOTE: This is a formal statement of account. Surcharges may apply for late payments under institutional terms.",
                      style: pw.TextStyle(
                          fontSize: 8, fontStyle: pw.FontStyle.italic)),
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
    await file.writeAsBytes(bytes);
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
      physics: const BouncingScrollPhysics(),
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
          // UI REFINEMENT: Scaled up Header fonts for clear structure
          Text("Billing & Clearance Terminal",
              style: GoogleFonts.inter(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: -1.2)),
          const SizedBox(height: 4),
          const Text(
              "Formal assessment generation and final institutional clearance auditing.",
              style: TextStyle(color: Colors.blueGrey, fontSize: 16)),
        ],
      );

  Widget _buildTerminalControls(Color cardColor, Color textColor) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: widget.isDarkMode ? Colors.white10 : Colors.black12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(widget.isDarkMode ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.fingerprint_rounded, color: aViolet, size: 28),
            const SizedBox(width: 16),
            Expanded(
                child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _fetchStudentAssessment(),
              style: TextStyle(
                  color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
              decoration: const InputDecoration(
                  hintText: "Enter Student ID for Billing Audit...",
                  hintStyle: TextStyle(color: Colors.blueGrey, fontSize: 16),
                  border: InputBorder.none),
            )),
            ElevatedButton.icon(
              onPressed: _fetchStudentAssessment,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.search_rounded, size: 20),
              label: const Text("AUDIT ACCOUNT",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: aViolet,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20)),
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
          border: Border.all(
              color: widget.isDarkMode ? Colors.white10 : Colors.black12)),
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
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          _studentLoad.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                        "No courses loaded or registered for this term.",
                        style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 14,
                            fontStyle: FontStyle.italic)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _studentLoad.length,
                  itemBuilder: (context, i) {
                    final item = _studentLoad[i];
                    final sub = item['subjects'];
                    final double units =
                        double.tryParse(sub?['units']?.toString() ?? "0") ??
                            0.0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                          color: widget.isDarkMode
                              ? Colors.white.withOpacity(0.03)
                              : Colors.black.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: widget.isDarkMode
                                  ? Colors.white10
                                  : Colors.black.withOpacity(0.05))),
                      child: Row(
                        children: [
                          Container(
                              width: 60,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: aViolet.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(units.toStringAsFixed(1),
                                  style: const TextStyle(
                                      color: aViolet,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      fontFamily: 'monospace'))),
                          const SizedBox(width: 16),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(sub['name'] ?? 'N/A',
                                    style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(sub['code'] ?? 'N/A',
                                    style: const TextStyle(
                                        color: Colors.blueGrey,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500)),
                              ])),
                          Text(
                              "₱${NumberFormat('#,##0.00').format(units * 1550.0)}",
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontFamily: 'monospace')),
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
    final bool isCleared = _accountBalance <= 0;

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
              boxShadow: [
                BoxShadow(
                    color: (isCleared ? Colors.green : Colors.red)
                        .withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 6)),
              ]),
          child: Column(
            children: [
              Icon(
                  isCleared
                      ? Icons.verified_user_rounded
                      : Icons.gpp_maybe_rounded,
                  color: Colors.white,
                  size: 56),
              const SizedBox(height: 18),
              Text(isCleared ? "FINANCIALLY CLEARED" : "CLEARANCE ON HOLD",
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 17,
                      letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Text(
                  isCleared
                      ? "Student is eligible for exams and academic releases."
                      : "Outstanding balance must be settled to release clearances.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                      height: 1.4)),
              const Divider(height: 40, color: Colors.white24),
              Text("₱${NumberFormat('#,##0.00').format(_accountBalance)}",
                  style: GoogleFonts.orbitron(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              const SizedBox(height: 4),
              const Text("REMAINING ACCOUNTABILITY",
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
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
              _actionTile("Generate Statement (SOA)",
                  Icons.receipt_long_rounded, _generateSOA,
                  textColor: Colors.white),
              const Divider(color: Colors.white10, height: 1),
              _actionTile("Email Billing Reminder", Icons.mail_outline_rounded,
                  _sendBillingReminderEmail,
                  textColor: Colors.white),
            ],
          ),
        )
      ],
    );
  }

  Widget _actionTile(String title, IconData icon, VoidCallback onTap,
          {Color? textColor}) =>
      ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Icon(icon, color: aViolet, size: 22),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
        trailing: const Icon(Icons.chevron_right_rounded,
            size: 20, color: Colors.blueGrey),
      );

  Widget _buildWelcomeState(Color textColor) => Center(
        child: Column(children: [
          const SizedBox(height: 100),
          Icon(Icons.wallet_rounded,
              size: 72, color: Colors.blueGrey.withOpacity(0.1)),
          const SizedBox(height: 24),
          Text("Billing Terminal Idle",
              style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey)),
          const SizedBox(height: 4),
          const Text(
              "Search a Student ID to perform an official clearance billing audit.",
              style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ]),
      );

  void _showToast(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }
}
