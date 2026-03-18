import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'financial_report_service.dart';

class CashFlowPdfService {
  static Future<pw.Document> generateCashFlowStatement({
    required String schoolName,
    required String date,
    required CashFlowData data,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            children: [
              FinancialReportService.buildHeader('CASH FLOW STATEMENT', schoolName, date),
              FinancialReportService.buildSubtitle('Operating, Investing & Financing Activities'),
              pw.SizedBox(height: 16),
              
              // Operating Activities
              _buildActivitySection(
                title: 'OPERATING ACTIVITIES',
                items: data.operatingActivities,
                isInflow: true,
              ),
              pw.SizedBox(height: 16),
              
              // Investing Activities
              _buildActivitySection(
                title: 'INVESTING ACTIVITIES',
                items: data.investingActivities,
                isInflow: false,
              ),
              pw.SizedBox(height: 16),
              
              // Financing Activities
              _buildActivitySection(
                title: 'FINANCING ACTIVITIES',
                items: data.financingActivities,
                isInflow: true,
              ),
              pw.SizedBox(height: 16),
              
              // Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: FinancialReportService.surfaceLight,
                  border: pw.Border.all(color: FinancialReportService.borderLight),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Net Cash from Operating Activities',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: FinancialReportService.textDark,
                          ),
                        ),
                        pw.Text(
                          FinancialReportService.formatCurrency(
                            data.operatingActivities.values.fold(0, (a, b) => a + b),
                          ),
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: FinancialReportService.textDark,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Divider(color: FinancialReportService.borderLight),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Net Cash from Investing Activities',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: FinancialReportService.textDark,
                          ),
                        ),
                        pw.Text(
                          FinancialReportService.formatCurrency(
                            data.investingActivities.values.fold(0, (a, b) => a + b),
                          ),
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: FinancialReportService.textDark,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Divider(color: FinancialReportService.borderLight),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Net Cash from Financing Activities',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: FinancialReportService.textDark,
                          ),
                        ),
                        pw.Text(
                          FinancialReportService.formatCurrency(
                            data.financingActivities.values.fold(0, (a, b) => a + b),
                          ),
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: FinancialReportService.textDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 16),
              
              // Net Change in Cash
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: pw.BoxDecoration(
                  color: FinancialReportService.surfaceAlt,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: FinancialReportService.borderLight),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'NET INCREASE IN CASH',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: FinancialReportService.textDark,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      FinancialReportService.formatCurrency(data.netChangeInCash),
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: FinancialReportService.successGreen,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                      children: [
                        pw.Column(
                          children: [
                            pw.Text(
                              'Beginning Balance',
                              style: const pw.TextStyle(
                                fontSize: 8,
                                color: FinancialReportService.textMuted,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              FinancialReportService.formatCurrency(data.beginningCashBalance),
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: FinancialReportService.textDark,
                              ),
                            ),
                          ],
                        ),
                        pw.Text('+', style: const pw.TextStyle(fontSize: 12, color: FinancialReportService.textMuted)),
                        pw.Column(
                          children: [
                            pw.Text(
                              'Net Change',
                              style: const pw.TextStyle(
                                fontSize: 8,
                                color: FinancialReportService.textMuted,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              FinancialReportService.formatCurrency(data.netChangeInCash),
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: FinancialReportService.textDark,
                              ),
                            ),
                          ],
                        ),
                        pw.Text('=', style: const pw.TextStyle(fontSize: 12, color: FinancialReportService.textMuted)),
                        pw.Column(
                          children: [
                            pw.Text(
                              'Ending Balance',
                              style: const pw.TextStyle(
                                fontSize: 8,
                                color: FinancialReportService.textMuted,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              FinancialReportService.formatCurrency(data.endingCashBalance),
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: FinancialReportService.textDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.Spacer(),
              FinancialReportService.buildFooter('CASH FLOW STATEMENT'),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildActivitySection({
    required String title,
    required Map<String, double> items,
    required bool isInflow,
  }) {
    return FinancialReportService.buildSectionCard(
      title: title,
      accent: FinancialReportService.borderLight,
      child: pw.Table(
        columnWidths: {
          0: const pw.FlexColumnWidth(2.5),
          1: const pw.FlexColumnWidth(1.5),
        },
        children: [
          FinancialReportService.buildTableHeaderRow([title, 'Amount']),
          ...items.entries.map((item) => FinancialReportService.buildTableRow(
                [
                  item.key,
                  FinancialReportService.formatCurrency(item.value),
                ],
                isPositive: item.value > 0,
                isNegative: item.value < 0,
              )),
          FinancialReportService.buildTableRow(
            [
              'Total $title',
              FinancialReportService.formatCurrency(
                items.values.fold(0, (a, b) => a + b),
              ),
            ],
            isTotal: true,
            isPositive: isInflow,
            isNegative: !isInflow,
          ),
        ],
      ),
    );
  }
}

class CashFlowData {
  final Map<String, double> operatingActivities;
  final Map<String, double> investingActivities;
  final Map<String, double> financingActivities;
  final double beginningCashBalance;
  final double endingCashBalance;

  double get netChangeInCash =>
      operatingActivities.values.fold(0.0, (a, b) => a + b) +
      investingActivities.values.fold(0.0, (a, b) => a + b) +
      financingActivities.values.fold(0.0, (a, b) => a + b);

  CashFlowData({
    required this.operatingActivities,
    required this.investingActivities,
    required this.financingActivities,
    required this.beginningCashBalance,
    required this.endingCashBalance,
  });
}
