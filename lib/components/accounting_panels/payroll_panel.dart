// c:\Users\Darlene Angel\uems_project\lib\components\accounting_panels\payroll_panel.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
                onPressed: () {},
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
}
