import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/supabase_service.dart';

class TuitionAssessmentPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const TuitionAssessmentPanel(
      {super.key, required this.isDarkMode, required this.userData});

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

  /// 🛰️ RELEASE ACTION: Save billing (Supports Batch)
  Future<void> _releaseAssessment() async {
    final List<String> profileIds = _selectedQueueIds.isNotEmpty
        ? _selectedQueueIds.toList()
        : [_activeStudent!['profile_id']];

    setState(() => _isLoading = true);

    try {
      for (String pId in profileIds) {
        // Create the breakdown object
        final String breakdownJson = jsonEncode({
          'tuition': _tuitionTotal,
          'misc_breakdown': _miscControllers.map((k, v) => MapEntry(k, v.text)),
          'other_breakdown':
              _otherControllers.map((k, v) => MapEntry(k, v.text)),
          'lab_fee': _labTotal,
          'installment_plan': {
            'downpayment': _downpayment.text,
            'periodic': _perInstallment.toStringAsFixed(2),
          }
        });

        // 1. Create Payment Record
        // FIX: Added 'amount_paid': 0.0 to satisfy the NOT NULL constraint in the database.
        // We are using 'amount' for the total billable and 'amount_paid' for tracked collections.
        await _service.client.from('payments').insert({
          'student_id': pId,
          'amount': _grandTotal,
          'amount_paid': 0.0, // Initial release always has zero payment
          'status': 'Unpaid',
          'payment_type': 'Enrollment Assessment',
          'remarks': breakdownJson,
        });

        // 2. Official Enrollment Handover
        await _service.client.from('student_details').update({
          'enrollment_status': 'Enrolled',
          'account_balance': _grandTotal,
        }).eq('profile_id', pId);
      }

      _showToast(
          "Assessment Released for ${profileIds.length} Student(s).", success);
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
        backgroundColor: surfaceDark,
        title: const Text("Save Fee Template",
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
              hintText: "Template Name (e.g., BSIT Regular)"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL")),
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
              child: const Text("SAVE")),
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
          width: 340,
          decoration: BoxDecoration(
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
                      fontWeight: FontWeight.w900, color: text, fontSize: 22)),
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
                          if (val!)
                            _selectedQueueIds.add(s['profile_id']);
                          else
                            _selectedQueueIds.remove(s['profile_id']);
                          if (_selectedQueueIds.isNotEmpty)
                            _activeStudent = null;
                        });
                      },
                      selected: isSelected,
                      activeColor: aViolet,
                      title: InkWell(
                        onTap: () => _loadStudentContext(s),
                        child: Text(
                            "${s['profiles']['fn']} ${s['profiles']['ln']}",
                            style: TextStyle(
                                color: text,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                      subtitle: Text(
                          "${s['courses']['code']} • ${s['year_levels']['definition']}",
                          style: const TextStyle(
                              color: Colors.blueGrey, fontSize: 10)),
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
                const SizedBox(height: 16),
                if (!isBatch) ...[
                  _summaryRow("Calculated Units:", "$_totalUnits Units"),
                  _summaryRow("Tuition Subtotal:",
                      "₱${_tuitionTotal.toStringAsFixed(2)}"),
                ] else
                  const Text(
                      "Units will be calculated individually per student.",
                      style: TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 11,
                          fontStyle: FontStyle.italic)),
              ])),
              const SizedBox(width: 24),
              Expanded(
                  child: _sectionCard("SPECIAL FEES", [
                _feeInput("Laboratory Fees", _labFee),
                const SizedBox(height: 16),
                _templateMenu(text),
              ])),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _sectionCard("MISCELLANEOUS BREAKDOWN", [
                _buildGridInputs(_miscControllers),
                const Divider(height: 32, color: Colors.white10),
                _summaryRow("Misc Total:", "₱${_miscTotal.toStringAsFixed(2)}",
                    isBold: true),
              ])),
              const SizedBox(width: 24),
              Expanded(
                  child: _sectionCard("OTHER FEES BREAKDOWN", [
                _buildGridInputs(_otherControllers),
                const Divider(height: 32, color: Colors.white10),
                _summaryRow(
                    "Other Total:", "₱${_otherTotal.toStringAsFixed(2)}",
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
              icon: const Icon(LucideIcons.shieldCheck),
              label: Text(
                  isBatch
                      ? "BATCH RELEASE TO ${_selectedQueueIds.length} STUDENTS"
                      : "FINALIZE & RELEASE TO STUDENT PORTAL",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: success,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _templateMenu(Color text) {
    return PopupMenuButton<String>(
      onSelected: (val) {
        if (val == 'save')
          _saveCurrentAsTemplate();
        else {
          final t = _savedTemplates.firstWhere((e) => e['name'] == val);
          _applyTemplate(t);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: aViolet.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: aViolet.withOpacity(0.3))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.copy, size: 16, color: aViolet),
            const SizedBox(width: 8),
            Text("FEE TEMPLATES",
                style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.bold, color: aViolet)),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
            value: 'save',
            child: Row(children: [
              Icon(LucideIcons.save, size: 16),
              SizedBox(width: 8),
              Text("Save Current Settings")
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
                        fontSize: 10)),
                _summaryRow(
                    "Gross Total:", "₱${_grandTotal.toStringAsFixed(2)}"),
                _summaryRow("Prompt Discount:", "- ₱${_cashDiscount.text}"),
                _summaryRow(
                    "NET CASH DUE:", "₱${_cashTotal.toStringAsFixed(2)}",
                    isBold: true, color: success),
              ],
            ),
          ),
          const VerticalDivider(width: 64, color: Colors.white10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("INSTALLMENT PLAN",
                    style: TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 10)),
                _summaryRow("Upon Registration:", "₱${_downpayment.text}"),
                _summaryRow("Balance (4 mos):",
                    "₱${_installmentBalance.toStringAsFixed(2)}"),
                _summaryRow(
                    "PERIODIC DUE:", "₱${_perInstallment.toStringAsFixed(2)}",
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 10,
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
          childAspectRatio: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12),
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
          fontSize: isSmall ? 11 : 14, // Keep font size
          color: widget.isDarkMode ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 10),
        prefixText: "₱ ",
        isDense: true,
        filled: true,
        fillColor: Colors.white.withOpacity(0.02),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
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
                style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
            Text(v,
                style: TextStyle(
                    color: color ?? Colors.white,
                    fontWeight: isBold ? FontWeight.w900 : FontWeight.normal,
                    fontSize: isBold ? 16 : 13)),
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
                  fontSize: 22, fontWeight: FontWeight.w900, color: text)),
          Text(
              "Processing ${_selectedQueueIds.length} students simultaneously.",
              style:
                  const TextStyle(color: aViolet, fontWeight: FontWeight.bold)),
        ],
      );
    }
    return Row(
      children: [
        CircleAvatar(
            radius: 24,
            backgroundColor: aViolet,
            child: Text(_activeStudent!['profiles']['ln'][0],
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold))),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "${_activeStudent!['profiles']['fn']} ${_activeStudent!['profiles']['ln']}",
                style: GoogleFonts.inter(
                    fontSize: 22, fontWeight: FontWeight.w900, color: text)),
            Text("${_activeStudent!['courses']['name']} • SY 2025-2026",
                style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholder(Color text) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.receipt, // Ensure visibility in light mode
                size: 80,
                color: widget.isDarkMode ? text.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
            const SizedBox(height: 16),
            const Text("Select students from the queue to generate billing.",
                style: TextStyle(color: Colors.blueGrey)),
          ],
        ),
      );

  Widget _badge(String t, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(t,
          style:
              TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.bold)));

  void _showToast(String m, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m),
          backgroundColor: c,
          behavior: SnackBarBehavior.floating));
}
