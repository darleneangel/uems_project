import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ReportingCompliancePanel extends StatelessWidget {
  final bool isDarkMode;
  const ReportingCompliancePanel({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final Color cardColor = isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Reporting & Institutional Compliance",
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _reportButton(
                "CHED Enrollment Report",
                LucideIcons.fileSpreadsheet,
                cardColor,
                textColor,
              ),
              const SizedBox(width: 16),
              _reportButton(
                "Graduation Statistics",
                LucideIcons.barChart,
                cardColor,
                textColor,
              ),
              const SizedBox(width: 16),
              _reportButton(
                "Government Audit Logs",
                LucideIcons.shieldCheck,
                cardColor,
                textColor,
              ),
            ],
          ),
          const SizedBox(height: 32),
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
                  "System Transaction Audit Trail",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 20),
                _auditItem(
                  "Grade Modified",
                  "Prof. Manalastas updated CS411 grade for ID 2024-00001",
                  "2 mins ago",
                  textColor,
                ),
                _auditItem(
                  "Record Created",
                  "New student record generated for ID 2024-00102",
                  "1 hour ago",
                  textColor,
                ),
                _auditItem(
                  "Status Change",
                  "ID 2023-00142 set to 'Alumni' status",
                  "Yesterday",
                  textColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportButton(String title, IconData icon, Color bg, Color text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF8B5CF6), size: 32),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: text,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "GENERATE PDF",
              style: TextStyle(
                color: Color(0xFF69F0AE),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _auditItem(String action, String detail, String time, Color text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.history, size: 16, color: Colors.blueGrey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(color: Colors.white24, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
