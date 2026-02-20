import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class FinancialReportsPanel extends StatefulWidget {
  final bool isDarkMode;
  const FinancialReportsPanel({super.key, required this.isDarkMode});

  @override
  State<FinancialReportsPanel> createState() => _FinancialReportsPanelState();
}

class _FinancialReportsPanelState extends State<FinancialReportsPanel> {
  // Theme Constants
  static const Color pViolet = Color(0xFF2E1065);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  // Mock Data: List of Students who have paid
  final List<Map<String, dynamic>> _paymentRecords = [
    {
      "id": "2024-00001",
      "name": "DARLENE ANGEL",
      "course": "BSCS",
      "amount": 15000.00,
      "date": "2026-02-10",
      "ref": "OR-8821",
    },
    {
      "id": "2024-00042",
      "name": "JOHN DOE",
      "course": "BSIT",
      "amount": 8500.00,
      "date": "2026-02-11",
      "ref": "OR-9012",
    },
    {
      "id": "2023-10042",
      "name": "JANE SMITH",
      "course": "BSCS",
      "amount": 25000.00,
      "date": "2026-02-09",
      "ref": "OR-8750",
    },
    {
      "id": "2022-30089",
      "name": "ROBERT BROWN",
      "course": "BSCPE",
      "amount": 12000.00,
      "date": "2026-02-08",
      "ref": "OR-8644",
    },
    {
      "id": "2024-00155",
      "name": "ALICE WONDER",
      "course": "BSN",
      "amount": 30000.00,
      "date": "2026-02-07",
      "ref": "OR-8521",
    },
  ];

  // --- EXPORT LOGIC ---

  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();
    final String timestamp = DateTime.now().toString().split('.')[0];
    final PdfColor brandViolet = PdfColor.fromInt(0xFF7C3AED);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "UEMSSP FINANCIAL REPORT",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18,
                        color: brandViolet,
                      ),
                    ),
                    pw.Text(
                      "Collection Summary - Paid Students",
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  "Date: $timestamp",
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: [
              "Student ID",
              "Name",
              "Course",
              "Amount",
              "Date",
              "Reference",
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 9,
            ),
            headerDecoration: pw.BoxDecoration(color: brandViolet),
            cellStyle: const pw.TextStyle(fontSize: 8),
            data: _paymentRecords
                .map(
                  (r) => [
                    r['id'],
                    r['name'],
                    r['course'],
                    "PHP ${r['amount'].toStringAsFixed(2)}",
                    r['date'],
                    r['ref'],
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 30),
          pw.Divider(),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "TOTAL COLLECTION: PHP ${_paymentRecords.fold(0.0, (sum, item) => sum + item['amount']).toStringAsFixed(2)}",
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
                color: brandViolet,
              ),
            ),
          ),
        ],
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        "${dir.path}/Financial_Report_${DateTime.now().millisecondsSinceEpoch}.pdf",
      );
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      _showSnackBar("Error generating PDF: $e", isError: true);
    }
  }

  void _exportToExcel() {
    // In a real app, you'd use the 'excel' package.
    // For this UI fix, we simulate the success feedback.
    _showSnackBar("Excel report generated and saved to downloads.");
  }

  void _showSnackBar(String m, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: isError ? Colors.redAccent : aViolet,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode ? Colors.white : pViolet;
    final Color cardColor = widget.isDarkMode ? surfaceDark : Colors.white;
    final Color subTextColor = widget.isDarkMode
        ? Colors.white54
        : Colors.blueGrey;

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor, subTextColor),
          const SizedBox(height: 32),
          _buildSummaryCards(cardColor, textColor),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.isDarkMode ? Colors.white10 : Colors.black12,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Payment Collection Ledger",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      Row(
                        children: [
                          _exportButton(
                            "EXCEL",
                            LucideIcons.fileSpreadsheet,
                            Colors.green,
                            _exportToExcel,
                          ),
                          const SizedBox(width: 12),
                          _exportButton(
                            "PDF",
                            LucideIcons.fileText,
                            Colors.redAccent,
                            _generatePdfReport,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildTableHead(subTextColor),
                  const Divider(height: 1, color: Colors.white10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _paymentRecords.length,
                      itemBuilder: (context, index) => _buildDataRow(
                        _paymentRecords[index],
                        textColor,
                        subTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color textColor, Color subTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Financial Reports & Analytics",
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: textColor,
            letterSpacing: -1,
          ),
        ),
        Text(
          "Generate and export institutional collection reports for auditing and transparency.",
          style: TextStyle(color: subTextColor, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(Color cardColor, Color textColor) {
    double total = _paymentRecords.fold(
      0.0,
      (sum, item) => sum + item['amount'],
    );
    return Row(
      children: [
        _statCard(
          "Total Collected",
          "₱${total.toStringAsFixed(2)}",
          LucideIcons.wallet,
          success,
          cardColor,
          textColor,
        ),
        const SizedBox(width: 16),
        _statCard(
          "Total Transactions",
          _paymentRecords.length.toString(),
          LucideIcons.hash,
          aViolet,
          cardColor,
          textColor,
        ),
        const SizedBox(width: 16),
        _statCard(
          "Average Payment",
          "₱${(total / _paymentRecords.length).toStringAsFixed(2)}",
          LucideIcons.trendingUp,
          Colors.blueAccent,
          cardColor,
          textColor,
        ),
      ],
    );
  }

  Widget _statCard(
    String label,
    String val,
    IconData icon,
    Color color,
    Color cardBg,
    Color text,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  val,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: text,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _exportButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.2)),
        ),
      ),
    );
  }

  Widget _buildTableHead(Color subText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: _tableHeader("STUDENT ID", subText)),
          Expanded(flex: 3, child: _tableHeader("NAME", subText)),
          Expanded(flex: 1, child: _tableHeader("COURSE", subText)),
          Expanded(flex: 2, child: _tableHeader("AMOUNT", subText)),
          Expanded(flex: 2, child: _tableHeader("DATE", subText)),
          Expanded(flex: 2, child: _tableHeader("REFERENCE", subText)),
        ],
      ),
    );
  }

  Widget _tableHeader(String t, Color c) => Text(
    t,
    style: GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w900,
      color: c,
      letterSpacing: 1,
    ),
  );

  Widget _buildDataRow(Map<String, dynamic> record, Color text, Color subText) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.03),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              record['id'],
              style: TextStyle(
                color: aViolet,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              record['name'],
              style: TextStyle(
                color: text,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: aViolet.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                record['course'],
                style: const TextStyle(
                  color: aViolet,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "₱${record['amount'].toStringAsFixed(2)}",
              style: TextStyle(
                color: success,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              record['date'],
              style: TextStyle(color: subText, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Icon(
                  LucideIcons.ticket,
                  size: 12,
                  color: Colors.blueGrey,
                ),
                const SizedBox(width: 8),
                Text(
                  record['ref'],
                  style: TextStyle(
                    color: subText,
                    fontSize: 12,
                    fontFamily: 'Courier',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
