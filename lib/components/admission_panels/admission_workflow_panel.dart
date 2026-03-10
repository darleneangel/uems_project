import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdmissionWorkflowPanel extends StatelessWidget {
  final bool isDarkMode;
  const AdmissionWorkflowPanel({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final Color cardColor = isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final Color subTextColor = isDarkMode ? Colors.white54 : Colors.blueGrey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [const Color(0xFF4C1D95), const Color(0xFF2E1065)]
                  : [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(
                LucideIcons.checkCircle,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ready for Admission",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Text(
                    "Applicants who have passed exams and interviews.",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView(
            children: [
              _buildAdmissionCard(
                "Michael Chen",
                "BS Information Tech",
                "92%",
                "Completed",
                cardColor,
                textColor,
                subTextColor,
              ),
              // Add more items here
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdmissionCard(
    String name,
    String course,
    String examScore,
    String interviewRating,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textColor,
                    ),
                  ),
                  Text(course, style: TextStyle(color: subTextColor)),
                ],
              ),
              const Spacer(),
              _buildBadge(
                LucideIcons.fileText,
                "Exam: $examScore",
                Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildBadge(
                LucideIcons.mic,
                "Interview: $interviewRating",
                Colors.purple,
              ),
              const SizedBox(width: 8),
              _buildBadge(LucideIcons.wallet, "Fee: Cleared", Colors.green),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () {}, // Generate Admission Letter
                icon: const Icon(LucideIcons.printer, size: 16),
                label: const Text("Notice of Admission"),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {}, // Transfer to Registrar Database
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF69F0AE),
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(LucideIcons.userPlus, size: 16),
                label: const Text("Finalize Admission"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
