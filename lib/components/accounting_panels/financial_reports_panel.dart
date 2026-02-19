import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uems_project/services/financial_pdf_manager.dart';
import 'package:uems_project/services/income_statement_pdf_service.dart';
import 'package:uems_project/services/balance_sheet_pdf_service.dart';
import 'package:uems_project/services/cash_flow_pdf_service.dart';
import 'package:uems_project/services/tax_compliance_pdf_service.dart';

class FinancialReportsPanel extends StatefulWidget {
  final bool isDarkMode;
  const FinancialReportsPanel({super.key, required this.isDarkMode});

  @override
  State<FinancialReportsPanel> createState() => _FinancialReportsPanelState();
}

class _FinancialReportsPanelState extends State<FinancialReportsPanel> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);

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
                () => _exportIncomeStatement(context),
              ),
              _reportCard(
                "Balance Sheet",
                "Assets, Liabilities, Equity",
                LucideIcons.scale,
                Colors.purpleAccent,
                cardColor,
                textColor,
                () => _exportBalanceSheet(context),
              ),
              _reportCard(
                "Cash Flow",
                "Inflow & Outflow",
                LucideIcons.banknote,
                const Color(0xFF69F0AE),
                cardColor,
                textColor,
                () => _exportCashFlow(context),
              ),
              _reportCard(
                "Tax Compliance",
                "BIR Forms & Audit",
                LucideIcons.fileCheck,
                Colors.orangeAccent,
                cardColor,
                textColor,
                () => _exportTaxCompliance(context),
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
                color: widget.isDarkMode ? Colors.white10 : Colors.black12,
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
        border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.black12),
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
            child: _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                : TextButton.icon(
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

  Future<void> _exportIncomeStatement(BuildContext context) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final incomeItems = [
        IncomeLineItem(name: 'Tuition Fees', amount: 750000, percentage: 60.0),
        IncomeLineItem(name: 'Lab Fees', amount: 180000, percentage: 14.4),
        IncomeLineItem(name: 'Miscellaneous Fees', amount: 320000, percentage: 25.6),
      ];

      final expenseItems = [
        ExpenseLineItem(name: 'Salaries & Benefits', amount: 520000, percentage: 61.5),
        ExpenseLineItem(name: 'Facility Maintenance', amount: 180000, percentage: 21.3),
        ExpenseLineItem(name: 'Office Supplies & Equipment', amount: 100000, percentage: 11.8),
        ExpenseLineItem(name: 'Utilities', amount: 45000, percentage: 5.4),
      ];

      final pdf = await IncomeStatementPdfService.generateIncomeStatement(
        schoolName: 'University of Excellence & Management System',
        date: DateTime.now().toString().split(' ')[0],
        incomeItems: incomeItems,
        expenseItems: expenseItems,
        netIncome: 405000,
      );

      final fileName = FinancialPdfManager.generateFileName(
        documentType: 'Income_Statement',
        schoolName: 'UEMS',
      );

      await FinancialPdfManager.savePDFAndOpen(pdf: pdf, fileName: fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Income Statement PDF generated and opened'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating Income Statement: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      debugPrint('Income Statement generation error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _exportBalanceSheet(BuildContext context) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final data = BalanceSheetData(
        currentAssets: {
          'Cash at Bank': 450000,
          'Accounts Receivable': 280000,
          'Advances to Employees': 50000,
        },
        fixedAssets: {
          'Buildings': 3500000,
          'Furniture & Equipment': 800000,
          'Transportation Equipment': 450000,
        },
        otherAssets: {
          'Goodwill': 200000,
          'Software Licenses': 150000,
        },
        currentLiabilities: {
          'Accounts Payable': 180000,
          'Accrued Expenses': 75000,
          'Short-term Loans': 200000,
        },
        longTermLiabilities: {
          'Long-term Debt': 500000,
          'Deferred Revenue': 120000,
        },
        equity: {
          'Capital Fund': 2000000,
          'Retained Earnings': 1204000,
          'Current Year Surplus': 405000,
        },
      );

      final pdf = await BalanceSheetPdfService.generateBalanceSheet(
        schoolName: 'University of Excellence & Management System',
        date: DateTime.now().toString().split(' ')[0],
        data: data,
      );

      final fileName = FinancialPdfManager.generateFileName(
        documentType: 'Balance_Sheet',
        schoolName: 'UEMS',
      );

      await FinancialPdfManager.savePDFAndOpen(pdf: pdf, fileName: fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Balance Sheet PDF generated and opened'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating Balance Sheet: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      debugPrint('Balance Sheet generation error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _exportCashFlow(BuildContext context) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final data = CashFlowData(
        operatingActivities: {
          'Cash from Student Fees': 850000,
          'Other Operating Income': 150000,
          'Operating Expenses': -620000,
        },
        investingActivities: {
          'Purchase of Equipment': -200000,
          'Sale of Assets': 50000,
          'Investment Income': 25000,
        },
        financingActivities: {
          'Loan Proceeds': 300000,
          'Loan Repayment': -150000,
          'Grants Received': 180000,
        },
        beginningCashBalance: 450000,
        endingCashBalance: 835000,
      );

      final pdf = await CashFlowPdfService.generateCashFlowStatement(
        schoolName: 'University of Excellence & Management System',
        date: DateTime.now().toString().split(' ')[0],
        data: data,
      );

      final fileName = FinancialPdfManager.generateFileName(
        documentType: 'Cash_Flow_Statement',
        schoolName: 'UEMS',
      );

      await FinancialPdfManager.savePDFAndOpen(pdf: pdf, fileName: fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cash Flow Statement PDF generated and opened'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating Cash Flow Statement: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      debugPrint('Cash Flow generation error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _exportTaxCompliance(BuildContext context) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final birData = TaxWithholdingData(
        totalCompensation: 2500000,
        nonTaxableCompensation: 125000,
        taxWithheld: 297500,
        totalPaymentsMade: 297500,
        penalties: 0,
      );

      final auditData = AuditFindingsData(
        complianceItems: {
          'Tax Returns Filed': true,
          'BIR Compliance': true,
          'Audit Trail Maintained': true,
          'Financial Records': true,
          'Withholding Payments': true,
          'Loan Compliance': true,
        },
        majorFindings: [],
        recommendations: [
          'Continue maintaining detailed financial records',
          'Regular tax compliance training for staff',
          'Quarterly financial reporting review',
        ],
      );

      final pdf = await TaxCompliancePdfService.generateComprehensiveReport(
        schoolName: 'University of Excellence & Management System',
        tinNumber: '123-456-789-000',
        forTheMonth: DateTime.now().month,
        forTheYear: DateTime.now().year,
        withholding: birData,
        auditData: auditData,
      );

      final fileName = FinancialPdfManager.generateFileName(
        documentType: 'Tax_Compliance_Report',
        schoolName: 'UEMS',
      );

      await FinancialPdfManager.savePDFAndOpen(pdf: pdf, fileName: fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tax Compliance Report PDF generated and opened'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating Tax Compliance Report: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      debugPrint('Tax Compliance generation error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
