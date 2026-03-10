import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';

class PromissoryNotePanel extends StatefulWidget {
  final bool isDarkMode;
  const PromissoryNotePanel({super.key, required this.isDarkMode});

  @override
  State<PromissoryNotePanel> createState() => _PromissoryNotePanelState();
}

class _PromissoryNotePanelState extends State<PromissoryNotePanel> {
  // Theme Colors
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);

  // Form Controllers
  final TextEditingController _borrowerNameController = TextEditingController();
  final TextEditingController _borrowerAddressController =
      TextEditingController();
  final TextEditingController _lenderNameController = TextEditingController();
  final TextEditingController _lenderAddressController =
      TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _amountWordsController = TextEditingController();
  final TextEditingController _interestRateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime? _issueDate;
  DateTime? _dueDate;
  String _paymentTerms = 'On Demand';
  String _interestType = 'Simple Interest';
  bool _securedNote = false;
  bool _showPreview = false;

  @override
  void dispose() {
    _borrowerNameController.dispose();
    _borrowerAddressController.dispose();
    _lenderNameController.dispose();
    _lenderAddressController.dispose();
    _amountController.dispose();
    _amountWordsController.dispose();
    _interestRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _convertToWords(double amount) {
    final ones = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
    ];
    final teens = [
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];
    final tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    int whole = amount.toInt();
    int cents = ((amount - whole) * 100).toInt();

    String convertHundreds(int num) {
      String result = '';
      int hundreds = num ~/ 100;
      int remainder = num % 100;

      if (hundreds > 0) {
        result += '${ones[hundreds]} Hundred ';
      }

      if (remainder >= 20) {
        result += '${tens[remainder ~/ 10]} ';
        if (remainder % 10 > 0) {
          result += '${ones[remainder % 10]} ';
        }
      } else if (remainder >= 10) {
        result += '${teens[remainder - 10]} ';
      } else if (remainder > 0) {
        result += '${ones[remainder]} ';
      }

      return result.trim();
    }

    String words = '';
    if (whole == 0) {
      words = 'Zero';
    } else {
      int millions = whole ~/ 1000000;
      int thousands = (whole % 1000000) ~/ 1000;
      int remainder = whole % 1000;

      if (millions > 0) {
        words += '${convertHundreds(millions)} Million ';
      }
      if (thousands > 0) {
        words += '${convertHundreds(thousands)} Thousand ';
      }
      if (remainder > 0) {
        words += convertHundreds(remainder);
      }
    }

    words = '${words.trim()} Pesos';
    if (cents > 0) {
      words += ' and $cents Centavos';
    }

    return words;
  }

  void _updateAmountWords() {
    if (_amountController.text.isNotEmpty) {
      try {
        double amount = double.parse(_amountController.text);
        _amountWordsController.text = _convertToWords(amount);
      } catch (e) {
        _amountWordsController.text = '';
      }
    }
  }

  Future<void> _generatePDF() async {
    if (_borrowerNameController.text.isEmpty ||
        _lenderNameController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _issueDate == null ||
        _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    'PROMISSORY NOTE',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Document Details
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'NOTE DETAILS',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Issue Date: ${DateFormat('MMMM dd, yyyy').format(_issueDate!)}',
                                style: pw.TextStyle(fontSize: 10),
                              ),
                              pw.Text(
                                'Payment Terms: $_paymentTerms',
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Due Date: ${DateFormat('MMMM dd, yyyy').format(_dueDate!)}',
                                style: pw.TextStyle(fontSize: 10),
                              ),
                              pw.Text(
                                'Interest: ${_interestRateController.text}% $_interestType',
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Main Promise Paragraph
                pw.Text(
                  'It is hereby promised and agreed that I, the undersigned, promise to pay unconditionally to:',
                  style: pw.TextStyle(fontSize: 11),
                ),
                pw.SizedBox(height: 12),

                // Payee Section
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(left: const pw.BorderSide(width: 3)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PAYEE (LENDER)',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        _lenderNameController.text,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _lenderAddressController.text,
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Amount Section
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 1.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PRINCIPAL AMOUNT',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('PHP ', style: pw.TextStyle(fontSize: 11)),
                          pw.Expanded(
                            child: pw.Text(
                              _amountController.text,
                              style: pw.TextStyle(
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.Divider(),
                      pw.Text(
                        '(${_amountWordsController.text})',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Payment Terms Section
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PAYMENT TERMS',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'The undersigned agrees to pay the above principal amount in full on or before ${DateFormat('MMMM dd, yyyy').format(_dueDate!)}.',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                      if (_interestRateController.text.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 8),
                          child: pw.Text(
                            'Interest Rate: ${_interestRateController.text}% per annum ($_interestType)',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      if (_securedNote)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 8),
                          child: pw.Text(
                            'This note is secured by collateral as described herein.',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                ),

                if (_notesController.text.isNotEmpty) ...[
                  pw.SizedBox(height: 20),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 0.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ADDITIONAL TERMS & CONDITIONS',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          _notesController.text,
                          style: pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],

                pw.Spacer(),

                // Signature Section
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.SizedBox(height: 40),
                        pw.Container(
                          width: 150,
                          height: 1,
                          color: PdfColors.black,
                        ),
                        pw.Text(
                          _borrowerNameController.text,
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'MAKER (BORROWER)',
                          style: pw.TextStyle(fontSize: 9),
                        ),
                        pw.Text(
                          'Date: ${DateFormat('MM/dd/yyyy').format(_issueDate!)}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.SizedBox(height: 40),
                        pw.Container(
                          width: 150,
                          height: 1,
                          color: PdfColors.black,
                        ),
                        pw.Text(
                          _lenderNameController.text,
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'PAYEE (LENDER)',
                          style: pw.TextStyle(fontSize: 9),
                        ),
                        pw.Text(
                          'Date: ${DateFormat('MM/dd/yyyy').format(_issueDate!)}',
                          style: pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Save and open PDF
      final output = await getApplicationDocumentsDirectory();
      final fileName =
          'PromissoryNote_${_borrowerNameController.text.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved: $fileName'),
            backgroundColor: success,
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => OpenFile.open(file.path),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _printPreview() {
    setState(() => _showPreview = true);
    // Switch to Preview & Print tab
    DefaultTabController.of(context).animateTo(1);
  }

  void _clearForm() {
    _borrowerNameController.clear();
    _borrowerAddressController.clear();
    _lenderNameController.clear();
    _lenderAddressController.clear();
    _amountController.clear();
    _amountWordsController.clear();
    _interestRateController.clear();
    _notesController.clear();
    setState(() {
      _issueDate = null;
      _dueDate = null;
      _paymentTerms = 'On Demand';
      _interestType = 'Simple Interest';
      _securedNote = false;
      _showPreview = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? surfaceDark : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color:
                      widget.isDarkMode ? Colors.white12 : Colors.grey.shade200,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: aViolet.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(LucideIcons.fileText, color: aViolet),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Promissory Note / Print',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      'Create and print professional promissory notes',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDarkMode
                            ? Colors.white54
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // TabBar
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color:
                      widget.isDarkMode ? Colors.white12 : Colors.grey.shade200,
                ),
              ),
            ),
            child: TabBar(
              labelColor: aViolet,
              unselectedLabelColor:
                  widget.isDarkMode ? Colors.white54 : Colors.grey,
              indicatorColor: aViolet,
              tabs: const [
                Tab(
                  icon: Icon(LucideIcons.edit),
                  text: 'Create Note',
                  height: 50,
                ),
                Tab(
                  icon: Icon(LucideIcons.eye),
                  text: 'Preview & Print',
                  height: 50,
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              children: [
                // Tab 1: Create Note
                _buildCreateNoteTab(),
                // Tab 2: Preview & Print
                _buildPreviewTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateNoteTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Borrower Section
          _buildSectionCard(
            title: 'Borrower Information',
            icon: LucideIcons.user,
            child: Column(
              children: [
                _buildTextField(
                  label: 'Full Name *',
                  controller: _borrowerNameController,
                  hint: 'Enter borrower full name',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Address *',
                  controller: _borrowerAddressController,
                  hint: 'Enter complete address',
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Lender Section
          _buildSectionCard(
            title: 'Lender Information',
            icon: LucideIcons.building,
            child: Column(
              children: [
                _buildTextField(
                  label: 'Full Name *',
                  controller: _lenderNameController,
                  hint: 'Enter lender full name',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Address *',
                  controller: _lenderAddressController,
                  hint: 'Enter complete address',
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Amount Section
          _buildSectionCard(
            title: 'Principal Amount',
            icon: LucideIcons.dollarSign,
            child: Column(
              children: [
                _buildTextField(
                  label: 'Amount (PHP) *',
                  controller: _amountController,
                  hint: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => _updateAmountWords(),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Amount in Words *',
                  controller: _amountWordsController,
                  hint: 'Auto-generated',
                  readOnly: true,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Dates Section
          _buildSectionCard(
            title: 'Important Dates',
            icon: LucideIcons.calendar,
            child: Column(
              children: [
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _issueDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _issueDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: widget.isDarkMode
                            ? Colors.white24
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.calendar, size: 18, color: aViolet),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Issue Date *',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.isDarkMode
                                      ? Colors.white54
                                      : Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                _issueDate == null
                                    ? 'Select date'
                                    : DateFormat(
                                        'MMMM dd, yyyy',
                                      ).format(_issueDate!),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: widget.isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _dueDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _dueDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: widget.isDarkMode
                            ? Colors.white24
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.calendar, size: 18, color: aViolet),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Due Date *',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.isDarkMode
                                      ? Colors.white54
                                      : Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                _dueDate == null
                                    ? 'Select date'
                                    : DateFormat(
                                        'MMMM dd, yyyy',
                                      ).format(_dueDate!),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: widget.isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Payment Terms Section
          _buildSectionCard(
            title: 'Payment Terms',
            icon: LucideIcons.fileText,
            child: Column(
              children: [
                _buildDropdown(
                  label: 'Payment Terms *',
                  value: _paymentTerms,
                  items: [
                    'On Demand',
                    'Within 30 Days',
                    'Within 60 Days',
                    'Within 90 Days',
                    'Custom',
                  ],
                  onChanged: (value) =>
                      setState(() => _paymentTerms = value ?? 'On Demand'),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Interest Rate (%) *',
                  controller: _interestRateController,
                  hint: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Interest Type *',
                  value: _interestType,
                  items: ['Simple Interest', 'Compound Interest'],
                  onChanged: (value) => setState(
                    () => _interestType = value ?? 'Simple Interest',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Additional Options
          _buildSectionCard(
            title: 'Additional Options',
            icon: LucideIcons.settings,
            child: Column(
              children: [
                CheckboxListTile(
                  value: _securedNote,
                  onChanged: (value) => setState(() => _securedNote = value!),
                  title: const Text('This is a Secured Note'),
                  subtitle: const Text(
                    'Check if the note is backed by collateral',
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Additional Terms & Conditions',
                  controller: _notesController,
                  hint: 'Enter any additional terms...',
                  maxLines: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _clearForm,
                icon: Icon(LucideIcons.rotateCcw),
                label: const Text('Clear Form'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _printPreview,
                icon: Icon(LucideIcons.eye),
                label: const Text('View Preview'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: aViolet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTab() {
    if (!_showPreview) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.eyeOff, size: 64, color: aViolet.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No Preview Available',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fill in the form and click "View Preview" to see the promissory note',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    widget.isDarkMode ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Preview Document
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Text(
                    'PROMISSORY NOTE',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Details Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NOTE DETAILS',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Issue Date: ${_issueDate == null ? 'Not selected' : DateFormat('MMMM dd, yyyy').format(_issueDate!)}',
                                style: const TextStyle(fontSize: 10),
                              ),
                              Text(
                                'Payment Terms: $_paymentTerms',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Due Date: ${_dueDate == null ? 'Not selected' : DateFormat('MMMM dd, yyyy').format(_dueDate!)}',
                                style: const TextStyle(fontSize: 10),
                              ),
                              Text(
                                'Interest: ${_interestRateController.text}% $_interestType',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Promise Text
                Text(
                  'It is hereby promised and agreed that I, the undersigned, promise to pay unconditionally to:',
                  style: const TextStyle(fontSize: 11, height: 1.6),
                ),
                const SizedBox(height: 12),

                // Payee Box
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: aViolet, width: 3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PAYEE (LENDER)',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _lenderNameController.text.isEmpty
                            ? '[Lender Name]'
                            : _lenderNameController.text,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _lenderAddressController.text.isEmpty
                            ? '[Lender Address]'
                            : _lenderAddressController.text,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Amount Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PRINCIPAL AMOUNT',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PHP ', style: TextStyle(fontSize: 11)),
                          Expanded(
                            child: Text(
                              _amountController.text.isEmpty
                                  ? '0.00'
                                  : _amountController.text,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(color: Colors.grey.shade400),
                      Text(
                        '(${_amountWordsController.text.isEmpty ? '[Amount in words]' : _amountWordsController.text})',
                        style: const TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Terms Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PAYMENT TERMS',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The undersigned agrees to pay the above principal amount in full on or before ${_dueDate == null ? '[Due Date]' : DateFormat('MMMM dd, yyyy').format(_dueDate!)}.',
                        style: const TextStyle(fontSize: 10, height: 1.5),
                      ),
                      if (_interestRateController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Interest Rate: ${_interestRateController.text}% per annum ($_interestType)',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                      if (_securedNote) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'This note is secured by collateral as described herein.',
                          style: TextStyle(fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                ),

                if (_notesController.text.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ADDITIONAL TERMS & CONDITIONS',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _notesController.text,
                          style: const TextStyle(fontSize: 10, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // Signature Lines
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 150,
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade400,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _borrowerNameController.text.isEmpty
                              ? '[Borrower Signature]'
                              : _borrowerNameController.text,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'MAKER (BORROWER)',
                          style: TextStyle(fontSize: 9),
                        ),
                        Text(
                          'Date: ${_issueDate == null ? '__________' : DateFormat('MM/dd/yyyy').format(_issueDate!)}',
                          style: const TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 150,
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade400,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _lenderNameController.text.isEmpty
                              ? '[Lender Signature]'
                              : _lenderNameController.text,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'PAYEE (LENDER)',
                          style: TextStyle(fontSize: 9),
                        ),
                        Text(
                          'Date: ${_issueDate == null ? '__________' : DateFormat('MM/dd/yyyy').format(_issueDate!)}',
                          style: const TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Print Button
          ElevatedButton.icon(
            onPressed: _generatePDF,
            icon: Icon(LucideIcons.printer),
            label: const Text('Generate & Print PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: success,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDarkMode ? pViolet : Colors.blue.shade50,
        border: Border.all(
          color: widget.isDarkMode ? Colors.white12 : Colors.blue.shade200,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: aViolet, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: widget.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          onChanged: onChanged,
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: widget.isDarkMode ? Colors.white38 : Colors.grey.shade500,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color:
                    widget.isDarkMode ? Colors.white24 : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color:
                    widget.isDarkMode ? Colors.white24 : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: aViolet, width: 2),
            ),
            filled: true,
            fillColor: widget.isDarkMode ? surfaceDark : Colors.white,
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: widget.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.isDarkMode ? Colors.white24 : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButton<String>(
            value: value,
            items: items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: onChanged,
            isExpanded: true,
            underline: const SizedBox(),
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black,
            ),
            dropdownColor: widget.isDarkMode ? surfaceDark : Colors.white,
          ),
        ),
      ],
    );
  }
}
