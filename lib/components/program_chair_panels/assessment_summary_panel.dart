import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../../services/supabase_service.dart';

class AssessmentSummaryPanel extends StatefulWidget {
  final bool isDarkMode;
  const AssessmentSummaryPanel({super.key, required this.isDarkMode});

  @override
  State<AssessmentSummaryPanel> createState() => _AssessmentSummaryPanelState();
}

class _AssessmentSummaryPanelState extends State<AssessmentSummaryPanel> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _activeAssessment;
  List<Map<String, dynamic>> _enrolledSubjects = [];

  // Modern Tonal Palette Constants
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);
  static const Color success = Color(0xFF69F0AE);

  /// DATABASE ENGINE: Fetches actual student data and calculates institutional fees
  Future<void> _handleSearch() async {
    final String idNum = _searchController.text.trim();
    if (idNum.isEmpty) return;

    setState(() {
      _isLoading = true;
      _activeAssessment = null;
    });

    final client = SupabaseService().client;

    try {
      // 1. Identity Handshake: profile -> details -> course -> year_level
      final response = await client
          .from('profiles')
          .select(
              '*, student_details(*, courses(name, code), year_levels(definition))')
          .eq('user_id_number', idNum)
          .maybeSingle();

      if (response == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 2. Load Sync: Fetch subjects assigned to this student in study_loads
      final List<dynamic> loadsResponse = await client
          .from('study_loads')
          .select('*, subjects(*)')
          .eq('student_id', response['id']);

      if (mounted) {
        setState(() {
          _isLoading = false;
          final details = _extractDetails(response);

          _enrolledSubjects = List<Map<String, dynamic>>.from(loadsResponse);

          // Calculate dynamic units from DB
          double totalUnits = _enrolledSubjects.fold(0.0, (sum, item) {
            return sum +
                (double.tryParse(item['subjects']['units'].toString()) ?? 0.0);
          });

          _activeAssessment = {
            "studentName": "${response['fn']} ${response['ln']}",
            "studentId": response['user_id_number'],
            "program": details?['courses']?['name'] ?? "Unknown Program",
            "year": details?['year_levels']?['definition'] ?? "N/A",
            "units": totalUnits,
            "ratePerUnit": 1550.0, // Institutional Constant
            "balance": details?['account_balance'] ?? 0.0,
            "misc": {
              "Registration": 500.0,
              "Library": 800.0,
              "Energy Fee": 2500.0,
              "Medical/Dental": 450.0,
              "Athletics": 600.0,
            },
            "discount":
                totalUnits > 20 ? 6510.0 : 0.0, // Scholarship logic simulation
          };
        });
      }
    } catch (e) {
      debugPrint("Assessment DB Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// HELPER: Handles Supabase single vs list return for student_details
  Map<String, dynamic>? _extractDetails(Map<String, dynamic> profile) {
    final dynamic raw = profile['student_details'];
    if (raw == null) return null;
    if (raw is List && raw.isNotEmpty) return raw[0] as Map<String, dynamic>;
    if (raw is Map<String, dynamic>) return raw;
    return null;
  }

  double _calculateTotal() {
    if (_activeAssessment == null) return 0.0;
    double tuition =
        _activeAssessment!['units'] * _activeAssessment!['ratePerUnit'];

    final Map<String, double> misc =
        Map<String, double>.from(_activeAssessment!['misc']);
    double miscTotal = misc.values.fold(0, (sum, val) => sum + val);

    double labFees = _enrolledSubjects.any((s) =>
            s['subjects']['code'].contains('CP') ||
            s['subjects']['code'].contains('CC'))
        ? 1200.0
        : 0.0;

    return (tuition + labFees + miscTotal) -
        (_activeAssessment!['discount'] as double);
  }

  Future<void> _generateBillingPDF(BuildContext context) async {
    if (_activeAssessment == null) return;
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
                  child: pw.Text("SAN SEBASTIAN COLLEGE - RECOLETOS DE CAVITE",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 14))),
              pw.Center(
                  child: pw.Text(
                      "OFFICE OF THE PROGRAM CHAIR - ASSESSMENT AUDIT",
                      style: pw.TextStyle(fontSize: 10))),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text("Student: ${_activeAssessment!['studentName']}"),
              pw.Text("ID: ${_activeAssessment!['studentId']}"),
              pw.Text(
                  "Program: ${_activeAssessment!['program']} | Year: ${_activeAssessment!['year']}"),
              pw.SizedBox(height: 30),
              pw.Text("ITEMIZED ENROLLED SUBJECTS",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.SizedBox(height: 10),
              ..._enrolledSubjects.map((s) => pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                          "${s['subjects']['code']} - ${s['subjects']['name']}",
                          style: const pw.TextStyle(fontSize: 9)),
                      pw.Text("${s['subjects']['units']}.0 Units",
                          style: const pw.TextStyle(fontSize: 9)),
                    ],
                  )),
              pw.Divider(height: 30),
              pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                      "TOTAL ASSESSMENT: PHP ${_calculateTotal().toStringAsFixed(2)}",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 14))),
              pw.Spacer(),
              pw.Text("Generated via UEMSSP Core on $timestamp",
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
            ],
          ),
        ),
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final file =
          File("${dir.path}/Assessment_${_activeAssessment!['studentId']}.pdf");
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      debugPrint("PDF Error: $e");
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
          _buildSearchBar(bgColor, textColor),
          const SizedBox(height: 32),
          if (_isLoading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(100),
                    child: CircularProgressIndicator(color: aViolet)))
          else if (_activeAssessment != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    flex: 6, child: _buildItemizedSection(bgColor, textColor)),
                const SizedBox(width: 24),
                Expanded(
                    flex: 4,
                    child: _buildSummaryCard(context, bgColor, textColor)),
              ],
            )
          else
            _buildEmptyState(textColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color text) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Academic Assessment Audit",
              style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: text,
                  letterSpacing: -1)),
          const Text(
              "Verify current student load and compute institutional fees based on real-time units.",
              style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
        ],
      );

  Widget _buildSearchBar(Color bg, Color text) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10)),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: text),
                onSubmitted: (_) => _handleSearch(),
                decoration: InputDecoration(
                  hintText: "Enter Student ID (e.g. 6001)...",
                  prefixIcon: const Icon(LucideIcons.search, color: aViolet),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.03),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 16),
            _actionIconButton(LucideIcons.refreshCw, _handleSearch, aViolet),
          ],
        ),
      );

  Widget _buildItemizedSection(Color bg, Color text) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("ITEMIZED ENROLLED LOAD",
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: aViolet,
                        letterSpacing: 1.5)),
                _statusBadge("LIVE DATA", success),
              ],
            ),
            const SizedBox(height: 24),
            ..._enrolledSubjects
                .map((s) => _itemRow(
                    s['subjects']['code'],
                    s['subjects']['name'],
                    (double.tryParse(s['subjects']['units'].toString()) ??
                            0.0) *
                        1550.0,
                    text))
                .toList(),
            const Divider(height: 48, color: Colors.white10),
            Text("MISCELLANEOUS BREAKDOWN",
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.blueGrey)),
            const SizedBox(height: 16),
            ...(_activeAssessment!['misc'] as Map<String, double>)
                .entries
                .map((e) =>
                    _itemRow(e.key, "Service Fee", e.value, text, isMisc: true))
                .toList(),
          ],
        ),
      );

  Widget _buildSummaryCard(BuildContext context, Color bg, Color text) =>
      Column(
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [pViolet, aViolet]),
                borderRadius: BorderRadius.circular(28)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("NET ASSESSMENT",
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                Text("₱${_calculateTotal().toStringAsFixed(2)}",
                    style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
                const SizedBox(height: 32),
                _summaryRow("Student", _activeAssessment!['studentName']),
                _summaryRow("Units", "${_activeAssessment!['units']} Units"),
                _summaryRow("Discount", "- ₱${_activeAssessment!['discount']}",
                    isDiscount: true),
                const Divider(height: 48, color: Colors.white24),
                SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                            backgroundColor: success,
                            foregroundColor: Colors.black),
                        child: const Text("FINALIZE & APPROVE"))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: OutlinedButton.icon(
              onPressed: () => _generateBillingPDF(context),
              icon: const Icon(LucideIcons.fileDown, size: 18),
              label: const Text("GENERATE STATEMENT"),
              style: OutlinedButton.styleFrom(
                  foregroundColor: aViolet,
                  side: const BorderSide(color: aViolet),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
            ),
          ),
        ],
      );

  Widget _itemRow(String l, String d, double a, Color t,
          {bool isSpecial = false, bool isMisc = false}) =>
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(l,
                      style: TextStyle(
                          color: isSpecial ? success : t,
                          fontWeight: FontWeight.bold)),
                  Text(d,
                      style:
                          const TextStyle(color: Colors.blueGrey, fontSize: 11))
                ])),
            Text("₱${a.toStringAsFixed(2)}",
                style: TextStyle(
                    color: isSpecial ? success : t,
                    fontWeight: FontWeight.w900))
          ]));

  Widget _summaryRow(String l, String v, {bool isDiscount = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l, style: const TextStyle(color: Colors.white70)),
        Text(v,
            style: TextStyle(
                color: isDiscount ? success : Colors.white,
                fontWeight: FontWeight.bold))
      ]));

  Widget _buildEmptyState(Color t) => Center(
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 100),
          child: Column(children: [
            Icon(LucideIcons.user, size: 64, color: t.withOpacity(0.05)),
            const SizedBox(height: 16),
            Text("Search a student ID to begin assessment audit.",
                style: TextStyle(color: t.withOpacity(0.3)))
          ])));

  Widget _actionIconButton(
          IconData icon, VoidCallback onTap, Color color) =>
      Container(
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: IconButton(
              onPressed: onTap, icon: Icon(icon, color: color, size: 20)));

  Widget _statusBadge(String t, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withOpacity(0.2))),
      child: Text(t,
          style:
              TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w900)));
}
