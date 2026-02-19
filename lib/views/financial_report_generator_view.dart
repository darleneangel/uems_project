import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/income_statement_pdf_service.dart';
import '../services/balance_sheet_pdf_service.dart';
import '../services/cash_flow_pdf_service.dart';
import '../services/tax_compliance_pdf_service.dart';
import '../services/financial_pdf_manager.dart';

class FinancialReportGeneratorView extends StatefulWidget {
  const FinancialReportGeneratorView({super.key});

  @override
  State<FinancialReportGeneratorView> createState() =>
      _FinancialReportGeneratorViewState();
}

class _FinancialReportGeneratorViewState
    extends State<FinancialReportGeneratorView> {
  static const Color primaryDark = Color(0xFF1E1033);
  static const Color accentViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF0F0820);

  bool isGenerating = false;

  // Sample data for Income Statement
  Future<void> _generateIncomeStatement() async {
    setState(() => isGenerating = true);

    try {
      final incomeItems = [
        IncomeLineItem(
          name: 'Tuition and Fees Income',
          amount: 125454357,
          percentage: 53.29,
        ),
        IncomeLineItem(
          name: 'Tuition Income',
          amount: 39110633,
          percentage: 16.61,
        ),
        IncomeLineItem(
          name: 'Miscellaneous Income',
          amount: 81686624,
          percentage: 34.70,
        ),
        IncomeLineItem(
          name: 'Internship Experiment Fee Income',
          amount: 4657100,
          percentage: 1.98,
        ),
        IncomeLineItem(
          name: 'Subsidy and Donation Income',
          amount: 56600651,
          percentage: 24.04,
        ),
        IncomeLineItem(
          name: 'Kindergarten Income',
          amount: 32265297,
          percentage: 13.71,
        ),
      ];

      final expenseItems = [
        ExpenseLineItem(
          name: 'Salaries & Wages',
          amount: 45000000,
          percentage: 40.0,
        ),
        ExpenseLineItem(
          name: 'Utilities & Maintenance',
          amount: 15000000,
          percentage: 13.3,
        ),
        ExpenseLineItem(
          name: 'Educational Materials',
          amount: 25000000,
          percentage: 22.2,
        ),
        ExpenseLineItem(
          name: 'Administrative Expenses',
          amount: 27500000,
          percentage: 24.5,
        ),
      ];

      final pdf = await IncomeStatementPdfService.generateIncomeStatement(
        schoolName: 'Unified Education Management System - Demo School',
        date: DateTime.now().toString().split(' ')[0],
        incomeItems: incomeItems,
        expenseItems: expenseItems,
      );

      final fileName = FinancialPdfManager.generateFileName(
        documentType: 'Income_Statement',
        schoolName: 'Demo_School',
      );

      await FinancialPdfManager.savePDFAndOpen(
        pdf: pdf,
        fileName: fileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Income Statement Generated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => isGenerating = false);
    }
  }

  // Sample data for Balance Sheet
  Future<void> _generateBalanceSheet() async {
    setState(() => isGenerating = true);

    try {
      final data = BalanceSheetData(
        currentAssets: {
          'Cash at Hand': 50000000,
          'Cash at Bank': 150000000,
          'Accounts Receivable': 45000000,
          'Inventory': 25000000,
        },
        fixedAssets: {
          'Buildings': 500000000,
          'Furniture & Fixtures': 100000000,
          'Equipment': 150000000,
          'Vehicles': 80000000,
        },
        otherAssets: {
          'Goodwill': 30000000,
          'Prepaid Expenses': 15000000,
        },
        currentLiabilities: {
          'Accounts Payable': 45000000,
          'Sales Taxes Payable': 8000000,
          'Payroll Taxes Payable': 5000000,
          'Short-Term Loan': 25000000,
        },
        longTermLiabilities: {
          'Long-term Bank Loans': 200000000,
          'Mortgage Payable': 150000000,
        },
        equity: {
          'Capital': 500000000,
          'Add: Net Profit': 100000000,
          'Less: Drawings': 25000000,
        },
      );

      final pdf = await BalanceSheetPdfService.generateBalanceSheet(
        schoolName: 'Unified Education Management System - Demo School',
        date: DateTime.now().toString().split(' ')[0],
        data: data,
      );

      final fileName = FinancialPdfManager.generateFileName(
        documentType: 'Balance_Sheet',
        schoolName: 'Demo_School',
      );

      await FinancialPdfManager.savePDFAndOpen(
        pdf: pdf,
        fileName: fileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Balance Sheet Generated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => isGenerating = false);
    }
  }

  // Sample data for Cash Flow Statement
  Future<void> _generateCashFlow() async {
    setState(() => isGenerating = true);

    try {
      final data = CashFlowData(
        operatingActivities: {
          'Tuition Fees Received': 1500000,
          'Government Grants': 250000,
          'Supplies & Utilities': -100000,
          'Program Expenses': -120000,
          'Staff Salaries': -750000,
        },
        investingActivities: {
          'Purchase of Equipment': -100000,
          'Renovation of Library': -200000,
          'Sale of Old Vehicles': -200000,
        },
        financingActivities: {
          'Loan from Bank': 400000,
          'Donations for Endowment': -40000,
          'Equipment Investments': -300000,
        },
        beginningCashBalance: 300000,
        endingCashBalance: 1200000,
      );

      final pdf = await CashFlowPdfService.generateCashFlowStatement(
        schoolName: 'Unified Education Management System - Demo School',
        date: DateTime.now().toString().split(' ')[0],
        data: data,
      );

      final fileName = FinancialPdfManager.generateFileName(
        documentType: 'Cash_Flow_Statement',
        schoolName: 'Demo_School',
      );

      await FinancialPdfManager.savePDFAndOpen(
        pdf: pdf,
        fileName: fileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cash Flow Statement Generated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => isGenerating = false);
    }
  }

  // Sample data for Tax Compliance
  Future<void> _generateTaxCompliance() async {
    setState(() => isGenerating = true);

    try {
      final taxData = TaxWithholdingData(
        totalCompensation: 2500000,
        nonTaxableCompensation: 250000,
        taxWithheld: 225000,
        totalPaymentsMade: 200000,
        penalties: 5000,
      );

      final pdf = await TaxCompliancePdfService.generateBIR1601CForm(
        schoolName: 'Unified Education Management System - Demo School',
        tinNumber: '123-456-789-012',
        forTheMonth: DateTime.now().month,
        forTheYear: DateTime.now().year,
        data: taxData,
      );

      final fileName = FinancialPdfManager.generateFileName(
        documentType: 'Tax_Compliance_BIR1601C',
        schoolName: 'Demo_School',
      );

      await FinancialPdfManager.savePDFAndOpen(
        pdf: pdf,
        fileName: fileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tax Compliance Report Generated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => isGenerating = false);
    }
  }

  // Sample data for Audit Report
  Future<void> _generateAuditReport() async {
    setState(() => isGenerating = true);

    try {
      final findings = AuditFindingsData(
        complianceItems: {
          'Financial Records Reconciliation': true,
          'Audit Trail Documentation': true,
          'Internal Controls Assessment': false,
          'Tax Payment Compliance': true,
          'Asset Verification': true,
          'Liability Documentation': true,
        },
        majorFindings: [
          'Incomplete documentation for certain transactions in Q2',
          'Minor discrepancies in inventory reconciliation',
          'Delayed tax payment filing for one month',
        ],
        recommendations: [
          'Implement automated reconciliation procedures',
          'Quarterly audit reviews instead of annual',
          'Enhanced training for accounting staff',
          'Implement document management system',
          'Monthly tax compliance check',
        ],
      );

      final pdf = await TaxCompliancePdfService.generateAuditReport(
        schoolName: 'Unified Education Management System - Demo School',
        auditPeriod: 'January 1, 2024 - December 31, 2024',
        auditedBy: 'Certified Internal Auditor',
        auditDate: DateTime.now().toString().split(' ')[0],
        findings: findings,
      );

      final fileName = FinancialPdfManager.generateFileName(
        documentType: 'Audit_Report',
        schoolName: 'Demo_School',
      );

      await FinancialPdfManager.savePDFAndOpen(
        pdf: pdf,
        fileName: fileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audit Report Generated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryDark,
        elevation: 0,
        title: Text(
          'Financial Reports',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      backgroundColor: surfaceDark,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        children: [
          _buildReportCard(
            title: 'Income Statement',
            subtitle: 'Revenue vs Expenses Analysis',
            icon: Icons.trending_up,
            onTap: isGenerating ? null : _generateIncomeStatement,
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            title: 'Balance Sheet',
            subtitle: 'Assets, Liabilities & Equity',
            icon: Icons.balance,
            onTap: isGenerating ? null : _generateBalanceSheet,
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            title: 'Cash Flow Statement',
            subtitle: 'Operating, Investing & Financing',
            icon: Icons.water_drop,
            onTap: isGenerating ? null : _generateCashFlow,
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            title: 'Tax Compliance (BIR 1601-C)',
            subtitle: 'Monthly Tax Remittance',
            icon: Icons.assignment,
            onTap: isGenerating ? null : _generateTaxCompliance,
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            title: 'Audit Report',
            subtitle: 'Findings & Recommendations',
            icon: Icons.checklist,
            onTap: isGenerating ? null : _generateAuditReport,
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: primaryDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isGenerating ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentViolet.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: accentViolet,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: isGenerating ? Colors.grey : accentViolet,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
