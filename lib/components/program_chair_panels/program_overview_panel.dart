import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProgramOverviewPanel extends StatelessWidget {
  final bool isDarkMode;
  const ProgramOverviewPanel({super.key, required this.isDarkMode});

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);

  @override
  Widget build(BuildContext context) {
    final Color textColor = isDarkMode ? Colors.white : pViolet;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Program Executive Summary",
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _statCard(
                "Active Students",
                "4,820",
                LucideIcons.users,
                aViolet,
                textColor,
              ),
              _statCard(
                "Faculty Count",
                "124",
                LucideIcons.graduationCap,
                Colors.blue,
                textColor,
              ),
              _statCard(
                "Graduation Rate",
                "92%",
                LucideIcons.award,
                Colors.greenAccent,
                textColor,
              ),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            "Pending Approvals",
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),
          _buildApprovalList(textColor),
        ],
      ),
    );
  }

  Widget _statCard(
    String label,
    String val,
    IconData icon,
    Color color,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDarkMode ? surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDarkMode ? Colors.white10 : Colors.black12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 15),
            Text(
              val,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalList(Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        children: List.generate(
          3,
          (index) => ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 8,
            ),
            leading: const CircleAvatar(
              backgroundColor: aViolet,
              child: Icon(LucideIcons.fileText, color: Colors.white, size: 16),
            ),
            title: Text(
              "Curriculum Revision - BSCS v2026",
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: const Text(
              "Submitted by Dept. Secretary • 2h ago",
              style: TextStyle(color: Colors.blueGrey, fontSize: 12),
            ),
            trailing: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: aViolet.withOpacity(0.1),
                foregroundColor: aViolet,
                elevation: 0,
              ),
              child: const Text(
                "Review",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
