import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

class PromissoryNotePanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const PromissoryNotePanel({
    super.key,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  State<PromissoryNotePanel> createState() => _PromissoryNotePanelState();
}

class _PromissoryNotePanelState extends State<PromissoryNotePanel> {
  final SupabaseService _service = SupabaseService();

  // Institutional Palette
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);

  // Form Controllers
  final TextEditingController _studentIdSearch = TextEditingController();
  final TextEditingController _borrowerNameController = TextEditingController();
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _courseYearController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _amountWordsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  Map<String, dynamic>? _selectedStudent;
  DateTime? _issueDate = DateTime.now();
  DateTime? _dueDate;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _dueDate = DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _studentIdSearch.dispose();
    _borrowerNameController.dispose();
    _parentNameController.dispose();
    _courseYearController.dispose();
    _amountController.dispose();
    _amountWordsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// 🛰️ DATABASE: Resolves student identity and academic program
  Future<void> _fetchStudentForNote() async {
    final id = _studentIdSearch.text.trim();
    if (id.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final res = await _service.client
          .from('profiles')
          .select(
              '*, student_details(*, courses(name), year_levels(definition))')
          .ilike('user_id_number', id)
          .maybeSingle();

      if (res != null) {
        final details = res['student_details'];
        setState(() {
          _selectedStudent = res;
          _borrowerNameController.text =
              "${res['fn']} ${res['ln']}".toUpperCase();
          _courseYearController.text =
              "${details['courses']?['name'] ?? 'N/A'} - ${details['year_levels']?['definition'] ?? 'N/A'}";
          _amountController.text =
              (details?['account_balance'] ?? 0).toString();
          _updateAmountWords();
        });
      } else {
        _showToast("Student not found.", Colors.orangeAccent);
      }
    } catch (e) {
      _showToast("Search failed.", Colors.redAccent);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🛰️ DATABASE: Commits the note and issues the Official PDF
  Future<void> _commitNoteToLedger() async {
    if (_selectedStudent == null || _amountController.text.isEmpty) {
      _showToast("Please identify a student and amount.", Colors.orangeAccent);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final String refNo =
          "PN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

      await _service.client.from('office_requests').insert({
        'student_id': _selectedStudent!['id'],
        'request_type': 'Promissory Note',
        'request_status': 'Approved',
        'amount_due': double.tryParse(_amountController.text) ?? 0.0,
        'due_date': _dueDate?.toIso8601String(),
        'qr_hash': refNo,
        'processed_by': widget.userData['id'],
        'remarks':
            'Issued Grace Period until ${DateFormat('MMMM dd, yyyy').format(_dueDate!)}. Parent: ${_parentNameController.text}',
      });

      await _generateProfessionalPDF(refNo);

      _showToast("Promissory Note Logged & PDF Generated", success);
      _clearForm();
    } catch (e) {
      _showToast("Ledger Error: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _updateAmountWords() {
    if (_amountController.text.isNotEmpty) {
      try {
        double amount = double.parse(_amountController.text);
        int whole = amount.toInt();
        int cents = ((amount - whole) * 100).toInt();
        _amountWordsController.text =
            "${whole.toString()} Pesos and $cents/100 Only";
      } catch (e) {
        _amountWordsController.text = '';
      }
    }
  }

  // --- 📄 PROFESSIONAL PDF RECONSTRUCTION ---

  Future<void> _generateProfessionalPDF(String refNo) async {
    final pdf = pw.Document();
    final dateIssued = DateFormat('MMMM dd, yyyy').format(_issueDate!);
    final dueDateStr = DateFormat('MMMM dd, yyyy').format(_dueDate!);
    final adminName =
        "${widget.userData['fn']} ${widget.userData['ln']}".toUpperCase();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Header / School Identification
              pw.Center(
                  child: pw.Text('BRIGHT FUTURE ACADEMY',
                      style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900))),
              pw.Center(
                  child: pw.Text('OFFICE OF THE ACCOUNTING',
                      style:
                          const pw.TextStyle(fontSize: 10, letterSpacing: 1))),
              pw.SizedBox(height: 12),
              pw.Center(
                  child: pw.Text('PROMISSORY NOTE',
                      style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          decoration: pw.TextDecoration.underline))),
              pw.SizedBox(height: 32),

              // 2. Reference Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Note Ref No.: $refNo",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text("Date Issued: $dateIssued",
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 32),

              // 3. Main Declaration (Debtor Info)
              pw.RichText(
                text: pw.TextSpan(
                  style: pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
                  children: [
                    const pw.TextSpan(text: "I, "),
                    pw.TextSpan(
                        text: _borrowerNameController.text,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    const pw.TextSpan(
                        text:
                            ", a student of Bright Future Academy with Student ID No. "),
                    pw.TextSpan(
                        text: _selectedStudent?['user_id_number'] ?? 'N/A',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    const pw.TextSpan(text: ", currently enrolled in "),
                    pw.TextSpan(
                        text: _courseYearController.text,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    const pw.TextSpan(
                        text:
                            ", hereby promise to pay to the order of the Office of the Comptroller the total amount of:"),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // 4. Amount Details
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.5)),
                child: pw.Column(
                  children: [
                    pw.Text("PHP ${_amountController.text}",
                        style: pw.TextStyle(
                            fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text("(${_amountWordsController.text})",
                        style: pw.TextStyle(
                            fontSize: 10, fontStyle: pw.FontStyle.italic)),
                  ],
                ),
              ),
              pw.SizedBox(height: 32),

              // 5. Payment Terms & Obligations
              pw.Text("Payment Terms:",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.SizedBox(height: 8),
              pw.Text(
                  "I agree to settle the above amount on or before $dueDateStr.",
                  style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 16),
              pw.Text("Failure to pay within the agreed period may result in:",
                  style: const pw.TextStyle(fontSize: 11)),
              pw.Bullet(
                  text: "Suspension of clearance processing",
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Bullet(
                  text:
                      "Withholding of academic records (TOR, Diploma, Certifications)",
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Bullet(
                  text: "Additional penalties as determined by the institution",
                  style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 24),

              pw.Text(
                "I hereby acknowledge my obligation and voluntarily commit to pay the stated amount under the terms and conditions set by Bright Future Academy.",
                style: pw.TextStyle(
                  fontSize: 11,
                  fontStyle: pw.FontStyle.italic,
                  height: 1.5,
                ),
                textAlign: pw.TextAlign.justify,
              ),

              pw.Spacer(),

              // 6. Triple Signature Section
              pw.Text("Signed:",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.SizedBox(height: 32),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Student Signature Block
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                          width: 180,
                          decoration: const pw.BoxDecoration(
                              border: pw.Border(top: pw.BorderSide(width: 1)))),
                      pw.Text("Student Name: ${_borrowerNameController.text}",
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text("Date Signed: _________________",
                          style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  // Parent/Guardian Signature Block
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                          width: 180,
                          decoration: const pw.BoxDecoration(
                              border: pw.Border(top: pw.BorderSide(width: 1)))),
                      pw.Text("Parent/Guardian: ${_parentNameController.text}",
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text("Date Signed: _________________",
                          style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),
              // School Representative Block
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                      width: 250,
                      decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(width: 1)))),
                  pw.Text("Authorized Representative: $adminName",
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Office: Office of the Comptroller",
                      style: const pw.TextStyle(fontSize: 8)),
                  pw.Text("Date: $dateIssued",
                      style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/Note_$refNo.pdf');
    await file.writeAsBytes(bytes);
    await OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : pViolet;
    final cardColor = widget.isDarkMode ? surfaceDark : Colors.white;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 32),
          _buildSearchSection(cardColor, textColor),
          const SizedBox(height: 24),
          if (_selectedStudent != null) ...[
            _buildMainForm(cardColor, textColor),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ] else
            _buildEmptyState(textColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Promissory Note Terminal",
              style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: t,
                  letterSpacing: -0.5)),
          const Text(
              "Official school version: Issue legally binding credit extensions for student tuition.",
              style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
        ],
      );

  Widget _buildSearchSection(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: widget.isDarkMode ? Colors.white10 : Colors.black12)),
      child: Row(
        children: [
          const Icon(LucideIcons.search, color: aViolet, size: 20),
          const SizedBox(width: 16),
          Expanded(
              child: TextField(
            controller: _studentIdSearch,
            onSubmitted: (_) => _fetchStudentForNote(),
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
                hintText: "Enter Student ID for Formal Note...",
                border: InputBorder.none),
          )),
          ElevatedButton(
              onPressed: _fetchStudentForNote,
              style: ElevatedButton.styleFrom(
                  backgroundColor: aViolet,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text("FETCH IDENTITY")),
        ],
      ),
    );
  }

  Widget _buildMainForm(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: aViolet.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("FORMAL OBLIGATION DATA",
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: aViolet,
                  letterSpacing: 1.5)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                  child: _buildTextField(
                      label: 'Maker (Student Name)',
                      controller: _borrowerNameController,
                      hint: '',
                      readOnly: true)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildTextField(
                      label: 'Parent/Guardian Full Name *',
                      controller: _parentNameController,
                      hint: 'Name for legal signature')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  flex: 2,
                  child: _buildTextField(
                      label: 'Program & Year Level',
                      controller: _courseYearController,
                      hint: '',
                      readOnly: true)),
              const SizedBox(width: 16),
              Expanded(
                  flex: 1,
                  child: _buildTextField(
                      label: 'Principal Amount (PHP)',
                      controller: _amountController,
                      hint: '0.00',
                      onChanged: (_) => _updateAmountWords())),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
              label: 'Amount in Words',
              controller: _amountWordsController,
              hint: 'Auto-generated...',
              readOnly: true),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                  child: _buildDateField("Date Issued", _issueDate,
                      (d) => setState(() => _issueDate = d))),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildDateField("Settlement Deadline (Due Date)",
                      _dueDate, (d) => setState(() => _dueDate = d))),
            ],
          ),
          const SizedBox(height: 24),
          _buildTextField(
              label: 'Institutional Remarks / Justification',
              controller: _notesController,
              hint: 'Context for final audit...',
              maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _commitNoteToLedger,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(LucideIcons.printer),
            label: const Text("GENERATE & PRINT PROMISSORY NOTE",
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
                backgroundColor: success,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 22),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: _clearForm,
          icon: const Icon(LucideIcons.rotateCcw),
          label: const Text("CANCEL"),
          style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))),
        ),
      ],
    );
  }

  Widget _buildTextField(
      {required String label,
      required TextEditingController controller,
      required String hint,
      bool readOnly = false,
      int maxLines = 1,
      ValueChanged<String>? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          onChanged: onChanged,
          style: TextStyle( // Ensure text is visible in both modes
              color: widget.isDarkMode ? Colors.white : Colors.black,
              fontSize: 14),
          decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: widget.isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.02),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none)),
        ),
      ],
    );
  }

  Widget _buildDateField(
      String label, DateTime? value, Function(DateTime) onPicked) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100));
        if (d != null) onPicked(d);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(LucideIcons.calendar, size: 16, color: aViolet),
              const SizedBox(width: 12),
              Text(
                  value == null
                      ? "Select Date"
                      : DateFormat('MM/dd/yyyy').format(value),
                  style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black)) // Ensure text is visible in both modes
            ]),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    setState(() {
      _selectedStudent = null;
      _borrowerNameController.clear();
      _parentNameController.clear();
      _courseYearController.clear();
      _amountController.clear();
      _amountWordsController.clear();
      _notesController.clear();
      _dueDate = DateTime.now().add(const Duration(days: 30));
    });
  }

  Widget _buildEmptyState(Color t) => Center(
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 100),
          child: Column(children: [
            Icon(LucideIcons.fileSignature,
                size: 64, color: t.withOpacity(0.05)),
            const SizedBox(height: 24),
            const Text(
                "Search a student to begin issuing a formal Promissory Note.",
                style: TextStyle(color: Colors.blueGrey))
          ])));

  void _showToast(String m, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m),
          backgroundColor: c,
          behavior: SnackBarBehavior.floating));
}
