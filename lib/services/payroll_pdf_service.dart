import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'financial_report_service.dart';

class PayrollPdfService {
  static Future<pw.Document> generatePayrollReport({
    required PayrollReportData data,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              FinancialReportService.buildHeader('PAYROLL REPORT', data.schoolName, data.payDate),
              FinancialReportService.buildSubtitle('Payroll cycle: ${data.payrollCycle}'),
              pw.SizedBox(height: 16),
              FinancialReportService.buildSectionCard(
                title: 'Payroll Configuration',
                accent: FinancialReportService.accentViolet,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _infoRow('Department', data.department),
                    _infoRow('Pay period', data.payPeriod),
                    _infoRow('Pay date', data.payDate),
                    _infoRow('Cycle', data.payrollCycle),
                    _infoRow(
                      'Overtime & adjustments',
                      data.includeOvertime ? 'Included' : 'Excluded',
                    ),
                    _infoRow(
                      'Allowances & benefits',
                      data.includeAllowances ? 'Included' : 'Excluded',
                    ),
                    _infoRow(
                      'Auto deductions & taxes',
                      data.autoDeductions ? 'Enabled' : 'Disabled',
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              FinancialReportService.buildSectionCard(
                title: 'SSS Details',
                accent: FinancialReportService.warningOrange,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _infoRow('Employer ID', data.sssEmployerId),
                    _infoRow('Contribution rate', data.sssContributionRate),
                    _infoRow('Cutoff', data.sssCutoff),
                    _infoRow('Coverage', 'All eligible staff'),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              FinancialReportService.buildSectionCard(
                title: 'Salary Groups',
                accent: FinancialReportService.successGreen,
                child: pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    FinancialReportService.buildTableHeaderRow([
                      'Group',
                      'Staff',
                      'Avg Salary',
                    ]),
                    ...data.groupSummaries.map(
                      (group) => FinancialReportService.buildTableRow(
                        [
                          group.name,
                          group.staffCount.toString(),
                          FinancialReportService.formatCurrency(group.averageSalary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              FinancialReportService.buildSectionCard(
                title: 'Payroll Totals',
                accent: FinancialReportService.accentViolet,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _infoRow('Employees included', data.totals.employeeCount.toString()),
                    _infoRow(
                      'Gross payroll',
                      FinancialReportService.formatCurrency(data.totals.grossPayroll),
                    ),
                    _infoRow(
                      'Total deductions',
                      FinancialReportService.formatCurrency(data.totals.totalDeductions),
                    ),
                    _infoRow(
                      'Net payout',
                      FinancialReportService.formatCurrency(data.totals.netPayout),
                      isEmphasis: true,
                    ),
                  ],
                ),
              ),
              pw.Spacer(),
              FinancialReportService.buildFooter('PAYROLL REPORT'),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _infoRow(String label, String value, {bool isEmphasis = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              color: FinancialReportService.textMuted,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isEmphasis ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isEmphasis
                  ? FinancialReportService.textDark
                  : FinancialReportService.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class PayrollReportData {
  final String schoolName;
  final String department;
  final String payPeriod;
  final String payDate;
  final String payrollCycle;
  final bool includeOvertime;
  final bool includeAllowances;
  final bool autoDeductions;
  final String sssEmployerId;
  final String sssContributionRate;
  final String sssCutoff;
  final List<PayrollGroupSummary> groupSummaries;
  final PayrollTotals totals;

  PayrollReportData({
    required this.schoolName,
    required this.department,
    required this.payPeriod,
    required this.payDate,
    required this.payrollCycle,
    required this.includeOvertime,
    required this.includeAllowances,
    required this.autoDeductions,
    required this.sssEmployerId,
    required this.sssContributionRate,
    required this.sssCutoff,
    required this.groupSummaries,
    required this.totals,
  });
}

class PayrollGroupSummary {
  final String name;
  final int staffCount;
  final double averageSalary;

  PayrollGroupSummary({
    required this.name,
    required this.staffCount,
    required this.averageSalary,
  });
}

class PayrollTotals {
  final int employeeCount;
  final double grossPayroll;
  final double totalDeductions;
  final double netPayout;

  PayrollTotals({
    required this.employeeCount,
    required this.grossPayroll,
    required this.totalDeductions,
    required this.netPayout,
  });
}
