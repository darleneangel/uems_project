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
                      style: const pw.TextStyle(
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
                              style: const pw.TextStyle(
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
                              style: const pw.TextStyle(
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
                              style: const pw.TextStyle(
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
                      style: const pw.TextStyle(
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
                      color: FinancialReportService.textDark,
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
                decoration: const pw.BoxDecoration(
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
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                        pw.Text(
                          'Authorized Signature',
                          style: const pw.TextStyle(
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
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                        pw.Text(
                          'Date',
                          style: const pw.TextStyle(
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
                              style: const pw.TextStyle(
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
                              style: const pw.TextStyle(
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
                  color: const PdfColor(0.08, 0.04, 0.12),
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
                                  style: const pw.TextStyle(
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
                  decoration: const pw.BoxDecoration(
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
                                  style: const pw.TextStyle(
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
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    left: pw.BorderSide(
                      color: FinancialReportService.borderLight,
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
                        color: FinancialReportService.textDark,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    ...findings.recommendations.asMap().entries.map((entry) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 5),
                          child: pw.Text(
                            '${entry.key + 1}. ${entry.value}',
                            style: const pw.TextStyle(
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
        pw.Expanded(
          flex: 2,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? FinancialReportService.textDark,
            ),
          ),
        ),
        pw.Expanded(
          flex: 1,
          child: pw.Text(
            amount,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? FinancialReportService.textDark,
            ),
            textAlign: pw.TextAlign.right,
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
        pw.Expanded(
          flex: 2,
          child: pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 9,
              color: FinancialReportService.textDark,
            ),
          ),
        ),
        pw.Expanded(
          flex: 1,
          child: pw.Text(
            amount,
            style: const pw.TextStyle(
              fontSize: 9,
              color: FinancialReportService.textDark,
            ),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  static Future<pw.Document> generateComprehensiveReport({
    required String schoolName,
    required String tinNumber,
    required int forTheMonth,
    required int forTheYear,
    required TaxWithholdingData withholding,
    required AuditFindingsData auditData,
  }) async {
    final pdf = pw.Document();

    // Page 1: BIR Form 1601-C
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return pw.Column(
            children: [
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
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: FinancialReportService.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
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
                              'TAXPAYER\'S NAME AND ADDRESS',
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: FinancialReportService.textMuted,
                              ),
                            ),
                            pw.Text(
                              schoolName,
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: FinancialReportService.textDark,
                              ),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'TIN',
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: FinancialReportService.textMuted,
                              ),
                            ),
                            pw.Text(
                              tinNumber,
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
                    pw.SizedBox(height: 10),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'FOR THE MONTH OF',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: FinancialReportService.textMuted,
                                ),
                              ),
                              pw.Text(
                                _getMonthName(forTheMonth),
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: FinancialReportService.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'YEAR',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: FinancialReportService.textMuted,
                                ),
                              ),
                              pw.Text(
                                '$forTheYear',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: FinancialReportService.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'TAX WITHHOLDING SUMMARY',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: FinancialReportService.textDark,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                },
                children: [
                  FinancialReportService.buildTableHeaderRow(
                    ['Description', 'Amount'],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: pw.Text(
                          'Total Compensation',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: pw.Text(
                          FinancialReportService.formatCurrency(
                            withholding.totalCompensation,
                          ),
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: pw.Text(
                          'Non-Taxable Compensation',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: pw.Text(
                          FinancialReportService.formatCurrency(
                            withholding.nonTaxableCompensation,
                          ),
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: FinancialReportService.surfaceAlt,
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: FinancialReportService.borderLight,
                          width: 1,
                        ),
                      ),
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: pw.Text(
                          'Total Tax Withheld',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: FinancialReportService.textDark,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: pw.Text(
                          FinancialReportService.formatCurrency(
                            withholding.taxWithheld,
                          ),
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: FinancialReportService.textDark,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: pw.Text(
                          'Total Payments Made',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: pw.Text(
                          FinancialReportService.formatCurrency(
                            withholding.totalPaymentsMade,
                          ),
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              if (withholding.penalties > 0) ...[
                pw.Text(
                  'Penalties: ${FinancialReportService.formatCurrency(withholding.penalties)}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: FinancialReportService.textDark,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
              pw.Spacer(),
              FinancialReportService.buildFooter('TAX COMPLIANCE - BIR FORM 1601-C'),
            ],
          );
        },
      ),
    );

    // Page 2: Audit Findings
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            children: [
              FinancialReportService.buildHeader(
                'AUDIT FINDINGS & RECOMMENDATIONS',
                schoolName,
                DateTime.now().toString().split(' ')[0],
              ),
              pw.Text(
                'Financial Compliance Status',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: FinancialReportService.accentViolet,
                ),
              ),
              pw.SizedBox(height: 16),

              // Compliance Checklist
              pw.Text(
                'Compliance Items',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: FinancialReportService.textDark,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: auditData.complianceItems.entries.map((entry) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 16,
                          height: 16,
                          decoration: pw.BoxDecoration(
                            color: entry.value
                                ? FinancialReportService.successGreen
                                : FinancialReportService.errorRed,
                            borderRadius:
                                const pw.BorderRadius.all(pw.Radius.circular(3)),
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              entry.value ? '✓' : '✗',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: FinancialReportService.textWhite,
                              ),
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: pw.Text(
                            entry.key,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              if (auditData.majorFindings.isNotEmpty) ...[
                pw.SizedBox(height: 16),
                pw.Text(
                  'Major Findings',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: FinancialReportService.errorRed,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: auditData.majorFindings.map((finding) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('• '),
                          pw.Expanded(
                            child: pw.Text(
                              finding,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],

              if (auditData.recommendations.isNotEmpty) ...[
                pw.SizedBox(height: 16),
                pw.Text(
                  'Recommendations',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: FinancialReportService.successGreen,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: auditData.recommendations.map((rec) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('✓ '),
                          pw.Expanded(
                            child: pw.Text(
                              rec,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],

              pw.Spacer(),
              FinancialReportService.buildFooter('TAX COMPLIANCE - AUDIT REPORT'),
            ],
          );
        },
      ),
    );

    return pdf;
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
