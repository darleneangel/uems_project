import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

class TuitionAssessmentPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const TuitionAssessmentPanel({
    super.key,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  State<TuitionAssessmentPanel> createState() => _TuitionAssessmentPanelState();
}

class _TuitionAssessmentPanelState extends State<TuitionAssessmentPanel> {
  final SupabaseService _service = SupabaseService();
  final Set<String> _selectedQueueIds = {}; // For batch processing
  List<Map<String, dynamic>> _queue = [];
  Map<String, dynamic>? _activeStudent;
  List<Map<String, dynamic>> _activeLoads = [];
  bool _isLoading = true;

  // --- TEMPLATE STORAGE (Local Session) ---
  static final List<Map<String, dynamic>> _savedTemplates = [];

  // --- FEE BREAKDOWN STATE ---
  final Map<String, TextEditingController> _miscControllers = {
    "Athletics/Sports": TextEditingController(text: "522.00"),
    "CEAP": TextEditingController(text: "53.00"),
    "Culture/Arts": TextEditingController(text: "279.00"),
    "Development": TextEditingController(text: "423.00"),
    "Ed-Tech/AVR": TextEditingController(text: "1164.00"),
    "Foundation Shirt": TextEditingController(text: "450.00"),
    "Foundation Week": TextEditingController(text: "212.00"),
    "Guidance": TextEditingController(text: "774.00"),
    "Internet": TextEditingController(text: "247.00"),
    "Library": TextEditingController(text: "1758.00"),
    "Medical/Dental": TextEditingController(text: "627.00"),
    "One Management": TextEditingController(text: "265.00"),
    "Outreach": TextEditingController(text: "100.00"),
    "Plagiarism Chk": TextEditingController(text: "212.00"),
    "Publication": TextEditingController(text: "223.00"),
    "REAP": TextEditingController(text: "200.00"),
    "Registration": TextEditingController(text: "469.00"),
    "Research": TextEditingController(text: "106.00"),
    "Student Activity": TextEditingController(text: "375.00"),
    "SSC": TextEditingController(text: "106.00"),
    "Test Papers": TextEditingController(text: "524.00"),
    "Web Service": TextEditingController(text: "79.00"),
  };

  final Map<String, TextEditingController> _otherControllers = {
    "Energy Fee": TextEditingController(text: "490.00"),
    "Insurance": TextEditingController(text: "0.00"),
    "LMS": TextEditingController(text: "1190.00"),
    "Recollection": TextEditingController(text: "0.00"),
    "Retreat": TextEditingController(text: "0.00"),
  };

  final TextEditingController _tuitionRate =
      TextEditingController(text: "772.36");
  final TextEditingController _labFee = TextEditingController(text: "10865.00");
  final TextEditingController _cashDiscount =
      TextEditingController(text: "1159.00");
  final TextEditingController _downpayment =
      TextEditingController(text: "15000.00");

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color pViolet = Color(0xFF2E1065);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  @override
  void initState() {
    super.initState();
    _fetchQueue();
  }

  /// 🛰️ DATABASE: Fetch students ready for assessment
  Future<void> _fetchQueue() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final res = await _service.client
          .from('student_details')
          .select('*, profiles!inner(*), courses(*), year_levels(*)')
          .eq('enrollment_status', 'Assessment');

      if (mounted) {
        setState(() {
          _queue = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🛰️ DATABASE: Load units for calculation
  Future<void> _loadStudentContext(Map<String, dynamic> student) async {
    try {
      final res = await _service.client
          .from('study_loads')
          .select('*, subjects(*)')
          .eq('student_id', student['profile_id']);

      setState(() {
        _activeStudent = student;
        _activeLoads = List<Map<String, dynamic>>.from(res);
        _selectedQueueIds.clear(); // Clear batch if single is selected
      });
    } catch (e) {
      debugPrint("Load Context Error: $e");
    }
  }

  // --- CALCULATION LOGIC ---
  double get _totalUnits => _activeLoads.fold(
      0.0,
      (sum, l) =>
          sum + (double.tryParse(l['subjects']['units'].toString()) ?? 0.0));
  double get _tuitionTotal =>
      _totalUnits * (double.tryParse(_tuitionRate.text) ?? 0.0);
  double get _miscTotal => _miscControllers.values
      .fold(0.0, (sum, c) => sum + (double.tryParse(c.text) ?? 0.0));
  double get _otherTotal => _otherControllers.values
      .fold(0.0, (sum, c) => sum + (double.tryParse(c.text) ?? 0.0));
  double get _labTotal => double.tryParse(_labFee.text) ?? 0.0;
  double get _grandTotal =>
      _tuitionTotal + _miscTotal + _otherTotal + _labTotal;
  double get _cashTotal =>
      _grandTotal - (double.tryParse(_cashDiscount.text) ?? 0.0);
  double get _installmentBalance =>
      _grandTotal - (double.tryParse(_downpayment.text) ?? 0.0);
  double get _perInstallment => _installmentBalance / 4.0;

  /// 🛰️ EDGE FUNCTION EMAIL DISPATCHER
  /// Invokes centralized SMTP gateway to dispatch detailed assessment statement to student's email
  Future<void> _sendBillingEmailViaEdge({
    required String recipientEmail,
    required String studentName,
    required double tuitionVal,
    required double labVal,
    required double totalVal,
    required double unitsVal,
    required List<String> feeBreakdown,
  }) async {
    try {
      debugPrint(
          "📧 UEMSSP Core: Invoking billing notification gateway for $recipientEmail...");
      await _service.client.functions.invoke(
        'send-otp',
        body: {
          'type': 'assessment_billing',
          'toEmail': recipientEmail,
          'name': studentName,
          'totalUnits': unitsVal.toStringAsFixed(1),
          'tuitionFee': "₱${NumberFormat('#,##0.00').format(tuitionVal)}",
          'labFee': "₱${NumberFormat('#,##0.00').format(labVal)}",
          'totalNetFees': "₱${NumberFormat('#,##0.00').format(totalVal)}",
          'documents': feeBreakdown,
        },
      );
    } catch (e) {
      debugPrint("❌ Edge Billing Dispatch Failure: $e");
    }
  }

  /// 🛰️ RELEASE ACTION: Save billing (Supports Batch)
  Future<void> _releaseAssessment() async {
    final List<String> profileIds = _selectedQueueIds.isNotEmpty
        ? _selectedQueueIds.toList()
        : [_activeStudent!['profile_id']];

    setState(() => _isLoading = true);

    try {
      for (String pId in profileIds) {
        // Resolve dynamic curriculum parameters individually per student
        final loadRes = await _service.client
            .from('study_loads')
            .select('*, subjects(*)')
            .eq('student_id', pId);
        final List studentLoads = loadRes as List;

        double studentUnits = studentLoads.fold(
            0.0,
            (sum, l) =>
                sum +
                (double.tryParse(l['subjects']['units'].toString()) ?? 0.0));

        double studentTuition =
            studentUnits * (double.tryParse(_tuitionRate.text) ?? 0.0);
        double studentTotal =
            studentTuition + _miscTotal + _otherTotal + _labTotal;

        final String breakdownJson = jsonEncode({
          'tuition': studentTuition,
          'misc_breakdown': _miscControllers.map((k, v) => MapEntry(k, v.text)),
          'other_breakdown':
              _otherControllers.map((k, v) => MapEntry(k, v.text)),
          'lab_fee': _labTotal,
          'installment_plan': {
            'downpayment': _downpayment.text,
            'periodic':
                ((studentTotal - (double.tryParse(_downpayment.text) ?? 0.0)) /
                        4.0)
                    .toStringAsFixed(2),
          }
        });

        // 1. Create Payment Record (Unpaid Enrollment Assessment)
        await _service.client.from('payments').insert({
          'student_id': pId,
          'amount': studentTotal,
          'amount_paid': 0.0, // Initial release always has zero payment
          'status': 'Unpaid',
          'payment_type': 'Enrollment Assessment',
          'remarks': breakdownJson,
        });

        // 2. Official Enrollment Handover
        await _service.client.from('student_details').update({
          'enrollment_status': 'Enrolled',
          'account_balance': studentTotal,
        }).eq('profile_id', pId);

        // 3. COMPILE DETAILED EMAIL INVOICE BREAKDOWN
        final matchedStudent = _queue.firstWhere((q) => q['profile_id'] == pId);
        final String recipientEmail =
            matchedStudent['profiles']['email'] ?? 'lustredarlene45@gmail.com';
        final String studentName =
            "${matchedStudent['profiles']['fn']} ${matchedStudent['profiles']['ln']}";

        final List<String> itemizedFeesList = [];
        itemizedFeesList.add(
            "Tuition Fee Base: ₱${NumberFormat('#,##0.00').format(studentTuition)} ($studentUnits Units @ ₱${_tuitionRate.text}/Unit)");
        if (_labTotal > 0) {
          itemizedFeesList.add(
              "Laboratory Matrix Fee: ₱${NumberFormat('#,##0.00').format(_labTotal)}");
        }

        // Itemize active Miscellaneous and other charges
        _miscControllers.forEach((k, v) {
          final val = double.tryParse(v.text) ?? 0.0;
          if (val > 0)
            itemizedFeesList
                .add("$k: ₱${NumberFormat('#,##0.00').format(val)}");
        });
        _otherControllers.forEach((k, v) {
          final val = double.tryParse(v.text) ?? 0.0;
          if (val > 0)
            itemizedFeesList
                .add("$k: ₱${NumberFormat('#,##0.00').format(val)}");
        });

        // 4. DISPATCH DETAILED BILLING STATEMENT VIA SUPABASE EDGE NODEMAILER
        _sendBillingEmailViaEdge(
          recipientEmail: recipientEmail,
          studentName: studentName,
          tuitionVal: studentTuition,
          labVal: _labTotal,
          totalVal: studentTotal,
          unitsVal: studentUnits,
          feeBreakdown: itemizedFeesList,
        );
      }

      _showToast(
          "Assessment approved & invoice statements sent to ${profileIds.length} Student(s).",
          success);
      setState(() {
        _activeStudent = null;
        _selectedQueueIds.clear();
        _activeLoads = [];
      });
      _fetchQueue();
    } catch (e) {
      _showToast("Release Error: $e", Colors.redAccent);
      setState(() => _isLoading = false);
    }
  }

  // --- TEMPLATE LOGIC ---
  void _saveCurrentAsTemplate() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F071D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Save Fee Template",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
              hintText: "Template Name (e.g., BSIT Regular)",
              hintStyle: TextStyle(color: Colors.white30)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL",
                  style: TextStyle(
                      color: Colors.blueGrey, fontWeight: FontWeight.bold))),
          ElevatedButton(
              onPressed: () {
                setState(() {
                  _savedTemplates.add({
                    'name': nameCtrl.text,
                    'tuitionRate': _tuitionRate.text,
                    'misc': _miscControllers.map((k, v) => MapEntry(k, v.text)),
                    'other':
                        _otherControllers.map((k, v) => MapEntry(k, v.text)),
                    'lab': _labFee.text,
                  });
                });
                Navigator.pop(context);
                _showToast("Template '${nameCtrl.text}' saved.", aViolet);
              },
              style: ElevatedButton.styleFrom(backgroundColor: aViolet),
              child: const Text("SAVE TEMPLATE",
                  style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _applyTemplate(Map<String, dynamic> template) {
    setState(() {
      _tuitionRate.text = template['tuitionRate'];
      _labFee.text = template['lab'];
      (template['misc'] as Map)
          .forEach((k, v) => _miscControllers[k]?.text = v.toString());
      (template['other'] as Map)
          .forEach((k, v) => _otherControllers[k]?.text = v.toString());
    });
    _showToast("Applied template: ${template['name']}", success);
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final cardColor = widget.isDarkMode ? surfaceDark : Colors.white;

    return Row(
      children: [
        // LEFT: ASSESSMENT QUEUE
        Container(
          width: 360,
          decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Colors.white10))),
          child: _buildQueue(textColor, cardColor),
        ),
        // RIGHT: BILLING WORKSPACE
        Expanded(
          child: _activeStudent == null && _selectedQueueIds.isEmpty
              ? _buildPlaceholder(textColor)
              : _buildBillingWorkspace(textColor, cardColor),
        ),
      ],
    );
  }

  Widget _buildQueue(Color text, Color card) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Billing Queue",
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      color: text,
                      fontSize: 24,
                      letterSpacing: -0.5)),
              if (_selectedQueueIds.isNotEmpty)
                _badge("${_selectedQueueIds.length} Selected", aViolet),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: aViolet))
              : ListView.builder(
                  itemCount: _queue.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, i) {
                    final s = _queue[i];
                    final isSelected = _activeStudent?['id'] == s['id'];
                    final isBatchSelected =
                        _selectedQueueIds.contains(s['profile_id']);

                    return CheckboxListTile(
                      value: isBatchSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val!) {
                            _selectedQueueIds.add(s['profile_id']);
                          } else {
                            _selectedQueueIds.remove(s['profile_id']);
                          }
                          if (_selectedQueueIds.isNotEmpty) {
                            _activeStudent = null;
                          }
                        });
                      },
                      selected: isSelected,
                      activeColor: aViolet,
                      title: InkWell(
                        onTap: () => _loadStudentContext(s),
                        child: Text(
                            "${s['profiles']['fn']} ${s['profiles']['ln']}"
                                .toUpperCase(),
                            style: TextStyle(
                                color: text,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ),
                      subtitle: Text(
                          "${s['courses']['code']} • ${s['year_levels']['definition']}",
                          style: const TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBillingWorkspace(Color text, Color card) {
    final bool isBatch = _selectedQueueIds.isNotEmpty;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(text, isBatch),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _sectionCard("TUITION CONFIGURATION", [
                _feeInput("Rate per Unit", _tuitionRate),
                const SizedBox(height: 20),
                if (!isBatch) ...[
                  _summaryRow("Calculated Units:", "$_totalUnits Units"),
                  _summaryRow("Tuition Subtotal:",
                      "₱${NumberFormat('#,##0.00').format(_tuitionTotal)}"),
                ] else
                  const Text(
                      "Units will be calculated individually per student in the queue.",
                      style: TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic)),
              ])),
              const SizedBox(width: 24),
              Expanded(
                  child: _sectionCard("SPECIAL FEES", [
                _feeInput("Laboratory Fees", _labFee),
                const SizedBox(height: 20),
                _templateMenu(text),
              ])),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _sectionCard("MISCELLANEOUS BREAKDOWN", [
                _buildGridInputs(_miscControllers),
                const Divider(height: 32, color: Colors.white10),
                _summaryRow("Misc Total Sum:",
                    "₱${NumberFormat('#,##0.00').format(_miscTotal)}",
                    isBold: true),
              ])),
              const SizedBox(width: 24),
              Expanded(
                  child: _sectionCard("OTHER FEES BREAKDOWN", [
                _buildGridInputs(_otherControllers),
                const Divider(height: 32, color: Colors.white10),
                _summaryRow("Other Total Sum:",
                    "₱${NumberFormat('#,##0.00').format(_otherTotal)}",
                    isBold: true),
              ])),
            ],
          ),
          const SizedBox(height: 32),
          _buildSummaryFooter(text),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 65,
            child: ElevatedButton.icon(
              onPressed: _releaseAssessment,
              icon: const Icon(Icons.verified_user_rounded, size: 22),
              label: Text(
                  isBatch
                      ? "BATCH RELEASE TO ${_selectedQueueIds.length} STUDENTS"
                      : "FINALIZE & RELEASE TO STUDENT PORTAL",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      fontSize: 15)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: success,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _templateMenu(Color text) {
    return PopupMenuButton<String>(
      onSelected: (val) {
        if (val == 'save') {
          _saveCurrentAsTemplate();
        } else {
          final t = _savedTemplates.firstWhere((e) => e['name'] == val);
          _applyTemplate(t);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
            color: aViolet.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: aViolet.withOpacity(0.3))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.copy_all_rounded, size: 18, color: aViolet),
            const SizedBox(width: 8),
            Text("FEE TEMPLATES",
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: aViolet,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
            value: 'save',
            child: Row(children: [
              Icon(Icons.save_rounded, size: 18, color: success),
              SizedBox(width: 8),
              Text("Save Current Settings",
                  style: TextStyle(fontWeight: FontWeight.bold))
            ])),
        const PopupMenuDivider(),
        if (_savedTemplates.isEmpty)
          const PopupMenuItem(
              enabled: false,
              child: Text("No saved templates",
                  style: TextStyle(color: Colors.grey))),
        ..._savedTemplates.map(
            (t) => PopupMenuItem(value: t['name'], child: Text(t['name']))),
      ],
    );
  }

  Widget _buildSummaryFooter(Color text) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: aViolet.withOpacity(0.3))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("CASH OPTION",
                    style: TextStyle(
                        color: aViolet,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1)),
                const SizedBox(height: 10),
                _summaryRow("Gross Total:",
                    "₱${NumberFormat('#,##0.00').format(_grandTotal)}"),
                _summaryRow("Prompt Discount:", "- ₱${_cashDiscount.text}"),
                _summaryRow("NET CASH DUE:",
                    "₱${NumberFormat('#,##0.00').format(_cashTotal)}",
                    isBold: true, color: success),
              ],
            ),
          ),
          const SizedBox(width: 48),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("INSTALLMENT PLAN",
                    style: TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1)),
                const SizedBox(height: 10),
                _summaryRow(
                    "Upon Registration Downpayment:", "₱${_downpayment.text}"),
                _summaryRow("Balance Outstanding (4 mos):",
                    "₱${NumberFormat('#,##0.00').format(_installmentBalance)}"),
                _summaryRow("PERIODIC MONTHLY DUE:",
                    "₱${NumberFormat('#,##0.00').format(_perInstallment)}",
                    isBold: true, color: Colors.orangeAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: widget.isDarkMode ? Colors.white10 : Colors.black12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.blueGrey,
                letterSpacing: 1.5)),
        const SizedBox(height: 20),
        ...children,
      ]),
    );
  }

  Widget _buildGridInputs(Map<String, TextEditingController> ctrls) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 4.8,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14),
      itemCount: ctrls.length,
      itemBuilder: (context, i) => _feeInput(
          ctrls.keys.elementAt(i), ctrls.values.elementAt(i),
          isSmall: true),
    );
  }

  Widget _feeInput(String label, TextEditingController ctrl,
      {bool isSmall = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      onChanged: (v) => setState(() {}),
      style: TextStyle(
          fontSize: isSmall ? 12 : 15,
          color: widget.isDarkMode ? Colors.white : Colors.black,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            color: Colors.blueGrey, fontSize: 11, fontWeight: FontWeight.bold),
        prefixText: "₱ ",
        isDense: true,
        filled: true,
        fillColor: Colors.white.withOpacity(0.02),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _summaryRow(String l, String v, {bool isBold = false, Color? color}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l,
                style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            Text(v,
                style: TextStyle(
                    color:
                        color ?? (widget.isDarkMode ? Colors.white : pViolet),
                    fontFamily: 'monospace',
                    fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
                    fontSize: isBold ? 17 : 14)),
          ],
        ),
      );

  Widget _buildHeader(Color text, bool isBatch) {
    if (isBatch) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Batch Assessment Mode",
              style: GoogleFonts.inter(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: text,
                  letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(
              "Processing ${_selectedQueueIds.length} students simultaneously with adaptive dynamic loading.",
              style: const TextStyle(
                  color: aViolet, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      );
    }
    return Row(
      children: [
        CircleAvatar(
            radius: 28,
            backgroundColor: aViolet,
            child: Text(_activeStudent!['profiles']['ln'][0],
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18))),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "${_activeStudent!['profiles']['fn']} ${_activeStudent!['profiles']['ln']}"
                    .toUpperCase(),
                style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: text,
                    letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text(
                "${_activeStudent!['courses']['name']} • Academic Session: 2025-2026",
                style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholder(Color text) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 80,
                color: widget.isDarkMode
                    ? text.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05)),
            const SizedBox(height: 20),
            const Text(
                "Select students from the queue to generate official billing assessments.",
                style: TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _badge(String t, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.withOpacity(0.2))),
      child: Text(t,
          style:
              TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)));

  void _showToast(String m, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          backgroundColor: c,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
}
