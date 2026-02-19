import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'financial_report_service.dart';

class TaxCompliancePdfService {
  static Future<pw.Document> generateBIR1601CForm({
    required String schoolName,
    required String tinNumber,
    required int forTheMonth,
    required int forTheYear,
    required TaxWithholdingData data,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return pw.Column(
            children: [
              // BIR Header
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: FinancialReportService.surfaceLight,
                  border: pw.Border.all(
                    color: FinancialReportService.accentViolet,
                    width: 1.5,
                  ),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'REPUBLIC OF THE PHILIPPINES',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: FinancialReportService.textDark,
                      ),
                    ),
                    pw.Text(
                      'Bureau of Internal Revenue',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: FinancialReportService.textDark,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'MONTHLY REMITTANCE RETURN OF INCOME TAXES',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: FinancialReportService.accentViolet,
                      ),
                    ),
                    pw.Text(
                      'WITHHELD ON COMPENSATION',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: FinancialReportService.accentViolet,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'BIR Form No. 1601-C (January 2008)',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: FinancialReportService.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 16),
              
              // Header Information
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
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
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'For the Month:',
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: FinancialReportService.textDark,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              _getMonthName(forTheMonth),
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: FinancialReportService.textMuted,
                              ),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Year:',
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: FinancialReportService.textDark,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              forTheYear.toString(),
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: FinancialReportService.textMuted,
                              ),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'TIN:',
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: FinancialReportService.textDark,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              tinNumber,
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: FinancialReportService.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Divider(color: FinancialReportService.borderLight),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Withholding Agent Name:',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: FinancialReportService.textDark,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      schoolName,
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: FinancialReportService.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 16),
              
              // Tax Computation Section
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: FinancialReportService.surfaceLight,
                  border: pw.Border.all(color: FinancialReportService.borderLight),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'COMPUTATION OF TAX',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: FinancialReportService.accentViolet,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    _buildTaxComputationRow(
                      'Total Amount of Compensation',
                      FinancialReportService.formatCurrency(data.totalCompensation),
                    ),
                    pw.SizedBox(height: 6),
                    _buildTaxComputationRow(
                      'Less: Non-Taxable Compensation',
                      FinancialReportService.formatCurrency(data.nonTaxableCompensation),
                    ),
                    pw.SizedBox(height: 6),
                    _buildTaxComputationRow(
                      'Taxable Compensation',
                      FinancialReportService.formatCurrency(
                        data.totalCompensation - data.nonTaxableCompensation,
                      ),
                      isBold: true,
                    ),
                    pw.SizedBox(height: 12),
                    _buildTaxComputationRow(
                      'Tax Required to be Withheld for Remittance',
                      FinancialReportService.formatCurrency(data.taxWithheld),
                      isBold: true,
                      color: FinancialReportService.errorRed,
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 16),
              
              // Tax Payment Details
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: FinancialReportService.surfaceLight,
                  border: pw.Border.all(color: FinancialReportService.borderLight),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'TAX PAYMENT DETAILS',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: FinancialReportService.accentViolet,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    _buildTaxPaymentRow(
                      'Total Tax Payments Made',
                      FinancialReportService.formatCurrency(data.totalPaymentsMade),
                    ),
                    pw.SizedBox(height: 6),
                    _buildTaxPaymentRow(
                      'Tax Still Due/(Overpayment)',
                      FinancialReportService.formatCurrency(
                        data.taxWithheld - data.totalPaymentsMade,
                      ),
                      isOverpayment: data.totalPaymentsMade > data.taxWithheld,
                    ),
                    pw.SizedBox(height: 6),
                    _buildTaxPaymentRow(
                      'Add: Penalties & Interest',
                      FinancialReportService.formatCurrency(data.penalties),
                    ),
                  ],
                ),
              ),
              
              pw.Spacer(),
              
              // Signature Block
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 12),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: FinancialReportService.borderLight),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    pw.Column(
                      children: [
                        pw.SizedBox(height: 30),
                        pw.Text(
                          '_______________________',
                          style: pw.TextStyle(fontSize: 8),
                        ),
                        pw.Text(
                          'Authorized Signature',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: FinancialReportService.textMuted,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.SizedBox(height: 30),
                        pw.Text(
                          '_______________________',
                          style: pw.TextStyle(fontSize: 8),
                        ),
                        pw.Text(
                          'Date',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: FinancialReportService.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              FinancialReportService.buildFooter('BIR FORM 1601-C'),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static Future<pw.Document> generateAuditReport({
    required String schoolName,
    required String auditPeriod,
    required String auditedBy,
    required String auditDate,
    required AuditFindingsData findings,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            children: [
              FinancialReportService.buildHeader('AUDIT REPORT', schoolName, auditDate),
              
              pw.Text(
                'Financial Audit Findings & Recommendations',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: FinancialReportService.accentViolet,
                ),
              ),
              pw.SizedBox(height: 16),
              
              // Audit Information
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: FinancialReportService.borderGrey),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Audit Period:',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: FinancialReportService.textWhite,
                              ),
                            ),
                            pw.Text(
                              auditPeriod,
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: FinancialReportService.textLight,
                              ),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Audited By:',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: FinancialReportService.textWhite,
                              ),
                            ),
                            pw.Text(
                              auditedBy,
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: FinancialReportService.textLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 16),
              
              // Compliance Status
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor(0.08, 0.04, 0.12),
                  border: pw.Border.all(color: FinancialReportService.borderGrey),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'COMPLIANCE SUMMARY',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: FinancialReportService.accentViolet,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    ...findings.complianceItems.entries.map((item) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 5),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                  item.key,
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    color: FinancialReportService.textLight,
                                  ),
                                ),
                              ),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: pw.BoxDecoration(
                                  color: item.value
                                      ? FinancialReportService.successGreen
                                      : FinancialReportService.errorRed,
                                  borderRadius: const pw.BorderRadius.all(
                                    pw.Radius.circular(4),
                                  ),
                                ),
                                child: pw.Text(
                                  item.value ? 'COMPLIANT' : 'NON-COMPLIANT',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: FinancialReportService.textWhite,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 16),
              
              // Findings
              if (findings.majorFindings.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      left: pw.BorderSide(
                        color: FinancialReportService.errorRed,
                        width: 4,
                      ),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MAJOR FINDINGS',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: FinancialReportService.errorRed,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      ...findings.majorFindings.map((finding) => pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 6),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  finding,
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    color: FinancialReportService.textLight,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
              ],
              
              // Recommendations
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    left: pw.BorderSide(
                      color: FinancialReportService.successGreen,
                      width: 4,
                    ),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'RECOMMENDATIONS',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: FinancialReportService.successGreen,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    ...findings.recommendations.asMap().entries.map((entry) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 5),
                          child: pw.Text(
                            '${entry.key + 1}. ${entry.value}',
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: FinancialReportService.textLight,
                            ),
                          ),
                        )),
                  ],
                ),
              ),
              
              pw.Spacer(),
              FinancialReportService.buildFooter(
                'AUDIT REPORT',
                auditNotes: 'For official use only',
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildTaxComputationRow(
    String label,
    String amount, {
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? FinancialReportService.textDark,
          ),
        ),
        pw.Text(
          amount,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? FinancialReportService.textDark,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTaxPaymentRow(
    String label,
    String amount, {
    bool isOverpayment = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            color: FinancialReportService.textDark,
          ),
        ),
        pw.Text(
          amount,
          style: pw.TextStyle(
            fontSize: 9,
            color: isOverpayment
                ? FinancialReportService.successGreen
                : FinancialReportService.errorRed,
          ),
        ),
      ],
    );
  }

  static String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return month >= 1 && month <= 12 ? months[month - 1] : 'Invalid Month';
  }
}

class TaxWithholdingData {
  final double totalCompensation;
  final double nonTaxableCompensation;
  final double taxWithheld;
  final double totalPaymentsMade;
  final double penalties;

  TaxWithholdingData({
    required this.totalCompensation,
    required this.nonTaxableCompensation,
    required this.taxWithheld,
    required this.totalPaymentsMade,
    required this.penalties,
  });
}

class AuditFindingsData {
  final Map<String, bool> complianceItems;
  final List<String> majorFindings;
  final List<String> recommendations;

  AuditFindingsData({
    required this.complianceItems,
    required this.majorFindings,
    required this.recommendations,
  });
}
