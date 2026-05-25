import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../services/supabase_service.dart';

class AccountingAuditPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const AccountingAuditPanel({
    super.key,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  State<AccountingAuditPanel> createState() => _AccountingAuditPanelState();
}

class _AccountingAuditPanelState extends State<AccountingAuditPanel> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _searchController =
      _searchControllerField ?? TextEditingController();
  static final TextEditingController _searchControllerField =
      TextEditingController();

  List<Map<String, dynamic>> _ledger = [];
  bool _isLoading = true;
  String _selectedTypeFilter = 'ALL';
  String _selectedStatusFilter = 'ALL';
  Map<String, dynamic>? _selectedLedgerItem;

  // Modern Tonal Palette Constants
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color pViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color warning = Color(0xFFFFD740);
  static const Color danger = Color(0xFFFF5252);
  static const Color surfaceDark = Color(0xFF0F071D);
  static const Color cardDark = Color(0xFF1E1B4B);

  @override
  void initState() {
    super.initState();
    _fetchAuditLedger();
  }

  /// 🛰️ DATABASE: Fetches all transactions from the payments table joined with profiles
  Future<void> _fetchAuditLedger() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _selectedLedgerItem = null;
    });

    try {
      // Rule 2: Simple queries, avoiding complex database filtering/ordering to bypass index crashes
      final List<dynamic> response =
          await _service.client.from('payments').select('*, profiles(*)');

      final List<Map<String, dynamic>> parsedLedger =
          List<Map<String, dynamic>>.from(response);

      // Sort in memory (Rule 2 compliance)
      parsedLedger.sort((a, b) {
        final DateTime dateA =
            DateTime.tryParse(a['created_at']?.toString() ?? '') ??
                DateTime.now();
        final DateTime dateB =
            DateTime.tryParse(b['created_at']?.toString() ?? '') ??
                DateTime.now();
        return dateB.compareTo(dateA); // Descending (latest first)
      });

      if (mounted) {
        setState(() {
          _ledger = parsedLedger;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Ledger Audit Sync Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FINANCIAL CALCULATION MATRIX ---
  double get _totalAssessed => _filteredLedger.fold(0.0, (sum, item) {
        return sum +
            (double.tryParse(item['amount']?.toString() ?? "0.0") ?? 0.0);
      });

  double get _totalCollected => _filteredLedger.fold(0.0, (sum, item) {
        return sum +
            (double.tryParse(item['amount_paid']?.toString() ?? "0.0") ?? 0.0);
      });

  double get _totalReceivables => _totalAssessed - _totalCollected;

  /// --- MEMORY-BASED FILTERING ENGINE (Rule 2 Compliance) ---
  List<Map<String, dynamic>> get _filteredLedger {
    final query = _searchController.text.toLowerCase().trim();
    return _ledger.where((item) {
      final profile = item['profiles'] as Map<String, dynamic>?;
      if (profile == null) return false;

      final fn = (profile['fn'] ?? '').toString().toLowerCase();
      final ln = (profile['ln'] ?? '').toString().toLowerCase();
      final idNum = (profile['user_id_number'] ?? '').toString().toLowerCase();
      final type = (item['payment_type'] ?? '').toString();
      final status = (item['status'] ?? '').toString();

      // Dropdown filtration
      if (_selectedTypeFilter != 'ALL' && type != _selectedTypeFilter)
        return false;
      if (_selectedStatusFilter != 'ALL' && status != _selectedStatusFilter)
        return false;

      return fn.contains(query) || ln.contains(query) || idNum.contains(query);
    }).toList();
  }

  /// 📃 PDF EXPORT: Generates professional statement auditing report
  Future<void> _generatePDFReport() async {
    final pdf = pw.Document();
    final String timestamp =
        DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final String comptroller =
        "${widget.userData['fn'] ?? ''} ${widget.userData['ln'] ?? ''}";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (pw.Context context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("BRIGHT FUTURE ACADEMY",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16,
                          color: PdfColor.fromInt(0xFF7C3AED))),
                  pw.Text("Institutional Accounting & Audit System Node",
                      style: const pw.TextStyle(fontSize: 8)),
                ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text("OFFICIAL COMPTROLLER LEDGER",
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text("Session Date: $timestamp",
                  style: const pw.TextStyle(fontSize: 8)),
            ]),
          ],
        ),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                      "TOTAL BILLING: PHP ${NumberFormat('#,##0.00').format(_totalAssessed)}",
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                      "TOTAL COLLECTED: PHP ${NumberFormat('#,##0.00').format(_totalCollected)}",
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green)),
                  pw.Text(
                      "OUTSTANDING: PHP ${NumberFormat('#,##0.00').format(_totalReceivables)}",
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: [
                "DATE",
                "STUDENT ID",
                "FULL STUDENT NAME",
                "CATEGORY TYPE",
                "ASSESSED",
                "PAID",
                "STATUS"
              ],
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                  color: PdfColors.white),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColor.fromInt(0xFF7C3AED)),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellPadding: const pw.EdgeInsets.all(5),
              data: _filteredLedger.map((item) {
                final prof = item['profiles'] as Map<String, dynamic>? ?? {};
                final dateStr = item['created_at'] != null
                    ? DateFormat('MM/dd/yyyy')
                        .format(DateTime.parse(item['created_at']))
                    : 'N/A';
                return [
                  dateStr,
                  prof['user_id_number'] ?? 'N/A',
                  "${prof['fn'] ?? ''} ${prof['ln'] ?? ''}".toUpperCase(),
                  item['payment_type'] ?? 'N/A',
                  "P${NumberFormat('#,##0.00').format(item['amount'] ?? 0.0)}",
                  "P${NumberFormat('#,##0.00').format(item['amount_paid'] ?? 0.0)}",
                  (item['status'] ?? 'N/A').toString().toUpperCase(),
                ];
              }).toList(),
            ),
            pw.Spacer(),
            pw.Divider(color: PdfColors.grey300, thickness: 0.5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Audited and Signed By: $comptroller",
                    style: pw.TextStyle(
                        fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.Text("Page ${context.pageNumber} of ${context.pagesCount}",
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          ];
        },
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final file = File(
          "${dir.path}/BFA_Ledger_Audit_Report_${DateTime.now().millisecondsSinceEpoch}.pdf");
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      _showToast("Failed to compile Audit PDF: $e", Colors.redAccent);
    }
  }

  void _showToast(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : pViolet;
    final cardColor = widget.isDarkMode ? cardDark : Colors.white;

    return Scaffold(
      backgroundColor: widget.isDarkMode ? surfaceDark : Colors.grey.shade100,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT VIEWPORT: Central Audit Journal Table
          Expanded(
            flex: 7,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(textColor),
                  const SizedBox(height: 32),
                  _buildMetricGrid(textColor, cardColor),
                  const SizedBox(height: 32),
                  _buildFilters(cardColor, textColor),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(
                          child: Padding(
                              padding: EdgeInsets.all(80),
                              child: CircularProgressIndicator(color: aViolet)))
                      : _buildTable(cardColor, textColor),
                ],
              ),
            ),
          ),

          // RIGHT VIEWPORT: Interactive Detailed Audit Trail sidebar
          if (_selectedLedgerItem != null)
            Container(
              width: 420,
              decoration: BoxDecoration(
                color: cardColor,
                border: const Border(
                    left: BorderSide(color: Colors.white10, width: 1)),
              ),
              child: _buildDetailsSidebar(textColor),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color textColor) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Institutional Audit Journal",
                  style: GoogleFonts.inter(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: -1)),
              const SizedBox(height: 4),
              const Text(
                  "Review audited accounts, tuition releases, and payment transactions dynamically.",
                  style: TextStyle(color: Colors.blueGrey, fontSize: 16)),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _generatePDFReport,
            icon: const Icon(Icons.print_rounded, size: 20),
            label: const Text("GENERATE AUDIT REPORT",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: aViolet,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ],
      );

  Widget _buildMetricGrid(Color textColor, Color cardColor) {
    return LayoutBuilder(builder: (context, constraints) {
      double itemWidth = (constraints.maxWidth - 48) / 4;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _buildMetricCard("TOTAL BILLING ASSESSED", _totalAssessed,
              Icons.analytics_rounded, aViolet, itemWidth),
          _buildMetricCard("TOTAL CASH COLLECTED", _totalCollected,
              Icons.savings_rounded, success, itemWidth),
          _buildMetricCard("OUTSTANDING RECEIVABLES", _totalReceivables,
              Icons.warning_amber_rounded, warning, itemWidth),
          _buildMetricCard(
              "TRANSACTIONS AUDITED",
              _filteredLedger.length.toDouble(),
              Icons.receipt_long_rounded,
              Colors.blueAccent,
              itemWidth,
              isFormatCurrency: false),
        ],
      );
    });
  }

  Widget _buildMetricCard(
      String label, double val, IconData icon, Color color, double width,
      {bool isFormatCurrency = true}) {
    final numberVal = isFormatCurrency
        ? "₱${NumberFormat('#,##0.00').format(val)}"
        : val.toInt().toString();

    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color:
            widget.isDarkMode ? Colors.white.withOpacity(0.02) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(numberVal,
                    style: TextStyle(
                        color: widget.isDarkMode ? Colors.white : pViolet,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace')),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilters(Color bg, Color text) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: widget.isDarkMode ? Colors.white10 : Colors.black12)),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() {}),
                style: TextStyle(
                    color: text, fontSize: 15, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: "Search Student Name or ID...",
                  hintStyle:
                      const TextStyle(color: Colors.blueGrey, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: aViolet),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.02),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                value: _selectedTypeFilter,
                dropdownColor: widget.isDarkMode ? surfaceDark : Colors.white,
                style: TextStyle(
                    color: text, fontWeight: FontWeight.bold, fontSize: 13),
                decoration: _getDropdownDecoration("Filter Type"),
                items: [
                  const DropdownMenuItem(
                      value: 'ALL', child: Text("ALL TRANSACTION TYPES")),
                  const DropdownMenuItem(
                      value: 'Enrollment Assessment',
                      child: Text("ENROLLMENT ASSESSMENT")),
                  const DropdownMenuItem(
                      value: 'Registration Fee',
                      child: Text("REGISTRATION FEE")),
                ],
                onChanged: (v) => setState(() => _selectedTypeFilter = v!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                value: _selectedStatusFilter,
                dropdownColor: widget.isDarkMode ? surfaceDark : Colors.white,
                style: TextStyle(
                    color: text, fontWeight: FontWeight.bold, fontSize: 13),
                decoration: _getDropdownDecoration("Filter Status"),
                items: [
                  const DropdownMenuItem(
                      value: 'ALL', child: Text("ALL PAYMENT STATUS")),
                  const DropdownMenuItem(
                      value: 'Unpaid', child: Text("UNPAID LEDGER")),
                  const DropdownMenuItem(
                      value: 'Paid', child: Text("PAID LEDGER")),
                ],
                onChanged: (v) => setState(() => _selectedStatusFilter = v!),
              ),
            ),
          ],
        ),
      );

  InputDecoration _getDropdownDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            color: Colors.blueGrey, fontSize: 11, fontWeight: FontWeight.bold),
        filled: true,
        fillColor: Colors.white.withOpacity(0.02),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
      );

  Widget _buildTable(Color cardColor, Color textColor) {
    if (_filteredLedger.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Column(
            children: [
              Icon(Icons.folder_off_rounded,
                  size: 56, color: Colors.blueGrey.withOpacity(0.3)),
              const SizedBox(height: 16),
              const Text("No audited transactions match your filter criteria.",
                  style: TextStyle(
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.4),
          1: FlexColumnWidth(1.2),
          2: FlexColumnWidth(2.2),
          3: FlexColumnWidth(2.0),
          4: FlexColumnWidth(1.2),
          5: FlexColumnWidth(1.2),
          6: FlexColumnWidth(1.0),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
                color: aViolet.withOpacity(0.06),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24))),
            children: [
              _headerCell("AUDIT DATE"),
              _headerCell("STUDENT ID"),
              _headerCell("FULL NAME"),
              _headerCell("TRANSACTION CATEGORY"),
              _headerCell("ASSESSED"),
              _headerCell("COLLECTED"),
              _headerCell("STATUS"),
            ],
          ),
          ..._filteredLedger.map((item) {
            final prof = item['profiles'] as Map<String, dynamic>? ?? {};
            final dateStr = item['created_at'] != null
                ? DateFormat('MM/dd/yyyy HH:mm')
                    .format(DateTime.parse(item['created_at']))
                : 'N/A';
            final bool isSelected = _selectedLedgerItem == item;
            final double balance =
                (double.tryParse(item['amount']?.toString() ?? "0") ?? 0) -
                    (double.tryParse(item['amount_paid']?.toString() ?? "0") ??
                        0);

            return TableRow(
              decoration: BoxDecoration(
                color:
                    isSelected ? aViolet.withOpacity(0.08) : Colors.transparent,
                border: Border(
                    bottom: BorderSide(
                        color: widget.isDarkMode
                            ? Colors.white10
                            : Colors.grey.shade200)),
              ),
              children: [
                _dataCell(dateStr, textColor, isSmall: true),
                _dataCell(prof['user_id_number'] ?? 'N/A', textColor,
                    isBold: true,
                    onTap: () => setState(() => _selectedLedgerItem = item)),
                _dataCell(
                    "${prof['ln'] ?? ''}, ${prof['fn'] ?? ''}".toUpperCase(),
                    textColor,
                    onTap: () => setState(() => _selectedLedgerItem = item)),
                _dataCell(item['payment_type'] ?? 'N/A', textColor,
                    color: aViolet),
                _dataCell(
                    "₱${NumberFormat('#,##0.00').format(item['amount'] ?? 0.0)}",
                    textColor,
                    isMonospace: true),
                _dataCell(
                    "₱${NumberFormat('#,##0.00').format(item['amount_paid'] ?? 0.0)}",
                    textColor,
                    isMonospace: true,
                    color: success),
                _statusBadgeCell(item['status'] ?? 'N/A'),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetailsSidebar(Color text) {
    final prof =
        _selectedLedgerItem!['profiles'] as Map<String, dynamic>? ?? {};
    final dateStr = _selectedLedgerItem!['created_at'] != null
        ? DateFormat('MMMM dd, yyyy HH:mm')
            .format(DateTime.parse(_selectedLedgerItem!['created_at']))
        : 'N/A';

    final double assessed =
        double.tryParse(_selectedLedgerItem!['amount']?.toString() ?? "0.0") ??
            0.0;
    final double paid = double.tryParse(
            _selectedLedgerItem!['amount_paid']?.toString() ?? "0.0") ??
        0.0;
    final double remaining = assessed - paid;

    // Decode audit break down details safely
    Map<String, dynamic> remarksBreakdown = {};
    if (_selectedLedgerItem!['remarks'] != null) {
      try {
        remarksBreakdown = jsonDecode(_selectedLedgerItem!['remarks']);
      } catch (_) {}
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Audit Trail Audit Details",
                  style: GoogleFonts.inter(
                      fontSize: 20, fontWeight: FontWeight.w900, color: text)),
              IconButton(
                  onPressed: () => setState(() => _selectedLedgerItem = null),
                  icon: const Icon(Icons.close, color: Colors.blueGrey)),
            ],
          ),
          const Divider(height: 32, color: Colors.white10),
          _auditDetailsRow("STUDENT ID", prof['user_id_number'] ?? 'N/A', text),
          _auditDetailsRow("STUDENT NAME",
              "${prof['fn'] ?? ''} ${prof['ln'] ?? ''}".toUpperCase(), text),
          _auditDetailsRow("EMAIL ADDRESS", prof['email'] ?? 'N/A', text,
              isSmall: true),
          _auditDetailsRow("TRANSACTION TIME", dateStr, text, isSmall: true),
          _auditDetailsRow("LEDGER CATEGORY",
              _selectedLedgerItem!['payment_type'] ?? 'N/A', text),
          const Divider(height: 32, color: Colors.white10),
          Text("FINANCIAL BALANCE STATEMENT",
              style: TextStyle(
                  color: text,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5)),
          const SizedBox(height: 16),
          _summaryAuditLine("Gross Assessed Total", assessed, Colors.blueGrey),
          _summaryAuditLine("Setted Payments", paid, success),
          _summaryAuditLine("Outstanding Receivables", remaining, danger,
              isBold: true),
          const Divider(height: 32, color: Colors.white10),
          Text("ITEMIZED FEES AUDIT BREAKDOWN",
              style: TextStyle(
                  color: text,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5)),
          const SizedBox(height: 16),
          if (remarksBreakdown.isEmpty)
            const Text(
                "Itemized breakdown pending or stored in legacy plaintext format.",
                style: TextStyle(
                    color: Colors.blueGrey,
                    fontStyle: FontStyle.italic,
                    fontSize: 12))
          else ...[
            if (remarksBreakdown['tuition'] != null)
              _itemBreakdownRow(
                  "Gross Tuition base",
                  double.tryParse(remarksBreakdown['tuition'].toString()) ??
                      0.0),
            if (remarksBreakdown['lab_fee'] != null)
              _itemBreakdownRow(
                  "Laboratory Base fees",
                  double.tryParse(remarksBreakdown['lab_fee'].toString()) ??
                      0.0),
            if (remarksBreakdown['misc_breakdown'] is Map)
              ...(remarksBreakdown['misc_breakdown'] as Map).entries.map((e) =>
                  _itemBreakdownRow(e.key.toString(),
                      double.tryParse(e.value.toString()) ?? 0.0)),
            if (remarksBreakdown['other_breakdown'] is Map)
              ...(remarksBreakdown['other_breakdown'] as Map).entries.map((e) =>
                  _itemBreakdownRow(e.key.toString(),
                      double.tryParse(e.value.toString()) ?? 0.0)),
          ]
        ],
      ),
    );
  }

  Widget _auditDetailsRow(String label, String value, Color text,
      {bool isSmall = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: text,
                  fontSize: isSmall ? 13 : 15,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _summaryAuditLine(String label, double val, Color color,
      {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          Text("₱${NumberFormat('#,##0.00').format(val)}",
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: isBold ? 16 : 14,
                  fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _itemBreakdownRow(String name, double amt) {
    if (amt == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: Text("• $name",
                  style:
                      const TextStyle(color: Colors.blueGrey, fontSize: 12))),
          Text("₱${NumberFormat('#,##0.00').format(amt)}",
              style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _headerCell(String text) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: aViolet,
              letterSpacing: 1)));

  Widget _dataCell(String text, Color textColor,
      {bool isBold = false,
      bool isSmall = false,
      Color? color,
      bool isMonospace = false,
      VoidCallback? onTap}) {
    final cellText = Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
          color: color ?? textColor,
          fontFamily: isMonospace ? 'monospace' : null,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: isSmall ? 12 : 14),
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: cellText,
      ),
    );
  }

  Widget _statusBadgeCell(String status) {
    final bool isPaid = status.toLowerCase() == 'paid';
    final Color badgeColor = isPaid ? success : danger;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: badgeColor.withOpacity(0.2)),
          ),
          child: Text(status.toUpperCase(),
              style: TextStyle(
                  color: badgeColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5)),
        ),
      ),
    );
  }
}
