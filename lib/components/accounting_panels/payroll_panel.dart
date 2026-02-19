// c:\Users\Darlene Angel\uems_project\lib\components\accounting_panels\payroll_panel.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/financial_pdf_manager.dart';
import '../../services/payroll_pdf_service.dart';

class PayrollPanel extends StatelessWidget {
  final bool isDarkMode;
  const PayrollPanel({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final subTextColor = isDarkMode ? Colors.white54 : Colors.blueGrey;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [const Color(0xFF2E1065), const Color(0xFF4C1D95)]
                  : [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Next Payroll Run",
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "March 30, 2026",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _openProcessPayroll(context),
                icon: const Icon(LucideIcons.play, size: 16),
                label: const Text("PROCESS PAYROLL"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2E1065),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDarkMode ? Colors.white10 : Colors.black12,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Employee List",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 20),
              _employeeRow(
                "Prof. R. Manalastas",
                "Faculty - IT",
                "₱45,000.00",
                "Pending",
                textColor,
                subTextColor,
              ),
              _employeeRow(
                "Dr. A. De Silva",
                "Faculty - CS",
                "₱55,000.00",
                "Pending",
                textColor,
                subTextColor,
              ),
              _employeeRow(
                "Ms. J. Santos",
                "Staff - Accounting",
                "₱30,000.00",
                "Pending",
                textColor,
                subTextColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _employeeRow(
    String name,
    String role,
    String salary,
    String status,
    Color textColor,
    Color subTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.1),
            child: const Icon(
              LucideIcons.userCheck,
              size: 16,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  role,
                  style: GoogleFonts.inter(fontSize: 12, color: subTextColor),
                ),
              ],
            ),
          ),
          Text(
            salary,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _openProcessPayroll(BuildContext context) {
    bool includeOvertime = true;
    bool includeAllowances = true;
    bool autoDeductions = true;
    String selectedDepartment = 'All Departments';
    String selectedPeriod = 'March 16 - March 31, 2026';
    String payDate = 'March 30, 2026';
    String payrollCycle = 'Monthly';
    String sssEmployerId = 'SSS-ER-102938';
    String sssContributionRate = '14.00%';
    String sssCutoff = 'Monthly';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Process Payroll',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E1065),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Configure the payroll run and review the payout summary before generating.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedDepartment,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'All Departments',
                                    child: Text('All Departments'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Faculty',
                                    child: Text('Faculty'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Staff',
                                    child: Text('Staff'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Administration',
                                    child: Text('Administration'),
                                  ),
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Department',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => selectedDepartment = value);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedPeriod,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'March 16 - March 31, 2026',
                                    child: Text('March 16 - March 31, 2026'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'April 1 - April 15, 2026',
                                    child: Text('April 1 - April 15, 2026'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'April 16 - April 30, 2026',
                                    child: Text('April 16 - April 30, 2026'),
                                  ),
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Pay Period',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => selectedPeriod = value);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: payDate,
                                decoration: const InputDecoration(
                                  labelText: 'Pay Date',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) => payDate = value,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: payrollCycle,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Weekly',
                                    child: Text('Weekly'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Semi-Monthly',
                                    child: Text('Semi-Monthly'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Monthly',
                                    child: Text('Monthly'),
                                  ),
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Payroll Cycle',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => payrollCycle = value);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: sssCutoff,
                          items: const [
                            DropdownMenuItem(
                              value: 'Monthly',
                              child: Text('SSS Cutoff: Monthly'),
                            ),
                            DropdownMenuItem(
                              value: 'Semi-Monthly',
                              child: Text('SSS Cutoff: Semi-Monthly'),
                            ),
                            DropdownMenuItem(
                              value: 'Weekly',
                              child: Text('SSS Cutoff: Weekly'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'SSS Cutoff',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => sssCutoff = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: sssEmployerId,
                                decoration: const InputDecoration(
                                  labelText: 'SSS Employer ID',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) => sssEmployerId = value,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: sssContributionRate,
                                decoration: const InputDecoration(
                                  labelText: 'SSS Contribution Rate',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) => sssContributionRate = value,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                value: includeOvertime,
                                onChanged: (value) => setState(() => includeOvertime = value ?? true),
                                title: const Text('Include overtime & late adjustments'),
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CheckboxListTile(
                                value: includeAllowances,
                                onChanged: (value) => setState(() => includeAllowances = value ?? true),
                                title: const Text('Include allowances & benefits'),
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                        CheckboxListTile(
                          value: autoDeductions,
                          onChanged: (value) => setState(() => autoDeductions = value ?? true),
                          title: const Text('Auto-calculate statutory deductions & taxes'),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F8FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE6E1FA)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Salary Groups & SSS Coverage',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2E1065),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _summaryRow('Payroll cycle', 'Monthly (Weekly option available)'),
                              _summaryRow('Academic working staff', '12 staff | ₱32,000.00 avg'),
                              _summaryRow('Teachers', '18 staff | ₱48,500.00 avg'),
                              _summaryRow('Non-academic working staff', '6 staff | ₱27,500.00 avg'),
                              _summaryRow('SSS coverage', 'Included for all eligible staff'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F2FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2DDFD)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payroll Summary',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2E1065),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _summaryRow('Employees included', '36'),
                              _summaryRow('Gross payroll', '₱1,480,000.00'),
                              _summaryRow('Total deductions', '₱214,250.00'),
                              _summaryRow('Net payout', '₱1,265,750.00', isEmphasis: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                Navigator.of(context).pop();
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Generating payroll PDF...'),
                                  ),
                                );

                                try {
                                  final reportData = PayrollReportData(
                                    schoolName: 'UEMS - Unified Education Management System',
                                    department: selectedDepartment,
                                    payPeriod: selectedPeriod,
                                    payDate: payDate,
                                    payrollCycle: payrollCycle,
                                    includeOvertime: includeOvertime,
                                    includeAllowances: includeAllowances,
                                    autoDeductions: autoDeductions,
                                    sssEmployerId: sssEmployerId,
                                    sssContributionRate: sssContributionRate,
                                    sssCutoff: sssCutoff,
                                    groupSummaries: [
                                      PayrollGroupSummary(
                                        name: 'Academic Working Staff',
                                        staffCount: 12,
                                        averageSalary: 32000,
                                      ),
                                      PayrollGroupSummary(
                                        name: 'Teachers',
                                        staffCount: 18,
                                        averageSalary: 48500,
                                      ),
                                      PayrollGroupSummary(
                                        name: 'Non-Academic Working Staff',
                                        staffCount: 6,
                                        averageSalary: 27500,
                                      ),
                                    ],
                                    totals: PayrollTotals(
                                      employeeCount: 36,
                                      grossPayroll: 1480000,
                                      totalDeductions: 214250,
                                      netPayout: 1265750,
                                    ),
                                  );

                                  final pdf = await PayrollPdfService.generatePayrollReport(
                                    data: reportData,
                                  );

                                  await FinancialPdfManager.savePDFAndOpen(
                                    pdf: pdf,
                                    fileName: FinancialPdfManager.generateFileName(
                                      documentType: 'PayrollReport',
                                      schoolName: 'UEMS',
                                    ),
                                  );

                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Payroll PDF generated successfully.'),
                                    ),
                                  );
                                } catch (error) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to generate payroll PDF: $error'),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(LucideIcons.fileCheck, size: 16),
                              label: const Text('Generate Payroll'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E1065),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _summaryRow(String label, String value, {bool isEmphasis = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.blueGrey,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isEmphasis ? FontWeight.bold : FontWeight.w600,
              color: isEmphasis ? const Color(0xFF2E1065) : const Color(0xFF1E1B4B),
            ),
          ),
        ],
      ),
    );
  }
}
