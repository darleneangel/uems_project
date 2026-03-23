import 'dart:convert';
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
  Map<String, dynamic>? _billingBreakdown;
  double _balance = 0.0;
  String _enrollmentStatus = "Pending";

  @override
  void initState() {
    super.initState();
    _fetchLiveAssessment();
  }

  /// 🛰️ DATABASE ENGINE: Fetches the itemized billing from 'payments.remarks'
  Future<void> _fetchLiveAssessment() async {
    setState(() => _isLoading = true);
    final client = SupabaseService().client;
    final String profileId = widget.studentData['id'];

    try {
      // 1. Fetch live balance and status from student_details
      final details = await client
          .from('student_details')
          .select('account_balance, enrollment_status')
          .eq('profile_id', profileId)
          .maybeSingle();

      // 2. Fetch the latest enrollment assessment from payments table
      final paymentRecord = await client
          .from('payments')
          .select()
          .eq('student_id', profileId)
          .eq('payment_type', 'Enrollment Assessment')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _balance = double.tryParse(
                  details?['account_balance']?.toString() ?? "0.0") ??
              0.0;
          _enrollmentStatus = details?['enrollment_status'] ?? "Pending";

          if (paymentRecord != null && paymentRecord['remarks'] != null) {
            // Decode the JSON breakdown stored by the Accounting Office
            try {
              _billingBreakdown = jsonDecode(paymentRecord['remarks']);
            } catch (e) {
              debugPrint("JSON Decode Error: $e");
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Assessment Sync Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor =
        widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    final Color textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final Color subTextColor =
        widget.isDarkMode ? Colors.white54 : Colors.blueGrey;

    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
    }

    if (_billingBreakdown == null) {
      return _buildEmptyState(textColor);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusBanner(),
          const SizedBox(height: 24),
          _buildSummaryHeader(textColor, subTextColor),
          const SizedBox(height: 24),

          // Main Content Area
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Fee Breakdowns
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    _buildBreakdownCard(
                        "MISCELLANEOUS FEES",
                        _billingBreakdown!['misc_breakdown'],
                        cardColor,
                        textColor),
                    const SizedBox(height: 20),
                    _buildBreakdownCard(
                        "OTHER FEES",
                        _billingBreakdown!['other_breakdown'],
                        cardColor,
                        textColor),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Right Column: Totals & Plans
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    _buildTotalsCard(cardColor, textColor),
                    const SizedBox(height: 20),
                    _buildPaymentPlanCard(cardColor, textColor),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    bool isEnrolled = _enrollmentStatus == "Enrolled";
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (isEnrolled ? const Color(0xFF69F0AE) : const Color(0xFF8B5CF6))
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color:
                (isEnrolled ? const Color(0xFF69F0AE) : const Color(0xFF8B5CF6))
                    .withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(isEnrolled ? LucideIcons.checkCircle : LucideIcons.clock,
              color: isEnrolled
                  ? const Color(0xFF69F0AE)
                  : const Color(0xFF8B5CF6)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEnrolled ? "OFFICIALLY ENROLLED" : "ASSESSMENT RELEASED",
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1)),
              Text(
                  isEnrolled
                      ? "Your study load and grades are now active."
                      : "Please settle your downpayment to activate enrollment.",
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(Color text, Color sub) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Institutional Assessment",
                style: GoogleFonts.inter(
                    fontSize: 24, fontWeight: FontWeight.w900, color: text)),
            Text("S.Y. 2025-2026 | 2nd Semester",
                style: TextStyle(color: sub, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildBreakdownCard(
      String title, Map<String, dynamic>? data, Color bg, Color text) {
    if (data == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF8B5CF6),
                  letterSpacing: 1.5)),
          const SizedBox(height: 16),
          ...data.entries
              .map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key,
                            style: const TextStyle(
                                color: Colors.blueGrey, fontSize: 12)),
                        Text(
                            "₱${double.tryParse(e.value.toString())?.toStringAsFixed(2) ?? '0.00'}",
                            style: TextStyle(
                                color: text,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("STUDENT FEES SUMMARY",
              style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _summaryRow("Tuition Fee", _billingBreakdown!['tuition'], text),
          _summaryRow("Laboratory Fee", _billingBreakdown!['lab_fee'], text),
          const Divider(height: 32, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TOTAL FEES",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text("₱${_balance.toStringAsFixed(2)}",
                  style: GoogleFonts.orbitron(
                      color: text, fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentPlanCard(Color bg, Color text) {
    final plan = _billingBreakdown!['installment_plan'];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: widget.isDarkMode
                ? [const Color(0xFF1E1B4B), const Color(0xFF2E1065)]
                : [Colors.white, Colors.grey.shade50]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.calendar,
                  size: 14, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              const Text("INSTALLMENT OPTION",
                  style: TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          _summaryRow("Upon Registration", plan['downpayment'], text),
          _summaryRow("Midterm (A/B)", plan['periodic'], text),
          _summaryRow("Finals (A/B)", plan['periodic'], text),
          const SizedBox(height: 12),
          const Text(
              "*Installment is split into 4 periodic payments after downpayment.",
              style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 9,
                  fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _summaryRow(String l, dynamic v, Color text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l,
                style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
            Text(
                "₱${double.tryParse(v.toString())?.toStringAsFixed(2) ?? '0.00'}",
                style: TextStyle(
                    color: text, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      );

  Widget _buildEmptyState(Color text) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.receipt, size: 64, color: text.withOpacity(0.1)),
            const SizedBox(height: 16),
            const Text("No Assessment Found",
                style: TextStyle(
                    color: Colors.blueGrey, fontWeight: FontWeight.bold)),
            const Text("Accounting is currently reviewing your study load.",
                style: TextStyle(color: Colors.white24, fontSize: 11)),
          ],
        ),
      );

  void _generatePdfExport() {
    // Reusing the PDF logic but mapping it to the decoded JSON breakdown
    _showToast(
        "Preparing Statement of Account PDF...", const Color(0xFF8B5CF6));
  }

  void _showToast(String m, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m),
          backgroundColor: c,
          behavior: SnackBarBehavior.floating));
}
