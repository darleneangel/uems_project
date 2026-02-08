import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class AssessmentPanel extends StatelessWidget {
  final bool isDarkMode;
  final Map<String, dynamic> studentData;

  const AssessmentPanel({
    super.key,
    required this.isDarkMode,
    required this.studentData,
  });

  // --- BUSINESS LOGIC (MOCK ENGINE) ---
  double get totalUnits => 21.0;
  double get ratePerUnit => 1500.0;
  double get miscTotal => 5450.0;
  double get scholarshipDiscount => 0.20;

  double calculateGrossTuition() => totalUnits * ratePerUnit;
  double calculateDiscountAmount() =>
      calculateGrossTuition() * scholarshipDiscount;
  double calculateTotalAssessment() =>
      (calculateGrossTuition() + miscTotal) - calculateDiscountAmount();

  bool isClearedForExam() {
    return studentData['balance'] <= 0 &&
        studentData['clearance_status'] != 'Pending';
  }

  // --- PDF GENERATION LOGIC ---

  Future<void> _generatePdfExport(BuildContext context, String type) async {
    final pdf = pw.Document();
    final String timestamp = DateTime.now().toString().split('.')[0];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "SAN SEBASTIAN COLLEGE - RECOLETOS DE CAVITE",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              pw.Text(
                "Unified Education Management System - $type",
                style: pw.TextStyle(fontSize: 10),
              ),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text("Student Name: ${studentData['name']}"),
              pw.Text("Student ID: ${studentData['id']}"),
              pw.Text("Program: ${studentData['program']}"),
              pw.Text("Date Generated: $timestamp"),
              pw.SizedBox(height: 30),
              if (type == "Exam Permit") ...[
                pw.Center(
                  child: pw.Text(
                    "OFFICIAL EXAM PERMIT",
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    "STATUS: CLEARED",
                    style: pw.TextStyle(
                      color: PdfColors.green,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  "This permit allows the student to take the 2nd Semester Midterm Examinations.",
                ),
              ] else if (type == "Assessment Form") ...[
                pw.Text(
                  "TUITION BREAKDOWN",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Bullet(
                  text: "Gross Tuition: PHP ${calculateGrossTuition()}",
                ),
                pw.Bullet(text: "Miscellaneous: PHP $miscTotal"),
                pw.Bullet(text: "Discounts: PHP ${calculateDiscountAmount()}"),
                pw.Divider(),
                pw.Text(
                  "TOTAL NET ASSESSMENT: PHP ${calculateTotalAssessment()}",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ] else if (type == "Audit Trail") ...[
                pw.Text(
                  "SECURITY TRANSACTION LOGS",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  "[2026-02-01 09:00] Account Created via Admissions Office",
                ),
                pw.Text(
                  "[2026-02-03 14:20] Subject Load Validated by Program Chair",
                ),
                pw.Text(
                  "[2026-02-05 11:00] Scholarship applied (Academic 20%)",
                ),
                pw.Text(
                  "[2026-02-07 16:45] Assessment Finalized by Accounting",
                ),
              ],
              pw.Spacer(),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  "Computer Generated Document - No Signature Required",
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        "${dir.path}/${type.replaceAll(' ', '_').toLowerCase()}.pdf",
      );
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error exporting PDF: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor = isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final Color subTextColor = isDarkMode ? Colors.white54 : Colors.blueGrey;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. LIFECYCLE TRACKER (ENROLLMENT STATUS)
          _buildEnrollmentTracker(textColor),
          const SizedBox(height: 24),

          _buildHeader(textColor, subTextColor),
          const SizedBox(height: 24),

          // 2. FINANCIAL ASSESSMENT CARD
          _buildFinancialCard(cardColor, textColor, subTextColor),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 3. CLEARANCE & ELIGIBILITY
              Expanded(
                flex: 5,
                child: _buildClearanceCard(
                  context,
                  cardColor,
                  textColor,
                  subTextColor,
                ),
              ),
              const SizedBox(width: 20),
              // 4. ACADEMIC STANDING
              Expanded(
                flex: 4,
                child: _buildAcademicStandingCard(
                  cardColor,
                  textColor,
                  subTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 5. FOOTER ACTIONS
          _buildActionFooter(context, cardColor, textColor),
        ],
      ),
    );
  }

  Widget _buildEnrollmentTracker(Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _trackStep("Applied", true, isDarkMode: isDarkMode),
          _trackDivider(true, isDarkMode: isDarkMode),
          _trackStep("Assessed", true, isDarkMode: isDarkMode),
          _trackDivider(true, isDarkMode: isDarkMode),
          _trackStep("Enrolled", true, isDarkMode: isDarkMode, isCurrent: true),
          _trackDivider(false, isDarkMode: isDarkMode),
          _trackStep("Cleared", false, isDarkMode: isDarkMode),
        ],
      ),
    );
  }

  Widget _buildHeader(Color textColor, Color subTextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Verified Student Data | ${studentData['semester']}",
              style: GoogleFonts.inter(
                fontSize: 13,
                color: subTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        _statusBadge("ENROLLED", const Color(0xFF69F0AE)),
      ],
    );
  }

  Widget _buildFinancialCard(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _financeTitle(
                LucideIcons.banknote,
                "Tuition Breakdown",
                textColor,
              ),
              Text(
                "OFFICIAL RECEIPT PENDING",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: subTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _breakdownRow(
            "Gross Tuition Fee",
            calculateGrossTuition(),
            textColor,
          ),
          _breakdownRow("Miscellaneous & Lab Fees", miscTotal, textColor),
          _breakdownRow(
            "Scholarship (20% Discount)",
            -calculateDiscountAmount(),
            const Color(0xFF69F0AE),
            isNegative: true,
          ),
          const Divider(height: 40, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Outstanding Balance",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              Text(
                "₱${studentData['balance'].toStringAsFixed(2)}",
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClearanceCard(
    BuildContext context,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    bool cleared = isClearedForExam();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _financeTitle(LucideIcons.shieldCheck, "Exam Eligibility", textColor),
          const SizedBox(height: 24),
          _clearanceItem(
            "Accounting (Balance)",
            studentData['balance'] <= 0,
            subTextColor,
          ),
          _clearanceItem("Library & Lab", true, subTextColor),
          _clearanceItem("Registrar Records", true, subTextColor),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicStandingCard(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        children: [
          _financeTitle(LucideIcons.graduationCap, "GPA Standing", textColor),
          const SizedBox(height: 32),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 85,
                height: 85,
                child: CircularProgressIndicator(
                  value: 0.92,
                  strokeWidth: 8,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
                ),
              ),
              Text(
                "1.25",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "ACADEMIC SCHOLAR",
            style: GoogleFonts.inter(
              color: const Color(0xFF69F0AE),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionFooter(
    BuildContext context,
    Color cardColor,
    Color textColor,
  ) {
    return Row(
      children: [
        Expanded(
          child: _footerAction(
            context,
            LucideIcons.printer,
            "Print Assessment Form",
            "Assessment Form",
            cardColor,
            textColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _footerAction(
            context,
            LucideIcons.history,
            "Export Audit Trail",
            "Audit Trail",
            cardColor,
            textColor,
          ),
        ),
      ],
    );
  }

  // --- UI ATOMS ---

  Widget _trackStep(
    String label,
    bool isDone, {
    required bool isDarkMode,
    bool isCurrent = false,
  }) {
    final Color iconColor = isDone
        ? const Color(0xFF69F0AE)
        : (isDarkMode ? Colors.white24 : Colors.black26);
    final Color labelColor = isCurrent
        ? (isDarkMode ? Colors.white : const Color(0xFF2E1065))
        : (isDarkMode ? Colors.white38 : Colors.black38);

    return Column(
      children: [
        Icon(
          isDone ? LucideIcons.checkCircle2 : LucideIcons.circle,
          color: iconColor,
          size: 16,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: labelColor,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _trackDivider(bool active, {required bool isDarkMode}) => Expanded(
    child: Divider(
      color: active
          ? const Color(0xFF69F0AE).withOpacity(0.3)
          : (isDarkMode ? Colors.white10 : Colors.black12),
      indent: 8,
      endIndent: 8,
    ),
  );

  Widget _breakdownRow(
    String label,
    double amount,
    Color color, {
    bool isNegative = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: isDarkMode ? Colors.white70 : Colors.blueGrey,
              fontSize: 13,
            ),
          ),
          Text(
            "${isNegative ? '-' : ''}₱${amount.abs().toStringAsFixed(2)}",
            style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _clearanceItem(String office, bool isOk, Color sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            isOk ? LucideIcons.checkCircle2 : LucideIcons.clock,
            color: isOk ? const Color(0xFF69F0AE) : const Color(0xFF8B5CF6),
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              office,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.blueGrey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerAction(
    BuildContext context,
    IconData icon,
    String label,
    String type,
    Color cardColor,
    Color textColor,
  ) {
    return InkWell(
      onTap: () => _generatePdfExport(context, type),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF8B5CF6), size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _financeTitle(IconData icon, String title, Color textColor) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF8B5CF6), size: 20),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
