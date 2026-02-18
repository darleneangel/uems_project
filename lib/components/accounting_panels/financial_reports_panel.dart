import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FinancialReportsPanel extends StatelessWidget {
  final bool isDarkMode;
  const FinancialReportsPanel({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2E1065);

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
            ),
            _reportCard(
              "Balance Sheet",
              "Assets, Liabilities, Equity",
              LucideIcons.scale,
              Colors.purpleAccent,
              cardColor,
              textColor,
            ),
            _reportCard(
              "Cash Flow",
              "Inflow & Outflow",
              LucideIcons.banknote,
              const Color(0xFF69F0AE),
              cardColor,
              textColor,
            ),
            _reportCard(
              "Tax Compliance",
              "BIR Forms & Audit",
              LucideIcons.fileCheck,
              Colors.orangeAccent,
              cardColor,
              textColor,
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
              color: isDarkMode ? Colors.white10 : Colors.black12,
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
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
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
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(LucideIcons.download, size: 16),
              label: const Text("EXPORT PDF"),
              style: TextButton.styleFrom(foregroundColor: color),
            ),
          ),
        ],
      ),
    );
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
