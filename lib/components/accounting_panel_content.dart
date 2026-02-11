import 'package:flutter/material.dart';
import 'accounting_panels/accounting_overview_panel.dart';
import 'accounting_panels/fee_management_panel.dart';
import 'accounting_panels/financial_reports_panel.dart';
import 'accounting_panels/payroll_panel.dart';
import 'shared/messaging_panel.dart';

class AccountingPanelContent extends StatelessWidget {
  final int selectedIndex;
  final bool isDarkMode;

  const AccountingPanelContent({
    super.key,
    required this.selectedIndex,
    required this.isDarkMode,
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
        return AccountingOverviewPanel(isDarkMode: isDarkMode);
      case 1:
        return FeeManagementPanel(isDarkMode: isDarkMode);
      case 2:
        return FinancialReportsPanel(isDarkMode: isDarkMode);
      case 3:
        return PayrollPanel(isDarkMode: isDarkMode);
      case 4:
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
