import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart'; // Changed from OpenFilePlus.open to OpenFile.open
import 'package:open_file/open_file.dart';
import '../../services/supabase_service.dart';

/// PAYROLL CALCULATION ENGINE (PH 2025 Standards)
/// Based on image_f191eb.png and image_f19264.png
class PHPayrollCalculator {
  static double calculateSSS(double gross) {
    // 2025 Rate: 4.5% Employee Share
    // MSC Capped at 35,000 (Based on SSS Circular 2024-006)
    double msc = gross > 35000 ? 35000 : (gross < 5000 ? 5000 : gross);
    return msc * 0.045;
  }

  static double calculatePhilHealth(double gross) {
    // 5% total share, 2.5% Employee Share. Floor: 10k, Ceiling: 100k
    double salary = gross.clamp(10000.0, 100000.0);
    return salary * 0.025;
  }

  static double calculatePagIBIG() {
    // Standard mandatory contribution capped at P200
    return 200.0;
  }

  static double calculateWithholdingTax(double taxableIncome) {
    double annual = taxableIncome * 12;
    double tax = 0;

    if (annual <= 250000) {
      tax = 0;
    } else if (annual <= 400000) {
      tax = (annual - 250000) * 0.20;
    } else if (annual <= 800000) {
      tax = 30000 + (annual - 400000) * 0.25;
    } else if (annual <= 2000000) {
      tax = 130000 + (annual - 800000) * 0.30;
    } else if (annual <= 8000000) {
      tax = 490000 + (annual - 2000000) * 0.32;
    } else {
      tax = 2400000 + (annual - 8000000) * 0.35;
    }
    return tax / 12;
  }
}

class AccountingPayrollManager extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const AccountingPayrollManager(
      {super.key, required this.isDarkMode, required this.userData});

  @override
  State<AccountingPayrollManager> createState() =>
      _AccountingPayrollManagerState();
}

class _AccountingPayrollManagerState extends State<AccountingPayrollManager> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _payrollLedger = [];
  bool _isLoading = true;
  final String _statusFilter = 'Active Staff';

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);

  @override
  void initState() {
    super.initState();
    _fetchAccountingData();
  }

  Future<void> _fetchAccountingData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final res = await _service.client
          .from('profiles')
          .select('*, employee_details(*)')
          .neq('role', 'student')
          .order('ln', ascending: true);
      if (mounted) {
        setState(() {
          _payrollLedger = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredLedger {
    return _payrollLedger.where((emp) {
      final name = "${emp['fn']} ${emp['ln']}".toLowerCase();
      final matchesSearch = name.contains(_searchController.text.toLowerCase());
      final isArchived =
          emp['employee_details']?['employment_status'] == 'Archived';
      return matchesSearch &&
          (_statusFilter == 'Archived' ? isArchived : !isArchived);
    }).toList();
  }

  Future<void> _issuePayslip(Map<String, dynamic> employee) async {
    final details = employee['employee_details'];
    final double base = (details?['base_salary'] ?? 0.0).toDouble();

    final sss = PHPayrollCalculator.calculateSSS(base);
    final phic = PHPayrollCalculator.calculatePhilHealth(base);
    final hdmf = PHPayrollCalculator.calculatePagIBIG();
    final taxable = base - (sss + phic + hdmf);
    final tax = PHPayrollCalculator.calculateWithholdingTax(taxable);

    final TextEditingController otController = TextEditingController(text: "0");
    final TextEditingController loanController = TextEditingController(
        text: (details?['sss_loan_monthly'] ?? 0.0).toString());
    final TextEditingController lateController =
        TextEditingController(text: "0");

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1B4B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text("Process Official Payroll",
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _payrollSummaryRow(
                    "Staff", "${employee['fn']} ${employee['ln']}"),
                _payrollSummaryRow(
                    "Basic Pay", "₱${NumberFormat('#,###.00').format(base)}"),
                const Divider(color: Colors.white10, height: 32),
                _inputField(otController, "Overtime Pay (Earnings)"),
                const SizedBox(height: 12),
                _inputField(loanController, "SSS/Pag-IBIG Loans (Deductions)"),
                const SizedBox(height: 12),
                _inputField(lateController, "Minutes Late (Statistical)"),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL")),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _processPayrollEntry(
                  employee,
                  base,
                  sss,
                  phic,
                  hdmf,
                  tax,
                  double.tryParse(otController.text) ?? 0,
                  double.tryParse(loanController.text) ?? 0,
                  double.tryParse(lateController.text) ?? 0,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: aViolet),
              child: const Text("GENERATE RECEIPT"),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _processPayrollEntry(
      Map<String, dynamic> emp,
      double base,
      double sss,
      double phic,
      double hdmf,
      double tax,
      double ot,
      double loans,
      double lates) async {
    setState(() => _isLoading = true);
    try {
      double totalDeductions = sss + phic + hdmf + tax + loans;
      double net = base + ot - totalDeductions;

      await _generateAndSavePDF(
          emp, base, ot, sss, phic, hdmf, tax, loans, lates, net);
      _showToast("Official Receipt Generated Successfully.", success);
    } catch (e) {
      _showToast("Error: $e", Colors.redAccent);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// REPLICATED RECEIPT DESIGN FROM reference images
  Future<void> _generateAndSavePDF(
      Map<String, dynamic> emp,
      double base,
      double ot,
      double sss,
      double phic,
      double hdmf,
      double tax,
      double loans,
      double lates,
      double net) async {
    final pdf = pw.Document();
    final d = emp['employee_details'];
    const dateRange = "03/01/2025 - 03/15/2025";
    final payDate = DateFormat('MM/dd/yyyy').format(DateTime.now());

    // Load specialized fonts for the receipt look
    final monoFont = pw.Font.courier();
    final monoFontBold = pw.Font.courierBold();

    pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Container(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // --- INSTITUTIONAL HEADER ---
                  pw.Center(
                      child: pw.Text("BRIGHT FUTURE ACADEMY",
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 13))),
                  pw.Center(
                      child: pw.Text("COLLEGE DEPARTMENT",
                          style: const pw.TextStyle(fontSize: 10))),
                  pw.SizedBox(height: 20),

                  // --- METADATA SECTION ---
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                  "NAME: ${emp['ln'].toString().toUpperCase()}, ${emp['fn'].toString().toUpperCase()}",
                                  style: pw.TextStyle(
                                      font: monoFontBold, fontSize: 10)),
                              pw.Text(
                                  "POSITION: ${d?['position_title'] ?? 'N/A'}",
                                  style: pw.TextStyle(
                                      font: monoFont, fontSize: 9)),
                            ]),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text("PAYDATE: $payDate",
                                  style: pw.TextStyle(
                                      font: monoFont, fontSize: 9)),
                              pw.Text("PERIOD: $dateRange",
                                  style: pw.TextStyle(
                                      font: monoFont, fontSize: 9)),
                            ])
                      ]),
                  pw.SizedBox(height: 10),
                  pw.Divider(thickness: 1.2, color: PdfColors.black),

                  // --- DATA GRID ---
                  pw.Table(
                      border: pw.TableBorder.symmetric(
                          inside: const pw.BorderSide(
                              width: 0.5, color: PdfColors.grey400)),
                      children: [
                        // Header Titles
                        pw.TableRow(children: [
                          _tableLabel("EARNINGS", monoFontBold),
                          _tableLabel("DEDUCTIONS", monoFontBold),
                          _tableLabel("LOANS", monoFontBold),
                          _tableLabel("STATISTICAL", monoFontBold),
                        ]),
                        // Main Content Row
                        pw.TableRow(children: [
                          // Column 1: EARNINGS
                          _receiptCell([
                            ["REGULAR", base],
                            ["OVERTIME", ot],
                            ["13TH MONTH", 0.00],
                            ["ADJ.", 0.00],
                          ], monoFont),
                          // Column 2: DEDUCTIONS
                          _receiptCell([
                            ["TAX W/HELD", tax],
                            ["SSS PREM.", sss],
                            ["PHILHEALTH", phic],
                            ["HDMF", hdmf],
                          ], monoFont),
                          // Column 3: LOANS
                          _receiptCell([
                            ["SSS LOAN", loans],
                            ["HDMF LOAN", 0.00],
                            ["TOTAL LOAN", loans],
                          ], monoFont),
                          // Column 4: STATISTICAL
                          _receiptCell([
                            ["LATE (MINS)", lates],
                            ["OT HOURS", ot > 0 ? 8.0 : 0.0],
                            ["VL BAL", 15.0],
                            ["SL BAL", 15.0],
                          ], monoFont),
                        ]),
                      ]),
                  pw.Divider(thickness: 1.2, color: PdfColors.black),

                  // --- SUMMARY SECTION ---
                  pw.SizedBox(height: 10),
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                            "TOTAL EARNINGS: ${NumberFormat('#,###.00').format(base + ot)}",
                            style: pw.TextStyle(font: monoFont, fontSize: 10)),
                        pw.Text(
                            "TOTAL DEDUCTIONS: ${NumberFormat('#,###.00').format(tax + sss + phic + hdmf + loans)}",
                            style: pw.TextStyle(font: monoFont, fontSize: 10)),
                      ]),
                  pw.SizedBox(height: 20),

                  // --- NET PAY BOX ---
                  pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration:
                          pw.BoxDecoration(border: pw.Border.all(width: 2)),
                      child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("NET TAKE-HOME PAY:",
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 12,
                                    font: monoFontBold)),
                            pw.Text(
                                "PHP ${NumberFormat('#,###.00').format(net)}",
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 13,
                                    font: monoFontBold)),
                          ])),

                  // --- ACKNOWLEDGEMENT TEXT ---
                  pw.SizedBox(height: 40),
                  pw.Text("RECEIPT FOR PAY",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    "I acknowledge to have received the amount of PHP ${NumberFormat('#,###.00').format(net)} in full payment of my salary for the period specified above, and have no further claims for services rendered.",
                    style: const pw.TextStyle(fontSize: 9),
                  ),

                  // --- SIGNATURE AREA ---
                  pw.Spacer(),
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Column(children: [
                          pw.Container(
                              width: 220,
                              decoration: const pw.BoxDecoration(
                                  border:
                                      pw.Border(top: pw.BorderSide(width: 1)))),
                          pw.SizedBox(height: 4),
                          pw.Text("${emp['fn']} ${emp['ln']}".toUpperCase(),
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10)),
                          pw.Text("Employee Signature / Date Received",
                              style: const pw.TextStyle(fontSize: 8)),
                        ])
                      ])
                ]))));

    final bytes = await pdf.save();
    final directory = await getApplicationDocumentsDirectory();
    final path =
        "${directory.path}/Payslip_${emp['ln']}_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final file = File(path);
    await file.writeAsBytes(bytes);
    await OpenFile.open(path);
  }

  pw.Widget _tableLabel(String text, pw.Font font) => pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text,
          style: pw.TextStyle(font: font, fontSize: 9),
          textAlign: pw.TextAlign.center));

  pw.Widget _receiptCell(List<List<dynamic>> items, pw.Font font) => pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Column(
          children: items
              .map((i) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                    child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("${i[0]}:",
                              style: pw.TextStyle(font: font, fontSize: 8)),
                          pw.Text(
                              "${i[1] is double ? i[1].toStringAsFixed(2) : i[1]}",
                              style: pw.TextStyle(font: font, fontSize: 8)),
                        ]),
                  ))
              .toList()));

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF1E1B4B);
    final cardColor =
        widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 32),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: aViolet))
                : _buildLedger(cardColor, textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color textColor) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Accounting Payroll Ledger",
            style: GoogleFonts.inter(
                fontSize: 28, fontWeight: FontWeight.w900, color: textColor)),
        const Text(
            "Generate official institutional receipts and manage disbursements.",
            style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
      ]);

  Widget _buildLedger(Color cardColor, Color textColor) {
    final list = _filteredLedger;
    return Container(
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: widget.isDarkMode
                  ? Colors.white10
                  : Colors.black.withOpacity(0.05))),
      child: Column(children: [
        _tableHeader(['ID', 'FULL NAME', 'POSITION', 'GROSS SALARY', 'ACTION']),
        Expanded(
            child: ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) =>
              const Divider(color: Colors.white10, height: 1),
          itemBuilder: (context, i) {
            final emp = list[i];
            final d = emp['employee_details'];
            return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(children: [
                  Expanded(
                      child: Text(emp['user_id_number'] ?? '---',
                          style: const TextStyle(color: Colors.blueGrey))),
                  Expanded(
                      flex: 2,
                      child: Text("${emp['fn']} ${emp['ln']}",
                          style: TextStyle(
                              color: textColor, fontWeight: FontWeight.bold))),
                  Expanded(
                      child: Text(d?['position_title'] ?? 'N/A',
                          style: const TextStyle(
                              color: Colors.blueGrey, fontSize: 11))),
                  Expanded(
                      child: Text(
                          "₱${NumberFormat('#,###').format(d?['base_salary'] ?? 0)}",
                          style: GoogleFonts.orbitron(
                              fontSize: 12,
                              color: success,
                              fontWeight: FontWeight.bold))),
                  Expanded(
                      child: Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                              icon: const Icon(LucideIcons.filePlus,
                                  color: aViolet),
                              onPressed: () => _issuePayslip(emp)))),
                ]));
          },
        )),
      ]),
    );
  }

  Widget _tableHeader(List<String> titles) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
          color: widget.isDarkMode
              ? Colors.white.withOpacity(0.02)
              : const Color(0xFFF8FAFC),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Row(
          children: titles
              .map((t) => Expanded(
                  flex: t == 'FULL NAME' ? 2 : 1,
                  child: Text(t,
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.blueGrey,
                          letterSpacing: 1.2))))
              .toList()));

  Widget _inputField(TextEditingController c, String l) => TextFormField(
      controller: c,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
          labelText: l,
          labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 12),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none)));

  Widget _payrollSummaryRow(String l, String v) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l, style: const TextStyle(color: Colors.blueGrey, fontSize: 11)),
        Text(v,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))
      ]));

  void _showToast(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating));
  }
}
