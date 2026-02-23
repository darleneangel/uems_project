import 'package:flutter/material.dart';
import 'accounting_panels/accounting_overview_panel.dart';
import 'accounting_panels/fee_management_panel.dart';
import 'accounting_panels/financial_reports_panel.dart';
import 'accounting_panels/payroll_panel.dart';
import 'accounting_panels/payment_request_panel.dart';
import 'accounting_panels/payment_channels_panel.dart';
import 'accounting_panels/payment_plans_panel.dart';
import 'accounting_panels/documentation_panel.dart';
import 'accounting_panels/daily_report_panel.dart';
import 'shared/messaging_panel.dart';
import 'accounting_panels/subject_load_fee_panel.dart';

class AccountingPanelContent extends StatelessWidget {
  final int selectedIndex;
  final bool isDarkMode;
  final VoidCallback? onNavigateToFeeManagement;
  final VoidCallback? onGenerateDailyReport;

  const AccountingPanelContent({
    super.key,
    required this.selectedIndex,
    required this.isDarkMode,
    this.onNavigateToFeeManagement,
    this.onGenerateDailyReport,
  });

  // Theme Constants (matching AdmissionDashboardView)
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);

  @override
  Widget build(BuildContext context) {
    final Color subTextColor = isDarkMode ? Colors.white54 : Colors.blueGrey;

    switch (selectedIndex) {
      case 0:
        return AccountingOverviewPanel(
          isDarkMode: isDarkMode,
          onNavigateToFeeManagement: onNavigateToFeeManagement,
          onGenerateDailyReport: onGenerateDailyReport,
        );
      case 1:
        return FeeManagementPanel(isDarkMode: isDarkMode);
      case 2:
        return FinancialReportsPanel(isDarkMode: isDarkMode);
      case 3:
        return PayrollPanel(isDarkMode: isDarkMode);
      case 4:
        return PaymentRequestPanel(isDarkMode: isDarkMode);
      case 5:
        return PaymentChannelsPanel(isDarkMode: isDarkMode);
      case 6:
        return PaymentPlansPanel(isDarkMode: isDarkMode);
      case 7:
        return DocumentationPanel(isDarkMode: isDarkMode);
      case 8:
        return DailyReportPanel(isDarkMode: isDarkMode);
      case 9:
        return MessagingPanel(isDarkMode: isDarkMode);
      default:
        return Center(
          child: Text(
            "Module Under Construction",
            style: TextStyle(color: subTextColor),
          ),
        );
    }
  }
}
