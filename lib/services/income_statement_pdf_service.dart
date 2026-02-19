import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'financial_report_service.dart';

class IncomeStatementPdfService {
  static Future<pw.Document> generateIncomeStatement({
    required String schoolName,
    required String date,
    required List<IncomeLineItem> incomeItems,
    required List<ExpenseLineItem> expenseItems,
    double? netIncome,
  }) async {
    final pdf = pw.Document();

    final netInc = netIncome ?? (incomeItems.fold(0.0, (sum, item) => sum + item.amount) - 
        expenseItems.fold(0.0, (sum, item) => sum + item.amount));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            children: [
              FinancialReportService.buildHeader('INCOME STATEMENT', schoolName, date),
              FinancialReportService.buildSubtitle('Revenue vs Expenses Analysis'),
              pw.SizedBox(height: 16),
              
              // Income Section
              FinancialReportService.buildSectionCard(
                title: 'Revenue',
                accent: FinancialReportService.successGreen,
                child: pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    FinancialReportService.buildTableHeaderRow(['Type', 'Amount', '%']),
                    ...incomeItems.map((item) => FinancialReportService.buildTableRow(
                          [
                            item.name,
                            FinancialReportService.formatCurrency(item.amount),
                            FinancialReportService.formatPercentage(item.percentage),
                          ],
                          isPositive: true,
                        )),
                    FinancialReportService.buildTableRow(
                      [
                        'Total Revenue',
                        FinancialReportService.formatCurrency(
                          incomeItems.fold(0.0, (sum, item) => sum + item.amount),
                        ),
                        '100.00',
                      ],
                      isTotal: true,
                      isPositive: true,
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Expenses Section
              FinancialReportService.buildSectionCard(
                title: 'Expenses',
                accent: FinancialReportService.errorRed,
                child: pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    FinancialReportService.buildTableHeaderRow(['Type', 'Amount', '%']),
                    ...expenseItems.map((item) => FinancialReportService.buildTableRow(
                          [
                            item.name,
                            FinancialReportService.formatCurrency(item.amount),
                            FinancialReportService.formatPercentage(item.percentage),
                          ],
                          isNegative: true,
                        )),
                    FinancialReportService.buildTableRow(
                      [
                        'Total Expenses',
                        FinancialReportService.formatCurrency(
                          expenseItems.fold(0.0, (sum, item) => sum + item.amount),
                        ),
                        '100.00',
                      ],
                      isTotal: true,
                      isNegative: true,
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Net Income Summary
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: pw.BoxDecoration(
                  color: FinancialReportService.surfaceAlt,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: FinancialReportService.borderLight),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'NET INCOME',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: FinancialReportService.textDark,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Profit After Expenses',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: FinancialReportService.textMuted,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      FinancialReportService.formatCurrency(netInc),
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: FinancialReportService.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.Spacer(),
              FinancialReportService.buildFooter('INCOME STATEMENT'),
            ],
          );
        },
      ),
    );

    return pdf;
  }
}

class IncomeLineItem {
  final String name;
  final double amount;
  final double percentage;

  IncomeLineItem({
    required this.name,
    required this.amount,
    required this.percentage,
  });
}

class ExpenseLineItem {
  final String name;
  final double amount;
  final double percentage;

  ExpenseLineItem({
    required this.name,
    required this.amount,
    required this.percentage,
  });
}
