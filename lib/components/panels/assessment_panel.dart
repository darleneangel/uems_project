import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../../services/supabase_service.dart';

class AssessmentPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> studentData;

  const AssessmentPanel({
    super.key,
    required this.isDarkMode,
    required this.studentData,
  });

  @override
  State<AssessmentPanel> createState() => _AssessmentPanelState();
}

class _AssessmentPanelState extends State<AssessmentPanel> {
  bool _isLoading = true;
  Map<String, dynamic>? _assessment;
  double _balance = 0.0;
  double _gwa = 0.0;
  String _clearanceStatus = "Pending";

  @override
  void initState() {
    super.initState();
    _fetchLiveAssessment();
  }

  /// DATABASE ENGINE: Fetches assessment details and current financial standing
  Future<void> _fetchLiveAssessment() async {
    setState(() => _isLoading = true);
    final client = SupabaseService().client;
    final String profileId = widget.studentData['id'];

    try {
      // 1. Fetch current balance and academic standing from student_details
      final details = await client
          .from('student_details')
          .select('account_balance, current_gwa, enrollment_status')
          .eq('profile_id', profileId)
          .maybeSingle();

      // 2. Fetch the detailed assessment breakdown from Accounting
      final assessmentResult = await client
          .from('assessments')
          .select()
          .eq('student_id', profileId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _assessment = assessmentResult;
          _balance = double.tryParse(
                  details?['account_balance']?.toString() ?? "0.0") ??
              0.0;
          _gwa =
              double.tryParse(details?['current_gwa']?.toString() ?? "0.0") ??
                  0.0;
          _clearanceStatus = details?['enrollment_status'] ?? "Pending";
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Assessment Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool isClearedForExam() {
    return _balance <= 0 && _clearanceStatus == 'Enrolled';
  }

  // --- MODERNIZED PDF GENERATION LOGIC ---
  Future<void> _generatePdfExport(BuildContext context, String type) async {
    final pdf = pw.Document();
    final String timestamp = DateTime.now().toString().split('.')[0];
    final PdfColor brandViolet = PdfColor.fromInt(0xFF7C3AED);

    pw.ImageProvider? logoImage;
    try {
      final ByteData data = await rootBundle.load('assets/image/logo (2).png');
      logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      if (logoImage != null)
                        pw.Container(
                            width: 40, height: 40, child: pw.Image(logoImage))
                      else
                        pw.Container(
                          width: 35,
                          height: 35,
                          decoration: pw.BoxDecoration(
                              color: brandViolet,
                              borderRadius: pw.BorderRadius.circular(8)),
                          child: pw.Center(
                              child: pw.Text("U",
                                  style: pw.TextStyle(
                                      color: PdfColors.white,
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 20))),
                        ),
                      pw.SizedBox(width: 12),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("UEMSSP",
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 22,
                                  color: brandViolet)),
                          pw.Text("OFFICIAL FINANCIAL RECORDS",
                              style: pw.TextStyle(
                                  fontSize: 8, color: PdfColors.grey700)),
                        ],
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("OFFICIAL DOCUMENT",
                          style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey500)),
                      pw.Text(type.toUpperCase(),
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: brandViolet, thickness: 1.5),
              pw.SizedBox(height: 25),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8)),
                child: pw.Column(
                  children: [
                    pw.Row(children: [
                      pw.Expanded(
                          child: _pdfMetaItem("STUDENT NAME",
                              "${widget.studentData['fn']} ${widget.studentData['ln']}")),
                      pw.Expanded(
                          child: _pdfMetaItem("STUDENT ID",
                              widget.studentData['user_id_number'] ?? "N/A")),
                    ]),
                    pw.SizedBox(height: 10),
                    pw.Row(children: [
                      pw.Expanded(
                          child: _pdfMetaItem("PROGRAM",
                              widget.studentData['program'] ?? "BSCS")),
                      pw.Expanded(
                          child: _pdfMetaItem("DATE GENERATED", timestamp)),
                    ]),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),
              if (type == "Exam Permit") ...[
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text("OFFICIAL EXAM PERMIT",
                          style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: brandViolet)),
                      pw.SizedBox(height: 10),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: pw.BoxDecoration(
                            color: PdfColors.green100,
                            borderRadius: pw.BorderRadius.circular(4)),
                        child: pw.Text("STATUS: FINANCIALLY CLEARED",
                            style: pw.TextStyle(
                                color: PdfColors.green900,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  "This permit officially authorizes the student to participate in the examination period. Authenticated via the Unified Education Management System Core.",
                  style: pw.TextStyle(fontSize: 11, lineSpacing: 4),
                  textAlign: pw.TextAlign.justify,
                ),
              ] else if (type == "Assessment Form") ...[
                pw.Text("TUITION & FEES BREAKDOWN",
                    style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: brandViolet)),
                pw.SizedBox(height: 15),
                _pdfFeeRow("Tuition Assessment",
                    "PHP ${_assessment?['total_tuition']?.toString() ?? '0.00'}"),
                _pdfFeeRow("Miscellaneous Fees",
                    "PHP ${_assessment?['total_misc']?.toString() ?? '0.00'}"),
                pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 10),
                    child: pw.Divider(thickness: 0.5)),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("TOTAL NET ASSESSMENT",
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 13)),
                    pw.Text(
                        "PHP ${_assessment?['grand_total']?.toString() ?? '0.00'}",
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 13,
                            color: brandViolet)),
                  ],
                ),
              ],
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("AUTHENTICATED BY UEMS CLOUD ENGINE",
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 8,
                              color: PdfColors.grey700)),
                      pw.Text(
                          "Verification Hash: ${widget.studentData['id'].toString().substring(0, 8)}",
                          style: pw.TextStyle(
                              fontSize: 7, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Container(
                      width: 40,
                      height: 40,
                      decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300)),
                      child: pw.Center(
                          child: pw.Text("QR",
                              style: pw.TextStyle(
                                  fontSize: 8, color: PdfColors.grey400)))),
                ],
              ),
            ],
          );
        },
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final file =
          File("${dir.path}/${type.replaceAll(' ', '_').toLowerCase()}.pdf");
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error exporting PDF: $e")));
    }
  }

  pw.Widget _pdfMetaItem(String label, String val) =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 7,
                color: PdfColors.grey600,
                fontWeight: pw.FontWeight.bold)),
        pw.Text(val,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))
      ]);
  pw.Widget _pdfFeeRow(String label, String amount) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
            pw.Text(amount,
                style:
                    pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))
          ]));

  @override
  Widget build(BuildContext context) {
    final Color cardColor =
        widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    final Color textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final Color subTextColor =
        widget.isDarkMode ? Colors.white54 : Colors.blueGrey;

    if (_isLoading)
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEnrollmentTracker(textColor),
          const SizedBox(height: 24),
          _buildHeader(textColor, subTextColor),
          const SizedBox(height: 24),
          _buildFinancialCard(cardColor, textColor, subTextColor),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  flex: 5,
                  child: _buildClearanceCard(
                      context, cardColor, textColor, subTextColor)),
              const SizedBox(width: 20),
              Expanded(
                  flex: 4,
                  child: _buildAcademicStandingCard(
                      cardColor, textColor, subTextColor)),
            ],
          ),
          const SizedBox(height: 24),
          _buildActionFooter(context, cardColor, textColor),
        ],
      ),
    );
  }

  Widget _buildEnrollmentTracker(Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _trackStep("Applied", true, isDarkMode: widget.isDarkMode),
          _trackDivider(true, isDarkMode: widget.isDarkMode),
          _trackStep("Assessed", _assessment != null,
              isDarkMode: widget.isDarkMode),
          _trackDivider(_assessment != null, isDarkMode: widget.isDarkMode),
          _trackStep("Enrolled", _clearanceStatus == "Enrolled",
              isDarkMode: widget.isDarkMode, isCurrent: true),
          _trackDivider(_balance <= 0, isDarkMode: widget.isDarkMode),
          _trackStep("Cleared", _balance <= 0, isDarkMode: widget.isDarkMode),
        ],
      ),
    );
  }

  Widget _trackStep(String label, bool isDone,
      {required bool isDarkMode, bool isCurrent = false}) {
    final Color iconColor = isDone
        ? const Color(0xFF69F0AE)
        : (isDarkMode ? Colors.white24 : Colors.black26);
    final Color labelColor = isCurrent
        ? (isDarkMode ? Colors.white : const Color(0xFF2E1065))
        : (isDarkMode ? Colors.white38 : Colors.black38);
    return Column(children: [
      Icon(isDone ? LucideIcons.checkCircle2 : LucideIcons.circle,
          color: iconColor, size: 16),
      const SizedBox(height: 4),
      Text(label,
          style: GoogleFonts.inter(
              fontSize: 10,
              color: labelColor,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
    ]);
  }

  Widget _trackDivider(bool active, {required bool isDarkMode}) => Expanded(
      child: Divider(
          color: active
              ? const Color(0xFF69F0AE).withOpacity(0.3)
              : (isDarkMode ? Colors.white10 : Colors.black12),
          indent: 8,
          endIndent: 8));

  Widget _buildHeader(Color textColor, Color subTextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Verified Financial Data | 2nd Semester 2025-2026",
          style: GoogleFonts.inter(
              fontSize: 13, color: subTextColor, fontWeight: FontWeight.w500),
        ),
        _statusBadge(_clearanceStatus.toUpperCase(), const Color(0xFF69F0AE)),
      ],
    );
  }

  Widget _buildFinancialCard(
      Color cardColor, Color textColor, Color subTextColor) {
    final double tuition =
        double.tryParse(_assessment?['total_tuition']?.toString() ?? "0.0") ??
            0.0;
    final double misc =
        double.tryParse(_assessment?['total_misc']?.toString() ?? "0.0") ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _financeTitle(
                  LucideIcons.banknote, "Cloud Ledger Assessment", textColor),
              Text("OFFICIAL SYNC ACTIVE",
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      color: subTextColor,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          _breakdownRow("Gross Tuition Fee", tuition, textColor),
          _breakdownRow("Miscellaneous & Lab Fees", misc, textColor),
          const Divider(height: 40, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Cloud Outstanding Balance",
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textColor)),
              Text("₱${_balance.toStringAsFixed(2)}",
                  style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF8B5CF6))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClearanceCard(BuildContext context, Color cardColor,
      Color textColor, Color subTextColor) {
    bool cleared = isClearedForExam();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: widget.isDarkMode ? Colors.white10 : Colors.black12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _financeTitle(LucideIcons.shieldCheck, "Exam Eligibility", textColor),
          const SizedBox(height: 24),
          _clearanceItem("Accounting (Balance)", _balance <= 0, subTextColor),
          _clearanceItem("Portal Enrollment", _clearanceStatus == "Enrolled",
              subTextColor),
          _clearanceItem("Administrative Check", true, subTextColor),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: cleared
                  ? () => _generatePdfExport(context, "Exam Permit")
                  : null,
              icon: const Icon(LucideIcons.fileDown, size: 18),
              label: const Text("GENERATE EXAM PERMIT"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF69F0AE),
                foregroundColor: const Color(0xFF1E1B4B),
                disabledBackgroundColor: Colors.white10,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicStandingCard(
      Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: widget.isDarkMode ? Colors.white10 : Colors.black12)),
      child: Column(
        children: [
          _financeTitle(LucideIcons.graduationCap, "Live GWA Index", textColor),
          const SizedBox(height: 32),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 85,
                height: 85,
                child: CircularProgressIndicator(
                  value: (5 - _gwa) /
                      4, // Simple inverse logic for grading scale visualization
                  strokeWidth: 8,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
                ),
              ),
              Text(_gwa.toStringAsFixed(2),
                  style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: textColor)),
            ],
          ),
          const SizedBox(height: 24),
          Text(_gwa <= 1.75 ? "ACADEMIC SCHOLAR" : "REGULAR STANDING",
              style: GoogleFonts.inter(
                  color: _gwa <= 1.75
                      ? const Color(0xFF69F0AE)
                      : Colors.blueAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildActionFooter(
      BuildContext context, Color cardColor, Color textColor) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _footerAction(
                    context,
                    LucideIcons.printer,
                    "Print Assessment",
                    "Assessment Form",
                    cardColor,
                    textColor)),
            const SizedBox(width: 16),
            Expanded(
                child: _footerAction(context, LucideIcons.history,
                    "Audit History", "Audit Trail", cardColor, textColor)),
          ],
        ),
      ],
    );
  }

  // --- UI HELPERS ---
  Widget _breakdownRow(String label, double amount, Color color,
          {bool isNegative = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: GoogleFonts.inter(
                  color: widget.isDarkMode ? Colors.white70 : Colors.blueGrey,
                  fontSize: 13)),
          Text("${isNegative ? '-' : ''}₱${amount.abs().toStringAsFixed(2)}",
              style:
                  GoogleFonts.inter(color: color, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _clearanceItem(String office, bool isOk, Color sub) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Icon(isOk ? LucideIcons.checkCircle2 : LucideIcons.clock,
              color: isOk ? const Color(0xFF69F0AE) : const Color(0xFF8B5CF6),
              size: 16),
          const SizedBox(width: 10),
          Expanded(
              child: Text(office,
                  style: TextStyle(
                      color:
                          widget.isDarkMode ? Colors.white70 : Colors.blueGrey,
                      fontSize: 12))),
        ]),
      );

  Widget _footerAction(BuildContext context, IconData icon, String label,
          String type, Color cardColor, Color textColor) =>
      InkWell(
        onTap: () => _generatePdfExport(context, type),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: const Color(0xFF8B5CF6), size: 18),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ]),
        ),
      );

  Widget _financeTitle(IconData icon, String title, Color textColor) =>
      Row(children: [
        Icon(icon, color: const Color(0xFF8B5CF6), size: 20),
        const SizedBox(width: 12),
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
      ]);

  Widget _statusBadge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Text(text,
            style: GoogleFonts.inter(
                color: color, fontSize: 10, fontWeight: FontWeight.w900)),
      );
}
