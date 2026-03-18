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
  final Map<String, dynamic>
      userData; // Context for the logged-in Program Chair

  const AssessmentSummaryPanel(
      {super.key, required this.isDarkMode, required this.userData});

  @override
  State<AssessmentSummaryPanel> createState() => _AssessmentSummaryPanelState();
}

class _AssessmentSummaryPanelState extends State<AssessmentSummaryPanel> {
  final TextEditingController _searchController = TextEditingController();
  final SupabaseService _service = SupabaseService();

  bool _isLoading = false;
  Map<String, dynamic>? _activeAssessment;
  List<Map<String, dynamic>> _enrolledSubjects = [];
  String? _chairDeptId;

  // Modern Tonal Palette Constants
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);
  static const Color success = Color(0xFF69F0AE);

  @override
  void initState() {
    super.initState();
    _initChairContext();
  }

  Future<void> _initChairContext() async {
    final String? userIdNum = widget.userData['user_id_number']?.toString();
    if (userIdNum == null) return;

    final context = await _service.getChairContext(userIdNum);
    if (context != null && mounted) {
      setState(() {
        _chairDeptId = context['department_id']?.toString();
      });
    }
  }

  /// 🛰️ DATABASE ENGINE: Fetches actual student data and calculates institutional fees
  Future<void> _handleSearch() async {
    final String idNum = _searchController.text.trim();
    if (idNum.isEmpty) return;

    setState(() {
      _isLoading = true;
      _activeAssessment = null;
    });

    try {
      // 1. Identity Handshake: profile -> details -> course -> year_level
      final response = await _service.client
          .from('profiles')
          .select(
              '*, student_details!inner(*, courses(name, code, department_id), year_levels(definition))')
          .eq('user_id_number', idNum)
          .maybeSingle();

      if (response == null) {
        _showToast("Student ID $idNum not found.", Colors.orangeAccent);
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Security Check: Ensure the Chair only assesses their own department's students
      final String studentDeptId =
          response['student_details']['courses']['department_id'].toString();
      if (_chairDeptId != null && studentDeptId != _chairDeptId) {
        _showToast("Access Denied: Student belongs to another department.",
            Colors.redAccent);
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 2. Load Sync: Fetch subjects assigned to this student using the specific FK fix
      final List<dynamic> loadsResponse = await _service.client
          .from('study_loads')
          .select('*, subjects(*)')
          .eq('student_id', response['id']);

      if (mounted) {
        setState(() {
          _isLoading = false;
          final details = response['student_details'];

          _enrolledSubjects = List<Map<String, dynamic>>.from(loadsResponse);

          // Calculate dynamic units from DB
          double totalUnits = _enrolledSubjects.fold(0.0, (sum, item) {
            final sub = item['subjects'];
            return sum + (double.tryParse(sub['units'].toString()) ?? 0.0);
          });

          _activeAssessment = {
            "profile_id": response['id'],
            "studentName": "${response['fn']} ${response['ln']}",
            "studentId": response['user_id_number'],
            "program": details?['courses']?['name'] ?? "Unknown Program",
            "year": details?['year_levels']?['definition'] ?? "N/A",
            "units": totalUnits,
            "ratePerUnit": 1550.0, // Institutional Constant
            "balance": double.tryParse(
                    details?['account_balance']?.toString() ?? "0.0") ??
                0.0,
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

  /// 🛰️ TRANSMISSION: Sends finalized assessment to Accounting Ledger
  Future<void> _finalizeAndSendToAccounting() async {
    if (_activeAssessment == null || _enrolledSubjects.isEmpty) return;

    setState(() => _isLoading = true);
    final double totalAmount = _calculateTotal();

    try {
      // 1. Create entry in a dedicated 'assessments' table for Accounting to view
      await _service.client.from('office_requests').insert({
        'profile_id': _activeAssessment!['profile_id'],
        'request_type': 'Accounting Assessment',
        'status': 'Pending Payment',
        'details':
            'Finalized assessment for ${_activeAssessment!['units']} units. Total: ₱${totalAmount.toStringAsFixed(2)}',
      });

      // 2. Update the student's pending balance in details
      await _service.updateAccountBalance(
          _activeAssessment!['profile_id'], totalAmount);

      _showToast("Assessment approved and transmitted to Accounting.", success);
      setState(() {
        _isLoading = false;
        _activeAssessment = null;
        _enrolledSubjects = [];
        _searchController.clear();
      });
    } catch (e) {
      _showToast("Handover Error: $e", Colors.redAccent);
      setState(() => _isLoading = false);
    }
  }

  double _calculateTotal() {
    if (_activeAssessment == null) return 0.0;
    double tuition =
        _activeAssessment!['units'] * _activeAssessment!['ratePerUnit'];

    final Map<String, double> misc =
        Map<String, double>.from(_activeAssessment!['misc']);
    double miscTotal = misc.values.fold(0, (sum, val) => sum + val);

    // Dynamic Lab Fees based on Subject Codes
    double labFees = _enrolledSubjects.any((s) {
      final code = s['subjects']['code'].toString();
      return code.contains('CP') ||
          code.contains('CC') ||
          code.contains('ITCC');
    })
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
                      style: const pw.TextStyle(fontSize: 10))),
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
              pw.Text(
                  "Authorized by: ${widget.userData['fn']} ${widget.userData['ln']}",
                  style: const pw.TextStyle(fontSize: 8)),
              pw.Text("Generated via UEMSSP Core on $timestamp",
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
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
      debugPrint("PDF Generation Failed: $e");
    }
  }

  void _showToast(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      backgroundColor: c,
      behavior: SnackBarBehavior.floating,
    ));
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
              "Verify student study load and compute institutional fees for Accounting handover.",
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
                  hintText: "Enter Student ID Number...",
                  hintStyle:
                      const TextStyle(color: Colors.blueGrey, fontSize: 13),
                  prefixIcon: const Icon(LucideIcons.userCheck, color: aViolet),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.03),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 16),
            _actionIconButton(LucideIcons.search, _handleSearch, aViolet),
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
                Text("ITEMIZED TUITION & LAB FEES",
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: aViolet,
                        letterSpacing: 1.5)),
                _statusBadge("VERIFIED LOAD", success),
              ],
            ),
            const SizedBox(height: 24),
            ..._enrolledSubjects.map((s) {
              final String code = s['subjects']['code'].toString();
              final bool isLab = code.contains('CP') ||
                  code.contains('CC') ||
                  code.contains('ITCC');
              return Column(
                children: [
                  _itemRow(
                      code,
                      s['subjects']['name'],
                      (double.parse(s['subjects']['units'].toString()) *
                          1550.0),
                      text),
                  if (isLab)
                    _itemRow(
                        "LAB FEE", "Computer/Specialist Resource", 1200.0, text,
                        isSpecial: true),
                ],
              );
            }),
            const Divider(height: 48, color: Colors.white10),
            Text("MISCELLANEOUS FEES",
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.blueGrey)),
            const SizedBox(height: 16),
            ...(_activeAssessment!['misc'] as Map<String, double>)
                .entries
                .map((e) => _itemRow(
                    e.key, "Fixed Institutional Fee", e.value, text,
                    isMisc: true))
                ,
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
                const Text("TOTAL ASSESSMENT",
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
                _summaryRow(
                    "Total Units", "${_activeAssessment!['units']} Units"),
                _summaryRow(
                    "Tuition Discount", "- ₱${_activeAssessment!['discount']}",
                    isDiscount: true),
                const Divider(height: 48, color: Colors.white24),
                SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                        onPressed: _finalizeAndSendToAccounting,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: success,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16))),
                        child: const Text("FINALIZE & TRANSMIT",
                            style: TextStyle(fontWeight: FontWeight.bold)))),
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
              label: const Text("SAVE AS STATEMENT"),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        Text(v,
            style: TextStyle(
                color: isDiscount ? success : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13))
      ]));

  Widget _buildEmptyState(Color t) => Center(
          child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 100),
        child: Column(children: [
          const Icon(LucideIcons.user, size: 64, color: Colors.blueGrey),
          const SizedBox(height: 16),
          Text("Search student ID to generate billing assessment.",
              style: TextStyle(color: t.withOpacity(0.3)))
        ]),
      ));

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
