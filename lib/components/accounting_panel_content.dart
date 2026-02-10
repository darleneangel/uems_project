// c:\Users\Darlene Angel\uems_project\lib\components\accounting_panel_content.dart

import 'package:flutter/material.dart';
import 'accounting_panels/fee_management_panel.dart';
import 'accounting_panels/payroll_panel.dart';
import 'accounting_panels/financial_reports_panel.dart';
import 'accounting_panels/accounting_overview_panel.dart';

class AccountingPanelContent extends StatelessWidget {
  final int selectedIndex;
  final bool isDarkMode;

  const AccountingPanelContent({
    super.key,
    required this.selectedIndex,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _buildActivePanel(),
    );
  }

  Widget _buildActivePanel() {
    // Using ValueKey ensures AnimatedSwitcher detects the widget change
    switch (selectedIndex) {
      case 1:
        return FeeManagementPanel(
          key: const ValueKey('fee_management'),
          isDarkMode: isDarkMode,
        );
      case 2:
        return PayrollPanel(
          key: const ValueKey('payroll'),
          isDarkMode: isDarkMode,
        );
      case 3:
        return FinancialReportsPanel(
          key: const ValueKey('financial_reports'),
          isDarkMode: isDarkMode,
        );
      case 0:
      default:
        return AccountingOverviewPanel(
          key: const ValueKey('overview'),
          isDarkMode: isDarkMode,
        );
    }
  }
}
