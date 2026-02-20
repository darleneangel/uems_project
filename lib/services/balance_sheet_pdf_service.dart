import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'financial_report_service.dart';

class BalanceSheetPdfService {
  static Future<pw.Document> generateBalanceSheet({
    required String schoolName,
    required String date,
    required BalanceSheetData data,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            children: [
              FinancialReportService.buildHeader('BALANCE SHEET', schoolName, date),
              FinancialReportService.buildSubtitle('Assets, Liabilities & Equity Statement'),
              pw.SizedBox(height: 16),
              
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Assets Section
                  pw.Expanded(
                    child: FinancialReportService.buildSectionCard(
                      title: 'Assets',
                      accent: FinancialReportService.accentViolet,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildAssetSection('Current Assets', data.currentAssets),
                          pw.SizedBox(height: 12),
                          _buildAssetSection('Fixed Assets', data.fixedAssets),
                          pw.SizedBox(height: 12),
                          _buildAssetSection('Other Assets', data.otherAssets),
                          pw.SizedBox(height: 12),
                          pw.Container(
                            width: double.infinity,
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: pw.BoxDecoration(
                              color: FinancialReportService.surfaceAlt,
                              borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(6),
                              ),
                              border: pw.Border.all(
                                color: FinancialReportService.borderLight,
                              ),
                            ),
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'TOTAL ASSETS',
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: FinancialReportService.textDark,
                                  ),
                                ),
                                pw.Text(
                                  FinancialReportService.formatCurrency(data.totalAssets),
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: FinancialReportService.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  // Liabilities & Equity Section
                  pw.Expanded(
                    child: FinancialReportService.buildSectionCard(
                      title: 'Liabilities & Equity',
                    accent: FinancialReportService.borderLight,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildLiabilitySection(
                            'Current Liabilities',
                            data.currentLiabilities,
                          ),
                          pw.SizedBox(height: 12),
                          _buildLiabilitySection(
                            'Long-Term Liabilities',
                            data.longTermLiabilities,
                          ),
                          pw.SizedBox(height: 12),
                          pw.Container(
                            width: double.infinity,
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: pw.BoxDecoration(
                              color: FinancialReportService.surfaceAlt,
                              borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(6),
                              ),
                              border: pw.Border.all(
                                color: FinancialReportService.borderLight,
                              ),
                            ),
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'Total Liabilities',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: FinancialReportService.textDark,
                                  ),
                                ),
                                pw.Text(
                                  FinancialReportService.formatCurrency(data.totalLiabilities),
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: FinancialReportService.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 12),
                          pw.Container(
                            width: double.infinity,
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: pw.BoxDecoration(
                              color: FinancialReportService.surfaceLight,
                              border: pw.Border.all(
                                color: FinancialReportService.borderLight,
                              ),
                              borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(6),
                              ),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Capital & Reserves',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: FinancialReportService.textDark,
                                  ),
                                ),
                                pw.SizedBox(height: 6),
                                ...data.equity.entries.map((e) => pw.Padding(
                                      padding: const pw.EdgeInsets.symmetric(vertical: 2),
                                      child: pw.Row(
                                        mainAxisAlignment:
                                            pw.MainAxisAlignment.spaceBetween,
                                        children: [
                                          pw.Text(
                                            e.key,
                                            style: pw.TextStyle(
                                              fontSize: 8,
                                              color: FinancialReportService.textMuted,
                                            ),
                                          ),
                                          pw.Text(
                                            FinancialReportService.formatCurrency(e.value),
                                            style: pw.TextStyle(
                                              fontSize: 8,
                                              color: FinancialReportService.textDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 12),
                          pw.Container(
                            width: double.infinity,
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: pw.BoxDecoration(
                              color: FinancialReportService.surfaceAlt,
                              borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(6),
                              ),
                              border: pw.Border.all(
                                color: FinancialReportService.borderLight,
                              ),
                            ),
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'TOTAL LIAB. & EQUITY',
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: FinancialReportService.textDark,
                                  ),
                                ),
                                pw.Text(
                                  FinancialReportService.formatCurrency(data.totalLiabilitiesAndEquity),
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: FinancialReportService.textDark,
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
              
              pw.Spacer(),
              FinancialReportService.buildFooter('BALANCE SHEET'),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildAssetSection(
    String title,
    Map<String, double> items,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: FinancialReportService.textDark,
          ),
        ),
        pw.SizedBox(height: 6),
        ...items.entries.map((e) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      e.key,
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: FinancialReportService.textMuted,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      FinancialReportService.formatCurrency(e.value),
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: FinancialReportService.textDark,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  static pw.Widget _buildLiabilitySection(
    String title,
    Map<String, double> items,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: FinancialReportService.textDark,
          ),
        ),
        pw.SizedBox(height: 6),
        ...items.entries.map((e) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      e.key,
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: FinancialReportService.textMuted,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      FinancialReportService.formatCurrency(e.value),
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: FinancialReportService.textDark,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class BalanceSheetData {
  final Map<String, double> currentAssets;
  final Map<String, double> fixedAssets;
  final Map<String, double> otherAssets;
  final Map<String, double> currentLiabilities;
  final Map<String, double> longTermLiabilities;
  final Map<String, double> equity;

  double get totalAssets =>
      currentAssets.values.fold(0.0, (a, b) => a + b) +
      fixedAssets.values.fold(0.0, (a, b) => a + b) +
      otherAssets.values.fold(0.0, (a, b) => a + b);

  double get totalLiabilities =>
      currentLiabilities.values.fold(0.0, (a, b) => a + b) +
      longTermLiabilities.values.fold(0.0, (a, b) => a + b);

  double get totalEquity => equity.values.fold(0, (a, b) => a + b);

  double get totalLiabilitiesAndEquity => totalLiabilities + totalEquity;

  BalanceSheetData({
    required this.currentAssets,
    required this.fixedAssets,
    required this.otherAssets,
    required this.currentLiabilities,
    required this.longTermLiabilities,
    required this.equity,
  });
}
