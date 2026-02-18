import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class FinancialReportsPanel extends StatelessWidget {
  final bool isDarkMode;
  const FinancialReportsPanel({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2E1065);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 2.5,
          children: [
            _reportCard(
              "Income Statement",
              "Revenue vs Expenses",
              LucideIcons.barChart2,
              Colors.blueAccent,
              cardColor,
              textColor,
              () => _showReportPanel(
                context,
                title: "Income Statement",
                accentColor: Colors.blueAccent,
                items: const [
                  "Total Revenue: ₱1,250,000.00",
                  "Total Expenses: ₱845,000.00",
                  "Net Income: ₱405,000.00",
                ],
              ),
            ),
            _reportCard(
              "Balance Sheet",
              "Assets, Liabilities, Equity",
              LucideIcons.scale,
              Colors.purpleAccent,
              cardColor,
              textColor,
              () => _showReportPanel(
                context,
                title: "Balance Sheet",
                accentColor: Colors.purpleAccent,
                items: const [
                  "Assets: ₱2,100,000.00",
                  "Liabilities: ₱780,000.00",
                  "Equity: ₱1,320,000.00",
                ],
              ),
            ),
            _reportCard(
              "Cash Flow",
              "Inflow & Outflow",
              LucideIcons.banknote,
              const Color(0xFF69F0AE),
              cardColor,
              textColor,
              () => _showReportPanel(
                context,
                title: "Cash Flow",
                accentColor: const Color(0xFF69F0AE),
                items: const [
                  "Operating Inflow: ₱620,000.00",
                  "Operating Outflow: ₱410,000.00",
                  "Net Cash: ₱210,000.00",
                ],
              ),
            ),
            _reportCard(
              "Tax Compliance",
              "BIR Forms & Audit",
              LucideIcons.fileCheck,
              Colors.orangeAccent,
              cardColor,
              textColor,
              () => _showReportPanel(
                context,
                title: "Tax Compliance",
                accentColor: Colors.orangeAccent,
                items: const [
                  "Form 1601C: Filed",
                  "Form 2550M: Pending",
                  "Audit Status: Cleared",
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          "Audit Trail & Daily Logs",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDarkMode ? Colors.white10 : Colors.black12,
            ),
          ),
          child: Column(
            children: [
              _auditRow(
                "Payment Received - OR#1001",
                "Darlene Angel",
                "₱5,000.00",
                "Just now",
                textColor,
              ),
              const Divider(),
              _auditRow(
                "Fee Added - Library Fine",
                "John Doe",
                "₱50.00",
                "15 mins ago",
                textColor,
              ),
              const Divider(),
              _auditRow(
                "Scholarship Applied",
                "Jane Smith",
                "Dean's Lister",
                "1 hour ago",
                textColor,
              ),
              const Divider(),
              _auditRow(
                "System Backup",
                "Automated",
                "Success",
                "2 hours ago",
                textColor,
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }

  Widget _reportCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    Color cardColor,
    Color textColor,
    VoidCallback onExport,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.blueGrey),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: TextButton.icon(
              onPressed: onExport,
              icon: const Icon(LucideIcons.download, size: 16),
              label: const Text("EXPORT PDF"),
              style: TextButton.styleFrom(foregroundColor: color),
            ),
          ),
        ],
      ),
    );
  }

  String _safeFileName(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r"\s+"), "_")
        .replaceAll(RegExp(r"[^a-z0-9_]+"), "");
  }

  Future<void> _exportReportPdf(
    BuildContext context, {
    required String title,
    required List<String> items,
  }) async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  "Generated: ${now.toString().split('.')[0]}",
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Divider(),
                pw.SizedBox(height: 12),
                pw.Text(
                  "Summary",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Column(
                  children: items
                      .map(
                        (item) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 6),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text("• "),
                              pw.Expanded(child: pw.Text(item)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            );
          },
        ),
      );

      final dir = await getTemporaryDirectory();
      final fileName =
          "${_safeFileName(title)}_${now.millisecondsSinceEpoch}.pdf";
      final file = File("${dir.path}/$fileName");
      await file.writeAsBytes(await pdf.save());

      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done) {
        debugPrint("Error opening file: ${result.message}");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("PDF exported: ${file.path}"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Export failed: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showReportPanel(
    BuildContext context, {
    required String title,
    required Color accentColor,
    required List<String> items,
  }) {
    final parentContext = context;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1E1B4B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final sheetTextColor =
            isDarkMode ? Colors.white : const Color(0xFF2E1065);
        final sheetSubText =
            isDarkMode ? Colors.white70 : Colors.black54;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(LucideIcons.fileText, color: accentColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: sheetTextColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(LucideIcons.x, color: sheetSubText),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "Latest Snapshot",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: sheetSubText,
                ),
              ),
              const SizedBox(height: 12),
              ...items.map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.dot, color: accentColor, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: GoogleFonts.inter(color: sheetTextColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _exportReportPdf(
                      parentContext,
                      title: title,
                      items: items,
                    );
                  },
                  icon: const Icon(LucideIcons.download),
                  label: const Text("EXPORT PDF"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _auditRow(
    String action,
    String user,
    String detail,
    String time,
    Color textColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              action,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(user, style: GoogleFonts.inter(color: Colors.blueGrey)),
          ),
          Expanded(
            flex: 1,
            child: Text(
              detail,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF69F0AE),
              ),
            ),
          ),
          Text(
            time,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
